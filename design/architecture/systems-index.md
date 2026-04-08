# 桃源乡 (Taoyuan) - Systems Index

> Godot 4.6 移植项目 - 系统索引

## 项目概述

**项目**: 桃源乡 Vue.js → Godot 4.6 移植
**基于**: `PROJECT_DOCUMENTATION.md` + `GODOT_PORTING_GUIDE.md`
**创建日期**: 2026-04-03
**最后更新**: --

---

## 1. 系统枚举

### 1.1 Foundation 系统 (5个)

| ID | 系统名称 | 英文名 | 描述 | 显性/隐性 |
|----|----------|--------|------|-----------|
| F01 | 时间/季节系统 | TimeSeasonSystem | 游戏时钟、日期推进、季节切换 (6:00-2:00, 28天/季) | 显性 |
| F02 | 天气系统 | WeatherSystem | 每日天气生成 (晴/雨/暴风雨/雪/风/绿雨) | 显性 |
| F03 | 物品数据系统 | ItemDataSystem | 所有物品定义资源 (40+ 数据文件) | 显性 |
| F04 | 存档系统 | SaveLoadSystem | AES加密、3存档槽、WebDAV同步 | 显性 |
| F05 | 音效系统 | AudioSystem | 80+SFX、19BGM、Tone.js → Godot迁移 | 显性 |

### 1.2 Core 系统 (8个)

| ID | 系统名称 | 英文名 | 描述 | 显性/隐性 |
|----|----------|--------|------|-----------|
| C01 | 玩家属性系统 | PlayerStatsSystem | HP、体力 (156上限)、金钱 (开局500) | 显性 |
| C02 | 库存系统 | InventorySystem | 物品管理、背包 (30格+扩展)、仓库 | 显性 |
| C03 | 技能系统 | SkillSystem | 5技能 (农/采/钓/矿/战), 10级, 天赋 | 显性 |
| C04 | 农场地块系统 | FarmPlotSystem | 耕地、播种、浇水、施肥、收获 | 显性 |
| C05 | 导航系统 | NavigationSystem | 地图切换、移动消耗 (体力/时间) | 隐性 |
| C06 | 建筑升级系统 | BuildingUpgradeSystem | farmhouse升级、温室、地窖、洞穴 | 显性 |
| C07 | NPC好感度系统 | NPCFriendshipSystem | 34 NPC、礼物、爱心事件、关系等级 | 显性 |
| C08 | 武器装备系统 | EquipmentSystem | 武器/帽子/鞋子/戒指、套装效果、附魔 | 显性 |

### 1.3 Feature 系统 (19个)

| ID | 系统名称 | 英文名 | 描述 | 显性/隐性 |
|----|----------|--------|------|-----------|
| P01 | 畜牧系统 | AnimalHusbandrySystem | 19动物、鸡舍/谷仓、产蛋/奶 | 显性 |
| P02 | 钓鱼系统 | FishingSystem | 60鱼、6地点、时机小游戏 | 显性 |
| P03 | 采矿系统 | MiningSystem | 120层、6区域、Boss战斗 | 显性 |
| P04 | 烹饪系统 | CookingSystem | 113食谱、5天buff效果 | 显性 |
| P05 | 加工系统 | ProcessingSystem | 21机器、150+配方 | 显性 |
| P06 | 商店系统 | ShopSystem | 种子/工具/商品购买 | 显性 |
| P07 | 隐藏NPC系统 | HiddenNPCSystem | 6隐藏精灵、发现机制、羁绊 | 显性 |
| P08 | 任务系统 | QuestSystem | 支线任务 + 主线任务 | 显性 |
| P09 | 成就系统 | AchievementSystem | 109成就、社区中心 bundles | 显性 |
| P10 | 公会系统 | GuildSystem | 冒险者公会、21目标、贡献点 | 显性 |
| P11 | 博物馆系统 | MuseumSystem | 40+物品捐赠、里程碑奖励 | 显性 |
| P12 | 育种系统 | BreedingSystem | 种子杂交、400+杂交种 | 显性 |
| P13 | 鱼塘系统 | FishPondSystem | 鱼塘养殖、水质、繁殖 | 显性 |
| P14 | 沙漠/赌场系统 | HanhaiCasinoSystem | 汉海区域、德州扑克、左轮赌 | 显性 |
| P15 | 对话/事件系统 | DialogueEventSystem | NPC对话、爱心事件、季节事件 | 显性 |
| P16 | 地图系统 | FarmMapSystem | 6种农场地图变体 | 显性 |
| P17 | 旅行商人系统 | TravelingMerchantSystem | 随机商品、限时抢购 | 隐性 |
| P18 | 市场系统 | MarketSystem | 每日物价波动、供需影响 | 隐性 |
| P19 | 秘密笔记系统 | SecretNoteSystem | 秘密笔记收集、解谜线索 | 显性 |

