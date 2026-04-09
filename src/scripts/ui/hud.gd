extends CanvasLayer

## HUD - 游戏主界面
## 显示体力、金钱、时间、天气和工具快捷栏
## 参考: design/gdd/ui/hud-system.md

# ============ 常量 ============

## 工具数量
const TOOL_COUNT: int = 4

## 天气 Emoji
const WEATHER_EMOJIS: Dictionary = {
	"sunny": "☀️",
	"rainy": "🌧️",
	"stormy": "⛈️",
	"snowy": "❄️",
	"windy": "💨",
	"green_rain": "💚"
}

## 季节 Emoji
const SEASON_EMOJIS: Dictionary = {
	"春": "🌸",
	"夏": "☀️",
	"秋": "🍂",
	"冬": "❄️"
}

## 体力条颜色
const STAMINA_COLORS: Dictionary = {
	"full": Color(0.18, 0.8, 0.44, 1),      # #2ECC71
	"good": Color(0.35, 0.84, 0.55, 1),    # #58D68D
	"warning": Color(0.95, 0.61, 0.07, 1), # #F39C12
	"danger": Color(0.91, 0.30, 0.24, 1)   # #E74C3C
}

## HP条颜色
const HP_COLORS: Dictionary = {
	"full": Color(0.91, 0.30, 0.24, 1),     # #E74C3C
	"danger": Color(0.75, 0.22, 0.17, 1)   # #C0392B
}

## 场景路径
const HUD_SCENE_PATH: String = "res://src/scenes/ui/HUD.tscn"

# ============ 节点引用 ============

## 顶部栏节点
var time_label: Label
var weather_label: Label
var money_label: Label
var stamina_bar: ProgressBar
var stamina_label: Label
var hp_bar: ProgressBar
var hp_label: Label

## 位置信息节点
var location_label: Label
var date_label: Label
var season_label: Label
var location_weather_icon: Label
var location_weather_label: Label
var region_label: Label

## 技能信息节点
var skill_panel: PanelContainer

## 快捷栏节点
var hotbar: HBoxContainer
var tool_slots: Array = []
var selected_slot: int = 0

## 工具信息
const TOOL_EMOJIS: Array = ["🔨", "💧", "🌰", "✋"]
const TOOL_NAMES: Array = ["锄头", "浇水壶", "种子", "手"]

## 通知标签
var notification_label: Label

## 状态追踪
var _current_stamina: int = 0
var _max_stamina: int = 100
var _current_hp: int = 100
var _max_hp: int = 100
var _money: int = 0
var _current_time: int = 6
var _current_day: int = 1
var _current_season: String = "春"
var _current_weather: String = "sunny"
var _notification_queue: Array = []
var _notification_timer: float = 0.0

# ============ 初始化 ============

func _ready() -> void:
	# 场景已通过 PackedScene 加载，无需再次实例化
	# 节点引用在 _setup_node_references() 中设置
	_setup_node_references()
	_connect_signals()

	# 延迟初始化，等待 Autoload 系统就绪
	await get_tree().process_frame
	_update_from_systems()

	print("[HUD] Initialized from scene")

## 设置节点引用
func _setup_node_references() -> void:
	# 顶部栏节点
	time_label = $TopBar/TimeContainer/TimeLabel
	weather_label = $TopBar/WeatherContainer/WeatherLabel
	money_label = $TopBar/MoneyContainer/MoneyLabel
	stamina_bar = $TopBar/StaminaContainer/StaminaBar
	stamina_label = $TopBar/StaminaContainer/StaminaBar/StaminaLabel
	hp_bar = $TopBar/HPContainer/HPBar
	hp_label = $TopBar/HPContainer/HPBar/HPLabel

	# 位置信息节点
	location_label = $LocationInfo/VBox/LocationRow/LocationLabel
	region_label = $LocationInfo/VBox/RegionRow/RegionLabel
	date_label = $LocationInfo/VBox/DateRow/DateLabel
	season_label = $LocationInfo/VBox/SeasonRow/SeasonLabel
	location_weather_icon = $LocationInfo/VBox/WeatherRow/WeatherIcon
	location_weather_label = $LocationInfo/VBox/WeatherRow/WeatherLabel

	# 技能信息节点
	skill_panel = $SkillPanel

	# 快捷栏节点
	hotbar = $Hotbar
	for i in range(TOOL_COUNT):
		var slot = hotbar.get_node_or_null("Slot_%d" % i)
		if slot:
			tool_slots.append(slot)
			# 连接鼠标点击信号
			slot.gui_input.connect(_on_slot_input.bind(i))

	# 通知标签
	notification_label = $Notification

	# 初始化槽位样式
	_update_hotbar_display()

