extends PanelContainer

## EquipmentSlot - 装备槽组件
## 用于装备Tab中的装备槽位
## 参考: design/gdd/ui/inventory-system.md

# ============ 装备槽类型 ============

enum EquipmentType { WEAPON, RING1, RING2, HEAD, FEET }

## 槽位名称
const TYPE_NAMES: Dictionary = {
	EquipmentType.WEAPON: "武器",
	EquipmentType.RING1: "戒指I",
	EquipmentType.RING2: "戒指II",
	EquipmentType.HEAD: "帽子",
	EquipmentType.FEET: "鞋子"
}

## 槽位图标
const TYPE_ICONS: Dictionary = {
	EquipmentType.WEAPON: "⚔️",
	EquipmentType.RING1: "💍",
	EquipmentType.RING2: "💍",
	EquipmentType.HEAD: "🎩",
	EquipmentType.FEET: "👢"
}

# ============ 信号 ============

signal equip_slot_clicked(slot_type: int)
signal equip_slot_right_clicked(slot_type: int)
signal tooltip_requested(item_id: String, quality: int, position: Vector2)
signal tooltip_hide_requested()

# ============ 节点引用 ============

var icon_label: Label
var icon_texture: TextureRect
var slot_name_label: Label
var item_name_label: Label
var empty_label: Label
var hover_overlay: Panel

# ============ 属性 ============

var slot_type: int = EquipmentType.WEAPON
var equipped_item_id: String = ""
var equipped_quality: int = Quality.NORMAL

# ============ 初始化 ============

func _ready() -> void:
	_setup_node_references()
	_setup_styles()
	_update_display()

# ============ 节点引用设置 ============

func _setup_node_references() -> void:
	icon_label = $IconContainer/IconLabel as Label
	icon_texture = $IconContainer/IconTexture as TextureRect
	slot_name_label = $SlotNameLabel as Label
	item_name_label = $ItemNameLabel as Label
	empty_label = $EmptyLabel as Label
	hover_overlay = $HoverOverlay as Panel

	# 默认隐藏图标和悬停遮罩
	if icon_texture:
		icon_texture.visible = false
	if hover_overlay:
		hover_overlay.visible = false

# ============ 样式设置 ============

func _setup_styles() -> void:
	# 创建槽位样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.18, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_color = Color(0.4, 0.45, 0.5, 0.6)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	add_theme_stylebox_override("normal", style)

# ============ 公开方法 ============

## 设置槽位类型
func set_slot_type(type: int) -> void:
	slot_type = type
	_update_display()

## 设置装备物品
func set_equipped(item_id: String, quality: int = Quality.NORMAL) -> void:
	equipped_item_id = item_id
	equipped_quality = quality
	_update_display()

## 清空装备
func clear_equipment() -> void:
	equipped_item_id = ""
	equipped_quality = Quality.NORMAL
	_update_display()

## 检查是否有装备
func has_equipment() -> bool:
	return not equipped_item_id.is_empty()

# ============ 显示更新 ============

func _update_display() -> void:
	_update_slot_name()
	_update_icon()
	_update_item_name()
	_update_empty_state()
	_update_border_color()

func _update_slot_name() -> void:
	if slot_name_label:
		slot_name_label.text = tr(TYPE_NAMES.get(slot_type, "装备"))

func _update_icon() -> void:
	if not icon_texture and not icon_label:
		return

	var is_empty = equipped_item_id.is_empty()

	if is_empty:
		# 显示槽位类型图标
		if icon_label:
			icon_label.text = TYPE_ICONS.get(slot_type, "📦")
			icon_label.visible = true
		if icon_texture:
			icon_texture.visible = false
	else:
		# 显示物品图标
		if icon_label:
			icon_label.visible = false
		if icon_texture:
			var item_def = ItemDataSystem.get_item_def(equipped_item_id) if ItemDataSystem else null
			if item_def and item_def.icon_path:
				icon_texture.texture = load(item_def.icon_path)
			icon_texture.visible = true

func _update_item_name() -> void:
	if not item_name_label:
		return

	if equipped_item_id.is_empty():
		item_name_label.text = ""
		item_name_label.visible = false
		return

	var item_def = ItemDataSystem.get_item_def(equipped_item_id) if ItemDataSystem else null
	if item_def:
		item_name_label.text = tr(item_def.name)
		# 品质颜色
		var color = Quality.get_color(equipped_quality)
		item_name_label.add_theme_color_override("font_color", color)
		item_name_label.visible = true
	else:
		item_name_label.text = equipped_item_id
		item_name_label.visible = true

func _update_empty_state() -> void:
	if not empty_label:
		return

	empty_label.visible = equipped_item_id.is_empty()

func _update_border_color() -> void:
	if not icon_texture and not icon_label:
		return

	var color: Color
	if equipped_item_id.is_empty():
		color = Color(0.4, 0.45, 0.5, 0.6)
	else:
		color = Quality.get_color(equipped_quality)

	var style = get_theme_stylebox("normal")
	if style is StyleBoxFlat:
		style.border_color = color
		add_theme_stylebox_override("normal", style)

# ============ 鼠标事件 ============

func _on_mouse_entered() -> void:
	if hover_overlay:
		hover_overlay.visible = true

	# 显示tooltip - 通过信号请求
	if has_equipment():
		tooltip_requested.emit(equipped_item_id, equipped_quality, get_global_mouse_position())

func _on_mouse_exited() -> void:
	if hover_overlay:
		hover_overlay.visible = false

	tooltip_hide_requested.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					equip_slot_clicked.emit(slot_type)
				MOUSE_BUTTON_RIGHT:
					equip_slot_right_clicked.emit(slot_type)

# ============ 动画 ============

func _on_hover_enter() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_hover_exit() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
