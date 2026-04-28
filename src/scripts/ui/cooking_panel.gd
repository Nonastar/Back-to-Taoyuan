extends Panel

# UITokens-based theming for consistent visuals

## CookingPanel - 烹饪UI面板
## 负责显示菜谱、开始烹饪、查看Buff

# ============ 属性 ============

var selected_recipe_id: String = ""

# Keyboard navigation for recipe list
var recipe_select_buttons: Array = []
var current_recipe_index: int = -1

# ============ UI节点 (延迟初始化) ============

var recipe_container: VBoxContainer
var selected_recipe_label: Label
var ingredients_list: VBoxContainer
var cook_button: Button
var buff_list: VBoxContainer
var status_label: Label
var close_button: Button

# ============ 生命周期 ============

func _ready() -> void:
	_init_node_references()
	_connect_signals()
	_populate_recipes()
	_update_buff_display()
	_setup_dynamic_styles()
	_focus_first_recipe_if_any()

func _init_node_references() -> void:
	recipe_container = get_node_or_null("MainLayout/ContentArea/RecipeList/RecipeScroll/RecipeContainer")
	selected_recipe_label = get_node_or_null("MainLayout/ContentArea/DetailPanel/SelectedRecipe")
	ingredients_list = get_node_or_null("MainLayout/ContentArea/DetailPanel/IngredientsList")
	cook_button = get_node_or_null("MainLayout/ContentArea/DetailPanel/CookButton")
	buff_list = get_node_or_null("MainLayout/ContentArea/DetailPanel/BuffList")
	status_label = get_node_or_null("MainLayout/StatusBar")
	close_button = get_node_or_null("MainLayout/Header/CloseButton")
	
	# 调试输出
	if not recipe_container:
		print("[CookingPanel] recipe_container is null!")

func _connect_signals() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if cook_button:
		cook_button.pressed.connect(_on_cook_pressed)
	if CookingSystem and CookingSystem.has_signal("cooking_finished"):
		CookingSystem.cooking_finished.connect(_on_cooking_finished)

	# Keyboard handling: ESC to close is implemented in _unhandled_input

func _setup_dynamic_styles() -> void:
	if not has_method("add_theme_stylebox_override"):
		return
	if cook_button:
		cook_button.add_theme_stylebox_override("normal", _make_button_style(UITokens.BUTTON_NORMAL))
		cook_button.add_theme_stylebox_override("hover", _make_button_style(UITokens.BUTTON_HOVER))
		cook_button.add_theme_stylebox_override("pressed", _make_button_style(UITokens.BUTTON_PRESSED))

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

func _focus_first_recipe_if_any() -> void:
	recipe_select_buttons.clear()
	for child in recipe_container.get_children():
		var btn = child.get_node_or_null("HBoxContainer/Button")
		if btn:
			recipe_select_buttons.append(btn)
	if recipe_select_buttons.size() > 0:
		current_recipe_index = 0
		recipe_select_buttons[0].grab_focus()

func _focus_next_recipe() -> void:
	if recipe_select_buttons.size() == 0:
		return
	current_recipe_index = (current_recipe_index + 1) % recipe_select_buttons.size()
	recipe_select_buttons[current_recipe_index].grab_focus()

func _focus_previous_recipe() -> void:
	if recipe_select_buttons.size() == 0:
		return
	current_recipe_index = (current_recipe_index - 1) % recipe_select_buttons.size()
	recipe_select_buttons[current_recipe_index].grab_focus()

func _unhandled_input(event) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("ui_cancel"):
			close_panel()
			return
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
			_focus_previous_recipe()
			return
		if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
			_focus_next_recipe()
			return
		if event.is_action_pressed("ui_accept"):
			if current_recipe_index >= 0 and current_recipe_index < recipe_select_buttons.size():
				recipe_select_buttons[current_recipe_index].emit_signal("pressed")
			return

# ============ 公开方法 ============

