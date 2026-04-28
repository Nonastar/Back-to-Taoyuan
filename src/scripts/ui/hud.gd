extends CanvasLayer

## HUD - 游戏主界面
## 显示体力、金钱、时间、天气和工具快捷栏
## 参考: design/gdd/ui/hud-system.md

# ============ 常量 ============

## 快捷栏槽位数量 (设计要求12格)
const HOTBAR_SLOTS: int = 12

## 快捷键映射 (1-9, 0, -, =)
const HOTBAR_KEYS: Array = [
	KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9,
	KEY_0, KEY_MINUS, KEY_EQUAL
]

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
var tool_slots: Dictionary = {}  # index(int) -> slot_node(PanelContainer)
var selected_slot: int = 0

## QuickButtons节点
var quick_buttons: VBoxContainer
var button_inventory: PanelContainer
var button_map: PanelContainer
var button_quest: PanelContainer
var button_menu: PanelContainer
var button_shop: PanelContainer
var button_cooking: PanelContainer
var button_npc_friendship: PanelContainer
var button_hunting: PanelContainer
var button_museum: PanelContainer
var button_achievement: PanelContainer
var button_hidden_npc: PanelContainer

## 商店和烹饪面板引用
var shop_panel: Control = null
var cooking_panel: Control = null
var npc_friendship_panel: Control = null
var hunting_panel: Control = null
var quest_panel: Control = null
var museum_panel: Control = null
var achievement_panel: Control = null
var hidden_npc_panel: Control = null
const SHOP_SCENE_PATH: String = "res://src/scenes/ui/shop_panel.tscn"
const COOKING_SCENE_PATH: String = "res://src/scenes/ui/cooking_panel.tscn"
const NPC_FRIENDSHIP_SCENE_PATH: String = "res://src/scenes/ui/npc_friendship_panel.tscn"
const HUNTING_SCENE_PATH: String = "res://src/scenes/ui/hunting_panel.tscn"
const QUEST_SCENE_PATH: String = "res://src/scenes/ui/quest_panel.tscn"
const MUSEUM_SCENE_PATH: String = "res://src/scenes/ui/museum_panel.tscn"
const ACHIEVEMENT_SCENE_PATH: String = "res://src/scenes/ui/achievement_panel.tscn"
const HIDDEN_NPC_SCENE_PATH: String = "res://src/scenes/ui/hidden_npc_panel.tscn"

## 工具信息
const TOOL_EMOJIS: Array = ["🔨", "💧", "🌰", "✋"]
const TOOL_NAMES: Array = ["锄头", "浇水壶", "种子", "手"]

## 通知区域（多飘窗容器）
var notification_area: Control

## 地图容器（全屏地图浮层）
var _map_container: Control = null

## 库存面板引用 (动态加载)
var inventory_panel: CanvasLayer = null
const INVENTORY_SCENE_PATH: String = "res://src/scenes/ui/inventory_panel.tscn"

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

## 多飘窗系统状态
const MAX_VISIBLE_TOASTS: int = 3        # 最多同时显示条数
const TOAST_HEIGHT: float = 40.0         # 单条飘窗高度(px)
const TOAST_SPACING: float = 10.0         # 飘窗间距(px)
const FADE_IN_DURATION: float = 0.2      # 淡入时长(s)
const FLOAT_SPEED: float = 50.0           # 向上飘动速度(px/s)
const FADE_OUT_DURATION: float = 0.3     # 淡出时长(s)
const BASE_OFFSET_Y: float = 0.0         # 基准Y偏移

## 活跃飘窗: Array[{label:Label, timer:float, duration:float, state:int, float_y:float, id:String}]
## state: 0=showing, 1=fading, 2=removing
var _active_toasts: Array = []

## 活跃飘窗 id 索引: id → toast（用于显示中 dedup）
var _active_toast_ids: Dictionary = {}

## 正在处理队列（NM await 期间）：阻止 _process 移除 toast，防止时序问题
var _is_spawning: bool = false

# ============ 初始化 ============

