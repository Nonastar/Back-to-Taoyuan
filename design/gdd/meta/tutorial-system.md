# 教程系统 (Tutorial System)

> **Status**: Approved
> **Author**: AI-assisted Design
> **Last Updated**: 2026-04-08
> **Implements Pillar**: 所有系统 (贯穿全游戏)

## Overview

教程系统为玩家提供游戏引导和上下文提示，确保玩家能够理解核心玩法而不感到被强制教导。通过渐进式引导、可跳过的教程关卡和智能提示系统，让新玩家顺利上手，同时让老玩家能够快速进入游戏。

## Player Fantasy

玩家应该感受到"这个游戏很友好，但不是幼稚的"。教程在后台默默工作，在需要时出现，帮助但不打扰。提示系统像是了解游戏的朋友，在你困惑时给出方向，但从不替你做决定。

## Detailed Design

### Core Rules

#### 1. 教程触发机制

1. **首次进入触发**: 当玩家第一次进入特定区域或触发某个游戏里程碑时
2. **行为检测触发**: 当玩家长时间(60秒)未进行有效操作时
3. **成就未达成触发**: 当某个成就长期(7天)未达成且玩家接近条件时
4. **手动呼出**: 玩家可通过菜单随时呼出帮助面板

#### 2. 教程类型

| 类型 | 描述 | 出现时机 | 可跳过 |
|------|------|----------|--------|
| 引导框 | 弹窗式教程提示 | 首次进入新区域 | 是(部分) |
| 高亮提示 | UI元素闪烁高亮 | 操作指引 | 否 |
| 对话教程 | NPC对话形式的教学 | 特定NPC附近 | 是 |
| 实战演练 | 小型教学关卡 | 核心功能首次使用 | 部分 |
| 提示气泡 | 小型提示文本 | 任意时刻 | 是 |

#### 3. 教程内容分类

- **农场基础**: 耕地、播种、浇水、收获
- **库存管理**: 背包使用、物品分类、整理
- **技能入门**: 钓鱼、采矿、畜牧基础
- **社交入门**: NPC对话、送礼、好感度
- **经济基础**: 商店交易、物品定价
- **节日引导**: 各节日活动入口和玩法
- **迷你游戏**: 各小游戏基础操作

### States and Transitions

```
┌─────────────────────────────────────────────────────────────┐
│                      教程系统状态机                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [INACTIVE] ──玩家首次进入游戏──> [FIRST_TIME_SETUP]       │
│       ↑                                    │                │
│       │                                完成设置后            │
│       │                                    ↓                │
│  跳过/退出                          [TUTORIAL_ACTIVE]      │
│       │                                    │                │
│       └──────────────────────────────> [WAITING] <──────────┤
│                                              │              │
│                                    检测到触发条件             │
│                                              ↓              │
│                                    [TUTORIAL_ACTIVE] ──┬────┤
│                                              │    │       │
│                                       完成/跳过  继续等待    │
│                                              ↓    │       │
│                                       [COMPLETED] ──┘       │
│                                              │              │
│                                    玩家请求帮助  返回WAITING │
│                                              ↓              │
│                                       [HELP_ACTIVE] ───────┘
│
└─────────────────────────────────────────────────────────────┘
```

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| INACTIVE | 游戏未开始 | 玩家首次进入游戏 | 无教程显示 |
| FIRST_TIME_SETUP | 新存档首次加载 | 完成基础设置 | 显示操作设置 |
| WAITING | 教程完成/跳过 | 检测到触发条件 | 监控系统状态 |
| TUTORIAL_ACTIVE | 触发条件满足 | 教程完成/跳过 | 显示教程内容 |
| COMPLETED | 教程步骤完成 | 玩家请求帮助 | 重置到WAITING |
| HELP_ACTIVE | 玩家呼出帮助 | 关闭帮助面板 | 显示帮助面板 |

### Interactions with Other Systems

#### 与 F01 时间/季节系统
- **输入**: 获取当前季节和日期，判断节日触发
- **输出**: 向时间系统注册节日活动提醒
- **接口**: `SeasonEventTrigger(season, day)`

#### 与 C02 库存系统
- **输入**: 获取背包状态，检测物品变化
- **输出**: 高亮特定物品格，提示物品用途
- **接口**: `HighlightItem(item_id)`, `GetInventoryState()`

#### 与 C04 农场地块系统
- **输入**: 获取地块状态，检测农作阶段
- **输出**: 引导耕地流程，提示作物状态
- **接口**: `GetPlotStates()`, `TriggerPlantingTutorial()`

#### 与 P02 钓鱼系统
- **输入**: 获取钓鱼小游戏状态
- **输出**: 钓鱼教程关卡，提示条操作
- **接口**: `StartFishingTutorial()`, `GetFishingProgress()`

#### 与 P15 对话/事件系统
- **输入**: 获取NPC好感度和对话状态
- **输出**: 在对话中嵌入教程提示
- **接口**: `InjectDialogueHint(npc_id, hint_key)`

#### 与 U01 HUD系统
- **输入**: HUD当前显示内容
- **输出**: 高亮HUD特定区域，显示教程气泡
- **接口**: `HighlightUI(element_id)`, `ShowTutorialBubble(text)`

#### 与 F04 存档系统
- **输入**: 存档进度数据
- **输出**: 记录教程完成状态到存档
- **接口**: `SaveTutorialProgress()`, `LoadTutorialProgress()`

## Formulas

### 教程触发延迟计算

