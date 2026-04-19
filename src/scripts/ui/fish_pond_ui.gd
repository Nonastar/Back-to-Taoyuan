class_name FishPondUI
extends CanvasLayer

## FishPondUI - 鱼塘管理界面
## 显示鱼塘状态，放入/取出鱼类，收获产物
## 增强版: 支持建造、选中移除、放入鱼类列表
##
## 依赖系统:
## - FishPondSystem: 鱼塘数据源
## - InventorySystem: 背包物品查询

# ============ 常量 ============

## 颜色常量
const COLOR_SELECTED_BG: Color = Color(0.89, 0.95, 0.99, 1)  # #E3F2FD
const COLOR_MATURE: Color = Color(0.3, 0.69, 0.31, 1)  # #4CAF50
const COLOR_IMMATURE: Color = Color(0.62, 0.62, 0.62, 1)  # #9E9E9E
const COLOR_DISABLE: Color = Color(0.5, 0.5, 0.5, 1)

## 透明度常量
const IMMATURE_OPACITY: float = 0.7

## 悬停效果常量
const HOVER_BRIGHTNESS: float = 1.15

# ============ 节点引用 ============

var _background: ColorRect
var _build_panel: PanelContainer  # 未建造时显示
var _main_panel: PanelContainer    # 已建造时显示
var _fish_count_label: Label
var _capacity_label: Label
var _fish_vbox: VBoxContainer
var _product_hbox: HBoxContainer
var _collect_button: Button
var _remove_button: Button
var _add_fish_container: VBoxContainer
var _add_fish_btn: Button
var _add_fish_expanded: bool = false
var _close_button: Button

## 建造面板节点
var _build_cost_vbox: VBoxContainer
var _build_button: Button

## 鱼类卡片状态
var _selected_indices: Array[int] = []
var _fish_cards: Array = []

# ============ 单例 ============

static var _instance: FishPondUI = null

static func get_instance() -> FishPondUI:
	return _instance

func _t(text: String) -> String:
	return tr(text)

func _fmt(template: String, values: Dictionary) -> String:
	var result = _t(template)
	for key in values.keys():
		result = result.replace("{" + str(key) + "}", str(values[key]))
	return result

static func show_pond_ui() -> void:
	if _instance == null:
		push_warning("[FishPondUI] Instance not found")
		return
	_instance.show_ui()

static func hide_pond_ui() -> void:
	if _instance == null:
		return
	_instance.hide_ui()

static func toggle() -> void:
	if _instance == null:
		return
	if _instance.visible:
		_instance.hide_ui()
	else:
		_instance.show_ui()

# ============ 初始化 ============

func _ready() -> void:
	_instance = self
	add_to_group("fish_pond_ui")  # 添加到组以便全局访问
	_setup_node_references()
	_connect_signals()
	hide_ui()
	print("[FishPondUI] Initialized")

func _setup_node_references() -> void:
	_background = $Background if has_node("Background") else null
	_build_panel = $BuildPanel if has_node("BuildPanel") else null
	_main_panel = $MainPanel if has_node("MainPanel") else null

	# 设置建造面板节点
	if _build_panel:
		var vbox = _build_panel.get_node_or_null("VBox")
		if vbox:
			_build_cost_vbox = vbox.get_node_or_null("CostList")
			var btn_container = vbox.get_node_or_null("ButtonContainer")
			if btn_container:
				_build_button = btn_container.get_node_or_null("BuildButton")

	# 设置主面板节点
	if _main_panel:
		var vbox = _main_panel.get_node_or_null("VBox")
		if vbox:
			var header = vbox.get_node_or_null("Header")
			if header:
				var count_section = header.get_node_or_null("CountSection")
				if count_section:
					_fish_count_label = count_section.get_node_or_null("FishCount")
					_capacity_label = count_section.get_node_or_null("Capacity")

			var fish_section = vbox.get_node_or_null("FishSection")
			if fish_section:
				var fish_scroll = fish_section.get_node_or_null("FishScroll")
				if fish_scroll:
					_fish_vbox = fish_scroll.get_node_or_null("FishVBox")

			var product_section = vbox.get_node_or_null("ProductSection")
			if product_section:
				_product_hbox = product_section.get_node_or_null("ProductList")

			var action_buttons = vbox.get_node_or_null("ActionButtons")
			if action_buttons:
				_remove_button = action_buttons.get_node_or_null("RemoveButton")
				_collect_button = action_buttons.get_node_or_null("CollectButton")

			var add_fish_section = vbox.get_node_or_null("AddFishSection")
			if add_fish_section:
				_add_fish_btn = add_fish_section.get_node_or_null("AddFishButton")
				_add_fish_container = add_fish_section.get_node_or_null("FishList")
				if _add_fish_container:
					_add_fish_container.visible = false

			var bottom_buttons = vbox.get_node_or_null("BottomButtons")
			if bottom_buttons:
				_close_button = bottom_buttons.get_node_or_null("CloseButton")

	# 设置悬停效果
	_setup_hover_effect(_build_button)
	_setup_hover_effect(_remove_button)
	_setup_hover_effect(_collect_button)
	_setup_hover_effect(_add_fish_btn)
	_setup_hover_effect(_close_button)

