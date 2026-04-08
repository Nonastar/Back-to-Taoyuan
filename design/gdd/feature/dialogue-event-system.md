# 对话/事件系统 (Dialogue Event System)

> **Status**: Approved
> **Author**: Claude + User
> **Last Updated**: 2026-04-07
> **Implements Pillar**: 社交与关系系统

## Overview

对话/事件系统是游戏中文本内容的管理中心，负责所有NPC的对话文本、事件触发和分支选择。系统管理普通对话，好感度对话、爱心事件对话、季节事件对话、天气对话等多种对话类型，支持分支选择、变量替换和条件触发。系统是玩家与游戏世界交流的主要方式，每个NPC都有独特的说话风格和可解锁的对话内容。

**与 C07 的关系**: C07 NPC好感度系统 管理关系数值，P15 对话/事件系统 管理对话文本。两者协作：C07 检测触发条件 → P15 提供对应对话内容。

## Player Fantasy

对话/事件系统给玩家带来**身临其境的社交体验**。玩家应该感受到：

- **对话的个性化** — 每个NPC都有独特的说话风格，有的直爽，有的含蓄，有的幽默
- **被记住的惊喜** — NPC会提及你们之间发生的事，上次对话的内容
- **解锁的期待** — 提升好感度后，新的对话内容让人期待
- **选择的重量** — 对话分支选择会影响NPC对你的看法和后续剧情

**Reference games**: Stardew Valley 的NPC每日对话让人感到角色真实存在；Baldur's Gate 3 的分支对话让选择有意义。

**情感曲线**:
1. **初次相遇**: 对话简短，礼貌但疏远
2. **逐渐熟悉**: 对话变长，开始分享日常
3. **深入了解**: 解锁心事件，了解NPC的故事
4. **亲密羁绊**: 专属对话，NPC主动关心玩家

## Detailed Design

### Core Rules

#### 1. 对话类型分类

| 对话类型 | 触发条件 | 显示位置 | 优先级 |
|----------|----------|----------|--------|
| **普通对话** | 每日首次对话 | 随机从当日对话池选取 | 最低 |
| **好感对话** | 好感度等级变化 | 好感升级时 | 中 |
| **心事件** | 好感度达标+触发条件 | 达到条件时 | 高 |
| **季节对话** | 特定季节 | 季节第一天 | 中 |
| **天气对话** | 特定天气 | 天气变化时 | 低 |
| **生日对话** | NPC生日当天 | 生日当天 | 高 |
| **节日对话** | 节日当天 | 节日期间 | 中 |
| **特殊对话** | 特定条件满足 | 条件满足时 | 高 |

#### 2. 对话数据结构

```yaml
# 对话文件格式 (YAML)
npc_dialogues:
  npc_id: "su_su"

  # 普通对话池
  daily:
    - { text: "今天天气真好呀！" }
    - { text: "你今天准备做什么？" }

  # 按好感等级
  by_friendship_level:
    stranger:
      - { text: "你好，初次见面。" }
    acquaintance:
      - { text: "又见面了。" }
    friendly:
      - { text: "最近怎么样？" }
    best_friend:
      - { text: "你是我最好的朋友！" }

  # 心事件
  heart_events:
    heart_2:
      trigger: { friendship_min: 500 }
      dialogue: [...]
    heart_4:
      trigger: { friendship_min: 1000, quest_complete: "q_2_1" }
      dialogue: [...]

  # 生日/节日
  birthday: "spring_14"
  festival_dialogue: "祝你生日快乐！"
```

#### 3. 对话变量系统

**可用的对话变量**:

