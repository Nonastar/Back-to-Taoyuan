## MuseumPanel - 博物馆面板
## 显示展柜、捐赠物品、领取里程碑奖励
## Tab: 展柜 / 捐赠 / 里程碑

extends PanelContainer

# ============ 常量 ============

const PANEL_ICON: String = "🏛️"

const CATEGORY_ICONS: Dictionary = {
	"ore": "⛏️",
	"gem": "💎",
	"bar": "🔩",
	"fossil": "🦴",
	"artifact": "🏺",
	"spirit": "✨"
}

const CATEGORY_NAMES: Dictionary = {
	"ore": "矿石",
	"gem": "宝石",
	"bar": "金属锭",
	"fossil": "化石",
	"artifact": "古物",
	"spirit": "仙灵物品"
}

const MILESTONE_DATA: Array = [
	{"count": 5, "name": "初窥门径", "money": 300, "item": "", "item_count": 0},
	{"count": 10, "name": "小有收藏", "money": 500, "item": "远古种子", "item_count": 1},
	{"count": 15, "name": "矿石鉴赏家", "money": 1000, "item": "", "item_count": 0},
	{"count": 20, "name": "博古通今", "money": 1500, "item": "五彩碎片", "item_count": 1},
	{"count": 25, "name": "文物守护者", "money": 3000, "item": "", "item_count": 0},
	{"count": 30, "name": "远古探秘", "money": 5000, "item": "铱锭", "item_count": 3},
	{"count": 36, "name": "博物馆之星", "money": 10000, "item": "", "item_count": 0},
	{"count": 40, "name": "灵物全鉴", "money": 8000, "item": "月光石", "item_count": 3}
]

# ============ 节点引用 ============

var _title_label: Label
var _close_btn: Button
var _count_label: Label
var _percent_label: Label
var _progress_bar: ProgressBar
var _tab_display: Button
var _tab_donate: Button
var _tab_milestone: Button
var _content_container: VBoxContainer

# ============ 状态 ============

var _visible: bool = false
var _current_tab: int = 0  # 0=展柜 1=捐赠 2=里程碑
var _system_ready: bool = false

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
	_count_label = vbox.get_node_or_null("ProgressSection/ProgressInfo/CountLabel")
	_percent_label = vbox.get_node_or_null("ProgressSection/ProgressInfo/PercentLabel")
	_progress_bar = vbox.get_node_or_null("ProgressSection/ProgressBar")
	var tab_nav = vbox.get_node_or_null("TabNav")
	_tab_display = tab_nav.get_node_or_null("TabDisplay") if tab_nav else null
	_tab_donate = tab_nav.get_node_or_null("TabDonate") if tab_nav else null
	_tab_milestone = tab_nav.get_node_or_null("TabMilestone") if tab_nav else null
	_content_container = vbox.get_node_or_null("ContentScroll/ContentContainer")

	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)
	if _tab_display:
		_tab_display.pressed.connect(_on_tab_display_pressed)
	if _tab_donate:
		_tab_donate.pressed.connect(_on_tab_donate_pressed)
	if _tab_milestone:
		_tab_milestone.pressed.connect(_on_tab_milestone_pressed)

func _apply_styles() -> void:
	# 面板背景
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = UITokens.PANEL_BG
	panel_style.border_color = UITokens.PANEL_BORDER
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(UITokens.RADIUS_MD)
	panel_style.set_content_margin_all(16.0)
	add_theme_stylebox_override("panel", panel_style)

	# 进度条
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

	# 标题样式
	if _title_label:
		_title_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_XL)

	# 计数/百分比样式
	if _count_label:
		_count_label.add_theme_color_override("font_color", UITokens.ACCENT_GOLD)
		_count_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_XL)
	if _percent_label:
		_percent_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
		_percent_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)

	# Tab 按钮样式
	_update_tab_button_style(_tab_display, true)
	_update_tab_button_style(_tab_donate, false)
	_update_tab_button_style(_tab_milestone, false)

