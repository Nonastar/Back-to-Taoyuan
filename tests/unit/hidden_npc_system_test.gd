extends "res://tests/unit/test_base.gd"

## HiddenNpcSystem 单元测试
## 测试仙灵发现、缘分计算、供奉、互动、能力解锁、存档序列化

var _system: Node = null

func _reset_all_state():
	_system._npc_states.clear()
	_system._initialized = false
	_system._initialize()

func before_each():
	_system = Node.new()
	_system.set_script(load("res://src/scripts/autoload/hidden_npc_system.gd"))
	_system._ready()

func after_each():
	_reset_all_state()
	_system.free()

# ============ 初始化测试 ============

func test_six_hidden_npcs_loaded():
	# Arrange & Act
	var all_npcs = _system.get_all_hidden_npcs()

	# Assert
	assert_eq(all_npcs.size(), 6, "应有6位仙灵")

func test_all_npcs_initialized_to_unknown_phase():
	# Arrange & Act
	var all_npcs = _system.get_all_hidden_npcs()

	# Assert
	for npc in all_npcs:
		var state = _system.get_hidden_npc_state(npc["id"])
		assert_eq(state.get("phase"), _system.PHASE_UNKNOWN, npc["id"] + "初始阶段应为UNKNOWN")

func test_npc_data_has_required_fields():
	# Arrange & Act
	var all_npcs = _system.get_all_hidden_npcs()

	# Assert
	for npc in all_npcs:
		assert_dict_has_key(npc, "id", "仙灵需有id")
		assert_dict_has_key(npc, "name", "仙灵需有name")
		assert_dict_has_key(npc, "title", "仙灵需有title")

# ============ 缘分等级测试 ============

func test_affinity_level_wary():
	# Arrange
	var level = _system._get_affinity_level(0)

	# Assert
	assert_eq(level, _system.AFFINITY_WARY, "0缘分应为戒备")

func test_affinity_level_curious():
	# Arrange
	var level = _system._get_affinity_level(400)

	# Assert
	assert_eq(level, _system.AFFINITY_CURIOUS, "400缘分应为好奇")

func test_affinity_level_trusting():
	# Arrange
	var level = _system._get_affinity_level(1000)

	# Assert
	assert_eq(level, _system.AFFINITY_TRUSTING, "1000缘分应为信任")

func test_affinity_level_devoted():
	# Arrange
	var level = _system._get_affinity_level(1800)

	# Assert
	assert_eq(level, _system.AFFINITY_DEVOTED, "1800缘分应为倾心")

func test_affinity_level_eternal():
	# Arrange
	var level = _system._get_affinity_level(2500)

	# Assert
	assert_eq(level, _system.AFFINITY_ETERNAL, "2500缘分应为永伴")

func test_get_affinity_level_for_unknown_npc_returns_wary():
	# Act
	var level = _system.get_affinity_level("nonexistent")

	# Assert
	assert_eq(level, _system.AFFINITY_WARY, "不存在仙灵应返回戒备")

# ============ 发现阶段进阶测试 ============

func test_next_phase_progression():
	# Arrange & Act & Assert
	assert_eq(_system._get_next_phase(_system.PHASE_UNKNOWN), _system.PHASE_RUMOR)
	assert_eq(_system._get_next_phase(_system.PHASE_RUMOR), _system.PHASE_GLIMPSE)
	assert_eq(_system._get_next_phase(_system.PHASE_GLIMPSE), _system.PHASE_ENCOUNTER)
	assert_eq(_system._get_next_phase(_system.PHASE_ENCOUNTER), _system.PHASE_REVEALED)

func test_next_phase_at_max_stays_at_max():
	# Act
	var next = _system._get_next_phase(_system.PHASE_REVEALED)

	# Assert
	assert_eq(next, _system.PHASE_REVEALED, "已达到最大阶段不应再进阶")

# ============ 查询测试 ============

func test_get_hidden_npc_state_returns_dict():
	# Act
	var state = _system.get_hidden_npc_state("long_ling")

	# Assert
	assert_not_null(state, "存在的仙灵状态不应为空")
	assert_true(state is Dictionary, "仙灵状态应为Dictionary")

func test_get_hidden_npc_state_unknown_returns_empty():
	# Act
	var state = _system.get_hidden_npc_state("nonexistent")

	# Assert
	assert_eq(state.size(), 0, "不存在仙灵应返回空字典")

func test_get_revealed_npcs_initially_empty():
	# Act
	var revealed = _system.get_revealed_npcs()

	# Assert
	assert_eq(revealed.size(), 0, "初始应无已显现仙灵")

func test_get_rumor_npcs_initially_empty():
	# Act
	var rumors = _system.get_rumor_npcs()

	# Assert
	assert_eq(rumors.size(), 0, "初始应无传闻仙灵")

# ============ 缘分添加测试 ============

func test_add_affinity_increases_value():
	# Arrange
	var state_before = _system.get_hidden_npc_state("long_ling")
	var affinity_before = state_before.get("affinity", 0)

	# Act
	_system.add_affinity("long_ling", 100)

	# Assert
	var state_after = _system.get_hidden_npc_state("long_ling")
	assert_eq(state_after.get("affinity"), affinity_before + 100, "缘分应增加100")

func test_add_affinity_capped_at_max():
	# Act
	_system.add_affinity("long_ling", _system.AFFINITY_MAX + 1000)

	# Assert
	var state = _system.get_hidden_npc_state("long_ling")
	assert_eq(state.get("affinity"), _system.AFFINITY_MAX, "缘分不应超过最大值")

