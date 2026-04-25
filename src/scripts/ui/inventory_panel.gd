extends CanvasLayer

## InventoryPanel - Inventory Panel Main Script
## Implements Backpack/Equipment/Tools/Presets/Crafting tabs

# ============ Constants ============

enum Tab { BACKPACK, EQUIPMENT, TOOLS, PRESETS, CRAFTING }

const TAB_NAMES: Dictionary = {
	Tab.BACKPACK: "Backpack",
	Tab.EQUIPMENT: "Equipment",
	Tab.TOOLS: "Tools",
	Tab.PRESETS: "Presets",
	Tab.CRAFTING: "Crafting"
}

const TAB_SHORTCUTS: Dictionary = {
	KEY_1: Tab.BACKPACK,
	KEY_2: Tab.EQUIPMENT,
	KEY_3: Tab.TOOLS,
	KEY_4: Tab.PRESETS,
	KEY_5: Tab.CRAFTING
}

const SLOT_SIZE: int = 64
const SLOT_SPACING: int = 4
const COLUMNS: int = 10
const INITIAL_CAPACITY: int = 24
const TEMP_CAPACITY: int = 5

const COLORS: Dictionary = {
	"bg_panel": Color(0.02, 0.04, 0.08, 0.92),
	"bg_slot": Color(0.05, 0.08, 0.12, 0.88),
	"bg_hover": Color(0.1, 0.15, 0.2, 0.5),
	"accent_gold": Color(0.85, 0.7, 0.3, 1.0),
	"accent_green": Color(0.4, 0.65, 0.4, 0.9),
	"text_normal": Color(0.9, 0.85, 0.8, 1.0),
	"text_dim": Color(0.5, 0.5, 0.5, 0.7),
	"border_light": Color(0.4, 0.45, 0.5, 0.6)
}

# ============ Node References ============

var main_panel: PanelContainer
var title_bar: HBoxContainer
var close_button: Button
var tab_container: HBoxContainer
var tab_buttons: Array = []
var content_container: Control
var backpack_tab: Control
var equipment_tab: Control
var tools_tab: Control
var presets_tab: Control
var crafting_tab: Control
var backpack_scroll: ScrollContainer
var backpack_grid: GridContainer
var backpack_slots: Array = []
var capacity_bar: ProgressBar
var capacity_label: Label
var sort_button: Button
var expand_button: Button
var money_label: Label
var temp_backpack_container: HBoxContainer
var temp_slots: Array = []
var move_all_button: Button
var current_tab: Tab = Tab.BACKPACK
var is_visible: bool = false
var _initialized: bool = false
var selected_slot_index: int = -1  # 方向键导航选中索引

# ============ Initialization ============

func _ready() -> void:
	_setup_node_references()
	_setup_styles()
	_connect_signals()
	_create_backpack_grid()
	_create_temp_grid()
	_update_display()
	visible = false

## 初始化完成后的处理（延迟一帧确保节点引用就绪）
func _delayed_init() -> void:
	# 如果之前因为节点未就绪而失败，重新尝试
	if backpack_grid == null:
		_setup_node_references()
		_create_backpack_grid()
		_create_temp_grid()
	_update_display()

## 显示面板 (带动画)
func open_panel() -> void:
	# 如果背包网格还未初始化，先初始化
	if backpack_grid == null or backpack_slots.is_empty():
		_delayed_init()

	if is_visible:
		return
	is_visible = true
	show()
	scale = Vector2(0.95, 0.95)

	# 缩放动画
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished

	_update_display()
	_grab_focus()

## 隐藏面板 (带动画)
func close_panel() -> void:
	if not is_visible:
		return

	is_visible = false

	# 缩小动画
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished

	hide()
	scale = Vector2(1.0, 1.0)  # 重置缩放
	_release_focus()

func _grab_focus() -> void:
	# 启用面板的焦点模式
	if main_panel:
		main_panel.set_focus_mode(Control.FOCUS_ALL)

func _release_focus() -> void:
	if main_panel:
		main_panel.release_focus()

## 快捷键处理
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				close_panel()
			KEY_TAB:
				_switch_tab_next()
			KEY_1:
				_switch_tab(Tab.BACKPACK)
			KEY_2:
				_switch_tab(Tab.EQUIPMENT)
			KEY_3:
				_switch_tab(Tab.TOOLS)
			KEY_4:
				_switch_tab(Tab.PRESETS)
			KEY_5:
				_switch_tab(Tab.CRAFTING)
			KEY_Q:
				_on_sort_button_pressed()
			KEY_LEFT:
				_move_selection(-1, 0)
			KEY_RIGHT:
				_move_selection(1, 0)
			KEY_UP:
				_move_selection(0, -1)
			KEY_DOWN:
				_move_selection(0, 1)
			KEY_ENTER:
				_activate_selected_slot()

