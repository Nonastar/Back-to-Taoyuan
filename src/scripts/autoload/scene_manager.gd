## ADR-0003: 场景管理与加载策略
## 分类: 系统逻辑 (Autoload)
## 依赖: Player

extends Node

## SceneManager - 场景管理器
## 负责世界场景和室内场景的加载与切换
## 遵循 ADR-0003 架构：场景=视觉，系统=逻辑

# ============ 常量 ============

## 世界场景路径
const WORLD_PATHS: Dictionary = {
	"farm": "res://src/scenes/worlds/farm/farm_world.tscn",
	"town": "res://src/scenes/worlds/town/town_world.tscn",
	"mine": "res://src/scenes/worlds/mountain/mine_world.tscn",
	"desert": "res://src/scenes/worlds/desert/desert_world.tscn"
}

## 室内场景路径
const INTERIOR_PATHS: Dictionary = {
	"fishpond": "res://src/scenes/interiors/fish_pond.tscn",
	"river": "res://src/scenes/interiors/fish_pond.tscn",
	"forest_pond": "res://src/scenes/interiors/fish_pond.tscn",
	"mountain_lake": "res://src/scenes/interiors/fish_pond.tscn",
	"ocean": "res://src/scenes/interiors/fish_pond.tscn",
	"shop": "res://src/scenes/interiors/shop.tscn",
	"cabin": "res://src/scenes/interiors/cabin.tscn",
	"mine_entrance": "res://src/scenes/interiors/mine_entrance.tscn",
	"animal": "res://src/scenes/interiors/animal_coop.tscn"
}

## 传送点位置
const TRANSITION_POINTS: Dictionary = {
	"farm_to_town": Vector2(640, 720),      # 农场底部边缘
	"town_to_farm": Vector2(640, 0),        # 城镇顶部
	"farm_to_mine": Vector2(1280, 360),     # 农场右边缘
	"mine_to_farm": Vector2(0, 360)         # 矿洞左边缘
}

# ============ 状态 ============

var current_world: String = ""
var current_interior: String = ""
var saved_world_position: Vector2 = Vector2(640, 360)
var is_transitioning: bool = false

# ============ 信号 ============

## 世界切换信号
signal world_changed(world_id: String, old_world: String)

## 室内进入/退出信号
signal interior_entered(building_id: String)
signal interior_exited(building_id: String)

## 传送信号
signal player_teleported(position: Vector2)

# ============ 初始化 ============

func _ready() -> void:
	# 延迟初始化，确保场景树准备好
	call_deferred("_initialize")

func _initialize() -> void:
	current_world = "farm"  # 初始世界
	_load_initial_world()
	print("[SceneManager] Initialized with world: " + str(current_world))

## 加载初始世界
func _load_initial_world() -> void:
	if not WORLD_PATHS.has(current_world):
		push_error("[SceneManager] Initial world not found in WORLD_PATHS")
		return

	var world_path = WORLD_PATHS[current_world]
	if not _load_world_scene(world_path):
		push_error("[SceneManager] Failed to load initial world: " + current_world)
		return

	# 加载 FarmLayer（承载 FarmManager）
	_load_farm_layer()

## 切换世界
func switch_world(target: String) -> bool:
	if is_transitioning:
		print("[SceneManager] Already transitioning, ignoring switch request")
		return false

	if not WORLD_PATHS.has(target):
		push_error("[SceneManager] Unknown world: %s" % target)
		return false

	if current_world == target:
		return true

	is_transitioning = true

	# 如果在室内，先退出室内
	if not current_interior.is_empty():
		_unload_current_interior()
		current_interior = ""

	# 卸载当前世界
	_unload_current_world()

	# 加载新世界
	var old_world = current_world
	var world_path = WORLD_PATHS[target]

	if not _load_world_scene(world_path):
		is_transitioning = false
		return false

	current_world = target
	is_transitioning = false

	# 同步更新 NavigationSystem 的当前世界
	if NavigationSystem:
		NavigationSystem.current_panel = target
		if EventBus:
			EventBus.panel_changed.emit(target)

	world_changed.emit(target, old_world)
	print("[SceneManager] Switched to world: " + str(target))

	return true

## 加载室内场景
func load_interior(building_id: String) -> bool:
	if current_interior == building_id:
		return true

	if not INTERIOR_PATHS.has(building_id):
		push_error("[SceneManager] Unknown interior: %s" % building_id)
		return false

	# 如果在世界中，先卸载世界
	if not current_world.is_empty():
		_unload_current_world()
		_unload_farm_layer()  # 同时清理 FarmLayer
		current_world = ""

	# 卸载当前室内（如果有）
	if not current_interior.is_empty():
		_unload_current_interior()

	# 先设置当前室内 ID
	current_interior = building_id

	# 加载新室内
	var interior_path = INTERIOR_PATHS[building_id]
	if not _load_interior_scene(interior_path, building_id):
		current_interior = ""  # 回滚
		return false

	# 同步更新 NavigationSystem 的当前面板
	if NavigationSystem:
		NavigationSystem.current_panel = building_id
		if EventBus:
			EventBus.panel_changed.emit(building_id)

	interior_entered.emit(building_id)
	return true

