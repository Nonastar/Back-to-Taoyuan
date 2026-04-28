class_name FishCompendiumUI
extends CanvasLayer

## FishCompendiumUI - 鱼类图鉴交互界面
## 显示所有鱼类的发现状态、捕获数量、难度和稀有度
## 与 FishCompendiumSystem 集成获取数据
## 与 FishingSystem 集成获取鱼类定义数据
##
## 依赖系统:
## - FishCompendiumSystem: 图鉴数据源
## - FishingSystem: 鱼类定义数据
## - NotificationManager: 通知显示

# ============ 常量 ============

## 布局常量
const PANEL_WIDTH: int = 600
const PANEL_HEIGHT: int = 500
const CARD_HEIGHT: int = 56
const TAB_BUTTON_SIZE: Vector2 = Vector2(70, 32)
const TAB_SPACING: int = 4

## 透明度常量
const UNDISCOVERED_OPACITY: float = 0.5

## 颜色常量
const COLOR_GOLD: Color = Color(0.8, 0.6, 0.2)
const COLOR_GOLD_BG: Color = Color(0.8, 0.6, 0.2, 0.2)
const COLOR_GOLD_BORDER: Color = Color(1, 0.84, 0, 0.8)

## 稀有度颜色
const RARITY_COLORS: Dictionary = {
	"common": Color(1, 1, 1, 1),       # 普通 - 白色
	"fine": Color(0.26, 0.65, 0.96, 1),  # 优质 - 蓝色
	"rare": Color(0.67, 0.28, 0.74, 1), # 精品 - 紫色
	"legendary": Color(1, 0.84, 0, 1)    # 传说 - 金色
}

## 悬停效果常量
const HOVER_BRIGHTNESS: float = 1.15

## 地点过滤器
const LOCATION_FILTERS: Array = ["全部", "鱼塘", "河流", "森林", "湖泊", "海洋", "沼泽", "秘密"]
const LOCATION_KEYS: Array = ["all", "fishpond", "river", "forest_pond", "mountain_lake", "ocean", "witch_swamp", "secret_pond"]

## 难度星级配置
const STAR_FILLED: String = "★"
const STAR_EMPTY: String = "☆"

## 鱼类 Emoji 映射（备用）
const FISH_EMOJI: Dictionary = {
	"bluegill": "🐟", "carp": "🐟", "frog": "🐸", "koi": "🐠",
	"catfish": "🐟", "trout": "🐟", "bass": "🐟", "snow_fish": "🐟",
	"golden_fish": "🐠", "eel": "🐍", "salmon": "🐟", "mountain_trout": "🐟",
	"ice_fish": "🐟", "magic_fish": "✨🐟", "swamp_creature": "🦎",
	"tuna": "🐟", "swordfish": "⚔️🐟", "shark": "🦈",
	"legendary_fish": "🐉", "mythical_fish": "🐲", "treasure_fish": "💎🐟"
}
const DEFAULT_EMOJI: String = "🐟"

# ============ 单例 ============

static var _instance: FishCompendiumUI = null

static func get_instance() -> FishCompendiumUI:
	return _instance

static func show_compendium_ui() -> void:
	if _instance == null:
		push_warning("[FishCompendiumUI] Instance not found")
		return
	_instance._show_ui()

static func hide_compendium_ui() -> void:
	if _instance == null:
		return
	_instance._hide_ui()

static func toggle() -> void:
	if _instance == null:
		return
	if _instance.visible:
		_instance._hide_ui()
	else:
		_instance._show_ui()

# ============ 节点引用 ============

var _background: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _progress_label: Label
var _progress_bar: ProgressBar
var _filter_scroll: ScrollContainer
var _filter_hbox: HBoxContainer
var _fish_scroll: ScrollContainer
var _fish_vbox: VBoxContainer
var _close_btn: Button
var _filter_buttons: Array[Button] = []

# ============ 状态 ============

var _current_filter: int = 0  # 0 = All
var _focusable_buttons: Array[Button] = []
var _current_focus_index: int = -1

# ============ 初始化 ============

func _ready() -> void:
	_instance = self
	add_to_group("fish_compendium")  # 添加到组以便全局访问
	_setup_node_references()
	_connect_signals()
	_build_filter_buttons()
	_hide_ui()  # 初始隐藏
	print("[FishCompendiumUI] Initialized")

