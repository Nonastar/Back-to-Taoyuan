// PROTOTYPE - NOT FOR PRODUCTION
// Question: Does the farming core loop feel satisfying?
// Date: 2026-04-08

extends Node2D

# Grid settings
const GRID_SIZE: int = 3
const CELL_SIZE: int = 64

# Game state
var stamina: float = 100.0
var max_stamina: float = 100.0
var day: int = 1
var seeds: Dictionary = {"tomato": 9, "carrot": 0}

# References
var plot_scenes: Array = []
var selected_tool: String = "hoe"  # hoe, seed, watering_can

# UI references
@onready var stamina_bar = $UI/StaminaBar
@onready var day_label = $UI/DayLabel
@onready var tool_label = $UI/ToolLabel
@onready var seed_label = $UI/SeedLabel
@onready var message_label = $UI/MessageLabel

func _ready():
	_setup_grid()
	_update_ui()

func _setup_grid():
	var plots_container = $Plots
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var plot = preload("res://farm_plot.tscn").instantiate()
			plot.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			plot.grid_pos = Vector2i(x, y)
			plot.connect("plot_clicked", _on_plot_clicked)
			plots_container.add_child(plot)
			plot_scenes.append(plot)

func _on_plot_clicked(plot):
	if stamina < 5:
		_show_message("体力不足!")
		return

	match selected_tool:
		"hoe":
			if plot.state == "wasteland":
				plot.set_state("tilled")
				_consume_stamina(5)
				_show_message("耕地完成!")
			elif plot.state == "tilled":
				_show_message("已经耕地了")
			else:
				_show_message("需要先收获")
		"seed":
			if plot.state == "tilled" and seeds.get("tomato", 0) > 0:
				plot.plant("tomato", 4)  # 4 days to grow
				seeds["tomato"] -= 1
				_consume_stamina(3)
				_show_message("播种番茄!")
			elif plot.state == "tilled":
				_show_message("没有种子了")
			elif plot.state == "wasteland":
				_show_message("需要先耕地")
			else:
				_show_message("这里已经有作物了")
		"watering_can":
			if plot.state in ["planted", "growing"]:
				if not plot.watered:
					plot.water()
					_consume_stamina(3)
					_show_message("浇水完成!")
				else:
					_show_message("已经浇过水了")
			elif plot.state == "harvestable":
				_show_message("可以收获了!")
			else:
				_show_message("这里没有作物")

	_update_ui()

func _consume_stamina(amount: float):
	stamina = max(0, stamina - amount)
	if stamina < 5:
		_show_message("体力过低! 请休息")

func _update_ui():
	if stamina_bar:
		stamina_bar.value = stamina
		stamina_bar.max_value = max_stamina
	if day_label:
		day_label.text = "第 %d 天" % day
	if tool_label:
		var tool_names = {"hoe": "锄头", "seed": "种子", "watering_can": "浇水壶"}
		tool_label.text = "工具: %s" % tool_names.get(selected_tool, selected_tool)
	if seed_label:
		seed_label.text = "番茄种子: %d" % seeds.get("tomato", 0)

func _show_message(text: String):
	if message_label:
		message_label.text = text
		message_label.visible = true
		await get_tree().create_timer(1.5).timeout
		message_label.visible = false

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				selected_tool = "hoe"
				_update_ui()
			KEY_2:
				selected_tool = "seed"
				_update_ui()
			KEY_3:
				selected_tool = "watering_can"
				_update_ui()
			KEY_SPACE:
				_advance_day()
			KEY_R:
				_reset_game()

func _advance_day():
	day += 1
	_show_message("时间流逝... 第 %d 天" % day)

	# Process all plots
	for plot in plot_scenes:
		plot.process_day()

	# Restore stamina
	stamina = max_stamina
	_update_ui()

func _reset_game():
	stamina = max_stamina
	day = 1
	seeds = {"tomato": 9, "carrot": 0}
	selected_tool = "hoe"

	for plot in plot_scenes:
		plot.reset()

	_update_ui()
	_show_message("游戏已重置")