func _connect_signals() -> void:
	# 建造按钮
	if _build_button:
		_build_button.pressed.connect(_on_build_pressed)

	# 操作按钮
	if _remove_button:
		_remove_button.pressed.connect(_on_remove_pressed)
	if _collect_button:
		_collect_button.pressed.connect(_on_collect_pressed)
	if _add_fish_btn:
		_add_fish_btn.pressed.connect(_on_add_fish_toggled)
	if _close_button:
		_close_button.pressed.connect(_on_close_pressed)

	# FishPondSystem 信号
	if FishPondSystem:
		FishPondSystem.pond_state_changed.connect(_on_pond_state_changed)
		FishPondSystem.product_collected.connect(_on_product_collected)

# ============ 显示/隐藏 ============

func show_ui() -> void:
	_update_display()
	visible = true
	_modulate_panel(true)

	# 默认焦点到关闭按钮
	if _close_button:
		_close_button.grab_focus()

func hide_ui() -> void:
	_modulate_panel(false)
	await get_tree().create_timer(0.25).timeout
	visible = false

func _modulate_panel(show: bool) -> void:
	var panel_to_animate = _build_panel if _build_panel and _build_panel.visible else _main_panel
	if not panel_to_animate:
		return

	var tween = create_tween()
	if show:
		panel_to_animate.modulate = Color(1, 1, 1, 0)
		panel_to_animate.scale = Vector2(0.95, 0.95)
		tween.tween_property(panel_to_animate, "modulate:a", 1.0, 0.2)
		tween.parallel().tween_property(panel_to_animate, "scale", Vector2(1, 1), 0.2)
	else:
		tween.tween_property(panel_to_animate, "modulate:a", 0.0, 0.2)
		tween.parallel().tween_property(panel_to_animate, "scale", Vector2(0.95, 0.95), 0.2)

# ============ 更新显示 ============

func _update_display() -> void:
	if not FishPondSystem:
		return

	_selected_indices.clear()

	var is_built = FishPondSystem.is_built()

	# 切换面板显示
	if _build_panel:
		_build_panel.visible = not is_built
	if _main_panel:
		_main_panel.visible = is_built

	if is_built:
		_update_main_panel()
	else:
		_update_build_panel()

func _update_build_panel() -> void:
	# 更新建造费用显示
	if _build_cost_vbox:
		# 清空现有
		for child in _build_cost_vbox.get_children():
			child.queue_free()

		# 显示费用
		var cost = FishPondSystem.get_build_cost() if FishPondSystem else {}

		_add_cost_item("💰 金币", cost.get("money", 5000), PlayerStats.get_money() if PlayerStats else 0)
		_add_cost_item("🪵 木材", cost.get("wood", 100), InventorySystem.get_item_count("wood") if InventorySystem else 0)
		_add_cost_item("🎋 竹子", cost.get("bamboo", 50), InventorySystem.get_item_count("bamboo") if InventorySystem else 0)

	# 更新建造按钮状态
	if _build_button:
		var can_build = FishPondSystem.can_build() if FishPondSystem else false
		_build_button.disabled = not can_build

func _add_cost_item(emoji_name: String, needed: int, have: int) -> void:
	if not _build_cost_vbox:
		return

	var label = Label.new()
	var status = "✅" if have >= needed else "❌"
	label.text = _fmt("{emoji} x{needed} ({status}持有: {have})", {
		"emoji": emoji_name,
		"needed": needed,
		"status": status,
		"have": have
	})
	label.modulate = COLOR_MATURE if have >= needed else COLOR_DISABLE
	_build_cost_vbox.add_child(label)

func _update_main_panel() -> void:
	# 更新鱼类数量
	var fish_count = FishPondSystem.get_fish_count() if FishPondSystem else 0
	var capacity = FishPondSystem.get_capacity() if FishPondSystem else 5

	if _fish_count_label:
		_fish_count_label.text = str(fish_count)
	if _capacity_label:
		_capacity_label.text = str(capacity)

	# 更新鱼类列表
	_update_fish_list()

	# 更新产物列表
	_update_product_list()

	# 更新按钮状态
	_update_button_states()

	# 更新放入鱼类列表
	_update_add_fish_list()

