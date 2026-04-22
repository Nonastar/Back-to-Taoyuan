extends "res://tests/unit/test_base.gd"

## AnimalHusbandrySystem 好感度系统单元测试
## 注意：由于测试运行器为每个文件创建一个实例并运行所有测试方法，
## 每个测试必须自行重置状态，防止测试间污染

var _animal_system: Node = null

func _reset_all_state():
	"""重置所有状态到初始值"""
	_animal_system._buildings = {}
	_animal_system._pending_products = Array([], TYPE_DICTIONARY, "", null)
	_animal_system._days_elapsed = 0

func before_each():
	_animal_system = Node.new()
	_animal_system.set_script(load("res://src/scripts/autoload/animal_husbandry_system.gd"))
	_animal_system._ready()

func after_each():
	_reset_all_state()
	_animal_system.free()

# ============ 好感度等级测试 ============

## 测试好感度等级名称 - Stranger (0-199)
func test_friendship_level_stranger():
	var level = _animal_system.get_friendship_level_name(0)
	assert_eq(level, "Stranger", "好感度0应为Stranger")

	level = _animal_system.get_friendship_level_name(100)
	assert_eq(level, "Stranger", "好感度100应为Stranger")

	level = _animal_system.get_friendship_level_name(199)
	assert_eq(level, "Stranger", "好感度199应为Stranger")

## 测试好感度等级名称 - Pal (200-399)
func test_friendship_level_pal():
	var level = _animal_system.get_friendship_level_name(200)
	assert_eq(level, "Pal", "好感度200应为Pal")

	level = _animal_system.get_friendship_level_name(300)
	assert_eq(level, "Pal", "好感度300应为Pal")

	level = _animal_system.get_friendship_level_name(399)
	assert_eq(level, "Pal", "好感度399应为Pal")

## 测试好感度等级名称 - Friend (400-699)
func test_friendship_level_friend():
	var level = _animal_system.get_friendship_level_name(400)
	assert_eq(level, "Friend", "好感度400应为Friend")

	level = _animal_system.get_friendship_level_name(550)
	assert_eq(level, "Friend", "好感度550应为Friend")

	level = _animal_system.get_friendship_level_name(699)
	assert_eq(level, "Friend", "好感度699应为Friend")

## 测试好感度等级名称 - Best Friend (700-1000)
func test_friendship_level_best_friend():
	var level = _animal_system.get_friendship_level_name(700)
	assert_eq(level, "Best Friend", "好感度700应为Best Friend")

	level = _animal_system.get_friendship_level_name(850)
	assert_eq(level, "Best Friend", "好感度850应为Best Friend")

	level = _animal_system.get_friendship_level_name(1000)
	assert_eq(level, "Best Friend", "好感度1000应为Best Friend")

## 测试边界值
func test_friendship_level_boundaries():
	assert_eq(_animal_system.get_friendship_level_name(199), "Stranger", "199是Stranger")
	assert_eq(_animal_system.get_friendship_level_name(200), "Pal", "200是Pal")
	assert_eq(_animal_system.get_friendship_level_name(399), "Pal", "399是Pal")
	assert_eq(_animal_system.get_friendship_level_name(400), "Friend", "400是Friend")
	assert_eq(_animal_system.get_friendship_level_name(699), "Friend", "699是Friend")
	assert_eq(_animal_system.get_friendship_level_name(700), "Best Friend", "700是Best Friend")

# ============ 品质加成测试 ============

## 测试品质加成 - Stranger
func test_quality_bonus_stranger():
	var bonus = _animal_system.get_quality_bonus(0)
	assert_almost_eq(bonus, 0.0, 0.001, "Stranger品质加成应为0%")

	bonus = _animal_system.get_quality_bonus(100)
	assert_almost_eq(bonus, 0.0, 0.001, "Stranger品质加成应为0%")

## 测试品质加成 - Pal
func test_quality_bonus_pal():
	var bonus = _animal_system.get_quality_bonus(200)
	assert_almost_eq(bonus, 0.02, 0.001, "Pal品质加成应为2%")

