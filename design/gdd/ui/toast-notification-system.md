# 飘窗通知系统 (Toast Notification System)

> **状态**: Approved
> **Author**: Claude Code
> **Last Updated**: 2026-04-24
> **System ID**: U01-SUB (HUD子系统)
> **Implements Pillar**: UI 基础设施
> **Parent System**: HUD系统 (U01)

## Overview

飘窗通知系统是游戏内所有玩家操作反馈的统一展示层。当玩家执行任何游戏内操作（采集、购买、建造、使用技能等）后，无论成功或失败，系统都会通过飘窗提供即时、可读的视觉反馈。

**核心设计：优先级队列 + 堆叠显示 + 去重合并**

**核心设计：NM 队列路由 + HUD 就地刷新**

```
┌──────────────────────────────────────────────────────────┐
│  NotificationManager (autoload)                          │
│  - _is_showing: 当前是否有 await 在执行                   │
│  - _is_showing=false + 收到消息 → 进入队列                │
│  - _is_showing=true  + 同id消息  → 直接发 HUD 合并        │
│  - _is_showing=true  + 不同id消息 → 进入队列              │
│  - 队列最大 20 条                                         │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│  HUD.show_message (CanvasLayer)                          │
│  - _active_toasts: 当前显示中的飘窗列表                   │
│  - _active_toast_ids: id → toast 索引（用于快速查找）     │
│  - _is_spawning: _spawn_toast 执行中（_process 不移除）   │
│  - 同 id 检查 → _refresh_active_toast（不创建新）         │
│  - 不同 id → _spawn_toast 新建                           │
│  - MAX_VISIBLE = 3                                       │
└──────────────────────────────────────────────────────────┘
```

- **统一入口**：所有系统通过 EventBus 发送 `notification_requested` 信号
- **优先级打断**：高优先级可打断低优先级显示
- **非阻塞**：不打断游戏进程，自动消失（2-4秒）
- **去重合并**：高频操作（如连续收割）2秒内合并为一条，显示总数

## Player Fantasy

飘窗系统给玩家带来**"操作必有回应"的安心感**。

玩家执行任何操作后，都期望系统给出反馈——哪怕是一个简单的"无法操作"提示。当飘窗及时出现，玩家会感到游戏是"活的"，每个操作都被记录和回应。

成功的反馈（如收获物品、任务完成）应该有**成就感**；失败的反馈（如资源不足、条件不满足）应该有**清晰的引导感**，让玩家知道下一步该做什么，而不是困惑地卡住。

飘窗不应该让玩家感到烦躁（刷屏）、困惑（看不懂）、或被打断（频繁弹框），而应该是流畅游戏体验的无缝组成部分。

**参考游戏**：
- **星露谷**：简短文字、居中偏上、向上飘动淡出
- **暗黑破坏神**：伤害数字垂直堆叠、多颜色
- **原神**：带图标、圆角背景、弹性动画
- **我的世界**：顶部黑底白字、左对齐

## Detailed Design

### Core Rules

#### 1. 通知类型与颜色

| 类型 | 颜色常量 | 前景色 | 背景色 | 示例 |
|------|----------|--------|--------|------|
| `gain` | `NotificationColor.GAIN` | 金色 `#FFD700` | 无 | `耕地完成`、`收获成功`、`🌟 X 升级！` |
| `cost` | `NotificationColor.COST` | 红色 `#E74C3C` | 无 | `没有种子了`、`作物枯萎了` |
| `consume` | `NotificationColor.CONSUME` | 红色 `#E74C3C` | 无 | `cost` 的别名，兼容旧调用 |
| `success` | `NotificationColor.SUCCESS` | 绿色 `#2ECC71` | 无 | `任务完成！` |
| `warning` | `NotificationColor.WARNING` | 橙色 `#F39C12` | **半透明黑 `priority≥3`** | `背包已满` |
| `error` | `NotificationColor.ERROR` | 深红色 `#C0392B` | **半透明黑 `priority≥3`** | `操作失败！` |
| `system` | `NotificationColor.SYSTEM` | 白色 `#FFFFFF` | 无 | 系统消息、操作提示 |
| `normal` | `NotificationColor.NORMAL` | 白色 `#FFFFFF` | 无 | 默认类型 |