func _update_tab_button_style(btn: Button, selected: bool) -> void:
	if not btn:
		return
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
	if EventBus:
		EventBus.time_day_changed.connect(_on_day_changed)

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
	scale = Vector2(0.95, 1.0)
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
	tween.tween_property(self, "scale", Vector2(0.9, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	_visible = false

func _refresh_data() -> void:
	_system_ready = get_node_or_null("/root/MuseumSystem") != null
	_update_progress()
	_switch_tab(_current_tab)

func _update_progress() -> void:
	var current: int = 0
	var total: int = 40
	var percent: float = 0.0

	if _system_ready:
		var progress = MuseumSystem.get_donation_progress()
		current = progress.get("current", 0)
		total = progress.get("total", 40)
		percent = progress.get("percentage", 0.0)

	if _count_label:
		_count_label.text = "%d/%d" % [current, total]
	if _percent_label:
		_percent_label.text = "%.1f%%" % (percent * 100.0)
	if _progress_bar:
		_progress_bar.value = percent

func _switch_tab(tab_index: int) -> void:
	_current_tab = tab_index

	# 更新 Tab 按钮样式
	_update_tab_button_style(_tab_display, tab_index == 0)
	_update_tab_button_style(_tab_donate, tab_index == 1)
	_update_tab_button_style(_tab_milestone, tab_index == 2)

	# 清空内容区
	if not _content_container:
		return
	for child in _content_container.get_children():
		child.queue_free()

	if not _system_ready:
		_show_placeholder()
		return

	match tab_index:
		0:
			_build_display_tab()
		1:
			_build_donate_tab()
		2:
			_build_milestone_tab()

func _show_placeholder() -> void:
	if not _content_container:
		return
	var label = Label.new()
	label.text = "博物馆系统开发中..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_LG)
	label.custom_minimum_size.y = 400
	_content_container.add_child(label)

# ============ 展柜 Tab ============

func _build_display_tab() -> void:
	if not _content_container:
		return
	var categories = ["ore", "gem", "bar", "fossil", "artifact", "spirit"]

	for cat_id in categories:
		# 分类标题
		var cat_title = HBoxContainer.new()
		cat_title.add_theme_constant_override("separation", 8)

		var cat_label = Label.new()
		cat_label.text = "%s %s" % [CATEGORY_ICONS.get(cat_id, "📦"), CATEGORY_NAMES.get(cat_id, cat_id)]
		cat_label.add_theme_color_override("font_color", Color(0.69, 0.69, 0.72, 1.0))
		cat_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_LG)
		cat_title.add_child(cat_label)

		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cat_title.add_child(spacer)

		_content_container.add_child(cat_title)

		# 物品网格
		var grid = HBoxContainer.new()
		grid.add_theme_constant_override("separation", 12)

		# 获取该分类的展品数据
		var exhibits = _get_exhibits_by_category(cat_id)
		for exhibit in exhibits:
			var card = _create_exhibit_card(exhibit)
			grid.add_child(card)

		_content_container.add_child(grid)

func _get_exhibits_by_category(category: String) -> Array:
	# 返回该分类的展品列表 {id, name, icon, donated}
	if not _system_ready:
		return []

	var result: Array = []
	var total = 40

	match category:
		"ore":
			var names = ["铜矿", "铁矿", "金矿", "水晶", "钨矿", "铱矿", "钛矿"]
			for i in range(7):
				var item_id = "ore_%d" % i
				result.append({
					"id": item_id,
					"name": names[i] if i < names.size() else "矿石%d" % (i + 1),
					"icon": CATEGORY_ICONS["ore"],
					"donated": MuseumSystem.is_donated(item_id)
				})
		"gem":
			var names = ["石英", "翡翠", "红宝石", "蓝宝石", "紫水晶", "钻石", "月光石"]
			for i in range(7):
				var item_id = "gem_%d" % i
				result.append({
					"id": item_id,
					"name": names[i] if i < names.size() else "宝石%d" % (i + 1),
					"icon": CATEGORY_ICONS["gem"],
					"donated": MuseumSystem.is_donated(item_id)
				})
		"bar":
			var names = ["铜锭", "铁锭", "金锭", "铱锭"]
			for i in range(4):
				var item_id = "bar_%d" % i
				result.append({
					"id": item_id,
					"name": names[i] if i < names.size() else "锭%d" % (i + 1),
					"icon": CATEGORY_ICONS["bar"],
					"donated": MuseumSystem.is_donated(item_id)
				})
		"fossil":
			for i in range(8):
				var item_id = "fossil_%d" % i
				result.append({
					"id": item_id,
					"name": "化石%d" % (i + 1),
					"icon": CATEGORY_ICONS["fossil"],
					"donated": MuseumSystem.is_donated(item_id)
				})
		"artifact":
			var names = ["古陶片", "青铜器", "铁器", "玉器", "瓷器", "书画", "织品", "漆器", "金银器", "古籍"]
			for i in range(10):
				var item_id = "artifact_%d" % i
				result.append({
					"id": item_id,
					"name": names[i] if i < names.size() else "古物%d" % (i + 1),
					"icon": CATEGORY_ICONS["artifact"],
					"donated": MuseumSystem.is_donated(item_id)
				})
		"spirit":
			var names = ["龙玉", "灵桃", "仙羽", "狐珠"]
			for i in range(4):
				var item_id = "spirit_%d" % i
				result.append({
					"id": item_id,
					"name": names[i] if i < names.size() else "仙灵物品%d" % (i + 1),
					"icon": CATEGORY_ICONS["spirit"],
					"donated": MuseumSystem.is_donated(item_id)
				})

	return result

func _create_exhibit_card(exhibit: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(72, 80)

	var donated: bool = exhibit.get("donated", false)
	var name: String = exhibit.get("name", "???")
	var icon: String = exhibit.get("icon", "❓")

	# 背景样式
	var bg_style = StyleBoxFlat.new()
	if donated:
		bg_style.bg_color = UITokens.PANEL_BG
		bg_style.border_color = UITokens.PANEL_BORDER
		bg_style.border_width_left = 1
		bg_style.border_width_top = 1
		bg_style.border_width_right = 1
		bg_style.border_width_bottom = 1
	else:
		bg_style.bg_color = Color(0.1, 0.1, 0.12, 0.8)
		bg_style.border_color = UITokens.PANEL_BORDER
		bg_style.border_width_left = 1
		bg_style.border_width_top = 1
		bg_style.border_width_right = 1
		bg_style.border_width_bottom = 1
	bg_style.set_corner_radius_all(UITokens.RADIUS_SM)
	bg_style.set_content_margin_all(6.0)
	panel.add_theme_stylebox_override("panel", bg_style)

	# 内部布局
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not donated:
		icon_label.modulate = Color(0.5, 0.5, 0.5, 1.0)
	vbox.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = name if donated else "?"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)
	if donated:
		name_label.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	else:
		name_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	var status_label = Label.new()
	status_label.text = "✓" if donated else "?"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)
	if donated:
		status_label.add_theme_color_override("font_color", UITokens.ACCENT_GREEN)
	else:
		status_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	vbox.add_child(status_label)

	return panel

