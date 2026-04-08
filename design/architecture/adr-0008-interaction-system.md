# ADR-0008: 交互系统架构

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
玩家需要与游戏中的各种对象交互（NPC对话、物品拾取、门开启、商店进入等），需要统一的交互检测、触发和反馈机制，确保交互体验一致且易于扩展。

### 交互对象分析

| 交互对象 | 交互方式 | 结果 |
|----------|----------|------|
| NPC | 靠近 + 按键 | 对话/送礼/战斗 |
| 物品 | 靠近 + 按键 | 拾取 |
| 门 | 靠近 + 按键 | 场景切换 |
| 宝箱 | 靠近 + 按键 | 获得物品 |
| 告示牌 | 靠近 + 按键 | 显示文本 |
| 机器 | 靠近 + 按键 | 打开加工界面 |
| 地块 | 点击 | 耕地/种植/收获 |

## Decision

### 碰撞层级配置

```
[layer_names]

2d_physics/layer_1 = "Player"
2d_physics/layer_2 = "World"
2d_physics/layer_3 = "Interactable"
2d_physics/layer_4 = "NPC"
2d_physics/layer_5 = "Monster"
2d_physics/layer_6 = "Item"
2d_physics/layer_7 = "Trigger"
```

### Interactable 基类

```gdscript
# entities/components/interactable.gd
class_name Interactable
extends Area2D

signal interacted(interactor: Node)
signal interaction_available_changed(available: bool)

@export_group("Interaction Settings")
@export var interaction_radius: float = 48.0  # 交互半径
@export var interaction_key: String = "interact"  # 对应输入
@export var required_item: String = ""  # 需要的物品ID
@export var min_player_level: int = 0  # 最低玩家等级

@export_group("Feedback")
@export var show_prompt: bool = true  # 是否显示提示
@export var prompt_text: String = "交互"
@export var auto_interact: bool = false  # 是否自动交互(传送点)

@export_group("Conditions")
@export var interaction_conditions: Array[Resource] = []  # 条件脚本

var _is_available: bool = false
var _player_in_range: bool = false

func _ready():
    # 碰撞检测
    collision_layer = 0
    collision_mask = 1 << 0  # 只检测Player层

    # 交互范围
    var shape = CircleShape2D.new()
    shape.radius = interaction_radius
    $CollisionShape2D.shape = shape

    # 连接信号
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    _update_availability()

func _process(delta: float):
    if _player_in_range and _is_available:
        if Input.is_action_just_pressed(interaction_key):
            _interact(get_tree().get_first_node_in_group("player"))

# 检测玩家进入范围
func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        _player_in_range = true
        _update_availability()
        if show_prompt:
            _show_prompt()

# 玩家离开范围
func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player"):
        _player_in_range = false
        _update_availability()
        if show_prompt:
            _hide_prompt()

func _update_availability() -> void:
    var was_available = _is_available

    # 检查所有条件
    _is_available = _player_in_range
    if _is_available:
        if required_item != "" and not InventorySystem.has_item(required_item):
            _is_available = false
        if GameManager.player_level < min_player_level:
            _is_available = false
        for condition in interaction_conditions:
            if condition and not condition.check():
                _is_available = false

    if was_available != _is_available:
        interaction_available_changed.emit(_is_available)
        if show_prompt:
            _update_prompt()

func _interact(player: Node) -> void:
    if not _is_available:
        return

    # 播放交互音效
    AudioManager.play_sfx("interact")

    # 派发事件
    interacted.emit(player)

    # 执行具体交互逻辑(子类实现)
    _do_interaction(player)

# 子类重写
func _do_interaction(player: Node) -> void:
    pass

# UI提示
func _show_prompt() -> void:
    # 创建或显示交互提示
    if not has_node("Prompt"):
        var prompt = Label.new()
        prompt.name = "Prompt"
        prompt.text = "[E] " + prompt_text
        prompt.global_position = global_position + Vector2(0, -50)
        get_tree().current_scene.add_child(prompt)
    else:
        get_node("Prompt").visible = true

func _hide_prompt() -> void:
    if has_node("Prompt"):
        get_node("Prompt").queue_free()

func _update_prompt() -> void:
    if has_node("Prompt"):
        var prompt = get_node("Prompt")
        if _is_available:
            prompt.text = "[E] " + prompt_text
            prompt.modulate = Color.WHITE
        else:
            prompt.text = prompt_text + " (不可用)"
            prompt.modulate = Color.GRAY
```

### 交互对象类型

```gdscript
# entities/interactables/npc_interactable.gd
class_name NPCInteractable
extends Interactable

@export var npc_id: String = ""

func _do_interaction(player: Node) -> void:
    # 打开NPC对话
    DialogueManager.start_dialogue(npc_id)
```

```gdscript
# entities/interactables/pickup_interactable.gd
class_name PickupInteractable
extends Interactable

@export var item_id: String = ""
@export var amount: int = 1
@export var respawn_time: float = 0.0  # 0=不重生

var _picked_up: bool = false

func _do_interaction(player: Node) -> void:
    if _picked_up:
        return

    # 尝试添加到背包
    if InventorySystem.add_item(item_id, amount):
        _picked_up = true
        _hide_prompt()
        queue_free()

        # 粒子效果
        EffectManager.spawn_pickup_effect(global_position)

        EventBus.item_added.emit(item_id, amount)
    else:
        NotificationManager.show_toast("背包已满!")
```