### 1.4 Presentation 系统 (UI)

| ID | 系统名称 | 英文名 | 对应游戏系统 |
|----|----------|--------|-------------|
| U01 | HUD系统 | HUDSystem | 全局 |
| U02 | 农场UI | FarmUI | 农场地块 |
| U03 | 背包UI | InventoryUI | 库存 |
| U04 | 技能UI | SkillUI | 技能 |
| U05 | NPC对话框 | NPCDialogUI | NPC好感度、对话/事件 |
| U06 | 商店UI | ShopUI | 商店 |
| U07 | 地图UI | MapUI | 导航 |
| U08 | 钓鱼UI | FishingUI | 钓鱼 |
| U09 | 采矿UI | MiningUI | 采矿 |
| U10 | 烹饪UI | CookingUI | 烹饪 |
| U11 | 设置UI | SettingsUI | 设置 |
| U12 | 存档UI | SaveLoadUI | 存档 |
| U13 | 成就UI | AchievementUI | 成就 |
| U14 | 任务UI | QuestUI | 任务 |
| U15 | 公会UI | GuildUI | 公会 |
| U16 | 博物馆UI | MuseumUI | 博物馆 |

### 1.5 Mini-game 系统

| ID | 系统名称 | 英文名 | 描述 |
|----|----------|--------|------|
| M01 | 钓鱼小游戏 | FishingMiniGame | 物理时机游戏 |
| M02 | 德州扑克 | TexasHoldemGame | 三档赌注、AI对手 |
| M03 | 左轮赌盘 | BuckshotRouletteGame | 子弹轮盘赌 |
| M04 | 赛龙舟 | DragonBoatGame | 节日小游戏 |
| M05 | 钓鱼比赛 | FishingContestGame | 节日钓鱼竞赛 |
| M06 | 猜灯谜 | LanternRiddleGame | 节日文字游戏 |
| M07 | 投壶 | PotThrowingGame | 节日技巧游戏 |
| M08 | 包饺子 | DumplingMakingGame | 节日小游戏 |
| M09 | 烟花秀 | FireworkShowGame | 节日小游戏 |
| M10 | 品茶会 | TeaContestGame | 节日小游戏 |
| M11 | 放风筝 | KiteFlyingGame | 节日小游戏 |

### 1.6 Meta 系统

| ID | 系统名称 | 英文名 | 描述 |
|----|----------|--------|------|
| X01 | 教程系统 | TutorialSystem | 新手引导、提示系统 |
| X02 | 偏好设置系统 | SettingsSystem | 音量、主题、按键配置 |

---

## 2. 依赖关系图

```
┌──────────────────────────────────────────────────────────────────┐
│  FOUNDATION (F01-F05)                                            │
│  时间 ← 天气, 存档, 设置, 音效                                     │
│  物品数据 ← 所有内容系统                                           │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│  CORE (C01-C08)                                                  │
│  玩家属性 ← 技能, 装备, 导航                                       │
│  库存 ← 商店, 畜牧, 钓鱼, 采矿, 烹饪, 加工                          │
│  农场地块 ← 畜牧, 育种                                             │
│  技能 ← 成就                                                      │
│  NPC好感度 ← 对话/事件, 隐藏NPC, 任务                               │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│  FEATURE (P01-P19)                                               │
│  畜牧 ← 鱼塘                                                      │
│  钓鱼 ← 鱼塘                                                      │
│  采矿 ← 公会                                                      │
│  商店 ← 旅行商人, 市场                                             │
│  任务 ← 成就                                                      │
└──────────────────────────────────────────────────────────────────┘
```

### 依赖矩阵

