extends CanvasLayer

## HUD - 游戏主界面
## 显示体力、金钱、时间、天气和工具快捷栏
## 参考: design/gdd/ui/hud-system.md

# ============ 常量 ============

## 工具数量
const TOOL_COUNT: int = 4

## 工具 Emoji 配置
const TOOL_EMOJIS: Dictionary = {
	0: "🔨",  # 锄头
	1: "💧",  # 浇水壶
	2: "🌰",  # 种子
	3: "✋"   # 手
}

## 工具名称
const TOOL_NAMES: Dictionary = {
	0: "锄头",
	1: "浇水壶",
	2: "种子",
	3: "手"
}

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

# ============ 节点引用 ============

## 顶部栏节点
var top_bar: HBoxContainer
var time_label: Label
var weather_label: Label
var money_label: Label
var stamina_bar: ProgressBar
var stamina_label: Label
var hp_bar: ProgressBar
var hp_label: Label

## 位置信息节点
var location_panel: PanelContainer
var location_label: Label
var date_label: Label
var season_label: Label

## 技能信息节点
var skill_panel: PanelContainer

## 快捷栏节点
var hotbar: HBoxContainer
var tool_slots: Array = []
var selected_slot: int = 0

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
	_setup_ui()
	_connect_signals()

	# 延迟初始化，等待 Autoload 系统就绪
	await get_tree().process_frame
	_update_from_systems()

	print("[HUD] Initialized")

func _setup_ui() -> void:
	# CanvasLayer 自动覆盖全屏，不需要设置锚点

	_create_top_bar()
	_create_location_info()
	_create_skill_panel()
	_create_hotbar()
	_create_notification_area()

	_update_display()

func _create_top_bar() -> void:
	# 顶部栏背景
	var top_bar_bg = ColorRect.new()
	top_bar_bg.name = "TopBarBG"
	top_bar_bg.color = Color(0, 0, 0, 0.5)
	top_bar_bg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar_bg.position = Vector2(0, 0)
	top_bar_bg.size = Vector2(1280, 50)
	add_child(top_bar_bg)

	# 顶部栏容器
	top_bar = HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_top = 5
	top_bar.offset_bottom = 50
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.custom_minimum_size = Vector2(0, 40)
	add_child(top_bar)

	# 时间显示
	var time_container = _create_info_container("时间")
	time_label = _create_label("06:00")
	time_label.add_theme_font_size_override("font_size", 18)
	time_container.add_child(time_label)
	top_bar.add_child(time_container)

	# 添加间距
	top_bar.add_child(_create_spacer(20))

	# 天气显示
	var weather_container = _create_info_container("天气")
	weather_label = _create_label("☀️")
	weather_label.add_theme_font_size_override("font_size", 20)
	weather_container.add_child(weather_label)
	top_bar.add_child(weather_container)

	top_bar.add_child(_create_spacer(20))

	# 金钱显示
	var money_container = _create_info_container("💰")
	money_label = _create_label("500")
	money_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))  # 金色
	money_label.add_theme_font_size_override("font_size", 16)
	money_container.add_child(money_label)
	top_bar.add_child(money_container)

	top_bar.add_child(_create_spacer(30))

	# 体力条
	var stamina_container = VBoxContainer.new()
	stamina_container.name = "StaminaContainer"
	stamina_container.alignment = BoxContainer.ALIGNMENT_CENTER

	var stamina_title = _create_label("体力")
	stamina_title.add_theme_font_size_override("font_size", 12)
	stamina_container.add_child(stamina_title)

	stamina_bar = _create_progress_bar()
	stamina_bar.custom_minimum_size = Vector2(120, 16)
	stamina_container.add_child(stamina_bar)

	stamina_label = _create_label("120/120")
	stamina_label.add_theme_font_size_override("font_size", 11)
	stamina_container.add_child(stamina_label)

	top_bar.add_child(stamina_container)

	top_bar.add_child(_create_spacer(20))

	# HP条
	var hp_container = VBoxContainer.new()
	hp_container.name = "HPContainer"
	hp_container.alignment = BoxContainer.ALIGNMENT_CENTER

	var hp_title = _create_label("HP")
	hp_title.add_theme_font_size_override("font_size", 12)
	hp_container.add_child(hp_title)

	hp_bar = _create_progress_bar()
	hp_bar.custom_minimum_size = Vector2(80, 16)
	hp_container.add_child(hp_bar)

	hp_label = _create_label("100/100")
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_container.add_child(hp_label)

	top_bar.add_child(hp_container)

