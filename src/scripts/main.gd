extends Node2D
class_name MainScene

## Main - 主场景控制器
## 游戏主入口点，负责初始化和主循环

# ============ 节点引用 ============

@onready var time_label: Label = $UILayer/TimePanel/MarginContainer/VBox/TimeLabel
@onready var date_label: Label = $UILayer/TimePanel/MarginContainer/VBox/DateLabel
@onready var state_label: Label = $UILayer/TimePanel/MarginContainer/VBox/StateLabel
@onready var sleep_button: Button = $UILayer/SleepButton

# ============ 初始化 ============

func _ready() -> void:
	print("[Main] Game starting...")
	_initialize_game()

func _initialize_game() -> void:
	# 等待Autoload初始化
	await get_tree().process_frame

	# 检查必需的单例
	if not _verify_autoloads():
		push_error("[Main] Critical autoloads missing!")
		return

	print("[Main] All autoloads verified")

	# 连接UI信号
	_setup_ui_signals()

	# 初始化UI
	_update_ui()

	# 开始时间
	TimeManager.resume_time()

## 检查必需的单例
func _verify_autoloads() -> bool:
	var required_autoloads = [
		"GameManager",
		"TimeManager",
		"EventBus",
		"SaveManager",
		"AudioManager",
		"InventorySystem"
	]

	for autoload_name in required_autoloads:
		if not has_node("/root/" + autoload_name):
			push_error("[Main] Missing autoload: " + autoload_name)
			return false

	return true

## 设置UI信号
func _setup_ui_signals() -> void:
	if sleep_button:
		sleep_button.pressed.connect(_on_sleep_button_pressed)

	# 连接时间事件
	EventBus.time_changed.connect(_on_time_changed)
	EventBus.hour_changed.connect(_on_hour_changed)
	EventBus.day_changed.connect(_on_day_changed)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.time_paused.connect(_on_time_paused)
	EventBus.time_resumed.connect(_on_time_resumed)
	EventBus.sleep_triggered.connect(_on_sleep_triggered)

# ============ UI更新 ============

func _process(delta: float) -> void:
	_update_ui()

func _update_ui() -> void:
	if time_label:
		time_label.text = TimeManager.get_time_string()
	if date_label:
		date_label.text = TimeManager.get_date_string()
	if state_label:
		var state_name = TimeManager.TimeState.keys()[TimeManager.time_state]
		var period_name = TimeManager.get_time_period_name()
		state_label.text = "%s [%s]" % [state_name, period_name]

# ============ 输入处理 ============

func _input(event: InputEvent) -> void:
	# 空格键切换时间
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		_toggle_time()

	# R键重置时间
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		_reset_time()

	# P键加速时间
	if event.is_action_pressed("ui_focus_next"):
		_speed_up_time()

## 切换时间
func _toggle_time() -> void:
	if TimeManager.time_state == TimeManager.TimeState.TIME_RUNNING:
		TimeManager.pause_time()
	elif TimeManager.time_state == TimeManager.TimeState.TIME_PAUSED:
		TimeManager.resume_time()

## 重置时间
func _reset_time() -> void:
	TimeManager.pause_time()
	TimeManager.set_time(1, TimeManager.Season.SPRING, 1, 6)
	TimeManager.resume_time()
	print("[Main] Time reset")

## 加速时间
func _speed_up_time() -> void:
	match TimeManager.time_scale:
		1.0:
			TimeManager.set_time_scale(2.0)
			print("[Main] Time speed: 2x")
		2.0:
			TimeManager.set_time_scale(3.0)
			print("[Main] Time speed: 3x")
		3.0:
			TimeManager.set_time_scale(1.0)
			print("[Main] Time speed: 1x")

## 睡觉按钮
func _on_sleep_button_pressed() -> void:
	if TimeManager.time_state == TimeManager.TimeState.TIME_RUNNING:
		TimeManager.player_sleep()

# ============ 事件处理 ============

func _on_time_changed(day: int, hour: int, minute: int) -> void:
	print("[Main] Time changed: Day %d, %02d:00" % [day, hour])

func _on_hour_changed(hour: int) -> void:
	# 每小时检查一次午夜警告
	if hour == 24:
		_show_notification("午夜了！再不睡觉明天会很累！")

func _on_day_changed(day: int, season: String) -> void:
	print("[Main] New day: %s Day %d" % [season, day])
	_show_notification("新的一天开始了！")

func _on_season_changed(season: String, year: int) -> void:
	print("[Main] Season changed: %s, Year %d" % [season, year])
	_show_notification("季节变化: %s！" % season)

func _on_time_paused() -> void:
	print("[Main] Time paused")
	_show_notification("时间暂停")

func _on_time_resumed() -> void:
	print("[Main] Time resumed")

func _on_sleep_triggered(bedtime: int, forced: bool) -> void:
	if forced:
		_show_notification("体力耗尽，昏倒了！")
	else:
		var msg = "晚安！"
		if bedtime <= 24:
			msg = "好好休息！"
		elif bedtime <= 25:
			msg = "有点晚了..."
		else:
			msg = "太晚起床会没精神的！"
		_show_notification(msg)

# ============ 工具函数 ============

func _show_notification(message: String) -> void:
	# TODO: 实现通知UI
	print("[Notification] %s" % message)
