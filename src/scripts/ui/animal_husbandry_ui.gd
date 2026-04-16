class_name AnimalHusbandryUI
extends CanvasLayer

## AnimalHusbandryUI - 畜牧系统交互界面
## 显示动物信息、喂养/抚摸按钮、产出收集
## 重构版本: 修复bug、改进布局、支持无障碍、视觉增强
##
## 主要改进 (v2):
## - 添加容量指示器
## - 添加喂养成本显示
## - 添加悬停效果
## - 改进空状态（添加商店链接）
## - 改进未成年动物显示（变暗）
## - 添加好感度满级视觉效果
##
## 依赖系统:
## - AnimalHusbandrySystem: 动物数据源
## - InventorySystem: 饲料数量查询
## - NotificationManager: 通知显示

# ============ 常量 ============

## 卡片样式常量
const CARD_HEIGHT: int = 72
const PROGRESS_BAR_WIDTH: int = 200
const PROGRESS_BAR_HEIGHT: int = 12
const BUTTON_WIDTH: int = 60
const BUTTON_HEIGHT: int = 30

## 透明度常量
const IMMATURE_OPACITY: float = 0.7

## 颜色常量
const COLOR_GOLD: Color = Color(0.8, 0.6, 0.2)
const COLOR_GOLD_BG: Color = Color(0.8, 0.6, 0.2, 0.3)
const COLOR_GOLD_BORDER: Color = Color(0.8, 0.6, 0.2, 0.8)
const COLOR_SPRING_BADGE: Color = Color(0.6, 0.4, 0.8, 1)
const COLOR_STAR_BADGE: Color = Color(1, 0.84, 0, 1)

## 悬停效果常量
const HOVER_BRIGHTNESS: float = 1.15

# ============ 单例引用 ============

static var _instance: AnimalHusbandryUI = null

static func get_instance() -> AnimalHusbandryUI:
	return _instance

static func toggle() -> void:
	if _instance == null:
		return
	if _instance.visible:
		_instance._hide_ui()
	else:
		_instance._show_ui()

static func show_animal_ui() -> void:
	if _instance == null:
		return
	_instance._show_ui()

static func hide_animal_ui() -> void:
	if _instance == null:
		return
	_instance._hide_ui()

# ============ 节点引用 ============

var _background: ColorRect
var _panel: PanelContainer
var _coop_tab_btn: Button
var _barn_tab_btn: Button
var _animal_scroll: ScrollContainer
var _animal_vbox: VBoxContainer
var _product_list: HBoxContainer
var _feed_all_btn: Button
var _pet_all_btn: Button
var _collect_btn: Button
var _close_btn: Button
var _shop_btn: Button  ## 新增：商店快捷按钮
var _feed_cost_label: Label  ## 新增：喂养成本提示

# ============ 状态 ============

var _current_building_type: int = 0  # 0=COOP, 1=BARN
var _focusable_buttons: Array[Button] = []
var _current_focus_index: int = -1

# ============ 初始化 ============

func _ready() -> void:
	_instance = self
	_setup_node_references()
	_connect_signals()
	_show_ui()  # 加载后自动显示
	print("[AnimalHusbandryUI] Initialized")