# ============ 捐赠 Tab ============

func _build_donate_tab() -> void:
	if not _content_container:
		return

	# 统计信息
	var progress = _get_progress_data()
	var donated_count = progress["current"]
	var total_count = progress["total"]
	var donatable_count = 0
	var undiscovered_count = total_count - donated_count

	var stats_label = HBoxContainer.new()
	stats_label.add_theme_constant_override("separation", 16)

	var donated_label = Label.new()
	donated_label.text = "已捐赠: %d件" % donated_count
	donated_label.add_theme_color_override("font_color", UITokens.ACCENT_GREEN)
	donated_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)
	stats_label.add_child(donated_label)

	var donatable_label = Label.new()
	if _system_ready:
		var items = MuseumSystem.get_donatable_items()
		donatable_count = items.size()
	donatable_label.text = "可捐赠: %d件" % donatable_count
	donatable_label.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	donatable_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)
	stats_label.add_child(donatable_label)

	var undiscovered_label = Label.new()
	undiscovered_label.text = "未发现: %d件" % undiscovered_count
	undiscovered_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	undiscovered_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)
	stats_label.add_child(undiscovered_label)

	_content_container.add_child(stats_label)

	if not _system_ready:
		return

	# 可捐赠物品列表
	var donatable_items = MuseumSystem.get_donatable_items()
	if donatable_items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "背包中无可捐赠物品"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
		empty_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)
		empty_label.custom_minimum_size.y = 200
		_content_container.add_child(empty_label)
		return

	var grid = HBoxContainer.new()
	grid.add_theme_constant_override("separation", 12)

	var idx = 0
	for item in donatable_items:
		var item_id = item.get("id", "")
		var item_name = item.get("name", "未知物品")
		var count = item.get("count", 1)
		var category = item.get("category", "ore")
		var icon = CATEGORY_ICONS.get(category, "📦")

		var card = _create_donation_card(item_id, item_name, icon, count, idx)
		grid.add_child(card)
		idx += 1

		if idx % 4 == 0:
			_content_container.add_child(grid)
			grid = HBoxContainer.new()
			grid.add_theme_constant_override("separation", 12)

	if idx % 4 != 0:
		_content_container.add_child(grid)

