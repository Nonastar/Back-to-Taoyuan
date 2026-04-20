extends Node

## CookingSystem - 烹饪系统 autoload
## 处理食谱定义、烹饪进度和食用料理的Buff系统

# ============ 信号 ============

signal cooking_started(recipe_id: String)
signal cooking_finished(output_item_id: String)
signal buff_applied(buff: Dictionary)

# ============ 常量 ============

const SAVE_PATH := "user://cooking_save.json"

# ============ 属性 ============

var rng := RandomNumberGenerator.new()

var recipes := {}

var _is_cooking: bool = false
var _current_recipe_id: String = ""
var _remaining_days: int = 0

var _active_buffs: Array = []  # [{ "type": String, "value": int, "remaining_days": int }]

# ============ 生命周期 ============

func _ready() -> void:
	rng.randomize()
	_initialize_recipes()
	_load_state()
	_connect_signals()

## 数据初始化（由 _ready() 或外部调用，可注入外部数据源）
func init(data_source: Object = null) -> void:
	if data_source != null and data_source.has_method("load_recipes"):
		recipes = data_source.load_recipes()
		print("[CookingSystem] Recipes loaded from injected source")
	else:
		_initialize_recipes()

func _connect_signals() -> void:
	# 连接日期变化信号，推进烹饪和Buff
	if EventBus and EventBus.has_signal("time_day_changed"):
		EventBus.time_day_changed.connect(_on_day_changed)

# ============ 食谱初始化 ============

func _initialize_recipes() -> void:
	# 优先从 DataLoader 加载 JSON 配置
	if DataLoader:
		var data = DataLoader.load_json("recipes.json")
		if data.has("recipes") and not data["recipes"].is_empty():
			recipes = data["recipes"]
			print("[CookingSystem] Loaded %d recipes from JSON" % recipes.size())
			return
	# 兜底：硬编码默认食谱（仅在新项目或 JSON 缺失时使用）
	print("[CookingSystem] No recipes.json found, using built-in defaults")
	recipes["egg_dish"] = {
		"id": "egg_dish",
		"name": "煎蛋",
		"ingredients": { "egg": 1 },
		"output_item_id": "egg_dish",
		"cook_time_days": 1,
		"buff_on_eat": { "type": "stamina_restore", "min": 20, "max": 50 }
	}
	recipes["bread"] = {
		"id": "bread",
		"name": "烤面包",
		"ingredients": { "wheat": 1 },
		"output_item_id": "bread",
		"cook_time_days": 1,
		"buff_on_eat": { "type": "speed", "min": 10, "max": 20 }
	}
	recipes["juice"] = {
		"id": "juice",
		"name": "果汁",
		"ingredients": { "fruit": 1 },
		"output_item_id": "juice",
		"cook_time_days": 1,
		"buff_on_eat": { "type": "stamina_restore", "min": 15, "max": 30 }
	}
	recipes["veg_soup"] = {
		"id": "veg_soup",
		"name": "蔬菜汤",
		"ingredients": { "vegetable": 1 },
		"output_item_id": "veg_soup",
		"cook_time_days": 1,
		"buff_on_eat": { "type": "stamina_restore", "min": 20, "max": 40 }
	}
	recipes["meat_soup"] = {
		"id": "meat_soup",
		"name": "肉汤",
		"ingredients": { "meat": 1 },
		"output_item_id": "meat_soup",
		"cook_time_days": 2,
		"buff_on_eat": { "type": "stamina_restore", "min": 30, "max": 60 }
	}
	recipes["fish_soup"] = {
		"id": "fish_soup",
		"name": "鱼汤",
		"ingredients": { "fish": 1 },
		"output_item_id": "fish_soup",
		"cook_time_days": 1,
		"buff_on_eat": { "type": "luck", "min": 5, "max": 15 }
	}
	recipes["cake"] = {
		"id": "cake",
		"name": "蛋糕",
		"ingredients": { "egg": 1, "milk": 1 },
		"output_item_id": "cake",
		"cook_time_days": 2,
		"buff_on_eat": { "type": "stamina_restore", "min": 40, "max": 80 }
	}
	recipes["jam"] = {
		"id": "jam",
		"name": "果酱",
		"ingredients": { "fruit": 2 },
		"output_item_id": "jam",
		"cook_time_days": 2,
		"buff_on_eat": { "type": "luck", "min": 10, "max": 20 }
	}
	recipes["cheese"] = {
		"id": "cheese",
		"name": "奶酪",
		"ingredients": { "milk": 2 },
		"output_item_id": "cheese",
		"cook_time_days": 3,
		"buff_on_eat": { "type": "speed", "min": 15, "max": 25 }
	}
	recipes["honey_dish"] = {
		"id": "honey_dish",
		"name": "蜂蜜料理",
		"ingredients": { "honey": 1 },
		"output_item_id": "honey_dish",
		"cook_time_days": 1,
		"buff_on_eat": { "type": "stamina_restore", "min": 25, "max": 45 }
	}

