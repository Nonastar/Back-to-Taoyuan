extends "res://tests/unit/test_base.gd"

## AchievementSystem 单元测试
## 测试成就解锁、物品发现、条件评估、完美度计算、存档序列化

var _system: Node = null

func _reset_all_state():
	_system._achievement_states.clear()
	_system._discovered_items.clear()
	_system._stats = {
		"total_crops_harvested": 0,
		"total_fish_caught": 0,
		"total_money_earned": 0,
		"highest_mine_floor": 0,
		"total_recipes_cooked": 0,
		"total_quests_completed": 0,
		"total_monsters_killed": 0,
		"total_breedings_done": 0
	}
	_system._pending_achievements.clear()
	_system._perfection_cache = -1.0
	_system._init_achievement_states()

func before_each():
	_system = Node.new()
	_system.set_script(load("res://src/scripts/autoload/achievement_system.gd"))
	_system._ready()

func after_each():
	_reset_all_state()
	_system.free()

# ============ 初始化测试 ============

func test_achievement_count_loaded():
	# Arrange & Act
	var total = _system.get_total_count()

	# Assert
	assert_gt(total, 50, "应至少有50个成就")

func test_all_achievements_initially_locked():
	# Arrange & Act
	var completed = _system.get_completed_count()

	# Assert
	assert_eq(completed, 0, "所有成就初始应为未解锁")

func test_achievement_has_required_fields():
	# Arrange & Act
	var all_ach = _system.get_all_achievements()

	# Assert
	assert_gt(all_ach.size(), 0, "应有成就数据")
	for ach in all_ach:
		assert_dict_has_key(ach, "id", "成就需有id")
		assert_dict_has_key(ach, "name", "成就需有name")
		assert_dict_has_key(ach, "category", "成就需有category")
		assert_dict_has_key(ach, "state", "成就需有state")

# ============ 物品发现测试 ============

func test_discover_item_adds_to_collection():
	# Arrange
	_system.discover_item("test_item_1")

	# Act
	var discovered = _system.get_discovered_count()
	var is_discovered = _system.is_item_discovered("test_item_1")

	# Assert
	assert_eq(discovered, 1, "应发现1件物品")
	assert_true(is_discovered, "物品应被标记为已发现")

func test_discover_duplicate_item_no_change():
	# Arrange
	_system.discover_item("test_item")
	var count_before = _system.get_discovered_count()

	# Act
	_system.discover_item("test_item")

	# Assert
	assert_eq(_system.get_discovered_count(), count_before, "重复发现不应增加计数")

func test_discover_empty_item_ignored():
	# Arrange
	_system.discover_item("")

	# Act
	var count = _system.get_discovered_count()

	# Assert
	assert_eq(count, 0, "空物品ID不应被记录")

func test_discover_multiple_items():
	# Arrange
	_system.discover_item("item_a")
	_system.discover_item("item_b")
	_system.discover_item("item_c")

	# Act
	var count = _system.get_discovered_count()
	var items = _system.get_discovered_items()

	# Assert
	assert_eq(count, 3, "应发现3件物品")
	assert_eq(items.size(), 3, "物品列表应有3项")

# ============ 条件评估测试 ============

func test_item_count_condition_evaluates():
	# Arrange - 发现足够物品触发 col_5 (需要5件)
	for i in range(5):
		_system.discover_item("item_%d" % i)

	# Act
	_system.evaluate_achievements()

	# Assert
	var state = _system.get_achievement_state("col_5")
	assert_eq(state, _system.AchievementState.COMPLETED, "col_5应被完成")

func test_crop_harvest_condition_accumulates():
	# Arrange
	_system._stats.total_crops_harvested = 10

	# Act
	_system.evaluate_achievements()

	# Assert
	var state = _system.get_achievement_state("farm_10")
	assert_eq(state, _system.AchievementState.COMPLETED, "farm_10应被完成")

func test_fish_caught_condition():
	# Arrange
	_system._stats.total_fish_caught = 5

	# Act
	_system.evaluate_achievements()

	# Assert
	assert_eq(_system.get_achievement_state("fish_5"), _system.AchievementState.COMPLETED)

func test_mine_floor_condition():
	# Arrange
	_system._stats.highest_mine_floor = 15

	# Act
	_system.evaluate_achievements()

	# Assert
	assert_eq(_system.get_achievement_state("mine_15"), _system.AchievementState.COMPLETED)

func test_money_earned_condition():
	# Arrange
	_system._stats.total_money_earned = 10000

	# Act
	_system.evaluate_achievements()

	# Assert
	assert_eq(_system.get_achievement_state("money_10k"), _system.AchievementState.COMPLETED)

func test_recipes_cooked_condition():
	# Arrange
	_system._stats.total_recipes_cooked = 10

	# Act
	_system.evaluate_achievements()

	# Assert
	assert_eq(_system.get_achievement_state("cook_10"), _system.AchievementState.COMPLETED)