| 系统 | 依赖 |
|------|------|
| F01 时间/季节 | - |
| F02 天气 | F01 |
| F03 物品数据 | - |
| F04 存档 | F01, F02, C01, C02 |
| F05 音效 | - |
| C01 玩家属性 | F01, F02, F03 |
| C02 库存 | F03, C01 |
| C03 技能 | C01, F01 |
| C04 农场地块 | F03, C03 |
| C05 导航 | F01, C01 |
| C06 建筑升级 | F03, C02 |
| C07 NPC好感度 | F03, C01 |
| C08 武器装备 | F03, C02 |
| P01 畜牧 | C04, C02, F03 |
| P02 钓鱼 | C02, F03 |
| P03 采矿 | C02, C08 |
| P04 烹饪 | C02, C03, F03 |
| P05 加工 | C02, F03 |
| P06 商店 | C02, C01 |
| P07 隐藏NPC | C07 |
| P08 任务 | C07, F03 |
| P09 成就 | C03, P01, P02, P03, P04, P08 |
| P10 公会 | P03, C08 |
| P11 博物馆 | F03 |
| P12 育种 | C04, F03 |
| P13 鱼塘 | P02, F03 |
| P14 沙漠/赌场 | C01, C02 |
| P15 对话/事件 | C07, C01 |
| P16 地图 | F01, F02 |
| P17 旅行商人 | F01, P06 |
| P18 市场 | F01 |
| P19 秘密笔记 | F03 |

---

## 3. 高风险系统

| 优先级 | 系统 | 风险原因 |
|--------|------|----------|
| 🔴 高 | F01 时间/季节 | 被15+系统依赖，错误影响全局 |
| 🔴 高 | F03 物品数据 | 被12+系统依赖，数据结构要稳健 |
| 🔴 高 | C02 库存 | 8+活动系统依赖，接口要清晰 |
| 🟡 中 | F04 存档 | 跨版本兼容性，数据迁移 |
| 🟡 中 | C03 技能 | 经验曲线影响平衡 |
| 🟡 中 | P15 对话/事件 | 叙事内容复杂，触发条件多 |

---

## 4. 推荐设计顺序

### Phase 1: Foundation (设计优先级: 最高)
1. F01 时间/季节系统
2. F02 天气系统
3. F03 物品数据系统
4. F04 存档系统
5. F05 音效系统

### Phase 2: Core (设计优先级: 高)
6. C01 玩家属性系统
7. C02 库存系统
8. C03 技能系统
9. C04 农场地块系统
10. C05 导航系统
11. C06 建筑升级系统
12. C07 NPC好感度系统
13. C08 武器装备系统

### Phase 3: Feature - 内容系统
14. P06 商店系统
15. P01 畜牧系统
16. P02 钓鱼系统
17. P03 采矿系统
18. P04 烹饪系统
19. P05 加工系统

### Phase 4: Feature - 社交系统
20. P15 对话/事件系统
21. P07 隐藏NPC系统
22. P08 任务系统
23. P09 成就系统

### Phase 5: Feature - 高级系统
24. P10 公会系统
25. P11 博物馆系统
26. P12 育种系统
27. P13 鱼塘系统
28. P14 沙漠/赌场系统
29. P16 地图系统
30. P17 旅行商人系统
31. P18 市场系统
32. P19 秘密笔记系统

### Phase 6: Presentation & Polish
33. UI 系统 (U01-U16)
34. Mini-game 系统 (M01-M11)
35. X01 教程系统
36. X02 偏好设置系统

---

## 5. 进度追踪