func _setup_node_references() -> void:
	_background = $Background if has_node("Background") else null
	_panel = $Panel if has_node("Panel") else null

	if _panel:
		var vbox = _panel.get_node_or_null("VBox")
		if vbox:
			# 标签按钮
			var tab_buttons = vbox.get_node_or_null("TabButtons")
			if tab_buttons:
				_coop_tab_btn = tab_buttons.get_node_or_null("CoopTabBtn")
				_barn_tab_btn = tab_buttons.get_node_or_null("BarnTabBtn")

			# 动物列表
			_animal_scroll = vbox.get_node_or_null("AnimalScroll")
			if _animal_scroll:
				_animal_vbox = _animal_scroll.get_node_or_null("AnimalVBox")

			# 产物列表
			var product_section = vbox.get_node_or_null("ProductSection")
			if product_section:
				_product_list = product_section.get_node_or_null("ProductList")
				_feed_cost_label = product_section.get_node_or_null("FeedCostLabel")

			# 操作按钮
			var action_buttons = vbox.get_node_or_null("ActionButtons")
			if action_buttons:
				_feed_all_btn = action_buttons.get_node_or_null("FeedAllBtn")
				_pet_all_btn = action_buttons.get_node_or_null("PetAllBtn")
				_collect_btn = action_buttons.get_node_or_null("CollectBtn")

			# 底部按钮
			var bottom_buttons = vbox.get_node_or_null("BottomButtons")
			if bottom_buttons:
				_close_btn = bottom_buttons.get_node_or_null("CloseBtn")
				_shop_btn = bottom_buttons.get_node_or_null("ShopBtn")

	# 设置悬停效果
	_setup_hover_effect(_coop_tab_btn)
	_setup_hover_effect(_barn_tab_btn)
	_setup_hover_effect(_feed_all_btn)
	_setup_hover_effect(_pet_all_btn)
	_setup_hover_effect(_collect_btn)
	_setup_hover_effect(_close_btn)
	_setup_hover_effect(_shop_btn)

func _connect_signals() -> void:
	# 标签按钮
	if _coop_tab_btn:
		_coop_tab_btn.pressed.connect(_on_coop_tab_pressed)
	if _barn_tab_btn:
		_barn_tab_btn.pressed.connect(_on_barn_tab_pressed)

	# 操作按钮
	if _feed_all_btn:
		_feed_all_btn.pressed.connect(_on_feed_all_pressed)
	if _pet_all_btn:
		_pet_all_btn.pressed.connect(_on_pet_all_pressed)
	if _collect_btn:
		_collect_btn.pressed.connect(_on_collect_pressed)
	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)
	if _shop_btn:
		_shop_btn.pressed.connect(_on_shop_pressed)

	# 畜牧系统信号
	if AnimalHusbandrySystem:
		AnimalHusbandrySystem.animal_state_changed.connect(_on_animal_state_changed)
		AnimalHusbandrySystem.animal_friendship_changed.connect(_on_friendship_changed)
		AnimalHusbandrySystem.product_collected.connect(_on_product_collected)
		AnimalHusbandrySystem.building_built.connect(_on_building_built)

# ============ 显示/隐藏 ============

func _show_ui() -> void:
	# 面板动画
	if _panel:
		_modulate_panel(true)

	visible = true
	_update_display()
	_update_focusable_buttons()

	# 默认焦点到标签按钮
	if _coop_tab_btn and not _coop_tab_btn.disabled:
		_coop_tab_btn.grab_focus()
	elif _barn_tab_btn and not _barn_tab_btn.disabled:
		_barn_tab_btn.grab_focus()

func _hide_ui() -> void:
	_modulate_panel(false)
	await get_tree().create_timer(0.3).timeout
	visible = false
	_release_all_focus()

func _modulate_panel(show: bool) -> void:
	if not _panel:
		return

	var tween = create_tween()
	if show:
		_panel.modulate = Color(1, 1, 1, 0)
		_panel.scale = Vector2(0.9, 0.9)
		tween.tween_property(_panel, "modulate:a", 1.0, 0.25)
		tween.parallel().tween_property(_panel, "scale", Vector2(1, 1), 0.25)
	else:
		tween.tween_property(_panel, "modulate:a", 0.0, 0.25)
		tween.parallel().tween_property(_panel, "scale", Vector2(0.9, 0.9), 0.25)

# ============ 更新显示 ============

func _update_display() -> void:
	if not AnimalHusbandrySystem:
		return

	_update_tab_buttons()
	_update_animal_list()
	_update_product_list()
	_update_button_states()

