# ADR-0010: 动画系统架构

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏需要统一的动画系统来管理角色动画(行走、idle、攻击)、UI动画和特效动画。要求支持动画状态机、混合、过渡和动画事件触发。

### 动画需求分析

| 类型 | 示例 | 需求 |
|------|------|------|
| 角色idle | 站立呼吸 | 循环播放 |
| 角色行走 | 上下左右4方向 | 方向混合 |
| 角色动作 | 锄地、砍树 | 动作状态机 |
| UI过渡 | 面板淡入淡出 | 插值动画 |
| 特效 | 收获闪光 | 粒子/精灵动画 |

## Decision

### 动画文件结构

```
res://
├── assets/
│   └── sprites/
│       ├── player/
│       │   ├── idle/
│       │   │   ├── player_idle_down.png (4帧)
│       │   │   ├── player_idle_up.png
│       │   │   └── player_idle_side.png
│       │   ├── walk/
│       │   │   ├── player_walk_down.png (4帧)
│       │   │   ├── player_walk_up.png
│       │   │   └── player_walk_side.png
│       │   ├── action/
│       │   │   ├── player_hoe.png (4帧)
│       │   │   ├── player_water.png
│       │   │   └── player_axe.png
│       │   └── spritesheet.tres
│       │
│       ├── npc/
│       │   └── ...
│       │
│       ├── tileset/
│       │   └── ...
│       │
│       └── effects/
│           ├── harvest_glow.png
│           ├── level_up.png
│           └── ...
```

### 角色动画状态机

```gdscript
# entities/components/character_animation.gd
class_name CharacterAnimation
extends AnimatedSprite2D

@export var character: CharacterBody2D

# 动画方向
enum Direction { DOWN, UP, LEFT, RIGHT }
var _current_direction: Direction = Direction.DOWN

# 动画状态
enum AnimState { IDLE, WALK, ACTION, HURT, DEAD }
var _current_state: AnimState = AnimState.IDLE

# 动画映射
var _animations: Dictionary = {
    AnimState.IDLE: {
        Direction.DOWN: "idle_down",
        Direction.UP: "idle_up",
        Direction.LEFT: "idle_side",
        Direction.RIGHT: "idle_side"  # 复用侧向动画，flip处理方向
    },
    AnimState.WALK: {
        Direction.DOWN: "walk_down",
        Direction.UP: "walk_up",
        Direction.LEFT: "walk_side",
        Direction.RIGHT: "walk_side"
    }
}

# 动作动画 (无方向)
var _action_animations: Array = ["action_hoe", "action_water", "action_axe", "action_pick"]

func _ready():
    play("idle_down")

func _process(delta: float):
    if character:
        _update_direction()
        _update_animation()

func _update_direction():
    var velocity = character.velocity

    if abs(velocity.x) > abs(velocity.y):
        if velocity.x > 0:
            _current_direction = Direction.RIGHT
            sprite.flip_h = false
        else:
            _current_direction = Direction.LEFT
            sprite.flip_h = true
    elif velocity.y != 0:
        if velocity.y > 0:
            _current_direction = Direction.DOWN
        else:
            _current_direction = Direction.UP

func _update_animation():
    if _current_state == AnimState.ACTION:
        return  # 动作动画播放中不切换

    var is_moving = character.velocity.length() > 0.1

    if is_moving:
        _set_state(AnimState.WALK)
    else:
        _set_state(AnimState.IDLE)

func _set_state(new_state: AnimState):
    if _current_state == new_state:
        return

    _current_state = new_state

    if _animations.has(new_state):
        var anim_name = _animations[new_state][_current_direction]
        if animation != anim_name:
            play(anim_name)
    elif new_state == AnimState.IDLE:
        play(_animations[AnimState.IDLE][_current_direction])

# 播放动作动画 (带回调)
func play_action(action_name: String, on_complete: Callable = Callable()) -> void:
    _current_state = AnimState.ACTION

    if sprite.sprite_frames.has_animation(action_name):
        sprite.play(action_name)
        await sprite.animation_finished
        on_complete.call()
        _current_state = AnimState.IDLE
        _set_state(AnimState.IDLE)
    else:
        _current_state = AnimState.IDLE

# 播放受伤动画
func play_hurt(on_complete: Callable = Callable()) -> void:
    _current_state = AnimState.HURT
    modulate = Color(1, 0.5, 0.5)  # 变红

    await get_tree().create_timer(0.3).timeout
    modulate = Color.WHITE
    _current_state = AnimState.IDLE
    on_complete.call()
```

### 精灵表单配置

```gdscript
# resources/sprites/player_sprites.gd
class_name SpriteSheetConfig
extends Resource

@export var frame_width: int = 32
@export var frame_height: int = 32
@export var frames_count: int = 4
@export var fps: int = 8

# 预配置常用角色
static func get_player_config() -> SpriteSheetConfig:
    var config = SpriteSheetConfig.new()
    config.frame_width = 32
    config.frame_height = 48
    config.frames_count = 4
    config.fps = 8
    return config
```