## 方向键导航
func _move_selection(delta_x: int, delta_y: int) -> void:
	if current_tab != Tab.BACKPACK:
		return

	var capacity = InventorySystem.backpack_size if InventorySystem else INITIAL_CAPACITY
	if capacity <= 0:
		return

	# 初始化选中
	if selected_slot_index < 0:
		selected_slot_index = 0
		_update_slot_selection()
		return

	# 计算新索引
	var col = selected_slot_index % COLUMNS
	var row = selected_slot_index / COLUMNS
	var new_col = col + delta_x
	var new_row = row + delta_y

	# 边界检查
	if new_col < 0:
		new_col = COLUMNS - 1
		new_row -= 1
	if new_col >= COLUMNS:
		new_col = 0
		new_row += 1
	if new_row < 0:
		new_row = (capacity + COLUMNS - 1) / COLUMNS - 1
	if new_row * COLUMNS + new_col >= capacity:
		new_row = 0

	selected_slot_index = new_row * COLUMNS + new_col
	_update_slot_selection()

## 更新选中状态
func _update_slot_selection() -> void:
	for i in range(backpack_slots.size()):
		var slot = backpack_slots[i]
		if slot and slot.has_node("QualityBorder"):
			var border = slot.get_node("QualityBorder") as ColorRect
			if border:
				if i == selected_slot_index:
					border.color = COLORS["accent_gold"]
					border.size = Vector2(3, 3)
				else:
					# 恢复原品质颜色
					var item_def = InventorySystem.backpack[i] if InventorySystem else null
					var quality = Quality.NORMAL
					if item_def:
						quality = item_def.quality
					border.color = Quality.get_color(quality)
					border.size = Vector2(2, 2)

## 激活选中槽位
func _activate_selected_slot() -> void:
	if selected_slot_index < 0 or selected_slot_index >= backpack_slots.size():
		return

	var slot = backpack_slots[selected_slot_index]
	if slot and not slot.is_empty():
		# 使用物品或显示详情
		if slot.item_def and slot.item_def.edible:
			InventorySystem.use_item(selected_slot_index)

# ============ 按钮处理函数 ============

## 关闭按钮
func _on_close_button_pressed() -> void:
	close_panel()

## 整理按钮
func _on_sort_button_pressed() -> void:
	if InventorySystem:
		InventorySystem.sort_items()
	_update_display()

## 扩容按钮
func _on_expand_button_pressed() -> void:
	if InventorySystem:
		var success = InventorySystem.expand_capacity()
		if not success:
			_show_notification("背包已达最大容量")
		else:
			_show_notification("背包扩容成功")
			# 重新创建网格以适应新容量
			_create_backpack_grid()
	_update_display()

# ============ 信号处理 ============

func _on_backpack_changed() -> void:
	_update_display()

func _on_backpack_expanded(new_size: int) -> void:
	_show_notification("背包已扩容至 %d 格" % new_size)
	_create_backpack_grid()
	_update_display()

func _on_money_changed(amount: int) -> void:
	_update_money()

## 临时背包全部移回
func _on_move_all_button_pressed() -> void:
	if InventorySystem:
		var count = InventorySystem.move_all_from_temp()
		if count > 0:
			_show_notification("已移回 %d 个物品" % count)
		else:
			_show_notification("临时背包为空")
	_update_display()

## 显示通知消息
func _show_notification(message: String) -> void:
	# 使用HUD的通知系统或自己的通知
	if has_node("/root/HUD"):
		var hud = get_node("/root/HUD")
		if hud.has_method("show_message"):
			hud.show_message(message)
	else:
		print("[InventoryPanel] ", message)

# ============ 物品格子交互 ============

var context_menu: PopupMenu
var selected_slot_index_for_menu: int = -1
var selected_slot_is_temp: bool = false
var locked_slots: Dictionary = {}  # 锁定状态存储 {slot_index: true}

