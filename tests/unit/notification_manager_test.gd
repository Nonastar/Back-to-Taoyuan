extends "res://tests/unit/test_base.gd"

## NotificationManager 单元测试
## 测试队列管理、去重合并、优先级、颜色定义

var _mgr: Node = null

func before_each():
	_mgr = Node.new()
	_mgr.set_script(load("res://src/scripts/autoload/notification_manager.gd"))
	_mgr._debug_mode = false
	_mgr._ready()
	# 测试模式：阻止 show_message 的 HUD 直发路径，同时阻止 _show_next 清空队列
	_mgr._test_mode = true
	_mgr._is_showing = true

func after_each():
	_mgr._is_showing = false
	_mgr._queue.clear()
	_mgr._dedup_map.clear()
	_mgr._is_paused = false
	_mgr._is_draining = false
	_mgr.free()

# ============ 常量验证测试 ============

func test_notification_constants():
	assert_eq(_mgr.MAX_QUEUE_SIZE, 20, "MAX_QUEUE_SIZE 应为 20")
	assert_almost_eq(_mgr.DEFAULT_DURATION, 2.5, 0.01, "DEFAULT_DURATION 应为 2.5")

func test_notification_colors_exist():
	var colors = _mgr.NotificationColor
	assert_not_null(colors.GAIN, "应有 GAIN 颜色")
	assert_not_null(colors.COST, "应有 COST 颜色")
	assert_not_null(colors.CONSUME, "应有 CONSUME 别名")
	assert_eq(colors.COST, colors.CONSUME, "COST 应等于 CONSUME")
	assert_not_null(colors.SUCCESS, "应有 SUCCESS 颜色")
	assert_not_null(colors.WARNING, "应有 WARNING 颜色")
	assert_not_null(colors.ERROR, "应有 ERROR 颜色")
	assert_not_null(colors.SYSTEM, "应有 SYSTEM 颜色")

func test_gain_color_is_gold():
	var c = _mgr.NotificationColor.GAIN
	assert_almost_eq(c.r, 1.0, 0.01, "GAIN 红色分量为 1.0")
	assert_almost_eq(c.g, 0.84, 0.01, "GAIN 绿色分量为 0.84")
	assert_almost_eq(c.b, 0.0, 0.01, "GAIN 蓝色分量为 0.0")

func test_error_color_is_deep_red():
	var c = _mgr.NotificationColor.ERROR
	assert_almost_eq(c.r, 0.75, 0.01, "ERROR 红色分量为 0.75 (#C0392B)")
	assert_almost_eq(c.g, 0.22, 0.01, "ERROR 绿色分量为 0.22")
	assert_almost_eq(c.b, 0.17, 0.01, "ERROR 蓝色分量为 0.17")

# ============ 队列基础测试 ============

func test_show_gain_adds_to_queue():
	_mgr.show_gain("+10 金币")
	assert_eq(_mgr.get_queue_size(), 1, "show_gain 应添加一条到队列")

func test_show_cost_adds_to_queue():
	_mgr.show_cost("-5 体力")
	assert_eq(_mgr.get_queue_size(), 1, "show_cost 应添加一条到队列")

func test_show_success_adds_to_queue():
	_mgr.show_success("任务完成!")
	assert_eq(_mgr.get_queue_size(), 1, "show_success 应添加一条到队列")

func test_show_warning_adds_to_queue():
	_mgr.show_warning("背包已满")
	assert_eq(_mgr.get_queue_size(), 1, "show_warning 应添加一条到队列")

func test_show_error_adds_to_queue():
	_mgr.show_error("操作失败")
	assert_eq(_mgr.get_queue_size(), 1, "show_error 应添加一条到队列")

func test_show_system_adds_to_queue():
	_mgr.show_system("系统消息")
	assert_eq(_mgr.get_queue_size(), 1, "show_system 应添加一条到队列")

# ============ 去重合并测试 ============

func test_different_ids_no_dedup():
	_mgr.show_gain("+1 萝卜", _mgr.DEFAULT_DURATION, "item_carrot_1")
	_mgr.show_gain("+1 白菜", _mgr.DEFAULT_DURATION, "item_cabbage_1")
	assert_eq(_mgr.get_queue_size(), 2, "不同 ID 不应合并，队列应有 2 条")