func _ready() -> void:
	_setup_node_references()
	_connect_signals()
	# 注册到 group，供 NotificationManager 等系统查找
	add_to_group("hud")
	# 延迟初始化，等待 Autoload 系统就绪
	await get_tree().process_frame
	_update_from_systems()

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
	for i in range(HOTBAR_SLOTS):
		var slot = hotbar.get_node_or_null("Slot_%d" % i)
		if slot:
			tool_slots[i] = slot
			# 连接鼠标点击信号
			slot.gui_input.connect(_on_slot_input.bind(i))

	# QuickButtons节点
	quick_buttons = $QuickButtons
	button_inventory = quick_buttons.get_node_or_null("BtnInventory") if quick_buttons else null
	button_map = quick_buttons.get_node_or_null("BtnMap") if quick_buttons else null
	button_quest = quick_buttons.get_node_or_null("BtnQuest") if quick_buttons else null
	button_menu = quick_buttons.get_node_or_null("BtnMenu") if quick_buttons else null
	button_shop = quick_buttons.get_node_or_null("BtnShop") if quick_buttons else null
	button_cooking = quick_buttons.get_node_or_null("BtnCooking") if quick_buttons else null
	button_npc_friendship = quick_buttons.get_node_or_null("BtnFriendship") if quick_buttons else null
	button_hunting = quick_buttons.get_node_or_null("BtnHunting") if quick_buttons else null
	button_museum = quick_buttons.get_node_or_null("BtnMuseum") if quick_buttons else null
	button_achievement = quick_buttons.get_node_or_null("BtnAchievement") if quick_buttons else null
	button_hidden_npc = quick_buttons.get_node_or_null("BtnHiddenNpc") if quick_buttons else null

	# 连接按钮点击信号
	if button_inventory:
		button_inventory.gui_input.connect(_on_quick_button_input.bind("inventory"))
	if button_map:
		button_map.mouse_filter = Control.MOUSE_FILTER_STOP
		button_map.gui_input.connect(_on_quick_button_input.bind("map"))
	if button_quest:
		button_quest.mouse_filter = Control.MOUSE_FILTER_STOP
		button_quest.gui_input.connect(_on_quick_button_input.bind("quest"))
	if button_menu:
		button_menu.mouse_filter = Control.MOUSE_FILTER_STOP
		button_menu.gui_input.connect(_on_quick_button_input.bind("menu"))
	if button_shop:
		button_shop.mouse_filter = Control.MOUSE_FILTER_STOP
		button_shop.gui_input.connect(_on_quick_button_input.bind("shop"))
	if button_cooking:
		button_cooking.mouse_filter = Control.MOUSE_FILTER_STOP
		button_cooking.gui_input.connect(_on_quick_button_input.bind("cooking"))
	if button_npc_friendship:
		button_npc_friendship.mouse_filter = Control.MOUSE_FILTER_STOP
		button_npc_friendship.gui_input.connect(_on_quick_button_input.bind("npc_friendship"))
	if button_hunting:
		button_hunting.mouse_filter = Control.MOUSE_FILTER_STOP
		button_hunting.gui_input.connect(_on_quick_button_input.bind("hunting"))
	if button_museum:
		button_museum.mouse_filter = Control.MOUSE_FILTER_STOP
		button_museum.gui_input.connect(_on_quick_button_input.bind("museum"))
	if button_achievement:
		button_achievement.mouse_filter = Control.MOUSE_FILTER_STOP
		button_achievement.gui_input.connect(_on_quick_button_input.bind("achievement"))
	if button_hidden_npc:
		button_hidden_npc.mouse_filter = Control.MOUSE_FILTER_STOP
		button_hidden_npc.gui_input.connect(_on_quick_button_input.bind("hidden_npc"))

	# 通知区域
	notification_area = $NotificationArea

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
		if EventBus.has_signal("time_hour_changed"):
			EventBus.time_hour_changed.connect(_on_hour_changed)
		if EventBus.has_signal("time_changed"):
			EventBus.time_changed.connect(_on_time_changed)
		if EventBus.has_signal("time_day_changed"):
			EventBus.time_day_changed.connect(_on_day_changed)
		if EventBus.has_signal("ui_notification"):
			EventBus.ui_notification.connect(_on_ui_notification)
		if EventBus.has_signal("farm_message"):
			EventBus.farm_message.connect(_on_farm_message)
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

	# SkillSystem 信号
	if SkillSystem and SkillSystem.has_signal("exp_changed"):
		SkillSystem.exp_changed.connect(_on_skill_exp_changed)
	if SkillSystem and SkillSystem.has_signal("skill_level_up"):
		SkillSystem.skill_level_up.connect(_on_skill_level_up)

	# Player 工具变化信号
	var player = _get_player()
	if player and player.has_signal("tool_changed"):
		player.tool_changed.connect(_on_tool_changed)

## 获取 Player 节点
func _get_player() -> Node:
	var player = get_node_or_null("/root/Main/Player")
	if player != null:
		return player
	player = get_node_or_null("/root/Player")
	if player != null:
		print("[HUD] Found Player at /root/Player")
	else:
		print("[HUD] Player not found at /root/Player")
	return player

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

func _on_day_changed(day: int, season: String, year: int) -> void:
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
	# Hotbar 仅在农场场景显示
	if hotbar:
		hotbar.visible = (new_group == NavigationSystem.LocationGroup.FARM) if NavigationSystem else false

func _on_panel_changed(panel_key: String) -> void:
	_update_location_display()
	_refresh_map_location_markers()
	_update_map_current_location_row()

## 刷新地图界面的"当前位置"标记
func _refresh_map_location_markers() -> void:
	if not _map_container:
		return
	var panel = _map_container.get_node_or_null("MapPanel/VBox")
	if not panel:
		return
	# 遍历所有 HBoxContainer（位置行），更新状态标签
	for i in range(panel.get_child_count()):
		var child = panel.get_child(i)
		if not (child is VBoxContainer):
			continue
		for j in range(child.get_child_count()):
			var row = child.get_child(j)
			if not (row is HBoxContainer) or row.get_child_count() < 3:
				continue
			# 取 emoji、name、status 三列
			var name_lbl = row.get_child(1) if row.get_child_count() >= 2 else null
			var status_lbl = row.get_child(2) if row.get_child_count() >= 3 else null
			if not (name_lbl is Label) or not (status_lbl is Label):
				continue
			# 从 name_lbl.text 匹配 panel_key
			var panel_key_candidate = name_lbl.text
			var matched_key = ""
			if NavigationSystem:
				for pk in NavigationSystem.PANELS:
					var info = NavigationSystem.PANELS[pk]
					if info.get("name", "") == panel_key_candidate:
						matched_key = pk
						break
			if matched_key.is_empty():
				continue
			var is_current = NavigationSystem.current_panel == matched_key
			if is_current:
				status_lbl.text = "← 当前位置"
				status_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			else:
				var can_access = NavigationSystem.can_navigate_to(matched_key)
				if can_access:
					var cost = NavigationSystem.get_travel_cost(matched_key)
					var stamina = cost.get("stamina_cost", 0)
					if stamina > 0:
						status_lbl.text = "⚡%d" % stamina
					else:
						status_lbl.text = "✅"
					status_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
				else:
					status_lbl.text = "❌"
					status_lbl.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))

## 刷新地图界面顶部的"当前位置: xxx"文字
func _update_map_current_location_row() -> void:
	if not _map_container:
		return
	var vbox = _map_container.get_node_or_null("MapPanel/VBox")
	if not vbox:
		return
	var current_row = vbox.get_node_or_null("CurrentLocationRow")
	if not current_row:
		return
	var lbl = current_row.get_node_or_null("CurrentLocationLabel")
	if not lbl:
		return
	lbl.text = "📍 当前位置: %s %s" % [
		NavigationSystem.get_current_group_emoji() if NavigationSystem else "🏠",
		NavigationSystem.get_current_panel_name() if NavigationSystem else "农场"
	]