| 变量 | 说明 | 示例 |
|------|------|------|
| `{player_name}` | 玩家名称 | "小明" |
| `{npc_name}` | NPC名称 | "苏苏" |
| `{current_season}` | 当前季节 | "春季" |
| `{current_day}` | 当前日期 | "14日" |
| `{weather}` | 当前天气 | "晴天" |
| `{farm_name}` | 农场名称 | "桃源农场" |
| `{day_count}` | 游戏天数 | "第42天" |
| `{gift_received}` | 最近收到的礼物 | "你喜欢那个礼物吗？" |
| `{player_gender}` | 玩家性别 | "小哥" / "姑娘" |

#### 4. 对话分支选择

**选择结构**:
```yaml
dialogue_with_choice:
  text: "今天我想去钓鱼，你要一起来吗？"
  choices:
    - id: "accept"
      text: "好啊，一起去！"
      effects:
        - type: "friendship_change"
          value: 20
        - type: "trigger_event"
          event_id: "fishing_together"
    - id: "decline"
      text: "今天有事，改天吧。"
      effects:
        - type: "friendship_change"
          value: -10
    - id: "neutral"
      text: "看情况吧。"
      effects: []
```

#### 5. 事件触发系统

**触发条件类型**:

| 条件类型 | 语法 | 说明 |
|----------|------|------|
| 好感度 | `friendship >= 1000` | NPC好感度要求 |
| 好感等级 | `friendship_level == "friendly"` | 好感等级要求 |
| 物品持有 | `has_item("dragon_jade")` | 背包中有指定物品 |
| 物品数量 | `item_count("gold") >= 10000` | 持有指定数量物品 |
| 已完成任务 | `quest_complete("q_2_1")` | 完成任务 |
| 持有金钱 | `money >= 50000` | 持有金币要求 |
| 季节 | `season == "spring"` | 特定季节 |
| 天气 | `weather == "rainy"` | 特定天气 |
| 日期范围 | `day >= 28` | 游戏中第N天后 |
| 随机概率 | `random() < 0.3` | 30%概率触发 |

#### 6. NPC说话风格

每个NPC有独特的说话风格配置：

| NPC | 语气 | 用词特点 | 示例 |
|-----|------|----------|------|
| 苏苏 | 温柔 | 使用"呀"、"呢" | "今天天气真好呀！" |
| 阿强 | 直爽 | 简洁直接 | "走，去钓鱼！" |
| 老村长 | 稳重 | 使用敬语 | "年轻人，要努力啊。" |
| 小商贩 | 热情 | 夸张赞美 | "哎呀，贵客来了！" |

### States and Transitions

#### 对话状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Idle** | 无对话进行 | 默认状态 |
| **DialogueActive** | 对话进行中 | 玩家与NPC开始对话 |
| **ChoiceActive** | 选择等待中 | 显示对话分支 |
| **EventActive** | 事件进行中 | 触发心事件 |
| **DialogueEnded** | 对话结束 | 完成或跳过 |

#### 对话队列状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **NoQueue** | 无待处理对话 | 对话队列空 |
| **HasQueue** | 有待处理对话 | 对话队列有内容 |
| **QueuePaused** | 对话暂停 | 显示选择等待玩家 |

#### 事件状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **EventLocked** | 事件锁定 | 未满足触发条件 |
| **EventUnlocked** | 事件解锁 | 满足所有触发条件 |
| **EventTriggered** | 事件已触发 | 完成事件对话 |
| **EventCompleted** | 事件完成 | 事件所有对话结束 |

**状态转换**:
```
Idle → DialogueActive: player_talk_to(npc_id)
DialogueActive → ChoiceActive: show_choices()
ChoiceActive → DialogueActive: player_select_choice()
DialogueActive → EventActive: trigger_heart_event()
EventActive → DialogueActive: event_dialogue_continue()
DialogueActive → Idle: dialogue_complete()
Any → Idle: dialogue_skip() / player_leave()
```

### Interactions with Other Systems

#### 依赖系统 (Upstream Dependencies)

