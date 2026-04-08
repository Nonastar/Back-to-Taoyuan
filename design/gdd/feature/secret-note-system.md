# 秘密笔记系统 (Secret Note System)

> **状态**: Approved
> **Author**: Claude Code
> **Last Updated**: 2026-04-07
> **System ID**: P19
> **Implements Pillar**: 探索与发现

## Overview

秘密笔记系统管理游戏中神秘笔记的收集与解锁机制。玩家通过各种活动（砍树、钓鱼、采矿等）随机发现秘密笔记，每张笔记包含隐晦的诗句或谜语，指向隐藏物品的位置或游戏中的秘密。当玩家收集完所有笔记后，可解锁终极奖励——"桃花源记"隐藏成就和特殊称号。

## Player Fantasy

玩家应该感受到：
- **探索的惊喜感** — 意外发现笔记时的"这是什么意思？"的兴奋
- **解谜的成就感** — 破解笔记含义、找到隐藏物品时的顿悟
- **收集的完整性** — 集齐所有笔记、解锁终极奖励的满足
- **世界的深度** — 笔记暗示这个世界有更多秘密等待发现

**Reference games**: Stardew Valley 的秘密笔记系统是此类玩法的标杆；《瓦尔登湖》的隐世探索感。

## Detailed Design

### Core Rules

#### 1. 笔记发现机制 (事件驱动模型)

**采用事件驱动 (Push Model)**：
- P19 订阅各活动系统发出的信号
- 各活动系统在关键动作完成后发出信号
- P19 收到信号后根据信号类型决定是否发现笔记

| 信号来源 | 信号名称 | 触发条件 | 发现概率 |
|----------|----------|----------|----------|
| P02 钓鱼系统 | `fish_caught(fish_id)` | 成功钓起任意鱼 | 1% |
| P03 采矿系统 | `rock_smashed(rock_id)` | 粉碎任意岩石 | 1.5% |
| C04 农场地块 | `soil_tilled()` | 翻土时 | 1% |
| P01 畜牧系统 | `animal_product_harvested()` | 收获动物产品时 | 0.5% |
| F02 天气系统 | `extreme_weather_entered()` | 暴风雨天气出门 | 5% |
| C07 NPC好感度 | `npc_gift_received(npc_id)` | 好感度事件赠送 | 固定掉落 |
| 任意宝箱系统 | `treasure_opened(location)` | 打开任意宝箱 | 12% |

**注意**: 砍树不发出专用信号，改由 P02/P03 等系统发出 `activity_completed` 信号统一处理。

**发现规则**:
- 每天最多发现 1 张笔记
- 已发现的笔记不会重复出现
- 发现时播放特殊音效并显示笔记获得动画
- 笔记物品自动进入玩家背包

#### 2. 笔记内容结构

```gdscript
class_name SecretNoteDef extends Resource
@export var note_id: int                    # 笔记编号 (1-24)
@export var title: String                    # 标题
@export_multiline var poem: String           # 诗句正文（4句）
@export var hint_type: HintType             # 提示类型
@export var hint_category: String            # 提示类别 (fishing/mining/farming/animal/npc/weather/location)
@export var hint_target: String              # 提示目标ID
@export var hint_target_count: int = 1      # 目标数量
@export var reward_item: String              # 完成奖励物品ID
@export var prerequisite_note: int = 0       # 前置笔记ID（可选）
```

#### 3. 提示类型与完成判定

每个 `HintType` 必须有明确的完成判定逻辑：

| HintType | 完成条件 | 检查方式 |
|----------|----------|----------|
| `item_location` | 玩家背包中存在 `hint_target` 物品 | C02 库存系统查询 `has_item(hint_target)` |
| `npc_location` | 玩家已与 `hint_target` NPC 进行首次对话 | C07 查询 `has_met_npc(hint_target)` |
| `action_count` | 完成指定动作 `hint_target` 累计 `hint_target_count` 次 | F01 时间系统记录动作计数 |
| `collection_all` | 收集 `hint_target` 类别的所有物品 | C02 查询该类别已收集数量 ≥ 总数 |
| `time_locked` | 在 `hint_target` 指定的时间/季节/天气出现 | F01/F02 查询当前时间/季节/天气 |
| `special_location` | 到达 `hint_target` 指定的地图坐标 | C05 导航系统查询位置 |
| `fish_secret` | 在 `hint_target` 秘密钓鱼点成功钓鱼 | P02 查询该秘密点是否被触发 |