```gdscript
# entities/interactables/door_interactable.gd
class_name DoorInteractable
extends Interactable

@export var target_scene: String = ""
@export var target_spawn: String = ""
@export var fade_color: Color = Color.BLACK

func _do_interaction(player: Node) -> void:
    # 场景切换
    SceneTransition.fade_to_scene(target_scene, target_spawn)
```

### 交互条件检查器

```gdscript
# systems/interaction/conditions/interaction_condition.gd
class_name InteractionCondition
extends Resource

@export var fail_message: String = "无法交互"

func check() -> bool:
    return true

func get_fail_message() -> String:
    return fail_message
```

```gdscript
# systems/interaction/conditions/has_item_condition.gd
class_name HasItemCondition
extends InteractionCondition

@export var required_item: String = ""
@export var required_amount: int = 1

func check() -> bool:
    return InventorySystem.has_item(required_item, required_amount)
```

```gdscript
# systems/interaction/conditions/quest_condition.gd
class_name QuestCondition
extends InteractionCondition

@export var quest_id: String = ""
@export var require_started: bool = true
@export var require_completed: bool = false

func check() -> bool:
    if require_started and not QuestSystem.has_started(quest_id):
        return false
    if require_completed and not QuestSystem.is_completed(quest_id):
        return false
    return true
```

### 交互提示UI

```gdscript
# systems/ui/interaction_prompt.gd
class_name InteractionPrompt
extends Control

@onready var label: Label = $Label
@onready var icon: TextureRect = $Icon

var _current_target: Interactable = null

func show_for(target: Interactable) -> void:
    if _current_target == target:
        return

    hide_current()
    _current_target = target
    visible = true

    label.text = "[E] " + target.prompt_text
    target.interaction_available_changed.connect(_on_availability_changed)

    _update_position(target)

func hide_current() -> void:
    if _current_target:
        _current_target.interaction_available_changed.disconnect(_on_availability_changed)
        _current_target = null
    visible = false

func _process(delta: float) -> void:
    if _current_target and is_instance_valid(_current_target):
        _update_position(_current_target)

func _update_position(target: Interactable) -> void:
    global_position = target.global_position + Vector2(0, -60)

func _on_availability_changed(available: bool) -> void:
    if _current_target:
        if available:
            label.text = "[E] " + _current_target.prompt_text
            label.modulate = Color.WHITE
        else:
            label.text = _current_target.prompt_text
            label.modulate = Color.GRAY
```

### 场景切换过渡

```gdscript
# systems/scene/scene_transition.gd
class_name SceneTransition
extends CanvasLayer

@export var transition_duration: float = 0.5
@export var transition_color: Color = Color.BLACK

var _transition_rect: ColorRect
var _tween: Tween

func _ready():
    _transition_rect = ColorRect.new()
    _transition_rect.color = transition_color
    _transition_rect.visible = false
    add_child(_transition_rect)

    # 全屏覆盖
    _transition_rect.anchors_preset = Control.PRESET_FULLSIZE

func fade_to_scene(scene_path: String, spawn_point: String = "") -> void:
    _fade_out()

    await _tween.finished

    # 加载新场景
    get_tree().change_scene_to_file(scene_path)

    # 设置玩家位置
    if spawn_point != "":
        var spawn = get_tree().get_first_node_in_group("spawn_" + spawn_point)
        if spawn:
            get_tree().get_first_node_in_group("player").global_position = spawn.global_position

    _fade_in()

func _fade_out() -> void:
    _transition_rect.visible = true
    _tween = create_tween()
    _tween.tween_property(_transition_rect, "color:a", 1.0, transition_duration)

func _fade_in() -> void:
    _tween = create_tween()
    _tween.tween_property(_transition_rect, "color:a", 0.0, transition_duration)
    _tween.finished.connect(func(): _transition_rect.visible = false)
```

## Alternatives Considered

### Alternative 1: Raycast 检测交互

- **描述**: 从玩家发射射线检测前方的交互对象
- **优点**: 可精确控制交互方向
- **缺点**: 实现复杂，边缘情况多
- **拒绝理由**: 2D游戏圆形区域检测足够

### Alternative 2: 距离检测 (无碰撞)

- **描述**: 通过距离判断交互
- **优点**: 实现简单
- **缺点**: 无法区分重叠对象
- **拒绝理由**: 需要碰撞区分不同的交互对象

## Consequences

### Positive
- **统一接口**: 所有交互对象继承同一基类
- **条件可组合**: 通过条件脚本实现复杂需求
- **反馈一致**: 统一的提示UI

### Negative
- **对象需要碰撞**: 所有交互对象需要添加Area2D
- **条件脚本增加复杂度**: 需要维护条件资源文件

## Validation Criteria

1. 玩家靠近对象时显示交互提示
2. 按E键正确触发交互
3. 条件不满足时提示正确显示
4. 场景切换有过渡动画
5. 交互反馈延迟 < 1帧
