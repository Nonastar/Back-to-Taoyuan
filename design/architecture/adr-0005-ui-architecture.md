# ADR-0005: UI/菜单系统架构

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏包含大量UI面板（背包、商店、设置、对话等），需要统一的UI架构来管理面板的显示/隐藏、层级关系、动画过渡和输入路由，确保UI响应迅速且易于扩展。

### 项目UI分析

| UI类型 | 示例 | 显示条件 | 层级 |
|--------|------|----------|------|
| HUD | 体力条、金钱、日 | 常驻 | 底层 |
| 交互面板 | 对话框、商店 | 触发显示 | 中层 |
| 全屏菜单 | 背包、地图 | 暂停游戏 | 顶层 |
| 模态对话框 | 确认、提示 | 覆盖所有 | 最高层 |

## Decision

### UI层级定义

```gdscript
# ui/ui_layers.gd
class_name UILayers
extends Node

enum Layer {
    HUD = 0,           # 底层HUD
    INTERACTION = 1,   # 交互面板
    FULLSCREEN = 2,    # 全屏面板
    MODAL = 3,         # 模态对话框
    TOAST = 4,         # 提示消息
    DEBUG = 5          # 调试信息
}

# 层级节点结构
func _ready():
    for layer in Layer.keys():
        var node = Control.new()
        node.name = layer
        add_child(node)
```

### 场景结构

```
res://
├── scenes/
│   └── ui/
│       ├── ui_manager.tscn        # UI管理器
│       ├── layers/
│       │   ├── hud_layer.tscn     # HUD层
│       │   ├── interaction_layer.tscn
│       │   ├── fullscreen_layer.tscn
│       │   ├── modal_layer.tscn
│       │   └── toast_layer.tscn
│       │
│       ├── panels/
│       │   ├── inventory_panel.tscn
│       │   ├── shop_panel.tscn
│       │   ├── crafting_panel.tscn
│       │   ├── map_panel.tscn
│       │   └── settings_panel.tscn
│       │
│       ├── components/
│       │   ├── item_slot.tscn
│       │   ├── tooltip.tscn
│       │   ├── button_styles.tres
│       │   └── panel_styles.tres
│       │
│       └── dialogs/
│           ├── confirm_dialog.tscn
│           ├── message_dialog.tscn
│           └── input_dialog.tscn
```

### UIManager 设计

```gdscript
# systems/ui/ui_manager.gd
class_name UIManager
extends CanvasLayer

# 单例实例
static var instance: UIManager

# 层级引用
@onready var hud_layer: Control = $HUD
@onready var interaction_layer: Control = $Interaction
@onready var fullscreen_layer: Control = $Fullscreen
@onready var modal_layer: Control = $Modal
@onready var toast_layer: Control = $Toast

# UI状态
var is_ui_open: bool = false
var current_panel: Control = null
var panel_stack: Array[Control] = []

# 面板预设
var _panel_scenes: Dictionary = {
    "inventory": preload("res://scenes/ui/panels/inventory_panel.tscn"),
    "shop": preload("res://scenes/ui/panels/shop_panel.tscn"),
    "crafting": preload("res://scenes/ui/panels/crafting_panel.tscn"),
    "map": preload("res://scenes/ui/panels/map_panel.tscn"),
    "settings": preload("res://scenes/ui/panels/settings_panel.tscn"),
}

func _ready():
    instance = self
    _setup_layers()

func _setup_layers():
    # 确保各层级存在
    for layer_name in ["HUD", "Interaction", "Fullscreen", "Modal", "Toast"]:
        if not has_node(layer_name):
            var layer = Control.new()
            layer.name = layer_name
            add_child(layer)

# 显示面板
func show_panel(panel_id: String, layer: Layer = Layer.FULLSCREEN) -> void:
    if _panel_scenes.has(panel_id):
        var panel = _panel_scenes[panel_id].instantiate()
        _add_panel_to_layer(panel, layer)
        panel.open()
        panel_close_requested.connect(_on_panel_close_requested.bind(panel))

# 关闭面板
func close_panel(panel: Control) -> void:
    if panel == current_panel:
        panel_stack.pop_back()
        current_panel = panel_stack.back() if not panel_stack.is_empty() else null

    panel.close()
    panel.queue_free()

    is_ui_open = not panel_stack.is_empty()
    _update_game_pause_state()

# 关闭所有面板
func close_all_panels() -> void:
    while not panel_stack.is_empty():
        var panel = panel_stack.pop_back()
        panel.queue_free()

    current_panel = null
    is_ui_open = false
    _update_game_pause_state()

# 显示提示消息
func show_toast(message: String, duration: float = 2.0) -> void:
    var toast = preload("res://scenes/ui/components/toast.tscn").instantiate()
    toast_layer.add_child(toast)
    toast.show_message(message, duration)

# 显示确认对话框
func show_confirm(title: String, message: String) -> Promise:
    var dialog = preload("res://scenes/ui/dialogs/confirm_dialog.tscn").instantiate()
    modal_layer.add_child(dialog)
    return dialog.show_confirm(title, message)

func _on_panel_close_requested(panel: Control) -> void:
    close_panel(panel)

func _add_panel_to_layer(panel: Control, layer: Layer) -> void:
    match layer:
        Layer.HUD:
            hud_layer.add_child(panel)
        Layer.INTERACTION:
            interaction_layer.add_child(panel)
        Layer.FULLSCREEN:
            fullscreen_layer.add_child(panel)
        Layer.MODAL:
            modal_layer.add_child(panel)

    panel_stack.append(panel)
    current_panel = panel
    is_ui_open = true
    _update_game_pause_state()

func _update_game_pause_state() -> void:
    if is_ui_open:
        get_tree().paused = true
        # 可选择只暂停游戏逻辑，不暂停UI动画
    else:
        get_tree().paused = false
```

