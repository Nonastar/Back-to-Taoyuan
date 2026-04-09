extends Node2D
class_name MainScene

## Main - 主场景控制器
## 游戏主入口点，负责初始化农场
## 鼠标点击交互模式

# ============ 节点引用 ============

var player: Node  # 简化的玩家控制器
var farm_manager: FarmManager

# UI 引用
var time_label: Label
var date_label: Label
var stamina_label: Label
var money_label: Label
var tool_label: Label
var seed_label: Label
var state_label: Label
var sleep_button: Button
var stats_label: Label

# ============ 初始化 ============

func _ready() -> void:
	_setup_ui()
	_initialize_game()

func _setup_ui() -> void:
	# 获取 UI 节点引用
	time_label = $UILayer/TimePanel/MarginContainer/VBox/TimeLabel
	date_label = $UILayer/TimePanel/MarginContainer/VBox/DateLabel
	state_label = $UILayer/TimePanel/MarginContainer/VBox/StateLabel
	stamina_label = $UILayer/StaminaPanel/MarginContainer/VBox/StaminaLabel
	money_label = $UILayer/MoneyPanel/MarginContainer/VBox/MoneyLabel
	tool_label = $UILayer/ToolPanel/MarginContainer/VBox/ToolLabel
	seed_label = $UILayer/SeedPanel/MarginContainer/VBox/SeedLabel
	sleep_button = $UILayer/SleepButton
	stats_label = $UILayer/StatsPanel/MarginContainer/VBox/StatsLabel

	if sleep_button:
		sleep_button.pressed.connect(_on_sleep_button_pressed)

func _initialize_game() -> void:
	await get_tree().process_frame

	# 检查必需的单例
	if not _verify_autoloads():
		push_error("[Main] Critical autoloads missing!")
		return

	print("[Main] All autoloads verified")

	# 创建农场管理器
	_setup_farm()

	# 创建玩家控制器
	_setup_player()

	# 连接事件信号
	_setup_event_signals()

	# 添加初始物品
	_add_starting_items()

	# 更新 UI
	_update_ui()

	# 开始时间
	TimeManager.resume_time()

func _setup_farm() -> void:
	farm_manager = FarmManager.new()
	farm_manager.name = "FarmManager"
	farm_manager.farm_name = "Home Farm"

	# 添加到 FarmLayer
	var farm_layer = $FarmLayer
	if farm_layer:
		farm_layer.add_child(farm_manager)
	else:
		add_child(farm_manager)

	print("[Main] FarmManager created")

func _setup_player() -> void:
	# Player 现在是 Autoload，不需要创建节点
	# 连接信号
	if Player.has_signal("tool_changed"):
		Player.tool_changed.connect(_on_tool_changed)
	if Player.has_signal("interaction_attempted"):
		Player.interaction_attempted.connect(_on_interaction_attempted)

	print("[Main] Player autoload connected")

func _add_starting_items() -> void:
	if InventorySystem:
		InventorySystem.add_item("tomato_seed", 15, 0)
		InventorySystem.add_item("carrot_seed", 10, 0)
		print("[Main] Starting items added")

# ============ 检查单例 ============

func _verify_autoloads() -> bool:
	var required = ["GameManager", "TimeManager", "EventBus", "InventorySystem", "PlayerStats"]
	for name in required:
		if not has_node("/root/" + name):
			push_error("[Main] Missing autoload: " + name)
			return false
	return true

# ============ 事件连接 ============

func _setup_event_signals() -> void:
	EventBus.hour_changed.connect(_on_hour_changed)
	EventBus.day_changed.connect(_on_day_changed)
	EventBus.sleep_triggered.connect(_on_sleep_triggered)

# ============ UI 更新 ============

func _process(delta: float) -> void:
	_update_ui()

func _update_ui() -> void:
	# 时间
	if time_label and TimeManager:
		time_label.text = TimeManager.get_time_string()
	if date_label and TimeManager:
		date_label.text = TimeManager.get_date_string()
	if state_label and TimeManager:
		var state_name = TimeManager.TimeState.keys()[TimeManager.time_state]
		state_label.text = state_name

	# 体力
	if stamina_label and PlayerStats:
		var stamina = PlayerStats.stamina
		var max_stamina = PlayerStats.get_max_stamina()
		stamina_label.text = "体力: %d/%d" % [stamina, max_stamina]

	# 金钱
	if money_label and PlayerStats:
		money_label.text = "金币: %d" % PlayerStats.money

	# 当前工具
	if tool_label and player:
		tool_label.text = "工具: %s" % Player.get_current_tool_name()

	# 种子数量
	if seed_label:
		var tomato_count = InventorySystem.get_item_count("tomato_seed") if InventorySystem else 0
		seed_label.text = "番茄: %d个" % tomato_count

	# 农场统计
	if stats_label and farm_manager:
		var stats = farm_manager.get_stats()
		stats_label.text = "已耕: %d | 作物: %d | 可收: %d" % [
			stats["tilled"], stats["planted"] + stats["growing"], stats["harvestable"]
		]

# ============ 输入处理 ============

func _input(event: InputEvent) -> void:
	# 空格 - 切换时间暂停
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		_toggle_time()

	# R - 重置时间
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		_reset_time()

	# P - 加速时间
	if event.is_action_pressed("ui_focus_next"):
		_speed_up_time()

func _toggle_time() -> void:
	if TimeManager.time_state == TimeManager.TimeState.TIME_RUNNING:
		TimeManager.pause_time()
	else:
		TimeManager.resume_time()

func _reset_time() -> void:
	TimeManager.pause_time()
	TimeManager.set_time(1, TimeManager.Season.SPRING, 1, 6)
	TimeManager.resume_time()

func _speed_up_time() -> void:
	match TimeManager.time_scale:
		1.0: TimeManager.set_time_scale(2.0)
		2.0: TimeManager.set_time_scale(3.0)
		3.0: TimeManager.set_time_scale(1.0)

func _on_sleep_button_pressed() -> void:
	if TimeManager.time_state == TimeManager.TimeState.TIME_RUNNING:
		TimeManager.player_sleep()

# ============ 事件处理 ============

func _on_hour_changed(hour: int) -> void:
	if hour == 24:
		print("[Main] 午夜了！")

func _on_day_changed(day: int, season: String) -> void:
	print("[Main] 新的一天: %s 第%d天" % [season, day])

func _on_sleep_triggered(bedtime: int, forced: bool) -> void:
	var msg = "晚安！" if not forced else "昏倒了..."
	print("[Main] %s" % msg)

	# 处理农场日常
	if farm_manager:
		farm_manager._process_day()

func _on_tool_changed(tool_type: int) -> void:
	var tool_names = {
		0: "锄头",
		1: "浇水壶",
		2: "种子",
		3: "手"
	}
	print("[Main] 工具切换: %s" % tool_names.get(tool_type, "?"))

func _on_interaction_attempted(position: Vector2) -> void:
	pass  # 可用于调试
