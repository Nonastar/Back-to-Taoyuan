extends Area2D
class_name FishingSpot

## FishingSpot - 钓鱼点
## 可交互的钓鱼位置
## 支持点击交互和E键交互

# ============ 常量 ============

## 钓鱼地点ID
@export var location_id: String = "forest_pond"

## 显示名称
@export var display_name: String = "钓鱼点"

## 交互范围
@export var interaction_range: float = 50.0

## Emoji图标
@export var emoji: String = "🎣"

## 位置显示名称
const LOCATION_NAMES: Dictionary = {
	"forest_pond": "森林池塘",
	"river": "河流",
	"mountain_lake": "山顶湖泊",
	"ocean": "海洋",
	"witch_swamp": "女巫沼泽",
	"secret_pond": "秘密池塘"
}

## Emoji映射
const LOCATION_EMOJIS: Dictionary = {
	"forest_pond": "🌲",
	"river": "🏞️",
	"mountain_lake": "🏔️",
	"ocean": "🌊",
	"witch_swamp": "🧙",
	"secret_pond": "✨"
}

# ============ 节点引用 ============

var sprite: Sprite2D
var interaction_hint: Label
var highlight_sprite: Sprite2D

# ============ 状态 ============

var is_highlighted: bool = false

# ============ 初始化 ============

func _ready() -> void:
	_setup_sprite()
	_setup_interaction_hint()
	_setup_collision()
	_connect_signals()

## 设置精灵
func _setup_sprite() -> void:
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.modulate = Color(1, 1, 1, 0.8)
	add_child(sprite)

	# 高亮精灵
	highlight_sprite = Sprite2D.new()
	highlight_sprite.name = "Highlight"
	highlight_sprite.modulate = Color(1, 1, 0, 0.3)
	highlight_sprite.visible = false
	add_child(highlight_sprite)

## 设置交互提示
func _setup_interaction_hint() -> void:
	interaction_hint = Label.new()
	interaction_hint.name = "InteractionHint"
	interaction_hint.text = "%s %s\n按 E 钓鱼" % [LOCATION_EMOJIS.get(location_id, "🎣"), LOCATION_NAMES.get(location_id, display_name)]
	interaction_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_hint.add_theme_font_size_override("font_size", 14)
	interaction_hint.add_theme_color_override("font_color", Color.WHITE)
	interaction_hint.modulate = Color(1, 1, 1, 0)
	interaction_hint.position = Vector2(-80, -60)
	interaction_hint.size = Vector2(160, 50)
	add_child(interaction_hint)

## 连接信号
func _connect_signals() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	# 点击信号（用于点击交互）
	input_event.connect(_on_input_event)

	# 注意：TimeManager 的 enter/exit 由 FishingSystem 自动处理

## 添加碰撞形状
func _setup_collision() -> void:
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	# 使用圆形碰撞
	var circle = CircleShape2D.new()
	circle.radius = interaction_range
	collision.shape = circle
	add_child(collision)

## 点击交互回调
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 检查是否是钓鱼工具或手
			var can_interact = true
			if Player and Player.has_method("get_current_tool"):
				var tool = Player.get_current_tool()
				# 任何工具都可以钓鱼，或者使用手也可以
				can_interact = true  # 钓鱼不消耗工具，直接可用

			if can_interact:
				_try_start_fishing()

# ============ 交互 ============

func _on_mouse_entered() -> void:
	is_highlighted = true
	if highlight_sprite:
		highlight_sprite.visible = true

	# 显示提示
	if interaction_hint:
		var tween = create_tween()
		tween.tween_property(interaction_hint, "modulate:a", 1.0, 0.2)

func _on_mouse_exited() -> void:
	is_highlighted = false
	if highlight_sprite:
		highlight_sprite.visible = false

	# 隐藏提示
	if interaction_hint:
		var tween = create_tween()
		tween.tween_property(interaction_hint, "modulate:a", 0.0, 0.2)

## 尝试开始钓鱼
func _try_start_fishing() -> void:
	# 检查是否已经在钓鱼
	if FishingSystem and FishingSystem.is_fishing():
		_show_message("正在钓鱼中...")
		return

	# 检查体力
	if PlayerStats and PlayerStats.stamina < 2:
		_show_message("体力不足！")
		return

	# 检查是否有鱼可钓
	if FishingSystem:
		var available = FishingSystem.get_available_fish(location_id)
		if available.is_empty():
			_show_message("这里现在没有鱼")
			return

	# 开始钓鱼
	# 注意：TimeManager 的暂停/恢复由 FishingSystem 自动处理
	if FishingSystem:
		FishingSystem.start_fishing(location_id)
		_show_message("开始钓鱼...")
	else:
		_show_message("钓鱼系统未初始化")

## 停止钓鱼
func stop_fishing() -> void:
	if FishingSystem:
		FishingSystem.cancel_fishing()

	# 恢复游戏时间
	if TimeManager:
		TimeManager.exit_minigame()

## 显示消息
func _show_message(msg: String) -> void:
	if EventBus:
		EventBus.notification_show.emit(msg, 2.0)
	push_warning("[FishingSpot] " + str(msg))

# ============ 状态更新 ============

func _process(delta: float) -> void:
	# 浮标动画
	if sprite:
		var bob_offset = sin(Time.get_ticks_msec() / 500.0) * 3
		sprite.position.y = bob_offset
