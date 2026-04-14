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
var consecutive_unwatered_days: int = 0  # 连续未浇水天数

# ============ 洒水器相关 ============
var has_sprinkler: bool = false  # 是否有洒水器
var sprinkler_type: String = "basic"  # 洒水器类型: basic, quality, premium

# ============ 肥料相关 ============
var fertilizer_type: String = ""  # 当前肥料类型: basic, quality, growth, moisture
var fertilizer_quality_bonus: int = 0  # 肥料品质加成
var fertilizer_growth_bonus: float = 0.0  # 肥料生长加速 (0.0-1.0)
var moisture_preserved: bool = false  # 保湿土是否保留浇水状态

var sprite: Sprite2D
var crop_label: Label
var water_label: Label
var fertilizer_label: Label  # 肥料状态标签
var collision: CollisionShape2D

signal plot_state_changed(state: PlotState)
signal crop_planted(crop_id: String, position: Vector2)
signal crop_harvested(crop_id: String, quantity: int, quality: int)
signal plot_clicked(position: Vector2)
signal plot_message(msg: String)  # 用于显示操作提示
signal farming_exp_changed(skill_type: int, exp: int, leveled_up: bool)  # 技能经验变化

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

## 肥料状态 Emoji
const FERTILIZER_EMOJIS: Dictionary = {
	"": "",
	"basic": "🌿",
	"quality": "⭐",
	"growth": "⚡",
	"moisture": "💧"
}

## 肥料效果配置
## 品质加成: 收获时额外增加品质等级
## 生长加速: 减少所需生长天数 (百分比)
## 保湿保留: 是否概率保留浇水状态
const FERTILIZER_EFFECTS: Dictionary = {
	"basic": {"quality_bonus": 1, "growth_bonus": 0.0, "moisture_preserve": 0.0},
	"quality": {"quality_bonus": 2, "growth_bonus": 0.0, "moisture_preserve": 0.0},
	"growth": {"quality_bonus": 0, "growth_bonus": 0.10, "moisture_preserve": 0.0},
	"moisture": {"quality_bonus": 0, "growth_bonus": 0.0, "moisture_preserve": 0.5}
}

# ============ 初始化 ============

func _ready() -> void:
	_setup_nodes()
	_setup_collision()
	_update_display()

func _setup_nodes() -> void:
	# 地块背景 - 检查场景中是否已有
	if not has_node("Sprite"):
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		sprite.centered = false
		add_child(sprite)
	else:
		sprite = get_node("Sprite")

	# 作物 Emoji 标签 - 检查场景中是否已有
	if not has_node("CropLabel"):
		crop_label = Label.new()
		crop_label.name = "CropLabel"
		crop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		crop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		crop_label.scale = Vector2(2, 2)
		add_child(crop_label)
	else:
		crop_label = get_node("CropLabel")

	# 浇水状态标签 - 检查场景中是否已有
	if not has_node("WaterLabel"):
		water_label = Label.new()
		water_label.name = "WaterLabel"
		water_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		water_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		water_label.position = Vector2(24, -12)
		water_label.scale = Vector2(1.5, 1.5)
		add_child(water_label)
	else:
		water_label = get_node("WaterLabel")

	# 肥料状态标签 - 检查场景中是否已有
	if not has_node("FertilizerLabel"):
		fertilizer_label = Label.new()
		fertilizer_label.name = "FertilizerLabel"
		fertilizer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fertilizer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fertilizer_label.position = Vector2(-16, -12)
		fertilizer_label.scale = Vector2(1.5, 1.5)
		add_child(fertilizer_label)
	else:
		fertilizer_label = get_node("FertilizerLabel")
	# 初始化时清空肥料标签
	fertilizer_label.text = ""

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
		Player.ToolType.FERTILIZER:
			return _apply_fertilizer()
	return false

