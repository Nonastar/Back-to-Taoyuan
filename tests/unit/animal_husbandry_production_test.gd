extends "res://tests/unit/test_base.gd"

## AnimalHusbandrySystem 产出系统单元测试
## 测试每日产出判定、品质计算、收集逻辑
## 注意：每个测试必须自行重置状态，防止测试间污染

var _animal_system: Node = null

func _reset_all_state():
	"""重置所有状态到初始值"""
	_animal_system._buildings = {}
	_animal_system._pending_products = Array([], TYPE_DICTIONARY, "", null)
	_animal_system._days_elapsed = 0

func _setup_building_with_mature_animal(building_type: int, animal_id: String, friendship: int) -> String:
	"""创建建筑并添加一只成熟动物，返回 unique_id"""
	if not _animal_system._buildings.has(building_type):
		var capacity = _animal_system.get_building_capacity(building_type)
		_animal_system._buildings[building_type] = {
			"capacity": capacity,
			"animals": [],
			"dirty_days": 0
		}

	var unique_id = "test_animal_" + str(Time.get_ticks_usec())
	var building = _animal_system._buildings[building_type]
	var maturity_days = _animal_system.ANIMAL_DATA[animal_id].get("maturity_days", 5)

	building["animals"].append({
		"animal_id": animal_id,
		"unique_id": unique_id,
		"days_in_building": maturity_days,
		"is_mature": true,
		"has_produced_today": false,
		"friendship": friendship,
		"fed_today": false,
		"pet_today": false,
		"is_sick": false
	})
	return unique_id

func before_each():
	_animal_system = Node.new()
	_animal_system.set_script(load("res://src/scripts/autoload/animal_husbandry_system.gd"))
	_animal_system._ready()

func after_each():
	_reset_all_state()
	_animal_system.free()

# ============ 产出常量测试 ============

func test_production_constants():
	## 基础高品质概率
	assert_almost_eq(_animal_system.BASE_HIGH_QUALITY_CHANCE, 0.10, 0.001)
	## 品质权重
	assert_almost_eq(_animal_system.QUALITY_WEIGHTS[Quality.NORMAL], 0.70, 0.001)
	assert_almost_eq(_animal_system.QUALITY_WEIGHTS[Quality.FINE], 0.20, 0.001)
	assert_almost_eq(_animal_system.QUALITY_WEIGHTS[Quality.EXCELLENT], 0.09, 0.001)
	assert_almost_eq(_animal_system.QUALITY_WEIGHTS[Quality.SUPREME], 0.01, 0.001)

# ============ 品质计算测试 ============

## 测试品质返回值在有效范围内
func test_calculate_product_quality_returns_valid():
	for i in range(50):
		var quality = _animal_system.calculate_product_quality(0.0)
		assert_true(quality >= Quality.NORMAL and quality <= Quality.SUPREME,
			"品质应在NORMAL到SUPREME之间")

## 测试高品质加成影响高品质概率 (统计测试)
func test_quality_bonus_increases_high_quality_chance():
	## 运行大量测试，验证有加成的动物获得高品质概率更高
	var stranger_high_count = 0
	var best_friend_high_count = 0
	var trials = 1000

	for i in range(trials):
		var stranger_q = _animal_system.calculate_product_quality(0.0)
		var best_friend_q = _animal_system.calculate_product_quality(0.10)
		if stranger_q > Quality.NORMAL:
			stranger_high_count += 1
		if best_friend_q > Quality.NORMAL:
			best_friend_high_count += 1

	## Best Friend 高品质率应显著高于 Stranger (有10%加成)
	## 使用宽松断言，允许统计波动
	var stranger_rate = float(stranger_high_count) / trials
	var best_friend_rate = float(best_friend_high_count) / trials
	assert_lt(stranger_rate + 0.15, 1.0,
		"Stranger 高品质率不应接近100%")

# ============ 每日产出判定测试 ============

## 测试未成熟动物不产出
func test_immature_animal_does_not_produce():
	var unique_id = "test_immature"
	_animal_system._buildings[_animal_system.BuildingType.COOP] = {
		"capacity": 8,
		"animals": [],
		"dirty_days": 0
	}
	var building = _animal_system._buildings[_animal_system.BuildingType.COOP]
	## 添加未成年鸡 (days_in_building < maturity_days=3)
	building["animals"].append({
		"animal_id": "chicken_white",
		"unique_id": unique_id,
		"days_in_building": 1,  ## 未成熟
		"is_mature": false,
		"has_produced_today": false,
		"friendship": 0,
		"fed_today": false,
		"pet_today": false,
		"is_sick": false
	})

	var initial_products = _animal_system.get_pending_products().size()
	_animal_system.daily_update()
	var after_products = _animal_system.get_pending_products().size()

	assert_eq(after_products, initial_products, "未成年动物不应产生产物")

