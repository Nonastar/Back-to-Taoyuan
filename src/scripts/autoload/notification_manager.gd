extends Node

## NotificationManager - 通知管理系统
## 统一管理游戏中的所有飘字通知
## 参考: ADR-0002 Autoload系统设计

# ============ 常量 ============

## 通知配置
const DEFAULT_DURATION: float = 2.5
const MAX_QUEUE_SIZE: int = 20
const DEDUP_WINDOW: float = 2.0  # 去重窗口（秒）

## 通知颜色
class NotificationColor:
	const NORMAL: Color = Color(1, 1, 1, 1)
	const GAIN: Color = Color(1, 0.84, 0, 1)              # 金色 - 获取（#FFD700）
	const COST: Color = Color(0.91, 0.30, 0.24, 1)     # 红色 - 消耗（#E74C3C），GDD: COST
	const CONSUME: Color = COST                          # CONSUME 别名，兼容旧调用
	const SUCCESS: Color = Color(0.18, 0.8, 0.44, 1)   # 绿色 - 成功（#2ECC71）
	const WARNING: Color = Color(0.95, 0.61, 0.07, 1)  # 橙色 - 警告（#F39C12）
	const ERROR: Color = Color(0.75, 0.22, 0.17, 1)    # 深红色 - 错误（#C0392B），GDD: ERROR
	const SYSTEM: Color = Color(1, 1, 1, 1)             # 白色 - 系统（#FFFFFF）

# ============ 状态 ============

## 通知队列
var _queue: Array[Dictionary] = []

## 是否正在显示
var _is_showing: bool = false

## HUD引用（可能是 CanvasLayer，不是 Control）
var _hud: Node = null

## 调试模式
var _debug_mode: bool = false

## 去重映射: id → {time: float, count: int}
var _dedup_map: Dictionary = {}

## 正在显示的通知计数（多飘窗支持，最多同时3条）
var _visible_count: int = 0
const MAX_VISIBLE: int = 3

## 暂停/恢复状态
var _is_paused: bool = false
var _is_draining: bool = false

# ============ 信号 ============

## 通知开始显示
signal notification_started(text: String)

## 通知显示完成
signal notification_finished(text: String)

## 队列状态变化
signal queue_changed(queue_size: int)

# ============ 初始化 ============

func _ready() -> void:
	_connect_signals()
	if _debug_mode:
		print("[NotificationManager] Initialized")

## 连接EventBus信号
func _connect_signals() -> void:
	if EventBus.has_signal("ui_notification"):
		EventBus.ui_notification.connect(_on_ui_notification)
	if EventBus.has_signal("notification_requested"):
		EventBus.notification_requested.connect(_on_notification_requested)
	# 暂停/恢复信号（场景管理器发送，进入/退出全屏UI时）
	if EventBus.has_signal("pause_requested"):
		EventBus.pause_requested.connect(_on_pause_requested)
	if EventBus.has_signal("resume_requested"):
		EventBus.resume_requested.connect(_on_resume_requested)

## 查找HUD
func _find_hud() -> Node:
	if _hud != null:
		return _hud
	var tree = get_tree()
	if tree == null:
		return null
	# 优先从 group 查找（最可靠）
	var hud_nodes = tree.get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		var raw = hud_nodes[0]
		if raw != null and raw.has_method("show_message"):
			_hud = raw
			return _hud
	# 兜底：递归查找
	var root = tree.root
	_hud = root.find_child("HUD", true, false)
	return _hud

# ============ 公共API ============

## 显示通知 (基础方法)
## id: 唯一标识符，用于去重合并。2秒内相同id的消息合并显示 count
func show_message(text: String, duration: float = DEFAULT_DURATION, color: Color = NotificationColor.NORMAL, id: String = "") -> void:
	var notification = {
		"text": text,
		"duration": duration,
		"color": color,
		"priority": 0,
		"id": id
	}
	_add_to_queue(notification)

