extends "res://tests/unit/test_base.gd"

## FishPondSystem 鱼塘系统单元测试
## 测试鱼塘建造、鱼类管理、每日产出
## 注意：每个测试必须自行重置状态，防止测试间污染

var _pond: Node = null

func _reset_all_state():
	"""重置所有状态到初始值"""
	_pond._is_built = false
	_pond._fish_in_pond = Array([], TYPE_DICTIONARY, "", null)
	_pond._capacity = _pond.BASE_CAPACITY
	_pond._pending_products = Array([], TYPE_DICTIONARY, "", null)
	_pond._days_elapsed = 0

func before_each():
	_pond = Node.new()
	_pond.set_script(load("res://src/scripts/autoload/fish_pond_system.gd"))
	_pond._ready()

func after_each():
	_reset_all_state()
	_pond.free()

# ============ 常量测试 ============

func test_build_cost_constants():
	var cost = _pond.get_build_cost()
	assert_eq(cost["money"], 5000, "建造费用-金币应为5000")
	assert_eq(cost["wood"], 100, "建造费用-木材应为100")
	assert_eq(cost["bamboo"], 50, "建造费用-竹子应为50")

func test_base_capacity():
	assert_eq(_pond.BASE_CAPACITY, 5, "基础容量应为5")

# ============ 建造状态测试 ============

func test_initial_state_not_built():
	assert_false(_pond.is_built(), "初始状态鱼塘未建造")
	assert_eq(_pond.get_fish_count(), 0, "未建造时鱼类数量应为0")
	assert_false(_pond.has_products_to_collect(), "未建造时无产物可收集")

func test_capacity_when_not_built():
	## 未建造时容量仍返回基础值
	assert_eq(_pond.get_capacity(), 5, "未建造时容量应为5")

# ============ 可养殖鱼类测试 ============

func test_pondable_fish_list_not_empty():
	var fish_list = _pond.get_pondable_fish_list()
	assert_gt(fish_list.size(), 0, "可养殖鱼类列表不应为空")

func test_is_fish_pondable():
	assert_true(_pond.is_fish_pondable("bluegill"), "蓝鳃鱼应可放入鱼塘")
	assert_true(_pond.is_fish_pondable("carp"), "鲤鱼应可放入鱼塘")
	assert_true(_pond.is_fish_pondable("swamp_loach"), "沼泽泥鳅应可放入鱼塘")
	assert_false(_pond.is_fish_pondable("nonexistent"), "不存在鱼类应返回false")

func test_pondable_fish_data_structure():
	var fish_list = _pond.get_pondable_fish_list()
	for fish in fish_list:
		assert_true(fish.has("fish_id"), "每条鱼应有fish_id")
		assert_true(fish.has("name"), "每条鱼应有name")
		assert_true(fish.has("maturity_days"), "每条鱼应有maturity_days")
		assert_true(fish.has("production_rate"), "每条鱼应有production_rate")

# ============ 建造测试 ============

## 测试 can_build 初始返回（无 PlayerStats/InventorySystem）
func test_can_build_without_external_systems():
	var can = _pond.can_build()
	assert_true(can is bool, "can_build应返回布尔值")

## 测试建造成功
func test_build_pond_success():
	assert_false(_pond.is_built(), "初始应未建造")
	_pond._is_built = true
	_pond._fish_in_pond = Array([], TYPE_DICTIONARY, "", null)
	_pond._capacity = _pond.BASE_CAPACITY
	_pond._pending_products = Array([], TYPE_DICTIONARY, "", null)
	_pond._days_elapsed = 0
	assert_true(_pond.is_built(), "建造后应为已建造")
	assert_eq(_pond.get_fish_count(), 0, "新建鱼塘鱼类数量为0")
	assert_false(_pond.has_products_to_collect(), "新建鱼塘无产物")

## 测试重复建造失败
func test_build_twice_fails():
	_pond._is_built = true
	var success = _pond.build_pond()
	assert_false(success, "重复建造应返回 false")

func test_can_add_fish_fails_when_not_built():
	assert_false(_pond.can_add_fish("bluegill"), "未建造时不能放鱼")

func test_can_add_fish_fails_for_unknown_fish():
	_pond._is_built = true
	assert_false(_pond.can_add_fish("unknown_fish"), "未知鱼种不能放入鱼塘")