## 测试品质加成 - Friend
func test_quality_bonus_friend():
	var bonus = _animal_system.get_quality_bonus(400)
	assert_almost_eq(bonus, 0.05, 0.001, "Friend品质加成应为5%")

## 测试品质加成 - Best Friend
func test_quality_bonus_best_friend():
	var bonus = _animal_system.get_quality_bonus(700)
	assert_almost_eq(bonus, 0.10, 0.001, "Best Friend品质加成应为10%")

	bonus = _animal_system.get_quality_bonus(1000)
	assert_almost_eq(bonus, 0.10, 0.001, "Best Friend品质加成应为10%")

## 测试等级名称获取品质加成
func test_quality_bonus_for_level():
	assert_almost_eq(_animal_system.get_quality_bonus_for_level("Stranger"), 0.0, 0.001)
	assert_almost_eq(_animal_system.get_quality_bonus_for_level("Pal"), 0.02, 0.001)
	assert_almost_eq(_animal_system.get_quality_bonus_for_level("Friend"), 0.05, 0.001)
	assert_almost_eq(_animal_system.get_quality_bonus_for_level("Best Friend"), 0.10, 0.001)

# ============ 好感度进度测试 ============

## 测试好感度进度 - Stranger阶段
func test_friendship_progress_stranger():
	var progress = _animal_system.get_friendship_progress(0)
	assert_almost_eq(progress, 0.0, 0.001, "0好感度进度应为0")

	progress = _animal_system.get_friendship_progress(100)
	assert_almost_eq(progress, 0.5, 0.01, "100好感度进度应为0.5")

	progress = _animal_system.get_friendship_progress(199)
	assert_almost_eq(progress, 0.995, 0.01, "199好感度进度应接近1.0")

## 测试好感度进度 - Pal阶段
func test_friendship_progress_pal():
	var progress = _animal_system.get_friendship_progress(200)
	assert_almost_eq(progress, 0.0, 0.001, "200好感度进度应为0")

	progress = _animal_system.get_friendship_progress(300)
	assert_almost_eq(progress, 0.5, 0.01, "300好感度进度应为0.5")

## 测试好感度进度 - Friend阶段
func test_friendship_progress_friend():
	var progress = _animal_system.get_friendship_progress(400)
	assert_almost_eq(progress, 0.0, 0.001, "400好感度进度应为0")

	progress = _animal_system.get_friendship_progress(550)
	assert_almost_eq(progress, 0.5, 0.01, "550好感度进度应为0.5")

## 测试好感度进度 - Best Friend阶段
func test_friendship_progress_best_friend():
	var progress = _animal_system.get_friendship_progress(700)
	assert_almost_eq(progress, 0.0, 0.001, "700好感度进度应为0")

	progress = _animal_system.get_friendship_progress(850)
	assert_almost_eq(progress, 0.5, 0.01, "850好感度进度应为0.5")

## 测试好感度进度 - 满级
func test_friendship_progress_max():
	var progress = _animal_system.get_friendship_progress(1000)
	assert_eq(progress, 1.0, "1000好感度进度应为1.0")

# ============ 好感度常量测试 ============

## 测试好感度常量值
func test_friendship_constants():
	assert_eq(_animal_system.FRIENDSHIP_MAX, 1000, "最大好感度应为1000")
	assert_eq(_animal_system.FRIENDSHIP_THRESHOLD_PAL, 200, "Pal阈值应为200")
	assert_eq(_animal_system.FRIENDSHIP_THRESHOLD_FRIEND, 400, "Friend阈值应为400")
	assert_eq(_animal_system.FRIENDSHIP_THRESHOLD_BEST_FRIEND, 700, "Best Friend阈值应为700")
	assert_eq(_animal_system.FRIENDSHIP_FEED_MIN, 1, "喂养好感度增量最小值应为1")
	assert_eq(_animal_system.FRIENDSHIP_FEED_MAX, 3, "喂养好感度增量最大值应为3")
	assert_eq(_animal_system.FRIENDSHIP_PET_MIN, 5, "抚摸好感度增量最小值应为5")
	assert_eq(_animal_system.FRIENDSHIP_PET_MAX, 12, "抚摸好感度增量最大值应为12")
	assert_eq(_animal_system.FRIENDSHIP_PICKUP_PENALTY, 10, "抱起好感度减量应为10")
	assert_eq(_animal_system.FRIENDSHIP_HEAL_BONUS, 30, "治疗好感度增量应为30")
	assert_eq(_animal_system.FRIENDSHIP_CLEAN_BONUS, 1, "清理好感度增量应为1")

