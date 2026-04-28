extends PanelContainer

## HuntingUI - 狩猎面板
## 显示3个狩猎区域、猎物状态、狩猎按钮、结果展示

# ============ 常量 ============

## 狩猎区域名称和 emoji
const AREA_NAMES: Array = ["灌木丛", "森林", "湖泊"]
const AREA_EMOJIS: Array = ["🌿", "🌲", "🌊"]

# ============ 节点引用 ============

var _skill_label: Label
var _area_list_vbox: VBoxContainer
var _result_label: Label
var _close_btn: Button
var _area_buttons: Array = []  # 0=BUSHES, 1=FOREST, 2=LAKE

# ============ 状态 ============

var _visible: bool = false

# ============ 生命周期 ============

func _ready() -> void:
	_setup_node_references()
	_connect_signals()

func _setup_node_references() -> void:
	var vbox = $VBox
	_skill_label = vbox.get_node_or_null("SkillInfo/SkillLabel")
	_area_list_vbox = vbox.get_node_or_null("AreaList")
	_result_label = vbox.get_node_or_null("ResultLabel")
	var header = vbox.get_node_or_null("Header")
	_close_btn = header.get_node_or_null("CloseBtn") if header else null
	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)

func _connect_signals() -> void:
	if EventBus:
		EventBus.time_day_changed.connect(_refresh_areas)
		EventBus.time_changed.connect(_on_time_changed)
	if SkillSystem:
		SkillSystem.skill_level_up.connect(_on_skill_level_up)

# ============ 公共 API ============

func open_panel() -> void:
	_show_panel()
	_refresh_skill_level()
	_populate_areas()

func close_panel() -> void:
	_hide_panel()

func toggle_panel() -> void:
	if _visible:
		close_panel()
	else:
		open_panel()

# ============ 私有方法 ============

func _show_panel() -> void:
	visible = true
	_visible = true
	z_index = 10

func _hide_panel() -> void:
	visible = false
	_visible = false

func _refresh_skill_level() -> void:
	if not _skill_label:
		return
	var level = 0
	if SkillSystem and SkillSystem.has_method("get_level"):
		level = SkillSystem.get_level(SkillSystem.SkillType.HUNTING)
	_skill_label.text = "狩猎技能: Lv.%d" % level

func _populate_areas() -> void:
	if not _area_list_vbox:
		return

	# 清空现有列表
	for child in _area_list_vbox.get_children():
		child.queue_free()
	_area_buttons.clear()

	# 添加3个区域按钮
	for i in range(3):
		var area_row = _create_area_row(i)
		_area_list_vbox.add_child(area_row)
		_area_buttons.append(area_row)

func _create_area_row(area: int) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# 区域 emoji + 名称
	var area_label = Label.new()
	area_label.text = "%s %s" % [AREA_EMOJIS[area], AREA_NAMES[area]]
	area_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(area_label)

	# 状态标签
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	_update_area_status_label(status_label, area)
	hbox.add_child(status_label)

	# 狩猎按钮
	var hunt_btn = Button.new()
	hunt_btn.name = "HuntBtn"
	hunt_btn.text = "狩猎"
	hunt_btn.pressed.connect(_on_hunt_pressed.bind(area, hunt_btn))
	hbox.add_child(hunt_btn)

	return hbox

func _update_area_status_label(label: Label, area: int) -> void:
	if HuntingSystem:
		var status = HuntingSystem.check_area_status(area)
		if status.get("available", false):
			label.text = "✅ 可狩猎"
			label.modulate = Color(0.2, 0.8, 0.2)  # 绿色
		else:
			var cooldown = status.get("cooldown", 0)
			label.text = "⏳ %d分钟后刷新" % cooldown
			label.modulate = Color(0.9, 0.6, 0.1)  # 橙色
	else:
		label.text = "系统未就绪"

func _refresh_areas(_day: int, _season: String, _year: int) -> void:
	if _visible:
		_populate_areas()

func _on_time_changed(_day: int, _hour: int, _minute: int) -> void:
	# 时间变化时刷新所有区域状态
	if _visible:
		for i in range(_area_buttons.size()):
			var row = _area_buttons[i]
			if row and row.has_node("StatusLabel"):
				var status_label = row.get_node("StatusLabel") as Label
				if status_label:
					_update_area_status_label(status_label, i)

func _on_skill_level_up(skill_type: int, _old: int, _new: int) -> void:
	if SkillSystem and skill_type == SkillSystem.SkillType.HUNTING:
		_refresh_skill_level()

# ============ 信号处理 ============

func _on_close_pressed() -> void:
	close_panel()

func _on_hunt_pressed(area: int, btn: Button) -> void:
	if not HuntingSystem:
		push_error("[HuntingUI] HuntingSystem not found")
		return

	btn.disabled = true
	btn.text = "狩猎中..."

	var result = HuntingSystem.hunt_in_area(area)

	# 显示结果
	if result.get("success", false):
		var prey_name = result.get("prey_name", "")
		var items = result.get("items_added", 0)
		_result_label.text = "🎯 狩猎成功！获得 %s (+%d物品)" % [prey_name, items]
		_result_label.modulate = Color(0.2, 0.8, 0.2)
		if NotificationManager:
			NotificationManager.show_gain("🏹 狩猎成功！获得 %s" % prey_name)
	else:
		var message = result.get("message", "狩猎失败")
		_result_label.text = "❌ %s" % message
		_result_label.modulate = Color(0.95, 0.6, 0.1)
		if NotificationManager:
			NotificationManager.show_warning(message)

	# 刷新区域状态
	await get_tree().create_timer(0.5).timeout
	btn.disabled = false
	btn.text = "狩猎"
	if area < _area_buttons.size():
		var area_row = _area_buttons[area]
		if area_row and area_row.has_node("StatusLabel"):
			var sl = area_row.get_node("StatusLabel") as Label
			if sl:
				_update_area_status_label(sl, area)
