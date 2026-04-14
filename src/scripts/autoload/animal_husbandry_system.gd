extends Node

## AnimalHusbandrySystem - 畜牧系统 MVP
## 管理动物养殖和每日产出
## 简化版：不包含繁殖、亲密度、疾病系统

# ============ 常量 ============

## 建筑建造费用
const BARN_COST_MONEY: int = 2000
const BARN_COST_WOOD: int = 50
const COOP_COST_MONEY: int = 1000
const COOP_COST_WOOD: int = 30

## 建筑容量
const BARN_BASE_CAPACITY: int = 4  # 谷仓基础容量
const COOP_BASE_CAPACITY: int = 8   # 鸡舍基础容量

## 饲料消耗
const FEED_COST_HAY: int = 1  # 每次喂养消耗干草数量

## 动物类型枚举
enum AnimalType { CHICKEN, COW, SHEEP, PIG, GOAT, DUCK }

## 建筑类型枚举
enum BuildingType { COOP, BARN }

## 建筑信息
const BUILDING_INFO: Dictionary = {
	BuildingType.COOP: {
		"name": "鸡舍",
		"description": "可容纳小动物（鸡、鸭）",
		"capacity": COOP_BASE_CAPACITY,
		"cost_money": COOP_COST_MONEY,
		"cost_wood": COOP_COST_WOOD,
		"animal_types": [AnimalType.CHICKEN, AnimalType.DUCK]
	},
	BuildingType.BARN: {
		"name": "谷仓",
		"description": "可容纳大型动物（牛、羊、猪、山羊）",
		"capacity": BARN_BASE_CAPACITY,
		"cost_money": BARN_COST_MONEY,
		"cost_wood": BARN_COST_WOOD,
		"animal_types": [AnimalType.COW, AnimalType.SHEEP, AnimalType.PIG, AnimalType.GOAT]
	}
}

## 动物定义
## 每种动物包含：名称、类型、购买价格、成熟天数、每日产出概率、产物ID
const ANIMAL_DATA: Dictionary = {
	## 小动物 (鸡舍)
	"chicken_white": {
		"name": "白鸡",
		"type": AnimalType.CHICKEN,
		"buy_price": 400,
		"maturity_days": 3,
		"production_rate": 0.60,
		"product_id": "egg",
		"building_type": BuildingType.COOP,
		"emoji": "🐔"
	},
	"chicken_brown": {
		"name": "棕鸡",
		"type": AnimalType.CHICKEN,
		"buy_price": 400,
		"maturity_days": 3,
		"production_rate": 0.60,
		"product_id": "egg",
		"building_type": BuildingType.COOP,
		"emoji": "🐔"
	},
	"duck": {
		"name": "鸭子",
		"type": AnimalType.DUCK,
		"buy_price": 500,
		"maturity_days": 4,
		"production_rate": 0.50,
		"product_id": "duck_egg",
		"building_type": BuildingType.COOP,
		"emoji": "🦆"
	},

	## 大型动物 (谷仓)
	"cow": {
		"name": "牛",
		"type": AnimalType.COW,
		"buy_price": 1000,
		"maturity_days": 5,
		"production_rate": 0.70,
		"product_id": "milk",
		"building_type": BuildingType.BARN,
		"emoji": "🐄"
	},
	"sheep": {
		"name": "绵羊",
		"type": AnimalType.SHEEP,
		"buy_price": 800,
		"maturity_days": 4,
		"production_rate": 0.50,
		"product_id": "wool",
		"building_type": BuildingType.BARN,
		"emoji": "🐑"
	},
	"pig": {
		"name": "猪",
		"type": AnimalType.PIG,
		"buy_price": 1200,
		"maturity_days": 6,
		"production_rate": 0.40,
		"product_id": "truffle",
		"building_type": BuildingType.BARN,
		"emoji": "🐷"
	},
	"goat": {
		"name": "山羊",
		"type": AnimalType.GOAT,
		"buy_price": 900,
		"maturity_days": 4,
		"production_rate": 0.60,
		"product_id": "goat_milk",
		"building_type": BuildingType.BARN,
		"emoji": "🐐"
	}
}

# ============ 信号 ============

signal building_built(building_type: BuildingType)
signal animal_bought(animal_id: String)
signal animal_fed(animal_id: String)
signal product_collected(product_id: String, quantity: int)
signal animal_state_changed()

# ============ 状态 ============

var _buildings: Dictionary = {}  ## {building_type: BuildingState}
var _pending_products: Array[Dictionary] = []  ## 待收获产物
var _days_elapsed: int = 0  ## 系统运行天数

# ============ BuildingState 结构 ============
# var capacity: int
# var animals: Array[Dictionary]  ## [{animal_id, unique_id, days_in_building, is_mature, has_produced_today}]