**检查时机**:
- 玩家每次进行相关活动时自动检查
- 玩家打开笔记册时批量检查所有笔记
- 每日凌晨重置时批量检查

#### 4. 笔记诗句格式

每张笔记由4句诗组成，使用中国古风意象：

```
示例笔记 #1 (指向矿石):
"深山有灵石，隐于岩壁间。
锤落星火现，光芒映青天。"
→ 指向: 在矿山找到"星光石" (hint_target="starlight_ore", hint_type=item_location)

示例笔记 #7 (指向钓鱼点):
"碧波深处有龙宫，锦鳞游泳乐无穷。
一竿风月无人问，独钓寒潭待相逢。"
→ 指向: 秘密钓鱼点"龙宫" (hint_target="secret_dragon_palace", hint_type=fish_secret)
```

#### 5. 笔记解锁流程

```
活动系统发出信号
        ↓
P19 接收信号 → 检查每日发现上限
        ↓
  随机数判定 → 失败：结束
        ↓
  成功：从对应类别抽取未发现笔记
        ↓
  笔记物品进入背包 + 显示获得动画
        ↓
  存入笔记册 → 玩家解读诗句 → 尝试寻找隐藏内容
        ↓
  完成条件满足 → 触发奖励 → 标记为已解决
        ↓
  全部24张完成 → 终极奖励
```

**笔记册UI**:
- 按编号排列显示所有24张笔记
- 已发现的笔记显示完整诗句
- 未发现的笔记显示"???"
- 已解决的笔记显示"✓ 已完成"状态
- 未解决的笔记显示"○ 未完成"状态

### States and Transitions

#### 单张笔记状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Hidden** | 笔记未被玩家发现 | 游戏开始时所有笔记默认状态 |
| **Discovered** | 笔记已被发现，等待解读 | 玩家通过活动发现笔记 |
| **Solved** | 玩家已解读并完成对应任务 | P19 检测到完成条件满足 |

**单张笔记状态转换图**:
```
[游戏开始]
    ↓
[Hidden] ←———┐
    ↓           │
发现事件         │ (不会回退)
    ↓           │
[Discovered]────┘
    ↓
完成条件满足
    ↓
[Solved]
```

#### 全局进度状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **InProgress** | 正在进行中 | 至少1张笔记被发现 |
| **AllCompleted** | 全部24张笔记已完成 | solved_count == total_count |

#### 发现触发机制 (详细)

**P19 Signal Handler 伪代码**:
```gdscript
func _ready():
    # 订阅各活动系统信号
    P02.fish_caught.connect(_on_fish_caught)
    P03.rock_smashed.connect(_on_rock_smashed)
    # ... 其他信号

func _on_activity_signal(activity_type: String):
    # 检查每日上限
    if daily_discovery_count >= MAX_DISCOVERY_PER_DAY:
        return

    # 获取该活动对应的发现概率
    var chance = ACTIVITY_CHANCE_MAP[activity_type]

    # 天气修正
    chance *= F02.get_weather_modifier()

    # 随机判定
    if randf() > chance:
        return

    # 从对应类别抽取未发现笔记
    var note = _get_random_undiscovered_note(activity_type)
    if note == null:
        return  # 没有未发现的该类别笔记

    # 发现笔记
    _discover_note(note)

func _discover_note(note: SecretNoteDef):
    # 标记已发现
    discovered_notes.append(note.note_id)

    # 每日计数+1
    daily_discovery_count += 1

    # 添加到背包
    C02.add_item(note.item_id, 1)

    # 播放获得动画
    UIEffects.play_note_discover_animation()

    # 发出信号通知其他系统
    note_discovered.emit(note.note_id)
```

