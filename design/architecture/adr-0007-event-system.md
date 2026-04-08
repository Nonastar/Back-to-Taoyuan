# ADR-0007: 事件/消息系统架构

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏46个系统需要互相通信，但直接引用会造成强耦合。需要统一的事件系统来解耦系统间通信，确保代码可维护性和可测试性。

### 系统通信需求分析

| 通信类型 | 示例 | 频率 |
|----------|------|------|
| 状态变化 | 体力变化、金钱变化 | 高 |
| 时间推进 | 天结束、季节变化 | 中 |
| 玩家操作 | 拾取物品、收获作物 | 高 |
| NPC交互 | 对话完成、送礼 | 低 |
| 成就解锁 | 达成条件 | 低 |
| UI更新 | 打开面板、关闭面板 | 中 |

## Decision

### EventBus 设计 (参考 ADR-0002)

```gdscript
# autoload/event_bus.gd
class_name EventBus
extends Node

# ============ 时间系统 ============
signal day_started(day: int, season: String)
signal day_ended(day: int)
signal time_changed(hour: int, minute: int)
signal season_changed(season: String)
signal year_changed(year: int)

# ============ 玩家属性 ============
signal stamina_changed(current: float, maximum: float)
signal health_changed(current: float, maximum: float)
signal money_changed(amount: int)
signal player_stat_changed(stat_name: String, new_value: Variant)

# ============ 物品系统 ============
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)
signal item_used(item_id: String)
signal inventory_full
signal inventory_changed()

# ============ 农场系统 ============
signal crop_planted(plot_position: Vector2, crop_id: String)
signal crop_harvested(plot_position: Vector2, crop_id: String, quality: int, amount: int)
signal crop_watered(plot_position: Vector2)
signal plot_state_changed(plot_position: Vector2, old_state: String, new_state: String)

# ============ 技能系统 ============
signal skill_leveled_up(skill_id: String, new_level: int)
signal skill_experience_gained(skill_id: String, amount: int)

# ============ NPC/社交 ============
signal npc_interacted(npc_id: String)
signal npc_gift_given(npc_id: String, item_id: String, loved: bool)
signal npc_friendship_changed(npc_id: String, old_value: int, new_value: int)

# ============ 成就/任务 ============
signal achievement_unlocked(achievement_id: String)
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_progress_updated(quest_id: String, progress: int, target: int)

# ============ 战斗 ============
signal combat_started(enemy_id: String)
signal combat_ended(victory: bool)
signal damage_dealt(target_id: String, amount: int, damage_type: String)
signal enemy_defeated(enemy_id: String)

# ============ UI ============
signal ui_panel_opened(panel_id: String)
signal ui_panel_closed(panel_id: String)
signal tooltip_requested(item_id: String)
signal notification_requested(message: String, type: String)

# ============ 杂项 ============
signal game_paused
signal game_resumed
signal save_requested
signal load_requested(slot: int)
```

### 派发事件示例

```gdscript
# 在 InventorySystem 中派发事件

func add_item(item_id: String, amount: int) -> bool:
    var success = _add_to_inventory(item_id, amount)
    if success:
        # 派发事件 - 通知其他系统
        EventBus.item_added.emit(item_id, amount)
        EventBus.inventory_changed.emit()
    return success

func remove_item(item_id: String, amount: int) -> bool:
    var success = _remove_from_inventory(item_id, amount)
    if success:
        EventBus.item_removed.emit(item_id, amount)
        EventBus.inventory_changed.emit()
    return success
```

### 订阅事件示例

```gdscript
# 在 HUDManager 中订阅事件

func _ready():
    # 连接事件
    EventBus.stamina_changed.connect(_on_stamina_changed)
    EventBus.health_changed.connect(_on_health_changed)
    EventBus.money_changed.connect(_on_money_changed)
    EventBus.notification_requested.connect(_on_notification)

func _on_stamina_changed(current: float, maximum: float):
    stamina_bar.value = current
    stamina_bar.max_value = maximum

func _on_money_changed(amount: int):
    money_label.text = "%d 金" % amount

func _on_notification(message: String, type: String):
    NotificationManager.show_message(message)
```

### TypedEvent 增强 (可选)

对于需要传递数据的复杂事件，使用 Dictionary 或自定义信号：

```gdscript
# 复杂事件使用字典
signal custom_event(event_data: Dictionary)

# 派发
EventBus.custom_event.emit({
    "source": "combat_system",
    "target": "achievement_system",
    "data": {
        "enemies_defeated": 10
    }
})

# 订阅
func _on_custom_event(event_data: Dictionary):
    if event_data.get("source") == "combat_system":
        # 处理事件
        pass
```

### 事件命名规范

| 类别 | 前缀 | 示例 |
|------|------|------|
| 状态变化 | [noun]_changed | health_changed, stamina_changed |
| 添加 | [noun]_added | item_added, npc_gift_given |
| 移除 | [noun]_removed | item_removed |
| 操作完成 | [verb]_ed | crop_harvested, quest_completed |
| 请求 | [noun]_requested | save_requested, tooltip_requested |
| 解锁 | [noun]_unlocked | achievement_unlocked |

## Alternatives Considered

### Alternative 1: 直接系统引用

- **描述**: 系统A直接调用系统B的方法
- **优点**: 简单直接，IDE自动完成支持好
- **缺点**: 强耦合，难以测试，循环依赖风险
- **拒绝理由**: 46个系统会形成复杂的网状依赖

### Alternative 2: Unity风格 SendMessage

- **描述**: 通过GameObject.SendMessage广播消息
- **优点**: 完全解耦
- **缺点**: 运行时才发现错误，调试困难，无类型检查
- **拒绝理由**: 过于动态，类型安全差

### Alternative 3: 消息队列/命令模式

- **描述**: 事件先入队，延迟处理
- **优点**: 可控制执行顺序，支持撤销
- **缺点**: 增加复杂度，适合命令模式而非事件通知
- **拒绝理由**: 本游戏事件主要是通知，不需要延迟处理

## Consequences

### Positive
- **完全解耦**: 系统间无直接引用
- **可测试性**: 可单独测试每个系统
- **可扩展性**: 新增系统只需订阅相关事件
- **调试方便**: 可全局监听事件追踪问题

### Negative
- **隐式依赖**: 事件定义改变可能影响多个系统
- **性能开销**: 信号派发有少量开销
- **追踪困难**: 事件流可能难以追踪

### Risks

| 风险 | 缓解措施 |
|------|----------|
| 事件风暴 | 限制全局事件数量，每个事件有明确用途 |
| 内存泄漏 | 确保disconnect不再需要的信号 |
| 循环事件 | 避免在事件处理中派发同一事件 |

## Performance Implications

- **CPU**: 信号派发开销约 0.01-0.05ms
- **Memory**: 连接但不处理的事件无内存开销
- **建议**: 避免在 _process 中高频派发事件

## Validation Criteria

1. 所有跨系统通信通过 EventBus
2. 无直接 get_node("/root/...") 获取其他系统
3. 事件命名符合规范
4. 无循环事件派发
5. 单元测试覆盖事件订阅逻辑
