# 桃源乡 (Taoyuan) - Godot 4 移植文档

## 文档信息

| 项目 | 值 |
|------|-----|
| 原项目 | 桃源乡 Vue.js 农场模拟游戏 |
| 目标引擎 | Godot 4.6 |
| 目标语言 | GDScript / C# |
| 文档版本 | 1.0 |
| 创建日期 | 2026-04-03 |

---

## 1. 项目概述

### 1.1 原始项目技术栈

| 类别 | 技术 | 版本 |
|------|------|------|
| 前端框架 | Vue 3 (Composition API) | 3.5.24 |
| 类型系统 | TypeScript | 5.9.3 |
| 构建工具 | Vite | 7.2.4 |
| 状态管理 | Pinia | 3.0.4 (26个store) |
| 路由 | Vue Router | 5.0.2 |
| 样式 | TailwindCSS | 3.4.19 |
| 音频 | Tone.js | 15.1.22 |
| 桌面端 | Electron | 39.2.7 |
| 移动端 | Capacitor | 8.1.0 |

### 1.2 目标技术栈

| 类别 | 技术 | 说明 |
|------|------|------|
| 引擎 | Godot 4.6 | Jolt物理引擎，D3D12/Vulkan |
| 语言 | GDScript / C# | 建议核心逻辑用C#，UI用GDScript |
| 版本控制 | Git | trunk-based |
| 构建目标 | Windows / Web / Android | 跨平台支持 |

---

## 2. 项目结构映射

### 2.1 Vue → Godot 目录对照

```
Vue.js 项目                    Godot 4 项目
─────────────────────────────────────────────────────
src/                          res://
├── views/game/               res://scenes/game/
│   ├── FarmView.vue    →     FarmScene.tscn
│   ├── VillageView.vue →     VillageScene.tscn
│   ├── MiningView.vue  →     MiningScene.tscn
│   └── ...
├── components/game/           res://scripts/components/
├── stores/                    res://scripts/systems/
│   ├── useGameStore.ts  →     GameState.cs
│   ├── usePlayerStore.ts →    PlayerState.cs
│   └── ...
├── composables/               res://scripts/systems/
├── data/                      res://resources/data/
│   ├── crops.ts         →     crops.tres (Resource)
│   ├── npcs.ts          →     npcs.tres
│   └── ...
├── types/                     res://scripts/types/
└── router/                    内置场景系统

electron/                      res://../godotexe/ (导出用)
android/                       Godot Android导出模板
```

### 2.2 推荐 Godot 项目结构

```
taoyuan/
├── .godot/                    # Godot引擎生成（gitignore）
├── addons/                    # 第三方插件
├── assets/                    # 游戏资源（美术、音效）
│   ├── art/
│   │   ├── sprites/
│   │   ├── tilesets/
│   │   ├── portraits/
│   │   └── ui/
│   ├── audio/
│   │   ├── bgm/
│   │   └── sfx/
│   └── fonts/
├── export/                    # 导出预设
├── project.godot              # 项目配置
├── scenes/                    # 游戏场景
│   ├── core/                  # 核心场景
│   │   ├── MainMenu.tscn
│   │   ├── GameRoot.tscn
│   │   └── LoadingScreen.tscn
│   ├── game/                  # 游戏内场景
│   │   ├── farm/
│   │   │   ├── FarmScene.tscn
│   │   │   ├── FarmPlot.tscn
│   │   │   └── Crop.tscn
│   │   ├── village/
│   │   ├── mining/
│   │   ├── fishing/
│   │   └── ui/
│   │       ├── DialogBox.tscn
│   │       ├── Inventory.tscn
│   │       └── HUD.tscn
│   └── mini_games/            # 小游戏
│       ├── FishingMiniGame.tscn
│       ├── TexasHoldem.tscn
│       └── BuckshotRoulette.tscn
├── resources/                 # Godot Resource文件
│   ├── data/                  # 游戏数据
│   │   ├── crops.tres
│   │   ├── animals.tres
│   │   ├── npcs.tres
│   │   ├── fish.tres
│   │   ├── recipes.tres
│   │   └── ...
│   ├── items/
│   ├── buildings/
│   ├── maps/
│   └── quests/
├── scripts/                   # 代码文件
│   ├── autoload/              # 自动加载（单例）
│   │   ├── GameManager.cs
│   │   ├── AudioManager.cs
│   │   ├── SaveManager.cs
│   │   ├── EventManager.cs
│   │   └── DataManager.cs
│   ├── components/            # 可复用组件
│   ├── systems/              # 游戏系统
│   │   ├── farming/
│   │   ├── combat/
│   │   ├── fishing/
│   │   └── cooking/
│   ├── states/               # 状态机
│   │   ├── PlayerState/
│   │   └── NPCState/
│   ├── ui/                   # UI逻辑
│   ├── types/                # 类型定义
│   └── utils/                # 工具函数
└── docs/                      # 文档
```

---

## 3. 核心系统移植方案

### 3.1 状态管理系统