**HUD._show_notification 消息内容路由**：EventBus.farm_message 等路径通过 HUD._show_notification 分发，根据消息前缀匹配颜色：
- 金色：`耕地完成`、`浇水完成`、`可以收获了`、`播种成功`、`收获成功`、`施肥成功`、`保湿土`、`雨天自动浇水`
- 红色：`没有种子了`、`没有肥料了`、`作物枯萎了`

#### 2. 消息结构

```gdscript
# 通知类型枚举
enum ToastType {
    GAIN,    # 获得（金色）
    COST,    # 消耗（红色）
    SUCCESS, # 成功（绿色）
    WARNING, # 警告（橙色）
    ERROR,   # 错误（深红）
    SYSTEM,  # 系统（白色）
}

class_name ToastMessage
extends RefCounted

var id: String                    # 唯一标识符（格式: "ToastType_hash"，不含时间戳）
var text: String                  # 显示文本
var type: ToastType               # 通知类型枚举
var priority: int                 # 1=low, 2=normal, 3=high, 4=critical
var duration: float               # 显示时长（秒），默认 2.5 秒
var icon_path: String             # 图标资源路径（可选）
var count: int                   # 合并计数（连续相同操作的数量）
var created_at: float             # 创建时间戳（用于去重窗口计算）
```

#### 3. 队列管理规则

| 规则 | 说明 |
|------|------|
| 同时显示上限 | 3 条（可配置） |
| 去重窗口 | 2 秒（可配置） |
| 队列最大长度 | 20 条（超出丢弃最早的低优先级） |
| 高优先级打断 | `priority >= 3` 可打断正在显示的低优先级消息 |

#### 4. 显示位置

| 参数 | 默认值 | 说明 |
|------|-------|------|
| 锚点 | `CENTER` | 屏幕中央 |
| 偏移 X | `0` | 水平居中 |
| 偏移 Y | `-100` | 偏上 100 像素 |
| 垂直间距 | `20px` | 多条飘窗之间的间距 |

### States and Transitions

#### 1. 单个飘窗状态机

| 状态 | 描述 | 持续时间 | 下一状态 |
|------|------|----------|----------|
| `creating` | 创建消息对象，分配唯一ID | <1帧 | `showing` |
| `showing` | 淡入动画 + 正常显示 | `duration` 秒（默认2.5s） | `fading` |
| `fading` | 向上飘动 + 淡出动画 | 0.3s | `removed` |
| `removed` | 从显示列表移除，可回收 | - | - |

**状态转换图**：

```
[CREATING] ──→ [SHOWING] ──→ [FADING] ──→ [REMOVED]
                    ↑              │
                    └──────────────┘ (如果被高优先级打断，直接进入FADING)
```

#### 2. 系统队列状态机

| 系统状态 | 描述 | 进入条件 | 退出条件 |
|----------|------|----------|----------|
| `idle` | 无有效消息，通知区隐藏 | 队列空且无显示中消息 | 收到新通知 |
| `running` | 正常显示飘窗 | 有消息要显示 | 队列空或暂停 |
| `paused` | 暂停处理（打开UI时） | `pause_requested` 信号 | `resume_requested` 信号 |
| `draining` | 恢复后继续按序处理队列 | 暂停结束 | 队列清空 |

**NM 层状态 `_is_showing`**：
| NM 状态 | 收到同 id 消息 | 收到不同 id 消息 |
|---------|---------------|-----------------|
| `_is_showing == false` | `_add_to_queue` → `_show_notification` → HUD 新建 | 同上 |
| `_is_showing == true` | **直接调用 HUD.show_message**（HUD 内部合并） | 正常进入队列 |

> `_is_paused` **不再阻止**通知显示。仅当 `_is_showing=true`（上一条正在 await）时新消息才被合并刷新，无论是否暂停。暂停期间通知正常叠加显示在 UI 上方。 |

#### 3. 状态转换规则

| 转换 | 触发条件 | 行为 |
|------|----------|------|
| `idle` → `running` | 收到 `notification_requested` | 如果有消息，立即开始显示 |
| `running` → `paused` | 进入全屏UI/菜单 | 设置 `_is_paused=true`，队列继续但新消息不受阻塞 |
| `paused` → `draining` | 退出全屏UI/菜单 | `_is_paused=false`，调用一次 `_show_next` |
| `draining` → `idle` | 队列清空 | 恢复 `running` 状态 |
| `running` → `running` | 收到新消息 | 按优先级插入显示或排队 |

#### 4. 暂停期间的队列行为

