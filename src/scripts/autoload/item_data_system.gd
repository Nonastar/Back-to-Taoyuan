extends Node

## ItemDataSystem - 物品数据系统
## 负责加载和管理所有物品定义
## 参考: F03 物品数据系统 GDD

# ============ 常量 ============

## 物品数据目录
const ITEMS_DATA_PATH: String = "res://src/resources/data/items/"

## 默认堆叠限制
const DEFAULT_MAX_STACK: int = 9999
const SEED_STACK: int = 999
const ORE_STACK: int = 999

# ============ 信号 ============

## 物品数据加载完成
signal items_loaded()

## 物品数据验证失败
signal validation_failed(errors: Array)

# ============ 数据存储 ============

## 物品定义字典 {id: ItemDef}
var _items: Dictionary = {}

## 是否已加载
var _is_loaded: bool = false

# ============ 生命周期 ============

func _ready() -> void:
	load_all_items()

## 加载所有物品数据
func load_all_items() -> void:
	_items.clear()

	# 加载所有物品定义文件
	var dir = DirAccess.open(ITEMS_DATA_PATH)
	if dir == null:
		print("[ItemDataSystem] Items directory not found: %s" % ITEMS_DATA_PATH)
		print("[ItemDataSystem] Creating default items...")
		_create_default_items()
		_is_loaded = true
		items_loaded.emit()
		print("[ItemDataSystem] Loaded %d default items" % _items.size())
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	var items_loaded_count = 0

	while file_name != "":
		if file_name.ends_with(".tres"):
			var item_path = ITEMS_DATA_PATH + file_name
			var item_def = load(item_path)
			if item_def is ItemDef:
				_register_item(item_def)
				items_loaded_count += 1
		file_name = dir.get_next()

	dir.list_dir_end()

	# 如果没有加载任何物品，创建默认物品
	if items_loaded_count == 0:
		print("[ItemDataSystem] No items found, creating defaults...")
		_create_default_items()

	# 验证所有物品
	var errors = _validate_all_items()
	if errors.size() > 0:
		validation_failed.emit(errors)

	_is_loaded = true
	items_loaded.emit()
	print("[ItemDataSystem] Loaded %d items" % _items.size())

# ============ 物品注册 ============

## 注册物品定义
func _register_item(item_def: ItemDef) -> bool:
	if item_def.id.is_empty():
		push_error("[ItemDataSystem] Cannot register item with empty ID")
		return false

	if _items.has(item_def.id):
		push_error("[ItemDataSystem] Duplicate item ID: %s" % item_def.id)
		return false

	_items[item_def.id] = item_def
	return true

# ============ 查询API ============

## 根据ID获取物品定义
func get_item_def(item_id: String) -> ItemDef:
	if _items.has(item_id):
		return _items[item_id]
	return null

## 检查物品是否存在
func item_exists(item_id: String) -> bool:
	return _items.has(item_id)

## 获取指定分类的所有物品
func get_items_by_category(category: int) -> Array[ItemDef]:
	var result: Array[ItemDef] = []
	for item_def in _items.values():
		if item_def.category == category:
			result.append(item_def)
	return result

## 获取具有指定标签的所有物品
func get_items_by_tag(tag: String) -> Array[ItemDef]:
	var result: Array[ItemDef] = []
	for item_def in _items.values():
		if tag in item_def.tags:
			result.append(item_def)
	return result

## 获取所有物品
func get_all_items() -> Array:
	var result: Array[ItemDef] = []
	for item_def in _items.values():
		result.append(item_def)
	return result

## 获取物品数量
func get_item_count() -> int:
	return _items.size()

# ============ 品质计算 ============

## 获取品质修正系数
func get_quality_multiplier(quality: int) -> float:
	return Quality.get_multiplier(quality)

## 计算实际售价
func calculate_sell_price(base_price: int, quality: int = Quality.NORMAL) -> int:
	var multiplier = Quality.get_multiplier(quality)
	return int(base_price * multiplier)

