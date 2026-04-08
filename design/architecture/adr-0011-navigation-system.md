# ADR-0011: 寻路/导航系统架构

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏需要寻路系统让玩家和NPC在地图上移动。需要支持网格寻路(A*)避障，同时处理边界、障碍物和导航网格生成。

### 寻路需求分析

| 实体 | 需求 | 复杂度 |
|------|------|--------|
| 玩家 | 点击移动、避障 | 中 |
| NPC | 自动行走、跟随 | 中 |
| 动物 | 简单徘徊 | 低 |
| 怪物 | 追踪玩家、追捕AI | 高 |

## Decision

### 导航配置

在 `project.godot` 中启用 Navigation:

```ini
[nav]

2d/enable_painted_area_tint=false
2d/default_cell_size=16

[layer_names]

2d_physics/layer_1="Player"
2d_physics/layer_2="World"
2d_physics/layer_3="Interactable"
2d_physics/layer_4="NPC"
2d_physics/layer_5="Monster"
2d_physics/layer_6="Item"
2d_physics/layer_7="NavigationObstacle"
```

### NavigationRegion2D 场景结构

```
res://
├── scenes/
│   └── levels/
│       ├── farm/
│       │   ├── farm.tscn
│       │   ├── farm_navregion.tscn    # 导航区域
│       │   ├── farm_walls.tscn        # 墙壁碰撞
│       │   └── farm_obstacles.tscn    # 可移动障碍物
│       │
│       └── town/
│           ├── town.tscn
│           ├── town_navregion.tscn
│           └── ...
```

### 寻路服务

```gdscript
# systems/navigation/pathfinder.gd
class_name Pathfinder
extends Node

static var instance: Pathfinder

# 导航地图
var _nav_region: NavigationRegion2D = null
var _nav_map: NavigationMap = null

func _ready():
    instance = self

func setup(nav_region: NavigationRegion2D) -> void:
    _nav_region = nav_region
    _nav_map = nav_region.get_navigation_map()

# 计算路径
func get_path(from: Vector2, to: Vector2) -> PackedVector2Array:
    if _nav_map == null:
        return PackedVector2Array([to])

    return NavigationServer2D.map_get_path(_nav_map, from, to, true)

# 获取最近可导航点
func get_closest_point(point: Vector2) -> Vector2:
    if _nav_map == null:
        return point

    return NavigationServer2D.map_get_closest_point(_nav_map, point)

# 检查点是否可达
func is_point_reachable(point: Vector2) -> bool:
    var nearest = get_closest_point(point)
    return nearest.distance_to(point) < 32.0  # 阈值

# 获取随机导航点
func get_random_point(region_id: int) -> Vector2:
    return NavigationServer2D.region_get_random_point(region_id, true)
```

### 角色移动组件

```gdscript
# entities/components/movement_component.gd
class_name MovementComponent
extends Node

@export var character_body: CharacterBody2D

# 移动参数
@export var move_speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

# 寻路参数
@export var use_pathfinding: bool = true
@export var pathfinding_threshold: float = 100.0  # 超过此距离使用寻路

# 当前目标
var _target_position: Vector2 = Vector2.ZERO
var _current_path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0

# 状态
var is_moving: bool = false

func _physics_process(delta: float):
    if not is_moving:
        character_body.velocity = character_body.velocity.move_toward(Vector2.ZERO, friction * delta)
        return

    var direction = Vector2.ZERO

    if use_pathfinding and _current_path.size() > 0:
        # 沿路径移动
        var target = _current_path[_path_index]
        direction = (target - character_body.global_position).normalized()

        # 检查是否到达路径点
        if character_body.global_position.distance_to(target) < 16.0:
            _path_index += 1
            if _path_index >= _current_path.size():
                # 到达终点
                is_moving = false
                _current_path.clear()
                return
    else:
        # 直接向目标移动
        direction = (_target_position - character_body.global_position).normalized()

        if character_body.global_position.distance_to(_target_position) < 16.0:
            is_moving = false
            return

    # 应用移动
    character_body.velocity = character_body.velocity.move_toward(direction * move_speed, acceleration * delta)
    character_body.move_and_slide()

# 移动到位置
func move_to(position: Vector2) -> void:
    _target_position = position

    if use_pathfinding:
        # 计算路径
        var start = Pathfinder.get_closest_point(character_body.global_position)
        var end = Pathfinder.get_closest_point(position)

        var distance = start.distance_to(end)

        if distance > pathfinding_threshold:
            _current_path = Pathfinder.get_path(start, end)
            _path_index = 0
        else:
            _current_path.clear()

    is_moving = true

# 停止移动
func stop() -> void:
    is_moving = false
    _current_path.clear()
    _path_index = 0
    character_body.velocity = Vector2.ZERO

# 看向方向
func look_at_direction(direction: Vector2) -> void:
    if direction.length() > 0.1:
        character_body.rotation = direction.angle()
```

### 导航障碍物组件 (用于动态障碍)

