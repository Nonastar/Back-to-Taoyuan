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

## 好感度常量
const FRIENDSHIP_MAX: int = 1000
const FRIENDSHIP_FEED_MIN: int = 1
const FRIENDSHIP_FEED_MAX: int = 3
const FRIENDSHIP_PET_MIN: int = 5
const FRIENDSHIP_PET_MAX: int = 12
const FRIENDSHIP_PICKUP_PENALTY: int = 10
const FRIENDSHIP_HEAL_BONUS: int = 30
const FRIENDSHIP_CLEAN_BONUS: int = 1

## 好感度等级阈值
const FRIENDSHIP_THRESHOLD_PAL: int = 200
const FRIENDSHIP_THRESHOLD_FRIEND: int = 400
const FRIENDSHIP_THRESHOLD_BEST_FRIEND: int = 700

## 好感度等级名称
const FRIENDSHIP_LEVEL_STRANGER: String = "Stranger"
const FRIENDSHIP_LEVEL_PAL: String = "Pal"
const FRIENDSHIP_LEVEL_FRIEND: String = "Friend"
const FRIENDSHIP_LEVEL_BEST_FRIEND: String = "Best Friend"

## 好感度等级对应的产出品质加成 (百分比)
const FRIENDSHIP_QUALITY_BONUS: Dictionary = {
	FRIENDSHIP_LEVEL_STRANGER: 0.0,
	FRIENDSHIP_LEVEL_PAL: 0.02,
	FRIENDSHIP_LEVEL_FRIEND: 0.05,
	FRIENDSHIP_LEVEL_BEST_FRIEND: 0.10
}

## 好感度等级枚举
enum FriendshipLevel {
	STRANGER = 0,
	PAL = 1,
	FRIEND = 2,
	BEST_FRIEND = 3
}

## 好感度等级对应的枚举映射
const FRIENDSHIP_LEVEL_TO_ENUM: Dictionary = {
	FRIENDSHIP_LEVEL_STRANGER: FriendshipLevel.STRANGER,
	FRIENDSHIP_LEVEL_PAL: FriendshipLevel.PAL,
	FRIENDSHIP_LEVEL_FRIEND: FriendshipLevel.FRIEND,
	FRIENDSHIP_LEVEL_BEST_FRIEND: FriendshipLevel.BEST_FRIEND
}

## 好感度等级阈值映射 (用于进度计算)
const _FRIENDSHIP_LEVEL_THRESHOLDS: Dictionary = {
	FRIENDSHIP_LEVEL_STRANGER: {"current": 0, "next": FRIENDSHIP_THRESHOLD_PAL},
	FRIENDSHIP_LEVEL_PAL: {"current": FRIENDSHIP_THRESHOLD_PAL, "next": FRIENDSHIP_THRESHOLD_FRIEND},
	FRIENDSHIP_LEVEL_FRIEND: {"current": FRIENDSHIP_THRESHOLD_FRIEND, "next": FRIENDSHIP_THRESHOLD_BEST_FRIEND},
	FRIENDSHIP_LEVEL_BEST_FRIEND: {"current": FRIENDSHIP_THRESHOLD_BEST_FRIEND, "next": 1000}
}

## ============ 疾病系统常量 ============

## 生病概率 (基于建筑脏乱天数)
const SICK_CHANCE_DIRTY_3_DAYS: float = 0.15   ## 连续脏乱3天: 15%
const SICK_CHANCE_DIRTY_2_DAYS: float = 0.05   ## 连续脏乱2天: 5%
const SICK_CHANCE_BASE: float = 0.01           ## 基础生病概率: 1%

## 治疗费用
const HEAL_COST: int = 100  ## 治疗费用: 100金币

## 治疗物品
const HEAL_ITEM_ID: String = "medicine"  ## 治疗需要消耗的物品ID

## 疾病常量
const SICKNESS_NAME: String = "疾病"
const SICKNESS_RECOVERY_FRIENDSHIP: int = 30  ## 治疗增加的好感度

## 产出品质常量
## 基础高品质概率：产物有10%基础概率为FINE+
const BASE_HIGH_QUALITY_CHANCE: float = 0.10  ## 10%基础高品质概率
const HIGH_QUALITY_THRESHOLD: float = 0.10    ## 高品质门槛（FINE及以上）

## 品质概率分布（用于roll品质）
## 普通品质：70%，优秀品质：20%，精良品质：9%，史诗品质：1%
const QUALITY_WEIGHTS: Dictionary = {
	0: 0.70,  ## NORMAL: 70%
	1: 0.20,  ## FINE: 20%
	2: 0.09,  ## EXCELLENT: 9%
	3: 0.01   ## SUPREME: 1%
}

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
signal animal_sick(unique_id: String)  ## 动物生病信号
signal animal_healed(unique_id: String)  ## 动物痊愈信号
signal product_collected(product_id: String, quantity: int)
signal animal_state_changed()
signal animal_friendship_changed(unique_id: String, old_friendship: int, new_friendship: int)