## 显示获取类通知 (金色)
func show_gain(text: String, duration: float = DEFAULT_DURATION, id: String = "") -> void:
	show_message(text, duration, NotificationColor.GAIN, id)

## 显示消耗类通知 (红色) — GDD: COST
func show_cost(text: String, duration: float = DEFAULT_DURATION, id: String = "") -> void:
	show_message(text, duration, NotificationColor.COST, id)

## 显示消耗类通知 (红色) — 兼容旧调用
func show_consume(text: String, duration: float = DEFAULT_DURATION, id: String = "") -> void:
	show_message(text, duration, NotificationColor.CONSUME, id)

## 显示成功类通知 (绿色)
func show_success(text: String, duration: float = DEFAULT_DURATION, id: String = "") -> void:
	show_message(text, duration, NotificationColor.SUCCESS, id)

## 显示警告类通知 (橙色)
func show_warning(text: String, duration: float = DEFAULT_DURATION, id: String = "") -> void:
	show_message(text, duration, NotificationColor.WARNING, id)

## 显示错误类通知 (深红色) — GDD: ERROR
func show_error(text: String, duration: float = 3.5, id: String = "") -> void:
	show_message(text, duration, NotificationColor.ERROR, id)

## 显示系统类通知 (白色)
func show_system(text: String, duration: float = 2.0, id: String = "") -> void:
	show_message(text, duration, NotificationColor.SYSTEM, id)

## 显示信息类通知 (白色) — 用于一般提示/NPC对话/任务描述等
func show_info(text: String, duration: float = 2.5, id: String = "") -> void:
	show_message(text, duration, NotificationColor.SYSTEM, id)

## 显示带优先级的通知
func show_with_priority(text: String, duration: float = DEFAULT_DURATION, color: Color = NotificationColor.NORMAL, priority: int = 0, id: String = "") -> void:
	var notification = {
		"text": text,
		"duration": duration,
		"color": color,
		"priority": priority,
		"id": id
	}
	_add_to_queue(notification)

## 清除所有待处理通知
func clear_queue() -> void:
	_queue.clear()
	queue_changed.emit(_queue.size())
	if _debug_mode:
		print("[NotificationManager] Queue cleared")

## 获取队列长度
func get_queue_size() -> int:
	return _queue.size()

## 是否有正在显示的通知
func is_showing() -> bool:
	return _is_showing

# ============ 内部方法 ============

## 清理过期去重记录（从 _dedup_map 中移除超过 DEDUP_WINDOW 的条目）
func _cleanup_expired_dedup() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	var expired_keys: Array = []
	for id_key in _dedup_map:
		var entry = _dedup_map[id_key]
		if now - entry["time"] > DEDUP_WINDOW:
			expired_keys.append(id_key)
	for k in expired_keys:
		_dedup_map.erase(k)

## 添加到队列
func _add_to_queue(notification: Dictionary) -> void:
	var notif_id: String = notification.get("id", "")
	var current_time = Time.get_ticks_msec() / 1000.0

	# 去重逻辑：2秒内相同 id 合并
	if notif_id != "":
		_cleanup_expired_dedup()
		if _dedup_map.has(notif_id):
			var entry = _dedup_map[notif_id]
			entry["count"] = mini(entry["count"] + 1, 999)
			entry["time"] = current_time
			# 更新队列中已有同id通知的文本（显示合并计数）
			var merged_text = notification["text"]
			if entry["count"] > 1:
				merged_text = "%s x%d" % [notification["text"], entry["count"]]
			# 在队列中查找并更新文本
			for q in _queue:
				if q.get("id", "") == notif_id:
					q["text"] = merged_text
					break
			if _debug_mode:
				print("[NotificationManager] Dedup merged: id=%s, count=%d" % [notif_id, entry["count"]])
			queue_changed.emit(_queue.size())
			return  # 不重复入队

	# 如果队列已满，移除最旧的通知（优先移除低优先级）
	if _queue.size() >= MAX_QUEUE_SIZE:
		var removed = false
		# 先尝试移除最低优先级的
		var min_priority = 999
		var min_idx = -1
		for i in range(_queue.size()):
			if _queue[i]["priority"] < min_priority:
				min_priority = _queue[i]["priority"]
				min_idx = i
		if min_idx >= 0:
			_queue.remove_at(min_idx)
			removed = true
		if not removed:
			_queue.pop_front()
		if _debug_mode:
			print("[NotificationManager] Queue full, removing oldest/lowest priority")

	# 记录去重信息
	if notif_id != "":
		_dedup_map[notif_id] = {"time": current_time, "count": 1}

	# 按优先级插入 (高优先级在前)
	var inserted = false
	for i in range(_queue.size()):
		if notification["priority"] > _queue[i]["priority"]:
			_queue.insert(i, notification)
			inserted = true
			break

	if not inserted:
		_queue.append(notification)

	queue_changed.emit(_queue.size())

	# 如果没有正在显示且未暂停，开始显示
	if not _is_showing and not _is_paused:
		_show_next()