### 简单插值动画工具

```gdscript
# systems/animation/tween_utils.gd
class_name TweenUtils
extends Node

# 通用动画函数
static func fade_in(node: CanvasItem, duration: float = 0.3) -> void:
    node.modulate.a = 0
    var tween = node.create_tween()
    tween.tween_property(node, "modulate:a", 1.0, duration)

static func fade_out(node: CanvasItem, duration: float = 0.3) -> void:
    var tween = node.create_tween()
    tween.tween_property(node, "modulate:a", 0.0, duration)
    await tween.finished
    node.visible = false

static func pop_in(node: Control, duration: float = 0.2) -> void:
    node.scale = Vector2.ZERO
    var tween = node.create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
    tween.tween_property(node, "scale", Vector2.ONE, duration)

static func bounce(node: Node2D, intensity: float = 5.0) -> void:
    var original_y = node.position.y
    var tween = node.create_tween().set_loops(2)
    tween.tween_property(node, "position:y", original_y - intensity, 0.1)
    tween.tween_property(node, "position:y", original_y, 0.2)

static func shake(node: Node2D, intensity: float = 3.0, duration: float = 0.3) -> void:
    var original_pos = node.position
    var tween = node.create_tween()
    var elapsed = 0.0

    while elapsed < duration:
        var offset = Vector2(
            randf_range(-intensity, intensity),
            randf_range(-intensity, intensity)
        )
        tween.tween_property(node, "position", original_pos + offset, 0.05)
        elapsed += 0.05

    tween.tween_property(node, "position", original_pos, 0.05)

# UI 面板动画
static func slide_in_from_right(panel: Control, duration: float = 0.3) -> void:
    var viewport_size = panel.get_viewport_rect().size
    panel.position.x = viewport_size.x
    panel.visible = true

    var tween = panel.create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(panel, "position:x", 0.0, duration)

static func slide_out_to_right(panel: Control, duration: float = 0.3) -> void:
    var viewport_size = panel.get_viewport_rect().size

    var tween = panel.create_tween()
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(panel, "position:x", viewport_size.x, duration)
    await tween.finished
    panel.visible = false
```

### 粒子效果封装

```gdscript
# systems/vfx/harvest_effect.gd
class_name HarvestEffect
extends Node2D

@export var particle_scene: PackedScene = preload("res://scenes/vfx/harvest_particle.tscn")

var _particles: Array[GPUParticles2D] = []

func spawn(position: Vector2, color: Color = Color(1, 0.8, 0.2)) -> void:
    var particles = GPUParticles2D.new()
    particles.position = position
    particles.amount = 20
    particles.lifetime = 0.8
    particles.explosiveness = 0.8
    particles.randomness = 0.5

    # 发射形状
    var circle = CircleShape2D.new()
    circle.radius = 10
    var shape = Node.new()
    shape.set("shape", circle)

    # 简单粒子材质
    var material = ParticleProcessMaterial.new()
    material.direction = Vector3(0, -1, 0)
    material.spread = 45.0
    material.initial_velocity_min = 50.0
    material.initial_velocity_max = 100.0
    material.gravity = Vector3(0, 200, 0)
    material.color = color

    particles.process_material = material

    add_child(particles)
    particles.emitting = true

    await get_tree().create_timer(1.0).timeout
    particles.queue_free()
```

### Sprite 方向工具

```gdscript
# systems/animation/sprite_utils.gd
class_name SpriteUtils
extends Node

# 根据移动方向获取精灵翻转
static func get_flip_direction(velocity: Vector2) -> Dictionary:
    var flip_h = false
    var direction = "down"

    if abs(velocity.x) > abs(velocity.y):
        if velocity.x > 0:
            flip_h = false
            direction = "side"
        else:
            flip_h = true
            direction = "side"
    elif velocity.y != 0:
        if velocity.y > 0:
            direction = "down"
        else:
            direction = "up"

    return {"flip_h": flip_h, "direction": direction}
```

## Alternatives Considered

### Alternative 1: AnimationTree (Godot 4.x)

- **描述**: 使用 Godot 内置的 AnimationTree
- **优点**: 功能强大，状态机可视化
- **缺点**: 学习曲线陡峭，配置复杂
- **拒绝理由**: 对于本游戏简单需求过于复杂

### Alternative 2: 第三方动画库

- **描述**: 使用 Spine/DragonBones
- **优点**: 专业骨骼动画
- **缺点**: 增加依赖，需要额外工具
- **拒绝理由**: 像素风格使用 SpriteSheet 足够

## Consequences

### Positive
- **轻量实现**: 基于 AnimatedSprite2D，简单高效
- **易于扩展**: 状态机模式便于添加新状态
- **工具函数**: TweenUtils 提供常用动画

### Negative
- **动画数量多**: 每个角色需要多个精灵表
- **方向处理**: 需要统一的方向约定

## Validation Criteria

1. 角色8方向行走动画正确
2. 动作动画播放时锁定移动
3. UI 面板动画流畅
4. 收获粒子效果正确显示
5. 动画帧率稳定