# ============ 状态 ============

var _buildings: Dictionary = {}  ## {building_type: BuildingState}
var _pending_products: Array[Dictionary] = []  ## 待收获产物
var _days_elapsed: int = 0  ## 系统运行天数
var _rng: RandomNumberGenerator  ## 共享随机数生成器，避免每帧 new 实例

## ============ 运行时配置（从 JSON 加载，const 为默认值）============

# 饲料消耗
var _feed_cost: int = FEED_COST_HAY

# 好感度
var _friendship_max: int = FRIENDSHIP_MAX
var _friendship_feed_min: int = FRIENDSHIP_FEED_MIN
var _friendship_feed_max: int = FRIENDSHIP_FEED_MAX
var _friendship_pet_min: int = FRIENDSHIP_PET_MIN
var _friendship_pet_max: int = FRIENDSHIP_PET_MAX
var _friendship_pickup_penalty: int = FRIENDSHIP_PICKUP_PENALTY
var _friendship_clean_bonus: int = FRIENDSHIP_CLEAN_BONUS

# 疾病
var _sick_chance_base: float = SICK_CHANCE_BASE
var _sick_chance_dirty_2: float = SICK_CHANCE_DIRTY_2_DAYS
var _sick_chance_dirty_3: float = SICK_CHANCE_DIRTY_3_DAYS
var _heal_cost: int = HEAL_COST
var _heal_item_id: String = HEAL_ITEM_ID
var _sickness_recovery_friendship: int = SICKNESS_RECOVERY_FRIENDSHIP

# 品质
var _base_high_quality_chance: float = BASE_HIGH_QUALITY_CHANCE
var _quality_weights: Dictionary = QUALITY_WEIGHTS.duplicate()

# 动物定义（从 JSON 加载）
var _animal_definitions: Dictionary = ANIMAL_DATA.duplicate()

# 建筑定义（从 JSON 加载）
var _building_definitions: Dictionary = {}

# ============ BuildingState 结构 ============
# var capacity: int
# var animals: Array[Dictionary]  ## [{animal_id, unique_id, days_in_building, is_mature, has_produced_today, is_sick}]
# var dirty_days: int  ## 连续脏乱天数

# ============ 初始化 ============

## 数据初始化（由 init() 调用，可注入外部数据源）
func init(data_source: Object = null) -> void:
	if data_source != null and data_source.has_method("load_animal_data"):
		var data: Dictionary = data_source.load_animal_data()
		if not data.is_empty():
			_apply_config(data)
			print("[AnimalHusbandrySystem] Config loaded from injected source")
			return
	_initialize_from_json()

func _initialize_from_json() -> void:
	if DataLoader:
		var data: Dictionary = DataLoader.load_json("animal_data.json")
		if not data.is_empty():
			_apply_config(data)
			print("[AnimalHusbandrySystem] Loaded config from JSON")
			return
	# 兜底：使用代码常量（JSON 缺失时保持行为不变）
	print("[AnimalHusbandrySystem] No animal_data.json found, using built-in defaults")