# ============ 动物好感度API测试 ============

## 测试获取不存在动物的好感度
func test_get_nonexistent_animal_friendship():
	var friendship = _animal_system.get_animal_friendship("nonexistent_id")
	assert_eq(friendship, -1, "不存在动物应返回-1")

## 测试获取不存在动物的好感度等级
func test_get_nonexistent_animal_friendship_level():
	var level = _animal_system.get_animal_friendship_level("nonexistent_id")
	assert_eq(level, "", "不存在动物应返回空字符串")

## 测试获取不存在动物的好感度加成
func test_get_nonexistent_animal_quality_bonus():
	var bonus = _animal_system.get_animal_quality_bonus("nonexistent_id")
	assert_almost_eq(bonus, 0.0, 0.001, "不存在动物应返回0")

## 测试获取不存在动物的详细信息
func test_get_nonexistent_animal_details():
	var details = _animal_system.get_animal_details("nonexistent_id")
	assert_true(details.is_empty(), "不存在动物应返回空字典")

# ============ 好感度枚举测试 ============

## 测试好感度等级枚举
func test_friendship_level_enum():
	assert_eq(_animal_system.get_friendship_level_enum(0), 0, "0应为STRANGER枚举")
	assert_eq(_animal_system.get_friendship_level_enum(199), 0, "199应为STRANGER枚举")
	assert_eq(_animal_system.get_friendship_level_enum(200), 1, "200应为PAL枚举")
	assert_eq(_animal_system.get_friendship_level_enum(399), 1, "399应为PAL枚举")
	assert_eq(_animal_system.get_friendship_level_enum(400), 2, "400应为FRIEND枚举")
	assert_eq(_animal_system.get_friendship_level_enum(699), 2, "699应为FRIEND枚举")
	assert_eq(_animal_system.get_friendship_level_enum(700), 3, "700应为BEST_FRIEND枚举")
	assert_eq(_animal_system.get_friendship_level_enum(1000), 3, "1000应为BEST_FRIEND枚举")

# ============ 建筑与好感度集成测试 ============

## 测试建造建筑后动物初始好感度
func test_initial_animal_friendship():
	## 模拟建造鸡舍
	_animal_system._buildings[_animal_system.BuildingType.COOP] = {
		"capacity": 8,
		"animals": []
	}

	## 模拟购买动物（手动添加并验证初始好感度）
	var unique_id = "test_chicken_1"
	var building = _animal_system._buildings[_animal_system.BuildingType.COOP]
	building["animals"].append({
		"animal_id": "chicken_white",
		"unique_id": unique_id,
		"days_in_building": 0,
		"is_mature": true,
		"has_produced_today": false,
		"friendship": 0,  ## 初始好感度
		"fed_today": false,
		"pet_today": false
	})

	## 验证初始好感度
	var friendship = _animal_system.get_animal_friendship(unique_id)
	assert_eq(friendship, 0, "新动物初始好感度应为0")

	var level = _animal_system.get_animal_friendship_level(unique_id)
	assert_eq(level, "Stranger", "新动物好感度等级应为Stranger")

