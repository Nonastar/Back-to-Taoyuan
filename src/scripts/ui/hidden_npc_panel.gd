## HiddenNPCPanel - 仙灵面板
## 显示6位仙灵、缘分等级、供奉与互动
## Tab: 全部 / 已发现 / 未发现
## 视图: 列表 / 详情 / 供奉选择

extends PanelContainer

# ============ 常量 ============

const AFFINITY_PER_DIAMOND: int = 250
const MAX_DIAMONDS: int = 12

const AFFINITY_LEVELS: Dictionary = {
	"wary": {"min": 0, "max": 399, "name": "戒备"},
	"curious": {"min": 400, "max": 999, "name": "好奇"},
	"trusting": {"min": 1000, "max": 1799, "name": "信任"},
	"devoted": {"min": 1800, "max": 2499, "name": "倾心"},
	"eternal": {"min": 2500, "max": 9999, "name": "永伴"}
}

const NPC_EMOJI: Dictionary = {
	"long_ling": "✨",
	"tao_yao": "🌸",
	"yue_tu": "🐰",
	"hu_xian": "🦊",
	"shan_weng": "⛰️",
	"gui_nv": "👧"
}

const NPC_TITLES: Dictionary = {
	"long_ling": "潜渊龙灵",
	"tao_yao": "桃林花灵",
	"yue_tu": "捣药玉兔",
	"hu_xian": "九尾灵狐",
	"shan_weng": "采药仙翁",
	"gui_nv": "织梦归女"
}

const ALL_NPC_IDS: Array = ["long_ling", "tao_yao", "yue_tu", "hu_xian", "shan_weng", "gui_nv"]

# ============ 节点引用 ============

var _title_label: Label
var _close_btn: Button
var _tab_all: Button
var _tab_revealed: Button
var _tab_hidden: Button
var _content_container: VBoxContainer

# ============ 状态 ============

var _visible: bool = false
var _system_ready: bool = false
var _closing: bool = false
var _current_tab: int = 0  # 0=全部 1=已发现 2=未发现
var _current_view: String = "list"  # list / detail / offering
var _selected_npc_id: String = ""

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
	var tab_nav = vbox.get_node_or_null("TabNav")
	_tab_all = tab_nav.get_node_or_null("TabAll") if tab_nav else null
	_tab_revealed = tab_nav.get_node_or_null("TabRevealed") if tab_nav else null
	_tab_hidden = tab_nav.get_node_or_null("TabHidden") if tab_nav else null
	_content_container = vbox.get_node_or_null("ContentContainer")

	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)
	if _tab_all:
		_tab_all.pressed.connect(_on_tab_all_pressed)
	if _tab_revealed:
		_tab_revealed.pressed.connect(_on_tab_revealed_pressed)
	if _tab_hidden:
		_tab_hidden.pressed.connect(_on_tab_hidden_pressed)

func _apply_styles() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = UITokens.PANEL_BG
	panel_style.border_color = UITokens.PANEL_BORDER
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8.0)
	panel_style.set_content_margin_all(16.0)
	add_theme_stylebox_override("panel", panel_style)

	if _title_label:
		_title_label.add_theme_font_size_override("font_size", 20)

	_update_tab_style(_tab_all, true)
	_update_tab_style(_tab_revealed, false)
	_update_tab_style(_tab_hidden, false)

func _update_tab_style(btn: Button, selected: bool) -> void:
	if not btn:
		return
	btn.button_pressed = selected
	if selected:
		btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.95, 0.95, 0.95, 1.0))
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.18, 0.8, 0.44, 1.0)
		style.set_corner_radius_all(4.0)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
	else:
		btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.95, 0.95, 0.95, 1.0))
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.25, 1.0)
		style.set_corner_radius_all(4.0)
		btn.add_theme_stylebox_override("normal", style)
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.3, 0.3, 0.38, 1.0)
		hover_style.set_corner_radius_all(4.0)
		btn.add_theme_stylebox_override("hover", hover_style)

func _connect_signals() -> void:
	pass

# ============ 公共 API ============

func open_panel() -> void:
	_closing = false
	_show_panel()
	_refresh_data()

func close_panel() -> void:
	_closing = true
	_hide_panel()

func toggle_panel() -> void:
	if _visible:
		close_panel()
	else:
		open_panel()

# ============ 私有方法 ============