## 将加载的配置应用到运行时变量
func _apply_config(data: Dictionary) -> void:
	# 疾病配置
	var sickness: Dictionary = data.get("sickness", {})
	_sick_chance_base = sickness.get("base_chance", SICK_CHANCE_BASE)
	_sick_chance_dirty_2 = sickness.get("dirty_2_days_chance", SICK_CHANCE_DIRTY_2_DAYS)
	_sick_chance_dirty_3 = sickness.get("dirty_3_days_chance", SICK_CHANCE_DIRTY_3_DAYS)
	_heal_cost = sickness.get("heal_cost_money", HEAL_COST)
	_heal_item_id = sickness.get("heal_item_id", HEAL_ITEM_ID)
	_sickness_recovery_friendship = sickness.get("recovery_friendship", SICKNESS_RECOVERY_FRIENDSHIP)

	# 品质配置
	var quality: Dictionary = data.get("quality", {})
	_base_high_quality_chance = quality.get("base_high_quality_chance", BASE_HIGH_QUALITY_CHANCE)
	_quality_weights = quality.get("weights", QUALITY_WEIGHTS.duplicate())

	# 好感度配置
	var friendship: Dictionary = data.get("friendship", {})
	_friendship_max = friendship.get("max", FRIENDSHIP_MAX)
	_friendship_feed_min = friendship.get("feed_min", FRIENDSHIP_FEED_MIN)
	_friendship_feed_max = friendship.get("feed_max", FRIENDSHIP_FEED_MAX)
	_friendship_pet_min = friendship.get("pet_min", FRIENDSHIP_PET_MIN)
	_friendship_pet_max = friendship.get("pet_max", FRIENDSHIP_PET_MAX)
	_friendship_pickup_penalty = friendship.get("pickup_penalty", FRIENDSHIP_PICKUP_PENALTY)
	_friendship_clean_bonus = friendship.get("clean_bonus", FRIENDSHIP_CLEAN_BONUS)

	# 饲料成本
	_feed_cost = data.get("feed_cost", FEED_COST_HAY)

	# 动物定义（从 buildings/animals 中提取，building_type 需映射到枚举）
	var animals: Dictionary = data.get("animals", {})
	if not animals.is_empty():
		var mapped: Dictionary = {}
		for animal_id: String in animals.keys():
			var animal_def: Dictionary = animals[animal_id].duplicate()
			var bt_str: String = animal_def.get("building_type", "")
			var bt_int: int = _string_to_building_type(bt_str)
			if bt_int >= 0:
				animal_def["building_type"] = bt_int
			# 转换 animal type 字符串到枚举
			var type_str: String = animal_def.get("type", "")
			var type_int: int = _string_to_animal_type(type_str)
			if type_int >= 0:
				animal_def["type"] = type_int
			mapped[animal_id] = animal_def
		_animal_definitions = mapped

	# 建筑定义（从 buildings 中提取，JSON 键为字符串需映射到枚举）
	var buildings: Dictionary = data.get("buildings", {})
	if not buildings.is_empty():
		var mapped: Dictionary = {}
		for key in buildings.keys():
			var enum_key: int = _string_to_building_type(key)
			if enum_key >= 0:
				mapped[enum_key] = buildings[key]
		_building_definitions = mapped

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_initialize_from_json()
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
	var info: Dictionary = _building_definitions.get(building_type, BUILDING_INFO.get(building_type, {}))
	return info.get("capacity", 0)

## 获取指定建筑中的动物数量
func get_building_animal_count(building_type: BuildingType) -> int:
	var animals = get_animals_in_building(building_type)
	return animals.size()

## 检查是否可以建造
func can_build(building_type: BuildingType) -> bool:
	if _buildings.has(building_type):
		return false

	var info: Dictionary = _building_definitions.get(building_type, BUILDING_INFO.get(building_type, {}))
	var cost_money: int = info.get("cost_money", 0)
	var cost_wood: int = info.get("cost_wood", 0)

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

	var info: Dictionary = _building_definitions.get(building_type, BUILDING_INFO.get(building_type, {}))
	var cost_money: int = info.get("cost_money", 0)
	var cost_wood: int = info.get("cost_wood", 0)

	## 扣除费用
	if PlayerStats and PlayerStats.has_method("spend_money"):
		PlayerStats.spend_money(cost_money)
	if InventorySystem and InventorySystem.has_method("remove_item"):
		InventorySystem.remove_item("wood", cost_wood)

	## 创建建筑状态
	var capacity = info.get("capacity", 0)
	_buildings[building_type] = {
		"capacity": capacity,
		"animals": [],
		"dirty_days": 0  ## 初始干净
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
		"has_produced_today": false,
		"friendship": 0,  ## 初始好感度为0
		"fed_today": false,  ## 今日是否已喂养
		"pet_today": false,  ## 今日是否已抚摸
		"is_sick": false     ## 初始不生病
	})
	building["animals"] = animals

	animal_bought.emit(animal_id)
	animal_state_changed.emit()
	print("[AnimalHusbandrySystem] Bought animal: " + str(animal_data.get("name", animal_id)))
	return true

## 喂养动物 (批量喂养)
## 返回: 喂养成功的动物数量，失败返回-1表示饲料不足
func feed_animals() -> int:
	## 计算需要喂养的动物数量
	var total_animals = 0
	for building in _buildings.values():
		total_animals += building.get("animals", []).size()

	if total_animals == 0:
		return 0

	## 检查饲料是否足够 (每只动物1个干草)
	if InventorySystem and InventorySystem.has_method("get_item_count"):
		var hay_count: int = InventorySystem.get_item_count("hay")
		var total_cost: int = total_animals * _feed_cost
		if hay_count < total_cost:
			print("[AnimalHusbandrySystem] Not enough hay to feed all animals: need %d, have %d" % [total_cost, hay_count])
			return -1

	## 消耗饲料 (按动物数量)
	if InventorySystem and InventorySystem.has_method("remove_item"):
		var total_cost: int = total_animals * _feed_cost
		InventorySystem.remove_item("hay", total_cost)

	## 重置所有动物的产出状态（喂养后可以产出）
	var fed_count: int = 0
	for building in _buildings.values():
		var animals = building.get("animals", [])
		for animal in animals:
			animal["has_produced_today"] = false
			animal["fed_today"] = true  ## 标记已喂养，防止脏乱天数增加
			fed_count += 1

	animal_fed.emit("")
	animal_state_changed.emit()
	print("[AnimalHusbandrySystem] Fed %d animals, cost %d hay" % [fed_count, fed_count * _feed_cost])
	return fed_count