func _update_tab_buttons() -> void:
	if not AnimalHusbandrySystem:
		return

	var coop_built = AnimalHusbandrySystem.is_building_built(AnimalHusbandrySystem.BuildingType.COOP)
	var barn_built = AnimalHusbandrySystem.is_building_built(AnimalHusbandrySystem.BuildingType.BARN)

	# 获取容量信息
	var coop_count = AnimalHusbandrySystem.get_building_animal_count(AnimalHusbandrySystem.BuildingType.COOP) if coop_built else 0
	var coop_capacity = AnimalHusbandrySystem.get_building_capacity(AnimalHusbandrySystem.BuildingType.COOP)
	var barn_count = AnimalHusbandrySystem.get_building_animal_count(AnimalHusbandrySystem.BuildingType.BARN) if barn_built else 0
	var barn_capacity = AnimalHusbandrySystem.get_building_capacity(AnimalHusbandrySystem.BuildingType.BARN)

	if _coop_tab_btn:
		_coop_tab_btn.disabled = not coop_built
		_coop_tab_btn.text = "🐔 鸡舍 (%d/%d)" % [coop_count, coop_capacity]
	if _barn_tab_btn:
		_barn_tab_btn.disabled = not barn_built
		_barn_tab_btn.text = "🐄 谷仓 (%d/%d)" % [barn_count, barn_capacity]

	# 如果当前标签被禁用，切换到可用标签
	if _current_building_type == 0 and not coop_built:
		_current_building_type = 1 if barn_built else 0
	elif _current_building_type == 1 and not barn_built:
		_current_building_type = 0 if coop_built else 1

	# 更新按钮状态
	if _coop_tab_btn:
		_coop_tab_btn.button_pressed = (_current_building_type == 0)
	if _barn_tab_btn:
		_barn_tab_btn.button_pressed = (_current_building_type == 1)

func _update_animal_list() -> void:
	if not _animal_vbox:
		return

	# 清空现有列表
	for child in _animal_vbox.get_children():
		child.queue_free()

	var building_type = AnimalHusbandrySystem.BuildingType.COOP if _current_building_type == 0 else AnimalHusbandrySystem.BuildingType.BARN
	var animals = AnimalHusbandrySystem.get_animals_in_building(building_type)

	if animals.is_empty():
		_add_empty_state()
		return

	# 添加动物卡片
	for animal in animals:
		var unique_id = animal.get("unique_id", "")
		var animal_id = animal.get("animal_id", "")
		var animal_data = AnimalHusbandrySystem._get_animal_data(animal_id)
		var card = _create_animal_card(animal, animal_data)
		_animal_vbox.add_child(card)

func _add_empty_state() -> void:
	var empty_panel = PanelContainer.new()
	empty_panel.custom_minimum_size = Vector2(0, 100)

	var vbox = VBoxContainer.new()
	empty_panel.add_child(vbox)

	var icon_label = Label.new()
	icon_label.text = "[ 鸡舍 ]" if _current_building_type == 0 else "[ 谷仓 ]"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)

	var empty_label = Label.new()
	empty_label.text = "空空如也"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(empty_label)

	var hint_label = Label.new()
	hint_label.text = "去购买小动物吧~"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.modulate = Color(0.6, 0.6, 0.6, 1)
	vbox.add_child(hint_label)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.add_child(center)

	_animal_vbox.add_child(empty_panel)