func _create_location_info() -> void:
	# 位置信息面板
	location_panel = PanelContainer.new()
	location_panel.name = "LocationInfo"
	location_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	location_panel.offset_left = 10
	location_panel.offset_top = 660
	location_panel.offset_right = 200
	location_panel.offset_bottom = 720
	location_panel.add_theme_stylebox_override("panel", _create_panel_style())
	add_child(location_panel)

	var location_vbox = VBoxContainer.new()
	location_vbox.add_theme_constant_override("separation", 4)
	location_panel.add_child(location_vbox)

	# 位置名称
	var loc_container = HBoxContainer.new()
	var loc_icon = _create_label("📍")
	loc_icon.add_theme_font_size_override("font_size", 14)
	loc_container.add_child(loc_icon)
	loc_container.add_child(_create_spacer(4))
	location_label = _create_label("农场")
	location_label.add_theme_font_size_override("font_size", 14)
	loc_container.add_child(location_label)
	location_vbox.add_child(loc_container)

	# 日期
	var date_container = HBoxContainer.new()
	var date_icon = _create_label("📅")
	date_icon.add_theme_font_size_override("font_size", 14)
	date_container.add_child(date_icon)
	date_container.add_child(_create_spacer(4))
	date_label = _create_label("春第1天")
	date_label.add_theme_font_size_override("font_size", 14)
	date_container.add_child(date_label)
	location_vbox.add_child(date_container)

	# 季节
	var season_container = HBoxContainer.new()
	season_label = _create_label("🌸")
	season_label.add_theme_font_size_override("font_size", 20)
	season_container.add_child(season_label)
	location_vbox.add_child(season_container)

func _create_skill_panel() -> void:
	# 技能信息面板
	skill_panel = PanelContainer.new()
	skill_panel.name = "SkillPanel"
	skill_panel.position = Vector2(210, 650)
	skill_panel.custom_minimum_size = Vector2(170, 60)
	skill_panel.add_theme_stylebox_override("panel", _create_panel_style())
	add_child(skill_panel)

	var skill_vbox = VBoxContainer.new()
	skill_vbox.name = "SkillVBox"
	skill_vbox.add_theme_constant_override("separation", 2)
	skill_panel.add_child(skill_vbox)

	# 技能标题
	var skill_title = HBoxContainer.new()
	skill_title.name = "SkillTitle"
	var skill_icon = _create_label("🌾")
	skill_icon.add_theme_font_size_override("font_size", 14)
	skill_title.add_child(skill_icon)
	skill_title.add_child(_create_spacer(4))
	var skill_title_label = _create_label("农耕 Lv.0")
	skill_title_label.name = "SkillNameLabel"
	skill_title_label.add_theme_font_size_override("font_size", 14)
	skill_title.add_child(skill_title_label)
	skill_vbox.add_child(skill_title)

	# 经验条容器
	var exp_container = HBoxContainer.new()
	exp_container.name = "ExpContainer"
	skill_vbox.add_child(exp_container)

	# 经验标签
	var exp_label = Label.new()
	exp_label.name = "ExpLabel"
	exp_label.text = "经验: "
	exp_label.add_theme_font_size_override("font_size", 11)
	exp_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	exp_container.add_child(exp_label)

	# 经验值标签
	var exp_value_label = Label.new()
	exp_value_label.name = "ExpValueLabel"
	exp_value_label.text = "0/100"
	exp_value_label.add_theme_font_size_override("font_size", 11)
	exp_value_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))
	exp_container.add_child(exp_value_label)

	# 经验条
	var exp_bar = ProgressBar.new()
	exp_bar.name = "FarmingExpBar"
	exp_bar.max_value = 100
	exp_bar.value = 0
	exp_bar.custom_minimum_size = Vector2(150, 10)
	exp_bar.add_theme_color_override("fill", Color(0.18, 0.8, 0.44, 1))  # 绿色
	exp_bar.add_theme_color_override("background", Color(0.2, 0.2, 0.2, 0.8))
	skill_vbox.add_child(exp_bar)