func _show_panel() -> void:
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.9, 0.9)
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
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	_visible = false

func _refresh_data() -> void:
	_system_ready = get_node_or_null("/root/HiddenNpcSystem") != null
	_show_list_view()

# ============ 列表视图 ============

func _show_list_view() -> void:
	if not _content_container:
		return
	_clear_content()

	_current_view = "list"
	_selected_npc_id = ""

	# 仙灵卡片网格 (3列)
	var grid = HBoxContainer.new()
	grid.add_theme_constant_override("separation", 12)

	var idx = 0
	for npc_id in ALL_NPC_IDS:
		if not _matches_tab_filter(npc_id):
			continue

		var card = _create_npc_card(npc_id)
		grid.add_child(card)
		idx += 1

		if idx % 3 == 0:
			_content_container.add_child(grid)
			grid = HBoxContainer.new()
			grid.add_theme_constant_override("separation", 12)

	if idx % 3 != 0:
		_content_container.add_child(grid)

	if idx == 0:
		var empty_label = Label.new()
		empty_label.text = "该分类暂无仙灵"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.custom_minimum_size.y = 200
		_content_container.add_child(empty_label)

func _matches_tab_filter(npc_id: String) -> bool:
	if _current_tab == 0:
		return true  # 全部
	if _current_tab == 1:
		return _is_npc_revealed(npc_id)  # 已发现
	if _current_tab == 2:
		return not _is_npc_revealed(npc_id)  # 未发现
	return true

func _is_npc_revealed(npc_id: String) -> bool:
	var state: Dictionary = {}
	if _system_ready:
		state = HiddenNpcSystem.get_hidden_npc_state(npc_id)
		var phase = state.get("phase", HiddenNpcSystem.PHASE_UNKNOWN)
		return phase > HiddenNpcSystem.PHASE_UNKNOWN
	return false

func _create_npc_card(npc_id: String) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(130, 100)

	var is_revealed = _is_npc_revealed(npc_id)
	var state: Dictionary = {}
	var affinity: int = 0
	var phase: int = HiddenNpcSystem.PHASE_UNKNOWN

	if _system_ready:
		state = HiddenNpcSystem.get_hidden_npc_state(npc_id)
		affinity = state.get("affinity", 0)
		phase = state.get("phase", HiddenNpcSystem.PHASE_UNKNOWN)

	var is_bonded = (state.get("bonded", false))
	var is_courting = (state.get("courting", false))
	var emoji = NPC_EMOJI.get(npc_id, "✨")
	var level_name = _get_affinity_level_name(affinity)

	# 背景样式
	var bg_style = StyleBoxFlat.new()
	if is_bonded:
		bg_style.bg_color = Color(0.12, 0.12, 0.16, 0.95)
		bg_style.bg_color.a = 0.98
		bg_style.border_color = Color(1.0, 0.84, 0.0, 1.0)
		bg_style.border_width_left = 2
		bg_style.border_width_top = 2
		bg_style.border_width_right = 2
		bg_style.border_width_bottom = 2
	elif is_courting:
		bg_style.bg_color = Color(0.12, 0.12, 0.16, 0.95)
		bg_style.border_color = Color(0.25, 0.25, 0.32, 1.0)
		bg_style.border_width_left = 1
		bg_style.border_width_top = 1
		bg_style.border_width_right = 1
		bg_style.border_width_bottom = 1
	elif is_revealed:
		bg_style.bg_color = Color(0.12, 0.12, 0.16, 0.95)
		bg_style.border_color = Color(0.25, 0.25, 0.32, 1.0)
		bg_style.border_width_left = 1
		bg_style.border_width_top = 1
		bg_style.border_width_right = 1
		bg_style.border_width_bottom = 1
	else:
		bg_style.bg_color = Color(0.1, 0.1, 0.12, 0.85)
		bg_style.border_color = Color(0.25, 0.25, 0.32, 1.0)
		bg_style.border_width_left = 1
		bg_style.border_width_top = 1
		bg_style.border_width_right = 1
		bg_style.border_width_bottom = 1

	bg_style.set_corner_radius_all(4.0)
	bg_style.set_content_margin_all(10.0)
	panel.add_theme_stylebox_override("panel", bg_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Emoji / 锁图标
	var icon_label = Label.new()
	if is_revealed:
		icon_label.text = emoji
	elif phase == HiddenNpcSystem.PHASE_RUMOR:
		icon_label.text = emoji
		icon_label.modulate = Color(0.5, 0.5, 0.5, 0.6)
	else:
		icon_label.text = "🔒"
		icon_label.modulate = Color(0.5, 0.5, 0.5, 1.0)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)

	# 名称
	var name_label = Label.new()
	if is_revealed or phase == HiddenNpcSystem.PHASE_RUMOR:
		name_label.text = _get_npc_display_name(npc_id)
		name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	else:
		name_label.text = "???"
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)

	# 缘分菱形
	var diamond_label = Label.new()
	diamond_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_revealed:
		diamond_label.text = _get_diamond_string(affinity)
		diamond_label.add_theme_font_size_override("font_size", 10)
	else:
		diamond_label.text = "未发现"
		diamond_label.add_theme_font_size_override("font_size", 12)
		diamond_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
	vbox.add_child(diamond_label)

	# 等级名
	var level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_revealed:
		level_label.text = level_name
		level_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
		level_label.add_theme_font_size_override("font_size", 12)
	elif phase == HiddenNpcSystem.PHASE_RUMOR:
		level_label.text = "传闻"
		level_label.add_theme_font_size_override("font_size", 12)
		level_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.6))
	else:
		level_label.text = "未发现"
		level_label.add_theme_font_size_override("font_size", 12)
		level_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
	vbox.add_child(level_label)

	if phase >= HiddenNpcSystem.PHASE_ENCOUNTER:
		_play_discovery_effect(panel)
	panel.gui_input.connect(_on_npc_card_input.bind(npc_id))
	return panel

