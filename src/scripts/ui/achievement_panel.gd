## AchievementPanel - 成就面板
## 显示所有成就、完美度、分类筛选
## Tab: 全部 / 17个分类 / 完美度详情

extends PanelContainer

# ============ 常量 ============

const ACHIEVEMENT_CATEGORIES: Array = [
	{"id": "all", "name": "全部", "icon": "📋"},
	{"id": "collection", "name": "收集", "icon": "📦"},
	{"id": "farming", "name": "农耕", "icon": "🌾"},
	{"id": "fishing", "name": "钓鱼", "icon": "🎣"},
	{"id": "mining", "name": "采矿", "icon": "⛏️"},
	{"id": "money", "name": "金钱", "icon": "💰"},
	{"id": "cooking", "name": "烹饪", "icon": "🍳"},
	{"id": "skill", "name": "技能", "icon": "📈"},
	{"id": "social", "name": "社交", "icon": "👥"},
	{"id": "friendship", "name": "好感", "icon": "❤️"},
	{"id": "combat", "name": "战斗", "icon": "⚔️"},
	{"id": "shipping", "name": "出货", "icon": "📮"},
	{"id": "animal", "name": "畜牧", "icon": "🐄"},
	{"id": "breeding", "name": "育种", "icon": "🌱"},
	{"id": "museum", "name": "博物馆", "icon": "🏛️"},
	{"id": "guild", "name": "公会", "icon": "🏰"},
	{"id": "hidden_npc", "name": "仙灵", "icon": "✨"},
	{"id": "quest", "name": "任务", "icon": "📋"}
]

const PERFECTION_WEIGHTS: Dictionary = {
	"achievement": 0.25,
	"shipping": 0.20,
	"bundle": 0.15,
	"collection": 0.15,
	"skill": 0.15,
	"friend": 0.10
}

# ============ 节点引用 ============

var _title_label: Label
var _close_btn: Button
var _percent_label: Label
var _progress_bar: ProgressBar
var _stats_label: Label
var _tab_container: HBoxContainer
var _content_container: VBoxContainer
var _tab_buttons: Array = []

# ============ 状态 ============

var _visible: bool = false
var _current_tab: int = 0  # 0=全部, 1-17=分类
var _system_ready: bool = false
var _showing_perfection_detail: bool = false

# ============ 生命周期 ============

func _ready() -> void:
	_setup_node_references()
	_apply_styles()
	_connect_signals()
	visible = false
	_visible = false

func _setup_node_references() -> void:
	var vbox = $VBox
	_title_label = vbox.get_node_or_null("Header/Title")
	_close_btn = vbox.get_node_or_null("Header/CloseBtn")
	_percent_label = vbox.get_node_or_null("PerfectionSection/PerfectionInfo/PercentLabel")
	_progress_bar = vbox.get_node_or_null("PerfectionSection/ProgressBar")
	_stats_label = vbox.get_node_or_null("PerfectionSection/StatsBar/StatsLabel")
	_tab_container = vbox.get_node_or_null("TabScrollX/TabContainer")
	_content_container = vbox.get_node_or_null("ContentScroll/ContentContainer")

	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)

func _apply_styles() -> void:
	# 面板背景
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = UITokens.PANEL_BG
	panel_style.border_color = UITokens.PANEL_BORDER
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(UITokens.RADIUS_MD)
	panel_style.set_content_margin_all(16.0)
	add_theme_stylebox_override("panel", panel_style)

	# 完美度进度条 - 渐变效果通过两层叠加实现
	if _progress_bar:
		_progress_bar.max_value = 1.0
		_progress_bar.step = 0.01
		var bar_bg = StyleBoxFlat.new()
		bar_bg.bg_color = Color(0.16, 0.16, 0.19, 1.0)
		bar_bg.set_corner_radius_all(UITokens.RADIUS_SM)
		_progress_bar.add_theme_stylebox_override("background", bar_bg)
		var bar_fill = StyleBoxFlat.new()
		bar_fill.bg_color = UITokens.ACCENT_GOLD
		bar_fill.set_corner_radius_all(UITokens.RADIUS_SM)
		_progress_bar.add_theme_stylebox_override("fill", bar_fill)

	# 标题
	if _title_label:
		_title_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_XL)

	# 百分比
	if _percent_label:
		_percent_label.add_theme_color_override("font_color", UITokens.ACCENT_GOLD)
		_percent_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_XL)

	# 统计
	if _stats_label:
		_stats_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
		_stats_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)

	# 构建 Tab 按钮
	_build_category_tabs()

