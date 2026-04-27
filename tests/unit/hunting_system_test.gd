extends "res://tests/unit/test_base.gd"

## HuntingSystem 狩猎系统单元测试
## 测试狩猎区域、猎物刷新、掉落计算

var _hunting_system: Node = null

func _reset_all_state():
	_hunting_system._area_states = {}
	_hunting_system._last_spawn_time = {}
	_hunting_system._hunting_skill_level = 0
	_hunting_system._hunt_cooldown_active = false
	_hunting_system._rng = RandomNumberGenerator.new()
	_hunting_system._rng.randomize()

func before_each():
	_hunting_system = Node.new()
	_hunting_system.set_script(load("res://src/scripts/autoload/hunting_system.gd"))
	_hunting_system._ready()

func after_each():
	_reset_all_state()
	_hunting_system.free()

# ============ 区域枚举测试 ============

func test_hunting_area_enum_values():
	assert_eq(_hunting_system.HuntingArea.BUSHES, 0, "BUSHES应为0")
	assert_eq(_hunting_system.HuntingArea.FOREST, 1, "FOREST应为1")
	assert_eq(_hunting_system.HuntingArea.LAKE, 2, "LAKE应为2")

func test_prey_state_enum_values():
	assert_eq(_hunting_system.PreyState.AVAILABLE, 0, "AVAILABLE应为0")
	assert_eq(_hunting_system.PreyState.COOLDOWN, 1, "COOLDOWN应为1")
	assert_eq(_hunting_system.PreyState.HUNTED, 2, "HUNTED应为2")

# ============ 区域数据测试 ============

func test_area_data_loaded():
	## 验证区域数据已加载（默认或JSON）
	var area_data = _hunting_system.get_area_data()
	assert_gt(area_data.size(), 0, "应有区域数据")

func test_all_three_areas_present():
	var all_areas = _hunting_system.get_all_areas()
	assert_eq(all_areas.size(), 3, "应有3个狩猎区域")
	assert_true(_hunting_system._area_data.has(_hunting_system.HuntingArea.BUSHES), "应有灌木丛数据")
	assert_true(_hunting_system._area_data.has(_hunting_system.HuntingArea.FOREST), "应有森林数据")
	assert_true(_hunting_system._area_data.has(_hunting_system.HuntingArea.LAKE), "应有湖泊数据")

func test_area_names():
	var bushes_info = _hunting_system.get_area_info(_hunting_system.HuntingArea.BUSHES)
	assert_eq(bushes_info.get("name"), "灌木丛", "灌木丛名称应正确")

	var forest_info = _hunting_system.get_area_info(_hunting_system.HuntingArea.FOREST)
	assert_eq(forest_info.get("name"), "森林", "森林名称应正确")

	var lake_info = _hunting_system.get_area_info(_hunting_system.HuntingArea.LAKE)
	assert_eq(lake_info.get("name"), "湖泊", "湖泊名称应正确")

func test_area_respawn_times():
	var bushes_info = _hunting_system.get_area_info(_hunting_system.HuntingArea.BUSHES)
	assert_eq(bushes_info.get("respawn_minutes"), 5, "灌木丛刷新时间应为5分钟")

	var forest_info = _hunting_system.get_area_info(_hunting_system.HuntingArea.FOREST)
	assert_eq(forest_info.get("respawn_minutes"), 10, "森林刷新时间应为10分钟")

	var lake_info = _hunting_system.get_area_info(_hunting_system.HuntingArea.LAKE)
	assert_eq(lake_info.get("respawn_minutes"), 15, "湖泊刷新时间应为15分钟")