func _get_npc_display_name(npc_id: String) -> String:
	match npc_id:
		"long_ling": return "龙灵"
		"tao_yao": return "桃夭"
		"yue_tu": return "月兔"
		"hu_xian": return "狐仙"
		"shan_weng": return "山翁"
		"gui_nv": return "归女"
	return npc_id

func _get_affinity_level_name(affinity: int) -> String:
	for key in AFFINITY_LEVELS:
		var level = AFFINITY_LEVELS[key]
		if affinity >= level["min"] and affinity <= level["max"]:
			return level["name"]
	return "戒备"

func _get_affinity_level_key(affinity: int) -> String:
	for key in AFFINITY_LEVELS:
		var level = AFFINITY_LEVELS[key]
		if affinity >= level["min"] and affinity <= level["max"]:
			return key
	return "wary"

func _get_diamond_string(affinity: int) -> String:
	var filled = clampi(affinity / AFFINITY_PER_DIAMOND, 0, MAX_DIAMONDS)
	var empty = MAX_DIAMONDS - filled
	return "◆".repeat(filled) + "◇".repeat(empty)

func _get_diamond_colored_string(affinity: int) -> String:
	var filled = clampi(affinity / AFFINITY_PER_DIAMOND, 0, MAX_DIAMONDS)
	var empty = MAX_DIAMONDS - filled
	# 返回普通字符串，实际颜色在 Label.modulate 设置
	return "◆".repeat(filled) + "◇".repeat(empty)

# ============ 详情视图 ============

