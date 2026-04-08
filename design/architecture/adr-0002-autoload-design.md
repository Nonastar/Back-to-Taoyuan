# ADR-0002: Autoload 全局系统设计

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏需要多个全局管理器来处理核心系统（时间、存档、音频、库存等）。需要确定 Autoload 的设计模式、加载顺序和交互规范，确保系统间松耦合且易于维护。

### Constraints
- **技术约束**: Godot 4.6 Autoload 机制
- **兼容性**: 需支持热重载（开发时）
- **性能**: 需最小化全局状态开销

## Decision

### Autoload 分类

将全局系统分为三层：

| 层级 | 名称 | 加载时机 | 说明 |
|------|------|----------|------|
| **Core** | 核心层 | ProjectStart (最早) | 基础设施，不依赖其他系统 |
| **Game** | 游戏层 | _ready() 顺序 | 游戏逻辑，依赖Core层 |
| **UI** | UI层 | 按需加载 | UI相关，按需实例化 |

### Autoload 注册表

```
# project.godot 中的 [autoload] 配置

# Core层 (加载顺序固定)
GameManager         # 游戏状态总控
TimeManager         # 时间/季节管理
SaveManager         # 存档加载
EventBus            # 全局事件总线

# Game层 (加载顺序固定)
InventorySystem     # 物品管理
AudioManager        # 音频管理
WeatherManager      # 天气管理
NotificationManager # 通知管理

# UI层 (按需加载，不在此注册)
# UIManager          # UI管理器（场景实例化）
```

### 核心层设计

#### 1. GameManager

```gdscript
# autoload/game_manager.gd
class_name GameManager
extends Node

# 全局游戏状态
enum GameState { LOADING, MAIN_MENU, PLAYING, PAUSED, SAVING }

var current_state: GameState = GameState.LOADING
var is_new_game: bool = true

# 系统引用
var time_manager: TimeManager
var save_manager: SaveManager
var inventory_system: InventorySystem

func _ready() -> void:
    # 获取其他Autoload引用
    time_manager = get_node("/root/TimeManager")
    save_manager = get_node("/root/SaveManager")
    inventory_system = get_node("/root/InventorySystem")

    # 连接信号
    time_manager.day_ended.connect(_on_day_ended)
    save_manager.save_completed.connect(_on_save_completed)

func _on_day_ended() -> void:
    # 每日结算
    pass

func change_state(new_state: GameState) -> void:
    current_state = new_state
    state_changed.emit(new_state)

signal state_changed(state: GameState)
```

#### 2. EventBus (事件总线)

```gdscript
# autoload/event_bus.gd
class_name EventBus
extends Node

# 事件信号定义
signal day_started(day: int, season: String)
signal day_ended(day: int)
signal item_picked_up(item_id: String, amount: int)
signal npc_interacted(npc_id: String)
signal achievement_unlocked(achievement_id: String)
signal skill_leveled_up(skill_id: String, new_level: int)

# 按需添加更多事件信号...
```

#### 3. NotificationManager

```gdscript
# autoload/notification_manager.gd
class_name NotificationManager
extends Node

const NOTIFICATION_SCENE: String = "res://scenes/ui/notification.tscn"

# 通知队列
var _queue: Array[Dictionary] = []
var _is_showing: bool = false

func show_message(text: String, duration: float = 2.0, color: Color = Color.WHITE) -> void:
    _queue.append({"text": text, "duration": duration, "color": color})
    if not _is_showing:
        _show_next()

func _show_next() -> void:
    if _queue.is_empty():
        _is_showing = false
        return

    _is_showing = true
    var notification = _queue.pop_front()
    # 显示通知UI...
    await get_tree().create_timer(notification.duration).timeout
    _show_next()
```

### 游戏层设计

#### 库存系统接口

```gdscript
# autoload/inventory_system.gd
class_name InventorySystem
extends Node

# 背包容量
const DEFAULT_CAPACITY: int = 30
var _capacity: int = DEFAULT_CAPACITY
var _items: Dictionary = {}  # {item_id: amount}

# Autowired dependencies
var item_data_system: ItemDataSystem

func _ready() -> void:
    item_data_system = get_node("/root/ItemDataSystem")

func add_item(item_id: String, amount: int = 1) -> bool:
    # 查找现有堆叠
    var item_def = item_data_system.get_item(item_id)
    if item_def and item_def.get("stackable", false):
        # 堆叠逻辑
        pass

    # 检查容量
    if _items.size() >= _capacity and not _items.has(item_id):
        EventBus.inventory_full.emit()
        return false

    _items[item_id] = _items.get(item_id, 0) + amount
    EventBus.item_added.emit(item_id, amount)
    return true

func remove_item(item_id: String, amount: int = 1) -> bool:
    if not _items.has(item_id) or _items[item_id] < amount:
        return false

    _items[item_id] -= amount
    if _items[item_id] <= 0:
        _items.erase(item_id)

    EventBus.item_removed.emit(item_id, amount)
    return true

func get_item_count(item_id: String) -> int:
    return _items.get(item_id, 0)

signal inventory_full
```

### 加载顺序控制

```
1. Project.godot [autoload] 配置顺序决定加载顺序
2. _ready() 按配置顺序调用
3. Core层先于Game层加载完成
```

### 禁止事项

```gdscript
# 禁止: 直接获取其他Autoload的子节点
var player = get_node("/root/Player")  # 禁止！

# 推荐: 通过EventBus或公开API交互
EventBus.item_picked_up.emit("crop_tomato", 5)

# 或在需要时获取
func some_function():
    var player = get_tree().get_first_node_in_group("player")
```

## Alternatives Considered

### Alternative 1: 依赖注入模式

- **描述**: 通过场景构造时注入依赖，避免全局状态
- **优点**: 测试友好，更灵活的耦合控制
- **缺点**: 对于Godot场景层次不够自然，增加复杂性
- **拒绝理由**: 增加不必要的复杂性，Godot的Autoload足够本项目使用

### Alternative 2: 服务定位器模式

- **描述**: 全局注册表，按需获取服务
- **优点**: 延迟初始化，松耦合
- **缺点**: 隐式依赖，不如Autoload直观
- **拒绝理由**: Autoload足够简单直接

## Consequences

### Positive
- **加载顺序明确**: 避免初始化顺序问题
- **松耦合**: 通过EventBus实现系统间通信
- **易于调试**: Autoload在场景树中可见
- **热重载支持**: Autoload支持运行时重载

### Negative
- **全局状态**: 可能导致隐藏依赖
- **加载顺序敏感**: 新增Autoload需注意顺序

## Validation Criteria

1. 所有系统通过 EventBus 或公开API交互
2. 无循环Autoload依赖
3. Autoload数量控制在12个以内
4. 新增系统不影响现有系统加载
