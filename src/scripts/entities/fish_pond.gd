## ADR-0003: 场景管理与加载策略
## 分类: 视觉场景 (interior)
## 依赖: FishingSystem (Autoload), FishPondSystem (Autoload)

extends Node2D

## FishPond - 鱼塘场景
## 包含水池视觉、钓鱼点位置标记
## 钓鱼逻辑由 FishingSystem (Autoload) 处理
## 鱼塘养殖由 FishPondSystem (Autoload) 处理

# ============ 节点引用 ============

@onready var water_area: Area2D = $WaterArea
@onready var pond_decoration: Node2D = $PondDecoration
@onready var fish_pond_panel: PanelContainer = $FishPondPanel
@onready var info_panel: PanelContainer = $InfoPanel

# 鱼塘管理面板节点
var _fish_count_label: Label
var _capacity_label: Label
var _fish_vbox: VBoxContainer
var _product_list: HBoxContainer
var _collect_button: Button
var _add_fish_button: Button
var _close_button: Button
var _toggle_pond_button: Button

# ============ 钓鱼点位置 ============

var fishing_spot_positions: Array[Vector2] = []

# ============ 初始化 ============

func _ready() -> void:
	_setup_fishing_spots()
	_setup_fish_pond_ui()
	_connect_signals()
	print("[FishPond] Initialized")

## 设置钓鱼点
func _setup_fishing_spots() -> void:
	# 从场景中获取钓鱼点标记
	var markers = ["FishingMarker1", "FishingMarker2", "FishingMarker3"]
	for marker_name in markers:
		var marker = water_area.get_node_or_null(marker_name)
		if marker:
			fishing_spot_positions.append(marker.position)
			print("[FishPond] Found fishing marker at: " + str(marker.position))

## 设置鱼塘管理UI
func _setup_fish_pond_ui() -> void:
	# 设置信息面板中的按钮
	if info_panel:
		var vbox = info_panel.get_node_or_null("MarginContainer/VBox")
		if vbox:
			_toggle_pond_button = vbox.get_node_or_null("TogglePondButton")
			if _toggle_pond_button:
				_toggle_pond_button.pressed.connect(_on_toggle_pond_pressed)
				print("[FishPond] Toggle button found")

	# 设置鱼塘管理面板
	if fish_pond_panel:
		var vbox = fish_pond_panel.get_node_or_null("MarginContainer/VBox")
		if vbox:
			var info_section = vbox.get_node_or_null("InfoSection")
			if info_section:
				_fish_count_label = info_section.get_node_or_null("FishCount")
				_capacity_label = info_section.get_node_or_null("Capacity")

			_fish_vbox = vbox.get_node_or_null("FishScroll/FishVBox")
			_product_list = vbox.get_node_or_null("ProductList")

			var collect_btn = vbox.get_node_or_null("CollectButton")
			if collect_btn:
				_collect_button = collect_btn
				_collect_button.pressed.connect(_on_collect_pressed)

			var button_section = vbox.get_node_or_null("ButtonSection")
			if button_section:
				_add_fish_button = button_section.get_node_or_null("AddFishButton")
				if _add_fish_button:
					_add_fish_button.pressed.connect(_on_add_fish_pressed)
				_close_button = button_section.get_node_or_null("CloseButton")
				if _close_button:
					_close_button.pressed.connect(_on_close_pond_ui)

		# 初始隐藏鱼塘面板
		fish_pond_panel.visible = false

## 连接信号
func _connect_signals() -> void:
	# 鱼塘系统信号
	if FishPondSystem:
		FishPondSystem.pond_state_changed.connect(_on_pond_state_changed)

## 检查是否在钓鱼范围内
func is_in_fishing_range(player_pos: Vector2, range: float = 100.0) -> bool:
	var nearest = get_nearest_fishing_spot(player_pos)
	return player_pos.distance_to(nearest) <= range

# ============ 钓鱼相关 ============