func open_panel() -> void:
	visible = true
	_populate_recipes()
	_update_buff_display()
	_clear_selection()
	# 显示当前烹饪状态
	_update_cooking_status_display()
	# Reset recipe focus state when opening panel
	recipe_select_buttons.clear()
	current_recipe_index = -1
	_focus_first_recipe_if_any()

func close_panel() -> void:
	visible = false
	_clear_selection()

func _update_cooking_status_display() -> void:
	if not CookingSystem:
		return
	var current_id = CookingSystem.get_current_recipe_id()
	if current_id.is_empty():
		return
	var remaining = CookingSystem.get_remaining_cooking_days()
	var recipe = CookingSystem.recipes.get(current_id, {})
	var name = recipe.get("name", current_id)
	_set_status(I18n.trf("cooking.cooking_status", [name, remaining]))

# ============ 内部方法 ============

func _populate_recipes() -> void:
	recipe_select_buttons.clear()
	_clear_selection()
	# 清除现有项
	for child in recipe_container.get_children():
		child.queue_free()
	
	# 获取菜谱
	if not CookingSystem or CookingSystem.recipes.is_empty():
		var empty_label = Label.new()
		empty_label.text = I18n.translate("cooking.no_recipes")
		recipe_container.add_child(empty_label)
		return
	
	# 添加菜谱项
	for recipe_id in CookingSystem.recipes.keys():
		var recipe = CookingSystem.recipes[recipe_id]
		var row = _create_recipe_row(recipe)
		recipe_container.add_child(row)

class _RecipeRow extends PanelContainer:
	var _recipe: Dictionary
	var _owner: Node

	func _init(recipe: Dictionary, owner: Node):
		_recipe = recipe
		_owner = owner
		_setup_ui()

	func _setup_ui() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_meta("recipe_id", _recipe.get("id", ""))

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
		base_style.content_margin_left = 6
		base_style.content_margin_right = 6
		base_style.content_margin_top = 4
		base_style.content_margin_bottom = 4
		add_theme_stylebox_override("panel", base_style)

		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size.y = 32
		add_child(hbox)

		# 菜谱名称
		var name_label = Label.new()
		name_label.text = _recipe.get("name", "?")
		name_label.custom_minimum_size.x = 120
		hbox.add_child(name_label)

		# 食材数量
		var ingredients = _recipe.get("ingredients", {})
		var ing_text = ""
		for ing_id in ingredients.keys():
			ing_text += "%sx%d " % [ing_id, ingredients[ing_id]]
		var ing_label = Label.new()
		ing_label.text = ing_text
		ing_label.custom_minimum_size.x = 100
		ing_label.add_theme_font_size_override("font_size", 10)
		hbox.add_child(ing_label)

		# 选择按钮
		var select_btn = Button.new()
		select_btn.text = I18n.translate("cooking.select")
		select_btn.pressed.connect(_on_select_pressed)
		hbox.add_child(select_btn)

	func _on_select_pressed() -> void:
		_owner._on_select_recipe(_recipe)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_owner._on_select_recipe(_recipe)


func _create_recipe_row(recipe: Dictionary) -> PanelContainer:
	var row = _RecipeRow.new(recipe, self)
	return row

## 烹饪Panel - 菜谱选中高亮
var _selected_recipe_row: Control = null

# 缓存的菜谱行样式（避免每次高亮都重新创建 StyleBoxFlat）
var _recipe_base_style: StyleBoxFlat = null
var _recipe_highlight_style: StyleBoxFlat = null