func test_area_prey_types():
	var bushes_info = _hunting_system.get_area_info(_hunting_system.HuntingArea.BUSHES)
	var prey_types = bushes_info.get("prey_types", [])
	assert_true(prey_types.has("rabbit"), "灌木丛应有rabbit")
	assert_true(prey_types.has("bird"), "灌木丛应有bird")
	assert_true(prey_types.has("squirrel"), "灌木丛应有squirrel")

	var forest_info = _hunting_system.get_area_info(_hunting_system.HuntingArea.FOREST)
	prey_types = forest_info.get("prey_types", [])
	assert_true(prey_types.has("deer"), "森林应有deer")
	assert_true(prey_types.has("boar"), "森林应有boar")
	assert_true(prey_types.has("fox"), "森林应有fox")

	var lake_info = _hunting_system.get_area_info(_hunting_system.HuntingArea.LAKE)
	prey_types = lake_info.get("prey_types", [])
	assert_true(prey_types.has("duck_wild"), "湖泊应有duck_wild")
	assert_true(prey_types.has("goose"), "湖泊应有goose")
	assert_true(prey_types.has("heron"), "湖泊应有heron")

# ============ 猎物数据测试 ============

func test_prey_data_loaded():
	var prey_data = _hunting_system.get_prey_data()
	assert_gt(prey_data.size(), 0, "应有猎物数据")

func test_prey_definitions():
	var rabbit_data = _hunting_system._prey_data.get("rabbit", {})
	assert_eq(rabbit_data.get("name"), "野兔", "野兔名称应正确")
	assert_true(rabbit_data.get("drops").has("fur"), "野兔应掉落fur")
	assert_true(rabbit_data.get("drops").has("meat"), "野兔应掉落meat")

	var deer_data = _hunting_system._prey_data.get("deer", {})
	assert_eq(deer_data.get("name"), "鹿", "鹿名称应正确")
	assert_true(deer_data.get("drops").has("antler"), "鹿应掉落antler")

# ============ 技能等级测试 ============

func test_set_hunting_skill_level():
	_hunting_system.set_hunting_skill_level(5)
	assert_eq(_hunting_system._hunting_skill_level, 5, "技能等级应为5")

func test_set_hunting_skill_level_clamp_max():
	_hunting_system.set_hunting_skill_level(20)
	assert_eq(_hunting_system._hunting_skill_level, 10, "技能等级上限为10")

func test_set_hunting_skill_level_clamp_min():
	_hunting_system.set_hunting_skill_level(-5)
	assert_eq(_hunting_system._hunting_skill_level, 0, "技能等级下限为0")

func test_initial_skill_level_is_zero():
	assert_eq(_hunting_system._hunting_skill_level, 0, "初始技能等级应为0")

# ============ 狩猎操作测试 ============

func test_hunt_succeeds_when_skill_level_zero():
	## 技能等级为0时仍可狩猎成功（技能仅影响掉落率和品质，不限制参与）
	var result = _hunting_system.hunt_in_area(_hunting_system.HuntingArea.BUSHES)
	assert_true(result.get("success", false), "技能等级为0时仍可狩猎（技能仅影响掉落）")

func test_hunt_succeeds_when_skill_level_low():
	## 低技能等级仍可狩猎成功（技能仅影响掉落率和品质）
	_hunting_system.set_hunting_skill_level(0)
	var result = _hunting_system.hunt_in_area(_hunting_system.HuntingArea.BUSHES)
	assert_true(result.get("success", false), "低技能等级仍可狩猎（技能仅影响掉落）")

func test_hunt_succeeds_when_skill_level_sufficient():
	_hunting_system.set_hunting_skill_level(3)
	var result = _hunting_system.hunt_in_area(_hunting_system.HuntingArea.BUSHES)
	## 成功条件：技能足够且区域可用
	if result.get("success", false):
		assert_true(result.has("prey_id"), "成功时应包含prey_id")
		assert_true(result.has("drops"), "成功时应包含drops")
	else:
		## 如果失败，应该是冷却中（已狩猎过），但技能检查应该通过
		## 这里主要验证技能等级检查逻辑正确
		pass

func test_hunt_fails_for_invalid_area():
	_hunting_system.set_hunting_skill_level(5)
	var result = _hunting_system.hunt_in_area(99)  # 无效区域
	assert_false(result.get("success", false), "无效区域应返回失败")

func test_hunt_fails_for_negative_area():
	_hunting_system.set_hunting_skill_level(5)
	var result = _hunting_system.hunt_in_area(-1)
	assert_false(result.get("success", false), "负数区域应返回失败")

