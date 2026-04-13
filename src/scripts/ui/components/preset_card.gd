extends PanelContainer

## PresetCard - 方案卡片组件
## 用于方案Tab中的预设方案显示
## 参考: design/gdd/ui/inventory-system.md

# ============ 信号 ============

signal preset_selected(preset_id: String)
signal preset_apply_clicked(preset_id: String)
signal preset_edit_clicked(preset_id: String)
signal preset_delete_clicked(preset_id: String)

# ============ 节点引用 ============

var preset_name_label: Label
var preset_icon_label: Label
var preset_desc_label: Label
var equipment_preview: VBoxContainer
var apply_button: Button
var edit_button: Button
var delete_button: Button
var selected_indicator: TextureRect

# ============ 属性 ============

var preset_id: String = ""
var is_selected: bool = false
var preset_data: Dictionary = {}

# ============ 初始化 ============

func _ready() -> void:
	_setup_node_references()
	_setup_styles()
	_setup_button_connections()

# ============ 节点引用设置 ============

func _setup_node_references() -> void:
	preset_name_label = $VBox/NameContainer/PresetNameLabel as Label
	preset_icon_label = $VBox/IconLabel as Label
	preset_desc_label = $VBox/DescLabel as Label
	equipment_preview = $VBox/EquipmentPreview as VBoxContainer
	apply_button = $VBox/ButtonContainer/ApplyButton as Button
	edit_button = $VBox/ButtonContainer/EditButton as Button
	delete_button = $VBox/ButtonContainer/DeleteButton as Button
	selected_indicator = $SelectedIndicator as TextureRect

# ============ 样式设置 ============

func _setup_styles() -> void:
	_update_styles()

func _update_styles() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.88)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6

	if is_selected:
		style.border_color = Color(0.85, 0.7, 0.3, 1.0)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
	else:
		style.border_color = Color(0.3, 0.35, 0.4, 0.5)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1

	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	add_theme_stylebox_override("normal", style)

	# 选中指示器
	if selected_indicator:
		selected_indicator.visible = is_selected

# ============ 按钮连接 ============

func _setup_button_connections() -> void:
	if apply_button:
		apply_button.pressed.connect(_on_apply_clicked)
	if edit_button:
		edit_button.pressed.connect(_on_edit_clicked)
	if delete_button:
		delete_button.pressed.connect(_on_delete_clicked)

# ============ 公开方法 ============

## 设置方案数据
func set_preset_data(id: String, data: Dictionary) -> void:
	preset_id = id
	preset_data = data
	_update_display()

## 设置选中状态
func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_styles()

## 清空方案数据
func clear_preset() -> void:
	preset_id = ""
	preset_data = {}
	_update_display()

# ============ 显示更新 ============

func _update_display() -> void:
	_update_name()
	_update_icon()
	_update_description()
	_update_equipment_preview()
	_update_button_states()

func _update_name() -> void:
	if not preset_name_label:
		return

	if preset_data.is_empty():
		preset_name_label.text = "空方案"
		preset_name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
	else:
		preset_name_label.text = tr(preset_data.get("name", "未命名"))
		preset_name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8, 1.0))

func _update_icon() -> void:
	if not preset_icon_label:
		return

	if preset_data.is_empty():
		preset_icon_label.text = "📦"
	else:
		var icon = preset_data.get("icon", "📋")
		preset_icon_label.text = icon

func _update_description() -> void:
	if not preset_desc_label:
		return

	if preset_data.is_empty():
		preset_desc_label.text = "点击编辑创建方案"
		preset_desc_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 0.6))
		preset_desc_label.visible = true
	else:
		var desc = preset_data.get("description", "")
		if desc.is_empty():
			preset_desc_label.visible = false
		else:
			preset_desc_label.text = tr(desc)
			preset_desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.8))
			preset_desc_label.visible = true

func _update_equipment_preview() -> void:
	if not equipment_preview:
		return

	# 清除旧的预览
	for child in equipment_preview.get_children():
		child.queue_free()

	if preset_data.is_empty():
		return

	# 添加装备预览
	var equipment = preset_data.get("equipment", {})
	var slots = ["weapon", "ring1", "ring2", "head", "feet"]
	var slot_names = {"weapon": "武器", "ring1": "戒指I", "ring2": "戒指II", "head": "帽子", "feet": "鞋子"}

	for slot in slots:
		if equipment.has(slot):
			var item_id = equipment[slot]
			if not item_id.is_empty():
				var item_def = ItemDataSystem.get_item_def(item_id) if ItemDataSystem else null
				if item_def:
					var label = Label.new()
					label.text = "%s: %s" % [slot_names.get(slot, slot), tr(item_def.name)]
					label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.9))
					equipment_preview.add_child(label)

func _update_button_states() -> void:
	var has_data = not preset_data.is_empty()

	if apply_button:
		apply_button.disabled = not has_data
	if edit_button:
		edit_button.disabled = false  # 可以编辑空方案
	if delete_button:
		delete_button.disabled = not has_data

# ============ 按钮回调 ============

func _on_apply_clicked() -> void:
	if not preset_id.is_empty():
		preset_apply_clicked.emit(preset_id)

func _on_edit_clicked() -> void:
	if not preset_id.is_empty():
		preset_edit_clicked.emit(preset_id)

func _on_delete_clicked() -> void:
	if not preset_id.is_empty():
		preset_delete_clicked.emit(preset_id)

# ============ 鼠标事件 ============

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			preset_selected.emit(preset_id)