func _show_detail_view(npc_id: String) -> void:
	if not _content_container:
		return
	_clear_content()

	_current_view = "detail"
	_selected_npc_id = npc_id

	var is_revealed = _is_npc_revealed(npc_id)
	var emoji = NPC_EMOJI.get(npc_id, "✨")
	var name = _get_npc_display_name(npc_id)
	var title = NPC_TITLES.get(npc_id, "???")
	var affinity: int = 0
	var phase: int = HiddenNpcSystem.PHASE_UNKNOWN
	var abilities: Array = []
	var state: Dictionary = {}

	if _system_ready:
		state = HiddenNpcSystem.get_hidden_npc_state(npc_id)
		affinity = state.get("affinity", 0)
		phase = state.get("phase", HiddenNpcSystem.PHASE_UNKNOWN)
		abilities = state.get("unlocked_abilities", [])

	var level_name = _get_affinity_level_name(affinity)
	var affinity_percent = float(affinity) / float(AFFINITY_PER_DIAMOND * MAX_DIAMONDS)

	# 返回按钮
	var back_row = HBoxContainer.new()
	back_row.add_theme_constant_override("separation", 8)
	var back_btn = Button.new()
	back_btn.text = "< 返回列表"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(_on_back_to_list_pressed)
	back_row.add_child(back_btn)
	back_row.add_child(_make_spacer())
	_content_container.add_child(back_row)

	# 仙灵信息区
	var info_hbox = HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 20)
	_content_container.add_child(info_hbox)

	# 头像区
	var avatar_panel = PanelContainer.new()
	avatar_panel.custom_minimum_size = Vector2(120, 120)

	var avatar_style = StyleBoxFlat.new()
	avatar_style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	avatar_style.border_color = Color(1.0, 0.84, 0.0, 1.0)
	avatar_style.border_width_left = 2
	avatar_style.border_width_top = 2
	avatar_style.border_width_right = 2
	avatar_style.border_width_bottom = 2
	avatar_style.set_corner_radius_all(8.0)
	avatar_style.set_content_margin_all(10.0)
	avatar_panel.add_theme_stylebox_override("panel", avatar_style)

	var avatar_vbox = VBoxContainer.new()
	avatar_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	avatar_vbox.add_theme_constant_override("separation", 4)

	var avatar_emoji = Label.new()
	avatar_emoji.text = emoji
	avatar_emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_emoji.add_theme_font_size_override("font_size", 48)
	avatar_vbox.add_child(avatar_emoji)

	avatar_panel.add_child(avatar_vbox)
	info_hbox.add_child(avatar_panel)

	# 信息区
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 8)

	var npc_name_label = Label.new()
	npc_name_label.text = "%s · %s" % [name, title]
	npc_name_label.add_theme_font_size_override("font_size", 18)
	npc_name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	info_vbox.add_child(npc_name_label)

	var level_label = Label.new()
	level_label.text = "缘分等级: %s" % level_name
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
	info_vbox.add_child(level_label)

	var diamond_label = Label.new()
	diamond_label.text = _get_diamond_string(affinity)
	diamond_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(diamond_label)

	var progress_bar = ProgressBar.new()
	progress_bar.max_value = 1.0
	progress_bar.value = affinity_percent
	progress_bar.custom_minimum_size.y = 6
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.16, 0.16, 0.19, 1.0)
	bar_bg.set_corner_radius_all(4.0)
	progress_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(1.0, 0.84, 0.0, 1.0)
	bar_fill.set_corner_radius_all(4.0)
	progress_bar.add_theme_stylebox_override("fill", bar_fill)
	info_vbox.add_child(progress_bar)

	var affinity_num_label = Label.new()
	affinity_num_label.text = "%d / —" % affinity
	affinity_num_label.add_theme_font_size_override("font_size", 12)
	affinity_num_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	info_vbox.add_child(affinity_num_label)

	var stage_label = Label.new()
	var stage_display = "未发现"
	if state.get("bonded", false):
		stage_display = "往来 (已结缘)"
	elif state.get("courting", false):
		stage_display = "往来 (求缘中)"
	elif phase == HiddenNpcSystem.PHASE_REVEALED:
		stage_display = "往来"
	elif phase == HiddenNpcSystem.PHASE_ENCOUNTER:
		stage_display = "邂逅"
	elif phase == HiddenNpcSystem.PHASE_GLIMPSE:
		stage_display = "惊鸿"
	elif phase == HiddenNpcSystem.PHASE_RUMOR:
		stage_display = "传闻"
	stage_label.text = "发现阶段: %s" % stage_display
	stage_label.add_theme_font_size_override("font_size", 14)
	stage_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	info_vbox.add_child(stage_label)

	info_hbox.add_child(info_vbox)

	# 缘分能力
	var ability_title = Label.new()
	ability_title.text = "缘分能力"
	ability_title.add_theme_font_size_override("font_size", 16)
	ability_title.add_theme_color_override("font_color", Color(0.69, 0.69, 0.72, 1.0))
	_content_container.add_child(ability_title)

	# 模拟能力列表 (实际从系统获取)
	var abilities_list = _get_npc_abilities(npc_id)
	for ability in abilities_list:
		var ability_row = _create_ability_row(ability, affinity)
		_content_container.add_child(ability_row)

	# 每日操作区
	if is_revealed:
		var remaining_hbox = HBoxContainer.new()
		remaining_hbox.add_theme_constant_override("separation", 16)

		var offering_remaining = 1
		var interaction_remaining = 1

		if _system_ready:
			offering_remaining = HiddenNpcSystem.get_offering_remaining(npc_id)
			interaction_remaining = HiddenNpcSystem.get_interaction_remaining(npc_id)

		var remaining_label = Label.new()
		remaining_label.text = "今日剩余: 供奉 %d次 | 互动 %d次" % [offering_remaining, interaction_remaining]
		remaining_label.add_theme_font_size_override("font_size", 14)
		remaining_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
		remaining_hbox.add_child(remaining_label)
		remaining_hbox.add_child(_make_spacer())
		_content_container.add_child(remaining_hbox)

		# 操作按钮
		var action_hbox = HBoxContainer.new()
		action_hbox.add_theme_constant_override("separation", 12)
		_content_container.add_child(action_hbox)

		# 参悟按钮
		var insight_btn = _make_action_button("参悟", "+30~∞")
		insight_btn.pressed.connect(_on_insight_pressed.bind(npc_id))
		if interaction_remaining <= 0:
			insight_btn.disabled = true
		action_hbox.add_child(insight_btn)

		# 供奉按钮
		var offering_btn = _make_action_button("供奉", "+10~100")
		offering_btn.pressed.connect(_on_offering_pressed.bind(npc_id))
		if offering_remaining <= 0:
			offering_btn.disabled = true
		action_hbox.add_child(offering_btn)

		# 求缘/结缘按钮
		var bond_cost = 2500
		var can_bond = (affinity >= bond_cost)
		var bond_btn = _make_special_button("求缘" if not state.get("bonded", false) else "结缘", "%d缘分" % bond_cost)
		bond_btn.pressed.connect(_on_bond_pressed.bind(npc_id))
		if not can_bond:
			bond_btn.disabled = true
			var disabled_style = StyleBoxFlat.new()
			disabled_style.bg_color = Color(0.1, 0.1, 0.12, 1.0)
			disabled_style.set_corner_radius_all(4.0)
			bond_btn.add_theme_stylebox_override("disabled", disabled_style)
		action_hbox.add_child(bond_btn)

