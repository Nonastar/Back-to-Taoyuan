extends Node2D
class_name MainScene

## Main - 主场景控制器
## 游戏主入口点，负责初始化农场
## 鼠标点击交互模式

# ============ 常量 ============

const HUD_SCENE_PATH: String = "res://src/scenes/ui/HUD.tscn"
const NAV_PANEL_SCENE_PATH: String = "res://src/scenes/ui/NavigationPanel.tscn"

# ============ 节点引用 ============

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

	# 动态加载导航面板（先加载，后加入树的 UI 会覆盖先加入的）
	_load_navigation_panel()

	# 动态加载 HUD 场景
	_load_hud()

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

func _add_starting_items() -> void:
	if InventorySystem:
		# 种子
		InventorySystem.add_item("tomato_seed", 15, 0)
		# 肥料
		InventorySystem.add_item("basic_fertilizer", 5, 0)
		InventorySystem.add_item("quality_fertilizer", 2, 0)
		InventorySystem.add_item("growth_fertilizer", 2, 0)
		InventorySystem.add_item("moisture_fertilizer", 2, 0)
		InventorySystem.add_item("carrot_seed", 10, 0)
		# 鱼饵
		InventorySystem.add_item("bait_common", 10, 0)
		InventorySystem.add_item("bait_deluxe", 3, 0)
		InventorySystem.add_item("bait_legendary", 1, 0)
		# 建筑材料
		InventorySystem.add_item("wood", 100, 0)
		InventorySystem.add_item("bamboo", 50, 0)
		# 畜牧饲料
		InventorySystem.add_item("hay", 20, 0)
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
	if EventBus.has_signal("time_hour_changed"):
		EventBus.time_hour_changed.connect(_on_hour_changed)
	if EventBus.has_signal("time_day_changed"):
		EventBus.time_day_changed.connect(_on_day_changed)
	if EventBus.has_signal("time_sleep_triggered"):
		EventBus.time_sleep_triggered.connect(_on_sleep_triggered)

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

func _on_day_changed(day: int, season: String, year: int) -> void:
	print("[Main] 新的一天: " + season + " 第" + str(day) + "天")

func _on_sleep_triggered(bedtime: int, forced: bool) -> void:
	var msg = "晚安！" if not forced else "昏倒了..."
	print("[Main] " + msg)

	# 注意：农场日结算在 FarmManager._on_sleep_triggered 中处理
	# 这里不需要再次调用 farm_manager._process_day()