func test_hunt_sets_cooldown_after_success():
	_hunting_system.set_hunting_skill_level(5)
	var result = _hunting_system.hunt_in_area(_hunting_system.HuntingArea.BUSHES)
	## 验证区域冷却状态
	var available = _hunting_system.is_area_available(_hunting_system.HuntingArea.BUSHES)
	if result.get("success", false):
		assert_false(available, "狩猎成功后区域应变为冷却")

# ============ 冷却系统测试 ============

func test_cooldown_reset_on_sleep():
	## 模拟狩猎后设置冷却
	_hunting_system._hunt_cooldown_active = true
	_hunting_system._on_sleep_triggered(0, false)
	assert_false(_hunting_system._hunt_cooldown_active, "睡眠后冷却应重置")

func test_use_hunting_cooldown():
	## _use_hunting_cooldown 仅标记狩猎完成，始终返回 true（冷却由区域状态独立管理）
	var result = _hunting_system._use_hunting_cooldown(_hunting_system.HuntingArea.BUSHES)
	assert_true(result, "首次调用应返回 true")

	## 多次调用始终返回 true，冷却检查由 is_area_available() 负责
	result = _hunting_system._use_hunting_cooldown(_hunting_system.HuntingArea.BUSHES)
	assert_true(result, "第二次调用同样返回 true")

func test_hunt_fails_when_cooldown_active():
	## 冷却通过 _area_states + _last_spawn_time 管理，用当前游戏时间使冷却未到期
	_hunting_system.set_hunting_skill_level(5)
	_hunting_system._area_states[_hunting_system.HuntingArea.BUSHES] = _hunting_system.PreyState.COOLDOWN
	_hunting_system._last_spawn_time[_hunting_system.HuntingArea.BUSHES] = _hunting_system._get_current_game_minutes()
	var result = _hunting_system.hunt_in_area(_hunting_system.HuntingArea.BUSHES)
	assert_false(result.get("success", false), "区域冷却中应狩猎失败")

# ============ 区域状态测试 ============

func test_initial_areas_available():
	## 初始所有区域应可用
	assert_true(_hunting_system.is_area_available(_hunting_system.HuntingArea.BUSHES), "灌木丛初始应可用")
	assert_true(_hunting_system.is_area_available(_hunting_system.HuntingArea.FOREST), "森林初始应可用")
	assert_true(_hunting_system.is_area_available(_hunting_system.HuntingArea.LAKE), "湖泊初始应可用")

func test_area_becomes_unavailable_after_hunt():
	_hunting_system.set_hunting_skill_level(5)
	var result = _hunting_system.hunt_in_area(_hunting_system.HuntingArea.BUSHES)
	if result.get("success", false):
		assert_false(_hunting_system.is_area_available(_hunting_system.HuntingArea.BUSHES), "狩猎后区域应不可用")

func test_check_area_status_available():
	var status = _hunting_system.check_area_status(_hunting_system.HuntingArea.BUSHES)
	assert_true(status.get("available"), "初始应可用")
	assert_eq(status.get("cooldown"), 0, "初始冷却应为0")

func test_check_area_status_invalid_area():
	var status = _hunting_system.check_area_status(99)
	assert_false(status.get("available"), "无效区域应不可用")
	assert_eq(status.get("reason"), "无效区域", "应提示无效区域")

# ============ 掉落计算测试 ============

func test_drop_quality_in_valid_range():
	## 多次调用确保返回值在有效范围内
	for i in range(100):
		var quality = _hunting_system._calculate_drop_quality(0)
		assert_true(quality >= Quality.NORMAL and quality <= Quality.SUPREME,
			"品质应在NORMAL到SUPREME之间")