### 面板基类

```gdscript
# ui/panels/base_panel.gd
class_name BasePanel
extends Control

signal opened()
signal closed()
signal close_requested()

@export var transition_duration: float = 0.3
@export var pause_game: bool = true  # 是否暂停游戏

# 动画状态
var is_animating: bool = false
var is_open: bool = false

func _ready():
    # 初始隐藏
    visible = false
    modulate.a = 0

    # ESC键关闭
    key_pressed.connect(_on_key_pressed)

func open() -> void:
    if is_animating or is_open:
        return

    is_animating = true
    visible = true

    # 淡入动画
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, transition_duration)
    await tween.finished

    is_animating = false
    is_open = true
    opened.emit()

func close() -> void:
    if is_animating or not is_open:
        return

    is_animating = true

    # 淡出动画
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, transition_duration)
    await tween.finished

    visible = false
    is_animating = false
    is_open = false
    closed.emit()

func _on_key_pressed(key: int) -> void:
    if key == KEY_ESCAPE and is_open:
        close_requested.emit()

# 子类实现
func _on_confirm_pressed() -> void:
    pass

func _on_cancel_pressed() -> void:
    close()
```

### HUD管理器

```gdscript
# systems/ui/hud_manager.gd
class_name HUDManager
extends Control

@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var health_bar: ProgressBar = $HealthBar
@onready var money_label: Label = $MoneyLabel
@onready var day_label: Label = $DayLabel
@onready var season_label: Label = $SeasonLabel
@onready var time_indicator: TextureRect = $TimeIndicator

func _ready():
    # 连接游戏状态信号
    GameManager.stamina_changed.connect(_on_stamina_changed)
    GameManager.health_changed.connect(_on_health_changed)
    GameManager.money_changed.connect(_on_money_changed)
    TimeManager.day_changed.connect(_on_day_changed)
    TimeManager.time_changed.connect(_on_time_changed)

    _update_all()

func _on_stamina_changed(current: float, maximum: float) -> void:
    stamina_bar.value = current
    stamina_bar.max_value = maximum

func _on_health_changed(current: float, maximum: float) -> void:
    health_bar.value = current
    health_bar.max_value = maximum

func _on_money_changed(amount: int) -> void:
    money_label.text = "%d 金" % amount

func _on_day_changed(day: int, season: String) -> void:
    day_label.text = "第 %d 天" % day
    season_label.text = season

func _on_time_changed(hour: int) -> void:
    # 根据时间更新图标
    if hour < 6 or hour >= 20:
        time_indicator.texture = preload("res://assets/ui/moon.png")
    elif hour < 12:
        time_indicator.texture = preload("res://assets/ui/morning.png")
    else:
        time_indicator.texture = preload("res://assets/ui/afternoon.png")

func _update_all() -> void:
    var stats = GameManager.get_player_stats()
    _on_stamina_changed(stats.stamina, stats.max_stamina)
    _on_health_changed(stats.health, stats.max_health)
    _on_money_changed(stats.money)
```

### 工具提示系统

```gdscript
# systems/ui/tooltip_manager.gd
class_name TooltipManager
extends Control

@onready var tooltip_panel: Panel = $TooltipPanel
@onready var title_label: Label = $TooltipPanel/VBox/Title
@onready var desc_label: Label = $TooltipPanel/VBox/Description
@onready var stats_label: Label = $TooltipPanel/VBox/Stats

var _current_item: ItemData = null
var _follow_mouse: bool = true

func _process(delta: float) -> void:
    if _follow_mouse and tooltip_panel.visible:
        tooltip_panel.global_position = get_global_mouse_position() + Vector2(20, 20)

func show_item(item: ItemData) -> void:
    _current_item = item
    title_label.text = item.display_name
    desc_label.text = item.description

    if item.stats.size() > 0:
        var stats_text = ""
        for stat in item.stats:
            stats_text += "%s: %s\n" % [stat.key, stat.value]
        stats_label.text = stats_text
        stats_label.visible = true
    else:
        stats_label.visible = false

    tooltip_panel.visible = true

func hide() -> void:
    tooltip_panel.visible = false
    _current_item = null
```

## Alternatives Considered

### Alternative 1: 每个UI独立脚本

- **描述**: 每个UI面板独立管理自己的显示/隐藏
- **优点**: 简单直接，无需中央管理
- **缺点**: 难以统一控制层级、动画、暂停状态
- **拒绝理由**: 需要统一的UI生命周期管理

### Alternative 2: 使用Godot的SubViewport

- **描述**: 每个UI层使用独立的SubViewport
- **优点**: 完美隔离，可独立缩放
- **缺点**: 增加渲染开销，调试复杂
- **拒绝理由**: 对于本项目复杂度不必要

## Consequences

### Positive
- **统一管理**: 所有UI通过UIManager管理，状态一致
- **层级清晰**: 固定的层级顺序避免显示冲突
- **动画一致**: 统一的过渡动画提升体验
- **易于扩展**: 新增面板只需注册到管理器

### Negative
- **单点依赖**: UIManager成为强依赖
- **面板注册**: 新面板需要手动注册到字典

## Validation Criteria

1. 同时打开多个面板时层级正确
2. ESC键正确关闭当前面板
3. 面板打开/关闭有平滑动画
4. 游戏在UI打开时正确暂停
5. 工具提示跟随鼠标且不越界
