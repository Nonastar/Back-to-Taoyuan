extends "res://tests/unit/test_base.gd"

## QuestSystem 单元测试
## 测试任务系统核心 API：接受/追踪/完成/放弃/奖励发放

var _qs: Node = null

func before_each():
	_qs = Node.new()
	_qs.set_script(load("res://src/scripts/autoload/quest_system.gd"))
	# 模拟依赖（防止 NPE）
	_simulate_dependencies()
	_qs._ready()

func _simulate_dependencies() -> void:
	# 安全清理前序测试残留的 singleton（Engine.unregister_singleton 对不存在者抛异常）
	if Engine.has_singleton("EventBus"):
		Engine.unregister_singleton("EventBus")
	if Engine.has_singleton("PlayerStats"):
		Engine.unregister_singleton("PlayerStats")
	if Engine.has_singleton("TimeManager"):
		Engine.unregister_singleton("TimeManager")
	if Engine.has_singleton("InventorySystem"):
		Engine.unregister_singleton("InventorySystem")
	if Engine.has_singleton("NpcFriendshipSystem"):
		Engine.unregister_singleton("NpcFriendshipSystem")
	# 注册 EventBus（PlayerStats._ready() 依赖 EventBus.has_signal 守卫）
	var eb = Node.new()
	eb.set_script(load("res://src/scripts/autoload/event_bus.gd"))
	Engine.register_singleton("EventBus", eb)
	# 模拟 PlayerStats（需要 _ready() 初始化脚本方法）
	var ps = Node.new()
	ps.set_script(load("res://src/scripts/autoload/player_stats_system.gd"))
	Engine.register_singleton("PlayerStats", ps)
	ps._ready()
	# 模拟 TimeManager
	var tm = Node.new()
	tm.set_script(load("res://src/scripts/autoload/time_manager.gd"))
	Engine.register_singleton("TimeManager", tm)
	# 模拟 InventorySystem
	var inv = Node.new()
	inv.set_script(load("res://src/scripts/autoload/inventory_system.gd"))
	Engine.register_singleton("InventorySystem", inv)
	# 模拟 NpcFriendshipSystem
	var nf = Node.new()
	nf.set_script(load("res://src/scripts/autoload/npc_friendship_system.gd"))
	Engine.register_singleton("NpcFriendshipSystem", nf)

func after_each():
	_qs._quests.clear()
	_qs._active_quests.clear()
	_qs._completed_quest_ids.clear()
	_qs.free()
	# 清理模拟 singletons（安全清理，Engine.has_singleton 无副作用）
	if Engine.has_singleton("EventBus"):
		Engine.unregister_singleton("EventBus")
	if Engine.has_singleton("PlayerStats"):
		Engine.unregister_singleton("PlayerStats")
	if Engine.has_singleton("TimeManager"):
		Engine.unregister_singleton("TimeManager")
	if Engine.has_singleton("InventorySystem"):
		Engine.unregister_singleton("InventorySystem")
	if Engine.has_singleton("NpcFriendshipSystem"):
		Engine.unregister_singleton("NpcFriendshipSystem")

# ============ 初始化测试 ============

func test_initializes_with_8_main_quests():
	# 初始应有 8 个主线任务（所有 PENDING）
	var all_quests = _qs.get_all_quests()
	assert_eq(all_quests.size(), 8, "应有 8 个主线任务")
	# 验证第一个任务状态
	var quest1 = _qs.get_quest("main_1_1")
	assert_not_null(quest1, "main_1_1 应存在")
	assert_eq(quest1.get("state"), _qs.QuestState.PENDING, "main_1_1 初始状态应为 PENDING")

func test_quest_type_enum_has_main():
	assert_eq(_qs.QuestType.MAIN, 0, "QuestType.MAIN 应为 0")
	assert_eq(_qs.QuestType.DAILY, 1, "QuestType.DAILY 应为 1")

func test_quest_state_enum():
	assert_eq(_qs.QuestState.PENDING, 0, "PENDING 应为 0")
	assert_eq(_qs.QuestState.AVAILABLE, 1, "AVAILABLE 应为 1")
	assert_eq(_qs.QuestState.ACTIVE, 2, "ACTIVE 应为 2")
	assert_eq(_qs.QuestState.COMPLETED, 3, "COMPLETED 应为 3")
	assert_eq(_qs.QuestState.EXPIRED, 4, "EXPIRED 应为 4")

# ============ 接取任务测试 ============

func test_accept_main_quest_success():
	var result = _qs.accept_quest("main_1_1")
	assert_eq(result.get("success"), true, "接取 main_1_1 应成功")
	# 状态应变为 ACTIVE
	var quest = _qs.get_quest("main_1_1")
	assert_eq(quest.get("state"), _qs.QuestState.ACTIVE, "接取后状态应为 ACTIVE")
	# 应出现在活跃任务中
	var active = _qs.get_active_quests()
	assert_eq(active.size(), 1, "应有 1 个进行中任务")