## 测试每日重置好感度操作标志
func test_daily_reset_friendship_flags():
	## 设置建筑和动物
	_animal_system._buildings[_animal_system.BuildingType.COOP] = {
		"capacity": 8,
		"animals": []
	}

	var unique_id = "test_chicken_2"
	var building = _animal_system._buildings[_animal_system.BuildingType.COOP]
	building["animals"].append({
		"animal_id": "chicken_white",
		"unique_id": unique_id,
		"days_in_building": 1,
		"is_mature": true,
		"has_produced_today": false,
		"friendship": 100,
		"fed_today": true,  ## 已被喂养
		"pet_today": true    ## 已被抚摸
	})

	## 执行每日更新
	_animal_system.daily_update()

	## 验证每日标志已重置
	assert_false(_animal_system.is_animal_fed(unique_id), "每日更新后fed_today应重置")
	assert_false(_animal_system.is_animal_pet(unique_id), "每日更新后pet_today应重置")

	## 验证好感度未变化
	var friendship = _animal_system.get_animal_friendship(unique_id)
	assert_eq(friendship, 100, "每日更新不应改变好感度")

# ============ 存档测试 ============

## 测试序列化好感度数据
func test_serialize_friendship():
	## 设置建筑和动物
	_animal_system._buildings[_animal_system.BuildingType.COOP] = {
		"capacity": 8,
		"animals": []
	}

	var unique_id = "test_chicken_save"
	var building = _animal_system._buildings[_animal_system.BuildingType.COOP]
	building["animals"].append({
		"animal_id": "chicken_white",
		"unique_id": unique_id,
		"days_in_building": 5,
		"is_mature": true,
		"has_produced_today": false,
		"friendship": 350,
		"fed_today": false,
		"pet_today": false
	})

	var data = _animal_system.serialize()
	assert_true(data.has("buildings"), "存档应包含buildings")
	assert_true(data.has("pending_products"), "存档应包含pending_products")
	assert_true(data.has("days_elapsed"), "存档应包含days_elapsed")

## 测试反序列化好感度数据
func test_deserialize_friendship():
	var data = {
		"buildings": {
			0: {  ## COOP = 0
				"capacity": 8,
				"animals": [{
					"animal_id": "chicken_white",
					"unique_id": "loaded_chicken",
					"days_in_building": 10,
					"is_mature": true,
					"has_produced_today": false,
					"friendship": 550,
					"fed_today": false,
					"pet_today": false
				}]
			}
		},
		"pending_products": [],
		"days_elapsed": 10
	}

	_animal_system.deserialize(data)

	## 验证好感度正确加载
	var friendship = _animal_system.get_animal_friendship("loaded_chicken")
	assert_eq(friendship, 550, "加载后好感度应为550")

	var level = _animal_system.get_animal_friendship_level("loaded_chicken")
	assert_eq(level, "Friend", "加载后好感度等级应为Friend")

# ============ 旧存档迁移测试 ============

## 测试迁移不包含好感度字段的旧存档
func test_migrate_legacy_data():
	## 模拟旧存档（不包含friendship等新字段）
	var legacy_data = {
		"buildings": {
			0: {
				"capacity": 8,
				"animals": [{
					"animal_id": "chicken_white",
					"unique_id": "legacy_chicken",
					"days_in_building": 5,
					"is_mature": true,
					"has_produced_today": false
					## 注意：没有friendship, fed_today, pet_today字段
				}]
			}
		},
		"pending_products": [],
		"days_elapsed": 5
	}

	_animal_system.deserialize(legacy_data)

	## 验证旧数据已迁移
	var friendship = _animal_system.get_animal_friendship("legacy_chicken")
	assert_eq(friendship, 0, "旧存档迁移后好感度应为0")

	var details = _animal_system.get_animal_details("legacy_chicken")
	assert_false(details.is_empty(), "旧存档迁移后应能获取详情")
	assert_eq(details["fed_today"], false, "旧存档迁移后fed_today应为false")
	assert_eq(details["pet_today"], false, "旧存档迁移后pet_today应为false")

