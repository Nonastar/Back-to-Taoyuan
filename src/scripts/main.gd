extends Node2D
class_name MainScene

## Main - 主场景控制器
## 游戏主入口点，负责初始化农场
## 鼠标点击交互模式

# ============ 常量 ============

const HUD_SCENE_PATH: String = "res://src/scenes/ui/HUD.tscn"
const NAV_PANEL_SCENE_PATH: String = "res://src/scenes/ui/NavigationPanel.tscn"

# ============ 节点引用 ============

var farm_manager: FarmManager
var sleep_button: Button
var hud: CanvasLayer
var nav_panel: CanvasLayer

# ============ 初始化 ============

func _ready() -> void:
	_setup_ui()
	_initialize_game()

func _setup_ui() -> void:
	# 获取睡觉按钮引用
	sleep_button = $UILayer/SleepButton
	if sleep_button:
		sleep_button.pressed.connect(_on_sleep_button_pressed)

func _initialize_game() -> void:
	await get_tree().process_frame

	# 检查必需的单例
	if not _verify_autoloads():
		push_error("[Main] Critical autoloads missing!")
		return

	print("[Main] All autoloads verified")

	# 动态加载 HUD 场景
	_load_hud()

	# 动态加载导航面板
	_load_navigation_panel()

	# 创建农场管理器
	_setup_farm()

	# 连接事件信号
	_setup_event_signals()

	# 添加初始物品
	_add_starting_items()

	# 开始时间
	TimeManager.resume_time()

## 运行时加载 HUD 场景
func _load_hud() -> void:
	var hud_scene = load(HUD_SCENE_PATH)
	if hud_scene:
		hud = hud_scene.instantiate() as CanvasLayer
		if hud:
			add_child(hud)
			print("[Main] HUD loaded from scene")
		else:
			push_error("[Main] Failed to instantiate HUD")
	else:
		push_error("[Main] Failed to load HUD scene: " + HUD_SCENE_PATH)

## 运行时加载导航面板
func _load_navigation_panel() -> void:
	var nav_scene = load(NAV_PANEL_SCENE_PATH)
	if nav_scene:
		nav_panel = nav_scene.instantiate() as CanvasLayer
		if nav_panel:
			add_child(nav_panel)
			print("[Main] NavigationPanel loaded from scene")
		else:
			push_error("[Main] Failed to instantiate NavigationPanel")
	else:
		push_error("[Main] Failed to load NavigationPanel scene: " + NAV_PANEL_SCENE_PATH)

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

func _add_starting_items() -> void:
	if InventorySystem:
		InventorySystem.add_item("tomato_seed", 15, 0)
		InventorySystem.add_item("carrot_seed", 10, 0)
		print("[Main] Starting items added")

# ============ 检查单例 ============

func _verify_autoloads() -> bool:
	var required = ["GameManager", "TimeManager", "EventBus", "InventorySystem", "PlayerStats", "SkillSystem", "NavigationSystem"]
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
