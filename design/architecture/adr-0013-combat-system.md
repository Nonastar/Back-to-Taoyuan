# ADR-0013: 战斗系统架构

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏需要战斗系统支持采矿Boss战和沙漠怪物遭遇。战斗需要包含武器攻击、伤害计算、受击反馈和敌人AI。

### 战斗需求分析

| 场景 | 敌人类型 | 需求 |
|------|----------|------|
| 矿洞Boss | 巨型怪物 | 多阶段战斗 |
| 沙漠遭遇 | 沙漠怪物 | 群体战斗 |
| 野外遭遇 | 野猪、蝙蝠 | 简单遭遇 |

## Decision

### 战斗相关目录结构

```
res://
├── entities/
│   ├── player/
│   │   ├── player.tscn
│   │   └── combat/
│   │       ├── weapon_component.gd
│   │       └── attack_animator.gd
│   │
│   ├── enemies/
│   │   ├── base_enemy.gd
│   │   ├── slime.tscn
│   │   ├── bat.tscn
│   │   └── boss/
│   │       └── mine_boss.tscn
│   │
│   └── combat/
│       ├── hitbox.gd
│       ├── hurtbox.gd
│       └── damage_number.tscn
│
├── resources/
│   └── combat/
│       ├── weapon_data.gd
│       ├── enemy_data.gd
│       └── damage_formulas.gd
```

### 武器组件

```gdscript
# entities/player/combat/weapon_component.gd
class_name WeaponComponent
extends Node

@export var weapon_owner: CharacterBody2D
@export var hitbox_scene: PackedScene = preload("res://entities/combat/hitbox.tscn")

# 武器数据
var _weapon_data: WeaponData = null
var _attack_cooldown: float = 0.0
var _is_attacking: bool = false

signal attack_started()
signal attack_finished()
signal damage_dealt(target: Node2D, damage: int)

func _ready():
    # 默认武器
    _weapon_data = WeaponData.new()

func _process(delta: float):
    if _attack_cooldown > 0:
        _attack_cooldown -= delta

func equip_weapon(data: WeaponData) -> void:
    _weapon_data = data

func can_attack() -> bool:
    return _attack_cooldown <= 0 and not _is_attacking

# 执行攻击
func attack(direction: Vector2) -> void:
    if not can_attack():
        return

    _is_attacking = true
    attack_started.emit()

    # 创建攻击判定区域
    var hitbox = _create_hitbox(direction)

    # 等待动画播放
    var attack_duration = _weapon_data.attack_duration
    await get_tree().create_timer(attack_duration).timeout

    _is_attacking = false
    attack_finished.emit()

    # 清理hitbox
    hitbox.queue_free()

func _create_hitbox(direction: Vector2) -> Area2D:
    var hitbox = hitbox_scene.instantiate()
    hitbox.damage = _weapon_data.damage
    hitbox.knockback = _weapon_data.knockback
    hitbox.element = _weapon_data.element

    # 根据方向放置hitbox
    var offset = direction * (_weapon_data.range / 2)
    hitbox.global_position = weapon_owner.global_position + offset

    # 设置碰撞层
    hitbox.collision_mask = 1 << 4  # Monster层

    # 连接到伤害信号
    hitbox.hit.connect(_on_hit)

    get_tree().current_scene.add_child(hitbox)

    return hitbox

func _on_hit(target: Node2D, damage: int) -> void:
    damage_dealt.emit(target, damage)
    EventBus.damage_dealt.emit(target.name, damage, _weapon_data.element)
```

### 武器数据

```gdscript
# resources/combat/weapon_data.gd
class_name WeaponData
extends Resource

@export var weapon_id: String = ""
@export var display_name: String = ""
@export var damage: int = 10
@export var range: float = 48.0  # 攻击范围
@export var attack_duration: float = 0.3  # 攻击动画时长
@export var cooldown: float = 0.5  # 攻击冷却
@export var knockback: float = 100.0  # 击退力
@export var element: String = "physical"  # 元素属性
@export var stamina_cost: float = 10.0  # 体力消耗
@export var attack_sound: String = ""

# 武器类型
enum WeaponType {
    SWORD,
    AXE,
    PICKAXE,
    TOOL
}

@export var weapon_type: WeaponType = WeaponType.SWORD

# 创建预设武器
static func create_sword() -> WeaponData:
    var data = WeaponData.new()
    data.weapon_id = "sword_basic"
    data.display_name = "铁剑"
    data.damage = 15
    data.range = 48.0
    data.attack_duration = 0.3
    data.cooldown = 0.5
    data.knockback = 100.0
    return data

static func create_axe() -> WeaponData:
    var data = WeaponData.new()
    data.weapon_id = "axe_basic"
    data.display_name = "铜斧"
    data.damage = 20
    data.range = 40.0
    data.attack_duration = 0.4
    data.cooldown = 0.8
    data.knockback = 150.0
    data.weapon_type = WeaponType.AXE
    return data
```