func _update_fish_list() -> void:
	if not _fish_vbox:
		return

	# 清空现有列表
	for child in _fish_vbox.get_children():
		child.queue_free()
	_fish_cards.clear()

	var fish_list = FishPondSystem.get_fish_list() if FishPondSystem else []

	for i in range(fish_list.size()):
		var fish = fish_list[i]
		var card = _create_fish_card(fish, i)
		_fish_vbox.add_child(card)
		_fish_cards.append(card)

	# 如果没有鱼
	if fish_list.is_empty():
		var label = Label.new()
		label.text = _t("  (鱼塘是空的)")
		label.modulate = COLOR_DISABLE
		_fish_vbox.add_child(label)

func _create_fish_card(fish: Dictionary, index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 48)

	# 未成熟降低透明度
	if not fish.get("is_mature", false):
		panel.modulate = Color(1, 1, 1, IMMATURE_OPACITY)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	# 复选框
	var checkbox = CheckBox.new()
	checkbox.pressed.connect(_on_fish_checkbox_toggled.bind(index))
	hbox.add_child(checkbox)

	# 鱼类 Emoji
	var emoji_label = Label.new()
	emoji_label.text = _get_fish_emoji(fish.get("fish_id", ""))
	emoji_label.custom_minimum_size = Vector2(32, 0)
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(emoji_label)

	# 鱼类名称
	var name_label = Label.new()
	name_label.text = fish.get("name", _t("未知"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	# 天数
	var days_label = Label.new()
	days_label.text = _fmt("第{day}天", {"day": fish.get("days_in_pond", 0)})
	days_label.custom_minimum_size = Vector2(70, 0)
	hbox.add_child(days_label)

	# 成熟状态
	var status_label = Label.new()
	if fish.get("is_mature", false):
		status_label.text = _t("✅成熟")
		status_label.modulate = COLOR_MATURE
	else:
		status_label.text = _t("⏳未成熟")
		status_label.modulate = COLOR_IMMATURE
	status_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(status_label)

	# 产出率
	var rate_label = Label.new()
	rate_label.text = "★%.0f%%" % (fish.get("production_rate", 0) * 100)
	rate_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(rate_label)

	return panel

func _get_fish_emoji(fish_id: String) -> String:
	# 简单的 Emoji 映射
	var emoji_map = {
		"bluegill": "🐟", "carp": "🐟", "grass_fish": "🐟",
		"koi": "🐠", "golden_fish": "🐠",
		"turtle": "🐢",
		"bass": "🐟", "catfish": "🐟", "eel": "🐍",
		"rainbow_trout": "🐟",
		"swamp_loach": "🐟", "snail": "🐌",
		"cave_fish": "🐟"
	}
	return emoji_map.get(fish_id, "🐟")

func _update_product_list() -> void:
	if not _product_hbox:
		return

	# 清空现有
	for child in _product_hbox.get_children():
		child.queue_free()

	var products = FishPondSystem.get_pending_products() if FishPondSystem else []

	if products.is_empty():
		var label = Label.new()
		label.text = _t("(无待收获产物)")
		label.modulate = COLOR_DISABLE
		_product_hbox.add_child(label)
	else:
		for product in products:
			var badge = _create_product_badge(product)
			_product_hbox.add_child(badge)

func _create_product_badge(product: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("normal", _create_flat_style(Color(0.2, 0.3, 0.4, 0.8)))

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	# 品质图标
	var quality_label = Label.new()
	var quality = product.get("quality", "normal")
	match quality:
		"excellent":
			quality_label.text = "⭐"
		"fine":
			quality_label.text = "✨"
		_:
			quality_label.text = "🐟"
	hbox.add_child(quality_label)

	# 名称和数量
	var info_label = Label.new()
	info_label.text = "%sx%d" % [product.get("product_id", "?"), product.get("quantity", 1)]
	hbox.add_child(info_label)

	return panel

func _create_flat_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.set_bg_color(color)
	style.set_corner_radius_all(4)
	return style

func _update_button_states() -> void:
	if not FishPondSystem:
		return

	var has_selection = not _selected_indices.is_empty()
	var has_products = FishPondSystem.has_products_to_collect()

	# 移除按钮
	if _remove_button:
		_remove_button.disabled = not has_selection

	# 收获按钮
	if _collect_button:
		_collect_button.disabled = not has_products

func _update_add_fish_list() -> void:
	if not _add_fish_container:
		return

	# 清空现有
	for child in _add_fish_container.get_children():
		child.queue_free()

	var fish_list = FishPondSystem.get_pondable_fish_list() if FishPondSystem else []

	for fish in fish_list:
		var fish_id = fish.get("fish_id", "")
		var in_inventory = InventorySystem.get_item_count(fish_id) > 0 if InventorySystem else false
		var can_add = FishPondSystem.can_add_fish(fish_id) if FishPondSystem else false

		var row = _create_add_fish_row(fish, in_inventory and can_add)
		_add_fish_container.add_child(row)

# ============ 鱼类选择 ============

func _on_fish_checkbox_toggled(index: int, pressed: bool) -> void:
	if pressed:
		if not _selected_indices.has(index):
			_selected_indices.append(index)
	else:
		_selected_indices.erase(index)

	_update_button_states()

# ============ 信号处理 ============

func _on_pond_state_changed() -> void:
	_update_display()

func _on_product_collected(product_id: String, quality: String, quantity: int) -> void:
	_show_notification(_fmt("收获了: {item} x{count}", {"item": product_id, "count": quantity}))

func _on_build_pressed() -> void:
	if not FishPondSystem:
		return

	if FishPondSystem.build_pond():
		_show_notification(_t("鱼塘建造成功!"))
	else:
		_show_notification(_t("建造失败: 材料不足"))

func _on_remove_pressed() -> void:
	if not FishPondSystem or _selected_indices.is_empty():
		return

	# 按索引倒序移除（避免移除后索引变化）
	var sorted_indices = _selected_indices.duplicate()
	sorted_indices.sort()
	sorted_indices.reverse()

	var removed_count = 0
	for index in sorted_indices:
		if FishPondSystem.remove_fish(index):
			removed_count += 1

	_selected_indices.clear()
	_show_notification(_fmt("取出了 {count} 条鱼", {"count": removed_count}))

func _on_collect_pressed() -> void:
	if not FishPondSystem:
		return

	var collected = FishPondSystem.collect_products()
	if collected > 0:
		_show_notification(_fmt("收获了 {count} 件产物!", {"count": collected}))
	else:
		_show_notification(_t("没有可收获的产物"))

func _on_add_fish_toggled() -> void:
	_add_fish_expanded = not _add_fish_expanded

	if _add_fish_container:
		_add_fish_container.visible = _add_fish_expanded

	if _add_fish_btn:
		_add_fish_btn.text = _t("➕ 放入鱼类") if not _add_fish_expanded else _t("➖ 收起列表")

func _on_add_fish_row_pressed(fish_id: String) -> void:
	if not FishPondSystem:
		return

	if FishPondSystem.add_fish(fish_id):
		# 获取鱼类名称
		var pondable_list = FishPondSystem.get_pondable_fish_list()
		var name = fish_id
		for fish in pondable_list:
			if fish.get("fish_id") == fish_id:
				name = fish.get("name", fish_id)
				break
		_show_notification(_fmt("放入了: {name}", {"name": name}))
		# 刷新显示
		_update_display()
	else:
		_show_notification(_t("放入失败: 鱼塘已满或背包没有这条鱼"))

func _create_add_fish_row(fish: Dictionary, can_add: bool) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 40)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	# 鱼类 Emoji
	var emoji_label = Label.new()
	emoji_label.text = _get_fish_emoji(fish.get("fish_id", ""))
	emoji_label.custom_minimum_size = Vector2(32, 0)
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(emoji_label)

	# 名称
	var name_label = Label.new()
	name_label.text = fish.get("name", _t("未知"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	# 背包数量
	var inv_count = InventorySystem.get_item_count(fish.get("fish_id", "")) if InventorySystem else 0
	var inv_label = Label.new()
	inv_label.text = _fmt("背包 x{count}", {"count": inv_count})
	inv_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(inv_label)

	# 成熟天数
	var days_label = Label.new()
	days_label.text = _fmt("{day}天成熟", {"day": fish.get("maturity_days", 5)})
	days_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(days_label)

	# 产出率
	var rate_label = Label.new()
	rate_label.text = "★%.0f%%" % (fish.get("production_rate", 0) * 100)
	rate_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(rate_label)

	# 放入按钮
	var add_btn = Button.new()
	add_btn.text = _t("放入") if can_add else _t("已满")
	add_btn.custom_minimum_size = Vector2(60, 30)
	add_btn.disabled = not can_add
	add_btn.pressed.connect(_on_add_fish_row_pressed.bind(fish.get("fish_id", "")))
	_setup_hover_effect(add_btn)
	hbox.add_child(add_btn)

	return panel

func _on_close_pressed() -> void:
	hide_ui()

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
		print("[FishPondUI] " + text)

# ============ 输入处理 ============

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# ESC 关闭
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		return

	# G 键切换（如果需要全局快捷键）
	if event.is_action_pressed("ui_focus_next") and event.is_echo() == false:
		# 可选的全局切换功能
		pass