func _get_npc_abilities(npc_id: String) -> Array:
	# 返回模拟的能力列表
	var abilities_map: Dictionary = {
		"long_ling": [
			{"id": "dragon_favor", "name": "龙泽", "desc": "瀑布钓鱼品质+1", "threshold": 800, "unlocked": false},
			{"id": "rain_call", "name": "唤雨", "desc": "下雨概率+15%", "threshold": 1500, "unlocked": false},
			{"id": "dragon_eye", "name": "龙瞳", "desc": "传说鱼捕获率+20%", "threshold": 2200, "unlocked": false}
		],
		"tao_yao": [
			{"id": "blossom_wind", "name": "花风", "desc": "果树生长加速", "threshold": 800, "unlocked": false},
			{"id": "spring_blessing", "name": "春祈", "desc": "春季作物产量+10%", "threshold": 1500, "unlocked": false},
			{"id": "peach_protection", "name": "桃护", "desc": "作物不会枯萎", "threshold": 2200, "unlocked": false}
		],
		"yue_tu": [
			{"id": "moon_blessing", "name": "月祝", "desc": "夜晚钓鱼经验+20%", "threshold": 800, "unlocked": false},
			{"id": "silver_hook", "name": "银钩", "desc": "夜间钓鱼品质+1", "threshold": 1500, "unlocked": false},
			{"id": "moonlight_cast", "name": "月投", "desc": "月亮湖传说鱼率+30%", "threshold": 2200, "unlocked": false}
		],
		"hu_xian": [
			{"id": "fox_whisper", "name": "狐语", "desc": "商店折扣5%", "threshold": 800, "unlocked": false},
			{"id": "illusion", "name": "幻化", "desc": "隐藏身形", "threshold": 1500, "unlocked": false},
			{"id": "nine_tails", "name": "九尾", "desc": "幸运加成+20%", "threshold": 2200, "unlocked": false}
		],
		"shan_weng": [
			{"id": "herb_mastery", "name": "药翁", "desc": "采矿额外矿物", "threshold": 800, "unlocked": false},
			{"id": "mountain_blessing", "name": "山祈", "desc": "采矿疲劳减半", "threshold": 1500, "unlocked": false},
			{"id": "earth_treasure", "name": "地宝", "desc": "铱矿概率+10%", "threshold": 2200, "unlocked": false}
		],
		"gui_nv": [
			{"id": "dream_weaver", "name": "织梦", "desc": "睡眠恢复+20%", "threshold": 800, "unlocked": false},
			{"id": "memory_restore", "name": "忆归", "desc": "遗忘种子保留", "threshold": 1500, "unlocked": false},
			{"id": "homecoming", "name": "归途", "desc": "传送cd减半", "threshold": 2200, "unlocked": false}
		]
	}

	var state: Dictionary = {}
	if _system_ready:
		state = HiddenNpcSystem.get_hidden_npc_state(npc_id)
		var system_abilities = state.get("unlocked_abilities", [])
		for ability in system_abilities:
			var ability_id = ability.get("id", "")
			var threshold = ability.get("threshold", 0)
			var unlocked = ability.get("unlocked", false)
			for default_ability in abilities_map.get(npc_id, []):
				if default_ability["id"] == ability_id:
					default_ability["unlocked"] = unlocked
					default_ability["threshold"] = threshold
		return abilities_map.get(npc_id, [])

	return abilities_map.get(npc_id, [])