func _on_tool_changed(tool_type: int) -> void:
	_select_slot(tool_type)

func _on_skill_exp_changed(skill_type: int, current_exp: int, exp_gained: int) -> void:
	_update_skill_display()

func _on_farm_message(msg: String) -> void:
	_show_notification(msg)

func _on_farming_exp_changed(skill_type: int, exp: int, leveled_up: bool) -> void:
	_update_skill_display()

func _on_skill_level_up(skill_type: int, old_level: int, new_level: int) -> void:
	_update_skill_display()
	if SkillSystem:
		var skill_name = SkillSystem.SKILL_NAMES.get(skill_type, "未知")
		if NotificationManager:
			NotificationManager.show_gain("🌟 %s 升级！Lv.%d" % [skill_name, new_level])

func _on_ui_notification(message: String, duration: float = 2.0, priority: int = 0) -> void:
	_show_notification(message)

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
		_current_season = TimeManager.SEASON_NAMES[TimeManager.current_season]
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

	# 更新农耕技能
	var farming_type = SkillSystem.SkillType.FARMING
	var farming_level = SkillSystem.get_level(farming_type)
	var farming_exp_percent = SkillSystem.get_exp_percent(farming_type)
	var farming_current_exp = SkillSystem.get_exp(farming_type)

	var farming_name_label = skill_panel.get_node_or_null("SkillVBox/FarmingTitle/FarmingName") as Label
	if farming_name_label:
		farming_name_label.text = "农耕 Lv.%d" % farming_level

	var farming_exp_value = skill_panel.get_node_or_null("SkillVBox/FarmingExpContainer/FarmingExpValue") as Label
	if farming_exp_value:
		var next_level_exp = SkillSystem.EXP_TABLE[farming_level + 1] if farming_level < SkillSystem.MAX_LEVEL else SkillSystem.EXP_TABLE[SkillSystem.MAX_LEVEL]
		farming_exp_value.text = "%d/%d" % [farming_current_exp, next_level_exp]

	var farming_exp_bar = skill_panel.get_node_or_null("SkillVBox/FarmingExpBar") as ProgressBar
	if farming_exp_bar:
		farming_exp_bar.value = farming_exp_percent

	# 更新钓鱼技能
	var fishing_type = SkillSystem.SkillType.FISHING
	var fishing_level = SkillSystem.get_level(fishing_type)
	var fishing_exp_percent = SkillSystem.get_exp_percent(fishing_type)
	var fishing_current_exp = SkillSystem.get_exp(fishing_type)

	var fishing_name_label = skill_panel.get_node_or_null("SkillVBox/FishingTitle/FishingName") as Label
	if fishing_name_label:
		fishing_name_label.text = "钓鱼 Lv.%d" % fishing_level

	var fishing_exp_value = skill_panel.get_node_or_null("SkillVBox/FishingExpContainer/FishingExpValue") as Label
	if fishing_exp_value:
		var next_level_exp = SkillSystem.EXP_TABLE[fishing_level + 1] if fishing_level < SkillSystem.MAX_LEVEL else SkillSystem.EXP_TABLE[SkillSystem.MAX_LEVEL]
		fishing_exp_value.text = "%d/%d" % [fishing_current_exp, next_level_exp]

	var fishing_exp_bar = skill_panel.get_node_or_null("SkillVBox/FishingExpBar") as ProgressBar
	if fishing_exp_bar:
		fishing_exp_bar.value = fishing_exp_percent

func _select_slot(index: int) -> void:
	if not tool_slots.has(index):
		return

	var old_slot = selected_slot
	selected_slot = index
	_update_slot_style(old_slot)
	_update_slot_style(selected_slot)

func _update_hotbar_display() -> void:
	for index in tool_slots.keys():
		_update_slot_style(index)

func _update_slot_style(index: int) -> void:
	if not tool_slots.has(index):
		return

	var slot: PanelContainer = tool_slots[index]
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

# ============ 通知系统（多飘窗） ============

## 优先级打断阈值：>=3 可打断低优先级
const INTERRUPT_PRIORITY_THRESHOLD: int = 3

func _show_notification(text: String) -> void:
	if not NotificationManager:
		return
	# 根据消息内容分发到对应的颜色方法
	if _is_gain_message(text):
		NotificationManager.show_gain(text)
	elif _is_cost_message(text):
		NotificationManager.show_cost(text)
	else:
		NotificationManager.show_info(text)

## 判断是否为获取类消息（金色）
func _is_gain_message(text: String) -> bool:
	return text.begins_with("耕地完成") \
		or text.begins_with("浇水完成") \
		or text.begins_with("可以收获了") \
		or text.begins_with("播种成功") \
		or text.begins_with("收获成功") \
		or text.begins_with("施肥成功") \
		or text.begins_with("保湿土") \
		or text.begins_with("雨天自动浇水")

## 判断是否为消耗/失败类消息（红色）
func _is_cost_message(text: String) -> bool:
	return "没有种子了" in text \
		or "没有肥料了" in text \
		or "作物枯萎了" in text

func show_message(text: String, color: Color = Color(1, 1, 1), id: String = "", priority: int = 0) -> void:
	# 文本超长截断
	if text.length() > 100:
		text = text.substr(0, 100) + "..."
	# 检查正在显示的飘窗中是否有同 id：刷新计数 + 重置计时器
	if id != "":
		for t in _active_toasts:
			if t.get("id", "") == id:
				t["count"] = mini(t.get("count", 1) + 1, 999)
				var display_text = text if t["count"] <= 1 else ("%s x%d+" % [text, t["count"]]) if t["count"] >= 999 else "%s x%d" % [text, t["count"]]
				_refresh_active_toast(id, display_text, color)
				return
	_add_toast_queue({"text": text, "color": color, "priority": priority, "duration": 2.5, "id": id, "count": 1})