## 退出室内场景
func exit_interior() -> void:
	if current_interior.is_empty():
		print("[SceneManager] Not in an interior")
		return

	var old_interior = current_interior

	# 卸载室内
	_unload_current_interior()

	# 恢复世界位置
	_restore_player_position()

	current_interior = ""

	# 重新加载世界场景
	var world_to_load = "farm"  # 默认回到农场
	if current_world.is_empty():
		current_world = world_to_load
		_load_world_scene(WORLD_PATHS[world_to_load])

	# 重新加载 FarmLayer（农场管理器）
	_load_farm_layer()

	interior_exited.emit(old_interior)
	print("[SceneManager] Exited interior: " + str(old_interior))

## 获取当前世界
func get_current_world() -> String:
	return current_world

## 获取当前室内
func get_current_interior() -> String:
	return current_interior

## 检查是否在室内
func is_in_interior() -> bool:
	return not current_interior.is_empty()

## 传送玩家到指定位置
func teleport_player(position: Vector2) -> void:
	# 注意：Player 是 Autoload，这里只是记录位置
	saved_world_position = position
	player_teleported.emit(position)
	print("[SceneManager] Player teleported to: " + str(position))

# ============ 内部方法 ============

func _save_player_position() -> void:
	# Player 是 Autoload（处理输入逻辑），不需要保存位置
	# 场景切换时只需记录当前世界位置即可
	pass

func _restore_player_position() -> void:
	# Player 是 Autoload，不需要恢复位置
	pass

func _unload_current_world() -> void:
	var world_layer = _get_world_layer()
	if world_layer:
		for child in world_layer.get_children():
			world_layer.remove_child(child)
			child.queue_free()

func _unload_farm_layer() -> void:
	var root = get_tree().root
	var main = root.get_node_or_null("Main")
	if main:
		var farm_layer = main.get_node_or_null("FarmLayer")
		if farm_layer:
			for child in farm_layer.get_children():
				farm_layer.remove_child(child)
				child.queue_free()

func _load_farm_layer() -> void:
	var root = get_tree().root
	var main = root.get_node_or_null("Main")
	if not main:
		push_warning("[SceneManager] Main node not found, skipping FarmLayer load (test mode)")
		return

	# 获取或创建 FarmLayer
	var farm_layer = main.get_node_or_null("FarmLayer")
	if not farm_layer:
		farm_layer = Node2D.new()
		farm_layer.name = "FarmLayer"
		main.add_child(farm_layer)

	# 创建 FarmManager
	var farm_manager = FarmManager.new()
	farm_manager.name = "FarmManager"
	farm_manager.farm_name = "Home Farm"
	farm_layer.add_child(farm_manager)

	print("[SceneManager] FarmManager reloaded")

func _unload_current_interior() -> void:
	if current_interior.is_empty():
		return

	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_node(current_interior):
		var interior = main.get_node(current_interior)
		main.remove_child(interior)
		interior.queue_free()

func _load_world_scene(path: String) -> bool:
	var world_scene = load(path)
	if not world_scene:
		push_error("[SceneManager] Failed to load world scene: %s" % path)
		return false

	var world = world_scene.instantiate()
	if not world:
		push_error("[SceneManager] Failed to instantiate world: %s" % path)
		return false

	var world_layer = _get_world_layer()
	if world_layer:
		world_layer.add_child(world)
	else:
		var main = get_tree().root.get_node_or_null("Main")
		if main:
			main.add_child(world)
		else:
			push_warning("[SceneManager] Main node not found, skipping world load")
			world.free()
			return true  # 不算错误，测试环境下可能没有 Main

	return true

func _load_interior_scene(path: String, building_id: String) -> bool:
	var interior_scene = load(path)
	if not interior_scene:
		push_error("[SceneManager] Failed to load interior scene: %s" % path)
		return false

	var interior = interior_scene.instantiate()
	if not interior:
		push_error("[SceneManager] Failed to instantiate interior: %s" % path)
		return false

	# 室内场景添加到 Main
	var main = get_tree().root.get_node_or_null("Main")
	if not main:
		push_warning("[SceneManager] Main not found, skipping interior load")
		interior.free()
		return true
	interior.name = building_id  # 使用 building_id 作为节点名
	main.add_child(interior)

	# 注意：玩家位置由 Player Autoload 管理（基于相机）
	# 不需要在这里设置玩家位置

	return true

func _get_world_layer() -> Node2D:
	var root = get_tree().root
	var main = root.get_node_or_null("Main")
	if main:
		return main.get_node_or_null("WorldLayer")
	return null

# ============ 调试 ============

## 调试函数：列出所有可用场景
func debug_list_scenes() -> void:
	print("[SceneManager] Available worlds:")
	for world_id in WORLD_PATHS:
		var prefix = "  " if world_id != current_world else " * "
		print(prefix + world_id + ": " + WORLD_PATHS[world_id])

	print("[SceneManager] Available interiors:")
	for interior_id in INTERIOR_PATHS:
		var prefix = "  " if interior_id != current_interior else " * "
		print(prefix + interior_id + ": " + INTERIOR_PATHS[interior_id])