func _create_hotbar() -> void:
	# 快捷栏容器
	var hotbar_bg = ColorRect.new()
	hotbar_bg.name = "HotbarBG"
	hotbar_bg.color = Color(0, 0, 0, 0.6)
	hotbar_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hotbar_bg.offset_bottom = 0
	hotbar_bg.size = Vector2(1280, 64)
	add_child(hotbar_bg)

	hotbar = HBoxContainer.new()
	hotbar.name = "Hotbar"
	hotbar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hotbar.offset_bottom = -10
	hotbar.offset_top = 0
	hotbar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(hotbar)

	# 创建4个工具槽
	for i in range(TOOL_COUNT):
		var slot = _create_tool_slot(i)
		tool_slots.append(slot)
		hotbar.add_child(slot)

func _create_tool_slot(index: int) -> PanelContainer:
	# 槽位背景
	var slot = PanelContainer.new()
	slot.name = "Slot_%d" % index
	slot.custom_minimum_size = Vector2(56, 56)

	# 设置默认/选中样式
	var default_style = _create_slot_style(false, index == selected_slot)
	var selected_style = _create_slot_style(true, true)

	slot.add_theme_stylebox_override("panel", default_style if index != selected_slot else selected_style)

	# 槽位内容
	var content = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER

	# 工具Emoji
	var emoji_label = Label.new()
	emoji_label.name = "Emoji"
	emoji_label.text = TOOL_EMOJIS.get(index, "?")
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_label.add_theme_font_size_override("font_size", 24)
	content.add_child(emoji_label)

	# 工具名称
	var name_label = Label.new()
	name_label.name = "Name"
	name_label.text = "[%d]%s" % [index + 1, TOOL_NAMES.get(index, "?")]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	content.add_child(name_label)

	slot.add_child(content)

	return slot

func _create_notification_area() -> void:
	notification_label = Label.new()
	notification_label.name = "Notification"
	notification_label.set_anchors_preset(Control.PRESET_CENTER)
	notification_label.offset_top = 80
	notification_label.offset_bottom = 110
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 16)
	notification_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	notification_label.modulate = Color(1, 1, 1, 0)  # 初始透明
	add_child(notification_label)

# ============ 辅助函数 ============

func _create_label(text: String = "") -> Label:
	var label = Label.new()
	label.text = text
	return label

func _create_spacer(size: int = 10) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size.x = size
	return spacer

func _create_info_container(icon: String = "") -> HBoxContainer:
	var container = HBoxContainer.new()
	if icon != "":
		var icon_label = _create_label(icon)
		icon_label.add_theme_font_size_override("font_size", 16)
		container.add_child(icon_label)
	return container

func _create_progress_bar() -> ProgressBar:
	var bar = ProgressBar.new()
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	return bar

func _create_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style