func _on_slot_mouse_entered(slot_index: int, is_temp: bool) -> void:
	# 高亮显示悬停的格子
	var slot
	if is_temp:
		if slot_index < temp_slots.size():
			slot = temp_slots[slot_index]
	else:
		if slot_index < backpack_slots.size():
			slot = backpack_slots[slot_index]

	if slot:
		# 缩放动画
		var tween = create_tween()
		tween.tween_property(slot, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# 显示HoverOverlay
		if slot.has_node("HoverOverlay"):
			var hover = slot.get_node("HoverOverlay") as Panel
			if hover:
				hover.visible = true

func _on_slot_mouse_exited() -> void:
	# 取消所有格子的高亮
	for slot in backpack_slots:
		if slot:
			var tween = create_tween()
			tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			if slot.has_node("HoverOverlay"):
				var hover = slot.get_node("HoverOverlay") as Panel
				if hover:
					hover.visible = false

	for slot in temp_slots:
		if slot:
			var tween = create_tween()
			tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			if slot.has_node("HoverOverlay"):
				var hover = slot.get_node("HoverOverlay") as Panel
				if hover:
					hover.visible = false

func _on_slot_gui_input(event: InputEvent, slot_index: int, is_temp: bool) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_show_context_menu(slot_index, is_temp)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 左键点击选中槽位
			selected_slot_index = slot_index
			_update_slot_selection()

func _show_context_menu(slot_index: int, is_temp: bool) -> void:
	selected_slot_index_for_menu = slot_index
	selected_slot_is_temp = is_temp

	# 获取物品信息
	var item_id = ""
	var quantity = 0
	var is_empty = true

	if is_temp:
		if slot_index < temp_slots.size():
			var temp_slot = temp_slots[slot_index]
			item_id = temp_slot.item_id
			quantity = temp_slot.quantity
			is_empty = temp_slot.is_empty
	else:
		if slot_index < backpack_slots.size():
			var backpack_slot = backpack_slots[slot_index]
			item_id = backpack_slot.item_id
			quantity = backpack_slot.quantity
			is_empty = backpack_slot.is_empty

	if is_empty:
		return

	# 获取或创建ContextMenu
	if not has_node("ContextMenu"):
		context_menu = PopupMenu.new()
		context_menu.name = "ContextMenu"
		add_child(context_menu)
	else:
		context_menu = get_node("ContextMenu")

	# 清空并添加菜单项
	context_menu.clear()
	context_menu.add_item("使用", 1)
	context_menu.add_item("丢弃", 2)
	context_menu.add_separator()

	# 检查是否已锁定
	var lock_key = "%d_%s" % [slot_index, "temp" if is_temp else "backpack"]
	var is_locked = locked_slots.has(lock_key)
	if is_locked:
		context_menu.add_item("解锁", 3)
	else:
		context_menu.add_item("锁定", 3)
	context_menu.add_item(I18n.translate("ui.sell"), 4)

	# 显示菜单
	context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	context_menu.hide()
	context_menu.popup_centered()

func _on_context_menu_id_pressed(id: int) -> void:
	match id:
		1:  # 使用
			_use_item(selected_slot_index_for_menu, selected_slot_is_temp)
		2:  # 丢弃
			_discard_item(selected_slot_index_for_menu, selected_slot_is_temp)
		3:  # 锁定
			_toggle_lock_item(selected_slot_index_for_menu, selected_slot_is_temp)
		4:  # 出售
			_sell_item(selected_slot_index_for_menu, selected_slot_is_temp)

	_update_display()

func _use_item(slot_index: int, is_temp: bool) -> void:
	if InventorySystem:
		InventorySystem.use_item(slot_index)

func _discard_item(slot_index: int, is_temp: bool) -> void:
	# 检查是否已锁定
	var lock_key = "%d_%s" % [slot_index, "temp" if is_temp else "backpack"]
	if locked_slots.has(lock_key):
		_show_notification("已锁定的物品无法丢弃")
		return

	if is_temp:
		if slot_index >= 0 and slot_index < temp_slots.size():
			InventorySystem.discard_temp_item(slot_index)
	else:
		if slot_index >= 0 and slot_index < backpack_slots.size():
			InventorySystem.discard_slot(slot_index)

func _toggle_lock_item(slot_index: int, is_temp: bool) -> void:
	var lock_key = "%d_%s" % [slot_index, "temp" if is_temp else "backpack"]
	if locked_slots.has(lock_key):
		locked_slots.erase(lock_key)
		_show_notification("已解锁")
	else:
		locked_slots[lock_key] = true
		_show_notification("已锁定")
	_update_slot_lock_visual(slot_index, is_temp)

## 更新格子锁定视觉
func _update_slot_lock_visual(slot_index: int, is_temp: bool) -> void:
	var lock_key = "%d_%s" % [slot_index, "temp" if is_temp else "backpack"]
	var is_locked = locked_slots.has(lock_key)

	var slot
	if is_temp:
		if slot_index < temp_slots.size():
			slot = temp_slots[slot_index]
	else:
		if slot_index < backpack_slots.size():
			slot = backpack_slots[slot_index]

	if slot and slot.has_node("QualityBorder"):
		var border = slot.get_node("QualityBorder") as ColorRect
		if border:
			if is_locked:
				border.color = Color(0.85, 0.7, 0.3, 1.0)  # 金色表示锁定
				border.size = Vector2(3, 3)
			# else: restore quality color

func _sell_item(slot_index: int, is_temp: bool) -> void:
	if not is_temp and InventorySystem:
		var slot = backpack_slots[slot_index]
		if slot:
			InventorySystem.sell_item(slot.item_id, slot.quantity)

## 切换到下一个标签
func _switch_tab_next() -> void:
	var next_tab = (current_tab + 1) % (Tab.CRAFTING + 1)
	_switch_tab(next_tab)

## 切换到指定标签
func _switch_tab(tab_id: int) -> void:
	if tab_id < Tab.BACKPACK or tab_id > Tab.CRAFTING:
		return
	
	current_tab = tab_id
	_update_tab_visibility()
	
	# Update button states
	for i in range(tab_buttons.size()):
		if tab_buttons[i]:
			tab_buttons[i].set_pressed_no_signal(i == tab_id)



func _setup_node_references() -> void:
	main_panel = $MainPanel as PanelContainer
	title_bar = $MainPanel/VBox/TitleBar as HBoxContainer
	close_button = $MainPanel/VBox/TitleBar/CloseButton as Button
	tab_container = $MainPanel/VBox/TabContainer as HBoxContainer
	content_container = $MainPanel/VBox/ContentContainer as Control

	# Setup individual tab references
	equipment_tab = $MainPanel/VBox/ContentContainer/EquipmentTab as Control
	tools_tab = $MainPanel/VBox/ContentContainer/ToolsTab as Control
	presets_tab = $MainPanel/VBox/ContentContainer/PresetsTab as Control
	crafting_tab = $MainPanel/VBox/ContentContainer/CraftingTab as Control

	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	_setup_tab_buttons()
	backpack_tab = $MainPanel/VBox/ContentContainer/BackpackTab as Control
	backpack_scroll = backpack_tab.get_node_or_null("ScrollContainer") as ScrollContainer if backpack_tab else null
	backpack_grid = backpack_scroll.get_node_or_null("BackpackGrid") as GridContainer if backpack_scroll else null
	capacity_bar = backpack_tab.get_node_or_null("CapacityBar") as ProgressBar if backpack_tab else null
	capacity_label = backpack_tab.get_node_or_null("CapacityLabel") as Label if backpack_tab else null
	sort_button = backpack_tab.get_node_or_null("SortButton") as Button if backpack_tab else null
	expand_button = backpack_tab.get_node_or_null("ExpandButton") as Button if backpack_tab else null
	money_label = backpack_tab.get_node_or_null("MoneyLabel") as Label if backpack_tab else null
	if sort_button:
		sort_button.pressed.connect(_on_sort_button_pressed)
	if expand_button:
		expand_button.pressed.connect(_on_expand_button_pressed)
	temp_backpack_container = $MainPanel/VBox/TempBackpackContainer as HBoxContainer
	move_all_button = $MainPanel/VBox/TempBackpackContainer/MoveAllButton as Button if temp_backpack_container else null
	if move_all_button:
		move_all_button.pressed.connect(_on_move_all_button_pressed)
	_initialized = true

func _setup_tab_buttons() -> void:
	tab_buttons.clear()
	for tab_id in TAB_NAMES.keys():
		var btn = tab_container.get_node_or_null("TabButton_%d" % tab_id) if tab_container else null
		if btn:
			tab_buttons.append(btn)
			btn.pressed.connect(_on_tab_button_pressed.bind(tab_id))

## Tab按钮点击处理
func _on_tab_button_pressed(tab_id: int) -> void:
	if tab_id >= 0 and tab_id < Tab.size():
		current_tab = tab_id
		_update_tab_visibility()
		# 创建对应Tab内容
		match current_tab:
			Tab.EQUIPMENT:
				_create_equipment_tab_content()
			Tab.TOOLS:
				_create_tools_tab_content()
			Tab.PRESETS:
				_create_presets_tab_content()
			Tab.CRAFTING:
				_create_crafting_tab_content()

func _setup_styles() -> void:
	if main_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = COLORS["bg_panel"]
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.border_color = COLORS["border_light"]
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		main_panel.add_theme_stylebox_override("panel", style)

func _connect_signals() -> void:
	if InventorySystem:
		InventorySystem.backpack_changed.connect(_on_backpack_changed)
		InventorySystem.backpack_expanded.connect(_on_backpack_expanded)
	if PlayerStats:
		PlayerStats.money_changed.connect(_on_money_changed)

func _create_backpack_grid() -> void:
	if not backpack_grid:
		push_error("[InventoryPanel] backpack_grid is null!")
		return
	backpack_grid.columns = COLUMNS
	backpack_slots.clear()
	var capacity = InventorySystem.backpack_size if InventorySystem else INITIAL_CAPACITY
	for i in range(capacity):
		var slot = _create_slot_node(i, false)
		backpack_grid.add_child(slot)
		backpack_slots.append(slot)
	# 布局结束后强制修正每个格子尺寸为 SLOT_SIZE，防止被 GridContainer 均分撑大
	call_deferred("_force_slot_sizes_deferred", backpack_slots)

func _force_slot_sizes_deferred(slots: Array) -> void:
	"""布局结束后强制修正格子及图标尺寸，防止被 GridContainer 均分撑大"""
	for slot in slots:
		if slot:
			slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
			slot.size = Vector2(SLOT_SIZE, SLOT_SIZE)
			var icon = slot.get_node_or_null("IconContainer/Icon") as Control
			if icon:
				icon.custom_minimum_size = Vector2(SLOT_SIZE - 2, SLOT_SIZE - 2)
				icon.size = Vector2(SLOT_SIZE - 2, SLOT_SIZE - 2)

func _create_temp_grid() -> void:
	if not temp_backpack_container:
		push_error("[InventoryPanel] temp_backpack_container is null!")
		return
	temp_slots.clear()
	for i in range(TEMP_CAPACITY):
		var slot = _create_slot_node(i, true)
		temp_backpack_container.add_child(slot)
		temp_slots.append(slot)

func _create_slot_node(index: int, is_temp: bool) -> PanelContainer:
	var slot = PanelContainer.new()
	slot.name = "Slot_%d" % index
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	var style = StyleBoxFlat.new()
	style.bg_color = COLORS["bg_slot"]
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_color = COLORS["border_light"]
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	slot.add_theme_stylebox_override("normal", style)
	# QualityBorder 先添加（在底层，不挡图标）
	var quality_border = ColorRect.new()
	quality_border.name = "QualityBorder"
	quality_border.color = COLORS["border_light"]
	quality_border.anchors_preset = Control.PRESET_FULL_RECT
	quality_border.set_offsets_preset(Control.PRESET_FULL_RECT)
	quality_border.offset_left = 3
	quality_border.offset_top = 3
	quality_border.offset_right = -3
	quality_border.offset_bottom = -3
	slot.add_child(quality_border)
	var icon_container = CenterContainer.new()
	icon_container.name = "IconContainer"
	icon_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	slot.add_child(icon_container)
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.visible = false
	# 固定 Icon 节点尺寸，IGNORE_SIZE + STRETCH_SCALE 让 128px 图标缩放填满此区域
	icon.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon_container.add_child(icon)
	var quantity = Label.new()
	quantity.name = "QuantityLabel"
	quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	quantity.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	quantity.visible = false
	slot.add_child(quantity)
	var hover = Panel.new()
	hover.name = "HoverOverlay"
	hover.visible = false
	slot.add_child(hover)
	slot.mouse_entered.connect(_on_slot_mouse_entered.bind(index, is_temp))
	slot.mouse_exited.connect(_on_slot_mouse_exited)
	slot.gui_input.connect(_on_slot_gui_input.bind(index, is_temp))
	return slot

func _update_display() -> void:
	if not _initialized:
		return
	_update_backpack_display()
	_update_temp_display()
	_update_capacity()
	_update_money()
	_update_tab_visibility()

func _update_backpack_display() -> void:
	if not InventorySystem:
		return
	if backpack_slots.is_empty():
		return
	var backpack = InventorySystem.backpack
	for i in range(backpack_slots.size()):
		var slot = backpack_slots[i]
		if i < backpack.size():
			var item_slot = backpack[i]
			_update_slot_display(slot, item_slot.item_id, item_slot.quantity, item_slot.quality)
		else:
			_update_slot_display(slot, "", 0, Quality.NORMAL)

func _update_temp_display() -> void:
	if not InventorySystem or temp_slots.is_empty():
		return
	var temp = InventorySystem.temp_backpack
	for i in range(temp_slots.size()):
		var slot = temp_slots[i]
		if i < temp.size():
			var item_slot = temp[i]
			_update_slot_display(slot, item_slot.item_id, item_slot.quantity, item_slot.quality)
		else:
			_update_slot_display(slot, "", 0, Quality.NORMAL)

func _update_slot_display(slot: PanelContainer, item_id: String, quantity: int, quality: int) -> void:
	var icon = slot.get_node_or_null("IconContainer/Icon") as TextureRect
	var quantity_label = slot.get_node_or_null("QuantityLabel") as Label
	var quality_border = slot.get_node_or_null("QualityBorder") as ColorRect
	if icon:
		if item_id.is_empty():
			icon.texture = null
			icon.visible = false
		else:
			var item_def = ItemDataSystem.get_item_def(item_id) if ItemDataSystem else null
			var icon_path = ""
			if item_def and not item_def.icon_path.is_empty() and ResourceLoader.exists(item_def.icon_path):
				icon_path = item_def.icon_path
			else:
				# 使用统一的占位图标
				icon_path = "res://icon.svg"
			if ResourceLoader.exists(icon_path):
				icon.texture = load(icon_path)
				icon.visible = true
			else:
				icon.texture = null
				icon.visible = false
	if quantity_label:
		if item_id.is_empty() or quantity <= 1:
			quantity_label.visible = false
		else:
			quantity_label.text = str(quantity)
			quantity_label.visible = true
	if quality_border:
		quality_border.color = Quality.get_color(quality)

## 更新槽位后备显示（当没有图标时显示物品标识）
func _update_slot_backup_display(slot: PanelContainer, item_id: String, icon_container: CenterContainer) -> void:
	# 查找或创建后备显示节点
	var backup_label = slot.get_node_or_null("BackupLabel") as Label
	if backup_label == null:
		backup_label = Label.new()
		backup_label.name = "BackupLabel"
		backup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		backup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		backup_label.scale = Vector2(1.5, 1.5)
		# 插入到 IconContainer 之后
		if icon_container and icon_container.get_parent() == slot:
			var idx = icon_container.get_index()
			slot.add_child(backup_label)
			backup_label.z_index = 1
		else:
			slot.add_child(backup_label)

	# 根据物品ID显示对应的emoji
	backup_label.text = _get_item_emoji(item_id)
	backup_label.visible = true

## 获取物品的emoji表示
func _get_item_emoji(item_id: String) -> String:
	# 种子类
	if item_id.contains("seed"):
		return "🫘"
	# 肥料类
	if item_id.contains("fertilizer"):
		return "🌿"
	# 木材
	if item_id == "wood":
		return "🪵"
	# 石材
	if item_id == "stone":
		return "🪨"
	# 矿石
	if item_id.contains("ore"):
		return "💎"
	# 煤炭
	if item_id == "coal":
		return "ite"
	# 鱼饵
	if item_id.contains("bait"):
		return "🪱"
	# 农产品
	if item_id == "tomato":
		return "🍅"
	if item_id == "potato":
		return "🥔"
	if item_id == "carrot":
		return "🥕"
	if item_id == "wheat":
		return "🌾"
	if item_id == "rice":
		return "🍚"
	if item_id == "egg":
		return "🥚"
	if item_id == "milk":
		return "🥛"
	if item_id == "duck_egg":
		return "🥚"
	if item_id == "goat_milk":
		return "🥛"
	if item_id == "wool":
		return "🧶"
	if item_id == "truffle":
		return "🍄"
	if item_id == "hay":
		return "🌾"
	# 竹子
	if item_id == "bamboo":
		return "🎋"

	# 默认返回物品ID的第一个字符
	return item_id.substr(0, 1).to_upper()

func _update_capacity() -> void:
	if not InventorySystem:
		return
	var used = InventorySystem.get_used_slots()
	var total = InventorySystem.backpack_size
	var percent = 0.0 if total == 0 else float(used) / float(total) * 100.0
	if capacity_bar:
		capacity_bar.value = percent
		var bar_color: Color
		if percent >= 90:
			bar_color = Color(0.91, 0.30, 0.24, 1.0)
		elif percent >= 70:
			bar_color = Color(0.95, 0.61, 0.07, 1.0)
		else:
			bar_color = COLORS["accent_green"]
		capacity_bar.add_theme_color_override("fill", bar_color)
	if capacity_label:
		capacity_label.text = "%d/%d" % [used, total]

func _update_money() -> void:
	if not money_label:
		return
	if PlayerStats:
		money_label.text = "$ %d" % PlayerStats.money
	else:
		money_label.text = "$ 0"

func _update_tab_visibility() -> void:
	# Update all tab visibilities
	if backpack_tab:
		backpack_tab.visible = current_tab == Tab.BACKPACK
	if equipment_tab:
		equipment_tab.visible = current_tab == Tab.EQUIPMENT
		if current_tab == Tab.EQUIPMENT and equipment_tab.get_child_count() <= 1:
			_create_equipment_tab_content()
	if tools_tab:
		tools_tab.visible = current_tab == Tab.TOOLS
		if current_tab == Tab.TOOLS and tools_tab.get_child_count() <= 1:
			_create_tools_tab_content()
	if presets_tab:
		presets_tab.visible = current_tab == Tab.PRESETS
		if current_tab == Tab.PRESETS and presets_tab.get_child_count() <= 1:
			_create_presets_tab_content()
	if crafting_tab:
		crafting_tab.visible = current_tab == Tab.CRAFTING
		if current_tab == Tab.CRAFTING and crafting_tab.get_child_count() <= 1:
			_create_crafting_tab_content()
	_update_tab_button_states()

func _update_tab_button_states() -> void:
	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i]
		if btn and btn.has_method("set_pressed_no_signal"):
			btn.set_pressed_no_signal(i == current_tab)