- 暂停期间**继续接收**新消息
- 新消息进入队列后**立即显示**（`_is_paused` 不再阻止 `_show_next`），toast 叠加在 UI 上方
- 恢复时队列中剩余消息继续按顺序显示

### Interactions with Other Systems

#### 1. 调用接口（EventBus 信号）

**实际调用链路（2026-04-24 实现）**：

```
游戏系统 (FarmPlot / Player / SkillSystem)
    │
    ├─→ NotificationManager.show_gain / show_cost / show_info / ...
    │       │
    │       ├─ _is_showing == false → _add_to_queue → _show_notification → HUD.show_message
    │       │                                                                 │
    │       │                                                  HUD._spawn_toast（新建 toast）│
    │       │                                                                 │
    │       └─ _is_showing == true  → 直接调用 HUD.show_message ──────────────┘
    │                                                    │
    │                                        HUD 检查 _active_toasts 有无同 id
    │                                                    │
    │                                        ├─ 有 → _refresh_active_toast（合并刷新）
    │                                        │
    │                                        └─ 无 → _spawn_toast（新建 toast）
    │
    └─→ EventBus.farm_message ──→ HUD._on_farm_message ──→ HUD._show_notification
                                                                          │
                                                          NM.show_gain / NM.show_cost / NM.show_info
                                                                          │
                                                          （后续同上：_is_showing 路由）
```

**游戏系统直接调 NM 的接口（推荐）**：
```gdscript
NotificationManager.show_gain(text, id)       # 金色
NotificationManager.show_cost(text, id)        # 红色
NotificationManager.show_success(text, id)     # 绿色
NotificationManager.show_warning(text, id)     # 橙色
NotificationManager.show_error(text, id)      # 深红色
NotificationManager.show_info(text, id)        # 白色（默认）
```
> 未传 `id` 时自动生成 `id = "text:" + text`，相同文本自动获得相同 id，可实现跨操作自动合并。

**EventBus 信号（供遗留系统使用）**：
```gdscript
# notification_requested - 完整参数，推荐用于需要指定 type 的场景
EventBus.notification_requested.emit(text, notif_type, priority, duration, id, icon_path)

# ui_notification - 简化版，内部由 NotificationManager 转换为 notif_type
EventBus.ui_notification.emit(message, duration, priority, notif_type, id)

# farm_message - 农场地块专用，通过 HUD._on_farm_message → NM 路由
EventBus.farm_message.emit(msg)
```

#### 4. 系统依赖关系

| 上游系统 | 发送信号 | 说明 |
|----------|----------|------|
| 所有游戏系统 | `notification_requested` | 通过 ToastManager 便捷调用 |
| 场景管理器 (SceneManager) | `pause_requested` / `resume_requested` | 进入/退出全屏UI时，HUD 监听此信号 |
| 时间系统 | `Time.get_ticks_msec()` | 去重窗口计时（通过 Godot 内置函数） |

| 下游系统 | 接收飘窗 | 说明 |
|----------|----------|------|
| 存档系统 | 记录飘窗历史 | 可选，用于成就追踪 |
| 教程系统 | 检测飘窗类型 | 可选，检测特定提示出现次数 |

## Formulas

### 1. 动画时序参数

| 参数 | 默认值 | 说明 |
|------|-------|------|
| `FADE_IN_DURATION` | 0.2s | 淡入动画时长 |
| `FADE_OUT_DURATION` | 0.3s | 淡出动画时长 |
| `FLOAT_SPEED` | 50px/s | 飘动上升速度 |
| `EASE_TYPE` | `EASE_OUT` | 弹性曲线类型 |
| `SPRING_OVERSHOOT` | 1.1 | 弹性效果的超调量 |

### 2. 位置计算

```
# 单个飘窗 Y 坐标（随时间上升）
Y(t) = base_y - (t × FLOAT_SPEED)

# 堆叠位置计算
for i in range(visible_toasts):
    toast_y[i] = base_y - (i × (toast_height + spacing))
    # i=0 是最顶部（最新）的飘窗
    # i=2 是最底部（最早）的飘窗
```

### 3. 透明度曲线