func _create_slot_style(is_selected: bool, highlight: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()

	if is_selected or highlight:
		style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
		style.border_color = Color(1, 0.84, 0, 1)  # 金色边框
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
	else:
		style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
		style.border_color = Color(0.3, 0.3, 0.4, 1)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1

	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4

	return style

# ============ 信号连接 ============

func _connect_signals() -> void:
	# PlayerStats 信号
	if PlayerStats and PlayerStats.has_signal("stamina_changed"):
		PlayerStats.stamina_changed.connect(_on_stamina_changed)
	if PlayerStats and PlayerStats.has_signal("hp_changed"):
		PlayerStats.hp_changed.connect(_on_hp_changed)
	if PlayerStats and PlayerStats.has_signal("money_changed"):
		PlayerStats.money_changed.connect(_on_money_changed)

	# TimeManager 信号
	if TimeManager and TimeManager.has_signal("day_changed"):
		TimeManager.day_changed.connect(_on_day_changed)

	# WeatherSystem 信号
	if WeatherSystem and WeatherSystem.has_signal("weather_changed"):
		WeatherSystem.weather_changed.connect(_on_weather_changed)

	# EventBus 信号
	if EventBus:
		if EventBus.has_signal("notification_requested"):
			EventBus.notification_requested.connect(_on_notification_requested)
		# 连接地块消息信号
		if EventBus.has_signal("plot_message_received"):
			EventBus.plot_message_received.connect(_on_plot_message_received)
		# 连接技能经验变化信号
		if EventBus.has_signal("farming_exp_changed"):
			EventBus.farming_exp_changed.connect(_on_farming_exp_changed)
		# 连接技能升级信号
		if EventBus.has_signal("skill_level_up"):
			EventBus.skill_level_up.connect(_on_skill_level_up)

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

func _on_time_changed(day: int, hour: int, minute: int) -> void:
	_current_time = hour
	_update_time_display()

func _on_weather_changed(new_weather: String, old_weather: String) -> void:
	_current_weather = new_weather
	_update_weather_display()

func _on_tool_changed(tool_type: int) -> void:
	_select_slot(tool_type)

func _on_plot_message_received(msg: String) -> void:
	# 显示地块操作消息
	_show_notification(msg)

func _on_farming_exp_changed(skill_type: int, exp: int, leveled_up: bool) -> void:
	# 技能经验变化时更新显示
	_update_skill_display()

func _on_skill_level_up(skill_type: int, old_level: int, new_level: int) -> void:
	# 更新技能显示
	_update_skill_display()

	# 显示升级提示
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

func _update_display() -> void:
	_update_time_display()
	_update_weather_display()
	_update_money_display()
	_update_stamina_display()
	_update_hp_display()
	_update_date_display()
	_update_skill_display()
	_update_hotbar_display()

func _update_time_display() -> void:
	if time_label:
		time_label.text = "%02d:00" % _current_time

func _update_weather_display() -> void:
	if weather_label:
		weather_label.text = WEATHER_EMOJIS.get(_current_weather, "☀️")

func _update_money_display() -> void:
	if money_label:
		# 格式化金钱
		var display_money = _money
		if display_money >= 10000:
			money_label.text = "%.1fK" % (display_money / 1000.0)
		else:
			money_label.text = str(display_money)

func _update_stamina_display() -> void:
	if stamina_bar:
		var percent = 0.0
		if _max_stamina > 0:
			percent = float(_current_stamina) / float(_max_stamina) * 100.0
		stamina_bar.value = percent

		# 根据百分比设置颜色
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

		# 根据百分比设置颜色
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

func _update_skill_display() -> void:
	if not skill_panel:
		return

	if not SkillSystem:
		return

	# 获取农耕技能信息
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

func _update_hotbar_display() -> void:
	for i in range(tool_slots.size()):
		_update_slot_style(i)

func _update_slot_style(index: int) -> void:
	if index >= tool_slots.size():
		return

	var slot = tool_slots[index]
	var is_selected = (index == selected_slot)
	slot.add_theme_stylebox_override("panel", _create_slot_style(is_selected, is_selected))

func _select_slot(index: int) -> void:
	if index < 0 or index >= tool_slots.size():
		return

	# 取消旧的选中
	var old_slot = selected_slot
	selected_slot = index
	_update_slot_style(old_slot)
	_update_slot_style(selected_slot)

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
	_notification_timer = 2.0  # 2秒后消失

	# 淡入
	var tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.2)

func _process(delta: float) -> void:
	if _notification_timer > 0:
		_notification_timer -= delta
		if _notification_timer <= 0:
			# 淡出
			var tween = create_tween()
			tween.tween_property(notification_label, "modulate:a", 0.0, 0.3)
			tween.tween_callback(_on_notification_finished)

func _on_notification_finished() -> void:
	if not _notification_queue.is_empty():
		_notification_queue.pop_front()
	_display_next_notification()

# ============ 输入处理 ============

func _input(event: InputEvent) -> void:
	# 工具快捷键 1-4
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

	# 通知Player切换工具
	if Player and Player.has_method("_switch_tool"):
		Player._switch_tool(index)

# ============ 公共方法 ============

## 显示提示消息
func show_message(text: String, color: Color = Color(1, 1, 1, 1)) -> void:
	notification_label.add_theme_color_override("font_color", color)
	_show_notification(text)

## 获取当前选中的工具槽
func get_selected_slot() -> int:
	return selected_slot