### Interactions with Other Systems

| 依赖系统 | 接口类型 | 交互说明 |
|----------|----------|----------|
| **F03 ItemDataSystem** | 硬依赖 | 查询笔记物品定义、奖励物品定义 |
| **C02 InventorySystem** | 硬依赖 | 获得笔记物品、获得奖励物品、查询物品持有状态 |
| **F01 TimeSeasonSystem** | 软依赖 | 季节限制笔记、每日发现计数重置 |
| **F02 WeatherSystem** | 软依赖 | 天气修正发现概率、极端天气触发 |
| **P02 FishingSystem** | 软依赖 | 钓鱼信号、秘密钓鱼点状态 |
| **P03 MiningSystem** | 软依赖 | 采矿信号、隐藏矿石状态 |
| **P01 AnimalHusbandrySystem** | 软依赖 | 动物产品收获信号 |
| **C04 FarmPlotSystem** | 软依赖 | 耕地信号 |
| **C07 NPCFriendshipSystem** | 软依赖 | NPC礼物信号 |

### SecretNoteSystem 提供给下游的 API

```gdscript
class_name SecretNoteSystem extends Node

## 信号定义
signal note_discovered(note_id: int)              # 笔记被发现
signal note_solved(note_id: int)                  # 笔记被解决
signal all_notes_completed()                       # 全部笔记完成

## 笔记发现 (事件驱动，由外部信号触发)
func on_activity_completed(activity_type: String) -> void:
    """由活动系统调用，检查是否发现新笔记"""

func on_treasure_opened(location: String) -> void:
    """由宝箱系统调用"""

func on_npc_gift_received(npc_id: String) -> void:
    """由C07调用，NPC赠送笔记"""

## 笔记状态查询
func is_note_discovered(note_id: int) -> bool:
    """检查笔记是否已发现"""

func is_note_solved(note_id: int) -> bool:
    """检查笔记是否已解决"""

func get_discovered_notes() -> Array[int]:
    """获取所有已发现笔记ID列表"""

func get_solved_notes() -> Array[int]:
    """获取所有已解决笔记ID列表"""

func get_note_def(note_id: int) -> SecretNoteDef:
    """获取笔记定义数据"""

## 完成验证
func check_note_completion(note_id: int) -> bool:
    """检查笔记完成条件是否满足"""

func claim_reward(note_id: int) -> bool:
    """领取笔记奖励，成功返回true"""

func check_all_notes() -> Array[int]:
    """批量检查所有笔记，返回满足完成条件的笔记ID列表"""

## 进度查询
func get_progress() -> Dictionary:
    """返回 {discovered: n, solved: n, total: 24}"""

func is_all_completed() -> bool:
    """检查是否全部完成"""

## 调试接口
func debug_force_discover(note_id: int) -> void:
    """强制发现指定笔记(调试用)"""

func debug_solve_note(note_id: int) -> void:
    """强制完成指定笔记(调试用)"""
```

### SecretNoteSystem 订阅的信号

```gdscript
# P19 订阅以下信号（由其他系统发出）

# P02 钓鱼系统
signal fish_caught(fish_id: String, location: String)

# P03 采矿系统
signal rock_smashed(rock_id: String, location: String)

# P01 畜牧系统
signal animal_product_harvested(product_id: String)

# C04 农场地块系统
signal soil_tilled(location: String)

# F02 天气系统
signal extreme_weather_entered()  # 暴风雨/暴风雪

# C07 NPC好感度系统
signal npc_gift_received(npc_id: String, gift_id: String)

# 宝箱系统 (通用)
signal treasure_opened(location: String)

# C02 库存系统 (用于完成检查)
signal item_added(item_id: String, count: int)
```

## Formulas

### 1. 笔记发现概率

```
actual_chance = base_chance × weather_modifier
```

| 活动类型 | 基础概率 | 发现类别 |
|----------|----------|----------|
| 砍树 | 2% | general |
| 钓鱼 | 1% | fishing |
| 采矿 | 1.5% | mining |
| 耕地 | 1% | farming |
| 牧畜 | 0.5% | animal |
| 极端天气 | 5% | weather |
| NPC赠送 | 100% | npc |
| 宝箱 | 12% | treasure |