func _create_animal_card(animal: Dictionary, animal_data: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, CARD_HEIGHT)

	# 处理未成年动物的视觉效果
	var is_mature = animal.get("is_mature", false)
	var friendship = animal.get("friendship", 0)
	var level_name = AnimalHusbandrySystem.get_friendship_level_name(friendship)
	var is_best_friend = level_name == "Best Friend"

	if not is_mature:
		# 未成年动物：降低透明度
		panel.modulate = Color(1, 1, 1, IMMATURE_OPACITY)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	# 左侧: 动物信息
	var info_vbox = VBoxContainer.new()
	hbox.add_child(info_vbox)

	# 第一行: 名称 + 好感度等级 + 特殊状态标记
	var top_hbox = HBoxContainer.new()
	info_vbox.add_child(top_hbox)

	# 特殊状态标记
	if not is_mature:
		var badge = Label.new()
		badge.text = "🌱 "
		badge.modulate = COLOR_SPRING_BADGE
		top_hbox.add_child(badge)
	elif is_best_friend:
		var badge = Label.new()
		badge.text = "⭐ "
		badge.modulate = COLOR_STAR_BADGE
		top_hbox.add_child(badge)

	var name_label = Label.new()
	name_label.text = "%s  %s" % [animal_data.get("emoji", "?"), animal_data.get("name", "未知")]
	top_hbox.add_child(name_label)

	var level_label = Label.new()
	var level_color = _get_level_color(level_name)
	level_label.text = "  %s (%d)" % [level_name, friendship]
	level_label.modulate = level_color
	top_hbox.add_child(level_label)

	# 添加 Best Friend 发光边框
	if is_best_friend:
		var style = StyleBoxFlat.new()
		style.set_bg_color(COLOR_GOLD_BG)
		style.set_border_color(COLOR_GOLD_BORDER)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("normal", style)

	# 第二行: 好感度进度条
	var progress = AnimalHusbandrySystem.get_friendship_progress(friendship)
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(PROGRESS_BAR_WIDTH, PROGRESS_BAR_HEIGHT)
	progress_bar.max_value = 1.0
	progress_bar.value = progress
	progress_bar.show_percentage = true
	info_vbox.add_child(progress_bar)

	# 第三行: 状态
	var status_label = Label.new()
	status_label.text = _get_status_text(animal)
	status_label.modulate = Color(0.5, 0.5, 0.5, 1)
	info_vbox.add_child(status_label)

	# 右侧: 操作按钮
	var btn_vbox = VBoxContainer.new()
	hbox.add_child(btn_vbox)

	var fed_today = animal.get("fed_today", false)
	var pet_today = animal.get("pet_today", false)
	var unique_id = animal.get("unique_id", "")

	var feed_btn = Button.new()
	feed_btn.text = "喂养"
	feed_btn.custom_minimum_size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)
	feed_btn.disabled = fed_today
	feed_btn.pressed.connect(_on_feed_single_pressed.bind(unique_id))
	_setup_hover_effect(feed_btn)
	btn_vbox.add_child(feed_btn)

	var pet_btn = Button.new()
	pet_btn.text = "抚摸"
	pet_btn.custom_minimum_size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)
	pet_btn.disabled = pet_today
	pet_btn.pressed.connect(_on_pet_single_pressed.bind(unique_id))
	_setup_hover_effect(pet_btn)
	btn_vbox.add_child(pet_btn)

	return panel

func _get_level_color(level_name: String) -> Color:
	match level_name:
		"Best Friend":
			return Color(0.8, 0.6, 0.2, 1)  # 金色
		"Friend":
			return Color(0.3, 0.6, 0.9, 1)  # 蓝色
		"Pal":
			return Color(0.3, 0.7, 0.3, 1)  # 绿色
		_:
			return Color(0.5, 0.5, 0.5, 1)  # 灰色

func _get_status_text(animal: Dictionary) -> String:
	var parts = []
	if animal.get("is_mature", false):
		parts.append("成年")
	else:
		parts.append("幼年")

	if animal.get("fed_today", false):
		parts.append("已喂养")
	else:
		parts.append("饥饿")

	if animal.get("pet_today", false):
		parts.append("已抚摸")

	return " | ".join(parts)

func _update_product_list() -> void:
	if not _product_list:
		return

	# 清空现有列表
	for child in _product_list.get_children():
		child.queue_free()

	var products = AnimalHusbandrySystem.get_pending_products() if AnimalHusbandrySystem else []

	if products.is_empty():
		var empty_label = Label.new()
		empty_label.text = "(无)"
		empty_label.modulate = Color(0.5, 0.5, 0.5, 1)
		_product_list.add_child(empty_label)
	else:
		for i in range(products.size()):
			var product = products[i]
			var preview = AnimalHusbandrySystem.get_product_preview_quality(i) if AnimalHusbandrySystem else {}
			var quality = preview.get("quality", 0)
			var quality_color = Quality.get_color(quality)

			var label = Label.new()
			label.text = "[%s] x%d" % [Quality.get_quality_name(quality), product.get("quantity", 1)]
			label.modulate = quality_color
			_product_list.add_child(label)

