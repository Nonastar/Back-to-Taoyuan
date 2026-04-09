extends Area2D
class_name FarmPlot

## FarmPlot - 农场地块
## 管理单个地块的状态和作物生长

enum PlotState { WASTELAND, TILLED, PLANTED, GROWING, HARVESTABLE }

const PLOT_SIZE: Vector2 = Vector2(48, 48)

var state: PlotState = PlotState.WASTELAND
@export var grid_position: Vector2i = Vector2i.ZERO
var is_watered: bool = false
var crop_id: String = ""
var growth_days: int = 0
var current_growth: int = 0
var quality: int = 0
var has_weed: bool = false
var has_pest: bool = false

var sprite: Sprite2D
var crop_label: Label
var water_label: Label
var collision: CollisionShape2D

signal plot_state_changed(state: PlotState)
signal crop_planted(crop_id: String, position: Vector2)
signal crop_harvested(crop_id: String, quantity: int, quality: int)
signal plot_clicked(position: Vector2)
signal plot_message(msg: String)  # 用于显示操作提示

# ============ Emoji 配置 ============

## 地块背景颜色
const PLOT_COLORS: Dictionary = {
	PlotState.WASTELAND: Color(0.5, 0.35, 0.2, 1),
	PlotState.TILLED: Color(0.35, 0.25, 0.1, 1),
	PlotState.PLANTED: Color(0.35, 0.25, 0.1, 1),
	PlotState.GROWING: Color(0.35, 0.25, 0.1, 1),
	PlotState.HARVESTABLE: Color(0.4, 0.3, 0.15, 1)
}

## 作物 Emoji 配置
const CROP_EMOJIS: Dictionary = {
	"tomato": {"seed": "🫘", "mature": "🍅"},
	"tomato_seed": {"seed": "🫘", "mature": "🍅"},
	"carrot": {"seed": "🫘", "mature": "🥕"},
	"carrot_seed": {"seed": "🫘", "mature": "🥕"},
	"potato": {"seed": "🥔", "mature": "🥔"},
	"wheat": {"seed": "🌰", "mature": "🌾"},
	"corn": {"seed": "🌰", "mature": "🌽"},
	"onion": {"seed": "🧄", "mature": "🧅"},
	"peanut": {"seed": "🥜", "mature": "🥜"},
	"soybean": {"seed": "🫘", "mature": "🫘"},
	"strawberry": {"seed": "🫘", "mature": "🍓"},
	"pumpkin": {"seed": "🫘", "mature": "🎃"},
	"eggplant": {"seed": "🫘", "mature": "🍆"},
	"pepper": {"seed": "🫘", "mature": "🫑"},
	"cabbage": {"seed": "🫘", "mature": "🥬"}
}

## 生长阶段 Emoji
const STAGE_EMOJIS: Dictionary = {
	"seed": "🌱",
	"sprout": "🌱",
	"flower": "🌼",
	"growing": "🌿",
	"mature": ""
}

## 浇水状态 Emoji
const WATER_EMOJI: String = "💧"

# ============ 初始化 ============

func _ready() -> void:
	_setup_nodes()
	_setup_collision()
	_update_display()

func _setup_nodes() -> void:
	# 地块背景
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.centered = false
	add_child(sprite)

	# 作物 Emoji 标签
	crop_label = Label.new()
	crop_label.name = "CropLabel"
	crop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crop_label.scale = Vector2(2, 2)
	add_child(crop_label)

	# 浇水状态标签
	water_label = Label.new()
	water_label.name = "WaterLabel"
	water_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	water_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	water_label.position = Vector2(24, -12)
	water_label.scale = Vector2(1.5, 1.5)
	add_child(water_label)

func _setup_collision() -> void:
	collision = CollisionShape2D.new()
	collision.name = "Collision"
	collision.position = PLOT_SIZE / 2  # 与 Label 位置对齐
	var shape = RectangleShape2D.new()
	shape.size = PLOT_SIZE
	collision.shape = shape
	add_child(collision)
	input_event.connect(_on_input_event)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			plot_clicked.emit(global_position)

# ============ 交互 ============

func interact(tool_type: int, direction: Vector2) -> bool:
	match tool_type:
		Player.ToolType.HOE:
			return _till()
		Player.ToolType.WATERING_CAN:
			return _water()
		Player.ToolType.SEEDS:
			return _plant()
		Player.ToolType.HAND:
			return _harvest()
	return false

func _till() -> bool:
	if state == PlotState.WASTELAND:
		state = PlotState.TILLED
		_update_display()
		plot_state_changed.emit(state)
		plot_message.emit("耕地完成！")
		return true
	elif state == PlotState.TILLED:
		plot_message.emit("这里已经耕过了")
	elif state == PlotState.PLANTED or state == PlotState.GROWING:
		plot_message.emit("有作物，不能耕地")
	elif state == PlotState.HARVESTABLE:
		plot_message.emit("先收获作物")
	return false

func _water() -> bool:
	if state == PlotState.PLANTED or state == PlotState.GROWING:
		if not is_watered:
			is_watered = true
			_update_display()
			plot_state_changed.emit(state)
			plot_message.emit("浇水完成！💧")
			return true
		else:
			plot_message.emit("已经浇过水了")
	elif state == PlotState.WASTELAND:
		plot_message.emit("先耕地")
	elif state == PlotState.TILLED:
		plot_message.emit("没有作物")
	elif state == PlotState.HARVESTABLE:
		plot_message.emit("可以收获了！")
	return false

