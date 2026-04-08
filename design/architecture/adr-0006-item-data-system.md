# ADR-0006: 物品与数据系统架构

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏包含200+种物品（作物、工具、装备、食材等），需要统一的数据结构来定义物品属性（名称、图标、堆叠、价值），以及系统化的数据管理方式，支持配置化设计而非硬编码。

### 物品分类

| 类别 | 示例 | 特性 |
|------|------|------|
| 种子 | 番茄种子、南瓜种子 | 可种植、一次性 |
| 作物 | 番茄、南瓜 | 可出售/烹饪、堆叠 |
| 工具 | 锄头、斧头 | 不可堆叠、可升级 |
| 装备 | 帽子、戒指 | 不可堆叠、属性加成 |
| 食材 | 面粉、糖 | 可烹饪、堆叠 |
| 建筑 | 鸡舍、温室 | 放置类、不可堆叠 |
| 特殊 | 秘密笔记、优惠券 | 唯一物品 |

## Decision

### Godot Resource 架构

```
res://
└── resources/
    └── data/
        ├── items/
        │   ├── base_item.tres           # 基类定义
        │   ├── crops/
        │   │   ├── crop_tomato.tres
        │   │   └── ...
        │   ├── tools/
        │   │   ├── tool_hoe.tres
        │   │   └── ...
        │   ├── equipment/
        │   │   ├── equip_hat.tres
        │   │   └── ...
        │   ├── seeds/
        │   │   ├── seed_tomato.tres
        │   │   └── ...
        │   └── materials/
        │       └── ...
        │
        ├── recipes/
        │   ├── recipe_tomato_sauce.tres
        │   └── ...
        │
        ├── npcs/
        │   ├── npc_merchant.tres
        │   └── ...
        │
        └── definitions/
            ├── item_definitions.tres    # 主索引
            └── drop_tables.tres          # 掉落表
```

### 基类定义

```gdscript
# resources/data/items/base_item.gd
class_name ItemData
extends Resource

@export_group("Basic Info")
@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon_path: String = ""

@export_group("Classification")
@export var category: ItemCategory = ItemCategory.MATERIAL
@export var item_type: String = ""  # 具体类型: "crop", "tool", "equipment"

@export_group("Stack & Trade")
@export var stackable: bool = true
@export var max_stack: int = 999
@export var sell_price: int = 0
@export var buy_price: int = 0

@export_group("Usage")
@export var consumable: bool = false
@export var edible: bool = false
@export var edible_heal: float = 0.0
@export var edible_stamina: float = 0.0

# 枚举定义
enum ItemCategory {
    SEED,
    CROP,
    TOOL,
    EQUIPMENT,
    MATERIAL,
    FOOD,
    BUILDING,
    QUEST,
    OTHER
}

func can_stack() -> bool:
    return stackable and max_stack > 1

func get_display_info() -> Dictionary:
    return {
        "name": display_name,
        "description": description,
        "category": ItemCategory.keys()[category],
        "stackable": stackable,
        "max_stack": max_stack,
        "sell_price": sell_price,
        "buy_price": buy_price
    }
```

### 具体物品定义示例

```gdscript
# resources/data/items/crops/crop_tomato.gd
class_name CropData
extends ItemData

@export_group("Crop Info")
@export var growth_days: int = 4
@export var seasons: Array[String] = ["spring", "summer"]
@export var base_quality: int = 0  # 0=normal, 1=fine, 2=excellent, 3=supreme
@export var crop_id: String = "tomato"  # 对应的作物类型
@export var seed_item_id: String = "seed_tomato"
```

```gdscript
# resources/data/items/tools/tool_hoe.gd
class_name ToolData
extends ItemData

@export_group("Tool Info")
@export var tool_type: ToolType
@export var tier: int = 1
@export var stamina_cost: float = 5.0
@export var effectiveness: float = 1.0  # 工具效率倍率
@export var upgrade_level: int = 0  # 当前升级等级

enum ToolType {
    HOE,
    WATERING_CAN,
    AXE,
    PICKAXE,
    SCythe,
    FISHING_ROD,
    pan
}

func get_upgrade_bonus() -> float:
    return 1.0 + upgrade_level * 0.25  # 每级+25%
```

```gdscript
# resources/data/items/equipment/equip_ring.gd
class_name EquipmentData
extends ItemData

@export_group("Equipment Info")
@export var equip_slot: EquipSlot
@export var stats: Dictionary = {}  # {"max_hp": 10, "stamina_bonus": 5}
@export var set_id: String = ""  # 套装ID
@export var enchantments: Array[String] = []

enum EquipSlot {
    HEAD,
    BODY,
    LEGS,
    BOOTS,
    RING1,
    RING2,
    NECKLACE,
    WEAPON
}
```

### ItemDatabase (物品数据库)

