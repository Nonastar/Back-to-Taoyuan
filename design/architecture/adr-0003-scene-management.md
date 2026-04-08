# ADR-0003: 场景管理与加载策略

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏包含多个区域（农场、城镇、矿洞、沙漠等）和大量实体。需要确定场景的组织方式、加载策略和切换机制，确保无缝的地图体验和合理的内存使用。

### 项目场景分析

| 区域 | 类型 | 实体数量 | 特殊需求 |
|------|------|----------|----------|
| 农场 | 室内/室外 | ~200 | 昼夜变化、温室 |
| 城镇 | 室外 | ~100 | NPC移动、商店 |
| 矿洞 | 地下 | ~150 | 无限深度、随机生成 |
| 沙漠 | 室外 | ~50 | 赌场、仙人掌 |
| 洞穴 | 室内 | ~80 | 季节变化、储物 |

## Decision

### 场景分类

将游戏场景分为两类：

| 类型 | 描述 | 加载方式 |
|------|------|----------|
| **持久场景** | 主世界区域，常驻内存 | 单例 + 按需激活 |
| **临时场景** | 室内、NPC位置、UI | 按需实例化/销毁 |

### 持久场景架构

```
res://
├── scenes/
│   ├── worlds/
│   │   ├── farm/
│   │   │   ├── farm_world.tscn       # 农场主场景
│   │   │   ├── farm_entities/        # 农场实体
│   │   │   └── farm_buildings/       # 农场建筑
│   │   ├── town/
│   │   │   ├── town_world.tscn
│   │   │   └── ...
│   │   ├── mountain/
│   │   │   ├── mine_world.tscn
│   │   │   └── ...
│   │   └── desert/
│   │       ├── desert_world.tscn
│   │       └── ...
│   │
│   ├── interiors/
│   │   ├── cabin/
│   │   ├── shop/
│   │   ├── mine_entrance/
│   │   └── ...
│   │
│   └── ui/
│       ├── pause_menu.tscn
│       ├── inventory.tscn
│       └── ...
```

### 场景切换策略

#### 1. 大世界切换 (Farm ↔ Town)

```
┌─────────────────────────────────────────────────────────────┐
│                    SceneManager                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  current_world ──切换入口──> target_world                  │
│       │                              │                      │
│  [1] 暂停当前场景          [2] 加载新场景                   │
│       │                              │                      │
│  [3] 保存玩家位置          [4] 传送玩家到入口位置           │
│       │                              │                      │
│  [5] 隐藏/冻结当前场景      [6] 激活新场景                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```gdscript
# systems/scene/scene_manager.gd
class_name SceneManager
extends Node

var current_world: Node2D
var transition_scene: PackedScene = preload("res://scenes/ui/transition.tscn")

# 场景切换入口点
const TRANSITION_POINTS: Dictionary = {
    "farm_to_town": Vector2(50, 100),
    "town_to_farm": Vector2(0, 50),
    "farm_to_mine": Vector2(200, 300),
    # ...更多传送点
}

func switch_world(target: String) -> void:
    var transition = transition_scene.instantiate()
    add_child(transition)
    transition.fade_to_black.connect(_on_fade_complete.bind(target))
    transition.start_fade()

func _on_fade_complete(target: String) -> void:
    # 保存当前位置
    GameManager.save_current_position()

    # 卸载当前世界
    if current_world:
        current_world.queue_free()
        await current_tree.process_frame

    # 加载新世界
    var world_path = _get_world_path(target)
    var new_world = load(world_path).instantiate()
    add_child(new_world)
    current_world = new_world

    # 传送到入口
    var entry_point = TRANSITION_POINTS.get("%s_entry" % target)
    if entry_point:
        Player.global_position = entry_point

    # 淡入
    transition.start_fade_in()

func _get_world_path(target: String) -> String:
    var paths = {
        "farm": "res://scenes/worlds/farm/farm_world.tscn",
        "town": "res://scenes/worlds/town/town_world.tscn",
        "mine": "res://scenes/worlds/mountain/mine_world.tscn",
        "desert": "res://scenes/worlds/desert/desert_world.tscn",
    }
    return paths.get(target, "")