| System | Interface | Usage |
|--------|-----------|-------|
| **C07 NPC好感度系统** | `get_friendship()`, `get_friendship_level()` | 获取NPC好感度 |
| **F01 时间/季节系统** | `get_season()`, `get_day()` | 季节/日期变量 |
| **F02 天气系统** | `get_weather()` | 天气变量 |
| **C01 玩家属性系统** | `get_player_name()`, `get_gender()` | 玩家变量 |
| **C02 库存系统** | `has_item()`, `item_count()` | 物品条件检查 |
| **P08 任务系统** | `quest_complete()` | 任务条件检查 |

#### 事件订阅 (Event Subscriptions)

```gdscript
# P15 对话系统发出
signal dialogue_started(npc_id: String, dialogue_type: String)
signal dialogue_ended(npc_id: String)
signal choice_selected(npc_id: String, choice_id: String, effects: Array)

# P15 订阅其他系统信号
C07.friendship_changed → on_friendship_changed()
C07.heart_event_triggered → on_heart_event(npc_id, event_id)  # C07触发 → P15提供对话
C07.marriage_status_changed → on_marriage_changed()
P08.quest_completed → on_quest_completed()
```

> **信号契约**: C07 发出 `heart_event_triggered(npc_id, event_id)` 信号 → P15 收到后调用 `get_heart_event_dialogue()` 提供对话内容。

#### API 接口

```gdscript
class_name DialogueEventSystem extends Node

## 单例访问
static func get_instance() -> DialogueEventSystem

## 对话获取
func get_dialogue(npc_id: String) -> DialogueData:
    """获取NPC当前对话内容"""

func get_daily_dialogue(npc_id: String) -> String:
    """获取NPC当日普通对话"""

func get_friendship_dialogue(npc_id: String, level: String) -> String:
    """获取好感等级对话"""

func get_weather_dialogue(npc_id: String, weather: String) -> String:
    """获取天气对话"""

func get_birthday_dialogue(npc_id: String) -> String:
    """获取生日对话"""

func get_festival_dialogue(npc_id: String, festival_id: String) -> String:
    """获取节日对话"""

## 心事件（由C07触发）

> **注意**: 心事件的触发由 C07 NPC好感度系统控制。P15 只负责提供对话内容。

```gdscript
func on_heart_event_triggered(npc_id: String, event_id: String) -> void:
    """C07发出heart_event_triggered信号时调用 — 提供事件对话"""

func get_heart_event_dialogue(npc_id: String, event_id: String) -> DialogueData:
    """获取心事件对话内容 — 由C07触发后调用"""

func get_event_dialogue(npc_id: String, event_type: String, event_id: String) -> DialogueData:
    """获取任意事件对话内容"""
```

## 分支选择
func get_dialogue_choices(npc_id: String, dialogue_id: String) -> Array[Choice]:
    """获取对话分支选项"""

func select_choice(npc_id: String, choice_id: String) -> Dictionary:
    """执行选择，返回效果结果"""

## 变量系统
func resolve_variables(text: String, context: Dictionary) -> String:
    """解析对话文本中的变量"""

func set_dialogue_variable(key: String, value: Variant) -> void:
    """设置对话变量"""

func get_dialogue_variable(key: String) -> Variant:
    """获取对话变量"""

## 事件触发
func trigger_special_dialogue(npc_id: String, dialogue_id: String) -> bool:
    """触发特殊对话"""

## 对话状态
func is_talking() -> bool:
    """是否正在进行对话"""

func skip_current_dialogue() -> void:
    """跳过当前对话"""

## 存档
func serialize() -> Dictionary
func deserialize(data: Dictionary)
```

## Formulas

### 1. 对话优先级判定

> **重要**: 生日对话永远优先于心事件。心事件由C07触发后进入对话队列。