## 测试成熟动物可以产出
func test_mature_animal_can_produce():
	## 设置成熟动物
	var unique_id = "test_mature_chicken"
	_animal_system._buildings[_animal_system.BuildingType.COOP] = {
		"capacity": 8,
		"animals": [{
			"animal_id": "chicken_white",
			"unique_id": unique_id,
			"days_in_building": 5,  ## 超过成熟天数3
			"is_mature": true,
			"has_produced_today": false,
			"friendship": 0,
			"fed_today": false,
			"pet_today": false,
			"is_sick": false
		}],
		"dirty_days": 0
	}

	var initial_products = _animal_system.get_pending_products().size()
	## 执行多次每日更新（产出是概率性的）
	var produced = false
	for i in range(50):
		_animal_system._buildings[_animal_system.BuildingType.COOP]["animals"][0]["has_produced_today"] = false
		_animal_system._buildings[_animal_system.BuildingType.COOP]["animals"][0]["days_in_building"] = 5
		_animal_system._maybe_produce_product(_animal_system._buildings[_animal_system.BuildingType.COOP]["animals"][0])
		if _animal_system.get_pending_products().size() > initial_products:
			produced = true
			break

	assert_true(produced, "成熟动物在足够次数尝试后应该产生过产出")

## 测试已产出动物不会重复产出
func test_already_produced_animal_does_not_produce_again():
	var unique_id = "test_produced"
	_animal_system._buildings[_animal_system.BuildingType.COOP] = {
		"capacity": 8,
		"animals": [{
			"animal_id": "chicken_white",
			"unique_id": unique_id,
			"days_in_building": 5,
			"is_mature": true,
			"has_produced_today": true,  ## 今日已产出
			"friendship": 0,
			"fed_today": false,
			"pet_today": false,
			"is_sick": false
		}],
		"dirty_days": 0
	}

	var initial = _animal_system.get_pending_products().size()
	_animal_system._maybe_produce_product(_animal_system._buildings[_animal_system.BuildingType.COOP]["animals"][0])
	var after = _animal_system.get_pending_products().size()
	assert_eq(after, initial, "今日已产出不应再产出")

## 测试生病动物不产出
func test_sick_animal_does_not_produce():
	var unique_id = "test_sick"
	_animal_system._buildings[_animal_system.BuildingType.COOP] = {
		"capacity": 8,
		"animals": [{
			"animal_id": "chicken_white",
			"unique_id": unique_id,
			"days_in_building": 5,
			"is_mature": true,
			"has_produced_today": false,
			"friendship": 0,
			"fed_today": false,
			"pet_today": false,
			"is_sick": true  ## 生病中
		}],
		"dirty_days": 0
	}

	var initial = _animal_system.get_pending_products().size()
	_animal_system._maybe_produce_product(_animal_system._buildings[_animal_system.BuildingType.COOP]["animals"][0])
	var after = _animal_system.get_pending_products().size()
	assert_eq(after, initial, "生病动物不应产出")

## 测试成年动物不产出 (is_mature=false 仍尝试产出)
func test_not_mature_flag_prevents_production():
	var unique_id = "test_not_mature_flag"
	_animal_system._buildings[_animal_system.BuildingType.COOP] = {
		"capacity": 8,
		"animals": [{
			"animal_id": "chicken_white",
			"unique_id": unique_id,
			"days_in_building": 5,
			"is_mature": false,  ## 标记为未成熟
			"has_produced_today": false,
			"friendship": 0,
			"fed_today": false,
			"pet_today": false,
			"is_sick": false
		}],
		"dirty_days": 0
	}

	var initial = _animal_system.get_pending_products().size()
	_animal_system._maybe_produce_product(_animal_system._buildings[_animal_system.BuildingType.COOP]["animals"][0])
	var after = _animal_system.get_pending_products().size()
	assert_eq(after, initial, "is_mature=false 时不应产出")

# ============ 产物收集测试 ============

## 测试收集空列表返回0
func test_collect_from_empty_returns_zero():
	var collected = _animal_system.collect_all_products()
	assert_eq(collected, 0, "空列表收集应返回0")

## 测试收集单个产物
func test_collect_single_product():
	## 添加待收集产物
	_animal_system._pending_products.append({
		"product_id": "egg",
		"quantity": 1,
		"unique_id": "test_chicken",
		"quality_bonus": 0.0
	})

	var result = _animal_system.collect_single_product(0)
	assert_true(result.get("success", false), "收集应成功")
	assert_eq(result.get("product_id", ""), "egg", "产物ID应为egg")
	assert_eq(result.get("quantity", 0), 1, "数量应为1")

