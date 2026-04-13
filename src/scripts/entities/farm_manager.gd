extends Node2D
class_name FarmManager

## FarmManager - 农场管理器
## 管理农场地块网格，处理日常结算
## 参考: C04 农场地块系统 GDD

# ============ 常量 ============

## 农场尺寸 (格数)
const FARM_WIDTH: int = 6
const FARM_HEIGHT: int = 4

## 地块大小 (像素)
const PLOT_SIZE: int = 48

## 地块间距 (像素)
const PLOT_SPACING: int = 64

## 农场起始偏移 (屏幕中心)
const FARM_OFFSET: Vector2 = Vector2(640, 360)

# ============ 属性 ============

## 地块数组
var plots: Array[FarmPlot] = []

## 农场名称
@export var farm_name: String = "Home Farm"

# ============ 信号 ============

signal day_processed()
signal plot_interacted(plot: FarmPlot, tool: int)
signal plot_message_received(msg: String)
signal farming_exp_changed(skill_type: int, exp: int, leveled_up: bool)

# ============ 初始化 ============

func _ready() -> void:
	_setup_farm()
	_connect_event_signals()
	print("[FarmManager] Initialized with %d plots" % plots.size())

func _setup_farm() -> void:
	# 查找 FarmLayer 节点
	var farm_layer = _get_farm_layer()

	for y in range(FARM_HEIGHT):
		for x in range(FARM_WIDTH):
			var plot = _create_plot(Vector2i(x, y))
			plots.append(plot)

			# 添加到 FarmLayer
			if farm_layer:
				farm_layer.add_child(plot)
			else:
				add_child(plot)

func _get_farm_layer() -> Node:
	# 尝试查找 FarmLayer
	if has_node("../FarmLayer"):
		return get_node("../FarmLayer")
	if has_node("FarmLayer"):
		return get_node("FarmLayer")
	return null

func _create_plot(pos: Vector2i) -> FarmPlot:
	var plot = FarmPlot.new()
	plot.name = "Plot_%d_%d" % [pos.x, pos.y]
	plot.grid_position = pos

	# 设置位置 (使地块居中对齐)
	var total_width = FARM_WIDTH * PLOT_SPACING
	var total_height = FARM_HEIGHT * PLOT_SPACING
	var start_x = FARM_OFFSET.x - total_width / 2 + PLOT_SPACING / 2
	var start_y = FARM_OFFSET.y - total_height / 2 + PLOT_SPACING / 2

	plot.position = Vector2(
		start_x + pos.x * PLOT_SPACING,
		start_y + pos.y * PLOT_SPACING
	)

	# 连接信号
	plot.plot_clicked.connect(_on_plot_clicked)
	plot.crop_planted.connect(_on_crop_planted)
	plot.crop_harvested.connect(_on_crop_harvested)
	plot.plot_message.connect(_on_plot_message)
	plot.farming_exp_changed.connect(_on_farming_exp_changed)

	return plot

func _connect_event_signals() -> void:
	# 连接睡眠/日结算信号
	if EventBus.has_signal("time_sleep_triggered"):
		EventBus.time_sleep_triggered.connect(_on_sleep_triggered)

# ============ 事件处理 ============

func _on_plot_clicked(position: Vector2) -> void:
	# 找到被点击的地块
	for plot in plots:
		if plot.has_method("get_center"):
			var plot_center = plot.get_center()
			if position.distance_to(plot_center) < 30:
				var tool: int = 0
				if has_node("/root/Player"):
					var player_node = get_node("/root/Player")
					if player_node.has_method("get_current_tool"):
						tool = player_node.get_current_tool()
				plot_interacted.emit(plot, tool)
				break

func _on_crop_planted(crop_id: String, position: Vector2) -> void:
	print("[FarmManager] Crop planted: " + str(crop_id))

func _on_crop_harvested(crop_id: String, quantity: int, quality: int) -> void:
	print("[FarmManager] Harvested: %d x %s (quality: %d)" % [quantity, crop_id, quality])