func _ensure_recipe_styles() -> void:
	if _recipe_base_style == null:
		_recipe_base_style = StyleBoxFlat.new()
		_recipe_base_style.bg_color = Color(0.18, 0.18, 0.22, 0.8)
		_recipe_base_style.border_color = Color(0.3, 0.3, 0.35, 1.0)
		_recipe_base_style.border_width_left = 1
		_recipe_base_style.border_width_top = 1
		_recipe_base_style.border_width_right = 1
		_recipe_base_style.border_width_bottom = 1
		_recipe_base_style.corner_radius_top_left = 4
		_recipe_base_style.corner_radius_top_right = 4
		_recipe_base_style.corner_radius_bottom_right = 4
		_recipe_base_style.corner_radius_bottom_left = 4
		_recipe_base_style.content_margin_left = 6
		_recipe_base_style.content_margin_right = 6
		_recipe_base_style.content_margin_top = 4
		_recipe_base_style.content_margin_bottom = 4
	if _recipe_highlight_style == null:
		_recipe_highlight_style = StyleBoxFlat.new()
		_recipe_highlight_style.bg_color = Color(0.3, 0.25, 0.0, 0.35)
		_recipe_highlight_style.border_color = Color(1.0, 0.84, 0.0, 1.0)
		_recipe_highlight_style.border_width_left = 2
		_recipe_highlight_style.border_width_top = 2
		_recipe_highlight_style.border_width_right = 2
		_recipe_highlight_style.border_width_bottom = 2
		_recipe_highlight_style.corner_radius_top_left = 4
		_recipe_highlight_style.corner_radius_top_right = 4
		_recipe_highlight_style.corner_radius_bottom_right = 4
		_recipe_highlight_style.corner_radius_bottom_left = 4
		_recipe_highlight_style.content_margin_left = 6
		_recipe_highlight_style.content_margin_right = 6
		_recipe_highlight_style.content_margin_top = 4
		_recipe_highlight_style.content_margin_bottom = 4

func _highlight_recipe_row(row: Control, selected: bool) -> void:
	if not row:
		return
	_ensure_recipe_styles()
	if selected:
		row.add_theme_stylebox_override("panel", _recipe_highlight_style)
	else:
		row.add_theme_stylebox_override("panel", _recipe_base_style)

func _on_select_recipe(recipe: Dictionary) -> void:
	selected_recipe_id = recipe.get("id", "")

	# 清除上一个高亮
	if _selected_recipe_row != null:
		_highlight_recipe_row(_selected_recipe_row, false)

	# 找到当前选中的行并高亮
	_selected_recipe_row = null
	if recipe_container:
		for child in recipe_container.get_children():
			if child.has_meta("recipe_id") and child.get_meta("recipe_id") == selected_recipe_id:
				_selected_recipe_row = child
				_highlight_recipe_row(_selected_recipe_row, true)
				break

	_update_recipe_detail(recipe)

func _update_recipe_detail(recipe: Dictionary) -> void:
	# 显示菜谱名称
	if selected_recipe_label:
		selected_recipe_label.text = "🍳 %s" % recipe.get("name", I18n.translate("ui.unknown"))
	
	# 显示食材需求
	_update_ingredients_display(recipe)

	# 更新按钮状态
	if cook_button:
		cook_button.disabled = selected_recipe_id.is_empty()
		cook_button.text = I18n.translate("cooking.start")

func _update_ingredients_display(recipe: Dictionary) -> void:
	# 清除现有食材显示
	for child in ingredients_list.get_children():
		child.queue_free()
	
	var ingredients = recipe.get("ingredients", {})
	if ingredients.is_empty():
		var empty_label = Label.new()
		empty_label.text = I18n.translate("cooking.no_ingredients")
		ingredients_list.add_child(empty_label)
		return
	
	# 检查并显示每个食材
	for ing_id in ingredients.keys():
		var required_amount = ingredients[ing_id]
		var have_amount = 0
		
		# 检查背包
		if InventorySystem and InventorySystem.has_method("get_item_count"):
			have_amount = InventorySystem.get_item_count(ing_id)
		
		var row = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = ing_id
		name_label.custom_minimum_size.x = 80
		row.add_child(name_label)
		
		var count_label = Label.new()
		var enough = have_amount >= required_amount
		count_label.text = "%d / %d" % [have_amount, required_amount]
		if not enough:
			count_label.add_theme_color_override("font_color", UITokens.ACCENT_RED)
		else:
			count_label.add_theme_color_override("font_color", UITokens.ACCENT_GREEN)
		count_label.custom_minimum_size.x = 80
		row.add_child(count_label)
		
		ingredients_list.add_child(row)