func show_toast(text: String, color: Color, priority: int, duration: float) -> void:
	_add_toast_queue({"text": text, "color": color, "priority": priority, "duration": duration})

func _add_toast_queue(notif: Dictionary) -> void:
	_notification_queue.append(notif)
	_process_toast_queue()

func _process_toast_queue() -> void:
	# 如果活跃飘窗已达上限，等待
	if _active_toasts.size() >= MAX_VISIBLE_TOASTS:
		return
	if _notification_queue.is_empty():
		return

	var notif = _notification_queue.pop_front()
	var notif_id = notif.get("id", "")

	# 队列中已有相同 id，不重复弹出
	if notif_id != "":
		for q in _notification_queue:
			if q.get("id", "") == notif_id:
				return  # 丢弃

	# 正在显示中有相同 id，跳过（刷新已在 show_message 中处理）
	if notif_id != "":
		for t in _active_toasts:
			if t.get("id", "") == notif_id:
				return

	_spawn_toast(notif["text"], notif["color"], notif.get("priority", 0), notif.get("duration", 2.5), notif_id, notif.get("count", 1))

## 优先级打断：priority>=3 可打断当前显示中的低优先级
func _try_interrupt_low_priority(incoming_priority: int) -> void:
	if incoming_priority < INTERRUPT_PRIORITY_THRESHOLD:
		return
	# 找最低优先级的正在显示的飘窗
	var min_idx = -1
	var min_priority = 999
	for i in range(_active_toasts.size()):
		var t = _active_toasts[i]
		if t["state"] == 0:  # 正在显示（非淡出）
			if t["priority"] < min_priority:
				min_priority = t["priority"]
				min_idx = i
	if min_idx >= 0 and min_priority < INTERRUPT_PRIORITY_THRESHOLD:
		_force_fade_out(min_idx)

func _spawn_toast(text: String, color: Color, priority: int, duration: float, id: String = "", count: int = 1) -> void:
	if not notification_area:
		return
	_is_spawning = true  # 阻止 _process 移除 toast
	if id != "":
		for t in _active_toasts:
			if t.get("id", "") == id:
				# 刷新已有 toast
				t["count"] = mini(t.get("count", 1) + 1, 999)
				var display_text = text if t["count"] <= 1 else ("%s x%d+" % [text, t["count"]]) if t["count"] >= 999 else "%s x%d" % [text, t["count"]]
				_refresh_active_toast(id, display_text, color)
				_is_spawning = false
				return

	# 文本超长截断
	var display_text_new = text
	if display_text_new.length() > 100:
		display_text_new = display_text_new.substr(0, 100) + "..."

	# 优先级打断检查
	_try_interrupt_low_priority(priority)

	# 创建飘窗 Label
	var label = Label.new()
	label.text = display_text_new
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 100

	# 样式：背景根据类型决定
	var bg = StyleBoxFlat.new()
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_right = 8
	bg.corner_radius_bottom_left = 8
	bg.content_margin_left = 16
	bg.content_margin_right = 16
	bg.content_margin_top = 8
	bg.content_margin_bottom = 8

	if priority >= INTERRUPT_PRIORITY_THRESHOLD:
		bg.bg_color = Color(0, 0, 0, 0.85)  # 高优先级带背景
	else:
		bg.bg_color = Color(0, 0, 0, 0)     # 普通无背景

	label.add_theme_stylebox_override("normal", bg)
	label.add_theme_color_override("font_color", color)

	# 初始位置：容器内 Y=0（居中偏上）
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = -250.0
	label.offset_right = 250.0
	label.offset_top = -20.0
	label.offset_bottom = 20.0
	label.grow_horizontal = 2
	label.grow_vertical = 2
	label.modulate.a = 0.0  # 初始透明

	notification_area.add_child(label)

	# 记录活跃飘窗
	var toast = {
		"label": label,
		"priority": priority,
		"duration": duration,
		"state": 0,         # 0=showing, 1=fading, 2=removing
		"elapsed": 0.0,
		"float_y": 0.0,
		"id": id,
		"count": count
	}
	_active_toasts.append(toast)
	if id != "":
		_active_toast_ids[id] = toast

	# 立即执行淡入
	_apply_fade_in(toast)

	# 排列所有活跃飘窗位置（最新在下层）
	_reorder_toasts()

	# 启动显示计时
	toast["state"] = 0
	_is_spawning = false  # 允许 _process 移除 toast

## 刷新显示中飘窗的文本并重置计时器
func _refresh_active_toast(id: String, display_text: String, color: Color) -> void:
	if not _active_toast_ids.has(id):
		return
	var toast = _active_toast_ids[id]
	toast["label"].text = display_text
	# 重置字体颜色（以防颜色不同）
	toast["label"].add_theme_color_override("font_color", color)
	toast["elapsed"] = 0.0
	toast["state"] = 0  # 重置为显示状态，重新开始计时
	# 停止旧 tween，重置透明度并淡入
	var old_tween = toast.get("tween")
	if old_tween:
		old_tween.kill()
	toast.erase("tween")
	var new_tween = create_tween()
	new_tween.tween_property(toast["label"], "modulate:a", 1.0, FADE_IN_DURATION)
	toast["tween"] = new_tween

func _apply_fade_in(toast: Dictionary) -> void:
	var tween = create_tween()
	tween.tween_property(toast["label"], "modulate:a", 1.0, FADE_IN_DURATION)
	toast["tween"] = tween