**天气修正**:
| 天气 | 修正系数 |
|------|----------|
| 晴天 | 1.0 |
| 雨天 | 1.2 |
| 暴风雨 | 2.0 |
| 雪天 | 1.5 |
| 绿雨 | 1.5 |
| 大风 | 1.0 |

### 2. 奖励物品计算

笔记完成奖励基于隐藏内容的稀有度：

```
reward_value = hidden_content.base_price × reward_multiplier
```

| 隐藏内容类型 | 基础奖励价值 | 修正系数 |
|--------------|--------------|----------|
| 稀有物品 | 物品价值 | 1.0 |
| 秘密钓鱼点 | 特殊鱼×3 | 1.5 |
| 隐藏NPC | 特殊道具 | 2.0 |
| 特殊地点 | 宝石×5 | 1.0 |

### 3. 终极奖励

当全部24张笔记完成后：

```
final_reward = {
    "桃花源记_称号": 1,           # 永久称号
    "桃花源居民_奖杯": 1,          # 博物馆展品
    "神秘种子_×1": 1,             # 可种植的隐藏种子
    "仙灵粉尘_×10": 10            # 稀有制作材料
}
```

## Edge Cases

### 1. 重复发现
- **Problem**: 玩家在同一天多次活动可能触发多次发现
- **Resolution**: 每天最多发现1张笔记，使用 `daily_discovery_count` 计数，超过上限直接忽略所有信号

### 2. 季节限制笔记
- **Problem**: 某些笔记指向的内容只在特定季节出现
- **Resolution**:
  - 诗句中暗示季节（如"春风"=春，"夏雨"=夏）
  - 完成检查时通过 `time_locked` 类型验证当前季节
  - 季节不符时返回 false，不触发奖励

### 3. 已解决笔记再次完成
- **Problem**: 玩家在完成某笔记后再次找到相同隐藏内容
- **Resolution**: `is_note_solved(note_id)` 返回 true 时，跳过奖励发放，仅播放轻量提示"该笔记已完成"

### 4. 存档迁移
- **Problem**: 笔记数量或格式在版本更新时变化
- **Resolution**:
  ```gdscript
  var save_data = {
      "version": 1,  # 版本号用于迁移
      "discovered_notes": [],
      "solved_notes": [],
      "daily_discovery_count": 0,
      "all_completed_flag": false
  }
  ```

### 5. Mod 兼容性
- **Problem**: Mod 可能添加新笔记或修改诗句
- **Resolution**:
  - 笔记数据支持热加载
  - Mod 注册新笔记时追加到 `SecretNoteDef[]` 数组
  - `TOTAL_NOTES` 动态计算为数组长度

### 6. 笔记册 UI 在未完成时打开
- **Problem**: 玩家打开笔记册但还没有任何笔记
- **Resolution**: 显示空笔记册，附带"继续探索吧！"提示，笔记网格全部显示"???"

### 7. 同时完成多个笔记条件
- **Problem**: 玩家可能在同一时间完成多个笔记的隐藏条件
- **Resolution**: `check_all_notes()` 返回所有满足条件的笔记列表，批量处理奖励发放

### 8. 笔记奖励物品已在背包满时
- **Problem**: 背包满时无法获得奖励
- **Resolution**:
  - C02 库存系统发出 `inventory_full` 信号
  - P19 收到信号后将奖励存入"暂存区"
  - 玩家有空间时通过邮箱或提示领取

### 9. 卸载已解决笔记的 Mod
- **Problem**: Mod 卸载后，其添加的笔记奖励无法获取
- **Resolution**:
  - Mod 笔记 ID 带有命名空间前缀 (如 `mod_xxx_note_1`)
  - Mod 卸载时，相应笔记从 `discovered_notes` 和 `solved_notes` 中移除
  - 版本迁移时清理无效笔记