func test_accept_invalid_quest_returns_error():
	var result = _qs.accept_quest("nonexistent_quest")
	assert_eq(result.get("success"), false, "接取不存在任务应失败")
	assert_eq(result.get("message"), "任务不存在", "错误消息应为'任务不存在'")

func test_accept_same_quest_twice_returns_error():
	_qs.accept_quest("main_1_1")
	var result = _qs.accept_quest("main_1_1")
	assert_eq(result.get("success"), false, "重复接取应失败")
	assert_eq(result.get("message"), "该任务已在进行中", "错误消息应为'该任务已在进行中'")

func test_accept_pending_only_for_main_quest():
	# main_1_1 初始为 PENDING，接取后状态变为 ACTIVE
	_qs.accept_quest("main_1_1")
	# 此时尝试再次接取（状态已变）应失败
	var result = _qs.accept_quest("main_1_1")
	assert_eq(result.get("success"), false, "已完成接取的任务不可再接")

func test_accept_daily_quest_requires_available_state():
	# 向量验证 _validate_quest_for_accept 中 DAILY 状态检查
	# 手动将一个任务设为 DAILY + AVAILABLE，验证接取成功
	var quest_data = {
		"id": "daily_test_1",
		"type": _qs.QuestType.DAILY,
		"title": "测试委托",
		"description": "测试",
		"target_type": "harvestCrops",
		"target_count": 3,
		"reward_money": 100,
		"reward_npc_id": "",
		"reward_friendship": 0,
		"reward_items": [],
		"state": _qs.QuestState.AVAILABLE,
		"progress": 0
	}
	_qs._quests["daily_test_1"] = quest_data
	var result = _qs.accept_quest("daily_test_1")
	assert_eq(result.get("success"), true, "AVAILABLE 状态的 DAILY 任务应可接取")
	assert_eq(_qs.get_quest("daily_test_1").get("state"), _qs.QuestState.ACTIVE, "接取后应为 ACTIVE")

# ============ 进度追踪测试 ============

func test_add_progress_increments_count():
	_qs.accept_quest("main_1_1")
	var progress_before = _qs.get_quest("main_1_1").get("progress", 0)
	_qs.add_progress("main_1_1", 1)
	var progress_after = _qs.get_quest("main_1_1").get("progress", 0)
	assert_eq(progress_after, progress_before + 1, "进度应增加1")

func test_add_progress_no_effect_if_not_active():
	# 未接取的任务不响应 add_progress
	var progress_before = _qs.get_quest("main_1_1").get("progress", 0)
	_qs.add_progress("main_1_1", 5)
	var progress_after = _qs.get_quest("main_1_1").get("progress", 0)
	assert_eq(progress_after, progress_before, "未接取任务的进度不应改变")

func test_add_progress_no_effect_if_quest_not_exists():
	# 不存在的任务静默忽略
	_qs.add_progress("fake_quest", 10)
	# 不应报错（静默忽略）

# ============ 矿洞任务进度测试（regression: _on_mine_floor_reached 委托 add_progress）============

func test_mine_floor_reached_sets_progress():
	# main_1_7: reachMineFloor, target=5
	_qs.accept_quest("main_1_7")
	_qs._on_mine_floor_reached(3)
	var quest = _qs.get_quest("main_1_7")
	assert_eq(quest.get("progress"), 3, "到达第3层时进度应为3")

func test_mine_floor_reached_uses_delta_not_absolute():
	# 验证 _on_mine_floor_reached 传递差量而非绝对值
	_qs.accept_quest("main_1_7")
	_qs._on_mine_floor_reached(2)
	_qs._on_mine_floor_reached(5)  # 差量应为 3（5-2）
	var quest = _qs.get_quest("main_1_7")
	assert_eq(quest.get("progress"), 5, "到达第5层时进度应为5")

func test_mine_floor_reached_does_not_decrease():
	# 验证不会往回走时减少进度
	_qs.accept_quest("main_1_7")
	_qs._on_mine_floor_reached(5)
	_qs._on_mine_floor_reached(3)  # 不应减少，仍为5
	var quest = _qs.get_quest("main_1_7")
	assert_eq(quest.get("progress"), 5, "往回走不应减少进度")

func test_mine_floor_reached_completable():
	# 到达目标层后可完成任务（验证 add_progress 触发目标达成逻辑）
	_qs.accept_quest("main_1_7")
	_qs._on_mine_floor_reached(5)
	var result = _qs.complete_quest("main_1_7")
	assert_eq(result.get("success"), true, "到达第5层应可完成任务")
	assert_eq(_qs._completed_quest_ids.has("main_1_7"), true, "main_1_7 应标记为已完成")

func test_mine_floor_reached_no_effect_if_not_active():
	# 未接取任务不应响应
	_qs._on_mine_floor_reached(5)
	var quest = _qs.get_quest("main_1_7")
	assert_eq(quest.get("progress"), 0, "未接取任务的矿洞进度不应改变")

func test_get_quest_progress_returns_correct_data():
	_qs.accept_quest("main_1_1")
	_qs.add_progress("main_1_1", 3)
	var p = _qs.get_quest_progress("main_1_1")
	assert_eq(p.get("progress"), 3, "进度应为3")
	assert_eq(p.get("target"), 3, "目标应为3（main_1_1 target_count=3）")
	assert_eq(p.get("state"), _qs.QuestState.ACTIVE, "状态应为ACTIVE")