```
# 优先级从高到低检查
# 1. 生日对话（最高优先）
if is_birthday(npc_id): return BIRTHDAY_DIALOGUE

# 2. C07触发的心事件（进入事件队列）
elif has_pending_event(npc_id): return EVENT_DIALOGUE

# 3. 节日/季节
elif is_festival_day(): return FESTIVAL_DIALOGUE
elif is_season_change(): return SEASON_DIALOGUE

# 4. 好感度升级
elif friendship_level_changed(): return FRIENDSHIP_DIALOGUE

# 5. 天气/普通
elif is_weather_special(): return WEATHER_DIALOGUE
else: return DAILY_DIALOGUE
```

### 2. 好感等级对话选择

```
# 从当前好感等级池随机选择
level = get_friendship_level(npc_id)
pool = daily_dialogues[level]
return random_select(pool)
```

### 3. 变量替换

```
# 替换规则
REPLACEMENTS = {
    "{player_name}": player_stats.get_name(),
    "{npc_name}": npc.get_name(),
    "{current_season}": time_system.get_season_name(),
    "{current_day}": time_system.get_day(),
    "{weather}": weather_system.get_weather_name(),
    "{player_gender}": player_stats.get_honorific()
}

def resolve(text):
    for pattern, value in REPLACEMENTS:
        text = text.replace(pattern, value)
    return text
```

### 4. 条件表达式解析

```
# 支持的条件操作符
OPERATORS = ["==", "!=", ">=", "<=", ">", "<"]

# 解析条件字符串
def evaluate_condition(condition_str: String) -> bool:
    for op in OPERATORS:
        if op in condition_str:
            parts = condition_str.split(op)
            left = resolve_variable(parts[0].strip())
            right = resolve_value(parts[1].strip())
            return compare(left, op, right)
    return false
```

## Edge Cases

### 1. 对话边界

- **对话文本为空**: 显示默认对话"..."
- **变量解析失败**: 保留原变量占位符 `{var}`
- **没有可用的对话**: 显示"今天没什么想说的。"

### 2. 选择边界

- **选择后无效果**: 正常继续对话
- **选择有多个效果**: 顺序执行所有效果
- **选择后物品不足**: 显示提示，效果不执行

### 3. 事件边界

- **多个事件同时解锁**: 按事件ID顺序触发第一个
- **事件触发条件冲突**: 使用AND逻辑，全部满足才触发
- **重复触发同一事件**: 已触发的事件不再触发

### 4. 每日重置

- **每日对话池**: 每天00:00重置
- **对话历史**: 保留最近10条记录
- **对话变量**: 按类型区分重置（每日/永久）

### 5. 多语言边界

- **未翻译文本**: 使用英文fallback
- **文本过长**: 自动截断或缩小字体

## Dependencies

### 上游依赖（P15 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **C07** | NPC好感度系统 | 硬依赖 | 好感度、状态变化 |
| **F01** | 时间/季节系统 | 硬依赖 | 季节、日期 |
| **F02** | 天气系统 | 硬依赖 | 天气类型 |
| **C01** | 玩家属性系统 | 硬依赖 | 玩家名称、性别 |
| **C02** | 库存系统 | 软依赖 | 物品检查 |
| **P08** | 任务系统 | 软依赖 | 任务完成检查 |

### 下游依赖（其他系统依赖 P15）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P07** | 隐藏NPC系统 | 软依赖 | 仙灵对话 |
| **P14** | 沙漠/赌场系统 | 软依赖 | 赌场NPC对话 |
| **U05** | NPC对话框 | 硬依赖 | 对话显示 |

### 关键接口契约

```gdscript
## P15 订阅的信号

# C07 NPC好感度系统
signal friendship_changed(npc_id: String, old_level: String, new_level: String)
signal heart_event_triggered(npc_id: String, event_id: String)  # P15收到后提供对话
signal marriage_status_changed(npc_id: String, status: String)

# P08 任务系统
signal quest_completed(quest_id: String)

## P15 发出的信号

signal dialogue_started(npc_id: String, dialogue_type: String)
signal dialogue_ended(npc_id: String)
signal choice_selected(npc_id: String, choice_id: String, effects: Array)

## C07-P15 协作契约

C07 职责:
  - 管理NPC好感度数值
  - 检查心事件触发条件
  - 当条件满足时发出 heart_event_triggered 信号
  - 负责事件状态的持久化

P15 职责:
  - 存储对话文本内容
  - 提供对话获取接口
  - 订阅 C07 的信号并提供对应对话
  - 管理对话队列和打字效果
```