## 检查是否有可喂养动物
func has_animals_to_feed() -> bool:
	return _buildings.size() > 0

## 获取需要喂养的动物总数
func get_total_animals_to_feed() -> int:
	var total = 0
	for building in _buildings.values():
		var animals = building.get("animals", [])
		for animal in animals:
			if not animal.get("fed_today", false) and not animal.get("is_sick", false):
				total += 1
	return total

## 获取总喂养成本 (干草数量)
func get_total_feed_cost() -> int:
	return get_total_animals_to_feed() * _feed_cost

## 检查是否有足够的饲料喂养所有动物
func has_enough_feed() -> bool:
	if InventorySystem and InventorySystem.has_method("get_item_count"):
		var hay_count = InventorySystem.get_item_count("hay")
		return hay_count >= get_total_feed_cost()
	return false

## 收获所有产物（带品质计算）
## 遍历所有待收获产物，使用品质计算添加到背包
func collect_all_products() -> int:
	if _pending_products.is_empty():
		return 0

	var collected = 0
	## 倒序遍历，避免移除时索引变化问题
	for i in range(_pending_products.size() - 1, -1, -1):
		var result = collect_single_product(i)
		if result.get("success", false):
			collected += result.get("quantity", 1)

	return collected

## 检查是否有待收获产物
func has_products_to_collect() -> bool:
	return not _pending_products.is_empty()

## 获取待收获产物列表
func get_pending_products() -> Array:
	return _pending_products

## 获取可购买的动物列表
func get_buyable_animals() -> Array:
	var result: Array = []
	for animal_id in _animal_definitions.keys():
		var data: Dictionary = _animal_definitions[animal_id].duplicate()
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
	var result: Array = []
	for animal_id in _animal_definitions.keys():
		var data: Dictionary = _animal_definitions[animal_id].duplicate()
		data["animal_id"] = animal_id
		result.append(data)
	return result

# ============ 好感度系统 ============

## 根据好感度值获取等级名称
static func get_friendship_level_name(friendship: int) -> String:
	if friendship >= FRIENDSHIP_THRESHOLD_BEST_FRIEND:
		return FRIENDSHIP_LEVEL_BEST_FRIEND
	elif friendship >= FRIENDSHIP_THRESHOLD_FRIEND:
		return FRIENDSHIP_LEVEL_FRIEND
	elif friendship >= FRIENDSHIP_THRESHOLD_PAL:
		return FRIENDSHIP_LEVEL_PAL
	else:
		return FRIENDSHIP_LEVEL_STRANGER

## 根据好感度值获取等级枚举
static func get_friendship_level_enum(friendship: int) -> FriendshipLevel:
	return FRIENDSHIP_LEVEL_TO_ENUM.get(get_friendship_level_name(friendship), FriendshipLevel.STRANGER)

## 获取好感度等级对应的品质加成
static func get_quality_bonus_for_level(level_name: String) -> float:
	return FRIENDSHIP_QUALITY_BONUS.get(level_name, 0.0)

## 根据好感度值获取品质加成百分比
static func get_quality_bonus(friendship: int) -> float:
	var level_name = get_friendship_level_name(friendship)
	return get_quality_bonus_for_level(level_name)

## 根据好感度值获取等级进度 (0.0 - 1.0)
## 用于UI显示进度条
static func get_friendship_progress(friendship: int) -> float:
	var level_name = get_friendship_level_name(friendship)
	var thresholds = _FRIENDSHIP_LEVEL_THRESHOLDS.get(level_name, {"current": 0, "next": FRIENDSHIP_THRESHOLD_PAL})

	var current_threshold = thresholds["current"]
	var next_threshold = thresholds["next"]
	var range_size = next_threshold - current_threshold
	## 防止除以零（Best Friend 的 next=1000 不会出现此情况）
	if range_size <= 0:
		return 1.0
	var progress = friendship - current_threshold
	return clamp(float(progress) / float(range_size), 0.0, 1.0)

## 获取指定动物的好感度
func get_animal_friendship(unique_id: String) -> int:
	var result = _find_animal(unique_id)
	if result.is_empty():
		return -1
	return result["animal"].get("friendship", 0)

## 获取指定动物的好感度等级
func get_animal_friendship_level(unique_id: String) -> String:
	var friendship = get_animal_friendship(unique_id)
	if friendship < 0:
		return ""
	return get_friendship_level_name(friendship)

## 获取指定动物的好感度品质加成
func get_animal_quality_bonus(unique_id: String) -> float:
	var friendship = get_animal_friendship(unique_id)
	if friendship < 0:
		return 0.0
	return get_quality_bonus(friendship)

