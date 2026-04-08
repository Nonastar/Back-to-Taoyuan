extends CharacterBody2D
class_name Player

## Player - 玩家角色
## 参考: ADR-0001 OOP架构, C01 玩家属性系统 GDD

# ============ 移动配置 ============

## 移动速度 (像素/秒)
const MOVE_SPEED: float = 200.0

## 动画方向阈值
const DIRECTION_THRESHOLD: float = 0.5

# ============ 状态 ============

## 玩家当前方向
var facing_direction: Vector2 = Vector2.DOWN

## 是否可以移动
var can_move: bool = true

# ============ 节点引用 ============

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

# ============ 初始化 ============

func _ready() -> void:
	# 连接事件
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.sleep_triggered.connect(_on_sleep_triggered)
	print("[Player] Initialized")

func _process(delta: float) -> void:
	if not can_move:
		return
	_handle_movement_input()

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

# ============ 移动控制 ============

func _handle_movement_input() -> void:
	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if input_dir.length() > 0:
		velocity = input_dir.normalized() * MOVE_SPEED
		_update_facing_direction(input_dir)
		_play_walk_animation()
	else:
		velocity = Vector2.ZERO
		_play_idle_animation()

func _update_facing_direction(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			facing_direction = Vector2.RIGHT
		else:
			facing_direction = Vector2.LEFT
	else:
		if dir.y > 0:
			facing_direction = Vector2.DOWN
		else:
			facing_direction = Vector2.UP

func _play_walk_animation() -> void:
	var anim_name = _get_direction_animation_name("walk")
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func _play_idle_animation() -> void:
	var anim_name = _get_direction_animation_name("idle")
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func _get_direction_animation_name(prefix: String) -> String:
	match facing_direction:
		Vector2.UP:
			return "%s_up" % prefix
		Vector2.DOWN:
			return "%s_down" % prefix
		Vector2.LEFT:
			return "%s_left" % prefix
		Vector2.RIGHT:
			return "%s_right" % prefix
		_:
			return "%s_down" % prefix

# ============ 交互 ============

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("inventory"):
		_toggle_inventory()

func _try_interact() -> void:
	# TODO: 实现交互逻辑
	# 发射射线检测可交互对象
	# var space_state = get_world_2d().direct_space_state
	# var query = PhysicsPointQueryParameters2D.new()
	# query.position = global_position + facing_direction * 48
	# var results = space_state.intersect_point(query, 5)
	pass

func _toggle_inventory() -> void:
	# TODO: 切换背包UI
	pass

# ============ 事件处理 ============

func _on_game_state_changed(from: int, to: int) -> void:
	match to:
		GameManager.GameState.PAUSED:
			can_move = false
			_play_idle_animation()
		GameManager.GameState.PLAYING:
			can_move = true
		GameManager.GameState.INVENTORY_OPEN:
			can_move = false

func _on_sleep_triggered(bedtime: int, forced: bool) -> void:
	# 睡眠时玩家不可移动
	can_move = false
	_play_idle_animation()

	# TODO: 播放睡眠动画或过渡效果
	if forced:
		print("[Player] Forced to faint!")
	else:
		print("[Player] Going to sleep at %d:00" % bedtime)

# ============ 公共方法 ============

## 获取玩家位置
func get_position() -> Vector2:
	return global_position

## 设置玩家位置
func set_position(pos: Vector2) -> void:
	global_position = pos

## 恢复玩家移动
func enable_movement() -> void:
	can_move = true

## 禁止玩家移动
func disable_movement() -> void:
	can_move = false
	velocity = Vector2.ZERO