func test_quests_completed_condition():
	# Arrange
	_system._stats.total_quests_completed = 10

	# Act
	_system.evaluate_achievements()

	# Assert
	assert_eq(_system.get_achievement_state("quest_10"), _system.AchievementState.COMPLETED)

# ============ 成就进度测试 ============

func test_achievement_progress_zero_initially():
	# Arrange & Act
	var progress = _system.get_achievement_progress()

	# Assert
	assert_almost_eq(progress, 0.0, 0.01, "初始进度应为0%")

func test_achievement_state_tracking():
	# Arrange
	_system._stats.total_crops_harvested = 100
	_system.evaluate_achievements()

	# Act
	var state = _system.get_achievement_state("farm_100")

	# Assert
	assert_eq(state, _system.AchievementState.COMPLETED)

func test_get_achievement_returns_full_data():
	# Arrange
	_system._stats.total_crops_harvested = 10
	_system.evaluate_achievements()

	# Act
	var ach = _system.get_achievement("farm_10")

	# Assert
	assert_eq(ach.get("state"), _system.AchievementState.COMPLETED)
	assert_eq(ach.get("id"), "farm_10")

func test_get_nonexistent_achievement_returns_empty():
	# Act
	var ach = _system.get_achievement("does_not_exist")

	# Assert
	assert_eq(ach.size(), 0, "不存在的成就应返回空字典")

# ============ 分类过滤测试 ============

func test_get_achievements_by_category():
	# Arrange
	_system._stats.total_crops_harvested = 10
	_system.evaluate_achievements()

	# Act
	var farming_achs = _system.get_achievements_by_category("farming")

	# Assert
	assert_gt(farming_achs.size(), 1, "农耕分类应有多个成就")
	for ach in farming_achs:
		assert_eq(ach.get("category"), "farming", "过滤结果应全为农耕分类")

func test_get_achievements_by_nonexistent_category():
	# Act
	var result = _system.get_achievements_by_category("nonexistent")

	# Assert
	assert_eq(result.size(), 0, "不存在的分类应返回空数组")

# ============ 完美度测试（功能门控） ============

func test_perfection_gated_by_flag():
	# Arrange
	_system._stats.total_crops_harvested = 5000  # 大量数据

	# Act
	var pct = _system.get_perfection_percent()

	# Assert
	assert_eq(pct, 0.0, "FEATURE_PERFECTION_ENABLED=false时应返回0")

# ============ 存档序列化测试 ============

func test_serialize_deserialize_roundtrip():
	# Arrange
	_system.discover_item("diamond")
	_system._stats.total_crops_harvested = 50
	_system._stats.total_money_earned = 50000
	_system.evaluate_achievements()

	var data = _system.serialize()

	# Act - 创建新实例并加载
	var sys2 = Node.new()
	sys2.set_script(load("res://src/scripts/autoload/achievement_system.gd"))
	sys2._ready()
	sys2.deserialize(data)

	# Assert
	assert_eq(sys2.get_discovered_count(), _system.get_discovered_count(), "发现物品数应一致")
	assert_eq(sys2.get_completed_count(), _system.get_completed_count(), "完成成就数应一致")

	sys2.free()

func test_deserialize_empty_data_keeps_defaults():
	# Act
	_system.deserialize({})

	# Assert
	assert_eq(_system.get_completed_count(), 0, "空数据不改变状态")
	assert_eq(_system.get_discovered_count(), 0, "空数据不改变发现数")

# ============ 调试方法测试 ============

func test_debug_unlock_achievement():
	# Act
	_system.debug_unlock_achievement("farm_10")

	# Assert
	assert_eq(_system.get_achievement_state("farm_10"), _system.AchievementState.COMPLETED)

func test_debug_reset_achievements():
	# Arrange
	_system.debug_unlock_achievement("farm_10")
	_system.debug_unlock_achievement("fish_5")
	assert_eq(_system.get_completed_count(), 2)

	# Act
	_system.debug_reset_achievements()

	# Assert
	assert_eq(_system.get_completed_count(), 0)

func test_debug_discover_item():
	# Act
	_system.debug_discover_item("test_artifact")

	# Assert
	assert_true(_system.is_item_discovered("test_artifact"), "调试发现应生效")

func test_debug_set_stat_and_trigger_achievement():
	# Act
	_system.debug_set_stat("total_crops_harvested", 100)

	# Assert
	assert_eq(_system._stats.total_crops_harvested, 100)
	assert_eq(_system.get_achievement_state("farm_100"), _system.AchievementState.COMPLETED)

func test_debug_get_stats():
	# Arrange
	_system._stats.total_fish_caught = 42

	# Act
	var stats = _system.debug_get_stats()

	# Assert
	assert_eq(stats.get("total_fish_caught"), 42)