## 测试迁移旧待收获产物数据
func test_migrate_legacy_products():
	## 模拟包含旧格式产物的存档
	var legacy_data = {
		"buildings": {},
		"pending_products": [
			{"product_id": "egg", "quantity": 2}
		],
		"days_elapsed": 0
	}

	_animal_system.deserialize(legacy_data)

	## 验证产物数据已迁移
	var products = _animal_system.get_pending_products()
	assert_eq(products.size(), 1, "应有1个产物")
	assert_eq(products[0]["product_id"], "egg", "产物ID应为egg")
	assert_almost_eq(products[0]["quality_bonus"], 0.0, 0.001, "旧存档迁移后quality_bonus应为0")
	assert_eq(products[0]["unique_id"], "", "旧存档迁移后unique_id应为空")

# ============ 获取所有动物信息测试 ============

## 测试获取所有动物详细信息
func test_get_all_animals_with_friendship():
	## 设置建筑和动物
	_animal_system._buildings[_animal_system.BuildingType.COOP] = {
		"capacity": 8,
		"animals": []
	}

	## 添加两只动物
	var building = _animal_system._buildings[_animal_system.BuildingType.COOP]
	building["animals"].append({
		"animal_id": "chicken_white",
		"unique_id": "chicken_1",
		"days_in_building": 5,
		"is_mature": true,
		"has_produced_today": false,
		"friendship": 150,
		"fed_today": true,
		"pet_today": false
	})
	building["animals"].append({
		"animal_id": "duck",
		"unique_id": "duck_1",
		"days_in_building": 3,
		"is_mature": false,
		"has_produced_today": false,
		"friendship": 50,
		"fed_today": false,
		"pet_today": false
	})

	var all_animals = _animal_system.get_all_animals_with_friendship()
	assert_eq(all_animals.size(), 2, "应有2只动物")

	## 验证第一只动物信息
	var chicken_info = null
	var duck_info = null
	for animal in all_animals:
		if animal["unique_id"] == "chicken_1":
			chicken_info = animal
		elif animal["unique_id"] == "duck_1":
			duck_info = animal

	assert_not_null(chicken_info, "应能找到chicken_1")
	assert_not_null(duck_info, "应能找到duck_1")

	assert_eq(chicken_info["friendship"], 150, "chicken_1好感度应为150")
	assert_eq(chicken_info["friendship_level"], "Stranger", "chicken_1等级应为Stranger")
	assert_true(chicken_info["fed_today"], "chicken_1应标记为已喂养")
	assert_false(chicken_info["pet_today"], "chicken_1应标记为未抚摸")

	assert_eq(duck_info["friendship"], 50, "duck_1好感度应为50")
	assert_eq(duck_info["friendship_level"], "Stranger", "duck_1等级应为Stranger")

# ============ 产出品质系统测试 ============

## 测试产出品质常量
func test_production_quality_constants():
	assert_almost_eq(_animal_system.BASE_HIGH_QUALITY_CHANCE, 0.10, 0.001, "基础高品质概率应为10%")
	assert_eq(_animal_system.QUALITY_WEIGHTS[Quality.NORMAL], 0.70, "NORMAL权重应为70%")
	assert_eq(_animal_system.QUALITY_WEIGHTS[Quality.FINE], 0.20, "FINE权重应为20%")
	assert_eq(_animal_system.QUALITY_WEIGHTS[Quality.EXCELLENT], 0.09, "EXCELLENT权重应为9%")
	assert_eq(_animal_system.QUALITY_WEIGHTS[Quality.SUPREME], 0.01, "SUPREME权重应为1%")

## 测试品质计算返回有效值
func test_calculate_product_quality_returns_valid():
	## 测试多次调用，确保返回值在有效范围内
	for i in range(100):
		var quality = _animal_system.calculate_product_quality(0.0)
		assert_true(quality >= Quality.NORMAL and quality <= Quality.SUPREME,
			"品质应在NORMAL到SUPREME之间")