# ============ 初始化 ============

func _ready() -> void:
	_connect_signals()
	print("[AnimalHusbandrySystem] Initialized")

func _connect_signals() -> void:
	## 连接日结算信号
	if EventBus and EventBus.has_signal("time_sleep_triggered"):
		EventBus.time_sleep_triggered.connect(_on_sleep_triggered)
		print("[AnimalHusbandrySystem] Connected to time_sleep_triggered")

func _on_sleep_triggered(bedtime: int, forced: bool) -> void:
	daily_update()

# ============ 公共 API ============

## 检查是否已建造指定建筑
func is_building_built(building_type: BuildingType) -> bool:
	return _buildings.has(building_type)

## 获取建筑状态
func get_building_state(building_type: BuildingType) -> Dictionary:
	if not _buildings.has(building_type):
		return {}
	return _buildings[building_type]

## 获取指定建筑中的动物列表
func get_animals_in_building(building_type: BuildingType) -> Array:
	if not _buildings.has(building_type):
		return []
	return _buildings[building_type].get("animals", [])

## 获取建筑容量
func get_building_capacity(building_type: BuildingType) -> int:
	var info = BUILDING_INFO.get(building_type, {})
	return info.get("capacity", 0)

## 获取指定建筑中的动物数量
func get_building_animal_count(building_type: BuildingType) -> int:
	var animals = get_animals_in_building(building_type)
	return animals.size()

## 检查是否可以建造
func can_build(building_type: BuildingType) -> bool:
	if _buildings.has(building_type):
		return false

	var info = BUILDING_INFO.get(building_type, {})
	var cost_money = info.get("cost_money", 0)
	var cost_wood = info.get("cost_wood", 0)

	## 检查金钱
	if PlayerStats and PlayerStats.has_method("get_money"):
		if PlayerStats.get_money() < cost_money:
			return false

	## 检查材料
	if InventorySystem and InventorySystem.has_method("get_item_count"):
		if InventorySystem.get_item_count("wood") < cost_wood:
			return false

	return true

## 建造建筑
func build_building(building_type: BuildingType) -> bool:
	if not can_build(building_type):
		print("[AnimalHusbandrySystem] Cannot build building: " + str(building_type))
		return false

	var info = BUILDING_INFO.get(building_type, {})
	var cost_money = info.get("cost_money", 0)
	var cost_wood = info.get("cost_wood", 0)

	## 扣除费用
	if PlayerStats and PlayerStats.has_method("spend_money"):
		PlayerStats.spend_money(cost_money)
	if InventorySystem and InventorySystem.has_method("remove_item"):
		InventorySystem.remove_item("wood", cost_wood)

	## 创建建筑状态
	var capacity = info.get("capacity", 0)
	_buildings[building_type] = {
		"capacity": capacity,
		"animals": []
	}

	building_built.emit(building_type)
	animal_state_changed.emit()
	print("[AnimalHusbandrySystem] Built building: " + str(info.get("name", "未知")))
	return true

## 检查是否可以购买动物
func can_buy_animal(animal_id: String) -> bool:
	var animal_data = _get_animal_data(animal_id)
	if animal_data.is_empty():
		return false

	var building_type = animal_data.get("building_type", -1)
	if not _buildings.has(building_type):
		return false

	var building = _buildings[building_type]
	var animal_count = building.get("animals", []).size()
	if animal_count >= building.get("capacity", 0):
		return false

	var buy_price = animal_data.get("buy_price", 0)
	if PlayerStats and PlayerStats.has_method("get_money"):
		if PlayerStats.get_money() < buy_price:
			return false

	return true

## 购买动物
func buy_animal(animal_id: String) -> bool:
	if not can_buy_animal(animal_id):
		return false

	var animal_data = _get_animal_data(animal_id)
	var building_type = animal_data.get("building_type", -1)
	var buy_price = animal_data.get("buy_price", 0)

	## 扣除费用
	if PlayerStats and PlayerStats.has_method("spend_money"):
		PlayerStats.spend_money(buy_price)

	## 添加动物到建筑
	var building = _buildings[building_type]
	var animals = building.get("animals", [])
	var unique_id = _generate_unique_id()
	animals.append({
		"animal_id": animal_id,
		"unique_id": unique_id,
		"days_in_building": 0,
		"is_mature": false,
		"has_produced_today": false
	})
	building["animals"] = animals

	animal_bought.emit(animal_id)
	animal_state_changed.emit()
	print("[AnimalHusbandrySystem] Bought animal: " + str(animal_data.get("name", animal_id)))
	return true