## 获取品质颜色
func get_quality_color(quality: int) -> Color:
	return Quality.get_color(quality)

## 获取品质名称
func get_quality_name(quality: int) -> String:
	return Quality.get_quality_name(quality)

# ============ 验证 ============

## 验证所有物品数据
func _validate_all_items() -> Array:
	var errors: Array = []

	for item_id in _items:
		var item_def = _items[item_id]
		if not item_def.validate():
			errors.append("Invalid item: %s" % item_id)

	return errors

## 验证单个物品
func validate_item(item_id: String) -> bool:
	var item_def = get_item_def(item_id)
	if item_def == null:
		return false
	return item_def.validate()

# ============ 显示信息 ============

## 获取物品显示信息
func get_display_info(item_id: String, quality: int = Quality.NORMAL) -> Dictionary:
	var item_def = get_item_def(item_id)
	if item_def == null:
		return {}
	return item_def.get_display_info(quality)

## 获取物品名称
func get_item_name(item_id: String) -> String:
	var item_def = get_item_def(item_id)
	if item_def:
		return item_def.name
	return "Unknown"

## 获取物品描述
func get_item_description(item_id: String) -> String:
	var item_def = get_item_def(item_id)
	if item_def:
		return item_def.description
	return ""

# ============ 默认物品 ============

## 创建默认物品（当数据目录为空时）
func _create_default_items() -> void:
	# 创建基础物品
	var default_items = [
		_create_copper_ore(),
		_create_gold_ore(),
		_create_wood(),
		_create_bamboo(),
		_create_stone(),
		_create_coal(),
		_create_egg(),
		_create_milk(),
		_create_duck_egg(),
		_create_goat_milk(),
		_create_wool(),
		_create_truffle(),
		_create_hay(),
		_create_wheat(),
		_create_rice(),
		_create_tomato_seed(),
		_create_carrot_seed(),
		_create_tomato(),
		_create_potato(),
		_create_basic_fertilizer(),
		_create_quality_fertilizer(),
		_create_growth_fertilizer(),
		_create_moisture_fertilizer(),
		_create_bait_common(),
		_create_bait_deluxe(),
		_create_bait_legendary(),
	]

	for item in default_items:
		if item != null:
			_register_item(item)

	_is_loaded = true
	items_loaded.emit()

	# 注册鱼类和烹饪产出物品（void方法）
	_create_fish_items()
	_create_cooking_outputs()


## 创建鱼类物品定义（供测试和游戏使用）
func _create_fish_items() -> void:
	# 注册所有鱼类物品（与 FishingSystem.FISH_DATA 对应）
	# 这些物品在鱼塘取出、钓鱼捕获后添加到背包
	var fish_items = [
		["bluegill", "蓝鳃鱼", "常见的淡水鱼，可食用", 10],
		["carp", "鲤鱼", "常见的淡水鱼，可食用", 25],
		["frog", "青蛙", "湿地水域的青蛙，可食用", 15],
		["koi", "锦鲤", "色彩鲜艳的观赏鱼，可食用", 100],
		["catfish", "鲶鱼", "河流中的大型鱼，可食用", 50],
		["trout", "鳟鱼", "冷水流域的鲜美鱼，可食用", 30],
		["bass", "鲈鱼", "湖泊中的掠食鱼，可食用", 45],
		["snow_fish", "雪鱼", "寒冷水域的珍稀鱼，可食用", 80],
		["golden_fish", "金鱼", "金色的美丽鱼，可食用", 150],
		["eel", "鳗鱼", "河流中的蛇形鱼，可食用", 150],
		["salmon", "三文鱼", "海洋回流鱼，富含营养", 60],
		["mountain_trout", "山鳟", "高海拔冷水鳟鱼，可食用", 120],
		["ice_fish", "冰鱼", "极寒水域的透明鱼，可食用", 200],
		["magic_fish", "魔法鱼", "蕴含魔力的神秘鱼，可食用", 250],
		["swamp_creature", "沼泽生物", "沼泽中的奇特生物，可食用", 100],
		["tuna", "金枪鱼", "大洋中的大型鱼类，可食用", 180],
		["swordfish", "剑鱼", "长嘴的海洋掠食者，可食用", 300],
		["shark", "鲨鱼", "海洋顶级掠食者，可食用", 500],
		["legendary_fish", "传说鱼", "传说中的稀世鱼类", 1000],
		["mythical_fish", "神话鱼", "神话中记载的神奇鱼类", 5000],
		["treasure_fish", "宝藏鱼", "据说藏着宝藏的鱼类", 800]
	]
	for d in fish_items:
		var item = ItemDef.new()
		item.id = d[0]
		item.name = d[1]
		item.description = d[2]
		item.category = ItemCategory.FISH
		item.sell_price = d[3]
		item.icon_path = ""
		item.max_stack = DEFAULT_MAX_STACK
		_register_item(item)