#### Vue (Pinia) → Godot

**Vue.js:**
```typescript
// useGameStore.ts
export const useGameStore = defineStore('game', () => {
  const year = ref(1)
  const season = ref<Season>('spring')
  const day = ref(1)
  const hour = ref(6)
  const weather = ref<Weather>('sunny')

  function nextDay() { ... }
  function advanceTime() { ... }

  return { year, season, day, hour, weather, nextDay, advanceTime }
})
```

**Godot 4 (C#):**
```csharp
// GameState.cs
using Godot;
using Godot.Collections;

public partial class GameState : Node
{
    public static GameState Instance { get; private set; }

    [Export] public int Year { get; set; } = 1;
    [Export] public Season Season { get; set; } = Season.Spring;
    [Export] public int Day { get; set; } = 1;
    [Export] public int Hour { get; set; } = 6;
    [Export] public Weather Weather { get; set; } = Weather.Sunny;

    public override void _Ready()
    {
        if (Instance == null) Instance = this;
        else QueueFree();
    }

    public void NextDay() { ... }
    public void AdvanceTime() { ... }
}

public enum Season { Spring, Summer, Autumn, Winter }
public enum Weather { Sunny, Rainy, Stormy, Snowy, Windy, GreenRain }
```

### 3.2 所有 Store 映射表

| Vue Store | Godot 单例/类 | 职责 |
|-----------|---------------|------|
| `useGameStore` | `GameState` | 时间、季节、天气、地点 |
| `usePlayerStore` | `PlayerState` | 玩家属性、金钱、体力、生命 |
| `useInventoryStore` | `InventorySystem` | 背包、工具、装备 |
| `useSaveStore` | `SaveManager` | 存档系统 |
| `useFarmStore` | `FarmingSystem` | 农场地块、洒水器 |
| `useSkillStore` | `SkillSystem` | 技能等级、天赋 |
| `useNpcStore` | `NPCSystem` | NPC好感度 |
| `useHiddenNpcStore` | `HiddenNPCSystem` | 隐藏精灵NPC |
| `useCookingStore` | `CookingSystem` | 烹饪、buff |
| `useMiningStore` | `MiningSystem` | 采矿 |
| `useFishingStore` | `FishingSystem` | 钓鱼 |
| `useAnimalStore` | `AnimalSystem` | 畜牧 |
| `useHomeStore` | `HomeSystem` | 建筑升级 |
| `useProcessingStore` | `ProcessingSystem` | 加工机器 |
| `useAchievementStore` | `AchievementSystem` | 成就 |
| `useQuestStore` | `QuestSystem` | 任务 |
| `useGuildStore` | `GuildSystem` | 公会 |
| `useMuseumStore` | `MuseumSystem` | 博物馆 |
| `useWalletStore` | `WalletSystem` | 钱包物品 |
| `useWarehouseStore` | `WarehouseSystem` | 仓库 |
| `useBreedingStore` | `BreedingSystem` | 育种 |
| `useFishPondStore` | `FishPondSystem` | 鱼塘 |
| `useHanhaiStore` | `HanhaiSystem` | 沙漠/赌场 |
| `useShopStore` | `ShopSystem` | 商店 |
| `useSettingsStore` | `SettingsManager` | 设置 |
| `useTutorialStore` | `TutorialSystem` | 教程 |

### 3.3 数据资源系统

#### Vue Data → Godot Resource

**Vue.js 数据文件:**
```typescript
// data/crops.ts
export interface CropDef {
  id: string
  name: string
  seedId: string
  season: Season[]
  growthDays: number
  sellPrice: number
  seedPrice: number
}

export const CROPS: CropDef[] = [
  { id: 'turnip', name: '芜菁', season: ['spring'], growthDays: 4, sellPrice: 35, seedPrice: 10 },
  // ...
]
```

**Godot 4 Resource:**
```csharp
// CropDef.cs
using Godot;
using System;

[GlobalClass]
public partial class CropDef : Resource
{
    [Export] public string Id { get; set; }
    [Export] public string Name { get; set; }
    [Export] public string SeedId { get; set; }
    [Export] public Season[] Seasons { get; set; }
    [Export] public int GrowthDays { get; set; }
    [Export] public int SellPrice { get; set; }
    [Export] public int SeedPrice { get; set; }
}

// crops.tres (CSV转换或手写)
[gd_resource type="Resource" load_steps=40 format=3]
```

**数据批量转换方案:**
```
1. 将 data/*.ts 转换为 CSV 格式
2. 编写 Godot Editor 插件读取 CSV 生成 .tres 文件
3. 或使用 Godot 的 GDScript/C# CSV 解析器在运行时加载
```

### 3.4 游戏数据清单

| 数据文件 | Godot Resource | 记录数 |
|----------|----------------|--------|
| `crops.ts` | `crops.tres` | 38种作物 |
| `animals.ts` | `animals.tres` | 19种动物 |
| `npcs.ts` | `npcs.tres` | 34个NPC |
| `hiddenNpcs.ts` | `hidden_npcs.tres` | 6个隐藏NPC |
| `fish.ts` | `fish.tres` | 60种鱼 |
| `recipes.ts` | `recipes.tres` | 113个食谱 |
| `buildings.ts` | `buildings.tres` | 建筑定义 |
| `farmMaps.ts` | `farm_maps.tres` | 6种农场地图 |
| `events.ts` | `events.tres` | 季节事件 |
| `heartEvents.ts` | `heart_events.tres` | 爱心事件 |
| `quests.ts` | `quests.tres` | 支线任务 |
| `storyQuests.ts` | `story_quests.tres` | 主线任务 |
| `achievements.ts` | `achievements.tres` | 109个成就 |
| `weapons.ts` | `weapons.tres` | 武器 |
| `hats.ts` | `hats.tres` | 帽子 |
| `shoes.ts` | `shoes.tres` | 鞋子 |
| `rings.ts` | `rings.tres` | 戒指 |
| `guild.ts` | `guild.tres` | 公会配置 |
| `shops.ts` | `shops.tres` | 商店库存 |
| `mine.ts` | `mine.tres` | 矿物数据 |
| `processing.ts` | `processing.tres` | 机器配置 |
| `breeding.ts` | `breeding.tres` | 杂交育种 |
| `fishPond.ts` | `fish_pond.tres` | 鱼塘配置 |
| `hanhai.ts` | `hanhai.tres` | 沙漠配置 |
| `travelingMerchant.ts` | `traveling_merchant.tres` | 旅行商人 |
| `forage.ts` | `forage.tres` | 采集物 |
| `museum.ts` | `museum.tres` | 博物馆 |
| `wildTrees.ts` | `wild_trees.tres` | 野生树木 |
| `fruitTrees.ts` | `fruit_trees.tres` | 果树 |
| `upgrades.ts` | `upgrades.tres` | 升级配置 |
| `themes.ts` | `themes.tres` | 主题配色 |

---

## 4. UI 系统移植

### 4.1 视图结构映射

| Vue View | Godot Scene | 复杂度 |
|----------|-------------|--------|
| `MainMenu.vue` | `MainMenu.tscn` | 低 |
| `GameLayout.vue` | `GameRoot.tscn` | 高 |
| `FarmView.vue` | `FarmScene.tscn` | 高 |
| `VillageView.vue` | `VillageScene.tscn` | 高 |
| `ShopView.vue` | `ShopScene.tscn` | 中 |
| `MiningView.vue` | `MiningScene.tscn` | 高 |
| `FishingView.vue` | `FishingScene.tscn` | 中 |
| `CookingView.vue` | `CookingScene.tscn` | 中 |
| `AnimalView.vue` | `AnimalScene.tscn` | 中 |
| `HomeView.vue` | `HomeScene.tscn` | 中 |
| `ProcessingView.vue` | `WorkshopScene.tscn` | 中 |
| `BreedingView.vue` | `BreedingScene.tscn` | 中 |
| `FishPondView.vue` | `FishPondScene.tscn` | 中 |
| `GuildView.vue` | `GuildScene.tscn` | 中 |
| `MuseumView.vue` | `MuseumScene.tscn` | 中 |
| `HanhaiView.vue` | `HanhaiScene.tscn` | 高 |
| `QuestView.vue` | `QuestScene.tscn` | 中 |
| `AchievementView.vue` | `AchievementScene.tscn` | 中 |
| `InventoryView.vue` | `InventoryScene.tscn` | 中 |
| `SkillView.vue` | `SkillScene.tscn` | 中 |
| `ToolUpgradeView.vue` | `UpgradeScene.tscn` | 低 |
| `WalletView.vue` | `WalletScene.tscn` | 低 |
| `ForageView.vue` | `ForageScene.tscn` | 中 |
| `CharInfoView.vue` | `CharacterInfo.tscn` | 低 |
| `SaveManager.vue` | `SaveLoadDialog.tscn` | 中 |

### 4.2 Dialog 组件映射

| Vue Component | Godot Scene | 用途 |
|---------------|-------------|------|
| `EventDialog.vue` | `EventDialog.tscn` | 季节事件 |
| `HeartEventDialog.vue` | `HeartEventDialog.tscn` | NPC爱心事件 |
| `PerkSelectDialog.vue` | `PerkSelectDialog.tscn` | 技能天赋选择 |
| `SettingsDialog.vue` | `SettingsDialog.tscn` | 设置面板 |
| `HiddenNpcModal.vue` | `HiddenNpcDialog.tscn` | 隐藏NPC交互 |
| `StatusBar.vue` | `HUD.tscn` (内嵌) | 状态栏 |

### 4.3 小游戏映射

| Mini Game | Godot Scene | 类型 |
|-----------|-------------|------|
| `FishingMiniGame.vue` | `FishingMiniGame.tscn` | 实时物理 |
| `TexasHoldemGame.vue` | `TexasHoldem.tscn` | 卡牌桌游 |
| `BuckshotRouletteGame.vue` | `BuckshotRoulette.tscn` | 俄罗斯轮盘 |
| `DragonBoatView.vue` | `DragonBoat.tscn` | 节日小游戏 |
| `FishingContestView.vue` | `FishingContest.tscn` | 钓鱼比赛 |
| `LanternRiddleView.vue` | `LanternRiddle.tscn` | 猜灯谜 |
| `PotThrowingView.vue` | `PotThrowing.tscn` | 投壶 |
| `DumplingMakingView.vue` | `DumplingMaking.tscn` | 包饺子 |
| `FireworkShowView.vue` | `FireworkShow.tscn` | 烟花秀 |
| `TeaContestView.vue` | `TeaContest.tscn` | 品茶会 |
| `KiteFlyingView.vue` | `KiteFlying.tscn` | 放风筝 |

---

## 5. 核心游戏系统详解

### 5.1 时间系统

**当前实现 (timeConstants.ts):**
```typescript
export const DAY_START_HOUR = 6
export const DAY_END_HOUR = 26  // 2:00 AM next day
export const HOUR_DURATION_MS = 700  // 1 game hour = 700ms real time
```

**Godot 移植方案:**
```csharp
// GameClock.cs
public partial class GameClock : Node
{
    [Signal] public delegate void HourChangedEventHandler(int hour);
    [Signal] public delegate void DayChangedEventHandler(int day, Season season);
    [Signal] public delegate void SeasonChangedEventHandler(Season season);

    private Timer _tickTimer;
    private const int DayStartHour = 6;
    private const int DayEndHour = 26;
    private const float TickInterval = 0.7f;  // seconds

    public override void _Ready()
    {
        _tickTimer = new Timer();
        _tickTimer.WaitTime = TickInterval;
        _tickTimer.Timeout += OnTick;
        AddChild(_tickTimer);
        _tickTimer.Start();
    }

    public void SetTimeScale(float scale) { ... }
    public void Pause() { _tickTimer.Stop(); }
    public void Resume() { _tickTimer.Start(); }
}
```

### 5.2 天气系统

**天气概率配置:**
```csharp
// WeatherSystem.cs
public static readonly Dictionary<Season, WeatherProbability[]> WeatherProbabilities = new()
{
    { Season.Spring, new[] {
        new WeatherProbability(Weather.Sunny, 0.50f),
        new WeatherProbability(Weather.Rainy, 0.25f),
        new WeatherProbability(Weather.Stormy, 0.10f),
        new WeatherProbability(Weather.Windy, 0.15f)
    }},
    // Summer, Autumn, Winter...
};

public void GenerateDailyWeather(Season season)
{
    // 随机选择天气
}
```

### 5.3 位置/导航系统

**Vue (useNavigation.ts):**
```typescript
type PanelKey = 'farm' | 'village' | 'shop' | 'mining' | 'fishing' | ...

interface TravelCost {
  staminaCost: number
  timeCost: number  // hours
}

const TRAVEL_COSTS: Record<PanelKey, TravelCost> = {
  farm: { staminaCost: 0, timeCost: 0 },
  village: { staminaCost: 1, timeCost: 0.17 },
  mine: { staminaCost: 3, timeCost: 0.33 },
  hanhai: { staminaCost: 5, timeCost: 0.5 },
}
```

**Godot:**
```csharp
// NavigationSystem.cs
public enum PanelKey { Farm, Village, Shop, Mining, Fishing, ... }

public struct TravelCost
{
    public float StaminaCost;
    public float TimeCost;
}

public static readonly Dictionary<PanelKey, TravelCost> TravelCosts = new()
{
    { PanelKey.Farm, new TravelCost { StaminaCost = 0, TimeCost = 0 } },
    { PanelKey.Village, new TravelCost { StaminaCost = 1, TimeCost = 0.17f } },
    { PanelKey.Mining, new TravelCost { StaminaCost = 3, TimeCost = 0.33f } },
    { PanelKey.Hanhai, new TravelCost { StaminaCost = 5, TimeCost = 0.5f } },
};

public void TravelTo(PanelKey target)
{
    var cost = TravelCosts[target];
    PlayerState.Instance.ConsumeStamina(cost.StaminaCost);
    GameState.Instance.AdvanceTimeByHours(cost.TimeCost);
    SceneManager.LoadScene(target.ToString());
}
```

### 5.4 农业系统

**核心数据结构:**
```csharp
// FarmPlot.cs
public partial class FarmPlot : Node2D
{
    [Export] public int PlotId { get; set; }
    [Export] public PlotState State { get; set; } = PlotState.Empty;
    [Export] public string CropId { get; set; }
    [Export] public int GrowthDaysElapsed { get; set; }
    [Export] public bool IsWatered { get; set; }
    [Export] public bool IsFertilized { get; set; }
    [Export] public FertilizerType? Fertilizer { get; set; }

    public void Till() { ... }
    public void Plant(string seedId) { ... }
    public void Water() { ... }
    public Variant Harvest() { ... }  // 返回收获物品或null
    public void DailyUpdate() { ... }
}

public enum PlotState { Empty, Tilled, Planted, Growing, Ready, Withered }
```

### 5.5 库存系统

```csharp
// InventorySystem.cs
public partial class InventorySystem : Node
{
    [Signal] public delegate void InventoryChangedEventHandler();

    private Array<InventoryItem> _items = new();
    private Dictionary<string, int> _tools = new();
    private Array<string> _weapons = new();
    private Array<string> _hats = new();
    private Array<string> _shoes = new();
    private Array<string> _rings = new();

    public bool AddItem(string itemId, int quantity = 1, ItemQuality quality = ItemQuality.Normal)
    {
        // 查找已有叠加或空槽
    }

    public bool RemoveItem(string itemId, int quantity = 1) { ... }
    public bool HasItem(string itemId, int quantity = 1) { ... }
    public int GetItemCount(string itemId) { ... }
    public Array<InventoryItem> GetAllItems() => _items;
}

public partial class InventoryItem : Resource
{
    [Export] public string ItemId { get; set; }
    [Export] public int Quantity { get; set; }
    [Export] public ItemQuality Quality { get; set; }
}
```

### 5.6 技能系统

```csharp
// SkillSystem.cs
public partial class SkillSystem : Node
{
    [Signal] public delegate void SkillLevelUpEventHandler(SkillType type, int newLevel);

    private Dictionary<SkillType, SkillState> _skills = new();

    public void AddExp(SkillType type, int amount)
    {
        var skill = _skills[type];
        skill.Exp += amount;
        CheckLevelUp(type);
    }

    private void CheckLevelUp(SkillType type)
    {
        // 根据经验值计算是否升级
        // 触发升级时显示天赋选择对话框
    }
}

public partial class SkillState : Resource
{
    [Export] public SkillType Type { get; set; }
    [Export] public int Level { get; set; } = 1;
    [Export] public int Exp { get; set; }
    [Export] public SkillPerk5? Perk5 { get; set; }
    [Export] public SkillPerk10? Perk10 { get; set; }
}

// 经验值曲线
public static readonly int[] LevelThresholds = { 0, 100, 280, 530, 870, 1350, ... };
```

### 5.7 NPC系统

```csharp
// NPCSystem.cs
public partial class NPCSystem : Node
{
    private Dictionary<string, NPCState> _npcStates = new();

    public void AdjustFriendship(string npcId, int amount)
    {
        var state = _npcStates[npcId];
        state.Friendship += amount;
        state.Friendship = Mathf.Clamp(state.Friendship, 0, 2500);

        if (state.Friendship >= 2500) state.FriendshipLevel = FriendshipLevel.BestFriend;
        // ... 其他等级判断
    }

    public void GiftTo(string npcId, string itemId)
    {
        // 根据物品类型和NPC喜好调整好感度
    }

    public bool CanTriggerHeartEvent(string npcId, int heartLevel)
    {
        // 检查是否满足爱心事件触发条件
    }
}

public partial class NPCState : Resource
{
    [Export] public string NPCId { get; set; }
    [Export] public int Friendship { get; set; }
    [Export] public FriendshipLevel FriendshipLevel { get; set; }
    [Export] public bool TalkedToday { get; set; }
    [Export] public bool GiftedToday { get; set; }
    [Export] public bool IsDating { get; set; }
    [Export] public bool IsMarried { get; set; }
    [Export] public Array<string> TriggeredHeartEvents { get; set; }
}
```

### 5.8 事件系统

```csharp
// EventManager.cs (Autoload)
public partial class EventManager : Node
{
    [Signal] public delegate void EventStartedEventHandler(BaseEvent evt);
    [Signal] public delegate void EventEndedEventHandler();

    private BaseEvent _currentEvent;
    private int _currentSceneIndex;
    private Array<BaseEvent> _pendingEvents = new();

    public void StartEvent(BaseEvent evt)
    {
        _currentEvent = evt;
        _currentSceneIndex = 0;
        EmitSignal(SignalName.EventStarted, evt);
        ShowDialog(evt.Scenes[0]);
    }

    public void AdvanceDialog()
    {
        _currentSceneIndex++;
        if (_currentSceneIndex >= _currentEvent.Scenes.Count)
        {
            EndEvent();
        }
        else
        {
            ShowDialog(_currentEvent.Scenes[_currentSceneIndex]);
        }
    }

    public void MakeChoice(int choiceIndex)
    {
        var scene = _currentEvent.Scenes[_currentSceneIndex];
        var choice = scene.Choices[choiceIndex];
        // 应用选择效果（好感度变化等）
        AdvanceDialog();
    }
}

// 事件定义
public partial class BaseEvent : Resource
{
    [Export] public string Id { get; set; }
    [Export] public EventType Type { get; set; }
    [Export] public Array<EventScene> Scenes { get; set; }
}

public partial class EventScene : Resource
{
    [Export] public string Text { get; set; }
    [Export] public Array<EventChoice> Choices { get; set; }  // 可空
    [Export] public string Portrait { get; set; }
}
```

### 5.9 存档系统

```csharp
// SaveManager.cs (Autoload)
public partial class SaveManager : Node
{
    private const string SavePrefix = "taoyuanxiang_save_";
    private const string EncryptionKey = "taoyuanxiang_2024_secret";
    private const int MaxSlots = 3;

    public bool SaveToSlot(int slotIndex, GameSaveData data)
    {
        var path = GetSavePath(slotIndex);
        var json = Json.Stringify(data.ToDict());
        var encrypted = Encrypt(json);
        return FileAccess.Write(path) != null;
    }

    public GameSaveData LoadFromSlot(int slotIndex)
    {
        var path = GetSavePath(slotIndex);
        var encrypted = FileAccess.GetFileAsString(path);
        var json = Decrypt(encrypted);
        return Json.ParseString(json).AsGodotDictionary();
    }

    public void AutoSave()
    {
        var activeSlot = SettingsManager.Instance.ActiveSaveSlot;
        SaveToSlot(activeSlot, CollectSaveData());
    }

    public void ExportSave(int slotIndex, string exportPath)
    {
        var data = LoadFromSlot(slotIndex);
        var json = Json.Stringify(data.ToDict());
        FileAccess.WriteAllBytes(exportPath, Encrypt(json).ToUtf8Buffer());
    }

    public bool ImportSave(string importPath)
    {
        // 导入.tyx文件
    }
}

public partial class GameSaveData : Resource
{
    [Export] public Dictionary GameData { get; set; }
    [Export] public Dictionary PlayerData { get; set; }
    [Export] public Dictionary InventoryData { get; set; }
    [Export] public Dictionary FarmData { get; set; }
    // ... 所有其他系统数据
    [Export] public string SavedAt { get; set; }
}
```

---

## 6. 音频系统

### 6.1 当前实现 (Tone.js)

**Vue composables/useAudio.ts:**
- 程序化音频合成，无需音频文件
- SFX: blip, water, plant, harvest, click, coin 等
- BGM: 19首曲目，按场景/季节/天气变化

### 6.2 Godot 移植方案

**Godot 音频架构:**
```
res://assets/audio/
├── bgm/
│   ├── spring_morning.ogg
│   ├── summer_afternoon.ogg
│   ├── autumn_rain.ogg
│   └── ...
└── sfx/
    ├── ui/
    │   ├── click.wav
    │   ├── menu_select.wav
    │   └── ...
    ├── farming/
    │   ├── plant.wav
    │   ├── harvest.wav
    │   ├── water.wav
    │   └── till.wav
    └── ...
```

**AudioManager.cs:**
```csharp
// AudioManager.cs (Autoload)
public partial class AudioManager : Node
{
    private AudioStreamPlayer _bgmPlayer;
    private AudioStreamPlayer _sfxPlayer;
    private Dictionary<string, AudioStream> _bgmCache = new();
    private Dictionary<string, AudioStream> _sfxCache = new();

    public float BgmVolume { get; set; } = 0.15f;
    public float SfxVolume { get; set; } = 0.3f;

    public override void _Ready()
    {
        _bgmPlayer = new AudioStreamPlayer();
        _sfxPlayer = new AudioStreamPlayer();
        AddChild(_bgmPlayer);
        AddChild(_sfxPlayer);
    }

    public void PlayBgm(string bgmName)
    {
        // 渐变切换BGM
    }

    public void PlaySfx(string sfxName)
    {
        // 播放音效
    }

    public void PlayFestivalBgm() { ... }
    public void PlayMinigameBgm(string type) { ... }
}
```

**Tone.js → Godot 迁移策略:**
1. 保留程序化 SFX (使用 Godot AudioStreamGenerator)
2. 或录制 Tone.js 输出为 WAV 文件
3. BGM 使用 OGG/Vorbis 格式

---

## 7. 小游戏详细设计

### 7.1 钓鱼小游戏

**参数配置:**
```csharp
public class FishingParams
{
    public float HookHeight { get; set; }
    public float FishSpeed { get; set; }
    public float FishChangeDirFrequency { get; set; }
    public float Gravity { get; set; }
    public float LiftSpeed { get; set; }
    public float ScoreGain { get; set; }
    public float ScoreLoss { get; set; }
    public float TimeLimit { get; set; }
}
```

**难度等级:**
```csharp
public static readonly Dictionary<string, FishingParams> DifficultyParams = new()
{
    { "easy", new FishingParams { FishSpeed = 1.0f, TimeLimit = 20f } },
    { "normal", new FishingParams { FishSpeed = 2.0f, TimeLimit = 15f } },
    { "hard", new FishingParams { FishSpeed = 3.0f, TimeLimit = 12f } },
    { "legendary", new FishingParams { FishSpeed = 4.0f, TimeLimit = 10f } }
};
```

### 7.2 德州扑克

**扑克牌数据结构:**
```csharp
public enum PokerSuit { Spades, Hearts, Clubs, Diamonds }
public enum PokerRank { Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace }

public partial class PokerCard : Resource
{
    [Export] public PokerSuit Suit { get; set; }
    [Export] public PokerRank Rank { get; set; }
    public int Value => (int)Rank + 2;  // 2-14
}

public enum PokerHand
{
    HighCard, OnePair, TwoPair, ThreeKind, Straight,
    Flush, FullHouse, FourKind, StraightFlush, RoyalFlush
}
```

**手牌判定:**
```csharp
public static PokerHand EvaluateHand(Array<PokerCard> hand)
{
    // 从大到小判定
    if (IsRoyalFlush(hand)) return PokerHand.RoyalFlush;
    if (IsStraightFlush(hand)) return PokerHand.StraightFlush;
    if (IsFourOfKind(hand)) return PokerHand.FourKind;
    if (IsFullHouse(hand)) return PokerHand.FullHouse;
    if (IsFlush(hand)) return PokerHand.Flush;
    if (IsStraight(hand)) return PokerHand.Straight;
    if (IsThreeOfKind(hand)) return PokerHand.ThreeKind;
    if (IsTwoPair(hand)) return PokerHand.TwoPair;
    if (IsOnePair(hand)) return PokerHand.OnePair;
    return PokerHand.HighCard;
}
```

### 7.3 左轮赌盘

**游戏规则:**
```csharp
public partial class BuckshotRouletteGame : Control
{
    private Array<ShellType> _chambers = new();
    private int _currentChamber;
    private int _playerHP = 3;
    private int _dealerHP = 3;

    public void SetupGame()
    {
        // 随机装入4发子弹（live/blank）
        // 洗牌
        _currentChamber = 0;
        _playerHP = 3;
        _dealerHP = 3;
    }

    public void ShootOpponent()
    {
        if (_chambers[_currentChamber] == ShellType.Live)
            _dealerHP--;
        else
            PlayBlankSfx();
        _currentChamber++;
        CheckGameEnd();
    }

    public void ShootSelf()
    {
        if (_chambers[_currentChamber] == ShellType.Live)
            _playerHP--;
        else
            PlayBlankSfx();
        _currentChamber++;
        CheckGameEnd();
    }
}

public enum ShellType { Live, Blank }
```

---

## 8. 移植任务分解

### 阶段一：项目基础 (2-3周)

| 任务 | 描述 | 产出 |
|------|------|------|
| 1.1 | 创建 Godot 项目结构 | `project.godot`, 目录结构 |
| 1.2 | 配置导出预设 | Windows/Web/Android 预设 |
| 1.3 | 实现自动加载系统 | 5个核心 Autoload |
| 1.4 | 创建数据 Resource 基类 | `BaseDataResource.cs` |
| 1.5 | 转换核心数据文件 | crops, items, seasons |
| 1.6 | 实现基础 UI 框架 | 主菜单, HUD |

### 阶段二：核心游戏循环 (4-6周)

| 任务 | 描述 | 依赖 |
|------|------|------|
| 2.1 | 时间/天气系统 | 1.3 |
| 2.2 | 玩家移动和控制 | 1.6 |
| 2.3 | 农场场景和地块 | 1.5, 2.1 |
| 2.4 | 农业种植/收获 | 2.3 |
| 2.5 | 背包和库存系统 | 1.3, 1.5 |
| 2.6 | 技能系统 | 2.5 |
| 2.7 | NPC基础互动 | 1.5 |

### 阶段三：游戏系统 (4-6周)

| 任务 | 描述 | 依赖 |
|------|------|------|
| 3.1 | 畜牧系统 | 2.5 |
| 3.2 | 钓鱼系统 | 1.5 |
| 3.3 | 采矿系统 | 1.5 |
| 3.4 | 烹饪系统 | 1.5, 2.6 |
| 3.5 | 加工系统 | 1.5 |
| 3.6 | 商店系统 | 2.5 |
| 3.7 | 事件系统 | 1.3, 2.7 |

### 阶段四：内容和深度 (3-4周)

| 任务 | 描述 | 依赖 |
|------|------|------|
| 4.1 | 所有小游戏 | 2.1 |
| 4.2 | 任务和成就 | 3.7 |
| 4.3 | 隐藏NPC系统 | 2.7 |
| 4.4 | 育种系统 | 3.4 |
| 4.5 | 沙漠/赌场区域 | 1.5 |
| 4.6 | 婚姻和子女系统 | 3.7 |

### 阶段五：打磨和导出 (2-3周)

| 任务 | 描述 | 依赖 |
|------|------|------|
| 5.1 | 存档系统完善 | 全部 |
| 5.2 | 音频系统 | 全部 |
| 5.3 | Android 导出配置 | 全部 |
| 5.4 | Web 导出优化 | 全部 |
| 5.5 | 性能优化 | 全部 |

---

## 9. 关键文件对照表

| Vue.js 源文件 | Godot 4 目标文件 | 行数(估) |
|---------------|------------------|----------|
| `src/stores/useGameStore.ts` | `scripts/autoload/GameState.cs` | ~200 |
| `src/stores/usePlayerStore.ts` | `scripts/autoload/PlayerState.cs` | ~250 |
| `src/stores/useSaveStore.ts` | `scripts/autoload/SaveManager.cs` | ~300 |
| `src/composables/useAudio.ts` | `scripts/autoload/AudioManager.cs` | ~200 |
| `src/composables/useNavigation.ts` | `scripts/systems/NavigationSystem.cs` | ~150 |
| `src/data/crops.ts` | `scripts/data/crops.csv` → `.tres` | ~500 |
| `src/data/npcs.ts` | `scripts/data/npcs.csv` → `.tres` | ~800 |
| `src/views/game/FarmView.vue` | `scenes/game/farm/FarmScene.tscn` | ~500 |
| `src/components/game/FishingMiniGame.vue` | `scenes/mini_games/FishingMiniGame.tscn` | ~400 |
| `src/components/game/TexasHoldemGame.vue` | `scenes/mini_games/TexasHoldem.tscn` | ~500 |

**总代码量估算:**
- Vue.js: ~25,000 行 TypeScript/Vue
- Godot 移植后: ~35,000 行 C#/GDScript (含UI)

---

## 10. 技术决策建议

### 10.1 语言选择

| 方案 | 优点 | 缺点 | 推荐场景 |
|------|------|------|----------|
| **纯 GDScript** | 原生集成、简单易学、热重载 | 性能较低 | 小型项目、UI逻辑 |
| **C# + GDScript** | 性能好、IDE支持好 | 需处理边界 | **推荐大型项目** |
| **C# 为主** | 统一语言、性能最佳 | GDScript组件互调麻烦 | 性能敏感系统 |

**建议:** 核心系统用 C#，UI 和小游戏用 GDScript

### 10.2 数据持久化

| 方案 | 适用场景 |
|------|----------|
| Godot Resource (.tres) | 游戏数据 (crops, items等) |
| JSON | 存档、可编辑配置 |
| SQLite | 大型数据查询 (未来扩展) |

### 10.3 多平台考虑

| 平台 | 特殊处理 |
|------|----------|
| Windows | Steam 集成 (未来) |
| Web | WebDAV、localStorage、触摸输入 |
| Android | 触控、通知、存档迁移 |

### 10.4 与 Vue 版本并行维护

```
taoyuan/
├── godot/                     # Godot 4 移植版本
│   ├── project.godot
│   └── ...
├── web-vue/                   # 保持 Vue 版本更新
│   ├── package.json
│   └── ...
└── docs/
    └── PORTING_GUIDE.md       # 本文档
```

---

## 11. 已知风险和解决方案

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 数据转换工作量大 | 高 | 编写自动化脚本批量转换 |
| UI 重新设计 | 中 | 保持 Vue 版本布局逻辑 |
| 性能调优 | 中 | 尽早进行性能测试 |
| 存档兼容性 | 中 | 实现双向导入/导出 |
| 移动端触控 | 中 | 参考现有移动端适配 |

---

## 12. 附录

### 12.1 枚举类型映射

```csharp
// Season
public enum Season { Spring, Summer, Autumn, Winter }

// Weather
public enum Weather { Sunny, Rainy, Stormy, Snowy, Windy, GreenRain }

// Location
public enum Location { Farm, Village, Shop, BambooForest, Creek, Mine, Home, ... }

// ItemQuality
public enum ItemQuality { Normal, Fine, Excellent, Supreme }

// ItemCategory
public enum ItemCategory { Seed, Crop, Fish, Ore, Gem, Gift, Food, Material,
    Misc, Processed, Machine, Sprinkler, Fertilizer, AnimalProduct,
    Sapling, Fruit, Bait, Tackle, Bomb, Fossil, Artifact, Weapon,
    Ring, Hat, Shoe }

// SkillType
public enum SkillType { Farming, Foraging, Fishing, Mining, Combat }

// FriendshipLevel
public enum FriendshipLevel { Stranger, Acquaintance, Friendly, BestFriend }
```

### 12.2 数据转换脚本示例

```python
# tools/csv_to_godot_resource.py
# 将 TS 数据文件转换为 Godot CSV/JSON

import json
import csv
from pathlib import Path

def convert_crops(input_file: str, output_dir: str):
    """将 crops.ts 转换为 Godot CSV"""
    # 解析 TypeScript
    # 提取 CropDef 数组
    # 输出 CSV
    pass
```

### 12.3 资源链接

- [Godot 4.6 文档](https://docs.godotengine.org/en/stable/)
- [Godot C# 教程](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/)
- [Godot 迁移指南](https://docs.godotengine.org/en/stable/tutorials/migrating/)
- [Godot GitHub](https://github.com/godotengine/godot)

---

*文档生成时间: 2026-04-03*
*原始项目: 桃源乡 Vue.js v1.0*
*目标项目: 桃源乡 Godot 4.6*