func _create_donation_card(item_id: String, item_name: String, icon: String, count: int, index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(90, 100)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = UITokens.PANEL_BG
	bg_style.border_color = UITokens.PANEL_BORDER
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.set_corner_radius_all(UITokens.RADIUS_SM)
	bg_style.set_content_margin_all(8.0)
	panel.add_theme_stylebox_override("panel", bg_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = item_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)
	name_label.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.y = 32
	vbox.add_child(name_label)

	var count_label = Label.new()
	count_label.text = "×%d" % count
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_SM)
	count_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	vbox.add_child(count_label)

	var donate_btn = Button.new()
	donate_btn.text = "捐赠"
	donate_btn.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_SM)
	donate_btn.custom_minimum_size.y = 28
	donate_btn.focus_mode = Control.FOCUS_NONE
	donate_btn.pressed.connect(_on_donate_item_pressed.bind(item_id, item_name))
	vbox.add_child(donate_btn)

	panel.gui_input.connect(_on_donation_card_input.bind(panel, item_id, item_name))
	return panel

# ============ 里程碑 Tab ============

func _build_milestone_tab() -> void:
	if not _content_container:
		return

	var title_label = Label.new()
	title_label.text = "里程碑奖励"
	title_label.add_theme_color_override("font_color", Color(0.69, 0.69, 0.72, 1.0))
	title_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_LG)
	_content_container.add_child(title_label)

	var progress = _get_progress_data()
	var current = progress["current"]

	for milestone in MILESTONE_DATA:
		var row = _create_milestone_row(milestone, current)
		_content_container.add_child(row)

