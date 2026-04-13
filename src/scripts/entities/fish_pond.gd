## ADR-0003: 场景管理与加载策略
## 分类: 视觉场景 (interior)
## 依赖: FishingSystem (Autoload)

extends Node2D

## FishPond - 鱼塘场景（仅视觉）
## 包含水池视觉、钓鱼点位置标记
## 钓鱼逻辑由 FishingSystem (Autoload) 处理

# ============ 节点引用 ============

@onready var water_area: Area2D = $WaterArea
@onready var pond_decoration: Node2D = $PondDecoration

# ============ 钓鱼点位置 ============

var fishing_spot_positions: Array[Vector2] = []

# ============ 初始化 ============

func _ready() -> void:
	_setup_fishing_spots()
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

# ============ 交互 ============

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

## 检查是否在钓鱼范围内
func is_in_fishing_range(player_pos: Vector2, range: float = 100.0) -> bool:
	var nearest = get_nearest_fishing_spot(player_pos)
	return player_pos.distance_to(nearest) <= range