## 重新排列所有活跃飘窗位置（从上到下堆叠，最新的在最上）
func _reorder_toasts() -> void:
	# 按添加顺序（_active_toasts 顺序），最新在末尾
	# Y 偏移：最新（最上）的 toast 在 BASE_OFFSET_Y，旧的向下排
	var n = _active_toasts.size()
	for i in range(n):
		# i=0 最旧（底部），i=n-1 最新（顶部）
		var toast = _active_toasts[i]
		if toast["state"] == 2:  # 已移除，跳过
			continue
		var base_y = BASE_OFFSET_Y + i * (TOAST_HEIGHT + TOAST_SPACING)
		# 设置 label 的 offset_top/bottom
		toast["label"].offset_top = base_y
		toast["label"].offset_bottom = base_y + TOAST_HEIGHT

## 强制淡出（被高优先级打断）
func _force_fade_out(idx: int) -> void:
	if idx < 0 or idx >= _active_toasts.size():
		return
	var toast = _active_toasts[idx]
	if toast["state"] == 2:
		return
	toast["state"] = 2  # 标记淡出中
	var tween = create_tween()
	tween.tween_property(toast["label"], "modulate:a", 0.0, FADE_OUT_DURATION)
	toast["tween"] = tween
	tween.tween_callback(_on_toast_fade_complete.bind(idx))

func _on_toast_fade_complete(idx: int) -> void:
	# 移除飘窗 Label
	if idx < _active_toasts.size():
		var toast = _active_toasts[idx]
		if toast["label"] and toast["label"].is_inside_tree():
			toast["label"].queue_free()
		var toast_id = toast.get("id", "")
		if toast_id != "" and _active_toast_ids.has(toast_id):
			_active_toast_ids.erase(toast_id)
		_active_toasts.remove_at(idx)
		# 重新排列剩余飘窗
		_reorder_toasts()
		# 处理队列中的下一条
		_process_toast_queue()

func _process(delta: float) -> void:
	# 处理所有活跃飘窗的计时
	var to_remove: Array[int] = []

	for i in range(_active_toasts.size()):
		var toast = _active_toasts[i]
		if toast["state"] == 2:  # 正在淡出，跳过
			continue

		toast["elapsed"] += delta

		if toast["state"] == 0:  # 正在显示
			# 向上飘动
			toast["float_y"] += FLOAT_SPEED * delta
			toast["label"].offset_top += FLOAT_SPEED * delta
			toast["label"].offset_bottom += FLOAT_SPEED * delta

			# 检查是否该开始淡出
			var time_in_toast = toast["elapsed"]
			var fade_out_start = toast["duration"] - FADE_OUT_DURATION
			if time_in_toast >= fade_out_start and time_in_toast < toast["duration"]:
				# 开始淡出
				toast["state"] = 1
				var tween = create_tween()
				tween.tween_property(toast["label"], "modulate:a", 0.0, FADE_OUT_DURATION)
				toast["tween"] = tween

		# 检查是否完全结束（_is_spawning 期间跳过，防止 NM await 窗口内 toast 被提前移除）
		if not _is_spawning and toast["elapsed"] >= toast["duration"]:
			toast["state"] = 2  # 标记移除
			var t = toast.get("tween")
			if t:
				t.kill()
			if toast["label"].is_inside_tree():
				toast["label"].queue_free()
			var toast_id = toast.get("id", "")
			if toast_id != "" and _active_toast_ids.has(toast_id):
				_active_toast_ids.erase(toast_id)
			to_remove.append(i)

	# 移除已结束的飘窗
	for i in range(to_remove.size() - 1, -1, -1):
		_active_toasts.remove_at(to_remove[i])
	_reorder_toasts()
	_process_toast_queue()

# ============ 输入处理 ============

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# 检查快捷键映射
		for i in range(HOTBAR_KEYS.size()):
			if event.keycode == HOTBAR_KEYS[i]:
				_on_hotbar_key(i)
				return

		# QuickButtons 快捷键
		match event.keycode:
			KEY_B: _on_quick_button_pressed("inventory")
			KEY_M: _on_quick_button_pressed("map")
			KEY_J: _on_quick_button_pressed("npc_friendship")
			KEY_ESCAPE: _on_quick_button_pressed("menu")
			KEY_V: _on_quick_button_pressed("shop")
			KEY_C: _on_quick_button_pressed("cooking")
			KEY_H: _on_quick_button_pressed("hunting")
			KEY_Q: _on_quick_button_pressed("quest")
			KEY_I: _on_quick_button_pressed("museum")
			KEY_L: _on_quick_button_pressed("achievement")
			KEY_K: _on_quick_button_pressed("hidden_npc")

func _on_hotbar_key(index: int) -> void:
	if index < 0 or index >= HOTBAR_SLOTS or not tool_slots.has(index):
		return

	_select_slot(index)

	# 只切换有效的工具槽位 (0-4 对应工具, 5+ 是物品栏)
	var player = _get_player()
	if index < 5 and player and player.has_method("switch_tool"):
		player.switch_tool(index)

## 处理槽位点击
func _on_slot_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_slot_clicked(slot_index)

## 槽位被点击
func _on_slot_clicked(slot_index: int) -> void:
	if not tool_slots.has(slot_index):
		return

	# 选中槽位
	_select_slot(slot_index)

	# 只切换有效的工具槽位 (0-4 对应工具, 5+ 是物品栏)
	var player = _get_player()
	if slot_index < 5 and player and player.has_method("switch_tool"):
		player.switch_tool(slot_index)

	# 显示提示
	var tool_name = TOOL_NAMES[slot_index] if slot_index < TOOL_NAMES.size() else "未知"
	_show_notification("已选择: %s" % tool_name)

## QuickButtons 输入处理
func _on_quick_button_input(event: InputEvent, button_id: String) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_quick_button_pressed(button_id)

