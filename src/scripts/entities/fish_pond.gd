## ADR-0003: 场景管理与加载策略
## 分类: 视觉场景 (interior)
## 依赖: FishingSystem (Autoload), FishPondSystem (Autoload), FishPondUI

extends Node2D

## FishPond - 鱼塘场景
## 包含水池视觉、钓鱼点位置标记
## 钓鱼逻辑由 FishingSystem (Autoload) 处理
## 鱼塘养殖由 FishPondSystem (Autoload) 处理
## UI 由 FishPondUI (CanvasLayer) 处理

# ============ 节点引用 ============

@onready var water_area: Area2D = $WaterArea
@onready var pond_decoration: Node2D = $PondDecoration
@onready var info_panel: PanelContainer = $InfoPanel

# 鱼塘管理面板节点 (已弃用，使用 FishPondUI)
var _fish_pond_panel: PanelContainer
var _toggle_pond_button: Button

# ============ 钓鱼点位置 ============

var fishing_spot_positions: Array[Vector2] = []

# ============ 初始化 ============

func _ready() -> void:
	_setup_fishing_spots()
	_setup_info_panel()
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

## 设置信息面板
func _setup_info_panel() -> void:
	if info_panel:
		var vbox = info_panel.get_node_or_null("MarginContainer/VBox")
		if vbox:
			_toggle_pond_button = vbox.get_node_or_null("TogglePondButton")
			if _toggle_pond_button:
				_toggle_pond_button.pressed.connect(_on_toggle_pond_pressed)
				print("[FishPond] Toggle button found")

## 连接信号
func _connect_signals() -> void:
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
	if NotificationManager:
		NotificationManager.show_info(msg)
	print("[FishPond] " + str(msg))

# ============ 鱼塘管理UI ============

## 切换鱼塘管理面板 (使用 FishPondUI)
func toggle_pond_ui() -> void:
	FishPondUI.toggle()

## 鱼塘状态变化 (通知 FishPondUI 更新)
func _on_pond_state_changed() -> void:
	# FishPondUI 会通过 pond_state_changed 信号自动更新
	pass

## 切换鱼塘管理面板
func _on_toggle_pond_pressed() -> void:
	toggle_pond_ui()

## 输入处理
func _input(event: InputEvent) -> void:
	# 按 G 键切换鱼塘管理面板
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_G:
			toggle_pond_ui()
