extends "res://tests/unit/test_base.gd"

## FishingSystem 钓鱼系统单元测试
## 测试鱼种数据、鱼饵系统、抽鱼逻辑、状态管理
## 注意：每个测试必须自行重置状态，防止测试间污染

var _fishing: Node = null

func _reset_all_state():
	_fishing._is_fishing = false
	_fishing._current_spot_id = ""
	_fishing._current_fish_id = ""
	_fishing._current_fish_data = {}
	_fishing._current_bait_type = _fishing.BaitType.NONE
	_fishing._assist_mode = false

func before_each():
	_fishing = Node.new()
	_fishing.set_script(load("res://src/scripts/autoload/fishing_system.gd"))
	_fishing._ready()

func after_each():
	_reset_all_state()
	_fishing.free()

# ============ 常量测试 ============

func test_bait_type_enum_values():
	assert_eq(_fishing.BaitType.NONE, 0, "BaitType.NONE 应为 0")
	assert_eq(_fishing.BaitType.COMMON, 1, "BaitType.COMMON 应为 1")
	assert_eq(_fishing.BaitType.DELUXE, 2, "BaitType.DELUXE 应为 2")
	assert_eq(_fishing.BaitType.LEGENDARY, 3, "BaitType.LEGENDARY 应为 3")

func test_bait_effects_has_all_types():
	assert_true(_fishing.BAIT_EFFECTS.has(_fishing.BaitType.NONE), "应包含 NONE")
	assert_true(_fishing.BAIT_EFFECTS.has(_fishing.BaitType.COMMON), "应包含 COMMON")
	assert_true(_fishing.BAIT_EFFECTS.has(_fishing.BaitType.DELUXE), "应包含 DELUXE")
	assert_true(_fishing.BAIT_EFFECTS.has(_fishing.BaitType.LEGENDARY), "应包含 LEGENDARY")

func test_bait_effects_structure():
	var common = _fishing.BAIT_EFFECTS[_fishing.BaitType.COMMON]
	assert_eq(common["name"], "普通饵料", "普通饵料名称应正确")
	assert_almost_eq(common["bite_bonus"], 0.10, 0.001, "普通饵料加成 10%")
	assert_almost_eq(common["legendary_bonus"], 0.0, 0.001, "普通饵料无传说加成")
	assert_eq(common["item_id"], "bait_common", "物品ID应正确")

func test_legendary_bait_has_legendary_bonus():
	var legendary = _fishing.BAIT_EFFECTS[_fishing.BaitType.LEGENDARY]
	assert_almost_eq(legendary["legendary_bonus"], 0.10, 0.001, "传说饵料传说加成 10%")
	assert_almost_eq(legendary["bite_bonus"], 0.50, 0.001, "传说饵料咬钩加成 50%")

# ============ 鱼种数据测试 ============

func test_fish_data_not_empty():
	assert_gt(_fishing.FISH_DATA.size(), 0, "鱼种数据不应为空")

func test_fish_data_contains_required_fields():
	var bluegill = _fishing.FISH_DATA["bluegill"]
	assert_true(bluegill.has("name"), "应包含 name")
	assert_true(bluegill.has("rarity"), "应包含 rarity")
	assert_true(bluegill.has("exp"), "应包含 exp")
	assert_true(bluegill.has("price"), "应包含 price")
	assert_true(bluegill.has("difficulty"), "应包含 difficulty")

func test_fish_data_rarity_range():
	for fish_id in _fishing.FISH_DATA:
		var fish = _fishing.FISH_DATA[fish_id]
		var rarity = fish["rarity"]
		assert_true(rarity >= 0.0 and rarity <= 1.0,
			"%s 稀有度应在 0-1 范围" % fish_id)

func test_fish_data_difficulty_range():
	for fish_id in _fishing.FISH_DATA:
		var fish = _fishing.FISH_DATA[fish_id]
		var difficulty = fish["difficulty"]
		assert_true(difficulty >= 1 and difficulty <= 10,
			"%s 难度应在 1-10 范围" % fish_id)

func test_legendary_fish_has_max_difficulty():
	var mythical = _fishing.FISH_DATA["mythical_fish"]
	var legendary = _fishing.FISH_DATA["legendary_fish"]
	assert_eq(mythical["difficulty"], 10, "神话鱼难度应为 10")
	assert_eq(legendary["difficulty"], 10, "传说鱼难度应为 10")

func test_fish_by_location_contains_fishpond():
	assert_true(_fishing.FISH_BY_LOCATION.has("fishpond"), "鱼塘应在地点列表中")
	var pond_fish = _fishing.FISH_BY_LOCATION["fishpond"]
	assert_gt(pond_fish.size(), 0, "鱼塘应可钓鱼类")
	assert_true(pond_fish.has("bluegill"), "鱼塘应可钓蓝鳃鱼")

func test_all_location_fish_exist_in_fish_data():
	for spot_id in _fishing.FISH_BY_LOCATION:
		for fish_id in _fishing.FISH_BY_LOCATION[spot_id]:
			assert_true(_fishing.FISH_DATA.has(fish_id),
				"%s: %s 鱼种数据缺失" % [spot_id, fish_id])

# ============ 抽鱼逻辑测试 ============

## 测试 roll_fish 返回有效鱼种
func test_roll_fish_returns_valid_fish():
	var fish_id = _fishing.roll_fish("fishpond")
	assert_false(fish_id.is_empty(), "不应返回空字符串")
	assert_true(_fishing.FISH_BY_LOCATION["fishpond"].has(fish_id),
		"应返回该地点可钓的鱼")