## QuickButton 被按下
func _on_quick_button_pressed(button_id: String) -> void:
	# 播放音效
	if AudioManager and AudioManager.has_method("play_ui_click"):
		AudioManager.play_ui_click()

	# 发送信号通知其他系统
	if EventBus and EventBus.has_signal("quick_button_pressed"):
		EventBus.quick_button_pressed.emit(button_id)

	# 显示提示
	match button_id:
		"inventory":
			_show_notification("📦 背包 (B)")
		"map":
			_show_notification("🗺️ 地图 (M)")
		"quest":
			_show_notification("📜 任务 (Q)")
		"npc_friendship":
			_show_notification("💬 NPC好感度 (J)")
		"menu":
			_show_notification("⚙️ 菜单 (ESC)")
		"shop":
			_show_notification("🏪 商店 (V)")
		"cooking":
			_show_notification("🍳 烹饪 (C)")
		"hunting":
			_show_notification("🏹 狩猎 (H)")
		"museum":
			_show_notification("🏛️ 博物馆 (I)")
		"achievement":
			_show_notification("⭐ 成就 (L)")
		"hidden_npc":
			_show_notification("✨ 仙灵 (K)")

	# 实际打开对应的UI面板
	match button_id:
		"inventory":
			_open_inventory()
		"map":
			_open_map()
		"quest":
			_open_quest()
		"npc_friendship":
			_open_npc_friendship()
		"menu":
			_open_menu()
		"shop":
			_open_shop()
		"cooking":
			_open_cooking()
		"hunting":
			_open_hunting()
		"museum":
			_open_museum()
		"achievement":
			_open_achievement()
		"hidden_npc":
			_open_hidden_npc()

## 打开背包UI (动态加载)
func _open_inventory() -> void:
	# 首次打开时动态加载
	if inventory_panel == null:
		var packed_scene = load(INVENTORY_SCENE_PATH)
		if packed_scene:
			inventory_panel = packed_scene.instantiate()
			add_child(inventory_panel)
			# 新实例 visible=true 但 is_visible=false，立即隐藏以避免 toggle 逻辑误判
			inventory_panel.visible = false
		else:
			push_error("[HUD] Failed to load inventory panel: " + INVENTORY_SCENE_PATH)
			return

	if inventory_panel.has_method("open_panel"):
		if inventory_panel.visible:
			inventory_panel.close_panel()
			if EventBus:
				EventBus.resume_requested.emit()
		else:
			if EventBus:
				EventBus.pause_requested.emit()
			inventory_panel.open_panel()
	else:
		inventory_panel.visible = not inventory_panel.visible

## 打开地图UI（全屏地图浮层）
func _open_map() -> void:
	if _map_container == null:
		_map_container = Control.new()
		_map_container.name = "MapContainer"
		_map_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		_map_container.z_index = 50
		_map_container.gui_input.connect(_on_map_container_input)
		add_child(_map_container)

		# 半透明背景（点击关闭地图）
		var bg = ColorRect.new()
		bg.name = "MapBG"
		bg.color = Color(0, 0, 0, 0.75)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.gui_input.connect(_on_map_bg_input)
		_map_container.add_child(bg)

		# 地图面板
		var map_panel = PanelContainer.new()
		map_panel.name = "MapPanel"
		map_panel.custom_minimum_size = Vector2(480, 560)
		map_panel.set_anchors_preset(Control.PRESET_CENTER)
		_map_container.add_child(map_panel)

		var vbox = VBoxContainer.new()
		vbox.name = "VBox"
		vbox.add_theme_constant_override("separation", 8)
		map_panel.add_child(vbox)

		# 标题
		var header = HBoxContainer.new()
		var title = Label.new()
		title.text = "🗺️ 地图"
		title.add_theme_font_size_override("font_size", 20)
		header.add_child(title)
		var close_btn = Button.new()
		close_btn.text = "X"
		close_btn.pressed.connect(_close_map)
		header.add_child(close_btn)
		header.add_theme_constant_override("separation", 10)
		vbox.add_child(header)

		# 分隔线
		var sep = HSeparator.new()
		sep.add_theme_constant_override("separation", 4)
		vbox.add_child(sep)

		# 当前区域高亮
		var current_row = HBoxContainer.new()
		current_row.name = "CurrentLocationRow"
		var current_label = Label.new()
		current_label.name = "CurrentLocationLabel"
		current_label.text = "📍 当前位置: %s %s" % [
			NavigationSystem.get_current_group_emoji() if NavigationSystem else "🏠",
			NavigationSystem.get_current_panel_name() if NavigationSystem else "农场"
		]
		current_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
		current_row.add_child(current_label)
		vbox.add_child(current_row)

		# 体力信息
		var stamina_row = HBoxContainer.new()
		var stamina_label = Label.new()
		var stamina = PlayerStats.stamina if PlayerStats else 0
		stamina_label.text = "⚡ 体力: %d" % stamina
		stamina_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.5))
		stamina_row.add_child(stamina_label)
		vbox.add_child(stamina_row)

		# 空标签
		var spacer = Control.new()
		spacer.custom_minimum_size.y = 4
		vbox.add_child(spacer)

		# 各区域列表
		var groups = ["farm", "village", "nature", "mine", "hanhai"]
		var emojis = {"farm": "🏠", "village": "🏘️", "nature": "🌲", "mine": "⛏️", "hanhai": "🏜️"}
		var names = {"farm": "农场", "village": "桃源村", "nature": "野外", "mine": "矿洞", "hanhai": "瀚海"}

		for grp in groups:
			var grp_vbox = VBoxContainer.new()
			# 组标题
			var grp_header = HBoxContainer.new()
			var grp_emoji = Label.new()
			grp_emoji.text = emojis.get(grp, "📍")
			grp_emoji.add_theme_font_size_override("font_size", 18)
			grp_header.add_child(grp_emoji)
			var grp_title = Label.new()
			grp_title.text = names.get(grp, grp)
			grp_title.add_theme_font_size_override("font_size", 16)
			grp_title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
			grp_header.add_child(grp_title)
			grp_vbox.add_child(grp_header)

			# 该组所有地点
			for panel_key in (NavigationSystem.PANELS if NavigationSystem else {}):
				var info = NavigationSystem.PANELS[panel_key] if NavigationSystem else {}
				if info.get("group", -1) != _group_name_to_enum(grp):
					continue
				var loc_row = _create_map_location_row(panel_key, info)
				grp_vbox.add_child(loc_row)

			vbox.add_child(grp_vbox)

	# 刷新显示
	if NavigationSystem:
		_refresh_map_current_location()
	_map_container.visible = true
	_map_container.z_index = 50
	if EventBus:
		EventBus.pause_requested.emit()