func _setup_node_references() -> void:
	_background = $Background if has_node("Background") else null
	_panel = $Panel if has_node("Panel") else null

	if _panel:
		var vbox = _panel.get_node_or_null("VBox")
		if vbox:
			_title_label = vbox.get_node_or_null("TitleLabel")
			_progress_label = vbox.get_node_or_null("ProgressLabel")
			_progress_bar = vbox.get_node_or_null("ProgressBar")

			_filter_scroll = vbox.get_node_or_null("FilterScroll")
			if _filter_scroll:
				_filter_hbox = _filter_scroll.get_node_or_null("FilterHBox")

			_fish_scroll = vbox.get_node_or_null("FishScroll")
			if _fish_scroll:
				_fish_vbox = _fish_scroll.get_node_or_null("FishVBox")

			_close_btn = vbox.get_node_or_null("CloseBtn")

	# 设置关闭按钮悬停效果
	_setup_hover_effect(_close_btn)

func _connect_signals() -> void:
	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)

	# 监听图鉴更新
	var system = FishCompendiumSystem.get_instance()
	if system:
		system.compendium_updated.connect(_on_compendium_updated)
		system.fish_discovered.connect(_on_fish_discovered)

# ============ 显示/隐藏 ============

func _show_ui() -> void:
	if _panel:
		_modulate_panel(true)

	visible = true
	_update_display()
	_update_focusable_buttons()

	# 默认焦点到关闭按钮
	if _close_btn:
		_close_btn.grab_focus()

func _hide_ui() -> void:
	_modulate_panel(false)
	await get_tree().create_timer(0.25).timeout
	visible = false
	_release_all_focus()

func _modulate_panel(_show: bool) -> void:
	if not _panel:
		return

	var tween = create_tween()
	if _show:
		_panel.modulate = Color(1, 1, 1, 0)
		_panel.scale = Vector2(0.95, 0.95)
		tween.tween_property(_panel, "modulate:a", 1.0, 0.2)
		tween.parallel().tween_property(_panel, "scale", Vector2(1, 1), 0.2)
	else:
		tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
		tween.parallel().tween_property(_panel, "scale", Vector2(0.95, 0.95), 0.2)

# ============ 构建过滤器按钮 ============

func _build_filter_buttons() -> void:
	if not _filter_hbox:
		return

	_filter_buttons.clear()

	for i in range(LOCATION_FILTERS.size()):
		var filter_name = LOCATION_FILTERS[i]
		var btn = Button.new()
		btn.text = filter_name
		btn.toggle_mode = true
		btn.custom_minimum_size = TAB_BUTTON_SIZE
		btn.pressed.connect(_on_filter_button_pressed.bind(i))
		_setup_hover_effect(btn)

		_filter_hbox.add_child(btn)
		_filter_buttons.append(btn)

	# 默认选中"全部"
	if not _filter_buttons.is_empty():
		_filter_buttons[0].button_pressed = true

# ============ 更新显示 ============

func _update_display() -> void:
	_update_progress()
	_update_filter_buttons()
	_update_fish_list()

func _update_progress() -> void:
	var system = FishCompendiumSystem.get_instance()
	if not system:
		return

	var discovered = system.get_discovered_count()
	var total = system.get_total_fish_count()
	var percentage = int(system.get_progress() * 100)

	if _progress_label:
		_progress_label.text = "已钓: %d/%d 种鱼 (%d%%)" % [discovered, total, percentage]

	if _progress_bar:
		_progress_bar.max_value = 100.0
		_progress_bar.value = percentage

func _update_filter_buttons() -> void:
	for i in range(_filter_buttons.size()):
		if _filter_buttons[i]:
			_filter_buttons[i].button_pressed = (i == _current_filter)

func _update_fish_list() -> void:
	if not _fish_vbox:
		return

	# 清空现有列表
	for child in _fish_vbox.get_children():
		child.queue_free()

	# 获取鱼类列表
	var fish_list = _get_fish_list_for_filter()

	if fish_list.is_empty():
		_add_empty_state()
		return

	# 按稀有度排序（传说在前）
	fish_list.sort_custom(func(a, b):
		var rarity_a = _get_fish_rarity(a)
		var rarity_b = _get_fish_rarity(b)
		return rarity_a < rarity_b  # 稀有度低的在前（传说<精品<优质<普通）
	)

	# 添加鱼类卡片
	for fish_id in fish_list:
		var card = _create_fish_card(fish_id)
		_fish_vbox.add_child(card)