func _plant() -> bool:
	if state != PlotState.TILLED:
		if state == PlotState.WASTELAND:
			plot_message.emit("先耕地")
		elif state == PlotState.PLANTED or state == PlotState.GROWING:
			plot_message.emit("已经有作物了")
		elif state == PlotState.HARVESTABLE:
			plot_message.emit("先收获")
		return false

	# 检查种子
	var seed_data = _get_selected_seed()
	if seed_data == null or seed_data["count"] <= 0:
		plot_message.emit("没有种子了！")
		return false

	if InventorySystem.get_item_count(seed_data["id"]) < 1:
		plot_message.emit("没有种子了！")
		return false

	# 消耗种子
	InventorySystem.remove_item(seed_data["id"], 1)

	# 设置作物
	crop_id = seed_data["id"]
	growth_days = seed_data["growth_days"]
	current_growth = 0
	state = PlotState.PLANTED
	quality = seed_data["base_quality"]

	_update_display()
	plot_state_changed.emit(state)
	plot_message.emit("播种成功！🌱")
	return true

func _harvest() -> bool:
	if state == PlotState.HARVESTABLE:
		var quantity = 1
		InventorySystem.add_item(crop_id, quantity, quality)
		crop_harvested.emit(crop_id, quantity, quality)

		# 重置为已耕地
		state = PlotState.TILLED
		crop_id = ""
		current_growth = 0
		is_watered = false
		quality = 0

		_update_display()
		plot_state_changed.emit(state)
		plot_message.emit("收获成功！🌾")
		return true
	elif state == PlotState.WASTELAND:
		plot_message.emit("先耕地")
	elif state == PlotState.TILLED:
		plot_message.emit("先播种")
	elif state == PlotState.PLANTED or state == PlotState.GROWING:
		plot_message.emit("作物还在生长中...")
	return false

func _get_selected_seed() -> Dictionary:
	# 从物品数据系统获取番茄种子
	if ItemDataSystem:
		var seed = ItemDataSystem.get_item_def("tomato_seed")
		if seed:
			var count = InventorySystem.get_item_count("tomato_seed") if InventorySystem else 0
			if count > 0:
				return {
					"id": "tomato_seed",
					"name": "番茄种子",
					"count": count,
					"growth_days": seed.growth_days if seed.growth_days > 0 else 4,
					"base_quality": 0
				}
		# 尝试胡萝卜
		seed = ItemDataSystem.get_item_def("carrot_seed")
		if seed:
			var count = InventorySystem.get_item_count("carrot_seed") if InventorySystem else 0
			if count > 0:
				return {
					"id": "carrot_seed",
					"name": "胡萝卜种子",
					"count": count,
					"growth_days": seed.growth_days if seed.growth_days > 0 else 3,
					"base_quality": 0
				}
	return {"id": "", "name": "", "count": 0, "growth_days": 4, "base_quality": 0}

# ============ 日常处理 ============

func process_day(is_rainy: bool = false) -> void:
	if is_rainy:
		is_watered = true

	if state == PlotState.PLANTED or state == PlotState.GROWING:
		if is_watered:
			current_growth += 1
			state = PlotState.GROWING
			if current_growth >= growth_days:
				state = PlotState.HARVESTABLE

	is_watered = false
	_update_display()

# ============ 显示更新 ============

func _update_display() -> void:
	_update_background()
	_update_crop_emoji()
	_update_water_status()

func _update_background() -> void:
	var color = PLOT_COLORS.get(state, Color(0.5, 0.35, 0.2, 1))
	var tex = _make_color_rect(color, Vector2i(48, 48))
	sprite.texture = tex

func _update_crop_emoji() -> void:
	if state == PlotState.WASTELAND or state == PlotState.TILLED:
		crop_label.text = ""
		return

	var emoji = _get_crop_emoji()
	crop_label.text = emoji

	# 成熟时添加闪烁效果（通过颜色变化）
	if state == PlotState.HARVESTABLE:
		crop_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
	else:
		crop_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _update_water_status() -> void:
	if is_watered:
		water_label.text = WATER_EMOJI
	else:
		water_label.text = ""

func _get_crop_emoji() -> String:
	if crop_id.is_empty():
		return ""

	# 获取作物配置
	var crop_config = CROP_EMOJIS.get(crop_id)
	if crop_config == null:
		# 通用配置
		crop_config = {"seed": "🫘", "mature": "?"}

	if state == PlotState.PLANTED:
		return crop_config.get("seed", "🌱")
	elif state == PlotState.HARVESTABLE:
		return crop_config.get("mature", "🌾")
	else:
		# 生长中 - 根据进度显示不同阶段
		var progress = float(current_growth) / float(growth_days) if growth_days > 0 else 0.0
		if progress < 0.33:
			return "🌱"
		elif progress < 0.66:
			return "🌼"
		else:
			return "🌿"

func _make_color_rect(color: Color, size: Vector2i) -> ImageTexture:
	var img = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var tex = ImageTexture.create_from_image(img)
	return tex

# ============ 调试 ============

func _get_state_name() -> String:
	return PlotState.keys()[state]

func get_display_text() -> String:
	var text = "%s" % _get_state_name()
	if not crop_id.is_empty():
		text += " | %s" % crop_id
		text += " | 生长: %d/%d" % [current_growth, growth_days]
	if is_watered:
		text += " | %s" % WATER_EMOJI
	return text