| ID | 系统 | 状态 | GDD 文件 | 完成日期 |
|----|------|------|----------|----------|
| F01 | 时间/季节系统 | Implemented | design/gdd/foundation/time-season-system.md | 2026-04-03 |
| F02 | 天气系统 | Approved | design/gdd/foundation/weather-system.md | 2026-04-03 |
| F03 | 物品数据系统 | Approved | design/gdd/foundation/item-data-system.md | 2026-04-03 |
| F04 | 存档系统 | Approved | design/gdd/foundation/save-load-system.md | 2026-04-03 |
| F05 | 音效系统 | Approved | design/gdd/foundation/audio-system.md | 2026-04-03 |
| C01 | 玩家属性系统 | Approved | design/gdd/core/player-stats-system.md | 2026-04-03 |
| C02 | 库存系统 | Approved | design/gdd/core/inventory-system.md | 2026-04-03 |
| C03 | 技能系统 | Approved | design/gdd/core/skill-system.md | 2026-04-03 |
| C04 | 农场地块系统 | Approved | design/gdd/core/farm-plot-system.md | 2026-04-03 |
| C05 | 导航系统 | Approved | design/gdd/core/navigation-system.md | 2026-04-03 |
| C06 | 建筑升级系统 | Approved | design/gdd/core/building-upgrade-system.md | 2026-04-03 |
| C07 | NPC好感度系统 | Approved | design/gdd/core/npc-friendship-system.md | 2026-04-03 |
| C08 | 武器装备系统 | Approved | design/gdd/core/weapon-equipment-system.md | 2026-04-07 |
| P01 | 畜牧系统 | Approved | design/gdd/feature/animal-husbandry-system.md | 2026-04-07 |
| P02 | 钓鱼系统 | Approved | design/gdd/feature/fishing-system.md | 2026-04-07 |
| P03 | 采矿系统 | Approved | design/gdd/feature/mining-system.md | 2026-04-07 |
| P04 | 烹饪系统 | Approved | design/gdd/feature/cooking-system.md | 2026-04-07 |
| P05 | 加工系统 | Approved | design/gdd/feature/processing-system.md | 2026-04-07 |
| P06 | 商店系统 | Approved | design/gdd/feature/shop-system.md | 2026-04-07 |
| P07 | 隐藏NPC系统 | Approved | design/gdd/feature/hidden-npc-system.md | 2026-04-07 |
| P08 | 任务系统 | Approved | design/gdd/feature/quest-system.md | 2026-04-07 |
| P09 | 成就系统 | Approved | design/gdd/feature/achievement-system.md | 2026-04-07 |
| P10 | 公会系统 | Approved | design/gdd/feature/guild-system.md | 2026-04-07 |
| P11 | 博物馆系统 | Approved | design/gdd/feature/museum-system.md | 2026-04-07 |
| P12 | 育种系统 | Approved | design/gdd/feature/breeding-system.md | 2026-04-07 |
| P13 | 鱼塘系统 | Approved | design/gdd/feature/fish-pond-system.md | 2026-04-07 |
| P14 | 沙漠/赌场系统 | Approved | design/gdd/feature/hanhai-casino-system.md | 2026-04-07 |
| P15 | 对话/事件系统 | Approved | design/gdd/feature/dialogue-event-system.md | 2026-04-07 |
| P16 | 地图系统 | Approved | design/gdd/feature/farm-map-system.md | 2026-04-07 |
| P17 | 旅行商人系统 | Approved | design/gdd/feature/traveling-merchant-system.md | 2026-04-07 |
| P18 | 市场系统 | Approved | design/gdd/feature/market-system.md | 2026-04-07 |
| P19 | 秘密笔记系统 | Approved | design/gdd/feature/secret-note-system.md | 2026-04-07 |
| U01 | HUD系统 | Approved | design/gdd/ui/hud-system.md | 2026-04-07 |
| M01 | 钓鱼小游戏 | Approved | design/gdd/minigames/fishing-mini-game.md | 2026-04-07 |
| M02 | 德州扑克小游戏 | Approved | design/gdd/minigames/texas-hold-em-game.md | 2026-04-07 |
| M03 | 左轮赌盘小游戏 | Approved | design/gdd/minigames/buckshot-roulette-game.md | 2026-04-07 |
| M04 | 赛龙舟小游戏 | Approved | design/gdd/minigames/dragon-boat-game.md | 2026-04-07 |
| M05 | 钓鱼比赛小游戏 | Approved | design/gdd/minigames/fishing-contest-game.md | 2026-04-07 |
| M06 | 猜灯谜小游戏 | Approved | design/gdd/minigames/lantern-riddle-game.md | 2026-04-07 |
| M07 | 投壶小游戏 | Approved | design/gdd/minigames/pot-throwing-game.md | 2026-04-07 |
| M08 | 包饺子小游戏 | Approved | design/gdd/minigames/dumpling-making-game.md | 2026-04-07 |
| M09 | 烟花秀小游戏 | Approved | design/gdd/minigames/firework-show-game.md | 2026-04-08 |
| M10 | 品茶会小游戏 | Approved | design/gdd/minigames/tea-contest-game.md | 2026-04-08 |
| M11 | 放风筝小游戏 | Approved | design/gdd/minigames/kite-flying-game.md | 2026-04-08 |
| X01 | 教程系统 | Approved | design/gdd/meta/tutorial-system.md | 2026-04-08 |
| X02 | 偏好设置系统 | Approved | design/gdd/meta/settings-system.md | 2026-04-08 |

---

## 6. 架构决策记录 (ADR)

### 6.1 已完成 ADR