```
trigger_delay = base_delay * (1 + recency_factor - mastery_factor)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base_delay | int | 30-120秒 | 配置表 | 基础延迟时间 |
| recency_factor | float | 0.0-0.5 | 系统计算 | 同一教程越近触发越短 |
| mastery_factor | float | 0.0-0.8 | 玩家数据 | 玩家经验越多提示越少 |
| trigger_delay | int | 6-180秒 | 计算结果 | 最终触发延迟 |

**Expected output range**: 6-180秒 (实际最小6秒，最大180秒)
**Edge case**:
- 当 mastery_factor > 1.0 时，trigger_delay 可能 < 6秒，应clamp到6秒
- 当 recency_factor = 0.5 且 mastery_factor = 0 时达到最大值180秒

### 提示优先级评分

```
priority_score = urgency * 0.4 + importance * 0.3 + recency * 0.2 + novelty * 0.1
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| urgency | float | 0-10 | 系统计算 | 玩家当前困境程度 |
| importance | float | 0-10 | 配置表 | 教程内容重要性 |
| recency | float | 0-10 | 系统计算 | 距上次提示时间 |
| novelty | float | 0-10 | 系统计算 | 是否重复显示 |
| priority_score | float | 0-10 | 计算结果 | 综合优先级 |

**Expected output range**: 0-10
**Edge case**: 当 priority_score < 3 时不触发提示

### 高亮透明度动画

```
highlight_alpha = abs(sin(elapsed_time * highlight_speed)) * max_opacity
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| elapsed_time | float | 0-∞ | 游戏时钟 | 已逝时间 |
| highlight_speed | float | 1.0-3.0 | 配置表 | 闪烁速度 |
| max_opacity | float | 0.5-1.0 | 配置表 | 最大透明度 |
| highlight_alpha | float | 0-1.0 | 计算结果 | 当前透明度 |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| 教程进行中游戏崩溃 | 重启后从断点继续，非从头开始 | 避免重复教学 |
| 玩家跳过所有教程 | 记录跳过，在第一个成就前不触发新教程 | 尊重玩家选择 |
| 教程目标在教程期间达成 | 自动完成教程步骤 | 避免无意义的等待 |
| 多个教程同时触发 | 按优先级排队，间隔3秒依次显示 | 避免信息过载 |
| 玩家已通过Lua版本学习过 | 检测存档创建日期，新存档显示完整教程 | 新玩家体验 |
| 教程指向的UI元素不存在 | 显示文本教程，标注"请联系客服" | 鲁棒性设计 |
| 网络断开时的教程 | 全部本地化，不依赖网络 | 离线可用性 |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| F01 时间/季节系统 | 依赖 | 获取节日日历和日期信息 |
| F04 存档系统 | 依赖 | 保存/加载教程完成状态 |
| U01 HUD系统 | 依赖 | UI高亮和气泡显示 |
| C02 库存系统 | 被依赖 | 教程目标之一 |
| C04 农场地块系统 | 被依赖 | 教程目标之一 |
| P02 钓鱼系统 | 被依赖 | 教程目标之一 |
| P15 对话/事件系统 | 被依赖 | NPC对话教程 |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| base_delay | 60秒 | 30-120秒 | 提示出现更慢 | 提示出现更快 |
| tutorial_queue_interval | 3秒 | 1-10秒 | 提示间隔更长 | 提示间隔更短 |
| max_highlight_opacity | 0.8 | 0.5-1.0 | 高亮更明显 | 高亮更柔和 |
| highlight_speed | 2.0 | 1.0-3.0 | 闪烁更快 | 闪烁更慢 |
| mastery_decay_rate | 0.1/天 | 0.05-0.2 | 遗忘更快 | 遗忘更慢 |
| skip_allowed_ratio | 0.7 | 0.5-1.0 | 更多教程可跳过 | 更少教程可跳过 |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| 教程开始 | 屏幕边缘淡入蒙版 | 柔和提示音效 | 高 |
| 高亮目标 | 目标元素脉冲发光 | 无 | 高 |
| 教程完成 | 对勾动画 + 淡出 | 成功音效 | 高 |
| 教程跳过 | 快速淡出 | 跳过音效 | 中 |
| 新提示到来 | 气泡弹出动画 | 提示音 | 中 |
| 帮助面板打开 | 面板滑入动画 | 界面音效 | 低 |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| 教程进度 | 教程面板顶部 | 实时 | 教程进行中 |
| 跳过按钮 | 教程面板右上角 | 常驻 | 教程可跳过 |
| 提示气泡 | 相关UI元素附近 | 触发时 | 提示激活 |
| 帮助菜单入口 | 设置菜单 | 常驻 | 始终可用 |
| 教程完成统计 | 设置 > 帮助 > 教程记录 | 按需 | 查看时刷新 |

## Acceptance Criteria

- [ ] 新存档首次进入显示农场基础教程
- [ ] 钓鱼系统首次交互显示钓鱼教程
- [ ] 玩家可随时在设置中重置教程进度
- [ ] 教程状态正确保存到存档并在加载后恢复
- [ ] 跳过教程后不再重复同一教程(除非重置)
- [ ] 帮助菜单显示所有教程主题索引
- [ ] 系统更新完成时自动检测并提示相关教程
- [ ] 性能: 教程系统CPU占用 < 1ms/帧
- [ ] 无硬编码教程文本，所有文本可外部化

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| 是否需要视频教程替代文字教程? | 待定 | v1.0 | 否,优先文字+图标 |
| 教程是否需要配音? | 待定 | v1.0 | 否,保持简洁 |
| 如何处理老玩家的"快速上手"需求? | 待定 | v1.0 | 提供跳过选项 |
| 教程是否支持mod扩展? | 待定 | v1.0 | 预留接口 |