# ============ Tab Content Creation ============

func _create_equipment_tab_content() -> void:
	if not equipment_tab:
		return
	equipment_tab.add_theme_color_override("bg_color", COLORS["bg_panel"])

	# 清除占位符
	for child in equipment_tab.get_children():
		child.queue_free()

	# 创建布局: 左侧装备预览 + 右侧列表
	var main_hbox = HBoxContainer.new()
	main_hbox.name = "MainHBox"
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	equipment_tab.add_child(main_hbox)

	# 左侧: 装备预览
	var left_vbox = VBoxContainer.new()
	left_vbox.name = "LeftPanel"
	left_vbox.custom_minimum_size = Vector2(180, 0)
	main_hbox.add_child(left_vbox)

	# 装备预览标题
	var preview_title = Label.new()
	preview_title.text = "当前装备"
	preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_vbox.add_child(preview_title)

	# 装备槽网格
	var slots_grid = GridContainer.new()
	slots_grid.name = "SlotsGrid"
	slots_grid.columns = 2
	slots_grid.custom_minimum_size = Vector2(160, 200)
	left_vbox.add_child(slots_grid)

	# 武器槽
	var weapon_slot = _create_equipment_slot("weapon", "武器", 64)
	slots_grid.add_child(weapon_slot)
	# 戒指槽1
	var ring1_slot = _create_equipment_slot("ring1", "戒指1", 40)
	slots_grid.add_child(ring1_slot)
	# 戒指槽2
	var ring2_slot = _create_equipment_slot("ring2", "戒指2", 40)
	slots_grid.add_child(ring2_slot)
	# 帽子槽
	var hat_slot = _create_equipment_slot("hat", "帽子", 48)
	slots_grid.add_child(hat_slot)
	# 鞋子槽
	var shoe_slot = _create_equipment_slot("shoe", "鞋子", 48)
	slots_grid.add_child(shoe_slot)

	# 套装进度
	var set_progress = Label.new()
	set_progress.name = "SetProgress"
	set_progress.text = "套装: 无"
	set_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_vbox.add_child(set_progress)

	# 右侧: 物品列表
	var right_scroll = ScrollContainer.new()
	right_scroll.name = "RightScroll"
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_scroll)

	var right_vbox = VBoxContainer.new()
	right_vbox.name = "RightVBox"
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right_vbox)

	# 武器列表
	var weapon_section = _create_item_section("武器列表", "weapon")
	right_vbox.add_child(weapon_section)

	# 戒指列表
	var ring_section = _create_item_section("戒指列表", "ring")
	right_vbox.add_child(ring_section)

	# 帽子列表
	var hat_section = _create_item_section("帽子列表", "hat")
	right_vbox.add_child(hat_section)

	# 鞋子列表
	var shoe_section = _create_item_section("鞋子列表", "shoe")
	right_vbox.add_child(shoe_section)