## 创建烹饪产出物品定义（供测试使用）
func _create_cooking_outputs() -> ItemDef:
	# 创建10种烹饪产出物品（与 CookingSystem.recipes 对应）
	# 这些物品在测试中被 eat_dish() 添加到背包
	var items_data = [
		["egg_dish", "煎蛋", "香喷喷的煎蛋，食用恢复体力", 15],
		["bread", "烤面包", "香脆的烤面包，食用加速移动", 20],
		["juice", "果汁", "清爽的果汁，食用恢复体力", 18],
		["veg_soup", "蔬菜汤", "清淡的蔬菜汤，食用恢复体力", 22],
		["meat_soup", "肉汤", "浓郁的肉汤，食用恢复体力", 30],
		["fish_soup", "鱼汤", "鲜美的鱼汤，食用增加幸运", 28],
		["cake", "蛋糕", "甜美的蛋糕，食用大幅恢复体力", 40],
		["jam", "果酱", "甜甜的果酱，食用增加幸运", 25],
		["cheese", "奶酪", "浓郁的奶酪，食用加速移动", 35],
		["honey_dish", "蜂蜜料理", "甜蜜的蜂蜜料理，食用恢复体力", 32]
	]
	for d in items_data:
		var item = ItemDef.new()
		item.id = d[0]
		item.name = d[1]
		item.description = d[2]
		item.category = ItemCategory.FOOD
		item.sell_price = d[3]
		item.icon_path = ""
		item.max_stack = DEFAULT_MAX_STACK
		_register_item(item)
	return null  # 不返回单个物品，而是注册多个

## 创建铜矿定义
func _create_copper_ore() -> ItemDef:
	var item = ItemDef.new()
	item.id = "copper_ore"
	item.name = "铜矿"
	item.description = "一块含有铜的矿石。"
	item.category = ItemCategory.ORE
	item.sell_price = 5
	item.icon_path = "res://assets/art/items/copper_ore.png"
	item.max_stack = ORE_STACK
	return item

## 创建金矿定义
func _create_gold_ore() -> ItemDef:
	var item = ItemDef.new()
	item.id = "gold_ore"
	item.name = "金矿"
	item.description = "一块闪闪发光的金矿石。"
	item.category = ItemCategory.ORE
	item.sell_price = 25
	item.icon_path = "res://assets/art/items/gold_ore.png"
	item.max_stack = ORE_STACK
	return item