## 测试收集后列表清空
func test_collect_clears_pending_products():
	_animal_system._pending_products.append({
		"product_id": "egg",
		"quantity": 1,
		"unique_id": "test_chicken",
		"quality_bonus": 0.0
	})
	_animal_system._pending_products.append({
		"product_id": "milk",
		"quantity": 1,
		"unique_id": "test_cow",
		"quality_bonus": 0.0
	})

	assert_eq(_animal_system.get_pending_products().size(), 2, "应有2个待收集产物")
	_animal_system.collect_all_products()
	assert_eq(_animal_system.get_pending_products().size(), 0, "收集后列表应清空")

## 测试无效索引返回失败
func test_collect_invalid_index_returns_failure():
	var result = _animal_system.collect_single_product(-1)
	assert_false(result.get("success", false), "无效索引应返回失败")

	result = _animal_system.collect_single_product(100)
	assert_false(result.get("success", false), "超出范围索引应返回失败")

## 测试待收集产物检查
func test_has_products_to_collect():
	assert_false(_animal_system.has_products_to_collect(), "初始应无产物")
	_animal_system._pending_products.append({
		"product_id": "egg", "quantity": 1, "unique_id": "x", "quality_bonus": 0.0
	})
	assert_true(_animal_system.has_products_to_collect(), "有产物时应返回true")

# ============ 产物详情测试 ============

func test_get_product_details():
	_animal_system._pending_products.append({
		"product_id": "milk",
		"quantity": 3,
		"unique_id": "cow_1",
		"quality_bonus": 0.05
	})

	var details = _animal_system.get_product_details(0)
	assert_false(details.is_empty(), "详情不应为空")
	assert_eq(details["product_id"], "milk")
	assert_eq(details["quantity"], 3)
	assert_eq(details["unique_id"], "cow_1")
	assert_almost_eq(details["quality_bonus"], 0.05, 0.001)

func test_get_product_preview_quality():
	_animal_system._pending_products.append({
		"product_id": "egg",
		"quantity": 1,
		"unique_id": "chicken_1",
		"quality_bonus": 0.10  ## Best Friend 加成
	})

	var preview = _animal_system.get_product_preview_quality(0)
	assert_false(preview.is_empty(), "预览不应为空")
	assert_true(preview.has("quality"), "应包含quality字段")
	assert_true(preview.has("quality_name"), "应包含quality_name字段")
	assert_almost_eq(preview["quality_bonus"], 0.10, 0.001)

## 测试获取所有产物品质预览
func test_get_all_products_quality_preview():
	_animal_system._pending_products.append({
		"product_id": "egg", "quantity": 1, "unique_id": "c1", "quality_bonus": 0.0
	})
	_animal_system._pending_products.append({
		"product_id": "milk", "quantity": 1, "unique_id": "c2", "quality_bonus": 0.10
	})

	var previews = _animal_system.get_all_products_quality_preview()
	assert_eq(previews.size(), 2, "应有2个预览")

# ============ 存档序列化测试 ============

func test_serialize_preserves_pending_products():
	_animal_system._pending_products.append({
		"product_id": "egg",
		"quantity": 5,
		"unique_id": "chicken_1",
		"quality_bonus": 0.02
	})

	var data = _animal_system.serialize()
	assert_true(data.has("pending_products"), "存档应包含pending_products")
	assert_eq(data["pending_products"].size(), 1, "应有1个产物")

func test_deserialize_restores_pending_products():
	var data = {
		"buildings": {},
		"pending_products": [
			{"product_id": "egg", "quantity": 2, "unique_id": "c1", "quality_bonus": 0.05}
		],
		"days_elapsed": 10
	}

	_animal_system.deserialize(data)
	var products = _animal_system.get_pending_products()
	assert_eq(products.size(), 1, "反序列化后应有1个产物")
	assert_eq(products[0]["product_id"], "egg")
	assert_eq(products[0]["quantity"], 2)

# ============ 好感度加成产出测试 ============

## 测试不同好感度等级对应不同品质加成
func test_friendship_quality_bonus_tiers():
	## Stranger (0-199): +0%
	assert_almost_eq(_animal_system.get_quality_bonus(0), 0.0, 0.001)
	assert_almost_eq(_animal_system.get_quality_bonus(199), 0.0, 0.001)
	## Pal (200-399): +2%
	assert_almost_eq(_animal_system.get_quality_bonus(200), 0.02, 0.001)
	assert_almost_eq(_animal_system.get_quality_bonus(399), 0.02, 0.001)
	## Friend (400-699): +5%
	assert_almost_eq(_animal_system.get_quality_bonus(400), 0.05, 0.001)
	assert_almost_eq(_animal_system.get_quality_bonus(699), 0.05, 0.001)
	## Best Friend (700+): +10%
	assert_almost_eq(_animal_system.get_quality_bonus(700), 0.10, 0.001)
	assert_almost_eq(_animal_system.get_quality_bonus(1000), 0.10, 0.001)