```gdscript
# entities/components/navigation_obstacle.gd
class_name NavigationObstacle
extends Node2D

@export var radius: float = 16.0

var _obstacle: NavigationAgent2D

func _ready():
    _obstacle = NavigationAgent2D.new()
    add_child(_obstacle)
    _obstacle.radius = radius

func _physics_process(delta: float):
    # 更新障碍物位置
    _obstacle.global_position = global_position

# 临时禁用障碍 (用于玩家交互)
func set_enabled(enabled: bool) -> void:
    _obstacle.enabled = enabled
```

### NPC 行为组件

```gdscript
# entities/npc/npc_behavior.gd
class_name NPCBehavior
extends Node

@export var npc: CharacterBody2D
@export var movement: MovementComponent

# NPC 行为类型
@export var behavior_type: BehaviorType = BehaviorType.IDLE

enum BehaviorType {
    IDLE,           # 静止
    WANDER,         # 随机徘徊
    PATROL,         # 巡逻路径
    FOLLOW,          # 跟随玩家
    FLEE            # 逃离
}

# 徘徊参数
@export var wander_range: float = 100.0
@export var wander_interval: float = 3.0  # 秒
@export var patrol_points: Array[Vector2] = []
var _current_patrol_index: int = 0
var _wander_timer: float = 0.0

# 跟随参数
@export var follow_distance: float = 50.0
@export var stop_follow_distance: float = 200.0

func _physics_process(delta: float):
    match behavior_type:
        BehaviorType.IDLE:
            _do_idle()
        BehaviorType.WANDER:
            _do_wander(delta)
        BehaviorType.PATROL:
            _do_patrol()
        BehaviorType.FOLLOW:
            _do_follow()
        BehaviorType.FLEE:
            _do_flee()

func _do_idle():
    movement.stop()

func _do_wander(delta: float):
    if not movement.is_moving:
        _wander_timer += delta
        if _wander_timer >= wander_interval:
            _wander_timer = 0.0
            _start_wander()

func _start_wander():
    var random_offset = Vector2(
        randf_range(-wander_range, wander_range),
        randf_range(-wander_range, wander_range)
    )
    var target = npc.global_position + random_offset
    movement.move_to(target)

func _do_patrol():
    if not movement.is_moving and patrol_points.size() > 0:
        var target = patrol_points[_current_patrol_index]
        movement.move_to(target)

        if npc.global_position.distance_to(target) < 32.0:
            _current_patrol_index = (_current_patrol_index + 1) % patrol_points.size()

func _do_follow():
    var player = get_tree().get_first_node_in_group("player")
    if player == null:
        return

    var distance = npc.global_position.distance_to(player.global_position)

    if distance > stop_follow_distance:
        movement.move_to(player.global_position)
    elif distance < follow_distance:
        movement.stop()

func _do_flee():
    var player = get_tree().get_first_node_in_group("player")
    if player == null:
        return

    var flee_direction = (npc.global_position - player.global_position).normalized()
    var flee_target = npc.global_position + flee_direction * 200.0
    movement.move_to(flee_target)

# 切换行为
func set_behavior(type: BehaviorType) -> void:
    behavior_type = type
    movement.stop()
```

### 碰撞层配置

```gdscript
# 碰撞层 (在 NavigationRegion2D 的 NavigationPolygonInstance 中设置)
# Layer: NavigationPolygon 定义的导航区域

# 碰撞层 (CharacterBody 使用)
const PLAYER_LAYER = 1  # Player
const NPC_LAYER = 4     # NPC

# 障碍物层 (NavigationObstacle2D 使用)
const OBSTACLE_LAYER = 7  # NavigationObstacle
```

### 地图边界处理

```gdscript
# systems/navigation/map_bounds.gd
class_name MapBounds
extends Node

@export var bounds_rect: Rect2 = Rect2(-500, -500, 1000, 1000)
@export var margin: float = 32.0

# 限制位置在边界内
static func clamp_to_bounds(position: Vector2) -> Vector2:
    var min_pos = Vector2(bounds_rect.position.x + margin, bounds_rect.position.y + margin)
    var max_pos = Vector2(bounds_rect.end.x - margin, bounds_rect.end.y - margin)
    return position.clamp(Rect2(min_pos, max_pos - min_pos))

# 检查位置是否在边界内
static func is_in_bounds(position: Vector2) -> bool:
    return bounds_rect.has_point(position)
```

## Alternatives Considered

### Alternative 1: 简单距离计算移动

- **描述**: 不使用NavMesh，直接沿向量移动
- **优点**: 实现简单
- **缺点**: 无法避障
- **拒绝理由**: 需要避开障碍物

### Alternative 2: A* Grid 寻路自己实现

- **描述**: 在代码中实现A*算法
- **优点**: 完全可控
- **缺点**: 复杂度高，需要自己维护网格
- **拒绝理由**: Godot NavigationServer 已实现

## Consequences

### Positive
- **原生支持**: 使用 Godot NavigationServer
- **性能优化**: NavMesh 预计算
- **动态避障**: NavigationObstacle 支持动态障碍

### Negative
- **NavMesh 生成**: 复杂地形需要手动调整
- **性能限制**: 大量同时寻路可能有性能影响

## Validation Criteria

1. 玩家点击移动正确避障
2. NPC 巡逻路径正确
3. 动态障碍物实时避障
4. 地图边界正确限制移动
5. 寻路性能 < 5ms (100个实体)