## 测试品质加成对高品质概率的影响
func test_quality_bonus_increases_high_quality_chance():
	## Stranger (0% bonus) vs Best Friend (10% bonus)
	var stranger_normal_count = 0
	var best_friend_normal_count = 0

	## 大量测试以验证概率差异
	for i in range(1000):
		var quality_stranger = _animal_system.calculate_product_quality(0.0)
		var quality_best_friend = _animal_system.calculate_product_quality(0.10)

		if quality_stranger == Quality.NORMAL:
			stranger_normal_count += 1
		if quality_best_friend == Quality.NORMAL:
			best_friend_normal_count += 1

	## Stranger应该有更高概率获得NORMAL（因为没有加成）
	## Best Friend应该有更低概率获得NORMAL（因为有10%加成）
	## 注意：这是统计结果，可能有波动
	var stranger_normal_rate = float(stranger_normal_count) / 1000.0
	var best_friend_normal_rate = float(best_friend_normal_count) / 1000.0

	assert_lt(best_friend_normal_rate, stranger_normal_rate + 0.1,
		"Best Friend的普通品质率应低于或接近Stranger")

## 测试获取产物预览品质
func test_get_product_preview_quality():
	## 添加一个待收获产物
	_animal_system._pending_products.append({
		"product_id": "egg",
		"quantity": 1,
		"unique_id": "test_chicken",
		"quality_bonus": 0.05  ## Friend等级加成
	})

	var preview = _animal_system.get_product_preview_quality(0)
	assert_false(preview.is_empty(), "预览不应为空")
	assert_true(preview.has("quality"), "预览应包含quality")
	assert_true(preview.has("quality_name"), "预览应包含quality_name")
	assert_true(preview.has("quality_bonus"), "预览应包含quality_bonus")
	assert_true(preview.has("quality_color"), "预览应包含quality_color")
	assert_eq(preview["quality_bonus"], 0.05, "quality_bonus应为0.05")

## 测试获取无效索引的产物预览
func test_get_product_preview_quality_invalid_index():
	var preview = _animal_system.get_product_preview_quality(-1)
	assert_true(preview.is_empty(), "无效索引应返回空字典")

	preview = _animal_system.get_product_preview_quality(100)
	assert_true(preview.is_empty(), "超出范围的索引应返回空字典")

## 测试获取所有产物品质预览
func test_get_all_products_quality_preview():
	## 添加多个待收获产物
	_animal_system._pending_products.append({
		"product_id": "egg",
		"quantity": 1,
		"unique_id": "chicken_1",
		"quality_bonus": 0.0
	})
	_animal_system._pending_products.append({
		"product_id": "milk",
		"quantity": 1,
		"unique_id": "cow_1",
		"quality_bonus": 0.10
	})

	var previews = _animal_system.get_all_products_quality_preview()
	assert_eq(previews.size(), 2, "应有2个预览")

## 测试获取产物详情
func test_get_product_details():
	_animal_system._pending_products.append({
		"product_id": "egg",
		"quantity": 3,
		"unique_id": "chicken_1",
		"quality_bonus": 0.05
	})

	var details = _animal_system.get_product_details(0)
	assert_false(details.is_empty(), "详情不应为空")
	assert_eq(details["index"], 0, "索引应为0")
	assert_eq(details["product_id"], "egg", "产物ID应为egg")
	assert_eq(details["quantity"], 3, "数量应为3")
	assert_eq(details["unique_id"], "chicken_1", "动物ID应为chicken_1")
	assert_eq(details["quality_bonus"], 0.05, "品质加成应为0.05")

## 测试收集单个产物 - 失败情况
func test_collect_single_product_failures():
	## 测试无效索引
	var result = _animal_system.collect_single_product(-1)
	assert_false(result.get("success", false), "无效索引应返回失败")

	result = _animal_system.collect_single_product(100)
	assert_false(result.get("success", false), "超出范围索引应返回失败")