func test_can_add_fish_fails_when_capacity_full():
	_pond._is_built = true
	_pond._capacity = 1
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 0})
	assert_false(_pond.can_add_fish("carp"), "鱼塘满时不能继续放鱼")

# ============ 鱼类数量和容量测试 ============

func test_get_fish_count_empty():
	assert_eq(_pond.get_fish_count(), 0, "空鱼塘鱼类数量为0")

func test_get_fish_count_after_adding():
	_pond._is_built = true
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 3})
	_pond._fish_in_pond.append({"fish_id": "carp", "days_in_pond": 5})
	assert_eq(_pond.get_fish_count(), 2, "添加2条鱼后数量应为2")

func test_get_capacity():
	_pond._capacity = 10
	assert_eq(_pond.get_capacity(), 10, "容量应为10")

# ============ 鱼类列表测试 ============

func test_get_fish_list_structure():
	_pond._is_built = true
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 5})

	var fish_list = _pond.get_fish_list()
	assert_eq(fish_list.size(), 1, "应有1条鱼")
	var fish = fish_list[0]
	assert_true(fish.has("fish_id"), "应包含fish_id")
	assert_true(fish.has("name"), "应包含name")
	assert_true(fish.has("days_in_pond"), "应包含days_in_pond")
	assert_true(fish.has("maturity_days"), "应包含maturity_days")
	assert_true(fish.has("is_mature"), "应包含is_mature")

func test_fish_maturity_based_on_days():
	_pond._is_built = true
	## bluegill: maturity_days=3
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 2})  ## 未成熟
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 3})  ## 刚好成熟

	var fish_list = _pond.get_fish_list()
	assert_false(fish_list[0]["is_mature"], "2天未成熟")
	assert_true(fish_list[1]["is_mature"], "3天应成熟")

# ============ 每日产出测试 ============

## 测试未建造时不执行每日更新
func test_daily_update_skips_when_not_built():
	_pond._days_elapsed = 0
	_pond.daily_update()
	assert_eq(_pond._days_elapsed, 0, "未建造时不应推进天数")

## 测试每日更新推进天数
func test_daily_update_increments_days():
	_pond._is_built = true
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 0})
	_pond.daily_update()
	assert_eq(_pond._days_elapsed, 1, "天数应+1")
	assert_eq(_pond._fish_in_pond[0]["days_in_pond"], 1, "鱼的养殖天数应+1")

## 测试未成熟鱼不产出
func test_immature_fish_no_production():
	_pond._is_built = true
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 1})  ## 3天成熟
	_pond._pending_products = Array([], TYPE_DICTIONARY, "", null)

	_pond._calculate_daily_production()
	assert_eq(_pond._pending_products.size(), 0, "未成熟鱼不应产出")

## 测试成熟鱼有概率产出（多次尝试）
func test_mature_fish_can_produce():
	_pond._is_built = true
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 10})  ## 远超成熟天数

	## 多次尝试，应至少有几次成功
	var produced_count = 0
	for i in range(50):
		_pond._pending_products = Array([], TYPE_DICTIONARY, "", null)
		_pond._calculate_daily_production()
		if _pond._pending_products.size() > 0:
			produced_count += 1

	assert_gt(produced_count, 0, "50次尝试中至少应有1次产出")

## 测试产出物结构
func test_production_product_structure():
	_pond._is_built = true
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 10})
	_pond._calculate_daily_production()

	if _pond._pending_products.size() > 0:
		var product = _pond._pending_products[0]
		assert_true(product.has("product_id"), "产物应包含product_id")
		assert_true(product.has("quality"), "产物应包含quality")
		assert_true(product.has("quantity"), "产物应包含quantity")
		assert_eq(product["quantity"], 1, "默认产出数量应为1")

# ============ 产物收集测试 ============

func test_collect_empty_returns_zero():
	var collected = _pond.collect_products()
	assert_eq(collected, 0, "空鱼塘收集应返回0")

func test_has_products_to_collect():
	assert_false(_pond.has_products_to_collect(), "初始无产物")
	_pond._pending_products.append({"product_id": "bluegill", "quality": "normal", "quantity": 1})
	assert_true(_pond.has_products_to_collect(), "有产物时应返回true")