```
# 淡入阶段 (0 → FADE_IN_DURATION)
alpha(t) = ease(t / FADE_IN_DURATION, EASE_OUT)

# 正常显示阶段
alpha(t) = 1.0

# 淡出阶段 (total_elapsed > duration - FADE_OUT_DURATION 时进入淡出)
# total_elapsed: 消息已显示的总时长
# duration: 消息配置的显示时长
fade_out_elapsed = total_elapsed - (duration - FADE_OUT_DURATION)
# fade_out_elapsed 从 0 增长到 FADE_OUT_DURATION
alpha(t) = 1.0 - ease(fade_out_elapsed / FADE_OUT_DURATION, EASE_IN)
# alpha 从 1.0 逐渐变为 0
```

### 4. 去重合并计算（实际实现）

**核心设计：NM 层跳过队列，HUD 层就地刷新**

```
调用路径:
NM.show_message(id="text:耕地完成！")
    │
    ├─ _is_showing == false → _add_to_queue → _show_next → HUD.show_message → _spawn_toast（新建）
    │
    └─ _is_showing == true → 直接调用 HUD.show_message → 检查 _active_toasts → _refresh_active_toast（刷新）
                                              │
                                              └─→ 文本变为 "耕地完成！ x2"，elapsed 重置为 0，tween 重新淡入
```

**合并判断条件**:
```
is_duplicate = toast.id == incoming.id AND toast is currently showing (not fading/removing)
```

**合并后行为**:
```
1. count++
2. display_text = count > 1 ? "{text} x{count}" : text
3. elapsed 重置为 0
4. state 重置为 0 (showing)
5. 旧 tween kill()，新建 tween 重新淡入
```

**刷新函数** `_refresh_active_toast(id, display_text, color)`:
```
tween.kill()           # 停止旧动画
label.text = display_text
label.font_color = color
elapsed = 0.0
state = 0              # 重置为显示状态
new_tween = fade_in()  # 重新淡入
```

**ID 生成规则**: 未传 id 时自动生成 `id = "text:" + text`，相同文本自动获得相同 id。调用方也可显式传入自定义 id 以跨操作合并（如连续出售同一物品）。

### 5. 优先级打断判断

```
# 判断条件
can_interrupt = (
    new_message.priority >= 3  # high 或 critical
    AND current_messages.exists(msg => msg.priority < 3)
    AND current_messages.length >= max_visible  # 已满
)

# 打断行为：移除最低优先级的消息
if can_interrupt:
    lowest_priority_msg = current_messages.min_by(msg => msg.priority)
    lowest_priority_msg.force_fade_out()
```

## Edge Cases

### 1. 数值边界处理

| 情况 | 处理方式 |
|------|----------|
| 队列为空时收到消息 | 直接显示，不排队 |
| 队列已满（20条）且收到新消息 | 丢弃队列中最旧的 `priority=1` 消息；如果没有 priority=1 的，丢弃最旧的低优先级消息 |
| `duration <= 0` | 使用默认值 2.5 秒 |
| `priority <= 0` | 强制设为 1 (low) |
| `priority > 4` | 强制设为 4 (critical) |
| 文本超长（>100字符） | 截断至 100 字符，末尾加 "..." |

### 2. 并发场景

| 场景 | 处理方式 |
|------|----------|
| 两消息同时到达（同一帧） | 按优先级排序后依次处理；同优先级按先到先处理 |
| 快速连续发送相同 ID（间隔 < 显示时长） | NM 层跳过队列，直接调用 HUD → 刷新计数 + 重置计时器（**不创建新飘窗**） |
| 快速连续发送相同 ID（间隔 > 显示时长） | 第一条正常消失后，第二条作为新 toast 显示（正常排队，不合并） |
| 高优先级打断正在淡出的消息 | 正在 `fading` 的消息不受打断影响，完成淡出后再处理新的 |

### 3. 优先级冲突

| 场景 | 处理方式 |
|------|----------|
| 3 条消息正在显示，新消息 priority=4 | 打断最低优先级（priority=1）的消息，立即显示新的 |
| 所有可见消息都是 priority=3，无法打断 | 新消息进入队列排队，等待空闲槽位 |
| critical (4) 打断 normal (2) | 被打断的消息立即进入 `fading` 状态（跳过剩余显示时间） |

### 4. 暂停/恢复期间

| 场景 | 处理方式 |
|------|----------|
| 暂停时收到新消息 | 立即显示（不等待恢复），toast 叠加在 UI 上方 |
| 恢复时队列有多条消息 | 依次显示 |
| 暂停恢复时显示槽位已满 | 等第一条消失后再显示下一条 |

### 5. 性能边界

