extends Node

## CookingSystem - 烹饪系统 autoload
## 处理食谱定义、烹饪进度和食用料理的Buff系统

# ============ 信号 ============

signal cooking_started(recipe_id: String)
signal cooking_finished(output_item_id: String)
signal cooking_cancelled(recipe_id: String, refunded_ingredients: Dictionary)
signal buff_applied(buff: Dictionary)

# ============ 常量 ============

const SAVE_PATH := "user://cooking_save.json"
const MASTERY_COUNT_FOR_MASTERED := 10       # 精通所需次数
const QUALITY_INHERIT_MODE := "minimum"        # 产出品质 = 投入最低品质
const CANCEL_REFUND_RATIO := 0.5              # 取消烹饪返还50%食材

# ============ 属性 ============

var rng := RandomNumberGenerator.new()

var recipes := {}

var _is_cooking: bool = false
var _current_recipe_id: String = ""
var _remaining_days: int = 0
var _current_input_qualities: Dictionary = {}  # {ingredient_id: quality} 用于产出品质计算

var _active_buffs: Array = []  # [{ "type": String, "value": int, "remaining_days": int }]
var _known_recipes: Dictionary = {}  # {recipe_id: cook_count} — 0=未知, 1-9=已知, 10+=精通

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

	# 检查食材并记录每种食材的品质（用于产出品质计算）
	_current_input_qualities.clear()
	for ing_id in ingredients.keys():
		if not InventorySystem.has_item(ing_id, ingredients[ing_id]):
			print("[CookingSystem] Missing ingredient: " + ing_id)
			return false
		# 记录投入的最低品质
		var q = _get_lowest_ingredient_quality(ing_id)
		_current_input_qualities[ing_id] = q

	# 移除食材
	for ing_id in ingredients.keys():
		InventorySystem.remove_item(ing_id, ingredients[ing_id])

	# 开始烹饪
	_is_cooking = true
	_current_recipe_id = recipe_id
	_remaining_days = recipe.get("cook_time_days", 1)

	# 标记为已知配方
	if not _known_recipes.has(recipe_id):
		_known_recipes[recipe_id] = 0

	cooking_started.emit(recipe_id)
	return true

func finish_cooking() -> void:
	if not _is_cooking or _current_recipe_id.is_empty():
		return

	var recipe_id = _current_recipe_id
	var recipe = recipes[recipe_id]
	var output_id = recipe.get("output_item_id", "")

	# 产出品质 = 投入最低品质
	var output_quality: int = _calculate_output_quality()

	# 添加产物到背包
	if not output_id.is_empty():
		InventorySystem.add_item(output_id, 1, output_quality)

	# 精通计数
	if _known_recipes.has(recipe_id):
		_known_recipes[recipe_id] += 1

	# 清理状态
	_is_cooking = false
	_current_recipe_id = ""
	_remaining_days = 0
	_current_input_qualities.clear()

	cooking_finished.emit(recipe_id)

## 取消烹饪 — 退还50%食材
func cancel_cooking() -> Dictionary:
	if not _is_cooking or _current_recipe_id.is_empty():
		return {"success": false, "message": "No cooking in progress"}

	var recipe_id = _current_recipe_id
	var recipe = recipes[recipe_id]
	var ingredients = recipe.get("ingredients", {})

	# 退还50%食材（向上取整）
	var refunded: Dictionary = {}
	for ing_id in ingredients.keys():
		var refund_amount = maxi(1, ceili(ingredients[ing_id] * CANCEL_REFUND_RATIO))
		InventorySystem.add_item(ing_id, refund_amount)
		refunded[ing_id] = refund_amount

	# 清理状态
	_is_cooking = false
	_current_recipe_id = ""
	_remaining_days = 0
	_current_input_qualities.clear()

	cooking_cancelled.emit(recipe_id, refunded)
	return {"success": true, "refunded": refunded}

## ============ 食用操作 ============

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
		"active_buffs": _active_buffs,
		"known_recipes": _known_recipes
	}

func load_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	_is_cooking = data.get("is_cooking", false)
	_current_recipe_id = data.get("current_recipe_id", "")
	_remaining_days = data.get("remaining_days", 0)
	_active_buffs = data.get("active_buffs", [])
	_known_recipes = data.get("known_recipes", {})

# ============ 配方查询 ============

## 获取配方所需食材
func get_recipe_ingredients(recipe_id: String) -> Dictionary:
	if not recipes.has(recipe_id):
		return {}
	return recipes[recipe_id].get("ingredients", {}).duplicate(true)

## 获取配方食用后的Buff
func get_recipe_buff(recipe_id: String) -> Dictionary:
	if not recipes.has(recipe_id):
		return {}
	return recipes[recipe_id].get("buff_on_eat", {}).duplicate(true)

## 获取所有已知配方状态
## 返回 {recipe_id: {status: "unknown"|"known"|"mastered", cook_count: int}}
func get_known_recipes() -> Dictionary:
	return _known_recipes.duplicate()

## 获取配方状态文字描述
func get_recipe_status(recipe_id: String) -> String:
	if not _known_recipes.has(recipe_id):
		return "unknown"
	var count: int = _known_recipes[recipe_id]
	if count >= MASTERY_COUNT_FOR_MASTERED:
		return "mastered"
	return "known"

## 获取当前可用的配方（已知且食材足够）
func get_available_recipes() -> Array:
	var available: Array = []
	for recipe_id in recipes.keys():
		if not _known_recipes.has(recipe_id):
			continue  # 未发现
		if is_recipe_ingredients_available(recipe_id):
			available.append(recipe_id)
	return available

## 检查配方食材是否足够
func is_recipe_ingredients_available(recipe_id: String) -> bool:
	if not recipes.has(recipe_id):
		return false
	var ingredients = recipes[recipe_id].get("ingredients", {})
	for ing_id in ingredients.keys():
		if not InventorySystem.has_item(ing_id, ingredients[ing_id]):
			return false
	return true

## 获取当前正在烹饪的配方ID
func get_current_recipe_id() -> String:
	return _current_recipe_id if _is_cooking else ""

## 获取烹饪剩余天数
func get_remaining_cooking_days() -> int:
	return _remaining_days if _is_cooking else 0

## 获取配方状态: 0=未知, 1+=已知(数字=烹饪次数)
func get_recipe_mastery_count(recipe_id: String) -> int:
	return _known_recipes.get(recipe_id, 0)

# ============ Buff查询 ============

func get_active_buffs() -> Array:
	return _active_buffs.duplicate()

# ============ 内部方法 ============

## 计算产出品质 — 投入最低品质
func _calculate_output_quality() -> int:
	if _current_input_qualities.is_empty():
		return Quality.NORMAL
	var min_quality: int = Quality.SUPREME
	for q in _current_input_qualities.values():
		if q < min_quality:
			min_quality = q
	return min_quality

## 获取某种食材在背包中的最低品质（返回存在的最高品质）
func _get_lowest_ingredient_quality(ing_id: String) -> int:
	# 从低到高检查各品质，找到第一个有库存的品质
	var qualities = [Quality.NORMAL, Quality.FINE, Quality.EXCELLENT, Quality.SUPREME]
	for q in qualities:
		if InventorySystem.get_item_count(ing_id, q) > 0:
			return q
	return Quality.NORMAL

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
