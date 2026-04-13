extends CanvasLayer

## FishPondUI - 鱼塘界面
## 显示鱼塘状态，放入/取出鱼类，收获产物

# ============ 节点引用 ============

var _background: ColorRect
var _panel: PanelContainer
var _fish_count_label: Label
var _capacity_label: Label
var _fish_vbox: VBoxContainer
var _product_list: HBoxContainer
var _collect_button: Button
var _close_button: Button

# ============ 初始化 ============

func _ready() -> void:
	_setup_node_references()
	_connect_signals()
	_hide_ui()

func _setup_node_references() -> void:
	_background = $Background if has_node("Background") else null
	_panel = $Panel if has_node("Panel") else null

	if _panel:
		var vbox = _panel.get_node_or_null("VBox")
		if vbox:
			var info_section = vbox.get_node_or_null("InfoSection")
			if info_section:
				_fish_count_label = info_section.get_node_or_null("FishCount")

				## 找到容量Label (在FishCount之后)
				var children = info_section.get_children()
				for i in range(children.size()):
					if children[i] == _fish_count_label and i + 2 < children.size():
						_capacity_label = children[i + 2]
						break

			_fish_vbox = vbox.get_node_or_null("FishList/FishVBox")
			_product_list = vbox.get_node_or_null("ProductList")
			_collect_button = vbox.get_node_or_null("CollectButton")

			var button_section = vbox.get_node_or_null("ButtonSection")
			if button_section:
				_close_button = button_section.get_node_or_null("CloseButton")

func _connect_signals() -> void:
	if _collect_button:
		_collect_button.pressed.connect(_on_collect_pressed)
	if _close_button:
		_close_button.pressed.connect(_on_close_pressed)

	if FishPondSystem:
		FishPondSystem.pond_state_changed.connect(_on_pond_state_changed)
		FishPondSystem.product_collected.connect(_on_product_collected)

# ============ 显示/隐藏 ============

func show_ui() -> void:
	visible = true
	_update_display()

func hide_ui() -> void:
	visible = false

func _hide_ui() -> void:
	visible = false

func toggle_ui() -> void:
	if visible:
		hide_ui()
	else:
		show_ui()

# ============ 更新显示 ============

func _update_display() -> void:
	if not FishPondSystem:
		return

	## 更新鱼类数量
	var fish_count = FishPondSystem.get_fish_count()
	var capacity = FishPondSystem.get_capacity()

	if _fish_count_label:
		_fish_count_label.text = str(fish_count)
	if _capacity_label:
		_capacity_label.text = str(capacity)

	## 更新鱼类列表
	_update_fish_list()

	## 更新产物列表
	_update_product_list()

	## 更新收获按钮状态
	if _collect_button:
		_collect_button.disabled = not FishPondSystem.has_products_to_collect()

func _update_fish_list() -> void:
	if not _fish_vbox:
		return

	## 清空现有列表
	for child in _fish_vbox.get_children():
		child.queue_free()

	## 添加鱼类条目
	var fish_list = FishPondSystem.get_fish_list()
	for fish in fish_list:
		var label = Label.new()
		var maturity_str = "✅" if fish["is_mature"] else "⏳"
		label.text = "  %s %s (第%d天, 产出率%.0f%%)" % [
			maturity_str,
			fish["name"],
			fish["days_in_pond"],
			fish["production_rate"] * 100
		]
		_fish_vbox.add_child(label)

	## 如果没有鱼
	if fish_list.is_empty():
		var label = Label.new()
		label.text = "  (鱼塘是空的)"
		label.modulate = Color(0.5, 0.5, 0.5)
		_fish_vbox.add_child(label)

func _update_product_list() -> void:
	if not _product_list:
		return

	## 清空现有列表
	for child in _product_list.get_children():
		child.queue_free()

	## 添加产物条目
	var products = FishPondSystem.get_pending_products()
	if products.is_empty():
		var label = Label.new()
		label.text = "(无待收获产物)"
		label.modulate = Color(0.5, 0.5, 0.5)
		_product_list.add_child(label)
	else:
		for product in products:
			var label = Label.new()
			var quality_emoji = _get_quality_emoji(product.get("quality", "normal"))
			label.text = "%s x%d" % [quality_emoji, product.get("quantity", 1)]
			_product_list.add_child(label)

func _get_quality_emoji(quality: String) -> String:
	match quality:
		"excellent":
			return "⭐"
		"fine":
			return "✨"
		"normal":
			return "🐟"
		_:
			return "🐟"

# ============ 信号处理 ============

func _on_pond_state_changed() -> void:
	_update_display()

func _on_product_collected(product_id: String, quality: String, quantity: int) -> void:
	_show_notification("收获了: %s x%d" % [product_id, quantity])

func _on_collect_pressed() -> void:
	if FishPondSystem:
		var collected = FishPondSystem.collect_products()
		if collected > 0:
			_show_notification("收获了 %d 件产物!" % collected)
		else:
			_show_notification("没有可收获的产物")

func _on_close_pressed() -> void:
	hide_ui()

# ============ 通知系统 ============

func _show_notification(text: String) -> void:
	if NotificationManager and NotificationManager.has_method("show_notification"):
		NotificationManager.show_notification(text)
	else:
		print("[FishPondUI] " + text)

# ============ 输入处理 ============

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		_on_close_pressed()