func _get_fish_list_for_filter() -> Array:
	if _current_filter == 0 or _current_filter >= LOCATION_KEYS.size():
		# 全部：返回所有鱼类
		return _get_all_fish_ids()
	else:
		# 按地点筛选
		var location_key = LOCATION_KEYS[_current_filter]
		if FishingSystem and FishingSystem.FISH_BY_LOCATION.has(location_key):
			# 创建可变副本
			return FishingSystem.FISH_BY_LOCATION[location_key].duplicate()
		return []

func _get_all_fish_ids() -> Array:
	if FishingSystem and FishingSystem.FISH_DATA:
		# 创建可变副本以便排序
		return FishingSystem.FISH_DATA.keys().duplicate()
	return []

func _add_empty_state() -> void:
	var empty_panel = PanelContainer.new()
	empty_panel.custom_minimum_size = Vector2(0, 100)

	var label = Label.new()
	label.text = "该区域暂无鱼类"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color(0.6, 0.6, 0.6, 1)
	empty_panel.add_child(label)

	_fish_vbox.add_child(empty_panel)

# ============ 创建鱼类卡片 ============

func _create_fish_card(fish_id: String) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, CARD_HEIGHT)

	# 获取鱼类数据
	var fish_data = _get_fish_data(fish_id)
	var system = FishCompendiumSystem.get_instance()
	var is_discovered = system.is_discovered(fish_id) if system else false
	var catch_count = system.get_catch_count(fish_id) if system else 0

	# 未发现的鱼降低透明度
	if not is_discovered:
		panel.modulate = Color(1, 1, 1, UNDISCOVERED_OPACITY)

	# 传说鱼类特殊效果
	var rarity = _get_fish_rarity(fish_id)
	if rarity < 0.1:
		var style = StyleBoxFlat.new()
		style.set_bg_color(COLOR_GOLD_BG)
		style.set_border_color(COLOR_GOLD_BORDER)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("normal", style)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	# 左侧: 图标
	var emoji_label = Label.new()
	emoji_label.text = _get_fish_emoji(fish_id)
	emoji_label.custom_minimum_size = Vector2(40, 0)
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(emoji_label)

	# 中间: 名称和详细信息
	var info_vbox = VBoxContainer.new()
	hbox.add_child(info_vbox)

	# 第一行: 名称 + 稀有度标记
	var top_hbox = HBoxContainer.new()
	info_vbox.add_child(top_hbox)

	var name_label = Label.new()
	if is_discovered:
		name_label.text = fish_data.get("name", fish_id)
	else:
		name_label.text = "???"
	name_label.modulate = _get_rarity_color(rarity)
	top_hbox.add_child(name_label)

	# 添加稀有度标记
	var rarity_badge = Label.new()
	rarity_badge.text = " [%s]" % _get_rarity_name(rarity)
	rarity_badge.modulate = _get_rarity_color(rarity)
	top_hbox.add_child(rarity_badge)

	# 第二行: 捕获状态 + 难度星级
	var detail_label = Label.new()
	if is_discovered:
		detail_label.text = "已钓 x%d  %s  💰%dg" % [
			catch_count,
			_get_difficulty_stars(fish_data.get("difficulty", 1)),
			fish_data.get("price", 0)
		]
	else:
		detail_label.text = "未发现"
	detail_label.modulate = Color(0.7, 0.7, 0.7, 1)
	info_vbox.add_child(detail_label)

	# 第三行: 发现状态图标
	var status_hbox = HBoxContainer.new()
	info_vbox.add_child(status_hbox)

	var status_icon = Label.new()
	if is_discovered:
		status_icon.text = "✅"
	else:
		status_icon.text = "❓"
	status_icon.modulate = Color(0.5, 0.5, 0.5, 1) if not is_discovered else Color(0.3, 0.7, 0.3, 1)
	status_hbox.add_child(status_icon)

	return panel

# ============ 辅助方法 ============