```gdscript
# systems/data/item_database.gd
class_name ItemDatabase
extends Node

static var instance: ItemDatabase

# 物品索引
var _items: Dictionary = {}  # {item_id: ItemData}
var _item_scenes: Dictionary = {}  # {item_id: PackedScene}

func _ready():
    instance = self
    _load_all_items()

func _load_all_items():
    # 从配置表加载所有物品
    var definitions: Resource = preload("res://resources/data/definitions/item_definitions.tres")
    for item_id in definitions.item_ids:
        var item_data = load("res://resources/data/items/%s.tres" % item_id)
        if item_data:
            _items[item_id] = item_data

func get_item(item_id: String) -> ItemData:
    return _items.get(item_id, null)

func has_item(item_id: String) -> bool:
    return _items.has(item_id)

func get_items_by_category(category: ItemData.ItemCategory) -> Array[ItemData]:
    var result: Array[ItemData] = []
    for item in _items.values():
        if item.category == category:
            result.append(item)
    return result

func get_item_scene(item_id: String) -> PackedScene:
    if not _item_scenes.has(item_id):
        var path = "res://scenes/items/%s.tscn" % item_id
        if ResourceLoader.exists(path):
            _item_scenes[item_id] = load(path)
    return _item_scenes.get(item_id, null)

# 获取物品显示信息
func get_display_info(item_id: String) -> Dictionary:
    var item = get_item(item_id)
    if item:
        return item.get_display_info()
    return {"error": "Item not found: %s" % item_id}
```

### 物品定义配置表

```gdscript
# resources/data/definitions/item_definitions.tres
[gd_resource type="Resource" script_class="ItemDefinitions" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/systems/data/item_definitions.gd" id="1"]

[resource]
script = ExtResource("1")

# 主物品ID列表
item_ids = [
    "seed_tomato",
    "seed_carrot",
    "crop_tomato",
    "crop_carrot",
    "tool_hoe",
    "tool_watering_can",
    "tool_axe",
    "equip_ring_1",
    "food_bread",
    # ... 200+ items
]

# 分类索引
category_items = {
    "SEED": ["seed_tomato", "seed_carrot"],
    "CROP": ["crop_tomato", "crop_carrot"],
    "TOOL": ["tool_hoe", "tool_watering_can"],
    "EQUIPMENT": ["equip_ring_1"],
    "FOOD": ["food_bread"]
}

# 季节物品
seasonal_items = {
    "spring": ["seed_tomato", "seed_carrot"],
    "summer": ["seed_tomato", "crop_melon"],
    "autumn": ["seed_pumpkin", "crop_pumpkin"],
    "winter": []
}
```

### 掉落表系统

```gdscript
# systems/data/drop_table.gd
class_name DropTable
extends Resource

@export var entries: Array[DropEntry] = []
@export var guaranteed_drops: Array[String] = []  # 必定掉落

@export_group("Settings")
@export var min_drops: int = 1
@export var max_drops: int = 3

[System.Serializable]
class DropEntry:
    @export var item_id: String
    @export var weight: float = 1.0  # 权重
    @export var min_amount: int = 1
    @export var max_amount: int = 1
    @export var chance: float = 1.0  # 掉落概率 0-1

func roll_drops(rng: RandomNumberGenerator) -> Array[Dictionary]:
    var results: Array[Dictionary] = []

    # 必定掉落
    for item_id in guaranteed_drops:
        results.append({"item_id": item_id, "amount": 1})

    # 随机掉落
    var total_weight = 0.0
    for entry in entries:
        total_weight += entry.weight

    var num_drops = rng.randi_range(min_drops, max_drops)
    for i in range(num_drops):
        var roll = rng.randf() * total_weight
        var current_weight = 0.0

        for entry in entries:
            if rng.randf() > entry.chance:
                continue
            current_weight += entry.weight
            if roll <= current_weight:
                var amount = rng.randi_range(entry.min_amount, entry.max_amount)
                results.append({"item_id": entry.item_id, "amount": amount})
                break

    return results
```

## Alternatives Considered

### Alternative 1: ScriptableObject (Unity风格)

- **描述**: 使用Godot的Resource作为Unity的ScriptableObject
- **优点**: 引擎原生支持，编辑器集成好
- **缺点**: Godot 4.x的Resource系统与Unity略有不同
- **拒绝理由**: Resource系统已足够，且更符合Godot最佳实践

### Alternative 2: JSON配置表

- **描述**: 所有物品定义为JSON，从外部加载
- **优点**: 易于外部编辑，不需要重启游戏
- **缺点**: 需要额外的序列化逻辑，类型安全差
- **拒绝理由**: 对于本项目复杂度不必要，失去编辑器支持

## Consequences

### Positive
- **类型安全**: GDScript类提供编译时检查
- **编辑器集成**: 可视化编辑物品数据
- **可扩展**: 易于添加新物品类型
- **性能**: Resource预加载，快速访问

### Negative
- **GIT冲突**: 多人编辑同一.tres文件可能冲突
- **热更新**: 修改需要游戏重启

## Validation Criteria

1. 物品数据在编辑器中正确显示
2. 物品系统正确处理堆叠/不可堆叠
3. 掉落表随机性符合预期分布
4. 物品数据库查询性能 < 1ms