# ============ 信号连接 ============

func _connect_signals() -> void:
	# PlayerStats 信号
	if PlayerStats and PlayerStats.has_signal("stamina_changed"):
		PlayerStats.stamina_changed.connect(_on_stamina_changed)
	if PlayerStats and PlayerStats.has_signal("hp_changed"):
		PlayerStats.hp_changed.connect(_on_hp_changed)
	if PlayerStats and PlayerStats.has_signal("money_changed"):
		PlayerStats.money_changed.connect(_on_money_changed)

	# EventBus 时间信号
	if EventBus:
		if EventBus.has_signal("hour_changed"):
			EventBus.hour_changed.connect(_on_hour_changed)
		if EventBus.has_signal("time_changed"):
			EventBus.time_changed.connect(_on_time_changed)
		if EventBus.has_signal("day_changed"):
			EventBus.day_changed.connect(_on_day_changed)
		if EventBus.has_signal("notification_requested"):
			EventBus.notification_requested.connect(_on_notification_requested)
		if EventBus.has_signal("plot_message_received"):
			EventBus.plot_message_received.connect(_on_plot_message_received)
		if EventBus.has_signal("farming_exp_changed"):
			EventBus.farming_exp_changed.connect(_on_farming_exp_changed)
		if EventBus.has_signal("skill_level_up"):
			EventBus.skill_level_up.connect(_on_skill_level_up)

	# WeatherSystem 信号
	if WeatherSystem and WeatherSystem.has_signal("weather_changed"):
		WeatherSystem.weather_changed.connect(_on_weather_changed)

	# NavigationSystem 信号
	if NavigationSystem and NavigationSystem.has_signal("location_changed"):
		NavigationSystem.location_changed.connect(_on_location_changed)
	if EventBus and EventBus.has_signal("panel_changed"):
		EventBus.panel_changed.connect(_on_panel_changed)

	# 初始更新技能显示
	_update_skill_display()

	# Player 工具变化信号
	if Player and Player.has_signal("tool_changed"):
		Player.tool_changed.connect(_on_tool_changed)

# ============ 信号回调 ============

func _on_stamina_changed(current: int, max_val: int) -> void:
	_current_stamina = current
	_max_stamina = max_val
	_update_stamina_display()

func _on_hp_changed(current: int, max_val: int) -> void:
	_current_hp = current
	_max_hp = max_val
	_update_hp_display()

func _on_money_changed(amount: int) -> void:
	_money = amount
	_update_money_display()

func _on_day_changed(day: int, season: String) -> void:
	_current_day = day
	_current_season = season
	_update_date_display()

func _on_hour_changed(hour: int) -> void:
	_current_time = hour
	_update_time_display()

func _on_time_changed(day: int, hour: int, minute: int) -> void:
	_current_time = hour
	_update_time_display()

func _on_weather_changed(new_weather: String, old_weather: String) -> void:
	_current_weather = new_weather
	_update_weather_display()

func _on_location_changed(new_group: int, old_group: int) -> void:
	_update_location_display()

func _on_panel_changed(panel_key: String) -> void:
	_update_location_display()

func _on_tool_changed(tool_type: int) -> void:
	_select_slot(tool_type)

func _on_plot_message_received(msg: String) -> void:
	_show_notification(msg)

func _on_farming_exp_changed(skill_type: int, exp: int, leveled_up: bool) -> void:
	_update_skill_display()

func _on_skill_level_up(skill_type: int, old_level: int, new_level: int) -> void:
	_update_skill_display()
	if SkillSystem:
		var skill_name = SkillSystem.SKILL_NAMES.get(skill_type, "未知")
		_show_notification("🌟 %s 升级！Lv.%d" % [skill_name, new_level])