# ============ 烹饪操作 ============

func cook_item(recipe_id: String) -> bool:
	if _is_cooking:
		print("[CookingSystem] Already cooking")
		return false
	
	if not recipes.has(recipe_id):
		print("[CookingSystem] Recipe not found: " + recipe_id)
		return false
	
	var recipe = recipes[recipe_id]
	var ingredients = recipe.get("ingredients", {})
	
	# 检查食材
	for ing_id in ingredients.keys():
		if not InventorySystem.has_item(ing_id, ingredients[ing_id]):
			print("[CookingSystem] Missing ingredient: " + ing_id)
			return false
	
	# 移除食材
	for ing_id in ingredients.keys():
		InventorySystem.remove_item(ing_id, ingredients[ing_id])
	
		# 开始烹饪
	_is_cooking = true
	_current_recipe_id = recipe_id
	_remaining_days = recipe.get("cook_time_days", 1)

	cooking_started.emit(recipe_id)
	return true

func finish_cooking() -> void:
	if not _is_cooking or _current_recipe_id.is_empty():
		return

	var recipe_id = _current_recipe_id
	var recipe = recipes[recipe_id]
	var output_id = recipe.get("output_item_id", "")

	# 添加产物到背包（默认普通品质）
	if not output_id.is_empty():
		InventorySystem.add_item(output_id, 1, Quality.NORMAL)

	# 清理状态
	_is_cooking = false
	_current_recipe_id = ""
	_remaining_days = 0

	cooking_finished.emit(recipe_id)

# ============ 食用操作 ============

func eat_dish(item_id: String) -> Dictionary:
	# 检查背包
	if not InventorySystem.has_item(item_id, 1):
		return { "success": false, "message": "物品不足" }
	
	# 移除料理
	InventorySystem.remove_item(item_id, 1)
	
	# 查找料理对应的Buff
	var buff_data = _get_dish_buff(item_id)
	
	if buff_data.size() > 0:
		var new_buff = {
			"type": buff_data.get("type", "none"),
			"value": rng.randi_range(buff_data.get("min", 0), buff_data.get("max", 0)),
			"remaining_days": rng.randi_range(1, 5)
		}
		_active_buffs.append(new_buff)
		buff_applied.emit(new_buff)
		return { "success": true, "message": "食用成功", "buff": new_buff }

	return { "success": true, "message": "食用成功", "buff": {} }

func _get_dish_buff(item_id: String) -> Dictionary:
	for recipe in recipes.values():
		if recipe.get("output_item_id", "") == item_id:
			return recipe.get("buff_on_eat", {})
	return {}

func _on_day_changed(day: int, season_name: String, year: int) -> void:
	advance_day(1)
	save_state()

func advance_day(days: int = 1) -> void:
	# 烹饪进度
	if _is_cooking and _remaining_days > 0:
		_remaining_days -= days
		if _remaining_days <= 0:
			finish_cooking()
	
	# Buff衰减
	var expired_buffs: Array = []
	for i in range(_active_buffs.size() - 1, -1, -1):
		var buff = _active_buffs[i]
		buff["remaining_days"] -= days
		if buff["remaining_days"] <= 0:
			expired_buffs.append(i)
	
	# 移除过期Buff
	for idx in expired_buffs:
		_active_buffs.remove_at(idx)

# ============ 存档���持 ============

func get_save_data() -> Dictionary:
	return {
		"is_cooking": _is_cooking,
		"current_recipe_id": _current_recipe_id,
		"remaining_days": _remaining_days,
		"active_buffs": _active_buffs
	}

func load_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	_is_cooking = data.get("is_cooking", false)
	_current_recipe_id = data.get("current_recipe_id", "")
	_remaining_days = data.get("remaining_days", 0)
	_active_buffs = data.get("active_buffs", [])

# ============ Buff查询 ============

func get_active_buffs() -> Array:
	return _active_buffs.duplicate()

# ============ 内部方法 ============

func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file_handle = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file_handle == null:
		return

	var json_str = file_handle.get_as_text()
	file_handle.close()
	
	if json_str.is_empty():
		return
	
	var json = JSON.new()
	var parse_result = json.parse(json_str)
	if parse_result == OK:
		var data = json.get_data()
		if typeof(data) == TYPE_DICTIONARY:
			load_save_data(data)

func save_state() -> void:
	var data = get_save_data()
	var json = JSON.stringify(data)
	
	var file_handle = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file_handle == null:
		push_error("[CookingSystem] Failed to open save file")
		return
	
	file_handle.store_string(json)
	file_handle.close()