func _create_milestone_row(milestone: Dictionary, current: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 70)

	var count = milestone.get("count", 0)
	var name = milestone.get("name", "未知")
	var money = milestone.get("money", 0)
	var item_name = milestone.get("item", "")
	var item_count = milestone.get("item_count", 0)

	var state: int = 0  # 0=未解锁 1=可领取 2=已领取
	if _system_ready:
		state = MuseumSystem.get_milestone_state(count)

	var left_color = UITokens.PANEL_BORDER
	var bg_alpha = 0.6
	var name_color = UITokens.TEXT_MUTED
	var btn_disabled = true
	var btn_text = ""

	match state:
		1:  # 可领取
			left_color = UITokens.ACCENT_GOLD
			bg_alpha = 1.0
			name_color = UITokens.TEXT_PRIMARY
			btn_disabled = false
			btn_text = "领取"
		2:  # 已领取
			left_color = UITokens.TEXT_MUTED
			bg_alpha = 0.6
			name_color = UITokens.TEXT_MUTED
			btn_disabled = true
			btn_text = "已领取"
		_:  # 未解锁
			var remaining = count - current
			btn_text = "%d件后解锁" % remaining if remaining > 0 else "完成解锁"
			btn_disabled = true

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.12, bg_alpha)
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

	var star_label = Label.new()
	star_label.text = "⭐"
	star_label.custom_minimum_size.x = 24
	hbox.add_child(star_label)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)

	var name_label = Label.new()
	name_label.text = "%s (%d件)" % [name, count]
	name_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_MD)
	name_label.add_theme_color_override("font_color", name_color)
	info_vbox.add_child(name_label)

	var reward_label = Label.new()
	var reward_text = "💰 %dg" % money
	if item_name != "":
		reward_text += "  [%s×%d]" % [item_name, item_count]
	reward_label.text = reward_text
	reward_label.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_SM)
	reward_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	info_vbox.add_child(reward_label)

	hbox.add_child(info_vbox)

	var action_btn = Button.new()
	action_btn.text = btn_text
	action_btn.disabled = btn_disabled
	action_btn.custom_minimum_size.x = 80
	action_btn.custom_minimum_size.y = 32
	action_btn.add_theme_font_size_override("font_size", UITokens.FONT_SIZE_SM)
	action_btn.focus_mode = Control.FOCUS_NONE

	if state == 1:
		action_btn.pressed.connect(_on_claim_milestone_pressed.bind(count, name))
	else:
		action_btn.add_theme_color_override("font_color", UITokens.TEXT_MUTED)

	hbox.add_child(action_btn)

	return panel

# ============ 数据辅助 ============

func _get_progress_data() -> Dictionary:
	var current: int = 0
	var total: int = 40
	var percent: float = 0.0

	if _system_ready:
		var progress = MuseumSystem.get_donation_progress()
		current = progress.get("current", 0)
		total = progress.get("total", 40)
		percent = progress.get("percentage", 0.0)

	return {"current": current, "total": total, "percentage": percent}

# ============ 信号处理 ============

func _on_close_pressed() -> void:
	close_panel()

func _on_tab_display_pressed() -> void:
	_switch_tab(0)

func _on_tab_donate_pressed() -> void:
	_switch_tab(1)

func _on_tab_milestone_pressed() -> void:
	_switch_tab(2)

func _on_donate_item_pressed(item_id: String, item_name: String) -> void:
	if not _system_ready:
		return

	var result = MuseumSystem.donate_item(item_id)
	if result:
		if NotificationManager:
			NotificationManager.show_success("博物馆: 成功捐赠 [%s]" % item_name)
		_update_progress()
		_switch_tab(_current_tab)
	else:
		if NotificationManager:
			NotificationManager.show_error("博物馆: 捐赠失败")

func _on_donation_card_input(event: InputEvent, card: Control, item_id: String, item_name: String) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_donate_item_pressed(item_id, item_name)

func _on_claim_milestone_pressed(count: int, name: String) -> void:
	if not _system_ready:
		return

	var result = MuseumSystem.claim_milestone(count)
	if result:
		if NotificationManager:
			NotificationManager.show_success("博物馆: 里程碑 [%s] 奖励已领取！" % name)
		_update_progress()
		_switch_tab(_current_tab)
	else:
		if NotificationManager:
			NotificationManager.show_error("博物馆: 领取失败")

func _on_day_changed(_day: int, _season: String, _year: int) -> void:
	# 每日重置时刷新数据
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _visible:
		close_panel()