| 场景 | 处理方式 |
|------|----------|
| 1 秒内收到 100 条不同消息 | 前 20 条进入队列，其余丢弃（MAX_QUEUE_SIZE=20） |
| 消息文本包含非法字符 | 过滤所有非打印字符，保留空格和可见 ASCII/Unicode |
| 动画过程中目标节点被释放 | 跳过该帧的动画更新，下一帧重新检查节点有效性 |

### 6. 与父系统 HUD 的冲突

| 场景 | 处理方式 |
|------|----------|
| HUD 切换场景时仍有消息在队列 | 队列状态保持，场景切换完成后继续处理 |
| 多个 HUD 实例同时存在 | 飘窗系统只依附于主 HUD 实例（单例模式） |

### 7. ID 去重的边界情况

| 场景 | 处理方式 |
|------|----------|
| 相同 id 第二次到达时前一条正在**淡出中**（state=1） | 视为新 toast，创建独立飘窗（淡出中的 toast 不可合并） |
| 相同 id 第二次到达时前一条已**消失**（state=2） | 创建新 toast（正常行为） |
| 合并计数达到 999 | 不继续累加，显示 "x999+" |
| 相同文本、不同 id（如显式传不同 id） | 不合并，视为不同消息 |
| NM 正在 await 期间（HUD 飘窗存活 `_is_spawning=true`） | `_process` 跳过移除检查，保证 HUD 瓢窗存活到下一次 REFRESH |
| 队列中已有相同 id 的待处理消息 | `_process_toast_queue` 中跳过去重检查，跳过新建（REFRESH 已在 NM 层处理） |

## Dependencies

### 上游依赖（飘窗依赖其他系统）

| 系统 | ID | 依赖类型 | 接口 | 说明 |
|------|-----|----------|------|------|
| 事件系统 | ADR-0007 | 硬依赖 | `notification_requested` 信号 | 所有通知的统一入口 |
| 时间系统 | F01 | 硬依赖 | `Time.get_ticks_msec()` | 去重窗口计时 |
| 场景管理器 | - | 软依赖 | `pause_requested` / `resume_requested` | 打开UI时暂停队列 |
| 音频系统 | F05 | 可选 | `AudioSystem.play_sfx()` | 飘窗弹出音效（可配置） |

### 下游依赖（其他系统依赖飘窗）

| 系统 | ID | 用途 | 调用方式 |
|------|-----|------|----------|
| 所有功能系统 | P01-P19 | 操作反馈 | `NotificationManager.show_*()` |
| HUD系统 | U01 | 飘窗容器 | 管理显示/隐藏 |

### 信号接口定义

**EventBus → 飘窗**:
```gdscript
signal notification_requested(
    text: String,
    type: ToastType,
    priority: int,
    duration: float,
    id: String,
    icon_path: String
)
```

**场景管理器 → 飘窗**:
```gdscript
signal pause_requested()      # 打开全屏UI时
signal resume_requested()     # 关闭全屏UI后
```

### 与父系统 HUD 的关系

- 飘窗系统是 HUD 系统 (U01) 的子系统
- 父系统提供容器（CanvasLayer + NotificationArea）
- 子系统负责队列管理、动画、显示逻辑
- 通过 `_notification_area` 节点引用进行交互

## Tuning Knobs

### 动画参数

| 参数 | 默认值 | 范围 | 说明 | 过高影响 | 过低影响 |
|------|-------|------|------|----------|----------|
| `FADE_IN_DURATION` | 0.2s | 0.1-0.5s | 淡入动画时长 | 出现太慢，反应迟钝 | 闪烁感 |
| `FADE_OUT_DURATION` | 0.3s | 0.1-0.5s | 淡出动画时长 | 消失太慢，屏幕拖沓 | 突兀消失 |
| `FLOAT_SPEED` | 50px/s | 20-100px/s | 飘动上升速度 | 消失太快，来不及读 | 飘太慢，视觉干扰 |
| `EASE_TYPE` | EASE_OUT | - | 弹性曲线 | - | - |

### 队列参数

| 参数 | 默认值 | 范围 | 说明 | 过高影响 | 过低影响 |
|------|-------|------|------|----------|----------|
| `MAX_VISIBLE` | 3 | 1-5 | 同时显示条数 | 屏幕太杂乱 | 反应慢 |
| `DEDUP_WINDOW` | 2.0s | - | 保留字段（已不用于时间去重，合并逻辑改为 HUD 就地刷新） | - | - |
| `MAX_QUEUE_SIZE` | 20 | 5-50 | 队列最大长度 | 内存占用高 | 消息可能丢失 |