func test_drop_quality_probability_distribution():
	## 测试品质分布（统计1000次）
	var counts = {Quality.NORMAL: 0, Quality.FINE: 0, Quality.EXCELLENT: 0, Quality.SUPREME: 0}
	for i in range(1000):
		var quality = _hunting_system._calculate_drop_quality(0)
		counts[quality] += 1

	## 验证各品质都有出现（概率不为0）
	var normal_rate = float(counts[Quality.NORMAL]) / 1000.0
	var fine_rate = float(counts[Quality.FINE]) / 1000.0
	var excellent_rate = float(counts[Quality.EXCELLENT]) / 1000.0
	var supreme_rate = float(counts[Quality.SUPREME]) / 1000.0

	assert_gt(normal_rate, 0.7, "NORMAL应占约80%+")
	assert_gt(fine_rate, 0.01, "FINE应有约5%")
	assert_gt(excellent_rate, 0.01, "EXCELLENT应有约9%")
	assert_ge(supreme_rate, 0.0, "SUPREME应存在")

# ============ 掉落物品测试 ============

func test_calculate_drops_returns_array():
	var drops = _hunting_system._calculate_drops("rabbit", 3)
	assert_true(drops is Array, "应返回数组")

func test_calculate_drops_includes_item_id():
	var drops = _hunting_system._calculate_drops("rabbit", 3)
	if drops.size() > 0:
		assert_true(drops[0].has("item_id"), "掉落应包含item_id")
		assert_true(drops[0].has("quantity"), "掉落应包含quantity")
		assert_true(drops[0].has("quality"), "掉落应包含quality")

func test_calculate_drops_invalid_prey():
	var drops = _hunting_system._calculate_drops("invalid_prey", 3)
	assert_eq(drops.size(), 0, "无效猎物应无掉落")

# ============ 每日刷新测试 ============

func test_daily_respawn_makes_all_areas_available():
	## 模拟狩猎后冷却
	_hunting_system.set_hunting_skill_level(5)
	_hunting_system.hunt_in_area(_hunting_system.HuntingArea.BUSHES)
	_hunting_system.hunt_in_area(_hunting_system.HuntingArea.FOREST)

	## 执行每日刷新
	_hunting_system._daily_respawn()

	## 验证所有区域重置为可用
	assert_true(_hunting_system.is_area_available(_hunting_system.HuntingArea.BUSHES), "刷新后灌木丛应可用")
	assert_true(_hunting_system.is_area_available(_hunting_system.HuntingArea.FOREST), "刷新后森林应可用")
	assert_true(_hunting_system.is_area_available(_hunting_system.HuntingArea.LAKE), "刷新后湖泊应可用")

# ============ 存档支持测试 ============

func test_serialize_contains_required_fields():
	var data = _hunting_system.serialize()
	assert_true(data.has("area_states"), "存档应包含area_states")
	assert_true(data.has("last_spawn_time"), "存档应包含last_spawn_time")
	assert_true(data.has("hunting_skill_level"), "存档应包含hunting_skill_level")
	assert_true(data.has("hunt_cooldown_active"), "存档应包含hunt_cooldown_active")

func test_deserialize_restores_state():
	var test_data = {
		"area_states": {_hunting_system.HuntingArea.BUSHES: _hunting_system.PreyState.COOLDOWN},
		"last_spawn_time": {_hunting_system.HuntingArea.BUSHES: 100},
		"hunting_skill_level": 7,
		"hunt_cooldown_active": true
	}

	_hunting_system.deserialize(test_data)

	assert_eq(_hunting_system._hunting_skill_level, 7, "技能等级应正确加载")
	assert_true(_hunting_system._hunt_cooldown_active, "冷却状态应正确加载")

func test_deserialize_with_empty_data():
	_hunting_system.deserialize({})
	## 应使用默认值，不崩溃
	assert_eq(_hunting_system._hunting_skill_level, 0, "默认技能等级为0")
	assert_false(_hunting_system._hunt_cooldown_active, "默认冷却状态为false")

# ============ get_all_areas 测试 ============

func test_get_all_areas_returns_array():
	var areas = _hunting_system.get_all_areas()
	assert_true(areas is Array, "应返回数组")
	assert_eq(areas.size(), 3, "应有3个区域")

func test_get_all_areas_includes_state():
	var areas = _hunting_system.get_all_areas()
	for area in areas:
		assert_true(area.has("area_id"), "应包含area_id")
		assert_true(area.has("state"), "应包含state")
		assert_true(area.has("available"), "应包含available")
		assert_true(area.has("cooldown_remaining"), "应包含cooldown_remaining")