### Hitbox 组件

```gdscript
# entities/combat/hitbox.gd
class_name Hitbox
extends Area2D

@export var damage: int = 10
@export var knockback: float = 100.0
@export var element: String = "physical"

# 已击中的目标 (防止一击多次)
var _hit_targets: Array = []

signal hit(target: Node2D, damage: int)

func _ready():
    # 配置碰撞
    collision_layer = 0
    collision_mask = 1 << 4  # Monster层

    # 碰撞形状
    var shape = CircleShape2D.new()
    shape.radius = 24.0
    var col = CollisionShape2D.new()
    col.shape = shape
    add_child(col)

    # 延迟启用碰撞
    await get_tree().process_frame
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body is HurtboxComponent:
        if body.owner not in _hit_targets:
            _hit_targets.append(body.owner)
            hit.emit(body.owner, damage)
            body.receive_damage(damage, knockback, element)
```

### Hurtbox 组件

```gdscript
# entities/combat/hurtbox.gd
class_name HurtboxComponent
extends Area2D

signal damaged(amount: int)

@export var owner_entity: Node2D
@export var invincibility_duration: float = 0.5  # 无敌时间

var _is_invincible: bool = false
var _health_component: HealthComponent = null

func _ready():
    collision_layer = 0
    collision_mask = 0  # 由子类型设置

    if owner_entity and owner_entity.has_node("HealthComponent"):
        _health_component = owner_entity.get_node("HealthComponent")

func receive_damage(amount: int, knockback_force: float, element: String) -> void:
    if _is_invincible:
        return

    # 计算实际伤害 (待扩展：护甲、元素克制等)
    var final_damage = amount

    if _health_component:
        _health_component.take_damage(final_damage)

    damaged.emit(final_damage)

    # 无敌时间
    _start_invincibility()

    # 击退
    _apply_knockback(knockback_force)

    # 受伤视觉反馈
    _show_damage_effect()

func _start_invincibility() -> void:
    _is_invincible = true
    await get_tree().create_timer(invincibility_duration).timeout
    _is_invincible = false

func _apply_knockback(force: float) -> void:
    if owner_entity is CharacterBody2D:
        # 简化击退
        pass

func _show_damage_effect():
    if owner_entity is AnimatedSprite2D:
        var sprite = owner_entity as AnimatedSprite2D
        var original_modulate = sprite.modulate
        sprite.modulate = Color(1.0, 0.3, 0.3)  # 红色闪烁
        await get_tree().create_timer(0.1).timeout
        sprite.modulate = original_modulate
```

### 健康组件

```gdscript
# entities/components/health_component.gd
class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal died()
signal damaged(amount: int)

@export var max_health: int = 100
@export var current_health: int = 100

var _defense: int = 0
var _element_resistances: Dictionary = {}

func _ready():
    health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
    # 应用防御力
    var actual_damage = max(1, amount - _defense)
    current_health = max(0, current_health - actual_damage)

    damaged.emit(actual_damage)
    health_changed.emit(current_health, max_health)

    if current_health <= 0:
        died.emit()

func heal(amount: int) -> void:
    current_health = min(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)

func set_max_health(value: int) -> void:
    max_health = value
    current_health = min(current_health, max_health)
    health_changed.emit(current_health, max_health)

func add_defense(amount: int) -> void:
    _defense += amount

func set_defense(amount: int) -> void:
    _defense = amount
```

### 敌人基类