### 10. 全部完成后重复检查
- **Problem**: 玩家每次加载游戏都触发"全部完成"检查
- **Resolution**: 使用 `all_completed_flag` 缓存结果，`set/get` 时更新缓存

### 11. NPC赠送笔记冲突
- **Problem**: 同一张NPC相关笔记被多次赠送
- **Resolution**: NPC赠送笔记时检查 `is_note_discovered(note_id)`，已发现则不重复发放

### 12. 信号顺序依赖
- **Problem**: `item_added` 信号可能在 `item_exists` 检查之前发出
- **Resolution**: P19 在 `check_note_completion` 中延迟一帧执行，或者 C02 保证先更新内部状态再发信号

## Dependencies

### 上游依赖 (P19 依赖其他系统)

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| F03 物品数据系统 | 硬依赖 | 查询笔记物品ID、奖励物品定义 |
| C02 库存系统 | 硬依赖 | 获得笔记物品、获得奖励、查询物品持有 |
| F01 时间/季节系统 | 软依赖 | 季节限制、每日重置 |
| F02 天气系统 | 软依赖 | 天气修正发现概率 |
| P02 钓鱼系统 | 软依赖 | 钓鱼信号、秘密钓鱼点 |
| P03 采矿系统 | 软依赖 | 采矿信号、隐藏矿石 |
| P01 畜牧系统 | 软依赖 | 动物产品收获信号 |
| C04 农场地块 | 软依赖 | 耕地信号 |
| C07 NPC好感度 | 软依赖 | NPC赠送信号 |

### 下游依赖 (其他系统依赖 P19)

无。P19 是独立的探索系统，不被其他系统依赖。

### 双向一致性验证

| 系统 | P19 列出依赖 | 该系统列出依赖 P19 | 状态 |
|------|-------------|-------------------|------|
| F03 物品数据系统 | ✅ | ✅ | 一致 |
| C02 库存系统 | ✅ | ❌ | P19不强制要求C02配合 |
| F01 时间/季节系统 | ✅ | ❌ | P19是软依赖 |
| F02 天气系统 | ✅ | ❌ | P19是软依赖 |
| P02 钓鱼系统 | ✅ | ❌ | P19是软依赖 |
| P03 采矿系统 | ✅ | ❌ | P19是软依赖 |

**说明**: P19 对大多数系统的依赖是"软依赖"——P19 需要知道这些系统发生了什么，但这些系统不需要知道 P19。这是正确的设计，因为笔记发现是额外奖励，不影响核心玩法。

## Tuning Knobs

### 发现概率参数

| 参数 | 默认值 | 范围 | 影响 |
|------|-------|------|------|
| `MAX_DISCOVERY_PER_DAY` | 1 | 0-3 | 每日最大发现数 |
| `TREES_CHANCE` | 0.02 | 0.01-0.05 | 砍树发现概率 |
| `FISHING_CHANCE` | 0.01 | 0.005-0.03 | 钓鱼发现概率 |
| `MINING_CHANCE` | 0.015 | 0.01-0.05 | 采矿发现概率 |
| `FARMING_CHANCE` | 0.01 | 0.005-0.03 | 耕地发现概率 |
| `ANIMAL_CHANCE` | 0.005 | 0.001-0.02 | 牧畜发现概率 |
| `WEATHER_CHANCE` | 0.05 | 0.02-0.10 | 极端天气发现概率 |
| `TREASURE_CHANCE` | 0.12 | 0.05-0.25 | 宝箱发现概率 |

### 天气修正参数

| 参数 | 默认值 | 说明 |
|------|-------|------|
| `WEATHER_SUNNY_MOD` | 1.0 | 晴天修正 |
| `WEATHER_RAINY_MOD` | 1.2 | 雨天修正 |
| `WEATHER_STORM_MOD` | 2.0 | 暴风雨修正 |
| `WEATHER_SNOW_MOD` | 1.5 | 雪天修正 |
| `WEATHER_GREEN_MOD` | 1.5 | 绿雨修正 |
| `WEATHER_WIND_MOD` | 1.0 | 大风修正 |

### 笔记数量参数