## 获取指定动物的好感度进度
func get_animal_friendship_progress(unique_id: String) -> float:
	var friendship = get_animal_friendship(unique_id)
	if friendship < 0:
		return 0.0
	return get_friendship_progress(friendship)

## 内部方法：修改动物好感度
func _modify_friendship(unique_id: String, delta: int) -> int:
	var result = _find_animal(unique_id)
	if result.is_empty():
		return -1
	var animal = result["animal"]
	var old_friendship = animal.get("friendship", 0)
	var new_friendship: int = clamp(old_friendship + delta, 0, _friendship_max)
	animal["friendship"] = new_friendship
	animal_friendship_changed.emit(unique_id, old_friendship, new_friendship)
	return new_friendship

## 喂养单个动物（增加好感度+1~3）
func feed_single_animal(unique_id: String) -> bool:
	var result = _find_animal(unique_id)
	if result.is_empty():
		return false  # 动物不存在

	var animal = result["animal"]
	if animal.get("fed_today", false):
		print("[AnimalHusbandrySystem] Animal already fed today: " + unique_id)
		return false

	# 检查饲料
	if InventorySystem and InventorySystem.has_method("get_item_count"):
		if InventorySystem.get_item_count("hay") < _feed_cost:
			print("[AnimalHusbandrySystem] Not enough hay to feed")
			return false
		InventorySystem.remove_item("hay", _feed_cost)

	# 随机好感度增量 (+1~3)
	var friendship_delta: int = _rng.randi_range(_friendship_feed_min, _friendship_feed_max)
	_modify_friendship(unique_id, friendship_delta)

	# 标记已喂养
	animal["fed_today"] = true

	print("[AnimalHusbandrySystem] Fed animal: " + unique_id + " (+" + str(friendship_delta) + " friendship)")
	return true

## 抚摸单个动物（增加好感度+5~12）
func pet_single_animal(unique_id: String) -> bool:
	var result = _find_animal(unique_id)
	if result.is_empty():
		return false  # 动物不存在

	var animal = result["animal"]
	if animal.get("pet_today", false):
		print("[AnimalHusbandrySystem] Animal already pet today: " + unique_id)
		return false

	# 随机好感度增量 (+5~12)
	var friendship_delta: int = _rng.randi_range(_friendship_pet_min, _friendship_pet_max)
	_modify_friendship(unique_id, friendship_delta)

	# 标记已抚摸
	animal["pet_today"] = true

	print("[AnimalHusbandrySystem] Pet animal: " + unique_id + " (+" + str(friendship_delta) + " friendship)")
	return true

## 检查指定动物今日是否已喂养
func is_animal_fed(unique_id: String) -> bool:
	var result = _find_animal(unique_id)
	if result.is_empty():
		return false
	return result["animal"].get("fed_today", false)

## 检查指定动物今日是否已抚摸
func is_animal_pet(unique_id: String) -> bool:
	var result = _find_animal(unique_id)
	if result.is_empty():
		return false
	return result["animal"].get("pet_today", false)

## 获取所有动物的详细信息（包含好感度）
func get_all_animals_with_friendship() -> Array:
	var result = []
	for building_type in _buildings.keys():
		var building = _buildings[building_type]
		var animals = building.get("animals", [])
		for animal in animals:
			var unique_id = animal.get("unique_id", "")
			var friendship = animal.get("friendship", 0)
			result.append({
				"unique_id": unique_id,
				"animal_id": animal.get("animal_id", ""),
				"friendship": friendship,
				"friendship_level": get_friendship_level_name(friendship),
				"friendship_progress": get_friendship_progress(friendship),
				"quality_bonus": get_quality_bonus(friendship),
				"fed_today": animal.get("fed_today", false),
				"pet_today": animal.get("pet_today", false),
				"is_mature": animal.get("is_mature", false),
				"has_produced_today": animal.get("has_produced_today", false),
				"days_in_building": animal.get("days_in_building", 0)
			})
	return result

## 获取指定动物的详细信息
func get_animal_details(unique_id: String) -> Dictionary:
	var result = _find_animal(unique_id)
	if result.is_empty():
		return {}
	var animal = result["animal"]
	var friendship = animal.get("friendship", 0)
	return {
		"unique_id": unique_id,
		"animal_id": animal.get("animal_id", ""),
		"friendship": friendship,
		"friendship_level": get_friendship_level_name(friendship),
		"friendship_progress": get_friendship_progress(friendship),
		"quality_bonus": get_quality_bonus(friendship),
		"fed_today": animal.get("fed_today", false),
		"pet_today": animal.get("pet_today", false),
		"is_mature": animal.get("is_mature", false),
		"has_produced_today": animal.get("has_produced_today", false),
		"is_sick": animal.get("is_sick", false),
		"days_in_building": animal.get("days_in_building", 0)
	}

# ============ 疾病系统 ============