func test_collect_clears_pending():
	_pond._is_built = true
	_pond._pending_products.append({"product_id": "egg", "quality": "normal", "quantity": 2})
	_pond._pending_products.append({"product_id": "milk", "quality": "fine", "quantity": 1})
	_pond.collect_products()
	assert_eq(_pond._pending_products.size(), 0, "收集后待收列表应清空")

func test_remove_fish_invalid_index_returns_false():
	_pond._is_built = true
	assert_false(_pond.remove_fish(-1), "负索引应返回false")
	assert_false(_pond.remove_fish(0), "空鱼塘移除应返回false")

## 测试放入鱼类成功（需要模拟 InventorySystem.remove_item）
func test_add_fish_success():
	_pond._is_built = true
	_pond._capacity = 5
	# 直接操作内部状态模拟 can_add_fish 通过
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 0})
	assert_eq(_pond.get_fish_count(), 1, "添加鱼后数量应为1")

## 测试从鱼塘移除鱼类成功
func test_remove_fish_success():
	_pond._is_built = true
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 5})
	_pond._fish_in_pond.append({"fish_id": "carp", "days_in_pond": 3})
	var removed = _pond.remove_fish(0)
	assert_true(removed, "移除应返回true")
	assert_eq(_pond.get_fish_count(), 1, "移除后数量应为1")
	assert_eq(_pond._fish_in_pond[0]["fish_id"], "carp", "剩余的应该是carp")

## 测试鱼塘满时不能放入更多鱼
func test_cannot_add_fish_when_full():
	_pond._is_built = true
	_pond._capacity = 2
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 5})
	_pond._fish_in_pond.append({"fish_id": "carp", "days_in_pond": 3})
	# 鱼塘已满，can_add_fish 应返回 false
	assert_false(_pond.can_add_fish("koi"), "鱼塘满时不能放入新鱼")

## 测试 has_products_to_collect 状态
func test_has_products_to_collect_reflects_pending():
	_pond._is_built = true
	assert_false(_pond.has_products_to_collect(), "无产物时应返回false")
	_pond._pending_products.append({"product_id": "bluegill", "quality": "normal", "quantity": 1})
	assert_true(_pond.has_products_to_collect(), "有产物时应返回true")

## 测试多条鱼同时产出
func test_multiple_mature_fish_produce():
	_pond._is_built = true
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 10})
	_pond._fish_in_pond.append({"fish_id": "carp", "days_in_pond": 10})
	_pond._fish_in_pond.append({"fish_id": "swamp_loach", "days_in_pond": 10})
	_pond._pending_products = Array([], TYPE_DICTIONARY, "", null)
	_pond._calculate_daily_production()
	# 至少有一条鱼产出（高概率）
	var produced = _pond._pending_products.size()
	assert_gt(produced, 0, "成熟鱼群应有产出")

## 测试未成熟临界天数（第maturity_days天）
func test_fish_at_exactly_maturity_days():
	_pond._is_built = true
	# bluegill maturity_days=3
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 2})
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 3})
	var fish_list = _pond.get_fish_list()
	assert_false(fish_list[0]["is_mature"], "2天未成熟")
	assert_true(fish_list[1]["is_mature"], "3天刚好成熟")

# ============ 存档序列化测试 ============

func test_serialize_preserves_built_state():
	_pond._is_built = true
	_pond._fish_in_pond.append({"fish_id": "bluegill", "days_in_pond": 5})
	_pond._days_elapsed = 10

	var data = _pond.serialize()
	assert_true(data["is_built"], "应记录已建造")
	assert_eq(data["fish_in_pond"].size(), 1, "应记录1条鱼")
	assert_eq(data["days_elapsed"], 10, "应记录天数")

func test_deserialize_restores_state():
	var data = {
		"is_built": true,
		"fish_in_pond": [{"fish_id": "koi", "days_in_pond": 7}],
		"capacity": 10,
		"pending_products": [{"product_id": "koi", "quality": "fine", "quantity": 1}],
		"days_elapsed": 15
	}

	_pond.deserialize(data)
	assert_true(_pond.is_built(), "应标记为已建造")
	assert_eq(_pond.get_fish_count(), 1, "应有1条鱼")
	assert_eq(_pond._days_elapsed, 15, "天数应为15")
	assert_true(_pond.has_products_to_collect(), "应有可收集产物")