func _update_button_states() -> void:
	if not AnimalHusbandrySystem:
		return

	var has_animals = AnimalHusbandrySystem.has_animals_to_feed()
	var has_products = AnimalHusbandrySystem.has_products_to_collect()

	# 获取饲料数量
	var hay_count = InventorySystem.get_item_count("hay") if InventorySystem else 0
	var feed_cost = AnimalHusbandrySystem.FEED_COST_HAY if AnimalHusbandrySystem else 1
	var has_enough_hay = hay_count >= feed_cost

	# 更新喂养成本提示
	if _feed_cost_label:
		if has_enough_hay:
			_feed_cost_label.text = "需要: 干草 x%d (持有: %d)" % [feed_cost, hay_count]
			_feed_cost_label.modulate = Color(0.5, 0.8, 0.5, 1)  # 绿色表示足够
		else:
			_feed_cost_label.text = "需要: 干草 x%d (持有: %d) - 饲料不足!" % [feed_cost, hay_count]
			_feed_cost_label.modulate = Color(1, 0.6, 0.3, 1)  # 橙色表示不足

	# 更新按钮状态
	if _feed_all_btn:
		_feed_all_btn.disabled = not has_animals or not has_enough_hay
	if _pet_all_btn:
		_pet_all_btn.disabled = not has_animals
	if _collect_btn:
		_collect_btn.disabled = not has_products

	# 更新商店按钮状态
	if _shop_btn:
		var building_type = AnimalHusbandrySystem.BuildingType.COOP if _current_building_type == 0 else AnimalHusbandrySystem.BuildingType.BARN
		var is_built = AnimalHusbandrySystem.is_building_built(building_type)
		var animal_count = AnimalHusbandrySystem.get_building_animal_count(building_type) if is_built else 0
		var capacity = AnimalHusbandrySystem.get_building_capacity(building_type) if is_built else 0
		_shop_btn.disabled = not is_built or animal_count >= capacity
		if not is_built:
			_shop_btn.text = "🏗️ 建造建筑"
		elif animal_count >= capacity:
			_shop_btn.text = "满员"
		else:
			_shop_btn.text = "🛒 去商店"

# ============ 焦点管理 ============

func _update_focusable_buttons() -> void:
	_focusable_buttons.clear()

	# 添加标签按钮
	if _coop_tab_btn and not _coop_tab_btn.disabled:
		_focusable_buttons.append(_coop_tab_btn)
	if _barn_tab_btn and not _barn_tab_btn.disabled:
		_focusable_buttons.append(_barn_tab_btn)

	# 添加动物卡片按钮 (从VBox中获取)
	if _animal_vbox:
		for child in _animal_vbox.get_children():
			if child is PanelContainer:
				for btn in child.find_children("*", "Button", true, false):
					if btn is Button and not btn.disabled:
						_focusable_buttons.append(btn)

	# 添加操作按钮
	if _feed_all_btn and not _feed_all_btn.disabled:
		_focusable_buttons.append(_feed_all_btn)
	if _pet_all_btn and not _pet_all_btn.disabled:
		_focusable_buttons.append(_pet_all_btn)
	if _collect_btn and not _collect_btn.disabled:
		_focusable_buttons.append(_collect_btn)

func _release_all_focus() -> void:
	for btn in _focusable_buttons:
		if btn and btn.has_focus():
			btn.release_focus()
	_current_focus_index = -1

# ============ 信号处理 ============

func _on_coop_tab_pressed() -> void:
	_current_building_type = 0
	_update_animal_list()
	_update_focusable_buttons()

func _on_barn_tab_pressed() -> void:
	_current_building_type = 1
	_update_animal_list()
	_update_focusable_buttons()

func _on_animal_state_changed() -> void:
	_update_display()
	_update_focusable_buttons()