func _close_map() -> void:
	if _map_container:
		_map_container.visible = false
	if EventBus:
		EventBus.resume_requested.emit()

func _on_map_container_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_close_map()

func _on_map_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_map()

func _create_map_location_row(panel_key: String, info: Dictionary) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	var emoji_lbl = Label.new()
	emoji_lbl.text = info.get("emoji", "📍")
	emoji_lbl.custom_minimum_size.x = 24
	hbox.add_child(emoji_lbl)

	var name_lbl = Label.new()
	name_lbl.text = info.get("name", panel_key)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_lbl)

	var status_lbl = Label.new()
	var is_current = NavigationSystem and NavigationSystem.current_panel == panel_key
	var can_access = NavigationSystem and NavigationSystem.can_navigate_to(panel_key)

	if is_current:
		status_lbl.text = "← 当前位置"
		status_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	elif can_access:
		var cost = NavigationSystem.get_travel_cost(panel_key)
		var stamina = cost.get("stamina_cost", 0)
		if stamina > 0:
			status_lbl.text = "⚡%d" % stamina
		else:
			status_lbl.text = "✅"
		status_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
	else:
		status_lbl.text = "❌"
		status_lbl.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))

	# 始终连接点击信号（无论是否可访问），在回调中统一判断
	hbox.gui_input.connect(_on_map_location_input.bind(panel_key))

	hbox.add_child(status_lbl)
	return hbox