```gdscript
# entities/enemies/base_enemy.gd
class_name BaseEnemy
extends CharacterBody2D

@export var enemy_data: EnemyData

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ai_state_machine: StateMachine = $AIStateMachine

# 敌人状态
enum EnemyState { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }
var _current_state: EnemyState = EnemyState.IDLE

func _ready():
    health_component.max_health = enemy_data.max_health
    health_component.current_health = enemy_data.max_health

    health_component.died.connect(_on_died)

func _on_died():
    _current_state = EnemyState.DEAD
    ai_state_machine.set_state("dead")
    # 播放死亡动画
    sprite.play("death")
    await sprite.animation_finished
    # 掉落物品
    _drop_loot()
    # 移除
    queue_free()

func _drop_loot():
    var drop_table = enemy_data.drop_table
    if drop_table:
        var drops = drop_table.roll_drops()
        for drop in drops:
            var item = load("res://entities/items/dropped_item.tscn").instantiate()
            item.item_id = drop.item_id
            item.amount = drop.amount
            item.global_position = global_position
            get_tree().current_scene.add_child(item)
```

### 敌人AI状态机

```gdscript
# entities/enemies/ai/state_machine.gd
class_name EnemyStateMachine
extends Node

@export var enemy: BaseEnemy

var _current_state: String = "idle"
var _state_time: float = 0.0

var _states: Dictionary = {}

func _ready():
    _states = {
        "idle": IdleState.new(self),
        "patrol": PatrolState.new(self),
        "chase": ChaseState.new(self),
        "attack": AttackState.new(self),
        "hurt": HurtState.new(self),
        "dead": DeadState.new(self)
    }

    set_state("idle")

func _process(delta: float):
    _state_time += delta
    if _states.has(_current_state):
        _states[_current_state].update(delta)

func set_state(new_state: String) -> void:
    if _states.has(_current_state):
        _states[_current_state].exit()

    _current_state = new_state
    _state_time = 0.0

    if _states.has(_current_state):
        _states[_current_state].enter()

func _physics_process(delta: float):
    if _states.has(_current_state):
        _states[_current_state].physics_update(delta)
```

### Boss战斗系统

```gdscript
# entities/enemies/boss/mine_boss.gd
class_name MineBoss
extends BaseEnemy

@export var phases: Array[BossPhase] = []

var _current_phase: int = 0
var _phase_health_threshold: float = 0.5

func _ready():
    super._ready()
    health_component.health_changed.connect(_on_health_changed)

func _on_health_changed(current: int, maximum: int):
    var ratio = float(current) / float(maximum)

    # 检查是否进入新阶段
    for i in range(phases.size()):
        if ratio <= phases[i].health_threshold and i > _current_phase:
            _enter_phase(i)
            break

func _enter_phase(phase_index: int) -> void:
    _current_phase = phase_index
    var phase = phases[phase_index]

    # 通知进入新阶段
    EventBus.boss_phase_changed.emit(self.name, phase_index)

    # 改变AI行为
    ai_state_machine.set_state(phase.ai_state)

    # 播放阶段过渡动画
    sprite.play("phase_transition")
    await sprite.animation_finished

    # 特殊技能冷却
    _activate_phase_skills(phase)

# Boss特殊技能
func _activate_phase_skills(phase: BossPhase):
    if phase.has_special_attack:
        # 启动特殊攻击定时器
        pass

[System.Serializable]
class BossPhase:
    @export var health_threshold: float = 1.0  # 进入此阶段的血量比例
    @export var ai_state: String = "chase"
    @export var has_special_attack: bool = false
    @export var special_attack_name: String = ""
    @export var movement_speed_multiplier: float = 1.0
```

## Alternatives Considered

### Alternative 1: 回合制战斗

- **描述**: 回合制RPG风格
- **优点**: 实现简单，策略性强
- **缺点**: 不符合ARPG节奏
- **拒绝理由**: 采矿战斗需要即时感

### Alternative 2: 使用Godot内置Combat

- **描述**: Godot没有内置战斗系统
- **优点**: N/A
- **缺点**: N/A
- **拒绝理由**: 需要自建

## Consequences

### Positive
- **组件化**: 各组件职责清晰
- **可扩展**: 易于添加新敌人类型
- **Boss支持**: 多阶段战斗框架

### Negative
- **实现复杂**: 需要多个组件配合
- **调试难度**: 状态机需要仔细测试

## Validation Criteria

1. 玩家攻击正确造成伤害
2. 敌人受击后正确响应
3. 敌人AI正确追踪和攻击
4. Boss多阶段正确切换
5. 伤害数值正确显示