## Tuning Knobs

### 对话配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `MAX_DAILY_DIALOGUES` | 5 | 3-10 | 每日对话池大小 |
| `DIALOGUE_HISTORY_SIZE` | 10 | 5-20 | 对话历史保留数 |
| `CHOICE_EFFECT_DELAY` | 0.5 | 0.1-2.0 | 选择效果延迟(秒) |
| `TEXT_SPEED` | 30 | 10-100 | 每秒显示字符数 |

### 触发配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `EVENT_PRIORITY_HIGH` | 100 | 固定 | 心事件优先级 |
| `EVENT_PRIORITY_MEDIUM` | 50 | 固定 | 季节/节日优先级 |
| `EVENT_PRIORITY_LOW` | 10 | 固定 | 天气/普通优先级 |
| `RANDOM_DIALOGUE_CHANCE` | 0.3 | 0.1-0.5 | 随机特殊对话概率 |

### 变量配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `VAR_RESET_DAILY` | true | true/false | 每日变量重置 |
| `VAR_RESET_ON_SCENE` | true | true/false | 场景切换重置 |
| `MAX_CHOICE_OPTIONS` | 4 | 2-6 | 最大选择选项数 |

## Visual/Audio Requirements

### 视觉要求

- **对话框**: 角色头像 + 对话文本框
- **选择框**: 分支选项列表，高亮当前选项
- **心事件**: 全屏剧情对话框，背景场景

### 音频要求

- **对话打字音**: 每显示一个字播放音效
- **选择音效**: 选择选项时的点击音
- **事件触发音**: 心事件开始的提示音

## UI Requirements

| 界面 | 组件 | 描述 |
|------|------|------|
| NPC对话框 | DialogueBox | 头像+文字+继续按钮 |
| 选择面板 | ChoicePanel | 分支选项列表 |
| 事件对话框 | EventDialogueView | 全屏剧情对话框 |
| 跳过按钮 | SkipButton | 跳过当前对话 |

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 普通对话显示 | 每日首次对话验证 |
| **AC-02** | 好感等级对话 | 不同好感等级验证对话差异 |
| **AC-03** | 心事件触发 | 好感达标后验证事件触发 |
| **AC-04** | 分支选择效果 | 选择后验证好感度变化 |
| **AC-05** | 变量替换 | 验证 `{player_name}` 等变量正确替换 |
| **AC-06** | 事件优先级 | 多条件同时满足时验证优先级 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | C07 好感变化 | 好感变化时触发新对话 |
| **CS-02** | F01 季节变化 | 季节第一天验证季节对话 |
| **CS-03** | F02 天气变化 | 特定天气验证天气对话 |
| **CS-04** | C02 物品检查 | 持有物品时触发特殊对话 |

### 性能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **PC-01** | 对话加载 < 50ms | 记录对话获取耗时 |
| **PC-02** | 文本打字效果流畅 | 观察打字动画 |

## Open Questions

| ID | 问题 | Owner | Target Date |
|----|------|-------|-------------|
| **OQ-01** | 心事件对话数量（每级几个）？ | 策划 | Pre-MVP |
| **OQ-02** | 结婚后对话变化幅度？ | 策划 | Pre-MVP |
| **OQ-03** | 隐藏NPC（P07）对话如何集成？ | 协调 | 与P07协调 |
| **OQ-04** | 对话文本的本地化方案？ | 技术 | Pre-MVP |