func _till() -> bool:
	if state == PlotState.WASTELAND:
		state = PlotState.TILLED
		consecutive_unwatered_days = 0  # 重置计数器
		_update_display()
		plot_state_changed.emit(state)
		_send_message("耕地完成！")
		return true
	elif state == PlotState.TILLED:
		_send_message("这里已经耕过了")
	elif state == PlotState.PLANTED or state == PlotState.GROWING:
		_send_message("有作物，不能耕地")
	elif state == PlotState.HARVESTABLE:
		_send_message("先收获作物")
	return false

func _water() -> bool:
	if state == PlotState.PLANTED or state == PlotState.GROWING:
		if not is_watered:
			is_watered = true
			_update_display()
			plot_state_changed.emit(state)
			_send_message("浇水完成！💧")
			return true
		else:
			_send_message("已经浇过水了")
	elif state == PlotState.WASTELAND:
		_send_message("先耕地")
	elif state == PlotState.TILLED:
		_send_message("没有作物")
	elif state == PlotState.HARVESTABLE:
		_send_message("可以收获了！")
	return false

func _plant() -> bool:
	if state != PlotState.TILLED:
		if state == PlotState.WASTELAND:
			_send_message("先耕地")
		elif state == PlotState.PLANTED or state == PlotState.GROWING:
			_send_message("已经有作物了")
		elif state == PlotState.HARVESTABLE:
			_send_message("先收获")
		return false

	# 检查种子
	var seed_data = _get_selected_seed()
	if seed_data == null or seed_data["count"] <= 0:
		_send_message("没有种子了！")
		return false

	if InventorySystem.get_item_count(seed_data["id"]) < 1:
		_send_message("没有种子了！")
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
	_send_message("播种成功！🌱")
	return true

func _harvest() -> bool:
	if state == PlotState.HARVESTABLE:
		# 根据农耕技能等级计算品质加成
		var final_quality = _calculate_harvest_quality()

		# 添加物品到背包
		var quantity = 1
		InventorySystem.add_item(crop_id, quantity, final_quality)

		# 给予农耕经验
		_add_farming_exp()

		# 发送收获信号
		crop_harvested.emit(crop_id, quantity, final_quality)

		# 重置为已耕地
		state = PlotState.TILLED
		crop_id = ""
		current_growth = 0
		is_watered = false
		consecutive_unwatered_days = 0  # 重置计数器
		quality = 0

		_update_display()
		plot_state_changed.emit(state)
		_send_message("收获成功！🌾 (品质: %s)" % _get_quality_name(final_quality))
		return true
	elif state == PlotState.WASTELAND:
		_send_message("先耕地")
	elif state == PlotState.TILLED:
		_send_message("先播种")
	elif state == PlotState.PLANTED or state == PlotState.GROWING:
		_send_message("作物还在生长中...")
	return false

## 计算收获品质
func _calculate_harvest_quality() -> int:
	var base_quality = 0  # 普通品质

	# 获取农耕技能加成
	if SkillSystem:
		var farming_level = SkillSystem.get_level(SkillSystem.SkillType.FARMING)
		var quality_bonus = SkillSystem.get_farming_quality_bonus()
		var rng = RandomNumberGenerator.new()
		var roll = rng.randf()

		# 9级+: 5% 概率出 Supreme (简化版)
		if farming_level >= 9 and roll < 0.05 + quality_bonus * 0.5:
			base_quality = 3  # Supreme
		# 6级+: 15% 概率出 Excellent
		elif farming_level >= 6 and roll < 0.15 + quality_bonus:
			base_quality = 2  # Excellent
		# 3级+: 30% 概率出 Fine
		elif farming_level >= 3 and roll < 0.30 + quality_bonus:
			base_quality = 1  # Fine

	# 肥料品质加成 (叠加到技能判定上)
	base_quality += fertilizer_quality_bonus
	base_quality = clamp(base_quality, 0, 3)  # 最高史诗

	return base_quality