func _get_fish_data(fish_id: String) -> Dictionary:
	if FishingSystem and FishingSystem.FISH_DATA.has(fish_id):
		return FishingSystem.FISH_DATA[fish_id]
	return {}

func _get_fish_rarity(fish_id: String) -> float:
	var data = _get_fish_data(fish_id)
	return data.get("rarity", 0.5)

func _get_fish_emoji(fish_id: String) -> String:
	var system = FishCompendiumSystem.get_instance()
	if system:
		return system.get_fish_emoji(fish_id)
	return FISH_EMOJI.get(fish_id, DEFAULT_EMOJI)

func _get_rarity_name(rarity: float) -> String:
	if rarity >= 0.5:
		return "普通"
	elif rarity >= 0.2:
		return "优质"
	elif rarity >= 0.1:
		return "精品"
	else:
		return "传说"

func _get_rarity_color(rarity: float) -> Color:
	if rarity >= 0.5:
		return RARITY_COLORS["common"]
	elif rarity >= 0.2:
		return RARITY_COLORS["fine"]
	elif rarity >= 0.1:
		return RARITY_COLORS["rare"]
	else:
		return RARITY_COLORS["legendary"]

func _get_difficulty_stars(difficulty: int) -> String:
	var stars = mini(difficulty, 5)  # 最多5星
	return STAR_FILLED.repeat(stars) + STAR_EMPTY.repeat(5 - stars)

# ============ 焦点管理 ============

func _update_focusable_buttons() -> void:
	_focusable_buttons.clear()

	# 添加过滤器按钮
	for btn in _filter_buttons:
		if btn:
			_focusable_buttons.append(btn)

	# 添加关闭按钮
	if _close_btn:
		_focusable_buttons.append(_close_btn)

func _release_all_focus() -> void:
	for btn in _focusable_buttons:
		if btn and is_instance_valid(btn) and btn.has_focus():
			btn.release_focus()
	_current_focus_index = -1

# ============ 信号处理 ============

func _on_filter_button_pressed(index: int) -> void:
	_current_filter = index
	_update_filter_buttons()
	_update_fish_list()
	_update_focusable_buttons()

func _on_compendium_updated() -> void:
	_update_progress()
	_update_fish_list()

func _on_fish_discovered(fish_id: String) -> void:
	var fish_data = _get_fish_data(fish_id)
	var fish_name = fish_data.get("name", fish_id)
	_show_notification("新鱼类发现: %s %s" % [_get_fish_emoji(fish_id), fish_name])

func _on_close_pressed() -> void:
	_hide_ui()

# ============ 悬停效果 ============

func _setup_hover_effect(button: Button) -> void:
	if not button:
		return
	button.mouse_entered.connect(func():
		if not button.disabled:
			button.modulate = Color(HOVER_BRIGHTNESS, HOVER_BRIGHTNESS, HOVER_BRIGHTNESS)
	)
	button.mouse_exited.connect(func():
		button.modulate = Color(1, 1, 1)
	)

# ============ 通知系统 ============

func _show_notification(text: String) -> void:
	if NotificationManager and NotificationManager.has_method("show_notification"):
		NotificationManager.show_notification(text)
	else:
		print("[FishCompendiumUI] " + text)

# ============ 输入处理 ============

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# ESC 关闭
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		return

	# 方向键导航 (游戏手柄支持)
	if event.is_action_pressed("ui_up"):
		_navigate_focus(-1)
	elif event.is_action_pressed("ui_down"):
		_navigate_focus(1)
	elif event.is_action_pressed("ui_left"):
		_navigate_filter(-1)
	elif event.is_action_pressed("ui_right"):
		_navigate_filter(1)

func _navigate_focus(direction: int) -> void:
	if _focusable_buttons.is_empty():
		return

	if _current_focus_index < 0:
		_current_focus_index = 0
	else:
		_current_focus_index = (_current_focus_index + direction) % _focusable_buttons.size()

	var btn = _focusable_buttons[_current_focus_index]
	if btn and is_instance_valid(btn):
		btn.grab_focus()

func _navigate_filter(direction: int) -> void:
	var new_index = clampi(_current_filter + direction, 0, _filter_buttons.size() - 1)
	if new_index != _current_filter:
		_on_filter_button_pressed(new_index)
		if _filter_buttons[new_index]:
			_filter_buttons[new_index].grab_focus()