```

#### 2. 室内场景加载

```gdscript
func enter_building(building_id: String) -> void:
    var building_scene = _get_building_scene(building_id)
    var building = building_scene.instantiate()

    # 室内场景作为UI层叠加
    get_tree().current_scene.add_child(building)

    # 玩家传送到室内入口
    Player.global_position = building.indoor_entry_position

func exit_building() -> void:
    # 保存室内状态（如果需要）
    # ...

    # 移室内场景
    var current_building = get_tree().get_current_building()
    current_building.queue_free()

    # 玩家回到室外位置
    Player.global_position = get_last_outdoor_position()
```

### 矿洞动态加载

矿洞采用分块加载策略：

```gdscript
# systems/world/mine_chunk_loader.gd
class_name MineChunkLoader
extends Node2D

const CHUNK_SIZE: Vector2i = Vector2i(20, 20)  # 每块20×20格子
const LOAD_RADIUS: int = 2  # 加载半径
const UNLOAD_DISTANCE: int = 4  # 卸载距离

var loaded_chunks: Dictionary = {}  # {chunk_coord: Chunk}
var player_chunk: Vector2i

func _process(delta: float) -> void:
    _update_chunks()

func _update_chunks() -> void:
    var new_chunk = _world_to_chunk(Player.global_position)

    if new_chunk != player_chunk:
        player_chunk = new_chunk
        _load_nearby_chunks()
        _unload_distant_chunks()

func _load_nearby_chunks() -> void:
    for x in range(player_chunk.x - LOAD_RADIUS, player_chunk.x + LOAD_RADIUS + 1):
        for y in range(player_chunk.y - LOAD_RADIUS, player_chunk.y + LOAD_RADIUS + 1):
            var coord = Vector2i(x, y)
            if not loaded_chunks.has(coord):
                _load_chunk(coord)

func _load_chunk(coord: Vector2i) -> void:
    var chunk_seed = _calculate_chunk_seed(coord)
    var chunk = _generate_chunk(coord, chunk_seed)
    loaded_chunks[coord] = chunk
    add_child(chunk)

func _unload_distant_chunks() -> void:
    var to_remove = []
    for coord in loaded_chunks:
        if coord.distance_to(player_chunk) > UNLOAD_DISTANCE:
            to_remove.append(coord)

    for coord in to_remove:
        loaded_chunks[coord].queue_free()
        loaded_chunks.erase(coord)
```

### 内存管理

| 场景类型 | 策略 | 预期内存 |
|----------|------|----------|
| 当前世界 | 常驻 | ~50MB |
| 邻近世界 | 冻结不卸载 | ~30MB |
| 远距离世界 | 卸载 | 0MB |
| 室内场景 | 按需实例化 | ~5MB |

## Alternatives Considered

### Alternative 1: 单一大世界 (无缝地图)

- **描述**: 所有区域在一个场景中，通过碰撞区分
- **优点**: 无加载画面，体验流畅
- **缺点**: 内存占用高，编辑器性能差
- **拒绝理由**: 桃源乡各区域风格差异大，单一场景不利于编辑

### Alternative 2: 全即时卸载

- **描述**: 进入区域立即加载，离开立即卸载
- **优点**: 内存占用最低
- **缺点**: 频繁IO，可能有明显加载
- **拒绝理由**: 切换频繁导致体验不佳

## Consequences

### Positive
- **编辑器友好**: 各区域独立场景，便于多人协作
- **内存可控**: 分层加载策略控制内存使用
- **加载可定制**: 各区域可有不同加载动画

### Negative
- **加载延迟**: 区域切换有短暂加载时间
- **状态同步**: 跨区域状态需要特殊处理

## Validation Criteria

1. 区域切换加载时间 < 2秒
2. 同时内存占用 < 200MB
3. 矿洞支持无限深度加载
4. 无场景切换时帧率 < 50fps 的情况