## 获取最近的钓鱼点
func get_nearest_fishing_spot(player_pos: Vector2) -> Vector2:
	var nearest = Vector2.ZERO
	var min_dist = INF

	for spot in fishing_spot_positions:
		var dist = player_pos.distance_to(spot)
		if dist < min_dist:
			min_dist = dist
			nearest = spot

	return nearest

## 尝试开始钓鱼
func try_start_fishing() -> bool:
	# 检查是否已经在钓鱼
	if FishingSystem and FishingSystem.is_fishing():
		_show_message("正在钓鱼中...")
		return false

	# 检查体力
	if PlayerStats and PlayerStats.stamina < 2:
		_show_message("体力不足！")
		return false

	# 开始钓鱼
	if FishingSystem:
		FishingSystem.start_fishing("fishpond")
		_show_message("开始钓鱼...")
		return true
	else:
		_show_message("钓鱼系统未初始化")
		return false

## 显示消息
func _show_message(msg: String) -> void:
	if EventBus:
		EventBus.notification_show.emit(msg, 2.0)
	print("[FishPond] " + str(msg))

# ============ 鱼塘管理UI ============

## 切换鱼塘管理面板
func toggle_pond_ui() -> void:
	if fish_pond_panel:
		fish_pond_panel.visible = not fish_pond_panel.visible
		if fish_pond_panel.visible:
			_update_pond_ui()

## 关闭鱼塘管理面板
func _on_close_pond_ui() -> void:
	if fish_pond_panel:
		fish_pond_panel.visible = false

## 更新鱼塘UI
func _update_pond_ui() -> void:
	if not FishPondSystem:
		return

	# 更新鱼类数量
	var fish_count = FishPondSystem.get_fish_count()
	var capacity = FishPondSystem.get_capacity()

	if _fish_count_label:
		_fish_count_label.text = str(fish_count)
	if _capacity_label:
		_capacity_label.text = str(capacity)

	# 更新鱼类列表
	_update_fish_list()

	# 更新产物列表
	_update_product_list()

	# 更新按钮状态
	if _collect_button:
		_collect_button.disabled = not FishPondSystem.has_products_to_collect()

	if _add_fish_button:
		_add_fish_button.disabled = FishPondSystem.get_fish_count() >= FishPondSystem.get_capacity()

func _update_fish_list() -> void:
	if not _fish_vbox:
		return

	# 清空现有列表
	for child in _fish_vbox.get_children():
		child.queue_free()

	# 添加鱼类条目
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

	# 如果没有鱼
	if fish_list.is_empty():
		var label = Label.new()
		label.text = "  (鱼塘是空的)"
		label.modulate = Color(0.5, 0.5, 0.5)
		_fish_vbox.add_child(label)

func _update_product_list() -> void:
	if not _product_list:
		return

	# 清空现有列表
	for child in _product_list.get_children():
		child.queue_free()

	# 添加产物条目
	var products = FishPondSystem.get_pending_products()
	if products.is_empty():
		var label = Label.new()
		label.text = "(无待收获)"
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

## 收获产物
func _on_collect_pressed() -> void:
	if FishPondSystem:
		var collected = FishPondSystem.collect_products()
		if collected > 0:
			_show_message("收获了 %d 件产物!" % collected)
		else:
			_show_message("没有可收获的产物")

## 放入鱼类
func _on_add_fish_pressed() -> void:
	# TODO: 显示鱼类选择对话框
	# 目前暂时显示提示
	_show_message("放入鱼类功能开发中...")

## 鱼塘状态变化
func _on_pond_state_changed() -> void:
	if fish_pond_panel and fish_pond_panel.visible:
		_update_pond_ui()

## 切换鱼塘管理面板
func _on_toggle_pond_pressed() -> void:
	toggle_pond_ui()

## 输入处理
func _input(event: InputEvent) -> void:
	# 按 G 键切换鱼塘管理面板
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_G:
			toggle_pond_ui()