func _update_buff_display() -> void:
	# 清除现有 Buff 显示
	for child in buff_list.get_children():
		child.queue_free()
	
	# 获取活跃 Buff
	var active_buffs = []
	if CookingSystem and CookingSystem.has_method("get_active_buffs"):
		active_buffs = CookingSystem.get_active_buffs()
	
	if active_buffs.is_empty():
		var empty_label = Label.new()
		empty_label.text = I18n.translate("cooking.no_buffs")
		buff_list.add_child(empty_label)
		return
	
	# 显示每个 Buff
	for buff in active_buffs:
		var row = HBoxContainer.new()
		
		var type_label = Label.new()
		type_label.text = _get_buff_name(buff.get("type", ""))
		type_label.custom_minimum_size.x = 100
		row.add_child(type_label)
		
		var value_label = Label.new()
		value_label.text = "+%d" % buff.get("value", 0)
		value_label.custom_minimum_size.x = 60
		row.add_child(value_label)
		
		var duration_label = Label.new()
		duration_label.text = I18n.trf("cooking.duration", [buff.get("remaining_days", 0)])
		duration_label.custom_minimum_size.x = 50
		row.add_child(duration_label)
		
		buff_list.add_child(row)

func _get_buff_name(buff_type: String) -> String:
	var key_map = {
		"stamina_restore": "buff.stamina_restore",
		"speed": "buff.speed",
		"luck": "buff.luck"
	}
	var key = key_map.get(buff_type, "")
	if not key.is_empty() and I18n and I18n.has_method("translate"):
		return I18n.translate(key)
	return buff_type

func _clear_selection() -> void:
	selected_recipe_id = ""
	if _selected_recipe_row != null:
		_highlight_recipe_row(_selected_recipe_row, false)
		_selected_recipe_row = null
	if selected_recipe_label:
		selected_recipe_label.text = I18n.translate("cooking.select_recipe")
	if cook_button:
		cook_button.disabled = true
	
	# 清除食材列表
	for child in ingredients_list.get_children():
		child.queue_free()

# ============ 信号处理 ============

func _on_cook_pressed() -> void:
	if selected_recipe_id.is_empty():
		_set_status(I18n.translate("cooking.select_first"), true)
		return
	
	# 检查食材
	var recipe = CookingSystem.recipes.get(selected_recipe_id)
	if not recipe:
		_set_status(I18n.translate("cooking.recipe_not_found"), true)
		return
	
	var ingredients = recipe.get("ingredients", {})
	for ing_id in ingredients.keys():
		var required = ingredients[ing_id]
		var have = 0
		if InventorySystem and InventorySystem.has_method("get_item_count"):
			have = InventorySystem.get_item_count(ing_id)
		
		if have < required:
			_set_status(I18n.trf("cooking.ingredient_insufficient", [ing_id]), true)
			return
	
	# 开始烹饪
	var result = CookingSystem.cook_item(selected_recipe_id)
	if result:
		_set_status(I18n.trf("cooking.starting", [recipe.get("name", "")]))
		# 刷新食材显示
		_update_ingredients_display(recipe)
		# 延迟刷新菜谱列表（烹饪完成后需要重新显示）
		await get_tree().create_timer(0.5).timeout
		_populate_recipes()
	else:
		_set_status(I18n.translate("cooking.failed"), true)

func _on_close_pressed() -> void:
	close_panel()

func _on_cooking_finished(recipe_id: String) -> void:
	_set_status(I18n.translate("cooking.finished"))
	_populate_recipes()
	_update_buff_display()
	# Refresh the selected recipe detail if one was selected
	if not selected_recipe_id.is_empty() and CookingSystem.recipes.has(selected_recipe_id):
		_update_recipe_detail(CookingSystem.recipes[selected_recipe_id])

func _set_status(msg: String, is_error: bool = false) -> void:
	if status_label:
		status_label.text = msg
		if is_error:
			status_label.add_theme_color_override("font_color", UITokens.ACCENT_RED)
		else:
			status_label.add_theme_color_override("font_color", UITokens.ACCENT_GREEN)