func _create_equipment_slot(slot_type: String, slot_name: String, slot_size: int) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.name = "Slot_%s" % slot_type

	var label = Label.new()
	label.text = slot_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(label)

	var slot_bg = PanelContainer.new()
	slot_bg.custom_minimum_size = Vector2(slot_size, slot_size)
	var style = StyleBoxFlat.new()
	style.bg_color = COLORS["bg_slot"]
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_color = COLORS["border_light"]
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	slot_bg.add_theme_stylebox_override("normal", style)
	container.add_child(slot_bg)

	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot_bg.add_child(icon)

	return container

func _create_item_section(title: String, category: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.name = "Section_%s" % category

	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", COLORS["accent_gold"])
	section.add_child(title_label)

	var scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.custom_minimum_size = Vector2(0, 60)
	section.add_child(scroll)

	var hbox = HBoxContainer.new()
	hbox.name = "ItemsHBox"
	scroll.add_child(hbox)

	# Mock: 添加3个占位物品
	for i in range(3):
		var item_slot = PanelContainer.new()
		item_slot.custom_minimum_size = Vector2(48, 48)
		var style = StyleBoxFlat.new()
		style.bg_color = COLORS["bg_slot"]
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		item_slot.add_theme_stylebox_override("normal", style)
		hbox.add_child(item_slot)

		var icon = Label.new()
		icon.name = "Icon"
		icon.text = "📦"
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_slot.add_child(icon)

	return section

func _create_tools_tab_content() -> void:
	if not tools_tab:
		return

	for child in tools_tab.get_children():
		child.queue_free()

	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tools_tab.add_child(main_vbox)

	# 升级进度条
	var upgrade_progress = PanelContainer.new()
	upgrade_progress.name = "UpgradeProgress"
	upgrade_progress.custom_minimum_size = Vector2(0, 40)
	main_vbox.add_child(upgrade_progress)

	var progress_vbox = VBoxContainer.new()
	upgrade_progress.add_child(progress_vbox)

	var progress_title = Label.new()
	progress_title.text = "升级进度"
	progress_title.add_theme_color_override("font_color", COLORS["accent_gold"])
	progress_vbox.add_child(progress_title)

	var progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(0, 20)
	progress_bar.value = 50
	progress_vbox.add_child(progress_bar)

	# 7工具网格
	var tools_title = Label.new()
	tools_title.text = "工具"
	tools_title.add_theme_color_override("font_color", COLORS["accent_gold"])
	main_vbox.add_child(tools_title)

	var tools_scroll = ScrollContainer.new()
	tools_scroll.name = "ToolsScroll"
	tools_scroll.custom_minimum_size = Vector2(0, 200)
	main_vbox.add_child(tools_scroll)

	var tools_grid = GridContainer.new()
	tools_grid.name = "ToolsGrid"
	tools_grid.columns = 4
	tools_scroll.add_child(tools_grid)

	# Mock: 7个工具
	var tool_names = ["浇水壶", "锄头", "镐子", "鱼竿", "镰刀", "斧头", "平底锅"]
	var tool_icons = ["💧", "🔨", "⛏️", "🎣", "🔪", "🪓", "🍳"]
	var tool_tiers = ["basic", "iron", "steel", "iridium"]

	for i in range(7):
		var tool_container = _create_tool_card(tool_names[i], tool_icons[i], tool_tiers[i % 4])
		tools_grid.add_child(tool_container)

	# 工具详情
	var detail_panel = PanelContainer.new()
	detail_panel.name = "DetailPanel"
	detail_panel.custom_minimum_size = Vector2(0, 80)
	main_vbox.add_child(detail_panel)

	var detail_vbox = VBoxContainer.new()
	detail_panel.add_child(detail_vbox)

	var detail_label = Label.new()
	detail_label.text = I18n.translate("inventory.select_tool_detail")
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_vbox.add_child(detail_label)

	var upgrade_btn = Button.new()
	upgrade_btn.text = "升级 (需要材料)"
	upgrade_btn.disabled = true
	detail_vbox.add_child(upgrade_btn)

func _create_tool_card(name: String, icon: String, tier: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.name = "Tool_%s" % name

	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.custom_minimum_size = Vector2(60, 60)
	container.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(name_label)

	var tier_label = Label.new()
	tier_label.text = tier.to_upper()
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.4, 1.0))
	container.add_child(tier_label)

	return container