func _on_notification_requested(text: String, type: String) -> void:
	_show_notification(text)

# ============ 显示更新 ============

func _update_from_systems() -> void:
	# 从系统获取初始值
	if PlayerStats:
		_current_stamina = PlayerStats.stamina
		_max_stamina = PlayerStats.get_max_stamina()
		_current_hp = PlayerStats.current_hp
		_max_hp = PlayerStats.get_max_hp()
		_money = PlayerStats.money

	if TimeManager:
		_current_day = TimeManager.current_day
		_current_season = TimeManager.SEASON_NAMES.get(TimeManager.current_season, "春")
		_current_time = TimeManager.current_hour

	if WeatherSystem:
		_current_weather = WeatherSystem.today_weather

	_update_display()
	_update_location_display()

func _update_display() -> void:
	_update_time_display()
	_update_weather_display()
	_update_money_display()
	_update_stamina_display()
	_update_hp_display()
	_update_date_display()
	_update_skill_display()

func _update_time_display() -> void:
	if time_label:
		time_label.text = "%02d:00" % _current_time

func _update_weather_display() -> void:
	if weather_label:
		weather_label.text = WEATHER_EMOJIS.get(_current_weather, "☀️")

	# 更新 LocationInfo 天气图标和名称
	if location_weather_icon:
		location_weather_icon.text = WEATHER_EMOJIS.get(_current_weather, "☀️")

	if location_weather_label:
		var weather_name = ""
		if WeatherSystem and WeatherSystem.has_method("get_weather_name"):
			weather_name = WeatherSystem.get_weather_name(_current_weather)
		else:
			weather_name = WEATHER_EMOJIS.get(_current_weather, "☀️")
		location_weather_label.text = weather_name

func _update_money_display() -> void:
	if money_label:
		var display_money = _money
		if display_money >= 10000:
			money_label.text = "💰 %.1fK" % (display_money / 1000.0)
		else:
			money_label.text = "💰 %d" % display_money

func _update_stamina_display() -> void:
	if stamina_bar:
		var percent = 0.0
		if _max_stamina > 0:
			percent = float(_current_stamina) / float(_max_stamina) * 100.0
		stamina_bar.value = percent

		var color: Color
		if percent >= 75:
			color = STAMINA_COLORS["full"]
		elif percent >= 50:
			color = STAMINA_COLORS["good"]
		elif percent >= 25:
			color = STAMINA_COLORS["warning"]
		else:
			color = STAMINA_COLORS["danger"]

		stamina_bar.add_theme_color_override("fill", color)

	if stamina_label:
		stamina_label.text = "%d/%d" % [_current_stamina, _max_stamina]

func _update_hp_display() -> void:
	if hp_bar:
		var percent = 0.0
		if _max_hp > 0:
			percent = float(_current_hp) / float(_max_hp) * 100.0
		hp_bar.value = percent

		var color: Color
		if percent >= 25:
			color = HP_COLORS["full"]
		else:
			color = HP_COLORS["danger"]

		hp_bar.add_theme_color_override("fill", color)

	if hp_label:
		hp_label.text = "%d/%d" % [_current_hp, _max_hp]

func _update_date_display() -> void:
	if date_label:
		date_label.text = "%s第%d天" % [_current_season, _current_day]

	if season_label:
		season_label.text = SEASON_EMOJIS.get(_current_season, "🌸")

func _update_location_display() -> void:
	if not NavigationSystem:
		return

	# 更新位置名称（当前面板）
	var panel_name = NavigationSystem.get_current_panel_name()
	var panel_emoji = NavigationSystem.get_current_panel_emoji()

	if location_label:
		location_label.text = panel_name

	# 更新区域名称（当前区域组）
	var region_name = NavigationSystem.get_current_group_name()
	var region_emoji = NavigationSystem.get_current_group_emoji()

	if region_label:
		region_label.text = "%s区域" % region_name

	# 更新区域图标
	var region_icon = $LocationInfo/VBox/RegionRow/RegionIcon if region_label else null
	if region_icon:
		region_icon.text = region_emoji