### 显示参数

| 参数 | 默认值 | 类型 | 说明 |
|------|-------|------|------|
| `DEFAULT_DURATION` | 2.5s | float | 消息默认显示时长 |
| `WARNING_DURATION` | 3.0s | float | 警告类型消息时长 |
| `ERROR_DURATION` | 3.5s | float | 错误类型消息时长 |
| `SUCCESS_DURATION` | 3.0s | float | 成功类型消息时长 |

### 位置参数

| 参数 | 默认值 | 范围 | 说明 |
|------|-------|------|------|
| `ANCHOR_X` | CENTER | - | 水平锚点 |
| `ANCHOR_Y` | CENTER | - | 垂直锚点 |
| `OFFSET_X` | 0 | -100~100 | 水平偏移 |
| `OFFSET_Y` | -100 | -300~0 | 垂直偏移（负值偏上） |
| `SPACING` | 20px | 10-50px | 飘窗间距 |
| `TOAST_HEIGHT` | 40px | 30-60px | 单行飘窗高度 |
| `TOAST_PADDING_X` | 20px | 10-40px | 水平内边距 |
| `TOAST_PADDING_Y` | 8px | 4-16px | 垂直内边距 |

## Acceptance Criteria

### 功能测试

1. [ ] **通知类型显示**
   - [ ] `gain` - 金色文字，无背景
   - [ ] `cost` - 红色文字，无背景
   - [ ] `success` - 绿色文字，无背景
   - [ ] `warning` - 橙色文字，半透明黑色背景
   - [ ] `error` - 深红色文字，半透明黑色背景
   - [ ] `system` - 白色文字，无背景

2. [ ] **队列管理**
   - [ ] 同时显示不超过 3 条飘窗
   - [ ] 超出队列进入等待状态
   - [ ] 队列满（20条）时丢弃**最低优先级**消息（优先级相同时丢弃最旧的）
   - [ ] `priority <= 0` 强制设为 1，`priority > 4` 强制设为 4

3. [ ] **去重合并**
   - [ ] 正在显示同 id 消息时，收到第二条直接刷新（不创建新飘窗）
   - [ ] 合并后显示总数：`"耕地完成！" x2`
   - [ ] 合并时计时器重置（延迟消失）
   - [ ] 不同 id 的消息独立显示，互不干扰
   - [ ] NM 层 await 期间（HUD 正在显示）_process 不移除前一条
   - [ ] 合并计数上限 999，超出显示 "x999+"

4. [ ] **优先级打断**
   - [ ] `priority >= 3` 可打断正在显示的低优先级消息
   - [ ] `priority < 3` 正常排队，不打断

5. [ ] **动画效果**
   - [ ] 淡入动画 0.2s，平滑出现
   - [ ] 显示期间向上飘动，速度 50px/s
   - [ ] 淡出动画 0.3s，逐渐消失

6. [ ] **暂停恢复**
   - [ ] 打开全屏 UI 时队列暂停（`_is_paused=true`）
   - [ ] 暂停期间新消息正常显示（不阻塞）
   - [ ] 关闭 UI 后队列恢复，剩余消息继续显示

### 集成测试

1. [ ] **耕地成功** - 耕地时显示 `"耕地完成！"` **金色**飘窗
2. [ ] **耕地连续操作** - 快速耕地两次，显示 `"耕地完成！ x2"` 合并飘窗
3. [ ] **浇水/收获/播种** - 各自显示对应成功消息，**金色**
4. [ ] **没有种子/肥料** - 显示 `"没有种子了"` / `"没有肥料了"` **红色**飘窗
5. [ ] **体力不足** - 体力耗尽时尝试行动，显示 `"体力不足"` **白色**飘窗
6. [ ] **背包满** - 背包满时点击拾取，显示 `"背包已满"` **橙色**飘窗（带半透明黑背景）

### 性能测试

1. [ ] 快速发送 20 条不同消息，队列正常处理，不崩溃
2. [ ] 帧率影响 < 0.5fps
3. [ ] 内存占用 < 2MB

### 用户体验测试

1. [ ] 飘窗出现时不会遮挡游戏核心区域
2. [ ] 玩家能在一瞥之间识别通知类型（颜色）
3. [ ] 连续操作时飘窗不会造成视觉干扰（刷屏感）