func _create_ability_row(ability: Dictionary, affinity: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 56)

	var unlocked = ability.get("unlocked", false)
	var threshold = ability.get("threshold", 0)
	var remaining = threshold - affinity if threshold > affinity else 0

	var border_color = Color(0.25, 0.25, 0.32, 1.0)
	var text_primary = Color(0.95, 0.95, 0.95, 1.0)
	var text_secondary = Color(0.7, 0.7, 0.75, 1.0)
	var text_muted = Color(0.5, 0.5, 0.55, 1.0)

	if unlocked:
		border_color = Color(1.0, 0.84, 0.0, 1.0)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.12, 0.16, 0.95)
	bg_style.border_color = border_color
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.set_corner_radius_all(4.0)
	bg_style.set_content_margin_all(12.0)
	panel.add_theme_stylebox_override("panel", bg_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var num_label = Label.new()
	num_label.text = "①" if unlocked else "②"
	num_label.custom_minimum_size.x = 20
	if unlocked:
		num_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
	else:
		num_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
	hbox.add_child(num_label)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)

	var name_label = Label.new()
	name_label.text = ability.get("name", "???")
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", text_primary if unlocked else text_muted)
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = ability.get("desc", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", text_secondary if unlocked else text_muted)
	info_vbox.add_child(desc_label)

	hbox.add_child(info_vbox)

	var status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.custom_minimum_size.x = 120
	if unlocked:
		status_label.text = "✓ 已解锁"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
	else:
		status_label.text = "🔒 待解锁 (+%d)" % remaining
		status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
	status_label.add_theme_font_size_override("font_size", 12)
	hbox.add_child(status_label)

	return panel

# ============ 供奉视图 ============

func _show_offering_view(npc_id: String) -> void:
	if not _content_container:
		return
	_clear_content()

	_current_view = "offering"

	var name = _get_npc_display_name(npc_id)

	# 返回按钮
	var back_row = HBoxContainer.new()
	var back_btn = Button.new()
	back_btn.text = "< 返回"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(_on_back_to_detail_pressed)
	back_row.add_child(back_btn)
	back_row.add_child(_make_spacer())
	_content_container.add_child(back_row)

	var title_label = Label.new()
	title_label.text = "选择供奉物品 - %s" % name
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.69, 0.69, 0.72, 1.0))
	_content_container.add_child(title_label)

	var sub_label = Label.new()
	sub_label.text = "可供奉物品 (背包中)"
	sub_label.add_theme_font_size_override("font_size", 14)
	sub_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	_content_container.add_child(sub_label)

	# 获取可供奉物品
	var offering_items: Array = []
	if _system_ready:
		offering_items = HiddenNpcSystem.get_offering_items(npc_id)

	if offering_items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "背包中无可供奉物品"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.custom_minimum_size.y = 100
		_content_container.add_child(empty_label)
		return

	var grid = HBoxContainer.new()
	grid.add_theme_constant_override("separation", 12)

	var idx = 0
	for item in offering_items:
		var item_id = item.get("id", "")
		var item_name = item.get("name", "未知")
		var count = item.get("count", 1)
		var quality = item.get("quality", "normal")
		var affinity_gain = item.get("affinity_gain", 10)

		var card = _create_offering_item_card(npc_id, item_id, item_name, count, quality, affinity_gain, idx)
		grid.add_child(card)
		idx += 1

		if idx % 4 == 0:
			_content_container.add_child(grid)
			grid = HBoxContainer.new()
			grid.add_theme_constant_override("separation", 12)

	if idx % 4 != 0:
		_content_container.add_child(grid)

