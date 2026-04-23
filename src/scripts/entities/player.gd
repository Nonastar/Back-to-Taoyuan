extends Node

## Player - 全局工具定义
## 提供工具类型枚举供其他脚本使用
## 参考: C04 工具系统 GDD

# ============ 工具类型 (全局枚举) ============

enum ToolType { HOE, WATERING_CAN, SEEDS, HAND, FERTILIZER }

## 工具名称映射
const TOOL_NAMES: Dictionary = {
	ToolType.HOE: "锄头",
	ToolType.WATERING_CAN: "浇水壶",
	ToolType.SEEDS: "种子",
	ToolType.HAND: "手",
	ToolType.FERTILIZER: "肥料"
}

## 工具体力消耗
const TOOL_STAMINA_COST: Dictionary = {
	ToolType.HOE: 5.0,
	ToolType.WATERING_CAN: 3.0,
	ToolType.SEEDS: 2.0,
	ToolType.HAND: 1.0,
	ToolType.FERTILIZER: 2.0
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
			# UI 面板打开时，阻止点击穿透到游戏世界
			if _is_ui_open():
				return
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
		KEY_5: return 4
	return -1

func _handle_click(screen_pos: Vector2) -> void:
	if is_using_tool:
		return

	is_using_tool = true
	interaction_attempted.emit(screen_pos)

	# 获取世界坐标
	var world_pos = _screen_to_world(screen_pos)

	# 先检查体力是否足够
	var stamina_cost = TOOL_STAMINA_COST.get(current_tool, 0.0)
	var final_cost: int = 0
	var weather_modifier: float = 1.0

	if stamina_cost > 0 and PlayerStats:
		# 应用天气修正
		weather_modifier = _get_weather_stamina_modifier()
		final_cost = max(1, int(stamina_cost * weather_modifier))

		if not PlayerStats.consume_stamina(final_cost):
			_show_message("体力不足!")
			is_using_tool = false
			return

		# 如果天气有惩罚，显示提示
		if weather_modifier > 1.0:
			var weather_msg = _get_weather_stamina_penalty_message()
			_show_message(weather_msg)

	# 体力足够，执行交互
	var interacted = _try_interact_at(world_pos)

	if interacted:
		print("[Player] Used %s at %s" % [TOOL_NAMES[current_tool], world_pos])
	else:
		# 交互失败，返还体力
		if stamina_cost > 0 and final_cost > 0 and PlayerStats and PlayerStats.has_method("restore_stamina"):
			PlayerStats.restore_stamina(final_cost)
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
			# 保存交互前的状态
			var original_state = plot.state
			# 执行交互
			var success = plot.interact(current_tool, Vector2.ZERO)
			# 确定动作类型
			var action = _get_action_name(current_tool)
			# 发出全局信号
			if EventBus.has_signal("farm_interaction_result"):
				EventBus.farm_interaction_result.emit(
					plot.name,
					current_tool,
					action,
					success,
					original_state
				)
			if success:
				return true
	return false

## 根据工具获取动作名称
func _get_action_name(tool: ToolType) -> String:
	match tool:
		ToolType.HOE: return "till"
		ToolType.WATERING_CAN: return "water"
		ToolType.SEEDS: return "plant"
		ToolType.HAND: return "harvest"
		ToolType.FERTILIZER: return "fertilize"
	return "unknown"

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
	if farm == null:
		return plots
	if farm and farm.has_method("get_plots"):
		var all_plots = farm.get_plots()
		for plot in all_plots:
			if plot.has_method("get_center"):
				# 使用地块接口获取中心点
				var plot_center = plot.get_center()
				var dist = world_pos.distance_to(plot_center)
				if dist < 30:
					plots.append(plot)
	return plots

## 获取天气体力消耗修正
func _get_weather_stamina_modifier() -> float:
	if WeatherSystem:
		return WeatherSystem.get_stamina_modifier()
	return 1.0

## 获取天气体力惩罚提示消息
func _get_weather_stamina_penalty_message() -> String:
	if WeatherSystem:
		var weather = WeatherSystem.get_today_weather()
		match weather:
			WeatherSystem.WEATHER_RAINY:
				return "雨天体力消耗增加 🌧️"
			WeatherSystem.WEATHER_STORMY:
				return "暴风雨中体力消耗增加 ⛈️"
			WeatherSystem.WEATHER_SNOWY:
				return "雪天体力消耗增加 ❄️"
			WeatherSystem.WEATHER_GREEN_RAIN:
				return "绿雨体力消耗增加 🌱"
			WeatherSystem.WEATHER_WINDY:
				return "大风体力消耗增加 💨"
	return "天气恶劣，体力消耗增加"

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
	## 边界检查：确保工具索引在有效范围内
	if tool < 0 or tool >= ToolType.size():
		print("[Player] Invalid tool type: " + str(tool))
		return

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
	if NotificationManager:
		NotificationManager.show_info(msg)
	print("[Player] " + str(msg))

# ============ 公共方法 ============

func get_current_tool() -> ToolType:
	return current_tool

func get_current_tool_name() -> String:
	return TOOL_NAMES.get(current_tool, "Unknown")

## 公开的工具切换方法（供外部调用，如 HUD）
func switch_tool(tool: ToolType) -> void:
	_switch_tool(tool)

## 检查是否有 UI 面板打开（阻止点击穿透到游戏世界）
func _is_ui_open() -> bool:
	var root = get_tree().root
	var hud = root.get_node_or_null("Main/HUD")
	if hud:
		for child in hud.get_children():
			# 只拦截真正的交互面板节点，不拦截装饰性或常驻信息面板
			if child is Control and child.visible and child.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				var name = child.name
				# 排除常驻 HUD 元素（位置信息、技能面板、装饰背景等）
				if name == "TopBarBG" or name == "HotbarBG" or name == "TopBar" or name == "Hotbar" or name == "QuickButtons" or name == "LocationInfo" or name == "SkillPanel" or name == "Notification":
					continue
				print("[Player] _is_ui_open=true blocked by child=%s" % name)
				return true
	return false
