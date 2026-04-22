extends Node

## NotificationManager - 通知管理系统
## 统一管理游戏中的所有飘字通知
## 参考: ADR-0002 Autoload系统设计

# ============ 常量 ============

## 通知配置
const DEFAULT_DURATION: float = 2.0
const MAX_QUEUE_SIZE: int = 10

## 通知颜色
class NotificationColor:
	const NORMAL: Color = Color(1, 1, 1, 1)
	const GAIN: Color = Color(1, 0.84, 0, 1)       # 金色 - 获取
	const CONSUME: Color = Color(0.91, 0.30, 0.24, 1)  # 红色 - 消耗
	const SUCCESS: Color = Color(0.18, 0.8, 0.44, 1)   # 绿色 - 成功
	const WARNING: Color = Color(0.95, 0.61, 0.07, 1)  # 橙色 - 警告
	const SYSTEM: Color = Color(0.7, 0.7, 0.9, 1)     # 蓝白色 - 系统

# ============ 状态 ============

## 通知队列
var _queue: Array[Dictionary] = []

## 是否正在显示
var _is_showing: bool = false

## HUD引用
var _hud: Control = null

## 调试模式
var _debug_mode: bool = false

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

## 查找HUD
func _find_hud() -> Control:
	if _hud == null:
		var root = get_tree().root
		_hud = root.find_child("HUD", true, false) as Control
	return _hud

# ============ 公共API ============

## 显示通知 (基础方法)
func show_message(text: String, duration: float = DEFAULT_DURATION, color: Color = NotificationColor.NORMAL) -> void:
	var notification = {
		"text": text,
		"duration": duration,
		"color": color,
		"priority": 0
	}
	_add_to_queue(notification)

## 显示获取类通知 (金色)
func show_gain(text: String, duration: float = DEFAULT_DURATION) -> void:
	show_message(text, duration, NotificationColor.GAIN)

## 显示消耗类通知 (红色)
func show_consume(text: String, duration: float = DEFAULT_DURATION) -> void:
	show_message(text, duration, NotificationColor.CONSUME)

## 显示成功类通知 (绿色)
func show_success(text: String, duration: float = DEFAULT_DURATION) -> void:
	show_message(text, duration, NotificationColor.SUCCESS)

## 显示警告类通知 (橙色)
func show_warning(text: String, duration: float = DEFAULT_DURATION) -> void:
	show_message(text, duration, NotificationColor.WARNING)

## 显示系统类通知 (蓝白色)
func show_system(text: String, duration: float = DEFAULT_DURATION) -> void:
	show_message(text, duration, NotificationColor.SYSTEM)

## 显示带优先级的通知
func show_with_priority(text: String, duration: float = DEFAULT_DURATION, color: Color = NotificationColor.NORMAL, priority: int = 0) -> void:
	var notification = {
		"text": text,
		"duration": duration,
		"color": color,
		"priority": priority
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

## 添加到队列
func _add_to_queue(notification: Dictionary) -> void:
	# 如果队列已满，移除最旧的通知
	if _queue.size() >= MAX_QUEUE_SIZE:
		_queue.pop_front()
		if _debug_mode:
			print("[NotificationManager] Queue full, removing oldest")

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

	# 如果没有正在显示，开始显示
	if not _is_showing:
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
	print("[NotificationManager] _show_notification: text=%s, hud=%s, has_show_message=%s" % [
		text, hud, hud.has_method("show_message") if hud else "N/A"])
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
func _on_ui_notification(message: String, duration: float = DEFAULT_DURATION, priority: int = 0) -> void:
	show_with_priority(message, duration, NotificationColor.NORMAL, priority)

# ============ 调试 ============

## 设置调试模式
func set_debug(enabled: bool) -> void:
	_debug_mode = enabled

## 调试: 测试通知
func debug_show_all_types() -> void:
	show_gain("+100 金币")
	await get_tree().create_timer(2.5).timeout
	show_consume("-10 体力")
	await get_tree().create_timer(2.5).timeout
	show_success("任务完成!")
	await get_tree().create_timer(2.5).timeout
	show_warning("背包已满")
	await get_tree().create_timer(2.5).timeout
	show_system("系统消息")