func _create_offering_item_card(npc_id: String, item_id: String, item_name: String, count: int, quality: String, affinity_gain: int, index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(90, 110)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.12, 0.16, 0.95)
	bg_style.border_color = Color(0.25, 0.25, 0.32, 1.0)
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.set_corner_radius_all(4.0)
	bg_style.set_content_margin_all(8.0)
	panel.add_theme_stylebox_override("panel", bg_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var icon_label = Label.new()
	icon_label.text = "🎁"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = item_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.y = 32
	vbox.add_child(name_label)

	var count_label = Label.new()
	count_label.text = "×%d" % count
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	vbox.add_child(count_label)

	var quality_label = Label.new()
	quality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var quality_text = "灵犀" if quality == "spiritual" else ("合意" if quality == "fine" else "一般")
	var quality_color = Color(1.0, 0.84, 0.0, 1.0) if quality == "spiritual" else (Color(0.7, 0.7, 0.75, 1.0) if quality == "fine" else Color(0.5, 0.5, 0.55, 1.0))
	quality_label.text = quality_text
	quality_label.add_theme_font_size_override("font_size", 11)
	quality_label.add_theme_color_override("font_color", quality_color)
	vbox.add_child(quality_label)

	var gain_label = Label.new()
	gain_label.text = "+%d" % affinity_gain
	gain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gain_label.add_theme_font_size_override("font_size", 12)
	gain_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
	vbox.add_child(gain_label)

	var confirm_btn = Button.new()
	confirm_btn.text = "供奉"
	confirm_btn.add_theme_font_size_override("font_size", 12)
	confirm_btn.custom_minimum_size.y = 28
	confirm_btn.pressed.connect(_on_confirm_offering.bind(npc_id, item_id, item_name, affinity_gain))
	vbox.add_child(confirm_btn)

	panel.gui_input.connect(_on_offering_card_input.bind(panel, npc_id, item_id, item_name, affinity_gain))
	return panel

# ============ 辅助方法 ============

func _clear_content() -> void:
	if not _content_container:
		return
	for child in _content_container.get_children():
		child.queue_free()

func _make_spacer() -> Control:
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer

func _make_action_button(text: String, sub: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(100, 60)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)

	var main_label = Label.new()
	main_label.text = text
	main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_label.add_theme_font_size_override("font_size", 14)
	main_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	vbox.add_child(main_label)

	var sub_label = Label.new()
	sub_label.text = sub
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 12)
	sub_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	vbox.add_child(sub_label)

	btn.add_child(vbox)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	style.set_corner_radius_all(4.0)
	style.set_content_margin_all(8.0)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.3, 0.38, 1.0)
	hover_style.set_corner_radius_all(4.0)
	hover_style.set_content_margin_all(8.0)
	btn.add_theme_stylebox_override("hover", hover_style)

	return btn

func _make_special_button(text: String, sub: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(100, 60)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)

	var main_label = Label.new()
	main_label.text = text
	main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_label.add_theme_font_size_override("font_size", 14)
	main_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	vbox.add_child(main_label)

	var sub_label = Label.new()
	sub_label.text = sub
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 12)
	sub_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	vbox.add_child(sub_label)

	btn.add_child(vbox)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.91, 0.11, 0.55, 1.0)
	style.set_corner_radius_all(4.0)
	style.set_content_margin_all(8.0)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.94, 0.38, 0.57, 1.0)
	hover_style.set_corner_radius_all(4.0)
	hover_style.set_content_margin_all(8.0)
	btn.add_theme_stylebox_override("hover", hover_style)

	return btn

# ============ 信号处理 ============

func _on_close_pressed() -> void:
	close_panel()

func _on_tab_all_pressed() -> void:
	_current_tab = 0
	_update_tab_style(_tab_all, true)
	_update_tab_style(_tab_revealed, false)
	_update_tab_style(_tab_hidden, false)
	_show_list_view()

func _on_tab_revealed_pressed() -> void:
	_current_tab = 1
	_update_tab_style(_tab_all, false)
	_update_tab_style(_tab_revealed, true)
	_update_tab_style(_tab_hidden, false)
	_show_list_view()