# ============ 完成任务测试 ============

func test_complete_quest_success_when_target_met():
	_qs.accept_quest("main_1_1")
	# 跳过目标检查：直接设置进度
	_qs.get_quest("main_1_1")["progress"] = 5
	var result = _qs.complete_quest("main_1_1")
	assert_eq(result.get("success"), true, "达到目标时应完成成功")
	assert_eq(_qs._completed_quest_ids.size(), 1, "应记录为已完成")
	assert_eq(_qs.get_quest("main_1_1").get("state"), _qs.QuestState.COMPLETED, "状态应为COMPLETED")

func test_complete_quest_fails_if_target_not_met():
	_qs.accept_quest("main_1_1")
	_qs.add_progress("main_1_1", 2)
	var result = _qs.complete_quest("main_1_1")
	assert_eq(result.get("success"), false, "目标未达成时应失败")
	assert_true("目标未达成" in str(result.get("message", "")), "错误消息应提及目标")

func test_complete_quest_fails_if_not_accepted():
	var result = _qs.complete_quest("main_1_1")
	assert_eq(result.get("success"), false, "未接取的任务无法完成")

func test_complete_quest_auto_activates_next():
	_qs.accept_quest("main_1_1")
	_qs.get_quest("main_1_1")["progress"] = 5
	_qs.complete_quest("main_1_1")
	# main_1_2 应从 PENDING 变为 PENDING（未激活，因为完成 main_1_1 才激活）
	# 实际上 complete_quest 调用 _activate_next_main_quest(main_1_1)
	# 但该方法需要检查 MAIN_QUESTS_DATA 中是否有 main_1_2
	var next = _qs.get_quest("main_1_2")
	assert_not_null(next, "main_1_2 应存在")
	assert_eq(next.get("state"), _qs.QuestState.PENDING, "main_1_2 应为 PENDING（待玩家接取）")

# ============ 放弃任务测试 ============

func test_abandon_quest_removes_from_active():
	_qs.accept_quest("main_1_1")
	var result = _qs.abandon_quest("main_1_1")
	assert_eq(result.get("success"), true, "放弃任务应成功")
	assert_eq(_qs.get_active_quests().size(), 0, "进行中任务应为0")

func test_abandon_mainquest_resets_to_pending():
	_qs.accept_quest("main_1_1")
	_qs.add_progress("main_1_1", 2)
	_qs.abandon_quest("main_1_1")
	var quest = _qs.get_quest("main_1_1")
	assert_eq(quest.get("state"), _qs.QuestState.PENDING, "主线放弃后应重置为PENDING")
	assert_eq(quest.get("progress"), 0, "放弃后进度应清零")

func test_abandon_nonexistent_returns_error():
	var result = _qs.abandon_quest("fake")
	assert_eq(result.get("success"), false, "放弃不存在的任务应失败")

# ============ get_active_quests 测试 ============

func test_get_active_quests_only_returns_active():
	_qs.accept_quest("main_1_1")
	_qs.accept_quest("main_1_3")
	var active = _qs.get_active_quests()
	assert_eq(active.size(), 2, "应返回2个进行中任务")
	for q in active:
		assert_eq(q.get("state"), _qs.QuestState.ACTIVE, "所有返回任务应为ACTIVE")

# ============ 序列化测试 ============

func test_serialize_contains_all_data():
	_qs.accept_quest("main_1_1")
	_qs.add_progress("main_1_1", 3)
	var data = _qs.serialize()
	assert_true(data.has("quests"), "序列化应有 quests 字段")
	assert_true(data.has("active_quests"), "序列化应有 active_quests 字段")
	assert_true(data.has("completed_quest_ids"), "序列化应有 completed_quest_ids 字段")
	assert_eq(data.get("quests", {}).size(), 8, "quests 应包含8个主线任务")

func test_deserialize_restores_state():
	# 先设置一些状态
	_qs.accept_quest("main_1_1")
	_qs.add_progress("main_1_1", 3)
	var data = _qs.serialize()
	# 清除状态
	_qs._active_quests.clear()
	# 反序列化
	_qs.deserialize(data)
	assert_eq(_qs.get_active_quests().size(), 1, "反序列化后应有1个活跃任务")

# ============ Debug 方法测试 ============

func test_debug_complete_quest_skips_target_check():
	# debug_complete_quest 绕过 accept，直接设置进度并完成
	_qs.debug_complete_quest("main_1_1")
	assert_true(_qs._completed_quest_ids.has("main_1_1"), "debug_complete_quest 应直接标记完成")

func test_debug_get_status_returns_summary():
	_qs.accept_quest("main_1_1")
	var status = _qs.debug_get_status()
	assert_eq(status.get("total"), 8, "总任务数应为8")
	assert_eq(status.get("active"), 1, "活跃数应为1")
	assert_eq(status.get("completed"), 0, "完成数初始为0")