| ADR | 标题 | 覆盖系统 | 状态 |
|-----|------|----------|------|
| ADR-0001 | OOP架构模式 | 全部 | ✅ 已完成 |
| ADR-0002 | Autoload系统设计 | F01-F05, Autoload | ✅ 已完成 |
| ADR-0003 | 场景管理与加载策略 | C05, P16, 导航 | ✅ 已完成 |
| ADR-0004 | 存档系统架构 | F04 存档系统 | ✅ 已完成 |
| ADR-0005 | UI/菜单系统架构 | U01-U16, UI | ✅ 已完成 |
| ADR-0006 | 物品与数据系统架构 | F03, C02 物品 | ✅ 已完成 |
| ADR-0007 | 事件/消息系统架构 | 全部系统间通信 | ✅ 已完成 |
| ADR-0008 | 交互系统架构 | C01玩家, P15对话 | ✅ 已完成 |
| ADR-0009 | 音频系统架构 | F05 音效系统 | ✅ 已完成 |
| ADR-0010 | 动画系统架构 | 玩家/NPC动画 | ✅ 已完成 |
| ADR-0011 | 寻路/导航系统 | C05, NPC移动 | ✅ 已完成 |
| ADR-0012 | 天气特效系统 | F02 天气系统 | ✅ 已完成 |
| ADR-0013 | 战斗系统架构 | 采矿Boss | ✅ 已完成 |
| ADR-0014 | 迷你游戏框架 | M01-M11 | ✅ 已完成 |

### 6.2 架构Map图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           桃源乡架构总览                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      全局基础设施层 ✅                             │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │   │
│  │  │ADR-0002 │ │ADR-0004 │ │ADR-0006 │ │ADR-0007 │          │   │
│  │  │Autoload │ │  存档   │ │ 物品数据 │ │  事件   │          │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                           │
│                              ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      游戏逻辑层 ✅                                 │   │
│  │  ┌───────────────────────────────────────────────────────┐      │   │
│  │  │ F01-F05: Foundation    C01-C08: Core              │      │   │
│  │  │ P01-P19: Feature       M01-M11: Mini-games        │      │   │
│  │  └───────────────────────────────────────────────────────┘      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                           │
│                              ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      表现层 ✅                                    │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │   │
│  │  │ADR-0005 │ │ADR-0008 │ │ ADR-0003│ │ ADR-0009│          │   │
│  │  │   UI    │ │  交互   │ │ 场景管理 │ │  音频   │          │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                           │
│                              ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      实体层 ✅                                    │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │   │
│  │  │ADR-0010 │ │ADR-0011 │ │ADR-0012 │ │ADR-0013 │          │   │
│  │  │ 动画系统 │ │ 寻路导航 │ │ 天气特效 │ │ 战斗系统 │          │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                           │
│                              ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      玩法层 ✅                                    │   │
│  │  ┌─────────────────────────────────────────────────────┐      │   │
│  │  │              ADR-0014: 迷你游戏通用框架              │      │   │
│  │  └─────────────────────────────────────────────────────┘      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                           │
│                              ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      架构模式 ✅                                  │   │
│  │  ┌─────────────────────────────────────────────────────┐      │   │
│  │  │ ADR-0001: OOP + 组件模式 (基于Stardew Valley)       │      │   │
│  │  └─────────────────────────────────────────────────────┘      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  图例: ✅ 全部完成                                                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.4 层级依赖关系

```
Layer 1: 全局基础设施 (ADR-0002, 0004, 0006, 0007)
    │
    ├─→ Layer 2: 游戏逻辑 (F01-F05, C01-C08, P01-P19)
    │       │
    │       ├─→ Layer 3: 表现层 (ADR-0003, 0005, 0008)
    │       │       │
    │       │       └─→ Layer 4: 视觉效果 (ADR-0010, 0011, 0012)
    │       │
    │       └─→ Layer 5: 玩法层 (ADR-0013, 0014)
    │
    └─→ Layer 0: 架构基础 (ADR-0001)
```

---

## 7. 参考文档

- **架构决策**: `design/architecture/adr-*.md`
- **引擎参考**: `docs/engine-reference/godot/`
- **Godot技能库**: `.claude/skills/godot-master/`
- **技术偏好**: `.claude/docs/technical-preferences.md`
- **原型验证**: `prototypes/farming-core-loop/REPORT.md`

---

*最后更新: 2026-04-08 (目录结构重组)*