## 创建木材定义
func _create_wood() -> ItemDef:
	var item = ItemDef.new()
	item.id = "wood"
	item.name = "木材"
	item.description = "普通的木材，可用于建筑和加工。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 2
	item.icon_path = "res://assets/art/items/wood.png"
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建竹子定义
func _create_bamboo() -> ItemDef:
	var item = ItemDef.new()
	item.id = "bamboo"
	item.name = "竹子"
	item.description = "坚韧的竹子，可用于建筑和加工。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 3
	item.icon_path = ""
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建石头定义
func _create_stone() -> ItemDef:
	var item = ItemDef.new()
	item.id = "stone"
	item.name = "石头"
	item.description = "普通的石头，可用于建筑。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 1
	item.icon_path = "res://assets/art/items/stone.png"
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建煤炭定义
func _create_coal() -> ItemDef:
	var item = ItemDef.new()
	item.id = "coal"
	item.name = "煤炭"
	item.description = "可用于熔炼的燃料。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 10
	item.icon_path = "res://assets/art/items/coal.png"
	item.max_stack = ORE_STACK
	return item

## 创建鸡蛋定义
func _create_egg() -> ItemDef:
	var item = ItemDef.new()
	item.id = "egg"
	item.name = "鸡蛋"
	item.description = "新鲜的鸡蛋。"
	item.category = ItemCategory.CROP
	item.sell_price = 5
	item.icon_path = "res://assets/art/items/egg.png"
	item.edible = true
	item.stamina_restore = 10
	item.health_restore = 5
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建牛奶定义
func _create_milk() -> ItemDef:
	var item = ItemDef.new()
	item.id = "milk"
	item.name = "牛奶"
	item.description = "新鲜的牛奶。"
	item.category = ItemCategory.CROP
	item.sell_price = 8
	item.icon_path = "res://assets/art/items/milk.png"
	item.edible = true
	item.stamina_restore = 15
	item.health_restore = 8
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建小麦定义
func _create_wheat() -> ItemDef:
	var item = ItemDef.new()
	item.id = "wheat"
	item.name = "小麦"
	item.description = "成熟的小麦，可用于制作面粉。"
	item.category = ItemCategory.CROP
	item.sell_price = 3
	item.icon_path = "res://assets/art/items/wheat.png"
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建大米定义
func _create_rice() -> ItemDef:
	var item = ItemDef.new()
	item.id = "rice"
	item.name = "大米"
	item.description = "脱壳后的大米，可用于烹饪。"
	item.category = ItemCategory.CROP
	item.sell_price = 4
	item.icon_path = "res://assets/art/items/rice.png"
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建番茄种子定义
func _create_tomato_seed() -> ItemDef:
	var item = ItemDef.new()
	item.id = "tomato_seed"
	item.name = "番茄种子"
	item.description = "可以种植番茄的种子。成熟需要4天。"
	item.category = ItemCategory.SEED
	item.sell_price = 10
	item.icon_path = "res://assets/art/items/tomato_seed.png"
	item.max_stack = SEED_STACK
	item.tags = ["spring", "summer", "crop"]
	item.growth_days = 4
	return item

## 创建胡萝卜种子定义
func _create_carrot_seed() -> ItemDef:
	var item = ItemDef.new()
	item.id = "carrot_seed"
	item.name = "胡萝卜种子"
	item.description = "可以种植胡萝卜的种子。成熟需要3天。"
	item.category = ItemCategory.SEED
	item.sell_price = 5
	item.icon_path = "res://assets/art/items/carrot_seed.png"
	item.max_stack = SEED_STACK
	item.tags = ["spring", "fall", "crop"]
	item.growth_days = 3
	return item

## 创建番茄作物定义
func _create_tomato() -> ItemDef:
	var item = ItemDef.new()
	item.id = "tomato"
	item.name = "番茄"
	item.description = "新鲜的红番茄，可食用或出售。"
	item.category = ItemCategory.CROP
	item.sell_price = 30
	item.icon_path = "res://assets/art/items/tomato.png"
	item.edible = true
	item.stamina_restore = 20
	item.health_restore = 10
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建土豆定义
func _create_potato() -> ItemDef:
	var item = ItemDef.new()
	item.id = "potato"
	item.name = "土豆"
	item.description = "新鲜的土豆，可食用或作为种子。"
	item.category = ItemCategory.CROP
	item.sell_price = 8
	item.icon_path = "res://assets/art/items/potato.png"
	item.edible = true
	item.stamina_restore = 12
	item.health_restore = 5
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建基础肥料定义
func _create_basic_fertilizer() -> ItemDef:
	var item = ItemDef.new()
	item.id = "basic_fertilizer"
	item.name = "基础肥料"
	item.description = "提升作物品质的普通肥料。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 10
	item.icon_path = ""
	item.max_stack = 99
	return item

