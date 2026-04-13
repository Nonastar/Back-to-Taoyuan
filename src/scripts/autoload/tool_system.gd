extends Node

## ToolSystem - 工具系统
## 管理工具定义和种子选择

# ============ 工具类型 ============

enum ToolType { HOE, WATERING_CAN, SEEDS, HAND }

class ToolDef:
	var id: String
	var name: String
	var type: int
	var stamina_cost: float

	func _init(
		p_id: String,
		p_name: String,
		p_type: int,
		p_stamina: float
	) -> void:
		id = p_id
		name = p_name
		type = p_type
		stamina_cost = p_stamina

# ============ 数据库 ============

var tools: Dictionary = {}
var selected_seed_id: String = "tomato_seed"

# ============ 初始化 ============

func _ready() -> void:
	_initialize_tools()
	print("[ToolSystem] Initialized")

func _initialize_tools() -> void:
	_register_tool(ToolDef.new("hoe", "锄头", ToolType.HOE, 5.0))
	_register_tool(ToolDef.new("watering_can", "浇水壶", ToolType.WATERING_CAN, 3.0))
	_register_tool(ToolDef.new("seeds", "种子袋", ToolType.SEEDS, 2.0))
	_register_tool(ToolDef.new("hand", "双手", ToolType.HAND, 1.0))

func _register_tool(tool: ToolDef) -> void:
	tools[tool.id] = tool

# ============ 公共方法 ============

func get_tool(tool_id: String) -> ToolDef:
	return tools.get(tool_id)

func get_tool_by_type(type: int) -> ToolDef:
	for tool in tools.values():
		if tool.type == type:
			return tool
	return null

func get_tool_stamina_cost(type: int) -> float:
	var tool = get_tool_by_type(type)
	return tool.stamina_cost if tool else 0.0

func get_selected_seed() -> String:
	return selected_seed_id

func set_selected_seed(seed_id: String) -> void:
	selected_seed_id = seed_id

func get_available_seeds() -> Array:
	var seeds: Array = []
	if ItemDataSystem:
		var seed_items = ItemDataSystem.get_items_by_category(ItemDataSystem.ItemCategory.SEED)
		for seed_item in seed_items:
			var count = InventorySystem.get_item_count(seed_item.id) if InventorySystem else 0
			if count > 0:
				seeds.append({
					"id": seed_item.id,
					"name": seed_item.name,
					"count": count
				})
	return seeds

func get_seed_count(seed_id: String) -> int:
	return InventorySystem.get_item_count(seed_id) if InventorySystem else 0
