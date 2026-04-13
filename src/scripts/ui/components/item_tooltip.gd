extends PanelContainer

## ItemTooltip - 物品信息提示组件
## 显示物品名称、品质、描述、价格等信息
## 参考: design/gdd/ui/inventory-system.md

# ============ 常量 ============

## 提示框最小宽度
const MIN_WIDTH: int = 180

## 提示框最大宽度
const MAX_WIDTH: int = 280

## 内边距
const PADDING: int = 10

## 品质颜色
const QUALITY_COLORS: Dictionary = {
	Quality.NORMAL: Color(0.7, 0.7, 0.7, 0.9),
	Quality.FINE: Color(0.4, 0.65, 0.4, 0.9),
	Quality.EXCELLENT: Color(0.4, 0.55, 0.75, 0.9),
	Quality.SUPREME: Color(0.6, 0.35, 0.65, 0.9)
}

## 品质名称
const QUALITY_NAMES: Dictionary = {
	Quality.NORMAL: "普通",
	Quality.FINE: "良品",
	Quality.EXCELLENT: "精品",
	Quality.SUPREME: "极品"
}

# ============ 节点引用 ============

var name_label: Label
var quality_label: Label
var description_label: Label
var price_label: Label
var stack_label: Label
var effect_container: VBoxContainer
var divider: HBoxContainer

# ============ 状态 ============

var current_item_id: String = ""
var current_quality: int = Quality.NORMAL
var fade_tween: Tween = null

# ============ 初始化 ============

func _ready() -> void:
	_setup_node_references()
	_setup_styles()
	_update_visibility()

func _process(delta: float) -> void:
	# 跟随鼠标
	if visible:
		var mouse_pos = get_viewport().get_mouse_position()
		var screen_size = get_viewport().get_visible_rect().size
		var tooltip_size = size

		# 计算位置，避免超出屏幕
		var pos = mouse_pos + Vector2(15, 15)
		if pos.x + tooltip_size.x > screen_size.x:
			pos.x = mouse_pos.x - tooltip_size.x - 15
		if pos.y + tooltip_size.y > screen_size.y:
			pos.y = mouse_pos.y - tooltip_size.y - 15

		position = pos

# ============ 节点引用设置 ============

func _setup_node_references() -> void:
	# 延迟获取子节点
	await get_tree().process_frame

	name_label = _find_child_by_path("NameLabel") as Label
	quality_label = _find_child_by_path("QualityLabel") as Label
	description_label = _find_child_by_path("DescriptionLabel") as Label
	price_label = _find_child_by_path("PriceLabel") as Label
	stack_label = _find_child_by_path("StackLabel") as Label
	effect_container = _find_child_by_path("EffectContainer") as VBoxContainer
	divider = _find_child_by_path("Divider") as HBoxContainer

func _find_child_by_path(path: String) -> Node:
	var parts = path.split("/")
	var current = self as Node
	for part in parts:
		if current:
			current = current.get_node_or_null(part)
	return current

# ============ 样式设置 ============

func _setup_styles() -> void:
	# 水墨风格背景
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.02, 0.04, 0.08, 0.95)
	bg_style.corner_radius_top_left = 6
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6
	bg_style.border_color = Color(0.4, 0.45, 0.5, 0.6)
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.content_margin_left = PADDING
	bg_style.content_margin_top = PADDING
	bg_style.content_margin_right = PADDING
	bg_style.content_margin_bottom = PADDING
	add_theme_stylebox_override("panel", bg_style)

# ============ 公开方法 ============

## 显示物品提示
func show_item(item_id: String, quality: int = Quality.NORMAL) -> void:
	if item_id.is_empty():
		hide_item()
		return

	current_item_id = item_id
	current_quality = quality

	_update_content()
	_update_visibility()

	# 淡入动画
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.15)

## 隐藏提示
func hide_item() -> void:
	if not visible:
		return

	current_item_id = ""

	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_callback(func(): _update_visibility())

# ============ 内容更新 ============

func _update_content() -> void:
	_update_name()
	_update_quality()
	_update_description()
	_update_price()
	_update_stack()
	_update_effects()

func _update_name() -> void:
	if not name_label:
		return

	if current_item_id.is_empty():
		name_label.text = ""
		return

	var item_def = ItemDataSystem.get_item_def(current_item_id) if ItemDataSystem else null
	if item_def:
		name_label.text = tr(item_def.name)
	else:
		name_label.text = current_item_id

	# 品质颜色
	var color = QUALITY_COLORS.get(current_quality, QUALITY_COLORS[Quality.NORMAL])
	name_label.add_theme_color_override("font_color", color)

func _update_quality() -> void:
	if not quality_label:
		return

	if current_quality == Quality.NORMAL:
		quality_label.visible = false
		return

	quality_label.text = "[%s]" % QUALITY_NAMES.get(current_quality, "普通")
	quality_label.add_theme_color_override("font_color", QUALITY_COLORS.get(current_quality, Color.WHITE))
	quality_label.visible = true

func _update_description() -> void:
	if not description_label:
		return

	if current_item_id.is_empty():
		description_label.text = ""
		return

	var item_def = ItemDataSystem.get_item_def(current_item_id) if ItemDataSystem else null
	if item_def and not item_def.description.is_empty():
		description_label.text = tr(item_def.description)
		description_label.visible = true
	else:
		description_label.visible = false

func _update_price() -> void:
	if not price_label:
		return

	if current_item_id.is_empty():
		price_label.text = ""
		price_label.visible = false
		return

	var item_def = ItemDataSystem.get_item_def(current_item_id) if ItemDataSystem else null
	if item_def and item_def.sell_price > 0:
		var price = ItemDataSystem.calculate_sell_price(item_def.sell_price, current_quality)
		price_label.text = "售价: %d 金" % price
		price_label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.3, 1.0))
		price_label.visible = true
	else:
		price_label.visible = false

func _update_stack() -> void:
	if not stack_label:
		return

	if current_item_id.is_empty():
		stack_label.text = ""
		stack_label.visible = false
		return

	var item_def = ItemDataSystem.get_item_def(current_item_id) if ItemDataSystem else null
	if item_def and item_def.max_stack > 1:
		stack_label.text = "堆叠上限: %d" % item_def.max_stack
		stack_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.8))
		stack_label.visible = true
	else:
		stack_label.visible = false

func _update_effects() -> void:
	if not effect_container:
		return

	# 清除旧效果
	for child in effect_container.get_children():
		child.queue_free()

	if current_item_id.is_empty():
		return

	var item_def = ItemDataSystem.get_item_def(current_item_id) if ItemDataSystem else null
	if not item_def:
		return

	# 添加物品效果描述
	if item_def.edible:
		_add_effect_line("可食用", Color(0.4, 0.8, 0.4, 1.0))
		if item_def.stamina_restore > 0:
			_add_effect_line("体力 +%d" % item_def.stamina_restore, Color(0.2, 0.8, 0.4, 1.0))
		if item_def.health_restore > 0:
			_add_effect_line("HP +%d" % item_def.health_restore, Color(0.9, 0.3, 0.3, 1.0))

	if item_def.category == ItemDataSystem.ItemCategory.SEED:
		if item_def.growth_days > 0:
			_add_effect_line("成熟时间: %d 天" % item_def.growth_days, Color(0.6, 0.8, 0.4, 1.0))

func _add_effect_line(text: String, color: Color) -> void:
	if not effect_container:
		return

	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	effect_container.add_child(label)

func _update_visibility() -> void:
	visible = not current_item_id.is_empty()
	modulate.a = 1.0 if visible else 0.0