func _build_category_tabs() -> void:
	if not _tab_container:
		return

	for child in _tab_container.get_children():
		child.queue_free()
	_tab_buttons.clear()

	for i in range(ACHIEVEMENT_CATEGORIES.size()):
		var cat = ACHIEVEMENT_CATEGORIES[i]
		var btn = Button.new()
		btn.text = "%s %s" % [cat["icon"], cat["name"]]
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)
		btn.custom_minimum_size.y = 36
		btn.pressed.connect(_on_category_tab_pressed.bind(i))
		btn.focus_mode = Control.FOCUS_ALL
		_tab_container.add_child(btn)
		_tab_buttons.append(btn)

	_update_tab_button_styles()

func _update_tab_button_styles() -> void:
	for i in range(_tab_buttons.size()):
		var btn = _tab_buttons[i] as Button
		if not btn:
			continue
		var selected = (i == _current_tab)
		btn.button_pressed = selected
		if selected:
			btn.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
			btn.add_theme_color_override("font_hover_color", UITokens.TEXT_PRIMARY)
			var style = StyleBoxFlat.new()
			style.bg_color = UITokens.ACCENT_GREEN
			style.set_corner_radius_all(UITokens.RADIUS_SM)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
		else:
			btn.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
			btn.add_theme_color_override("font_hover_color", UITokens.TEXT_PRIMARY)
			var style = StyleBoxFlat.new()
			style.bg_color = UITokens.BUTTON_NORMAL
			style.set_corner_radius_all(UITokens.RADIUS_SM)
			btn.add_theme_stylebox_override("normal", style)
			var hover_style = StyleBoxFlat.new()
			hover_style.bg_color = UITokens.BUTTON_HOVER
			hover_style.set_corner_radius_all(UITokens.RADIUS_SM)
			btn.add_theme_stylebox_override("hover", hover_style)

func _connect_signals() -> void:
	pass

# ============ 公共 API ============

func open_panel() -> void:
	_show_panel()
	_refresh_data()

func close_panel() -> void:
	_hide_panel()

func toggle_panel() -> void:
	if _visible:
		close_panel()
	else:
		open_panel()

# ============ 私有方法 ============

func _show_panel() -> void:
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(1.0, 0.9)
	visible = true
	_visible = true
	z_index = 10
	_animate_open()

func _hide_panel() -> void:
	_animate_close()

func _animate_open() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _animate_close() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(1.0, 0.95), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	_visible = false

func _refresh_data() -> void:
	_system_ready = get_node_or_null("/root/AchievementSystem") != null
	_update_perfection()
	_build_achievement_list()

func _update_perfection() -> void:
	var completed: int = 0
	var total: int = 120
	var percent: float = 0.0

	if _system_ready:
		completed = AchievementSystem.get_completed_count()
		total = AchievementSystem.get_total_count()
		var breakdown = AchievementSystem.get_perfection_breakdown()
		percent = breakdown.get("total_percent", 0.0)

	if _percent_label:
		_percent_label.text = "%.1f%%" % (percent * 100.0)
	if _progress_bar:
		_progress_bar.value = percent
	if _stats_label:
		_stats_label.text = "成就 %d/%d" % [completed, total]

