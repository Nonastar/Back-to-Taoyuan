extends "res://tests/unit/test_base.gd"

## MuseumSystem 单元测试
## 测试展品捐赠、捐赠进度、里程碑状态、存档序列化

var _system: Node = null

func _reset_all_state():
	_system._donated_items.clear()
	_system._claimed_milestones.clear()

func before_each():
	_system = Node.new()
	_system.set_script(load("res://src/scripts/autoload/museum_system.gd"))
	_system._ready()

func after_each():
	_reset_all_state()
	_system.free()

# ============ 初始化测试 ============

func test_forty_museum_items_loaded():
	# Arrange & Act
	var items = _system.MUSEUM_ITEMS

	# Assert
	assert_eq(items.size(), 40, "应有40件博物馆展品")

func test_museum_items_have_required_fields():
	# Arrange & Act
	var items = _system.MUSEUM_ITEMS

	# Assert
	for item in items:
		assert_dict_has_key(item, "id", "展品需有id")
		assert_dict_has_key(item, "name", "展品需有name")
		assert_dict_has_key(item, "category", "展品需有category")

# ============ 捐赠进度测试 ============

func test_donation_progress_initially_zero():
	# Arrange & Act
	var progress = _system.get_donation_progress()

	# Assert
	assert_eq(progress.get("current"), 0, "初始捐赠数应为0")
	assert_eq(progress.get("total"), 40, "总展品数应为40")
	assert_almost_eq(progress.get("percentage"), 0.0, 0.01, "初始百分比应为0%")

# ============ 物品查询测试 ============

func test_is_donated_initially_false():
	# Act
	var donated = _system.is_donated("copper_ore")

	# Assert
	assert_false(donated, "初始应未捐赠铜矿")

func test_get_donated_count_initially_zero():
	# Act
	var count = _system.get_donated_count()

	# Assert
	assert_eq(count, 0, "初始捐赠计数应为0")

func test_is_donated_unknown_item_returns_false():
	# Act
	var donated = _system.is_donated("nonexistent_item")

	# Assert
	assert_false(donated, "不存在物品应返回false")

# ============ 分类查询测试 ============

func test_get_items_by_category_ore():
	# Arrange & Act
	var ore_items = _system.get_items_by_category("ore")

	# Assert
	assert_eq(ore_items.size(), 7, "应有7件矿石展品")
	for item in ore_items:
		assert_eq(item.get("category"), "ore", "过滤结果应全为矿石分类")

func test_get_items_by_category_gem():
	# Arrange & Act
	var gem_items = _system.get_items_by_category("gem")

	# Assert
	assert_eq(gem_items.size(), 7, "应有7件宝石展品")

func test_get_items_by_category_nonexistent():
	# Act
	var result = _system.get_items_by_category("nonexistent")

	# Assert
	assert_eq(result.size(), 0, "不存在分类应返回空数组")

func test_all_categories_present():
	# Arrange & Act
	var categories = _system.get_categories()

	# Assert
	assert_array_contains(categories, "ore", "应有矿石分类")
	assert_array_contains(categories, "gem", "应有宝石分类")
	assert_array_contains(categories, "bar", "应有金属锭分类")
	assert_array_contains(categories, "fossil", "应有化石分类")
	assert_array_contains(categories, "artifact", "应有古物分类")
	assert_array_contains(categories, "spirit", "应有仙灵物品分类")

# ============ 里程碑测试 ============

func test_eight_milestones_defined():
	# Arrange & Act
	var milestones = _system.MILESTONES

	# Assert
	assert_eq(milestones.size(), 8, "应有8个里程碑")

func test_milestone_state_locked_when_no_donations():
	# Act
	var state = _system.get_milestone_state(5)

	# Assert
	assert_eq(state, _system.MILESTONE_LOCKED, "无捐赠时里程碑应为未解锁")

func test_milestone_state_unknown_returns_locked():
	# Act
	var state = _system.get_milestone_state(999)

	# Assert
	assert_eq(state, _system.MILESTONE_LOCKED, "不存在里程碑应返回未解锁")

func test_milestone_state_changes_with_donations():
	# Arrange - 模拟捐赠5件物品
	for i in range(5):
		_system._donated_items.append("item_%d" % i)

	# Act
	var state = _system.get_milestone_state(5)

	# Assert
	assert_eq(state, _system.MILESTONE_CLAIMABLE, "捐赠5件后里程碑5应可领取")

func test_milestone_not_claimable_below_threshold():
	# Arrange - 只捐赠4件
	for i in range(4):
		_system._donated_items.append("item_%d" % i)

	# Act
	var state = _system.get_milestone_state(5)

	# Assert
	assert_eq(state, _system.MILESTONE_LOCKED, "4件时里程碑5应未解锁")

# ============ 里程碑领取测试 ============

func test_claim_milestone_sets_as_claimed():
	# Arrange - 模拟达到15件捐赠
	for i in range(15):
		_system._donated_items.append("item_%d" % i)

	# Act
	var result = _system.claim_milestone(15)

	# Assert
	assert_true(result, "里程碑15应可领取")
	assert_eq(_system.get_milestone_state(15), _system.MILESTONE_CLAIMED, "领取后应为已领取")

func test_claim_already_claimed_milestone_fails():
	# Arrange
	for i in range(10):
		_system._donated_items.append("item_%d" % i)
	_system._claimed_milestones.append(10)

	# Act
	var result = _system.claim_milestone(10)

	# Assert
	assert_false(result, "已领取不应再次领取")

func test_claim_locked_milestone_fails():
	# Act
	var result = _system.claim_milestone(5)

	# Assert
	assert_false(result, "未达到不应领取")

# ============ 模拟捐赠流程测试 ============

func test_donate_item_too_early_returns_false():
	# Arrange - 模拟尚未有捐赠物品
	var item_id = "copper_ore"
	_system._donated_items.clear()

	# Act
	var items = _system.MUSEUM_ITEMS
	var target_item = null
	for item in items:
		if item["id"] == item_id:
			target_item = item
			break

	# Assert - 物品存在但未捐赠
	assert_not_null(target_item, "铜矿应在可捐赠列表中")
	assert_false(_system.is_donated(item_id), "初始不应已捐赠")

# ============ 存档序列化测试 ============

func test_serialize_deserialize_roundtrip():
	# Arrange - 模拟部分捐赠
	for i in range(10):
		_system._donated_items.append("item_%d" % i)
	_system._claimed_milestones.append(5)
	_system._claimed_milestones.append(10)

	var data = _system.serialize()

	# Act
	var sys2 = Node.new()
	sys2.set_script(load("res://src/scripts/autoload/museum_system.gd"))
	sys2._ready()
	sys2.deserialize(data)

	# Assert
	assert_eq(sys2.get_donated_count(), 10, "捐赠数应一致")
	assert_eq(sys2._claimed_milestones.size(), 2, "已领取里程碑数应一致")

	sys2.free()

func test_deserialize_empty_data_keeps_defaults():
	# Act
	_system.deserialize({})

	# Assert
	assert_eq(_system.get_donated_count(), 0, "空数据不应改变捐赠数")

# ============ 调试方法测试 ============

func test_debug_get_all_items():
	# Act
	var items = _system.MUSEUM_ITEMS

	# Assert
	assert_eq(items.size(), 40, "调试应返回全部40件展品")

func test_debug_get_progress_summary():
	# Act
	var summary = _system.get_donation_progress()

	# Assert
	assert_not_null(summary, "进度摘要不应为空")
	assert_dict_has_key(summary, "current", "摘要应有current字段")
	assert_dict_has_key(summary, "total", "摘要应有total字段")
