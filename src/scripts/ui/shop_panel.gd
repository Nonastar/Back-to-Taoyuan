extends PanelContainer

# UITokens-based theming for consistent visuals
const UITokens = preload("res://src/design/ui_tokens.gd")

## ShopPanel - 商店UI面板
## 负责显示商店界面和处理购买/出售交互

# ============ 模式枚举 ============

enum ShopMode { BUY, SELL }
enum ShopType { GENERAL, ANIMAL }

# ============ 属性 ============

var current_mode: ShopMode = ShopMode.BUY
var current_shop_type: ShopType = ShopType.GENERAL
var selected_item_id: String = ""
var selected_item_name: String = ""
var selected_item_price: int = 0
var current_quantity: int = 1
var max_quantity: int = 99

# Keyboard navigation support for shop item list
var item_select_buttons: Array = []
var current_item_index: int = -1
var _all_items: Array = []  # 当前商品列表，用于按索引查找

# ============ 选中高亮 ============

var _selected_card_index: int = -1
var _selected_card: PanelContainer = null

# 缓存的卡片样式（避免每次高亮都重新创建 StyleBoxFlat）
var _card_base_style: StyleBoxFlat = null
var _card_highlight_style: StyleBoxFlat = null

func _ensure_card_styles() -> void:
	if _card_base_style == null:
		_card_base_style = StyleBoxFlat.new()
		_card_base_style.bg_color = Color(0.18, 0.18, 0.22, 0.8)
		_card_base_style.border_color = Color(0.3, 0.3, 0.35, 1.0)
		_card_base_style.border_width_left = 1
		_card_base_style.border_width_top = 1
		_card_base_style.border_width_right = 1
		_card_base_style.border_width_bottom = 1
		_card_base_style.corner_radius_top_left = 4
		_card_base_style.corner_radius_top_right = 4
		_card_base_style.corner_radius_bottom_right = 4
		_card_base_style.corner_radius_bottom_left = 4
		_card_base_style.content_margin_left = 8
		_card_base_style.content_margin_right = 8
		_card_base_style.content_margin_top = 6
		_card_base_style.content_margin_bottom = 6
	if _card_highlight_style == null:
		_card_highlight_style = StyleBoxFlat.new()
		_card_highlight_style.bg_color = Color(0.3, 0.25, 0.0, 0.35)
		_card_highlight_style.border_color = Color(1.0, 0.84, 0.0, 1.0)
		_card_highlight_style.border_width_left = 2
		_card_highlight_style.border_width_top = 2
		_card_highlight_style.border_width_right = 2
		_card_highlight_style.border_width_bottom = 2
		_card_highlight_style.corner_radius_top_left = 4
		_card_highlight_style.corner_radius_top_right = 4
		_card_highlight_style.corner_radius_bottom_right = 4
		_card_highlight_style.corner_radius_bottom_left = 4
		_card_highlight_style.content_margin_left = 8
		_card_highlight_style.content_margin_right = 8
		_card_highlight_style.content_margin_top = 6
		_card_highlight_style.content_margin_bottom = 6

## 应用选中卡片高亮（金色边框 + 背景微亮）
func _highlight_card(card: Control, selected: bool) -> void:
	if not card:
		return
	_ensure_card_styles()
	if selected:
		card.add_theme_stylebox_override("panel", _card_highlight_style)
	else:
		card.add_theme_stylebox_override("panel", _card_base_style)

# ============ UI节点 ============

var close_button: Button
var tab_general: Button
var tab_animal: Button
var buy_button: Button
var sell_button: Button
var action_button: Button
var item_grid: GridContainer
var quantity_minus: Button
var quantity_plus: Button
var quantity_label: Label
var selected_item_label: Label
var price_display: Label
var status_label: Label

# ============ 生命周期 ============

func _ready() -> void:
	_init_node_references()
	_connect_signals()
	_setup_dynamic_styles()
	# 确保所有按钮接受鼠标事件（Godot 4 stylebox 会重置 mouse_filter）
	for btn in [close_button, tab_general, tab_animal, buy_button, sell_button, action_button, quantity_minus, quantity_plus]:
		if btn:
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_update_ui()
	_focus_first_item_if_any()