## 创建优质肥料定义
func _create_quality_fertilizer() -> ItemDef:
	var item = ItemDef.new()
	item.id = "quality_fertilizer"
	item.name = "优质肥料"
	item.description = "更有效提升作物品质的肥料。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 25
	item.icon_path = ""
	item.max_stack = 99
	return item

## 创建生长激素定义
func _create_growth_fertilizer() -> ItemDef:
	var item = ItemDef.new()
	item.id = "growth_fertilizer"
	item.name = "生长激素"
	item.description = "加速作物生长的激素。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 20
	item.icon_path = ""
	item.max_stack = 99
	return item

## 创建保湿土定义
func _create_moisture_fertilizer() -> ItemDef:
	var item = ItemDef.new()
	item.id = "moisture_fertilizer"
	item.name = "保湿土"
	item.description = "保持土壤水分，减少浇水需求。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 15
	item.icon_path = ""
	item.max_stack = 99
	return item

## 创建普通饵料定义
func _create_bait_common() -> ItemDef:
	var item = ItemDef.new()
	item.id = "bait_common"
	item.name = "普通饵料"
	item.description = "增加10%咬钩率。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 5
	item.icon_path = ""
	item.max_stack = 99
	return item

## 创建美味饵料定义
func _create_bait_deluxe() -> ItemDef:
	var item = ItemDef.new()
	item.id = "bait_deluxe"
	item.name = "美味饵料"
	item.description = "增加20%咬钩率。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 15
	item.icon_path = ""
	item.max_stack = 99
	return item

## 创建传说饵料定义
func _create_bait_legendary() -> ItemDef:
	var item = ItemDef.new()
	item.id = "bait_legendary"
	item.name = "传说饵料"
	item.description = "增加50%咬钩率，10%传说鱼概率提升。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 50
	item.icon_path = ""
	item.max_stack = 99
	return item

## 创建鸭蛋定义
func _create_duck_egg() -> ItemDef:
	var item = ItemDef.new()
	item.id = "duck_egg"
	item.name = "鸭蛋"
	item.description = "新鲜的鸭蛋，比鸡蛋大一些。"
	item.category = ItemCategory.CROP
	item.sell_price = 15
	item.icon_path = ""
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建羊奶定义
func _create_goat_milk() -> ItemDef:
	var item = ItemDef.new()
	item.id = "goat_milk"
	item.name = "羊奶"
	item.description = "营养丰富的羊奶，比牛奶更易消化。"
	item.category = ItemCategory.FOOD
	item.sell_price = 25
	item.icon_path = ""
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建羊毛定义
func _create_wool() -> ItemDef:
	var item = ItemDef.new()
	item.id = "wool"
	item.name = "羊毛"
	item.description = "柔软的羊毛，可用于纺织或出售。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 30
	item.icon_path = ""
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建松露定义
func _create_truffle() -> ItemDef:
	var item = ItemDef.new()
	item.id = "truffle"
	item.name = "松露"
	item.description = "珍贵的真菌，可出售获得高价。"
	item.category = ItemCategory.CROP
	item.sell_price = 100
	item.icon_path = ""
	item.max_stack = DEFAULT_MAX_STACK
	return item

## 创建干草定义
func _create_hay() -> ItemDef:
	var item = ItemDef.new()
	item.id = "hay"
	item.name = "干草"
	item.description = "动物的饲料，用于喂养农场动物。"
	item.category = ItemCategory.MATERIAL
	item.sell_price = 5
	item.icon_path = ""
	item.max_stack = DEFAULT_MAX_STACK
	return item