## 检查动物是否生病
func is_animal_sick(unique_id: String) -> bool:
	var result = _find_animal(unique_id)
	if result.is_empty():
		return false
	return result["animal"].get("is_sick", false)

## 检查是否有生病动物
func has_sick_animals() -> bool:
	for building in _buildings.values():
		for animal in building.get("animals", []):
			if animal.get("is_sick", false):
				return true
	return false

## 获取生病动物列表
func get_sick_animals() -> Array:
	var result = []
	for building in _buildings.values():
		for animal in building.get("animals", []):
			if animal.get("is_sick", false):
				result.append({
					"unique_id": animal.get("unique_id", ""),
					"animal_id": animal.get("animal_id", ""),
					"friendship": animal.get("friendship", 0)
				})
	return result

## 计算生病概率 (基于建筑脏乱天数)
func get_sick_probability(building_type: BuildingType) -> float:
	if not _buildings.has(building_type):
		return _sick_chance_base

	var building = _buildings[building_type]
	var dirty_days: int = building.get("dirty_days", 0)

	if dirty_days >= 3:
		return _sick_chance_dirty_3  ## 15%
	elif dirty_days >= 2:
		return _sick_chance_dirty_2  ## 5%
	else:
		return _sick_chance_base  ## 1%

## 获取建筑脏乱天数
func get_building_dirty_days(building_type: BuildingType) -> int:
	if not _buildings.has(building_type):
		return 0
	return _buildings[building_type].get("dirty_days", 0)

## 清理建筑 (增加所有动物好感度+1，重置脏乱天数)
func clean_building(building_type: BuildingType) -> bool:
	if not _buildings.has(building_type):
		return false

	var building = _buildings[building_type]
	var animals = building.get("animals", [])

	## 重置脏乱天数
	building["dirty_days"] = 0

	## 所有动物好感度+1
	for animal in animals:
		var unique_id = animal.get("unique_id", "")
		_modify_friendship(unique_id, _friendship_clean_bonus)

	animal_state_changed.emit()
	print("[AnimalHusbandrySystem] Cleaned building: " + str(building_type))
	return true

## 治疗生病动物
## 返回: {success, message, friendship_delta}
func heal_animal(unique_id: String) -> Dictionary:
	if not is_animal_sick(unique_id):
		return {"success": false, "message": "动物没有生病"}

	## 检查治疗费用 (金币或物品)
	var has_item: bool = false
	if InventorySystem and InventorySystem.has_method("get_item_count"):
		var medicine_count: int = InventorySystem.get_item_count(_heal_item_id)
		has_item = medicine_count > 0

	## 优先使用物品，如果没有则使用金币
	if has_item:
		## 消耗治疗物品
		if InventorySystem and InventorySystem.has_method("remove_item"):
			InventorySystem.remove_item(_heal_item_id, 1)
	elif PlayerStats and PlayerStats.has_method("spend_money"):
		## 检查金币
		if PlayerStats.get_money() < _heal_cost:
			return {"success": false, "message": "金币不足 (需要 %d)" % _heal_cost}
		## 扣除金币
		PlayerStats.spend_money(_heal_cost)
	else:
		return {"success": false, "message": "无法进行支付"}

	## 治疗动物
	var result = _find_animal(unique_id)
	if not result.is_empty():
		result["animal"]["is_sick"] = false

	## 增加好感度
	var friendship_delta: int = _modify_friendship(unique_id, _sickness_recovery_friendship)

	animal_healed.emit(unique_id)
	animal_state_changed.emit()

	var details = get_animal_details(unique_id)
	var animal_name = details.get("animal_id", "未知动物")

	print("[AnimalHusbandrySystem] Healed animal: " + unique_id + " (+%d friendship)" % friendship_delta)

	return {
		"success": true,
		"message": "治愈了 %s! 好感度+%d" % [animal_name, friendship_delta],
		"friendship_delta": friendship_delta
	}

## 检查是否可以治疗 (有足够的金币或物品)
func can_heal_animal(unique_id: String) -> bool:
	if not is_animal_sick(unique_id):
		return false

	## 检查治疗物品
	if InventorySystem and InventorySystem.has_method("get_item_count"):
		if InventorySystem.get_item_count(_heal_item_id) > 0:
			return true

	## 检查金币
	if PlayerStats and PlayerStats.has_method("get_money"):
		return PlayerStats.get_money() >= _heal_cost

	return false

## 检查是否有可治疗的动物
func has_healable_animals() -> bool:
	return has_sick_animals()

# ============ 产出系统 ============

