extends Node

## FishPondSystem - 鱼塘系统 MVP
## 管理鱼塘养殖和每日产出
## 简化版：不包含水质、疾病、繁殖系统

# ============ 常量 ============

## 鱼塘建造费用
const BUILD_COST_MONEY: int = 5000
const BUILD_COST_WOOD: int = 100
const BUILD_COST_BAMBOO: int = 50

## 鱼塘容量
const BASE_CAPACITY: int = 5

## 可养殖鱼类定义
## 每种鱼包含：名称、成熟天数、产出概率、产物ID
const PONDABLE_FISH: Dictionary = {
	## 溪流鱼类 (3-5天成熟)
	"bluegill": {"name": "蓝鳃鱼", "maturity_days": 3, "production_rate": 0.40, "product_id": "bluegill"},
	"carp": {"name": "鲤鱼", "maturity_days": 4, "production_rate": 0.35, "product_id": "carp"},
	"grass_fish": {"name": "草鱼", "maturity_days": 5, "production_rate": 0.30, "product_id": "grass_fish"},

	## 池塘鱼类 (6-8天成熟)
	"koi": {"name": "锦鲤", "maturity_days": 6, "production_rate": 0.25, "product_id": "koi"},
	"golden_fish": {"name": "金鱼", "maturity_days": 7, "production_rate": 0.20, "product_id": "golden_fish"},
	"turtle": {"name": "乌龟", "maturity_days": 8, "production_rate": 0.15, "product_id": "turtle"},

	## 江河鱼类 (5-6天成熟)
	"bass": {"name": "鲈鱼", "maturity_days": 5, "production_rate": 0.30, "product_id": "bass"},
	"catfish": {"name": "鲶鱼", "maturity_days": 5, "production_rate": 0.28, "product_id": "catfish"},
	"eel": {"name": "黄鳝", "maturity_days": 6, "production_rate": 0.25, "product_id": "eel"},

	## 瀑布鱼类 (6天成熟)
	"rainbow_trout": {"name": "虹鳟", "maturity_days": 6, "production_rate": 0.25, "product_id": "rainbow_trout"},

	## 沼泽鱼类 (2-3天成熟，高产出)
	"swamp_loach": {"name": "沼泽泥鳅", "maturity_days": 2, "production_rate": 0.50, "product_id": "swamp_loach"},
	"snail": {"name": "田螺", "maturity_days": 3, "production_rate": 0.45, "product_id": "snail"},

	## 矿洞鱼类 (8天成熟)
	"cave_fish": {"name": "洞穴盲鱼", "maturity_days": 8, "production_rate": 0.15, "product_id": "cave_fish"}
}

# ============ 信号 ============

signal pond_built()
signal fish_added(fish_id: String, count: int)
signal fish_removed(fish_id: String)
signal product_collected(product_id: String, quality: String, quantity: int)
signal pond_state_changed()

# ============ 状态 ============

var _is_built: bool = false
var _fish_in_pond: Array[Dictionary] = []  ## 鱼塘中的鱼类 [{fish_id, days_in_pond}]
var _capacity: int = BASE_CAPACITY
var _pending_products: Array[Dictionary] = []  ## 待收获产物 [{product_id, quality, quantity}]
var _days_elapsed: int = 0  ## 鱼塘已运行天数

# ============ 初始化 ============

func _ready() -> void:
	_connect_signals()
	print("[FishPondSystem] Initialized")

func _connect_signals() -> void:
	## 连接日结算信号
	if EventBus and EventBus.has_signal("time_sleep_triggered"):
		EventBus.time_sleep_triggered.connect(_on_sleep_triggered)
		print("[FishPondSystem] Connected to time_sleep_triggered")

func _on_sleep_triggered(bedtime: int, forced: bool) -> void:
	daily_update()

# ============ 公共 API ============

## 检查鱼塘是否已建造
func is_built() -> bool:
	return _is_built

## 获取鱼塘容量
func get_capacity() -> int:
	return _capacity

## 获取当前鱼类数量
func get_fish_count() -> int:
	return _fish_in_pond.size()