func _build_achievement_list() -> void:
	if not _content_container:
		return
	for child in _content_container.get_children():
		child.queue_free()

	if not _system_ready:
		var label = Label.new()
		label.text = "成就系统开发中..."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
		label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_LG)
		label.custom_minimum_size.y = 400
		_content_container.add_child(label)
		return

	var category_id = "all"
	if _current_tab > 0 and _current_tab <= ACHIEVEMENT_CATEGORIES.size() - 1:
		category_id = ACHIEVEMENT_CATEGORIES[_current_tab]["id"]

	var achievements: Array = []
	if category_id == "all":
		achievements = AchievementSystem.get_all_achievements()
	else:
		achievements = AchievementSystem.get_achievements_by_category(category_id)

	for achievement in achievements:
		var card = _create_achievement_card(achievement)
		_content_container.add_child(card)

	if achievements.is_empty():
		var empty_label = Label.new()
		empty_label.text = "该分类暂无成就"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
		empty_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)
		empty_label.custom_minimum_size.y = 100
		_content_container.add_child(empty_label)

func _create_achievement_card(achievement: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 64)

	var achievement_id = achievement.get("id", "")
	var name = achievement.get("name", "未知成就")
	var desc = achievement.get("description", "")
	var state_int = achievement.get("state", 0)
	var completed = (state_int == AchievementSystem.AchievementState.COMPLETED)
	var condition = achievement.get("condition", {})
	var target = condition.get("count", 1)
	if target == 0:
		target = 1
	var progress: int = target if completed else 0

	# 边框颜色
	var left_color = UITokens.PANEL_BORDER
	var icon_text = "🔒"
	var name_color = UITokens.TEXT_PRIMARY
	var desc_color = Color(UITokens.TEXT_MUTED.r, UITokens.TEXT_MUTED.g, UITokens.TEXT_MUTED.b, 0.6)  # 未完成时60%透明度

	if completed:
		left_color = UITokens.ACCENT_GOLD
		icon_text = "⭐"
		name_color = UITokens.TEXT_PRIMARY
		desc_color = UITokens.TEXT_SECONDARY

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = UITokens.PANEL_BG
	bg_style.border_color = left_color
	bg_style.border_width_left = 3
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.set_corner_radius_all(UITokens.RADIUS_SM)
	bg_style.set_content_margin_all(12.0)
	panel.add_theme_stylebox_override("panel", bg_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var icon_label = Label.new()
	icon_label.text = icon_text
	icon_label.custom_minimum_size.x = 28
	if not completed:
		icon_label.modulate = Color(0.5, 0.5, 0.5, 1.0)
	hbox.add_child(icon_label)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)

	var name_label = Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)
	name_label.add_theme_color_override("font_color", name_color)
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_SM)
	desc_label.add_theme_color_override("font_color", desc_color)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_label)

	# 进度/状态
	var status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.custom_minimum_size.x = 100

	if completed:
		status_label.text = "✓"
		status_label.add_theme_color_override("font_color", UITokens.ACCENT_GREEN)
		status_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)
	else:
		if target > 1:
				if progress >= 0:
					status_label.text = "%d/%d" % [progress, target]
				else:
					status_label.text = "0/%d" % target
					status_label.add_theme_color_override("font_color", UITokens.ACCENT_GOLD)
				status_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_SM)
		else:
			status_label.text = ""

	hbox.add_child(info_vbox)
	hbox.add_child(status_label)

	panel.gui_input.connect(_on_achievement_card_input.bind(achievement_id, achievement))
	return panel

func _on_achievement_clicked(achievement_id: String, achievement: Dictionary) -> void:
	# 简化：点击成就卡片显示 toast 提示，非详细弹窗
	var name = achievement.get("name", "未知成就")
	var desc = achievement.get("description", "")
	var state_int = achievement.get("state", 0)
	var completed = (state_int == AchievementSystem.AchievementState.COMPLETED)
	if NotificationManager:
		if completed:
			NotificationManager.show_success("成就: %s" % name)
		else:
			NotificationManager.show_info("%s\n%s" % [name, desc])

# ============ 信号处理 ============

func _on_close_pressed() -> void:
	close_panel()

func _on_category_tab_pressed(index: int) -> void:
	_current_tab = index
	_update_tab_button_styles()
	_build_achievement_list()

func _on_achievement_card_input(event: InputEvent, achievement_id: String, achievement: Dictionary) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_achievement_clicked(achievement_id, achievement)
	elif event is InputEventKey:
		if event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
			_on_achievement_clicked(achievement_id, achievement)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _visible:
		close_panel()