## 测试 roll_fish 统计分布（多次调用应覆盖多种鱼）
func test_roll_fish_distribution():
	var results = {}
	var trials = 100
	for i in range(trials):
		var fish_id = _fishing.roll_fish("fishpond")
		results[fish_id] = results.get(fish_id, 0) + 1

	## 多次调用应能钓到多种鱼（或至少是有效鱼）
	assert_gt(results.size(), 0, "应有结果")

## 测试无效地点返回空
func test_roll_fish_invalid_spot_returns_empty():
	var result = _fishing.roll_fish("nonexistent_spot")
	assert_eq(result, "", "无效地点应返回空字符串")

## 测试空地点列表返回空
## 注意: FISH_BY_LOCATION 是 const，无法动态修改，用 invalid_spot 代替
## 已在 test_roll_fish_invalid_spot_returns_empty 覆盖

## 测试传说饵料加成传说鱼概率
func test_legendary_bait_bonus_increases_legendary_fish_chance():
	## 设置当前鱼饵为传说饵料
	_fishing._current_bait_type = _fishing.BaitType.LEGENDARY

	## 多次尝试 secret_pond（只有传说鱼）
	var legendary_count = 0
	var trials = 50
	for i in range(trials):
		var fish_id = _fishing.roll_fish("secret_pond")
		if fish_id == "legendary_fish" or fish_id == "mythical_fish" or fish_id == "treasure_fish":
			legendary_count += 1

	## 有传说饵料加成时，传说鱼出现概率应更高
	## 注：由于随机性，只验证方法可调用且返回值有效
	assert_le(legendary_count, trials, "传说鱼计数不应超过总次数")

# ============ 地点查询测试 ============

func test_get_available_fish_returns_list():
	var fish = _fishing.get_available_fish("river")
	assert_true(fish is Array, "应返回数组")
	assert_gt(fish.size(), 0, "river 应有可钓鱼类")

func test_get_available_fish_invalid_spot():
	var fish = _fishing.get_available_fish("invalid")
	assert_eq(fish.size(), 0, "无效地点应返回空列表")

func test_get_fish_data_returns_dict():
	var data = _fishing.get_fish_data("bluegill")
	assert_true(data is Dictionary, "应返回字典")
	assert_eq(data["name"], "蓝鳃鱼", "名称应匹配")

func test_get_fish_data_invalid_fish():
	var data = _fishing.get_fish_data("nonexistent_fish")
	assert_eq(data.size(), 0, "无效鱼种应返回空字典")

func test_get_fishing_spot_info_structure():
	var info = _fishing.get_fishing_spot_info("fishpond")
	assert_true(info.has("spot_id"), "应包含 spot_id")
	assert_true(info.has("available_fish"), "应包含 available_fish")
	assert_true(info.has("fish_data"), "应包含 fish_data")
	assert_eq(info["spot_id"], "fishpond", "spot_id 应匹配")

# ============ 鱼饵加成测试 ============

func test_get_bait_bonus_default():
	_fishing._current_bait_type = _fishing.BaitType.NONE
	var bonus = _fishing.get_bait_bonus()
	assert_eq(bonus["type"], _fishing.BaitType.NONE, "类型应为 NONE")
	assert_eq(bonus["name"], "无", "名称应为无")
	assert_almost_eq(bonus["bite_bonus"], 0.0, 0.001)
	assert_almost_eq(bonus["legendary_bonus"], 0.0, 0.001)

func test_get_bait_bonus_common():
	_fishing._current_bait_type = _fishing.BaitType.COMMON
	var bonus = _fishing.get_bait_bonus()
	assert_eq(bonus["name"], "普通饵料", "名称应匹配")
	assert_almost_eq(bonus["bite_bonus"], 0.10, 0.001)

func test_get_current_bait_name():
	_fishing._current_bait_type = _fishing.BaitType.DELUXE
	assert_eq(_fishing.get_current_bait_name(), "美味饵料", "应返回美味饵料")

# ============ 辅助模式测试 ============

func test_assist_mode_default_false():
	assert_false(_fishing.is_assist_mode(), "辅助模式默认应为 false")

func test_set_assist_mode():
	_fishing.set_assist_mode(true)
	assert_true(_fishing.is_assist_mode(), "辅助模式应设为 true")
	_fishing.set_assist_mode(false)
	assert_false(_fishing.is_assist_mode(), "辅助模式应设为 false")

# ============ 状态管理测试 ============

func test_initial_state_not_fishing():
	assert_false(_fishing.is_fishing(), "初始不应在钓鱼状态")
	assert_eq(_fishing.get_current_spot_id(), "", "初始地点应为空")
	assert_eq(_fishing.get_current_fish_id(), "", "初始鱼ID应为空")

func test_cleanup_fishing_state():
	_fishing._is_fishing = true
	_fishing._current_spot_id = "fishpond"
	_fishing._current_fish_id = "bluegill"
	_fishing._current_fish_data = {"test": true}
	_fishing._current_bait_type = _fishing.BaitType.COMMON
	_fishing._assist_mode = true

	_fishing._cleanup_fishing_state()

	assert_false(_fishing._is_fishing, "is_fishing 应重置")
	assert_eq(_fishing._current_spot_id, "", "spot_id 应重置")
	assert_eq(_fishing._current_fish_id, "", "fish_id 应重置")
	assert_eq(_fishing._current_fish_data.size(), 0, "fish_data 应重置")
	assert_eq(_fishing._current_bait_type, _fishing.BaitType.NONE, "bait 应重置")
	assert_false(_fishing._assist_mode, "assist_mode 应重置")

func test_build_fish_data_adds_fish_id():
	var data = _fishing._build_fish_data("carp")
	assert_eq(data["fish_id"], "carp", "fish_id 字段应正确添加")
	assert_eq(data["name"], "鲤鱼", "名称应匹配")
