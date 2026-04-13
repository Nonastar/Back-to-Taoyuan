extends PanelContainer

## ItemSlot - 物品格子组件
## 显示单个物品槽位，支持拖拽、悬停提示、右键菜单
## 参考: design/gdd/ui/inventory-system.md

# ============ 常量 ============

## 格子尺寸
const SLOT_SIZE: int = 56

## 品质颜色
const QUALITY_COLORS: Dictionary = {
	Quality.NORMAL: Color(0.7, 0.7, 0.7, 0.9),
	Quality.FINE: Color(0.4, 0.65, 0.4, 0.9),
	Quality.EXCELLENT: Color(0.4, 0.55, 0.75, 0.9),
	Quality.SUPREME: Color(0.6, 0.35, 0.65, 0.9)
}

# ============ 信号 ============

## 槽位点击信号
signal slot_clicked(slot_index: int, button: int)

## 槽位拖拽开始
signal drag_started(slot_index: int)

## 槽位拖拽结束
signal drag_ended(slot_index: int)

## 槽位右键信号
signal slot_right_clicked(slot_index: int)

## Tooltip请求信号
signal tooltip_requested(item_id: String, quality: int, position: Vector2)
signal tooltip_hide_requested()

# ============ 节点引用 ============

var icon_texture: TextureRect
var quantity_label: Label
var quality_border: ColorRect
var locked_icon: TextureRect
var hover_overlay: Panel

# ============ 属性 ============

## 槽位索引
var slot_index: int = -1

## 槽位数据
var item_id: String = ""
var quantity: int = 0
var quality: int = Quality.NORMAL

## 状态
var is_empty: bool = true
var is_selected: bool = false
var is_locked: bool = false
var is_dragging: bool = false

## 是否属于临时背包
var is_temp_slot: bool = false

## 品质边框宽度
const BORDER_WIDTH: float = 2.0

# ============ 初始化 ============

func _ready() -> void:
	_setup_node_references()
	_setup_styles()
	_update_display()

# ============ 节点引用设置 ============

func _setup_node_references() -> void:
	# 获取子节点
	icon_texture = $IconContainer/Icon as TextureRect
	quantity_label = $QuantityLabel as Label
	quality_border = $QualityBorder as ColorRect
	locked_icon = $LockedIcon as TextureRect
	hover_overlay = $HoverOverlay as Panel

	# 默认隐藏锁图标和悬停遮罩
	if locked_icon:
		locked_icon.visible = false
	if hover_overlay:
		hover_overlay.visible = false

# ============ 样式设置 ============

func _setup_styles() -> void:
	# 创建槽位样式
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.05, 0.08, 0.12, 0.88)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.border_color = Color(0.4, 0.45, 0.5, 0.6)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.content_margin_left = 2
	normal_style.content_margin_top = 2
	normal_style.content_margin_right = 2
	normal_style.content_margin_bottom = 2
	add_theme_stylebox_override("normal", normal_style)

# ============ 数据设置 ============

## 设置槽位数据
func set_slot_data(p_slot_index: int, p_item_id: String, p_quantity: int, p_quality: int, p_is_temp: bool = false) -> void:
	slot_index = p_slot_index
	item_id = p_item_id
	quantity = p_quantity
	quality = p_quality
	is_temp_slot = p_is_temp
	is_empty = item_id.is_empty() or quantity <= 0
	_update_display()

## 清空槽位
func clear_slot() -> void:
	item_id = ""
	quantity = 0
	quality = Quality.NORMAL
	is_empty = true
	_update_display()

## 设置选中状态
func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_border_style()

## 设置锁定状态
func set_locked(locked: bool) -> void:
	is_locked = locked
	if locked_icon:
		locked_icon.visible = locked
	_update_border_style()

# ============ 显示更新 ============

func _update_display() -> void:
	_update_icon()
	_update_quantity()
	_update_border_style()
	_update_lock_icon()

func _update_icon() -> void:
	if not icon_texture:
		return

	if is_empty:
		icon_texture.texture = null
		icon_texture.visible = false
		return

	# 获取物品图标
	var item_def = ItemDataSystem.get_item_def(item_id) if ItemDataSystem else null
	if item_def and item_def.icon_path:
		var icon_res = load(item_def.icon_path)
		icon_texture.texture = icon_res
		icon_texture.visible = true
	else:
		# 使用默认图标
		icon_texture.texture = null
		icon_texture.visible = false

func _update_quantity() -> void:
	if not quantity_label:
		return

	if is_empty or quantity <= 1:
		quantity_label.visible = false
	else:
		quantity_label.text = str(quantity)
		quantity_label.visible = true

func _update_border_style() -> void:
	if not quality_border:
		return

	# 根据品质设置边框颜色
	var border_color: Color
	if is_locked:
		border_color = Color(0.5, 0.5, 0.5, 0.7)
	elif is_selected:
		border_color = Color(0.85, 0.7, 0.3, 1.0)  # 金色选中
	else:
		border_color = QUALITY_COLORS.get(quality, QUALITY_COLORS[Quality.NORMAL])

	quality_border.color = border_color

	# 更新边框宽度
	var width = BORDER_WIDTH
	if is_selected:
		width = 3.0
	quality_border.size = Vector2(width, width)

func _update_lock_icon() -> void:
	if locked_icon:
		locked_icon.visible = is_locked

# ============ 鼠标事件 ============

func _on_mouse_entered() -> void:
	if hover_overlay:
		hover_overlay.visible = true

	# 显示tooltip - 通过信号请求
	if not is_empty:
		tooltip_requested.emit(item_id, quality, get_global_mouse_position())

func _on_mouse_exited() -> void:
	if hover_overlay:
		hover_overlay.visible = false

	# 隐藏tooltip
	tooltip_hide_requested.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					slot_clicked.emit(slot_index, MOUSE_BUTTON_LEFT)
				MOUSE_BUTTON_RIGHT:
					slot_right_clicked.emit(slot_index)

## 获取物品信息用于拖拽
func get_drag_data(position: Vector2) -> Variant:
	if is_empty or is_locked:
		return null

	is_dragging = true
	drag_started.emit(slot_index)

	# 创建拖拽预览
	var preview = TextureRect.new()
	preview.texture = icon_texture.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(SLOT_SIZE - 4, SLOT_SIZE - 4)
	preview.modulate = Color(1, 1, 1, 0.8)

	var container = Control.new()
	container.add_child(preview)
	preview.position = -preview.custom_minimum_size / 2
	set_drag_preview(container)

	return {
		"item_id": item_id,
		"quantity": quantity,
		"quality": quality,
		"source_slot": slot_index,
		"is_temp": is_temp_slot
	}

## 接收拖拽放置
func can_drop_data(position: Vector2, data: Variant) -> bool:
	if is_locked:
		return false
	if data is Dictionary and data.has("item_id"):
		return true
	return false

func drop_data(position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.has("item_id"):
		# 通知父级处理物品移动
		_on_item_dropped(slot_index, data)

func _on_item_dropped(target_slot: int, data: Dictionary) -> void:
	# 由父级容器处理具体逻辑
	pass

# ============ 动画 ============

## 悬停缩放动画
func _on_hover_enter() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_hover_exit() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# ============ 工具方法 ============

## 获取物品显示名称
func get_item_name() -> String:
	if is_empty:
		return ""
	var item_def = ItemDataSystem.get_item_def(item_id) if ItemDataSystem else null
	return item_def.name if item_def else item_id
