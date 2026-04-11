# ADR-0003: 场景管理与加载策略

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏包含多个区域（农场、城镇、矿洞、沙漠等）和大量实体。需要确定场景的组织方式、加载策略和切换机制，确保无缝的地图体验和合理的内存使用。

### 核心原则

**场景 = 视觉，系统 = 逻辑**

| 类型 | 职责 | 示例 |
|------|------|------|
| **视觉场景** | 仅包含视觉元素（地形、装饰、碰撞） | farm_world.tscn, FishPond.tscn |
| **系统逻辑** | 游戏规则和数据（Autoload 单例） | FarmPlotSystem, InventorySystem |

> ⚠️ **禁止**：在视觉场景中包含游戏逻辑
> ⚠️ **禁止**：游戏逻辑作为场景节点而非 Autoload

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

将游戏场景分为三类：

| 类型 | 描述 | 加载方式 | 包含逻辑 |
|------|------|----------|----------|
| **World 场景** | 主世界区域 | 场景管理器切换 | ❌ 仅视觉 |
| **Interior 场景** | 室内、可进入建筑 | 按需实例化 | ❌ 仅视觉 |
| **UI 场景** | 用户界面 | 按需显示/隐藏 | ❌ 仅视觉 |

### 系统分类

所有游戏逻辑必须作为 Autoload 单例：

```
src/scripts/autoload/
├── FarmPlotSystem.gd      ← 农场系统（不是 FarmManager）
├── InventorySystem.gd
├── NavigationSystem.gd
└── ...
```

### 目录结构

```
src/
├── scenes/
│   ├── worlds/                    # 世界场景（视觉）
│   │   ├── farm/
│   │   │   └── farm_world.tscn   # 农场世界（仅视觉）
│   │   ├── town/
│   │   │   └── town_world.tscn
│   │   ├── mountain/
│   │   │   └── mine_world.tscn
│   │   └── desert/
│   │       └── desert_world.tscn
│   │
│   ├── interiors/                 # 室内场景（视觉）
│   │   ├── cabin.tscn
│   │   ├── shop.tscn
│   │   ├── fish_pond.tscn
│   │   └── mine_entrance.tscn
│   │
│   ├── entities/                  # 可复用实体（视觉）
│   │   ├── farm_plot.tscn
│   │   ├── npc.tscn
│   │   └── item.tscn
│   │
│   └── ui/                       # UI 场景（视觉）
│       ├── hud.tscn
│       ├── inventory.tscn
│       ├── pause_menu.tscn
│       └── fishing_mini_game.tscn
│
├── scripts/
│   ├── autoload/                 # 游戏系统（逻辑）
│   │   ├── FarmPlotSystem.gd
│   │   ├── InventorySystem.gd
│   │   └── ...
│   │
│   ├── entities/                 # 实体组件
│   └── ui/                      # UI 逻辑
│
└── resources/
    └── data/                     # 数据定义
```

### Main.tscn 的角色

`Main.tscn` 是游戏入口点，**不应包含游戏逻辑**：

```
Main.tscn
├── Background (视觉背景)
├── WorldLayer (挂载切换的世界场景)
├── UILayer (常驻 UI)
│   ├── HUD
│   ├── NavigationPanel
│   └── FishingMiniGame
└── [不包含 FarmManager 等系统逻辑]
```

**系统获取方式**：通过 Autoload 访问，不通过场景树

```gdscript
# ❌ 错误：通过场景树获取系统
var farm = get_tree().root.get_node("Main/FarmManager")

# ✅ 正确：通过 Autoload 访问
var farm = FarmPlotSystem
```

### FarmPlotSystem 设计

根据 C04 FarmPlotSystem 文档，系统应为 Autoload：

```gdscript
# project.godot
[autoload]
FarmPlotSystem="*res://src/scripts/autoload/farm_plot_system.gd"
```

**不在** Main.tscn 或任何场景中实例化。

### 鱼塘场景设计

`FishPond.tscn` 是视觉场景，位于 `interiors/`：

```
src/scenes/interiors/
└── fish_pond.tscn    # 仅包含水池视觉、钓鱼点位置
```

钓鱼逻辑由 `FishingSystem` (Autoload) 处理。

## Decision

### 场景切换策略

场景切换由 `SceneManager` (Autoload) 处理。

#### 大世界切换 (Farm ↔ Town)

```
SceneManager (Autoload)
├── switch_world(target: String)
├── load_interior(building_id: String)
├── exit_interior()
└── WorldLayer (Node2D - 挂载当前世界场景)
```