func _init_node_references() -> void:
	close_button = get_node_or_null("VBox/Header/CloseBtn")
	tab_general = get_node_or_null("VBox/ShopTypeTabs/TabGeneral")
	tab_animal = get_node_or_null("VBox/ShopTypeTabs/TabAnimal")
	buy_button = get_node_or_null("VBox/ModeTabs/BuyBtn")
	sell_button = get_node_or_null("VBox/ModeTabs/SellBtn")
	action_button = get_node_or_null("VBox/ModeTabs/ActionBtn")
	item_grid = get_node_or_null("VBox/ItemScroll/ItemGrid")
	quantity_minus = get_node_or_null("VBox/QBox/Minus")
	quantity_plus = get_node_or_null("VBox/QBox/Plus")
	quantity_label = get_node_or_null("VBox/QBox/QtyLabel")
	selected_item_label = get_node_or_null("VBox/InfoBar/SelectedItem")
	price_display = get_node_or_null("VBox/InfoBar/PriceDisplay")
	status_label = get_node_or_null("VBox/StatusBar")

func _connect_signals() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if tab_general:
		tab_general.pressed.connect(_on_tab_general_pressed)
	if tab_animal:
		tab_animal.pressed.connect(_on_tab_animal_pressed)
	if buy_button:
		buy_button.pressed.connect(_on_buy_pressed)
	if sell_button:
		sell_button.pressed.connect(_on_sell_pressed)
	if action_button:
		action_button.pressed.connect(_on_action_pressed)
	if quantity_minus:
		quantity_minus.pressed.connect(_on_quantity_minus)
	if quantity_plus:
		quantity_plus.pressed.connect(_on_quantity_plus)

func _setup_dynamic_styles() -> void:
	if not has_method("add_theme_stylebox_override"):
		return
	# 面板样式
	add_theme_stylebox_override("panel", _make_panel_style(UITokens.PANEL_BG))
	# 按钮样式
	_apply_button_styles(buy_button, UITokens.BUTTON_NORMAL)
	_apply_button_styles(sell_button, UITokens.BUTTON_NORMAL)
	_apply_button_styles(action_button, UITokens.BUTTON_NORMAL)