## 获取鱼塘中的鱼类列表
func get_fish_list() -> Array:
	var result: Array = []
	for fish_entry in _fish_in_pond:
		var fish_id = fish_entry["fish_id"]
		var fish_data = _get_fish_data(fish_id)
		if not fish_data.is_empty():
			var days_in_pond = fish_entry.get("days_in_pond", 0)
			var maturity_days = fish_data.get("maturity_days", 5)
			var is_mature = days_in_pond >= maturity_days
			result.append({
				"fish_id": fish_id,
				"name": fish_data.get("name", "未知"),
				"days_in_pond": days_in_pond,
				"maturity_days": maturity_days,
				"is_mature": is_mature,
				"production_rate": fish_data.get("production_rate", 0.3)
			})
	return result

## 获取待收获产物列表
func get_pending_products() -> Array[Dictionary]:
	return _pending_products

## 获取建造费用
func get_build_cost() -> Dictionary:
	return {
		"money": BUILD_COST_MONEY,
		"wood": BUILD_COST_WOOD,
		"bamboo": BUILD_COST_BAMBOO
	}

## 检查是否可以建造
func can_build() -> bool:
	if _is_built:
		return false

	## 检查金钱
	if PlayerStats and PlayerStats.has_method("get_money"):
		if PlayerStats.get_money() < BUILD_COST_MONEY:
			return false

	## 检查材料
	if InventorySystem and InventorySystem.has_method("get_item_count"):
		if InventorySystem.get_item_count("wood") < BUILD_COST_WOOD:
			return false
		if InventorySystem.get_item_count("bamboo") < BUILD_COST_BAMBOO:
			return false

	return true

## 建造鱼塘
func build_pond() -> bool:
	if not can_build():
		print("[FishPondSystem] Cannot build pond")
		return false

	## 扣除费用
	if PlayerStats and PlayerStats.has_method("spend_money"):
		PlayerStats.spend_money(BUILD_COST_MONEY)
	if InventorySystem and InventorySystem.has_method("remove_item"):
		InventorySystem.remove_item("wood", BUILD_COST_WOOD)
		InventorySystem.remove_item("bamboo", BUILD_COST_BAMBOO)

	_is_built = true
	_fish_in_pond = []
	_capacity = BASE_CAPACITY
	_pending_products = []
	_days_elapsed = 0

	pond_built.emit()
	pond_state_changed.emit()
	print("[FishPondSystem] Pond built!")
	return true

## 检查是否可以放入鱼
func can_add_fish(fish_id: String) -> bool:
	if not _is_built:
		return false

	if not PONDABLE_FISH.has(fish_id):
		print("[FishPondSystem] Fish not pondable: " + str(fish_id))
		return false

	if _fish_in_pond.size() >= _capacity:
		print("[FishPondSystem] Pond is full")
		return false

	## 检查背包中是否有这条鱼
	if InventorySystem and InventorySystem.has_method("get_item_count"):
		if InventorySystem.get_item_count(fish_id) <= 0:
			return false

	return true

## 放入鱼类到鱼塘
func add_fish(fish_id: String) -> bool:
	if not can_add_fish(fish_id):
		return false

	## 从背包移除鱼
	if InventorySystem and InventorySystem.has_method("remove_item"):
		InventorySystem.remove_item(fish_id, 1)

	## 添加到鱼塘
	_fish_in_pond.append({
		"fish_id": fish_id,
		"days_in_pond": 0
	})

	fish_added.emit(fish_id, 1)
	pond_state_changed.emit()
	print("[FishPondSystem] Added fish to pond: " + str(fish_id))
	return true

## 从鱼塘取出鱼类
func remove_fish(index: int) -> bool:
	if index < 0 or index >= _fish_in_pond.size():
		return false

	var fish_entry = _fish_in_pond[index]
	var fish_id = fish_entry["fish_id"]

	## 添加回背包
	if InventorySystem and InventorySystem.has_method("add_item"):
		InventorySystem.add_item(fish_id, 1)

	## 从鱼塘移除
	_fish_in_pond.remove_at(index)

	fish_removed.emit(fish_id)
	pond_state_changed.emit()
	print("[FishPondSystem] Removed fish from pond: " + str(fish_id))
	return true