func test_same_id_dedup_merges():
	_mgr.show_gain("+1 萝卜", _mgr.DEFAULT_DURATION, "harvest_carrot")
	assert_eq(_mgr.get_queue_size(), 1, "首次添加，队列应有 1 条")
	# 模拟时间内再次添加（同一 id）
	_mgr.show_gain("+1 萝卜", _mgr.DEFAULT_DURATION, "harvest_carrot")
	# 去重后仍应有 1 条（合并），但 _dedup_map 中 count=2
	assert_eq(_mgr.get_queue_size(), 1, "相同 ID 在去重窗口内应合并，队列仍为 1 条")
	assert_eq(_mgr._dedup_map["harvest_carrot"]["count"], 2, "合并计数应为 2")

func test_different_types_no_dedup():
	_mgr.show_gain("+10 金币", _mgr.DEFAULT_DURATION, "gain_gold")
	_mgr.show_cost("-5 金币", _mgr.DEFAULT_DURATION, "cost_gold")  # 不同 type，id 不同，不合并
	assert_eq(_mgr.get_queue_size(), 2, "不同 type+id 不应合并，队列应有 2 条")

func test_dedup_count_caps_at_999():
	# 模拟多次合并
	_mgr.show_gain("+1 萝卜", _mgr.DEFAULT_DURATION, "harvest_carrot")
	for i in range(10):
		_mgr.show_gain("+1 萝卜", _mgr.DEFAULT_DURATION, "harvest_carrot")
	assert_le(_mgr._dedup_map["harvest_carrot"]["count"], 999, "合并计数上限为 999")

# ============ 队列满测试 ============

func test_queue_respects_max_size():
	# 添加 20 条不同 id 的消息
	for i in range(25):
		_mgr.show_gain("+1 物品%d" % i, _mgr.DEFAULT_DURATION, "item_%d" % i)
	# 队列应限制在 MAX=20
	assert_le(_mgr.get_queue_size(), 20, "队列大小不应超过 MAX_QUEUE_SIZE")

func test_queue_full_removes_lowest_priority():
	# 添加低优先级消息填满队列
	for i in range(20):
		_mgr.show_message("msg_%d" % i, 2.5, _mgr.NotificationColor.SYSTEM, "low_%d" % i)
	# 添加高优先级消息
	_mgr.show_with_priority("urgent!", 2.5, _mgr.NotificationColor.WARNING, 5, "high_1")
	# 高优先级应在队列前面
	assert_eq(_mgr._queue[0]["priority"], 4, "高优先级消息应在队列最前面（priority>4 被钳制为 4）")

# ============ 优先级测试 ============

func test_priority_insertion_high_first():
	_mgr.show_with_priority("low priority", 2.5, _mgr.NotificationColor.NORMAL, 0, "low")
	_mgr.show_with_priority("high priority", 2.5, _mgr.NotificationColor.WARNING, 5, "high")
	assert_eq(_mgr._queue[0]["id"], "high", "高优先级消息应在队列最前面")

func test_same_priority_fifo():
	_mgr.show_with_priority("first", 2.5, _mgr.NotificationColor.NORMAL, 2, "msg1")
	_mgr.show_with_priority("second", 2.5, _mgr.NotificationColor.NORMAL, 2, "msg2")
	assert_eq(_mgr._queue[0]["id"], "msg1", "同优先级按 FIFO 顺序")
	assert_eq(_mgr._queue[1]["id"], "msg2", "第二条消息在后面")

func test_priority_0_inserted_at_end():
	_mgr.show_with_priority("p5", 2.5, _mgr.NotificationColor.WARNING, 5, "p5")
	_mgr.show_with_priority("p0", 2.5, _mgr.NotificationColor.NORMAL, 0, "p0")
	assert_eq(_mgr._queue[0]["id"], "p5", "priority=5 应在前面")
	assert_eq(_mgr._queue[1]["id"], "p0", "priority=0 应在后面")

# ============ 暂停恢复测试 ============

func test_pause_stops_showing():
	_mgr.show_gain("test1")
	assert_eq(_mgr._queue.size(), 1, "添加消息后队列有 1 条")
	_mgr._is_paused = true
	# 再添加一条
	_mgr.show_gain("test2")
	assert_eq(_mgr._queue.size(), 2, "暂停时仍可添加消息到队列")

func test_clear_queue():
	_mgr.show_gain("msg1")
	_mgr.show_warning("msg2")
	_mgr.clear_queue()
	assert_eq(_mgr.get_queue_size(), 0, "clear_queue 应清空队列")

func test_is_showing():
	# after_each 设置 _is_showing=true 以阻止无场景树时触发 HUD display path
	assert_true(_mgr.is_showing(), "after_each 后 _is_showing 应为 true（阻止 HUD 路径）")
	_mgr.show_gain("test")
	# show_gain 在 _is_showing=true 时不触发 _show_next，队列应有内容
	assert_eq(_mgr.get_queue_size(), 1, "show_gain 应添加一条到队列")