func test_add_negative_affinity_not_below_zero():
	# Arrange
	_system.add_affinity("long_ling", 50)
	assert_gt(_system.get_hidden_npc_state("long_ling").get("affinity"), 0)

	# Act
	_system.add_affinity("long_ling", -100)

	# Assert
	var state = _system.get_hidden_npc_state("long_ling")
	assert_ge(state.get("affinity"), 0, "缘分不应低于0")

func test_add_affinity_to_unknown_npc_no_error():
	# Act - 不应崩溃
	_system.add_affinity("nonexistent", 100)

	# Assert
	assert_true(true, "不存在仙灵添加缘分不应崩溃")

# ============ 供奉测试（功能门控） ============

func test_offering_gated_when_disabled():
	# Act
	var result = _system.perform_offering("long_ling", "test_item")

	# Assert
	assert_false(result.get("success", true), "FEATURE_OFFERINGS_ENABLED=false时应失败")
	assert_eq(result.get("affinity_change"), 0, "关闭时缘分变化应为0")

func test_offering_to_nonexistent_npc_fails():
	# Act
	var result = _system.perform_offering("nonexistent", "test_item")

	# Assert
	assert_false(result.get("success", true), "不存在仙灵供奉应失败")

# ============ 独特互动测试 ============

func test_special_interaction_requires_revealed():
	# Arrange - 仙灵初始为UNKNOWN阶段
	var result = _system.perform_special_interaction("long_ling")

	# Assert
	assert_false(result.get("success", true), "未显现仙灵不应接受互动")

func test_special_interaction_to_nonexistent_npc_fails():
	# Act
	var result = _system.perform_special_interaction("nonexistent")

	# Assert
	assert_false(result.get("success", true))

# ============ 显灵日测试 ============

func test_is_manifestation_day_requires_time_system():
	# Act
	var result = _system.is_manifestation_day("long_ling")

	# Assert
	assert_false(result, "无TimeManager时应返回false")

# ============ 能力系统测试 ============

func test_get_ability_value_known():
	# Act
	var value = _system.get_ability_value("long_ling_1")

	# Assert
	assert_eq(value, 1, "龙泽的能力值应为1")

func test_get_ability_value_unknown():
	# Act
	var value = _system.get_ability_value("nonexistent_ability")

	# Assert
	assert_eq(value, 0, "不存在能力应返回0")

func test_get_active_abilities_initially_empty():
	# Act
	var active = _system.get_active_abilities()

	# Assert
	assert_eq(active.size(), 0, "初始应无激活的能力")

func test_is_ability_active_initially_false():
	# Act
	var active = _system.is_ability_active("long_ling_1")

	# Assert
	assert_false(active, "未解锁能力应不可用")

# ============ 求缘与结缘测试 ============

func test_courting_requires_revealed():
	# Act
	var result = _system.start_courting("long_ling")

	# Assert
	assert_false(result.get("success", true), "未显现仙灵不应接受求缘")

func test_form_bond_requires_revealed():
	# Act
	var result = _system.form_bond("long_ling")

	# Assert
	assert_false(result.get("success", true), "未显现仙灵不应接受结缘")

func test_form_bond_to_nonexistent_npc_fails():
	# Act
	var result = _system.form_bond("nonexistent")

	# Assert
	assert_false(result.get("success", true))

# ============ 心事件测试（功能门控） ============

func test_heart_event_gated_when_disabled():
	# Act
	var result = _system.check_heart_event("long_ling")

	# Assert
	assert_false(result.get("available", true), "FEATURE_HEART_EVENTS_ENABLED=false时应返回不可用")

# ============ 存档序列化测试 ============

func test_serialize_deserialize_roundtrip():
	# Arrange
	_system.add_affinity("long_ling", 500)
	var state_before = _system.get_hidden_npc_state("long_ling").duplicate()

	var data = _system.serialize()

	# Act
	var sys2 = Node.new()
	sys2.set_script(load("res://src/scripts/autoload/hidden_npc_system.gd"))
	sys2._ready()
	sys2.deserialize(data)

	# Assert
	var state_after = sys2.get_hidden_npc_state("long_ling")
	assert_eq(state_after.get("affinity"), state_before.get("affinity"), "缘分值应保留")

	sys2.free()

func test_deserialize_empty_data_keeps_defaults():
	# Act
	_system.deserialize({})

	# Assert
	var state = _system.get_hidden_npc_state("long_ling")
	assert_eq(state.get("phase"), _system.PHASE_UNKNOWN, "空数据不应改变默认状态")

# ============ 每日重置测试 ============

func test_daily_reset_clears_interaction_flags():
	# Arrange
	var state = _system.get_hidden_npc_state("long_ling")
	state["offered_today"] = true
	state["interacted_today"] = true

	# Act
	_system.daily_reset()

	# Assert
	assert_false(state.get("offered_today"), "每日重置应清除供奉标记")
	assert_false(state.get("interacted_today"), "每日重置应清除互动标记")

# ============ 调试方法测试 ============

func test_debug_set_phase():
	# Act
	_system.debug_set_phase("long_ling", _system.PHASE_RUMOR)

	# Assert
	var state = _system.get_hidden_npc_state("long_ling")
	assert_eq(state.get("phase"), _system.PHASE_RUMOR, "调试设置阶段应生效")

func test_debug_set_affinity():
	# Act
	_system.debug_set_affinity("long_ling", 1200)

	# Assert
	var state = _system.get_hidden_npc_state("long_ling")
	assert_eq(state.get("affinity"), 1200)

func test_debug_get_all_states():
	# Act
	var states = _system.debug_get_all_states()

	# Assert
	assert_eq(states.size(), 6, "应有6位仙灵的状态")
	assert_dict_has_key(states, "long_ling")
	assert_dict_has_key(states, "tao_yao")