## 显示下一条通知
func _show_next() -> void:
	if _queue.is_empty():
		_is_showing = false
		return

	_is_showing = true
	var notification = _queue.pop_front()

	queue_changed.emit(_queue.size())
	_show_notification(
		notification["text"],
		notification["duration"],
		notification["color"]
	)

## 执行通知显示 - 委托给HUD
func _show_notification(text: String, duration: float, color: Color) -> void:
	notification_started.emit(text)

	# 查找HUD并使用其通知系统
	var hud = _find_hud()
	if hud and hud.has_method("show_message"):
		hud.show_message(text, color)
		# 等待duration后显示下一条
		await get_tree().create_timer(duration).timeout
		notification_finished.emit(text)
		_show_next()
	else:
		# 没有HUD，使用内置显示
		_show_fallback_notification(text, duration, color)

## 备用通知显示 (无HUD时)
func _show_fallback_notification(text: String, duration: float, color: Color) -> void:
	# 直接打印到控制台作为后备
	print("[Notification] " + text)
	notification_finished.emit(text)
	_show_next()

# ============ EventBus回调 ============

## EventBus通知信号处理
func _on_ui_notification(message: String, duration: float = DEFAULT_DURATION, priority: int = 0, id: String = "") -> void:
	show_with_priority(message, duration, NotificationColor.NORMAL, priority, id)

## EventBus notification_requested 信号处理（GDD 标准信号）
func _on_notification_requested(text: String, notif_type: int = 0, priority: int = 2, duration: float = DEFAULT_DURATION, id: String = "", icon_path: String = "") -> void:
	var color = NotificationColor.NORMAL
	match notif_type:
		0: color = NotificationColor.GAIN
		1: color = NotificationColor.COST
		2: color = NotificationColor.SUCCESS
		3: color = NotificationColor.WARNING
		4: color = NotificationColor.ERROR
		5: color = NotificationColor.SYSTEM
	show_with_priority(text, duration, color, priority, id)

## 暂停队列（收到 pause_requested 信号时）
func _on_pause_requested() -> void:
	_is_paused = true
	if _debug_mode:
		print("[NotificationManager] Paused")

## 恢复队列（收到 resume_requested 信号时）
func _on_resume_requested() -> void:
	_is_paused = false
	_is_draining = true
	if _debug_mode:
		print("[NotificationManager] Draining")
	# 立即尝试显示下一条（跳过淡入）
	_show_next()

# ============ 调试 ============

## 设置调试模式
func set_debug(enabled: bool) -> void:
	_debug_mode = enabled

## 调试: 测试通知（覆盖全部6种类型）
func debug_show_all_types() -> void:
	show_gain("+100 金币")
	await get_tree().create_timer(2.5).timeout
	show_cost("-10 体力")
	await get_tree().create_timer(2.5).timeout
	show_success("任务完成!")
	await get_tree().create_timer(2.5).timeout
	show_warning("背包已满")
	await get_tree().create_timer(2.5).timeout
	show_error("操作失败！")
	await get_tree().create_timer(2.5).timeout
	show_system("系统消息")