## 根据品质加成计算最终品质
## quality_bonus: 好感度带来的品质加成 (0.0 - 0.10)
## 返回: Quality.NORMAL (0), Quality.FINE (1), Quality.EXCELLENT (2), 或 Quality.SUPREME (3)
func calculate_product_quality(quality_bonus: float) -> int:
	## 最终高品质概率 = 基础概率 + 好感度加成
	var final_high_quality_chance: float = clamp(_base_high_quality_chance + quality_bonus, 0.0, 1.0)

	## 掷骰决定是否高品质
	var roll: float = _rng.randf()
	if roll >= final_high_quality_chance:
		return Quality.NORMAL  # 70%概率普通品质

	## 进入高品质池，掷骰决定具体品质
	## 调整权重以适应高质量概率增加
	var high_roll: float = _rng.randf()

	## 史诗品质
	if high_roll < _quality_weights.get(Quality.SUPREME, 0.01):
		return Quality.SUPREME

	## 精良品质
	high_roll -= _quality_weights.get(Quality.SUPREME, 0.01)
	if high_roll < _quality_weights.get(Quality.EXCELLENT, 0.09):
		return Quality.EXCELLENT

	## 优秀品质
	high_roll -= _quality_weights.get(Quality.EXCELLENT, 0.09)
	if high_roll < _quality_weights.get(Quality.FINE, 0.20):
		return Quality.FINE

	## 默认优秀品质（如果以上都不中）
	return Quality.FINE

## 获取待收获产物的品质（不消耗）
## 返回指定index产物的预估品质
func get_product_preview_quality(product_index: int) -> Dictionary:
	if product_index < 0 or product_index >= _pending_products.size():
		return {}

	var product = _pending_products[product_index]
	var quality_bonus = product.get("quality_bonus", 0.0)
	var quality = calculate_product_quality(quality_bonus)

	return {
		"quality": quality,
		"quality_name": Quality.get_quality_name(quality),
		"quality_bonus": quality_bonus,
		"quality_color": Quality.get_color(quality)
	}

## 获取所有待收获产物的品质预览
func get_all_products_quality_preview() -> Array:
	var previews = []
	for i in range(_pending_products.size()):
		previews.append(get_product_preview_quality(i))
	return previews

## 获取产物详情
func get_product_details(product_index: int) -> Dictionary:
	if product_index < 0 or product_index >= _pending_products.size():
		return {}

	var product = _pending_products[product_index]
	return {
		"index": product_index,
		"product_id": product.get("product_id", ""),
		"quantity": product.get("quantity", 1),
		"unique_id": product.get("unique_id", ""),
		"quality_bonus": product.get("quality_bonus", 0.0)
	}

## 收集单个产物（带品质计算）
## 返回: {success, product_id, quantity, quality, quality_name}
func collect_single_product(product_index: int) -> Dictionary:
	if product_index < 0 or product_index >= _pending_products.size():
		return {"success": false, "message": "Invalid product index"}

	var product = _pending_products[product_index]
	var product_id = product.get("product_id", "")
	var quantity = product.get("quantity", 1)
	var quality_bonus = product.get("quality_bonus", 0.0)

	## 计算品质
	var quality = calculate_product_quality(quality_bonus)

	## 添加到背包
	if InventorySystem and InventorySystem.has_method("add_item"):
		var success = InventorySystem.add_item(product_id, quantity, quality)
		if not success:
			return {"success": false, "message": "Inventory full"}

		## 从待收获列表移除
		_pending_products.remove_at(product_index)

		product_collected.emit(product_id, quantity)
		animal_state_changed.emit()

		print("[AnimalHusbandrySystem] Collected: " + str(product_id) + " x" + str(quantity) + " (" + Quality.get_quality_name(quality) + ")")

		return {
			"success": true,
			"product_id": product_id,
			"quantity": quantity,
			"quality": quality,
			"quality_name": Quality.get_quality_name(quality)
		}
	else:
		return {"success": false, "message": "InventorySystem not available"}

# ============ 每日更新 ============

func daily_update() -> void:
	_days_elapsed += 1
	print("[AnimalHusbandrySystem] Daily update: Day " + str(_days_elapsed))

	for building_type in _buildings.keys():
		var building = _buildings[building_type]
		var animals = building.get("animals", [])
		_update_building_dirty_days(building, animals)
		for animal in animals:
			_process_animal_daily_status(animal, building_type)

	animal_state_changed.emit()

## 更新建筑脏乱天数
func _update_building_dirty_days(building: Dictionary, animals: Array) -> void:
	var was_fed = false
	for animal in animals:
		if animal.get("fed_today", false):
			was_fed = true
			break
	if not was_fed:
		building["dirty_days"] = building.get("dirty_days", 0) + 1

## 处理动物每日状态：重置状态、检查成熟、检查疾病、尝试产出
func _process_animal_daily_status(animal: Dictionary, building_type: BuildingType) -> void:
	animal["fed_today"] = false
	animal["pet_today"] = false
	animal["days_in_building"] += 1

	_check_animal_maturity(animal)
	_check_animal_sickness(animal, building_type)
	_maybe_produce_product(animal)

