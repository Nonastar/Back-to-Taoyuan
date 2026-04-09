extends Node

## Player - 全局工具定义
## 提供工具类型枚举供其他脚本使用
## 参考: C04 工具系统 GDD

# ============ 工具类型 (全局枚举) ============

enum ToolType { HOE, WATERING_CAN, SEEDS, HAND }

## 工具名称映射
const TOOL_NAMES: Dictionary = {
	ToolType.HOE: "锄头",
	ToolType.WATERING_CAN: "浇水壶",
	ToolType.SEEDS: "种子",
	ToolType.HAND: "手"
}

## 工具体力消耗
const TOOL_STAMINA_COST: Dictionary = {
	ToolType.HOE: 5.0,
	ToolType.WATERING_CAN: 3.0,
	ToolType.SEEDS: 2.0,
	ToolType.HAND: 1.0
}

# ============ 信号 ============

signal tool_changed(tool_type: ToolType)
signal interaction_attempted(position: Vector2)

# ============ 状态 ============

## 当前工具
var current_tool: ToolType = ToolType.HOE

## 是否正在使用工具
var is_using_tool: bool = false

# ============ 初始化 ============

func _ready() -> void:
	print("[Player] Initialized (Click-to-Interact Mode)")

# ============ 鼠标交互 ============

func _input(event: InputEvent) -> void:
	# 工具切换 (数字键 1-4)
	if event is InputEventKey and event.pressed:
		var key_index = _get_key_tool_index(event.keycode)
		if key_index >= 0:
			_switch_tool(key_index as ToolType)
			return

	# 鼠标点击交互
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)

	# 滚轮切换工具
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_cycle_tool(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_cycle_tool(1)

func _get_key_tool_index(keycode: int) -> int:
	match keycode:
		KEY_1: return 0
		KEY_2: return 1
		KEY_3: return 2
		KEY_4: return 3
	return -1

func _handle_click(screen_pos: Vector2) -> void:
	if is_using_tool:
		return

	is_using_tool = true
	interaction_attempted.emit(screen_pos)

	# 获取世界坐标
	var world_pos = _screen_to_world(screen_pos)

	# 先尝试交互，只有成功时才消耗体力
	var interacted = _try_interact_at(world_pos)

	if interacted:
		# 消耗体力（只有成功交互才消耗）
		var stamina_cost = TOOL_STAMINA_COST.get(current_tool, 0.0)
		if stamina_cost > 0 and PlayerStats:
			var cost_int = int(stamina_cost)
			if not PlayerStats.consume_stamina(cost_int):
				_show_message("体力不足!")
				is_using_tool = false
				return
		print("[Player] Used %s at %s" % [TOOL_NAMES[current_tool], world_pos])
	else:
		# 点击空白处不消耗体力，只显示提示
		var msg = _get_interact_fail_message(world_pos)
		if msg != "":
			_show_message(msg)

	await get_tree().create_timer(0.15).timeout
	is_using_tool = false

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if camera:
		return camera.get_global_mouse_position()
	return screen_pos

func _try_interact_at(world_pos: Vector2) -> bool:
	var plots = _get_plots_at(world_pos)
	for plot in plots:
		if plot.has_method("interact"):
			if plot.interact(current_tool, Vector2.ZERO):
				return true
	return false

func _get_interact_fail_message(world_pos: Vector2) -> String:
	var plots = _get_plots_at(world_pos)
	for plot in plots:
		if plot.has_method("interact"):
			# 尝试调用以获取提示
			match current_tool:
				Player.ToolType.HOE:
					if plot.state == FarmPlot.PlotState.TILLED:
						return "这里已经耕过了"
					elif plot.state == FarmPlot.PlotState.PLANTED or plot.state == FarmPlot.PlotState.GROWING:
						return "有作物，不能耕地"
					elif plot.state == FarmPlot.PlotState.HARVESTABLE:
						return "先收获作物"
				Player.ToolType.WATERING_CAN:
					if plot.state == FarmPlot.PlotState.WASTELAND:
						return "先耕地"
					elif plot.state == FarmPlot.PlotState.TILLED:
						return "没有作物"
					elif plot.is_watered:
						return "已经浇过水了"
				Player.ToolType.SEEDS:
					if plot.state == FarmPlot.PlotState.WASTELAND:
						return "先耕地"
					elif plot.state == FarmPlot.PlotState.PLANTED or plot.state == FarmPlot.PlotState.GROWING:
						return "已经有作物了"
					elif plot.state == FarmPlot.PlotState.HARVESTABLE:
						return "先收获"
					elif InventorySystem.get_item_count("tomato_seed") < 1:
						return "没有种子了！"
				Player.ToolType.HAND:
					if plot.state == FarmPlot.PlotState.WASTELAND:
						return "先耕地"
					elif plot.state == FarmPlot.PlotState.TILLED:
						return "先播种"
					elif plot.state == FarmPlot.PlotState.PLANTED or plot.state == FarmPlot.PlotState.GROWING:
						return "作物还在生长中..."
	return ""

func _get_plots_at(world_pos: Vector2) -> Array:
	var plots: Array = []
	var farm = _find_farm_manager()
	if farm and farm.has_method("get_plots"):
		var all_plots = farm.get_plots()
		for plot in all_plots:
			if plot is Node2D:
				var dist = world_pos.distance_to(plot.global_position)
				if dist < 40:
					plots.append(plot)
	return plots

func _find_farm_manager() -> Node:
	var root = get_tree().root
	if root.has_node("Main/FarmManager"):
		return root.get_node("Main/FarmManager")
	if root.has_node("FarmManager"):
		return root.get_node("FarmManager")
	if root.has_node("Main/FarmLayer/FarmManager"):
		return root.get_node("Main/FarmLayer/FarmManager")
	return null

# ============ 工具系统 ============

func _switch_tool(tool: ToolType) -> void:
	if current_tool != tool:
		current_tool = tool
		tool_changed.emit(tool)
		_show_message("切换到: %s" % TOOL_NAMES[tool])

func _cycle_tool(direction: int) -> void:
	var new_tool = (current_tool + direction) % ToolType.size()
	if new_tool < 0:
		new_tool = ToolType.size() - 1
	_switch_tool(new_tool as ToolType)

func _show_message(msg: String) -> void:
	print("[Player] %s" % msg)

# ============ 公共方法 ============

func get_current_tool() -> ToolType:
	return current_tool

func get_current_tool_name() -> String:
	return TOOL_NAMES.get(current_tool, "Unknown")