func _on_tab_hidden_pressed() -> void:
	_current_tab = 2
	_update_tab_style(_tab_all, false)
	_update_tab_style(_tab_revealed, false)
	_update_tab_style(_tab_hidden, true)
	_show_list_view()

func _on_npc_card_input(event: InputEvent, npc_id: String) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_show_detail_view(npc_id)
	elif event is InputEventKey:
		if event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
			_show_detail_view(npc_id)

func _on_back_to_list_pressed() -> void:
	_show_list_view()

func _on_back_to_detail_pressed() -> void:
	_show_detail_view(_selected_npc_id)

func _on_insight_pressed(npc_id: String) -> void:
	if not _system_ready:
		return

	var result = HiddenNpcSystem.perform_special_interaction(npc_id)
	if result.get("success", false):
		var gain = result.get("affinity_change", 0)
		_play_bond_effect()
		if NotificationManager:
			NotificationManager.show_success("参悟: 缘分 +%d" % gain)
		_show_detail_view(npc_id)
	else:
		var message = result.get("message", "参悟失败")
		if NotificationManager:
			NotificationManager.show_warning(message)

func _on_offering_pressed(npc_id: String) -> void:
	_show_offering_view(npc_id)

func _on_confirm_offering(npc_id: String, item_id: String, item_name: String, affinity_gain: int) -> void:
	if not _system_ready:
		return

	var result = HiddenNpcSystem.perform_offering(npc_id, item_id)
	if result.get("success", false):
		var actual_gain = result.get("affinity_change", affinity_gain)
		if NotificationManager:
			NotificationManager.show_success("供奉: 缘分 +%d" % actual_gain)
		_play_bond_effect()
		_show_detail_view(npc_id)
	else:
		var message = result.get("message", "供奉失败")
		if NotificationManager:
			NotificationManager.show_error(message)

func _on_bond_pressed(npc_id: String) -> void:
	if not _system_ready:
		return

	var result = HiddenNpcSystem.form_bond(npc_id)
	if result.get("success", false):
		if NotificationManager:
			NotificationManager.show_success("结缘成功！与 %s 正式结缘" % _get_npc_display_name(npc_id))
		_show_detail_view(npc_id)
	else:
		var message = result.get("message", "结缘失败")
		if NotificationManager:
			NotificationManager.show_warning(message)

func _on_offering_card_input(event: InputEvent, card: Control, npc_id: String, item_id: String, item_name: String, affinity_gain: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_confirm_offering(npc_id, item_id, item_name, affinity_gain)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _visible:
		if _current_view == "detail":
			_show_list_view()
		elif _current_view == "offering":
			_show_detail_view(_selected_npc_id)
		else:
			close_panel()

# ============ 动画效果 ============

## 发现仙灵时的光效动画
func _play_discovery_effect(card: Control) -> void:
	# 卡片缩放弹跳
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(card, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.15)
	# 金色光晕
	tween.parallel().tween_property(card, "modulate", Color(1.0, 0.9, 0.4, 0.6), 0.1)
	tween.tween_property(card, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	# 漂浮星星粒子
	_spawn_sparkles(card, "✨", 4)

## 供奉成功反馈
func _play_offering_effect(card: Control) -> void:
	if not card:
		return
	var tween = create_tween()
	tween.tween_property(card, "modulate", Color(0.7, 1.0, 0.7, 1.0), 0.1)
	tween.tween_property(card, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	tween.parallel().tween_property(card, "scale", Vector2(1.08, 1.08), 0.1)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2)
	_spawn_sparkles(card, "💫", 2)

## 结缘成功庆祝
func _play_bond_effect() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25)
	tween.parallel().tween_property(self, "modulate", Color(1.0, 0.9, 0.6, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	# 在面板中心产生爱心粒子
	if _content_container:
		_spawn_sparkles(_content_container, "❤️", 3)

## 生成漂浮粒子
func _spawn_sparkles(parent: Control, emoji: String, count: int) -> void:
	for i in range(count):
		var label = Label.new()
		label.text = emoji
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 18 + randi() % 10)
		label.position = Vector2(randi() % 60 - 30, randi() % 20 - 10)
		parent.add_child(label)

		var tween = create_tween()
		tween.tween_property(label, "position:y", label.position.y - 40.0 - randi() % 30, 0.6)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
		tween.tween_callback(label.queue_free)