## 收获产物
func collect_products() -> int:
	if _pending_products.is_empty():
		return 0

	var collected = 0
	for product in _pending_products:
		var product_id = product["product_id"]
		var quantity = product.get("quantity", 1)

		## 添加到背包
		if InventorySystem and InventorySystem.has_method("add_item"):
			InventorySystem.add_item(product_id, quantity)
			collected += quantity

		product_collected.emit(product_id, product.get("quality", "normal"), quantity)
		print("[FishPondSystem] Collected: " + str(product_id) + " x" + str(quantity))

	## 清空待收获列表
	_pending_products = []
	pond_state_changed.emit()

	return collected

## 每日更新
func daily_update() -> void:
	if not _is_built:
		return

	_days_elapsed += 1

	## 增加所有鱼的养殖天数
	for fish_entry in _fish_in_pond:
		fish_entry["days_in_pond"] += 1

	## 计算产出
	_calculate_daily_production()

	pond_state_changed.emit()
	print("[FishPondSystem] Daily update: " + str(_days_elapsed) + " days, fish count: " + str(_fish_in_pond.size()))

## 检查是否有可收获产物
func has_products_to_collect() -> bool:
	return not _pending_products.is_empty()

## 获取可养殖鱼类列表
func get_pondable_fish_list() -> Array:
	var result = []
	for fish_id in PONDABLE_FISH.keys():
		var data = PONDABLE_FISH[fish_id]
		result.append({
			"fish_id": fish_id,
			"name": data.get("name", "未知"),
			"maturity_days": data.get("maturity_days", 5),
			"production_rate": data.get("production_rate", 0.3)
		})
	return result

## 检查鱼类是否可养殖
func is_fish_pondable(fish_id: String) -> bool:
	return PONDABLE_FISH.has(fish_id)

# ============ 内部方法 ============

func _get_fish_data(fish_id: String) -> Dictionary:
	return PONDABLE_FISH.get(fish_id, {})

func _calculate_daily_production() -> void:
	var rng = RandomNumberGenerator.new()

	for fish_entry in _fish_in_pond:
		var fish_id = fish_entry["fish_id"]
		var days_in_pond = fish_entry.get("days_in_pond", 0)
		var fish_data = _get_fish_data(fish_id)

		if fish_data.is_empty():
			continue

		var maturity_days = fish_data.get("maturity_days", 5)

		## 未成熟的鱼不产出
		if days_in_pond < maturity_days:
			continue

		## 计算产出
		var production_rate = fish_data.get("production_rate", 0.3)
		var roll = rng.randf()

		if roll < production_rate:
			var product_id = fish_data.get("product_id", fish_id)
			var quality = _roll_quality()
			var quantity = 1

			_pending_products.append({
				"product_id": product_id,
				"quality": quality,
				"quantity": quantity
			})

			print("[FishPondSystem] Production: " + str(product_id) + " (quality: " + str(quality) + ")")

func _roll_quality() -> String:
	var rng = RandomNumberGenerator.new()
	var roll = rng.randf()

	## 基础高品质概率 10%
	var quality_chance = 0.10

	## 钓鱼技能加成（每级+2%）
	var skill_bonus = 0.0
	if SkillSystem and SkillSystem.has_method("get_level"):
		var fishing_level = SkillSystem.get_level(SkillSystem.SkillType.FISHING)
		skill_bonus = fishing_level * 0.02

	var total_chance = quality_chance + skill_bonus
	total_chance = clampf(total_chance, 0.0, 0.30)  ## 最高30%

	if roll < total_chance * 0.33:
		return "excellent"
	elif roll < total_chance:
		return "fine"
	else:
		return "normal"

# ============ 存档支持 ============

func serialize() -> Dictionary:
	return {
		"is_built": _is_built,
		"fish_in_pond": _fish_in_pond,
		"capacity": _capacity,
		"pending_products": _pending_products,
		"days_elapsed": _days_elapsed
	}

func deserialize(data: Dictionary) -> void:
	_is_built = data.get("is_built", false)
	_fish_in_pond = data.get("fish_in_pond", [])
	_capacity = data.get("capacity", BASE_CAPACITY)
	_pending_products = data.get("pending_products", [])
	_days_elapsed = data.get("days_elapsed", 0)

	print("[FishPondSystem] Loaded: built=" + str(_is_built) + ", fish=" + str(_fish_in_pond.size()))