```gdscript
# src/scripts/autoload/scene_manager.gd
extends Node

## 世界场景路径
const WORLD_PATHS: Dictionary = {
    "farm": "res://src/scenes/worlds/farm/farm_world.tscn",
    "town": "res://src/scenes/worlds/town/town_world.tscn",
    "mine": "res://src/scenes/worlds/mountain/mine_world.tscn",
    "desert": "res://src/scenes/worlds/desert/desert_world.tscn"
}

## 室内场景路径
const INTERIOR_PATHS: Dictionary = {
    "cabin": "res://src/scenes/interiors/cabin.tscn",
    "shop": "res://src/scenes/interiors/shop.tscn",
    "fish_pond": "res://src/scenes/interiors/fish_pond.tscn",
    "mine_entrance": "res://src/scenes/interiors/mine_entrance.tscn"
}

## 传送点
const TRANSITION_POINTS: Dictionary = {
    "farm_to_town": Vector2(50, 100),
    "town_to_farm": Vector2(0, 50),
    "farm_to_mine": Vector2(200, 300)
}

var current_world: String = ""
var current_interior: String = ""
var saved_world_position: Vector2 = Vector2.ZERO

## 切换世界
func switch_world(target: String) -> bool:
    if not WORLD_PATHS.has(target):
        push_error("[SceneManager] Unknown world: %s" % target)
        return false

    # 保存当前位置
    if Player:
        saved_world_position = Player.global_position

    # 卸载当前世界
    _unload_current_world()

    # 加载新世界
    var world_path = WORLD_PATHS[target]
    var world_scene = load(world_path)
    var world = world_scene.instantiate()

    # 添加到 WorldLayer
    var world_layer = _get_world_layer()
    if world_layer:
        world_layer.add_child(world)

    current_world = target
    print("[SceneManager] Switched to world: %s" % target)
    return true

## 加载室内场景
func load_interior(building_id: String) -> bool:
    if not INTERIOR_PATHS.has(building_id):
        push_error("[SceneManager] Unknown interior: %s" % building_id)
        return false

    # 保存世界位置
    if Player:
        saved_world_position = Player.global_position

    var interior_path = INTERIOR_PATHS[building_id]
    var interior_scene = load(interior_path)
    var interior = interior_scene.instantiate()

    # 添加到场景树
    get_tree().current_scene.add_child(interior)

    current_interior = building_id
    print("[SceneManager] Loaded interior: %s" % building_id)
    return true

## 退出室内场景
func exit_interior() -> void:
    var current = get_tree().current_scene.get_node_or_null(current_interior)
    if current:
        current.queue_free()

    # 恢复世界位置
    if Player:
        Player.global_position = saved_world_position

    current_interior = ""
    print("[SceneManager] Exited interior")

func _unload_current_world() -> void:
    var world_layer = _get_world_layer()
    if world_layer:
        for child in world_layer.get_children():
            world_layer.remove_child(child)
            child.queue_free()

func _get_world_layer() -> Node2D:
    var main = get_tree().root.get_node("Main")
    return main.get_node_or_null("WorldLayer")
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

## Common Violations and Lessons Learned

> 记录实际开发中违反此架构导致的问题，供后续开发参考。

### 2026-04-09: MainFarm.tscn 违规事件

#### 错误描述
开发过程中错误地创建了 `MainFarm.tscn` 和 `main_farm.gd`，违反了"场景=视觉"的架构原则。

#### 问题文件
```
src/scenes/levels/MainFarm.tscn    ← 违反：包含游戏逻辑
src/scripts/ui/main_farm.gd        ← 违反：应作为 Autoload
```

#### 错误症状
```
ERROR: Attempt to open script 'res://src/scripts/ui/main_farm.gd'
       resulted in error 'File not found'.
ERROR: Cannot set object script. Parameter should be null or a
       reference to valid script.
```

#### 根本原因
- 在 `Main.tscn` 已有农场逻辑的情况下，又创建了 `MainFarm.tscn` 作为第二套种植场景
- 违反了"单一职责"和"场景=视觉"原则
- 未遵守 ADR-0003 的目录结构规范

#### 修复措施
1. 删除 `MainFarm.tscn` 和 `main_farm.gd`
2. 确保 `Main.tscn` 仅作为入口点，不包含游戏逻辑
3. 游戏逻辑通过 Autoload 访问

#### 预防措施
| 检查项 | 操作 |
|--------|------|
| 创建新场景前 | 确认属于 `worlds/`、`interiors/`、`ui/` 还是 `entities/` |
| 创建新脚本前 | 确认是系统逻辑（→autoload）还是实体逻辑（→entities） |
| Main.tscn 修改 | 确保只修改 UI 引用，不添加游戏逻辑节点 |
| 场景节点脚本 | 确保节点类型与脚本继承匹配（Node vs Node2D） |

#### 场景节点类型检查表

| 脚本继承 | 场景节点类型 |
|----------|--------------|
| `extends Node` | `type="Node"` |
| `extends Node2D` | `type="Node2D"` |
| `extends Control` | `type="Control"` |
| `extends CharacterBody2D` | `type="CharacterBody2D"` |

> ⚠️ **常见错误**：脚本 `extends Node2D` 但场景中写 `type="Node"`，导致类型不匹配错误。