| 参数 | 默认值 | 范围 | 说明 |
|------|-------|------|------|
| `TOTAL_NOTES` | 24 | 12-48 | 笔记总数量（动态计算） |
| `NOTES_PER_CATEGORY` | 见下表 | - | 各类别笔记数 |

| 类别 | 数量 | hint_category |
|------|------|---------------|
| 矿石/采矿 | 4 | mining |
| 钓鱼/水域 | 4 | fishing |
| 农作物 | 4 | farming |
| 动物/畜牧 | 3 | animal |
| NPC/社交 | 3 | npc |
| 天气/自然 | 3 | weather |
| 宝箱/奖励 | 3 | treasure |

### 奖励参数

| 参数 | 默认值 | 说明 |
|------|-------|------|
| `REWARD_MULTIPLIER` | 1.5 | 奖励价值倍率 |
| `INCLUDE_FINAL_REWARD` | true | 是否包含终极奖励 |
| `FINAL_REWARD_UNIQUE` | true | 终极奖励是否唯一（防止重复领取） |

### 调试参数

| 参数 | 默认值 | 说明 |
|------|-------|------|
| `DEBUG_INSTANT_DISCOVER` | false | 一键发现所有笔记 |
| `DEBUG_SHOW_ALL_NOTES` | true | 显示未发现笔记内容 |
| `DEBUG_SKIP_HINTS` | false | 直接显示提示答案 |
| `DEBUG_FORCE_COMPLETE` | false | 一键完成所有笔记 |

## Acceptance Criteria

### 功能测试

1. [ ] **笔记发现**
   - [ ] 各活动系统正确发出信号
   - [ ] P19 正确订阅并处理信号
   - [ ] 每天最多发现1张笔记
   - [ ] 已发现的笔记不会重复出现
   - [ ] 发现时播放特殊音效
   - [ ] 笔记物品正确进入背包

2. [ ] **笔记册功能**
   - [ ] 玩家可打开笔记册查看所有笔记
   - [ ] 已发现笔记显示完整内容
   - [ ] 未发现笔记显示"???"
   - [ ] 显示进度 (X/24)

3. [ ] **提示系统**
   - [ ] 每张笔记的诗句正确描述隐藏内容
   - [ ] 诗句暗示足够但不直接给出答案
   - [ ] 各类别笔记对应正确的内容
   - [ ] 每种 HintType 有明确的完成判定逻辑

4. [ ] **完成验证**
   - [ ] 玩家完成隐藏条件时自动触发完成检查
   - [ ] 正确识别各类隐藏内容完成状态
   - [ ] 已完成笔记标记为"已完成"

5. [ ] **奖励系统**
   - [ ] 每张笔记有对应奖励
   - [ ] 奖励正确发放到背包
   - [ ] 背包满时正确处理（暂存区）
   - [ ] 全部完成后触发终极奖励

6. [ ] **存档功能**
   - [ ] 笔记状态正确保存
   - [ ] 加载存档后状态正确恢复
   - [ ] 跨版本存档兼容

### 跨系统集成测试

1. [ ] **F03 物品数据系统**
   - [ ] 笔记物品ID正确注册
   - [ ] 奖励物品数据正确

2. [ ] **C02 库存系统**
   - [ ] 获得笔记时物品进入背包
   - [ ] 奖励物品正确添加到背包
   - [ ] `has_item()` 查询正确

3. [ ] **F01 时间/季节系统**
   - [ ] 每日发现计数正确重置
   - [ ] 季节限制笔记正确判断

4. [ ] **F02 天气系统**
   - [ ] 天气修正正确应用到发现概率
   - [ ] 极端天气信号正确发出

5. [ ] **P02 钓鱼系统**
   - [ ] 钓鱼信号正确发出
   - [ ] 秘密钓鱼点触发对应笔记完成

6. [ ] **P03 采矿系统**
   - [ ] 采矿信号正确发出
   - [ ] 秘密矿石触发对应笔记完成

### 性能测试

1. [ ] **启动时间**
   - [ ] 笔记数据加载 < 50ms