## 获取品质名称
func _get_quality_name(q: int) -> String:
	match q:
		0: return "普通"
		1: return "优秀"
		2: return "精良"
		3: return "史诗"
		_: return "普通"

## 添加农耕经验
func _add_farming_exp() -> void:
	if SkillSystem:
		var base_exp = 15  # 每次收获获得15点经验
		var result = SkillSystem.add_exp(SkillSystem.SkillType.FARMING, base_exp)

		# 发送技能经验变化信号
		var current_exp = SkillSystem.get_exp(SkillSystem.SkillType.FARMING)

		# 通过 EventBus 发送
		if EventBus.has_signal("farming_exp_changed"):
			EventBus.farming_exp_changed.emit(SkillSystem.SkillType.FARMING, current_exp, result["leveled_up"])

		if result["leveled_up"]:
			_send_message("🌾 农耕升级！Lv.%d" % result["new_level"])

## 施肥操作
func _apply_fertilizer() -> bool:
	# 只有已耕地块才能施肥
	if state != PlotState.TILLED:
		if state == PlotState.WASTELAND:
			_send_message("先耕地")
		elif state == PlotState.PLANTED or state == PlotState.GROWING:
			_send_message("已有作物，不能施肥")
		elif state == PlotState.HARVESTABLE:
			_send_message("先收获再施肥")
		return false

	# 检查是否有可用的肥料
	var fert_data = _get_selected_fertilizer()
	if fert_data.is_empty():
		_send_message("没有肥料了！")
		return false

	var fert_id = fert_data.get("id", "")
	if InventorySystem.get_item_count(fert_id) < 1:
		_send_message("没有肥料了！")
		return false

	# 检查是否已有相同类型肥料
	if fertilizer_type == fert_data["type"]:
		_send_message("这块地已经施过 %s 了" % fert_data["name"])
		return false

	# 消耗肥料
	InventorySystem.remove_item(fert_id, 1)

	# 应用肥料效果
	fertilizer_type = fert_data["type"]
	fertilizer_quality_bonus = fert_data["quality_bonus"]
	fertilizer_growth_bonus = fert_data["growth_bonus"]
	moisture_preserved = fert_data["moisture_preserve"] > 0.0

	_update_display()
	_send_message("施肥成功！%s 🌱" % fert_data["name"])
	return true