func _create_presets_tab_content() -> void:
	if not presets_tab:
		return

	for child in presets_tab.get_children():
		child.queue_free()

	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	presets_tab.add_child(main_vbox)

	# 预设标题
	var title = Label.new()
	title.text = "装备方案 (最多5个)"
	title.add_theme_color_override("font_color", COLORS["accent_gold"])
	main_vbox.add_child(title)

	# 预设卡片滚动
	var scroll = ScrollContainer.new()
	scroll.name = "PresetsScroll"
	scroll.custom_minimum_size = Vector2(0, 120)
	main_vbox.add_child(scroll)

	var cards_hbox = HBoxContainer.new()
	cards_hbox.name = "CardsHBox"
	scroll.add_child(cards_hbox)

	# Mock: 5个预设
	var preset_names = ["战斗装", "矿工装", "钓鱼装", "农夫装", "默认"]
	for i in range(5):
		var card = _create_preset_card(i, preset_names[i])
		cards_hbox.add_child(card)

	# 选中预设预览
	var preview_panel = PanelContainer.new()
	preview_panel.name = "PreviewPanel"
	preview_panel.custom_minimum_size = Vector2(0, 150)
	main_vbox.add_child(preview_panel)

	var preview_vbox = VBoxContainer.new()
	preview_panel.add_child(preview_vbox)

	var preview_title = Label.new()
	preview_title.text = "方案详情"
	preview_title.add_theme_color_override("font_color", COLORS["accent_gold"])
	preview_vbox.add_child(preview_title)

	var preview_content = Label.new()
	preview_content.text = "选择一个方案查看详情"
	preview_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_content.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_content.custom_minimum_size = Vector2(0, 100)
	preview_vbox.add_child(preview_content)

	# 操作按钮
	var btn_hbox = HBoxContainer.new()
	btn_hbox.name = "ButtonsHBox"
	main_vbox.add_child(btn_hbox)

	var apply_btn = Button.new()
	apply_btn.text = "应用"
	apply_btn.disabled = true
	btn_hbox.add_child(apply_btn)

	var edit_btn = Button.new()
	edit_btn.text = "编辑"
	btn_hbox.add_child(edit_btn)

	var delete_btn = Button.new()
	delete_btn.text = "删除"
	delete_btn.disabled = true
	btn_hbox.add_child(delete_btn)

	var new_btn = Button.new()
	new_btn.text = "新建方案"
	new_btn.disabled = true
	btn_hbox.add_child(new_btn)