func _on_map_location_input(event: InputEvent, panel_key: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 室内场景直接加载
		if NavigationSystem:
			var panel_data = NavigationSystem.get_panel_info(panel_key)
			if panel_data.has("scene") and not panel_data["scene"].is_empty():
				# 是室内场景，走 SceneManager 加载
				if SceneManager:
					var success = SceneManager.load_interior(panel_key)
					if success:
						_close_map()
						if NotificationManager:
							NotificationManager.show_info("进入%s" % panel_data.get("name", panel_key))
					else:
						if NotificationManager:
							NotificationManager.show_warning("无法进入该地点")
				return

		# 关闭地图，再处理世界区域/旅行场景
		_close_map()

		# 世界区域（farm、village 等）
		if NavigationSystem and NavigationSystem.can_navigate_to(panel_key):
			var result = NavigationSystem.navigate_to_panel(panel_key)
			if result.get("success", false):
				# 如果当前在室内或已有世界，需要退出室内并加载对应的世界场景
				if SceneManager:
					if not SceneManager.current_interior.is_empty() or not SceneManager.current_world.is_empty():
						SceneManager.switch_world(panel_key)
				var minutes = int(result.get("time_cost", 0.0) * 60)
				var stamina = result.get("stamina_cost", 0)
				var panel_name = NavigationSystem.PANELS.get(panel_key, {}).get("name", panel_key)
				var msg = "前往%s" % panel_name
				if minutes > 0:
					msg += " (%d分钟" % minutes
					if stamina > 0:
						msg += ", %d体力)" % stamina
					else:
						msg += ")"
				if NotificationManager:
					NotificationManager.show_info(msg)
		else:
			if NotificationManager:
				var cost = NavigationSystem.get_travel_cost(panel_key) if NavigationSystem else {}
				var stamina_needed = cost.get("stamina_cost", 0) if cost else 0
				if stamina_needed > 0 and PlayerStats and PlayerStats.stamina < stamina_needed:
					NotificationManager.show_warning("体力不足 (需要%d点)" % stamina_needed)
				else:
					NotificationManager.show_warning("当前无法前往此处")

func _refresh_map_current_location() -> void:
	if not _map_container:
		return
	var panel = _map_container.get_node_or_null("MapPanel/VBox")
	if not panel:
		return
	# 刷新体力显示
	for i in range(panel.get_child_count()):
		var child = panel.get_child(i)
		if child is HBoxContainer and child.get_child_count() >= 1:
			var first_lbl = child.get_child(0)
			if first_lbl is Label and first_lbl.text.begins_with("⚡"):
				var stamina = PlayerStats.stamina if PlayerStats else 0
				first_lbl.text = "⚡ 体力: %d" % stamina
				break

func _group_name_to_enum(name: String) -> int:
	if NavigationSystem:
		match name:
			"farm": return NavigationSystem.LocationGroup.FARM
			"village": return NavigationSystem.LocationGroup.VILLAGE
			"nature": return NavigationSystem.LocationGroup.NATURE
			"mine": return NavigationSystem.LocationGroup.MINE
			"hanhai": return NavigationSystem.LocationGroup.HANHAI
	return 0

## 打开任务UI
func _open_quest() -> void:
	if quest_panel == null:
		var packed_scene = load(QUEST_SCENE_PATH)
		if packed_scene:
			quest_panel = packed_scene.instantiate()
			add_child(quest_panel)
			print("[HUD] Quest panel instantiated")
		else:
			push_error("[HUD] Failed to load quest panel: " + QUEST_SCENE_PATH)
			return

	if quest_panel.has_method("toggle_panel"):
		if EventBus:
			EventBus.pause_requested.emit()
		quest_panel.toggle_panel()
		if EventBus:
			EventBus.resume_requested.emit()
	else:
		quest_panel.visible = not quest_panel.visible

## 打开NPC好感度面板
func _open_npc_friendship() -> void:
	if npc_friendship_panel == null:
		var packed_scene = load(NPC_FRIENDSHIP_SCENE_PATH)
		if packed_scene:
			npc_friendship_panel = packed_scene.instantiate()
			add_child(npc_friendship_panel)
			print("[HUD] NPC Friendship panel instantiated")
		else:
			push_error("[HUD] Failed to load NPC Friendship panel: " + NPC_FRIENDSHIP_SCENE_PATH)
			return

	if npc_friendship_panel.has_method("toggle_panel"):
		if EventBus:
			EventBus.pause_requested.emit()
		npc_friendship_panel.toggle_panel()
		if EventBus:
			EventBus.resume_requested.emit()
	else:
		npc_friendship_panel.visible = not npc_friendship_panel.visible

## 打开菜单UI (占位，待实现)
func _open_menu() -> void:
	if EventBus:
		EventBus.pause_requested.emit()
	print("[HUD] Open menu - TODO: Implement menu UI")

## 打开商店UI
func _open_shop() -> void:
	print("[HUD] _open_shop called, shop_panel: ", shop_panel)
	if shop_panel == null:
		var packed_scene = load(SHOP_SCENE_PATH)
		if packed_scene:
			shop_panel = packed_scene.instantiate()
			add_child(shop_panel)
			print("[HUD] Shop panel instantiated")
		else:
			push_error("[HUD] Failed to load shop panel: " + SHOP_SCENE_PATH)
			return
	
	if shop_panel.has_method("open_panel"):
		if shop_panel.visible:
			print("[HUD] Closing shop panel")
			shop_panel.close_panel()
			if EventBus:
				EventBus.resume_requested.emit()
		else:
			print("[HUD] Opening shop panel")
			if EventBus:
				EventBus.pause_requested.emit()
			shop_panel.open_panel(0, 0)  # BUY mode, GENERAL store
	else:
		shop_panel.visible = not shop_panel.visible

## 打开烹饪UI
func _open_cooking() -> void:
	if cooking_panel == null:
		var packed_scene = load(COOKING_SCENE_PATH)
		if packed_scene:
			cooking_panel = packed_scene.instantiate()
			add_child(cooking_panel)
		else:
			push_error("[HUD] Failed to load cooking panel: " + COOKING_SCENE_PATH)
			return

	if cooking_panel.has_method("open_panel"):
		if cooking_panel.visible:
			cooking_panel.close_panel()
			if EventBus:
				EventBus.resume_requested.emit()
		else:
			if EventBus:
				EventBus.pause_requested.emit()
			cooking_panel.open_panel()
	else:
		cooking_panel.visible = not cooking_panel.visible

## 打开狩猎UI
func _open_hunting() -> void:
	if hunting_panel == null:
		var packed_scene = load(HUNTING_SCENE_PATH)
		if packed_scene:
			hunting_panel = packed_scene.instantiate()
			add_child(hunting_panel)
			print("[HUD] Hunting panel instantiated")
		else:
			push_error("[HUD] Failed to load hunting panel: " + HUNTING_SCENE_PATH)
			return

	if hunting_panel.has_method("toggle_panel"):
		if EventBus:
			EventBus.pause_requested.emit()
		hunting_panel.toggle_panel()
		if EventBus:
			EventBus.resume_requested.emit()
	else:
		hunting_panel.visible = not hunting_panel.visible

## 打开博物馆UI
func _open_museum() -> void:
	if museum_panel == null:
		var packed_scene = load(MUSEUM_SCENE_PATH)
		if packed_scene:
			museum_panel = packed_scene.instantiate()
			add_child(museum_panel)
			print("[HUD] Museum panel instantiated")
		else:
			push_error("[HUD] Failed to load museum panel: " + MUSEUM_SCENE_PATH)
			return

	if museum_panel.has_method("toggle_panel"):
		if EventBus:
			EventBus.pause_requested.emit()
		museum_panel.toggle_panel()
		if EventBus:
			EventBus.resume_requested.emit()
	else:
		museum_panel.visible = not museum_panel.visible

## 打开成就UI
func _open_achievement() -> void:
	if achievement_panel == null:
		var packed_scene = load(ACHIEVEMENT_SCENE_PATH)
		if packed_scene:
			achievement_panel = packed_scene.instantiate()
			add_child(achievement_panel)
			print("[HUD] Achievement panel instantiated")
		else:
			push_error("[HUD] Failed to load achievement panel: " + ACHIEVEMENT_SCENE_PATH)
			return

	if achievement_panel.has_method("toggle_panel"):
		if EventBus:
			EventBus.pause_requested.emit()
		achievement_panel.toggle_panel()
		if EventBus:
			EventBus.resume_requested.emit()
	else:
		achievement_panel.visible = not achievement_panel.visible

## 打开仙灵UI
func _open_hidden_npc() -> void:
	if hidden_npc_panel == null:
		var packed_scene = load(HIDDEN_NPC_SCENE_PATH)
		if packed_scene:
			hidden_npc_panel = packed_scene.instantiate()
			add_child(hidden_npc_panel)
			print("[HUD] Hidden NPC panel instantiated")
		else:
			push_error("[HUD] Failed to load hidden npc panel: " + HIDDEN_NPC_SCENE_PATH)
			return

	if hidden_npc_panel.has_method("toggle_panel"):
		if EventBus:
			EventBus.pause_requested.emit()
		hidden_npc_panel.toggle_panel()
		if EventBus:
			EventBus.resume_requested.emit()
	else:
		hidden_npc_panel.visible = not hidden_npc_panel.visible

# ============ 公共方法 ============

func get_selected_slot() -> int:
	return selected_slot