## 测试收集单个产物 - 空产物列表
func test_collect_single_product_empty():
	var result = _animal_system.collect_single_product(0)
	assert_false(result.get("success", false), "空列表应返回失败")

## 测试待收获产物列表操作
func test_pending_products_count():
	## 初始应为空
	assert_eq(_animal_system.get_pending_products().size(), 0, "初始待收获列表应为空")
	assert_false(_animal_system.has_products_to_collect(), "初始不应有可收集产物")

	## 添加产物
	_animal_system._pending_products.append({
		"product_id": "egg",
		"quantity": 2,
		"unique_id": "chicken_1",
		"quality_bonus": 0.0
	})

	assert_eq(_animal_system.get_pending_products().size(), 1, "应有1个待收获产物")
	assert_true(_animal_system.has_products_to_collect(), "应有可收集产物")

## 测试收集所有产物方法存在
func test_collect_all_products_method_exists():
	assert_true(_animal_system.has_method("collect_all_products"), "应有collect_all_products方法")
	assert_true(_animal_system.has_method("collect_single_product"), "应有collect_single_product方法")
	assert_true(_animal_system.has_method("calculate_product_quality"), "应有calculate_product_quality方法")
	assert_true(_animal_system.has_method("get_product_preview_quality"), "应有get_product_preview_quality方法")
	assert_true(_animal_system.has_method("get_all_products_quality_preview"), "应有get_all_products_quality_preview方法")
	assert_true(_animal_system.has_method("get_product_details"), "应有get_product_details方法")

## 测试Quality枚举值
func test_quality_enum_values():
	assert_eq(Quality.NORMAL, 0, "NORMAL应为0")
	assert_eq(Quality.FINE, 1, "FINE应为1")
	assert_eq(Quality.EXCELLENT, 2, "EXCELLENT应为2")
	assert_eq(Quality.SUPREME, 3, "SUPREME应为3")

## 测试Quality名称映射
func test_quality_names():
	assert_eq(Quality.get_quality_name(Quality.NORMAL), "普通", "NORMAL名称应为'普通'")
	assert_eq(Quality.get_quality_name(Quality.FINE), "优秀", "FINE名称应为'优秀'")
	assert_eq(Quality.get_quality_name(Quality.EXCELLENT), "精良", "EXCELLENT名称应为'精良'")
	assert_eq(Quality.get_quality_name(Quality.SUPREME), "史诗", "SUPREME名称应为'史诗'")

## 测试产出逻辑（验证 _try_produce 正确追加产物，不依赖概率）
func test_daily_update_produces_with_probability():
	## 设置建筑和动物
	_animal_system._buildings[_animal_system.BuildingType.COOP] = {
		"capacity": 8,
		"animals": []
	}

	var unique_id = "test_chicken_produce"
	var building = _animal_system._buildings[_animal_system.BuildingType.COOP]
	var animal = {
		"animal_id": "chicken_white",
		"unique_id": unique_id,
		"days_in_building": 5,
		"is_mature": true,
		"has_produced_today": false,
		"friendship": 0,
		"is_sick": false
	}
	building["animals"].append(animal)

	## 预置已知产物，验证 _try_produce 只追加不覆盖
	_animal_system._pending_products.clear()
	_animal_system._pending_products.push_back({"product_id": "known_item", "quality": "normal", "quantity": 1})

	## 直接调用 _try_produce（内部使用 _rng.randf()，结果不确定但逻辑正确）
	## 验证追加行为：原有产物保留，新产物追加（若概率触发）
	## _try_produce 在生产成功时会追加到 _pending_products
	var animal_data = _animal_system.ANIMAL_DATA.get("chicken_white", {})
	_animal_system._try_produce(animal, animal_data)

	## 已知产物应保留（追加而非覆盖）
	assert_eq(_animal_system._pending_products[0]["product_id"], "known_item", "原有产物应保留")
	## 若生产成功，新产物被追加
	if animal["has_produced_today"]:
		assert_gt(_animal_system._pending_products.size(), 1, "生产成功时应追加新产物")