## 获取选中的肥料
func _get_selected_fertilizer() -> Dictionary:
	# 优先使用背包中的肥料
	var basic_count = InventorySystem.get_item_count("basic_fertilizer") if InventorySystem else 0
	var quality_count = InventorySystem.get_item_count("quality_fertilizer") if InventorySystem else 0
	var growth_count = InventorySystem.get_item_count("growth_fertilizer") if InventorySystem else 0
	var moisture_count = InventorySystem.get_item_count("moisture_fertilizer") if InventorySystem else 0

	if basic_count > 0:
		var effect = FERTILIZER_EFFECTS.get("basic", {})
		return {
			"id": "basic_fertilizer",
			"name": "基础肥料",
			"type": "basic",
			"quality_bonus": effect.get("quality_bonus", 0),
			"growth_bonus": effect.get("growth_bonus", 0.0),
			"moisture_preserve": effect.get("moisture_preserve", 0.0)
		}
	if quality_count > 0:
		var effect = FERTILIZER_EFFECTS.get("quality", {})
		return {
			"id": "quality_fertilizer",
			"name": "优质肥料",
			"type": "quality",
			"quality_bonus": effect.get("quality_bonus", 0),
			"growth_bonus": effect.get("growth_bonus", 0.0),
			"moisture_preserve": effect.get("moisture_preserve", 0.0)
		}
	if growth_count > 0:
		var effect = FERTILIZER_EFFECTS.get("growth", {})
		return {
			"id": "growth_fertilizer",
			"name": "生长激素",
			"type": "growth",
			"quality_bonus": effect.get("quality_bonus", 0),
			"growth_bonus": effect.get("growth_bonus", 0.0),
			"moisture_preserve": effect.get("moisture_preserve", 0.0)
		}
	if moisture_count > 0:
		var effect = FERTILIZER_EFFECTS.get("moisture", {})
		return {
			"id": "moisture_fertilizer",
			"name": "保湿土",
			"type": "moisture",
			"quality_bonus": effect.get("quality_bonus", 0),
			"growth_bonus": effect.get("growth_bonus", 0.0),
			"moisture_preserve": effect.get("moisture_preserve", 0.0)
		}
	return {}

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
	# 保湿土效果：昨天浇过水，今天有概率保留浇水状态
	var moisture_kept = false
	if moisture_preserved and _moisture_restore_chance() > randf():
		moisture_kept = true

	# 处理洒水器自动浇水
	if has_sprinkler:
		is_watered = true
		consecutive_unwatered_days = 0

	if is_rainy:
		is_watered = true
		consecutive_unwatered_days = 0  # 雨天浇水，重置计数器

	if state == PlotState.PLANTED or state == PlotState.GROWING:
		if is_watered or moisture_kept:
			# 计算有效生长天数（应用肥料生长加速）
			var effective_growth = 1
			if fertilizer_growth_bonus > 0.0:
				effective_growth = 1 + int(fertilizer_growth_bonus)
			current_growth += effective_growth
			state = PlotState.GROWING
			consecutive_unwatered_days = 0  # 重置计数器
			if current_growth >= growth_days:
				state = PlotState.HARVESTABLE

			# 保湿土生效时显示提示
			if moisture_kept and not is_watered:
				_send_message("保湿土保留了昨日水分！")
		else:
			consecutive_unwatered_days += 1
			if consecutive_unwatered_days >= 2:
				_wither_crop()
				return  # 枯萎后直接返回

	is_watered = false
	_update_display()

	# 如果是雨天，自动显示提示
	if is_rainy and (state == PlotState.PLANTED or state == PlotState.GROWING):
		_send_message("雨天自动浇水！🌧️")

## 保湿土保留浇水的概率判定
func _moisture_restore_chance() -> float:
	# 基础50%概率保留浇水状态
	# 可以根据肥料类型调整，这里使用配置中的值
	if fertilizer_type == "moisture":
		return 0.5  # 保湿土50%概率
	return 0.0

## 作物枯萎处理
func _wither_crop() -> void:
	state = PlotState.TILLED
	crop_id = ""
	current_growth = 0
	consecutive_unwatered_days = 0
	is_watered = false
	_update_display()
	plot_state_changed.emit(state)
	_send_message("作物枯萎了！需要重新播种...")

# ============ 显示更新 ============

func _update_display() -> void:
	_update_background()
	_update_crop_emoji()
	_update_water_status()
	_update_fertilizer_status()

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

func _update_fertilizer_status() -> void:
	if fertilizer_label == null:
		return
	var emoji = FERTILIZER_EMOJIS.get(fertilizer_type, "")
	fertilizer_label.text = emoji
	# 如果有肥料，给标签添加特殊颜色
	if not fertilizer_type.is_empty():
		fertilizer_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3, 1))  # 绿色
	else:
		fertilizer_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

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

# ============ 公共方法 ============

## 获取地块中心点（用于点击检测）
func get_center() -> Vector2:
	return global_position + PLOT_SIZE / 2

## 获取地块大小
func get_size() -> Vector2:
	return PLOT_SIZE

## 发送消息（同时通过本地信号和 EventBus）
func _send_message(msg: String) -> void:
	plot_message.emit(msg)
	if EventBus and EventBus.has_signal("farm_message"):
		EventBus.farm_message.emit(msg)

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
	if not fertilizer_type.is_empty():
		var fert_emoji = FERTILIZER_EMOJIS.get(fertilizer_type, "")
		text += " | %s" % fert_emoji
	return text