## 制作面板样式
func _make_panel_style(bg_color: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg_color
	s.border_color = UITokens.PANEL_BORDER
	s.corner_radius_top_left = UITokens.RADIUS_MD
	s.corner_radius_top_right = UITokens.RADIUS_MD
	s.corner_radius_bottom_right = UITokens.RADIUS_MD
	s.corner_radius_bottom_left = UITokens.RADIUS_MD
	s.content_margin_left = UITokens.SPACE_16
	s.content_margin_right = UITokens.SPACE_16
	s.content_margin_top = UITokens.SPACE_16
	s.content_margin_bottom = UITokens.SPACE_16
	return s

## 制作按钮样式并附加到按钮（含 normal/hover/pressed 三态）
func _apply_button_styles(btn: Button, normal_color: Color) -> void:
	if not btn:
		return
	var normal_style = _make_button_style(normal_color)
	btn.add_theme_stylebox_override("normal", normal_style)
	var hover_style = _make_button_style(UITokens.BUTTON_HOVER)
	btn.add_theme_stylebox_override("hover", hover_style)
	var pressed_style = _make_button_style(UITokens.BUTTON_PRESSED)
	btn.add_theme_stylebox_override("pressed", pressed_style)

## 制作按钮样式（通用布局参数）
func _make_button_style(bg_color: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg_color
	s.border_color = UITokens.PANEL_BORDER
	s.corner_radius_top_left = UITokens.RADIUS_MD
	s.corner_radius_top_right = UITokens.RADIUS_MD
	s.corner_radius_bottom_left = UITokens.RADIUS_MD
	s.corner_radius_bottom_right = UITokens.RADIUS_MD
	s.content_margin_left = UITokens.SPACE_16
	s.content_margin_right = UITokens.SPACE_16
	s.content_margin_top = UITokens.SPACE_8
	s.content_margin_bottom = UITokens.SPACE_8
	return s

func _focus_first_item_if_any() -> void:
	item_select_buttons.clear()
	# Collect existing select buttons if any are present after populate
	var grid = get_node_or_null("VBox/ItemScroll/ItemGrid")
	if grid:
		for child in grid.get_children():
			if child is PanelContainer:
				# The item card contains a button named "选择" we can locate by traversal
				var btn = child.get_node_or_null("HBoxContainer/Button")
				if btn:
					item_select_buttons.append(btn)
	if item_select_buttons.size() > 0:
		current_item_index = 0
		item_select_buttons[0].grab_focus()

func _focus_next_item() -> void:
	if item_select_buttons.size() == 0:
		return
	current_item_index = (current_item_index + 1) % item_select_buttons.size()
	item_select_buttons[current_item_index].grab_focus()

func _focus_previous_item() -> void:
	if item_select_buttons.size() == 0:
		return
	current_item_index = (current_item_index - 1) % item_select_buttons.size()
	item_select_buttons[current_item_index].grab_focus()

func _unhandled_input(event) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("ui_cancel"):
			close_panel()
			return
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
			_focus_previous_item()
			return
		if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
			_focus_next_item()
			return
		if event.is_action_pressed("ui_accept"):
			if current_item_index >= 0 and current_item_index < item_select_buttons.size():
				item_select_buttons[current_item_index].emit_signal("pressed")
			return

	# Keyboard navigation handled in _unhandled_input

# ============ 公开方法 ============

func open_panel(mode: int = ShopMode.BUY, shop_type: int = ShopType.GENERAL) -> void:
	current_mode = mode
	current_shop_type = shop_type
	visible = true
	mouse_filter = Control.MOUSE_FILTER_PASS  # 让 ShopPanel 接收 _gui_input
	_clear_selection()
	_populate_items()
	_update_ui()
	item_select_buttons.clear()
	current_item_index = -1
	_focus_first_item_if_any()

func close_panel() -> void:
	visible = false
	_clear_selection()

# ============ 商品列表 ============

func _populate_items() -> void:
	if not item_grid:
		return
	
	# 清除现有项
	for child in item_grid.get_children():
		child.queue_free()
	
	# 获取物品列表 - 根据模式选择数据源
	var items: Array = []
	if current_mode == ShopMode.SELL:
		items = _get_sell_items()
	else:
		# 购买模式显示商店物品
		if current_shop_type == ShopType.GENERAL:
			items = _get_general_store_items()
		else:
			items = _get_animal_shop_items()
	
	if items.is_empty():
		var label = Label.new()
		label.text = I18n.translate("ui.no_products")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_grid.add_child(label)
		_all_items.clear()
		return

	_all_items = items
	# 创建商品卡片
	for i in range(items.size()):
		var card = _create_item_card(items[i], i)
		item_grid.add_child(card)

func _get_general_store_items() -> Array:
	var items: Array = []
	if Shop and Shop.has_method("get_shop_inventory"):
		items = Shop.get_shop_inventory(Shop.ShopId.GENERAL_STORE)
	elif Shop and Shop.has_method("get_general_store_items"):
		items = Shop.get_general_store_items()
	return items

func _get_sell_items() -> Array:
	# 出售模式：从玩家背包获取可出售物品
	var sell_items: Array = []
	
	# 获取背包内容
	var backpack_contents = []
	if InventorySystem and InventorySystem.has_method("get_backpack_contents"):
		backpack_contents = InventorySystem.get_backpack_contents()
	
	# 按物品ID聚合，统计每种物品的总数量
	var item_aggregation: Dictionary = {}
	for slot in backpack_contents:
		var item_id = slot.get("item_id", "")
		var quantity = slot.get("quantity", 0)

		if item_id.is_empty() or quantity <= 0:
			continue

		# 获取物品定义（一次查询，复用于名称和价格）
		var item_def = null
		if ItemDataSystem and ItemDataSystem.has_method("get_item_def"):
			item_def = ItemDataSystem.get_item_def(item_id)

		if item_def == null:
			continue

		# 聚合物品（同时缓存 item_def 供后续价格计算复用）
		if not item_aggregation.has(item_id):
			item_aggregation[item_id] = {
				"item_id": item_id,
				"name": item_def.name,
				"total_quantity": 0,
				"icon": "📦",
				"item_def": item_def  # 缓存以避免重复查询
			}
		item_aggregation[item_id]["total_quantity"] += quantity

	# 转换为列表
	var sell_multiplier: float = 0.5 if not Shop or not Shop.has_method("get_sell_price_multiplier") else Shop.get_sell_price_multiplier()
	for item_id in item_aggregation:
		var item_data = item_aggregation[item_id]
		var item_def: Dictionary = item_data["item_def"]
		var sell_price = int(item_def.sell_price * sell_multiplier) if item_def else 0

		sell_items.append({
			"item_id": item_data["item_id"],
			"name": item_data["name"],
			"price": sell_price,
			"stock": item_data["total_quantity"],
			"icon": item_data["icon"]
		})
	
	return sell_items

func _get_animal_shop_items() -> Array:
	if Shop and Shop.has_method("get_shop_inventory"):
		return Shop.get_shop_inventory(Shop.ShopId.ANIMAL_SHOP)
	return []

func _create_item_card(item: Dictionary, index: int) -> PanelContainer:
	var card = _Card.new(item, index, self)
	card.custom_minimum_size = Vector2(280, 70)
	return card

func _on_select_item(item: Dictionary) -> void:
	selected_item_id = item.get("item_id", "")
	selected_item_name = item.get("name", selected_item_id)
	selected_item_price = item.get("price", 0)
	var stock = item.get("stock", -1)
	max_quantity = stock if stock > 0 else 99
	current_quantity = 1

	# 清除上一个选中卡片的高亮
	if _selected_card != null:
		_highlight_card(_selected_card, false)

	# 找到并高亮当前卡片
	_selected_card = null
	if item_grid:
		for c in item_grid.get_children():
			if c.has_meta("item_id") and c.get_meta("item_id") == selected_item_id:
				_selected_card = c
				_highlight_card(_selected_card, true)
				break

	_update_selection_display()
	_update_ui()

func _update_selection_display() -> void:
	if selected_item_label:
		selected_item_label.text = selected_item_name if selected_item_name else "请选择商品"
	if price_display:
		var total = selected_item_price * current_quantity
		price_display.text = I18n.trf("ui.total_price", [total])
		
		# 显示好感度折扣提示 (如果有)
		if current_mode == ShopMode.BUY:
			# 暂时显示原价，未来接入好感度系统
			pass

# ============ 信号处理 ============

func _on_close_pressed() -> void:
	close_panel()

func _on_tab_general_pressed() -> void:
	current_shop_type = ShopType.GENERAL
	_clear_selection()
	_populate_items()
	_update_ui()

func _on_tab_animal_pressed() -> void:
	current_shop_type = ShopType.ANIMAL
	_clear_selection()
	_populate_items()
	_update_ui()

func _on_buy_pressed() -> void:
	current_mode = ShopMode.BUY
	_update_ui()

func _on_sell_pressed() -> void:
	current_mode = ShopMode.SELL
	_update_ui()

func _on_action_pressed() -> void:
	if selected_item_id.is_empty():
		_set_status(I18n.translate("ui.select_first"))
		return
	
	# 检查背包空间 (购买时)
	# 购买时检查背包空间（Shop.buy_item也会检查，但提前检查可以给出更友好的提示）
	if current_mode == ShopMode.BUY:
		# 简单检查：如果背包满了，buy_item会返回失败
		# 这里不做预检查，让buy_item处理
		pass
	
	var result = {}
	var shop_id = Shop.ShopId.GENERAL_STORE if current_shop_type == ShopType.GENERAL else Shop.ShopId.ANIMAL_SHOP
	
	if current_mode == ShopMode.BUY:
		result = Shop.buy_item(shop_id, selected_item_id, current_quantity)
	else:
		result = Shop.sell_item(shop_id, selected_item_id, current_quantity)
	
	if result.get("success", false):
		var msg: String = I18n.translate(result.get("message", "成功"))
		if current_mode == ShopMode.BUY:
			msg += " " + I18n.trf("ui.spent", [result.get("total_cost", 0)])
		else:
			msg += " " + I18n.trf("ui.earned", [result.get("money_earned", 0)])
		_set_status(msg)
		_populate_items()
	else:
		_set_status(I18n.translate("ui.failed") + result.get("message", I18n.translate("ui.unknown_error")))
	
	_clear_selection()

func _on_quantity_minus() -> void:
	if current_quantity > 1:
		current_quantity -= 1
		_update_quantity_label()
		_update_selection_display()

func _on_quantity_plus() -> void:
	if current_quantity < max_quantity:
		current_quantity += 1
		_update_quantity_label()
		_update_selection_display()

func _clear_selection() -> void:
	if _selected_card != null:
		_highlight_card(_selected_card, false)
	_selected_card = null
	selected_item_id = ""
	selected_item_name = ""
	selected_item_price = 0
	current_quantity = 1
	max_quantity = 99
	_update_quantity_label()
	_update_selection_display()

func _update_quantity_label() -> void:
	if quantity_label:
		quantity_label.text = str(current_quantity)

func _update_ui() -> void:
	if buy_button:
		buy_button.disabled = current_mode == ShopMode.BUY
	if sell_button:
		sell_button.disabled = current_mode == ShopMode.SELL
	if action_button:
		action_button.text = I18n.translate("ui.buy") if current_mode == ShopMode.BUY else I18n.translate("ui.sell")
		action_button.disabled = selected_item_id.is_empty()
	if tab_general:
		tab_general.disabled = current_shop_type == ShopType.GENERAL
	if tab_animal:
		tab_animal.disabled = current_shop_type == ShopType.ANIMAL

func _set_status(msg: String) -> void:
	if status_label:
		status_label.text = msg

# ============ 商品卡片类 ============
# 独立类处理点击事件，避免 gui_input 信号兼容性问题

class _Card extends PanelContainer:
	var _item: Dictionary
	var _index: int
	var _owner: Node

	func _init(item: Dictionary, index: int, owner: Node):
		_item = item
		_index = index
		_owner = owner
		_setup_ui()

	func _setup_ui() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_meta("card_index", _index)
		set_meta("item_id", _item.get("item_id", ""))

		# 基础背景样式
		var base_style = StyleBoxFlat.new()
		base_style.bg_color = Color(0.18, 0.18, 0.22, 0.8)
		base_style.border_color = Color(0.3, 0.3, 0.35, 1.0)
		base_style.border_width_left = 1
		base_style.border_width_top = 1
		base_style.border_width_right = 1
		base_style.border_width_bottom = 1
		base_style.corner_radius_top_left = 4
		base_style.corner_radius_top_right = 4
		base_style.corner_radius_bottom_right = 4
		base_style.corner_radius_bottom_left = 4
		base_style.content_margin_left = 8
		base_style.content_margin_right = 8
		base_style.content_margin_top = 6
		base_style.content_margin_bottom = 6
		add_theme_stylebox_override("panel", base_style)

		var hbox = HBoxContainer.new()
		add_child(hbox)

		# 图标
		var icon = Label.new()
		icon.text = _item.get("icon", "📦")
		icon.custom_minimum_size.x = 50
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(icon)

		# 名称和价格
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info)

		var name_label = Label.new()
		name_label.text = _item.get("name", _item.get("item_id", "?"))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(name_label)

		var price_label = Label.new()
		price_label.text = "%dg" % _item.get("price", 0)
		info.add_child(price_label)

		# 库存信息
		var stock = _item.get("stock", -1)
		if stock > 0:
			var stock_label = Label.new()
			stock_label.text = I18n.trf("ui.stock", [stock])
			info.add_child(stock_label)

		# 点击选择提示
		var select_label = Label.new()
		select_label.text = I18n.translate("ui.click_to_select")
		hbox.add_child(select_label)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_owner._on_select_item(_item)