func _create_preset_card(index: int, name: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.name = "Preset_%d" % index
	container.custom_minimum_size = Vector2(100, 100)

	var bg = PanelContainer.new()
	bg.name = "BG"
	var style = StyleBoxFlat.new()
	style.bg_color = COLORS["bg_slot"]
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	bg.add_theme_stylebox_override("normal", style)
	container.add_child(bg)

	var inner_vbox = VBoxContainer.new()
	bg.add_child(inner_vbox)

	var num_label = Label.new()
	num_label.text = "#%d" % (index + 1)
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(num_label)

	var name_label = Label.new()
	name_label.text = name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(name_label)

	var icon_label = Label.new()
	icon_label.text = "📋"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.custom_minimum_size = Vector2(40, 40)
	inner_vbox.add_child(icon_label)

	return container

func _create_crafting_tab_content() -> void:
	if not crafting_tab:
		return

	for child in crafting_tab.get_children():
		child.queue_free()

	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	crafting_tab.add_child(main_vbox)

	# 标题
	var title = Label.new()
	title.text = "装备合成"
	title.add_theme_color_override("font_color", COLORS["accent_gold"])
	main_vbox.add_child(title)

	# 类别按钮
	var category_hbox = HBoxContainer.new()
	category_hbox.name = "CategoryButtons"
	main_vbox.add_child(category_hbox)

	var categories = ["戒指", "帽子", "鞋子"]
	for i in range(3):
		var btn = Button.new()
		btn.text = categories[i]
		btn.toggle_mode = true
		if i == 0:
			btn.button_pressed = true
		btn.custom_minimum_size = Vector2(100, 40)
		category_hbox.add_child(btn)

	# 开发中提示
	var dev_panel = PanelContainer.new()
	dev_panel.name = "DevPanel"
	dev_panel.custom_minimum_size = Vector2(0, 200)
	main_vbox.add_child(dev_panel)

	var dev_style = StyleBoxFlat.new()
	dev_style.bg_color = Color(0.1, 0.08, 0.05, 0.9)
	dev_style.corner_radius_top_left = 8
	dev_style.corner_radius_top_right = 8
	dev_style.corner_radius_bottom_left = 8
	dev_style.corner_radius_bottom_right = 8
	dev_panel.add_theme_stylebox_override("normal", dev_style)

	var dev_vbox = VBoxContainer.new()
	dev_panel.add_child(dev_vbox)

	var dev_icon = Label.new()
	dev_icon.text = "🔧"
	dev_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dev_icon.custom_minimum_size = Vector2(0, 60)
	dev_vbox.add_child(dev_icon)

	var dev_label = Label.new()
	dev_label.text = "合成系统开发中"
	dev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dev_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5, 1.0))
	dev_vbox.add_child(dev_label)

	var dev_sublabel = Label.new()
	dev_sublabel.text = "戒指、帽子、鞋子合成功能\n将在 C05 ProcessingSystem 实现后开放"
	dev_sublabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dev_sublabel.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.8))
	dev_vbox.add_child(dev_sublabel)

	# 配方列表（将来用）
	var recipe_scroll = ScrollContainer.new()
	recipe_scroll.name = "RecipeScroll"
	recipe_scroll.custom_minimum_size = Vector2(0, 150)
	main_vbox.add_child(recipe_scroll)

	var recipe_vbox = VBoxContainer.new()
	recipe_vbox.name = "RecipeVBox"
	recipe_scroll.add_child(recipe_vbox)

	var recipe_label = Label.new()
	recipe_label.text = "配方列表 (待实现)"
	recipe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recipe_vbox.add_child(recipe_label)