2. [ ] **内存占用**
   - [ ] 24张笔记数据 < 50KB

3. [ ] **响应时间**
   - [ ] 信号处理响应 < 1ms
   - [ ] 完成验证响应 < 5ms

4. [ ] **信号频率**
   - [ ] 高频信号（如砍树）不会导致性能问题
   - [ ] 使用信号聚合或节流处理高频事件

### 用户体验测试

1. [ ] **发现体验**
   - [ ] 发现动画流畅 (0.5-1秒)
   - [ ] 音效清晰可辨识
   - [ ] 发现提示不会打断游戏

2. [ ] **解读体验**
   - [ ] 诗句排版美观，适合阅读
   - [ ] 提示不过于明显
   - [ ] 有足够线索让玩家解谜

3. [ ] **完成体验**
   - [ ] 完成奖励反馈强烈
   - [ ] 全部完成的震撼感

## Visual/Audio Requirements

### 视觉效果

| 元素 | 要求 |
|------|------|
| 笔记图标 | 64×64 PNG，羊皮纸质感 |
| 笔记册背景 | 256×256，古籍样式 |
| 发现特效 | 金色光芒，1秒淡出 |
| 完成特效 | 绿色勾选动画 |
| 未发现遮罩 | 半透明灰色覆盖 |

### 音效要求

| 音效 | 文件 | 时长 |
|------|------|------|
| 发现音效 | `sfx/note_discover.ogg` | 0.5s |
| 翻开笔记册 | `sfx/book_open.ogg` | 0.3s |
| 笔记完成 | `sfx/note_complete.ogg` | 0.8s |
| 全部完成 | `sfx/all_notes_complete.ogg` | 2.0s |

## UI Requirements

### 笔记册界面

```
┌─────────────────────────────────────┐
│  秘密笔记册                     [×] │
├─────────────────────────────────────┤
│  [1] [2] [3] [4] [5] [6] [7] [8]   │
│  [9][10][11][12][13][14][15][16]   │
│ [17][18][19][20][21][22][23][24]   │
├─────────────────────────────────────┤
│  进度: 12/24 ✓                     │
├─────────────────────────────────────┤
│  ▼ 笔记 #7                         │
│  ────────────                       │
│  碧波深处有龙宫，                   │
│  锦鳞游泳乐无穷。                   │
│  一竿风月无人问，                   │
│  独钓寒潭待相逢。                   │
│                                     │
│  状态: ✓ 已完成                     │
│  奖励: 神秘鱼饵 ×3                  │
└─────────────────────────────────────┘
```

### 布局规范

- 笔记册最大尺寸: 600×500 像素
- 笔记缩略图网格: 8列×3行，每格 48×48
- 诗句区域: 宋体，14pt，行高 1.8
- 状态标签: 绿色"✓ 已完成" / 灰色"○ 未完成" / "???" 未发现

### 交互规范

- 点击缩略图查看笔记详情
- 已发现的笔记点击后显示完整诗句和状态
- 未发现的笔记点击后显示"尚未发现此笔记"
- 已完成的笔记点击后显示奖励信息

## Open Questions

1. **笔记数量是否足够？**
   - 当前设定24张可能偏少，建议与美术确认内容丰富度
   - Owner: Game Designer

2. **诗句质量谁来撰写？**
   - 需要专业文案或诗人来写古风诗句
   - 当前模板需要替换为真实诗句
   - Owner: Narrative Director → Writer

3. **隐藏内容的平衡**
   - 某些隐藏内容（如秘密钓鱼点）是否太稀有？
   - 建议设置合理的发现概率
   - Owner: Systems Designer

4. **Mod 支持程度**
   - 是否允许 Mod 添加新笔记？
   - Mod 笔记如何整合到笔记册？
   - Owner: Technical Director

5. **移动端适配**
   - 笔记册在移动端是否需要单独布局？
   - 诗句较长时是否需要滚动？
   - Owner: UX Designer

6. **高频信号优化**
   - 砍树等活动可能非常频繁
   - 是否需要节流机制避免性能问题？
   - Owner: Performance Analyst