func _on_friendship_changed(unique_id: String, old_friendship: int, new_friendship: int) -> void:
	var details = AnimalHusbandrySystem.get_animal_details(unique_id) if AnimalHusbandrySystem else {}
	var animal_name = details.get("animal_id", unique_id)
	_show_notification("%s 好感度: %d -> %d" % [animal_name, old_friendship, new_friendship])
	_update_display()

func _on_product_collected(product_id: String, quantity: int) -> void:
	_show_notification("收获了: %s x%d" % [product_id, quantity])
	_update_display()

func _on_building_built(building_type: int) -> void:
	_update_display()

# ============ 操作处理 ============

func _on_feed_single_pressed(unique_id: String) -> void:
	if not AnimalHusbandrySystem:
		return

	var success = AnimalHusbandrySystem.feed_single_animal(unique_id)
	if success:
		var details = AnimalHusbandrySystem.get_animal_details(unique_id)
		var animal_name = details.get("animal_id", "未知")
		var friendship = details.get("friendship", 0)
		_show_notification("喂养 %s 成功! 好感度: %d" % [animal_name, friendship])
	else:
		_show_notification("喂养失败: 饲料不足或已喂养")

func _on_pet_single_pressed(unique_id: String) -> void:
	if not AnimalHusbandrySystem:
		return

	var success = AnimalHusbandrySystem.pet_single_animal(unique_id)
	if success:
		var details = AnimalHusbandrySystem.get_animal_details(unique_id)
		var animal_name = details.get("animal_id", "未知")
		var friendship = details.get("friendship", 0)
		_show_notification("抚摸 %s 成功! 好感度: %d" % [animal_name, friendship])
	else:
		_show_notification("抚摸失败: 今日已抚摸")

func _on_feed_all_pressed() -> void:
	if not AnimalHusbandrySystem:
		return

	var fed_count = 0
	var all_animals = AnimalHusbandrySystem.get_all_animals_with_friendship()
	for animal in all_animals:
		if not animal.get("fed_today", false):
			if AnimalHusbandrySystem.feed_single_animal(animal.get("unique_id", "")):
				fed_count += 1

	if fed_count > 0:
		_show_notification("喂养了 %d 只动物!" % fed_count)
	else:
		_show_notification("没有需要喂养的动物（或饲料不足）")

func _on_pet_all_pressed() -> void:
	if not AnimalHusbandrySystem:
		return

	var pet_count = 0
	var all_animals = AnimalHusbandrySystem.get_all_animals_with_friendship()
	for animal in all_animals:
		if not animal.get("pet_today", false):
			if AnimalHusbandrySystem.pet_single_animal(animal.get("unique_id", "")):
				pet_count += 1

	if pet_count > 0:
		_show_notification("抚摸了 %d 只动物!" % pet_count)
	else:
		_show_notification("没有需要抚摸的动物（或今日已抚摸）")

func _on_collect_pressed() -> void:
	if not AnimalHusbandrySystem:
		return

	var collected = AnimalHusbandrySystem.collect_all_products()
	if collected > 0:
		_show_notification("收获了 %d 件产物!" % collected)
	else:
		_show_notification("没有可收获的产物")

func _on_close_pressed() -> void:
	_hide_ui()

func _on_shop_pressed() -> void:
	# 商店功能暂未实现，显示提示
	_show_notification("商店功能暂未开放，请前往村落购买动物")
	_hide_ui()

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
		print("[AnimalHusbandryUI] " + text)

# ============ 输入处理 ============

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# ESC 关闭
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		return

	# 方向键导航 (游戏手柄支持)
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
		_navigate_focus(-1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
		_navigate_focus(1)

func _navigate_focus(direction: int) -> void:
	if _focusable_buttons.is_empty():
		return

	if _current_focus_index < 0:
		_current_focus_index = 0
	else:
		_current_focus_index = (_current_focus_index + direction) % _focusable_buttons.size()

	var btn = _focusable_buttons[_current_focus_index]
	if btn and is_instance_valid(btn):
		btn.grab_focus()