## 喂养动物
func feed_animals() -> int:
	if InventorySystem and InventorySystem.has_method("get_item_count"):
		var hay_count = InventorySystem.get_item_count("hay")
		if hay_count < FEED_COST_HAY:
			print("[AnimalHusbandrySystem] Not enough hay to feed animals")
			return 0

	## 消耗饲料
	if InventorySystem and InventorySystem.has_method("remove_item"):
		InventorySystem.remove_item("hay", FEED_COST_HAY)

	## 重置所有动物的产出状态（喂养后可以产出）
	for building in _buildings.values():
		var animals = building.get("animals", [])
		for animal in animals:
			animal["has_produced_today"] = false

	animal_fed.emit("")
	animal_state_changed.emit()
	print("[AnimalHusbandrySystem] Fed all animals")
	return FEED_COST_HAY

## 检查是否有可喂养动物
func has_animals_to_feed() -> bool:
	return _buildings.size() > 0

## 收获所有产物
func collect_all_products() -> int:
	if _pending_products.is_empty():
		return 0

	var collected = 0
	for product in _pending_products:
		var product_id = product.get("product_id", "")
		var quantity = product.get("quantity", 1)

		if InventorySystem and InventorySystem.has_method("add_item"):
			InventorySystem.add_item(product_id, quantity)
			collected += quantity

		product_collected.emit(product_id, quantity)
		print("[AnimalHusbandrySystem] Collected: " + str(product_id) + " x" + str(quantity))

	## 清空待收获列表
	_pending_products = []
	animal_state_changed.emit()

	return collected

## 检查是否有待收获产物
func has_products_to_collect() -> bool:
	return not _pending_products.is_empty()

## 获取待收获产物列表
func get_pending_products() -> Array:
	return _pending_products

## 获取可购买的动物列表
func get_buyable_animals() -> Array:
	var result = []
	for animal_id in ANIMAL_DATA.keys():
		var data = ANIMAL_DATA[animal_id].duplicate()
		data["animal_id"] = animal_id
		## 检查是否已满
		var building_type = data.get("building_type", -1)
		if _buildings.has(building_type):
			var building = _buildings[building_type]
			var animal_count = building.get("animals", []).size()
			var capacity = building.get("capacity", 0)
			data["is_full"] = animal_count >= capacity
		else:
			data["is_full"] = true  # 未建造对应建筑
		result.append(data)
	return result

## 获取所有可养殖动物信息
func get_all_animal_info() -> Array:
	var result = []
	for animal_id in ANIMAL_DATA.keys():
		var data = ANIMAL_DATA[animal_id].duplicate()
		data["animal_id"] = animal_id
		result.append(data)
	return result

# ============ 每日更新 ============

func daily_update() -> void:
	_days_elapsed += 1
	print("[AnimalHusbandrySystem] Daily update: Day " + str(_days_elapsed))

	## 遍历所有建筑
	for building_type in _buildings.keys():
		var building = _buildings[building_type]
		var animals = building.get("animals", [])

		for animal in animals:
			## 增加养殖天数
			animal["days_in_building"] += 1

			## 检查是否成熟
			var animal_id = animal.get("animal_id", "")
			var animal_data = _get_animal_data(animal_id)
			var maturity_days = animal_data.get("maturity_days", 5)

			if animal["days_in_building"] >= maturity_days:
				animal["is_mature"] = true

			## 如果已成熟且今日未产出，计算产出
			if animal["is_mature"] and not animal.get("has_produced_today", false):
				_try_produce(animal, animal_data)

	animal_state_changed.emit()

func _try_produce(animal: Dictionary, animal_data: Dictionary) -> void:
	var rng = RandomNumberGenerator.new()
	var production_rate = animal_data.get("production_rate", 0.5)
	var roll = rng.randf()

	if roll < production_rate:
		var product_id = animal_data.get("product_id", "")
		_pending_products.append({
			"product_id": product_id,
			"quantity": 1
		})
		animal["has_produced_today"] = true
		print("[AnimalHusbandrySystem] Production: " + str(product_id))

# ============ 内部方法 ============

func _get_animal_data(animal_id: String) -> Dictionary:
	return ANIMAL_DATA.get(animal_id, {})

func _generate_unique_id() -> String:
	return "animal_" + str(Time.get_ticks_msec()) + "_" + str(randf())

# ============ 存档支持 ============

func serialize() -> Dictionary:
	return {
		"buildings": _buildings,
		"pending_products": _pending_products,
		"days_elapsed": _days_elapsed
	}

func deserialize(data: Dictionary) -> void:
	_buildings = data.get("buildings", {})
	_pending_products = data.get("pending_products", [])
	_days_elapsed = data.get("days_elapsed", 0)
	print("[AnimalHusbandrySystem] Loaded: buildings=" + str(_buildings.size()) + ", products=" + str(_pending_products.size()))