func _check_animal_maturity(animal: Dictionary) -> void:
	var animal_id = animal.get("animal_id", "")
	var animal_data = _get_animal_data(animal_id)
	var maturity_days = animal_data.get("maturity_days", 5)
	if animal["days_in_building"] >= maturity_days:
		animal["is_mature"] = true

func _check_animal_sickness(animal: Dictionary, building_type: BuildingType) -> void:
	if animal.get("is_sick", false):
		return
	var sick_roll = _rng.randf()
	var sick_chance = get_sick_probability(building_type)
	if sick_roll < sick_chance:
		animal["is_sick"] = true
		animal_sick.emit(animal.get("unique_id", ""))
		print("[AnimalHusbandrySystem] Animal became sick: " + str(animal.get("animal_id", "")))

func _maybe_produce_product(animal: Dictionary) -> void:
	if not animal["is_mature"] or animal.get("is_sick", false) or animal.get("has_produced_today", false):
		return
	var animal_id = animal.get("animal_id", "")
	var animal_data = _get_animal_data(animal_id)
	_try_produce(animal, animal_data)

func _try_produce(animal: Dictionary, animal_data: Dictionary) -> void:
	var production_rate = animal_data.get("production_rate", 0.5)
	var roll = _rng.randf()

	if roll < production_rate:
		var product_id = animal_data.get("product_id", "")
		var unique_id = animal.get("unique_id", "")

		## 计算产出品质加成
		var quality_bonus = get_quality_bonus(animal.get("friendship", 0))

		_pending_products.append({
			"product_id": product_id,
			"quantity": 1,
			"unique_id": unique_id,  ## 记录产出该产品的动物
			"quality_bonus": quality_bonus  ## 存储品质加成
		})
		animal["has_produced_today"] = true
		print("[AnimalHusbandrySystem] Production: " + str(product_id) + " (quality_bonus: " + str(quality_bonus) + ")")

# ============ 内部方法 ============

func _get_animal_data(animal_id: String) -> Dictionary:
	return _animal_definitions.get(animal_id, {})

## 获取动物数据（公开方法，供外部调用）
func get_animal_data(animal_id: String) -> Dictionary:
	return _get_animal_data(animal_id)

## 内部辅助方法：通过 unique_id 查找动物
## 返回 {building_type: int, animal: Dictionary} 或空字典（未找到）
func _find_animal(unique_id: String) -> Dictionary:
	for building_type in _buildings.keys():
		var animals: Array = _buildings[building_type].get("animals", [])
		for animal in animals:
			if animal.get("unique_id") == unique_id:
				return {"building_type": building_type, "animal": animal}
	return {}

func _string_to_building_type(s: String) -> int:
	match s:
		"coop": return BuildingType.COOP
		"barn": return BuildingType.BARN
	return -1

func _string_to_animal_type(s: String) -> int:
	match s:
		"chicken": return AnimalType.CHICKEN
		"duck": return AnimalType.DUCK
		"cow": return AnimalType.COW
		"sheep": return AnimalType.SHEEP
		"pig": return AnimalType.PIG
		"goat": return AnimalType.GOAT
	return -1

func _generate_unique_id() -> String:
	return "animal_" + str(Time.get_ticks_usec())

# ============ 存档支持 ============

func serialize() -> Dictionary:
	return {
		"buildings": _buildings,
		"pending_products": _pending_products,
		"days_elapsed": _days_elapsed
	}

func deserialize(data: Dictionary) -> void:
	_buildings = data.get("buildings", {})
	_pending_products = Array(data.get("pending_products", []), TYPE_DICTIONARY, "", null)
	_days_elapsed = data.get("days_elapsed", 0)

	## 迁移旧存档数据（添加新字段）
	_migrate_legacy_data()

	print("[AnimalHusbandrySystem] Loaded: buildings=" + str(_buildings.size()) + ", products=" + str(_pending_products.size()))

## 迁移旧存档数据，添加新字段以保持兼容性
func _migrate_legacy_data() -> void:
	for building_type in _buildings.keys():
		var building = _buildings[building_type]
		var animals = building.get("animals", [])

		## 确保dirty_days字段存在
		if not building.has("dirty_days"):
			building["dirty_days"] = 0

		for i in range(animals.size()):
			var animal = animals[i]
			## 确保新字段存在
			if not animal.has("friendship"):
				animals[i]["friendship"] = 0
			if not animal.has("fed_today"):
				animals[i]["fed_today"] = false
			if not animal.has("pet_today"):
				animals[i]["pet_today"] = false
			if not animal.has("is_sick"):
				animals[i]["is_sick"] = false

	## 迁移待收获产物数据
	for i in range(_pending_products.size()):
		var product = _pending_products[i]
		if not product.has("quality_bonus"):
			_pending_products[i]["quality_bonus"] = 0.0
		if not product.has("unique_id"):
			_pending_products[i]["unique_id"] = ""