func _on_plot_message(msg: String) -> void:
	# 转发地块消息
	plot_message_received.emit(msg)

func _on_farming_exp_changed(skill_type: int, exp: int, leveled_up: bool) -> void:
	# 转发技能经验变化信号
	farming_exp_changed.emit(skill_type, exp, leveled_up)

func _on_sleep_triggered(bedtime: int, forced: bool) -> void:
	_process_day()

# ============ 公共方法 ============

## 获取所有地块
func get_plots() -> Array:
	return plots

## 获取指定位置的地块
func get_plot_at(grid_pos: Vector2i) -> FarmPlot:
	for plot in plots:
		if plot.grid_position == grid_pos:
			return plot
	return null

## 获取可收获的地块
func get_harvestable_plots() -> Array[FarmPlot]:
	var result: Array[FarmPlot] = []
	for plot in plots:
		if plot.state == FarmPlot.PlotState.HARVESTABLE:
			result.append(plot)
	return result

## 获取需要浇水的地块
func get_needs_water_plots() -> Array[FarmPlot]:
	var result: Array[FarmPlot] = []
	for plot in plots:
		if (plot.state == FarmPlot.PlotState.PLANTED or plot.state == FarmPlot.PlotState.GROWING) and not plot.is_watered:
			result.append(plot)
	return result

## 获取统计信息
func get_stats() -> Dictionary:
	var stats = {
		"total": plots.size(),
		"wasteland": 0,
		"tilled": 0,
		"planted": 0,
		"growing": 0,
		"harvestable": 0,
		"watered": 0
	}

	for plot in plots:
		match plot.state:
			FarmPlot.PlotState.WASTELAND: stats["wasteland"] += 1
			FarmPlot.PlotState.TILLED: stats["tilled"] += 1
			FarmPlot.PlotState.PLANTED: stats["planted"] += 1
			FarmPlot.PlotState.GROWING: stats["growing"] += 1
			FarmPlot.PlotState.HARVESTABLE: stats["harvestable"] += 1
		if plot.is_watered:
			stats["watered"] += 1

	return stats

## 处理一天结束
func _process_day() -> void:
	# 检查是否为雨天（自动浇水日）
	var is_auto_water_day = false
	if WeatherSystem:
		is_auto_water_day = WeatherSystem.is_auto_watering_day()

	for plot in plots:
		plot.process_day(is_auto_water_day)

	# 发送日结算信号
	day_processed.emit()

	if is_auto_water_day:
		print("[FarmManager] Rainy day - crops auto-watered: " + str(get_stats()))
	else:
		print("[FarmManager] Day processed: " + str(get_stats()))

# ============ 存档/加载 ============

func get_save_data() -> Dictionary:
	var plot_data = []
	for plot in plots:
		plot_data.append({
			"grid_pos": {"x": plot.grid_position.x, "y": plot.grid_position.y},
			"state": plot.state,
			"crop_id": plot.crop_id,
			"growth_days": plot.growth_days,
			"current_growth": plot.current_growth,
			"is_watered": plot.is_watered,
			"quality": plot.quality
		})

	return {"farm_name": farm_name, "plots": plot_data}

func load_save_data(data: Dictionary) -> void:
	if not data.has("plots"):
		return

	var plot_dict = {}
	for plot_data in data["plots"]:
		var pos = Vector2i(plot_data["grid_pos"]["x"], plot_data["grid_pos"]["y"])
		plot_dict[pos] = plot_data

	for plot in plots:
		if plot_dict.has(plot.grid_position):
			var d = plot_dict[plot.grid_position]
			plot.state = d["state"]
			plot.crop_id = d["crop_id"]
			plot.growth_days = d["growth_days"]
			plot.current_growth = d["current_growth"]
			plot.is_watered = d["is_watered"]
			plot.quality = d["quality"]
			plot._update_sprite()

	print("[FarmManager] Loaded %d plots" % plot_dict.size())