func _update_skill_display() -> void:
	if not skill_panel:
		return

	if not SkillSystem:
		return

	var farming_type = SkillSystem.SkillType.FARMING
	var level = SkillSystem.get_level(farming_type)
	var exp_percent = SkillSystem.get_exp_percent(farming_type)
	var current_exp = SkillSystem.get_exp(farming_type)

	# 更新技能名称标签
	var skill_name_label = skill_panel.get_node_or_null("SkillVBox/SkillTitle/SkillNameLabel") as Label
	if skill_name_label:
		skill_name_label.text = "农耕 Lv.%d" % level

	# 更新经验值标签
	var exp_value_label = skill_panel.get_node_or_null("SkillVBox/ExpContainer/ExpValueLabel") as Label
	if exp_value_label:
		var next_level_exp = SkillSystem.EXP_TABLE[level + 1] if level < SkillSystem.MAX_LEVEL else SkillSystem.EXP_TABLE[SkillSystem.MAX_LEVEL]
		exp_value_label.text = "%d/%d" % [current_exp, next_level_exp]

	# 更新经验条
	var exp_bar = skill_panel.get_node_or_null("SkillVBox/FarmingExpBar") as ProgressBar
	if exp_bar:
		exp_bar.value = exp_percent

func _select_slot(index: int) -> void:
	if index < 0 or index >= tool_slots.size():
		return

	var old_slot = selected_slot
	selected_slot = index
	_update_slot_style(old_slot)
	_update_slot_style(selected_slot)

func _update_hotbar_display() -> void:
	for i in range(tool_slots.size()):
		_update_slot_style(i)

func _update_slot_style(index: int) -> void:
	if index >= tool_slots.size():
		return

	var slot = tool_slots[index]
	var is_selected = (index == selected_slot)

	# 创建槽位样式
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4

	if is_selected:
		# 选中状态：深色背景 + 金色边框
		style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
		style.border_color = Color(1, 0.84, 0, 1)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
	else:
		# 默认状态：浅色背景 + 灰色边框
		style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
		style.border_color = Color(0.3, 0.3, 0.4, 1)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1

	slot.add_theme_stylebox_override("panel", style)

# ============ 通知系统 ============

func _show_notification(text: String) -> void:
	_notification_queue.append(text)
	if _notification_queue.size() == 1:
		_display_next_notification()

func _display_next_notification() -> void:
	if _notification_queue.is_empty():
		notification_label.modulate.a = 0
		return

	var text = _notification_queue[0]
	notification_label.text = text
	_notification_timer = 2.0

	var tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.2)

func _process(delta: float) -> void:
	if _notification_timer > 0:
		_notification_timer -= delta
		if _notification_timer <= 0:
			var tween = create_tween()
			tween.tween_property(notification_label, "modulate:a", 0.0, 0.3)
			tween.tween_callback(_on_notification_finished)

func _on_notification_finished() -> void:
	if not _notification_queue.is_empty():
		_notification_queue.pop_front()
	_display_next_notification()

# ============ 输入处理 ============

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _on_hotbar_key(0)
			KEY_2: _on_hotbar_key(1)
			KEY_3: _on_hotbar_key(2)
			KEY_4: _on_hotbar_key(3)

func _on_hotbar_key(index: int) -> void:
	if index < 0 or index >= tool_slots.size():
		return

	_select_slot(index)

	if Player and Player.has_method("_switch_tool"):
		Player._switch_tool(index)

## 处理槽位点击
func _on_slot_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_slot_clicked(slot_index)

## 槽位被点击
func _on_slot_clicked(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= tool_slots.size():
		return

	# 选中槽位
	_select_slot(slot_index)

	# 通知 Player 切换工具
	if Player and Player.has_method("_switch_tool"):
		Player._switch_tool(slot_index)

	# 显示提示
	var tool_name = TOOL_NAMES[slot_index] if slot_index < TOOL_NAMES.size() else "未知"
	_show_notification("已选择: %s" % tool_name)

# ============ 公共方法 ============

func show_message(text: String, color: Color = Color(1, 1, 1, 1)) -> void:
	notification_label.add_theme_color_override("font_color", color)
	_show_notification(text)

func get_selected_slot() -> int:
	return selected_slot
