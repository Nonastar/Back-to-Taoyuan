extends SceneTree

## FarmPlot单元测试

var passed: int = 0
var failed: int = 0

func _init():
	print("=== FarmPlot System Tests ===")
	_run_all_tests()
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit()

func _run_all_tests():
	_test_initial_state()
	_test_till()
	_test_till_only_on_wasteland()
	_test_reset()

## 创建带场景的 FarmPlot（触发 _ready）
func _create_plot() -> FarmPlot:
	var plot = FarmPlot.new()
	plot.grid_position = Vector2i(0, 0)
	# 添加到场景以触发 _ready()
	get_root().add_child(plot)
	# 等待 _ready() 完成
	await plot.ready
	return plot

func _test_initial_state():
	var plot = await _create_plot()

	var ok = plot.state == FarmPlot.PlotState.WASTELAND
	_check("初始状态为 WASTELAND", ok)
	_check("未浇水", not plot.is_watered)
	_check("无作物", plot.crop_id == "")

	plot.free()

func _test_till():
	var plot = await _create_plot()

	# 耕地
	var result = plot.interact(0, Vector2.DOWN)  # HOE = 0

	_check("耕地返回成功", result)
	_check("耕地后状态为 TILLED", plot.state == FarmPlot.PlotState.TILLED)

	plot.free()

func _test_till_only_on_wasteland():
	var plot = await _create_plot()

	# 先耕地
	plot.state = FarmPlot.PlotState.WASTELAND
	plot.interact(0, Vector2.DOWN)

	# 再次耕地应失败
	plot.state = FarmPlot.PlotState.TILLED
	var result = plot.interact(0, Vector2.DOWN)

	_check("已耕地再次耕地应失败", result == false)

	plot.free()

func _test_reset():
	var plot = await _create_plot()

	plot.state = FarmPlot.PlotState.HARVESTABLE
	plot.crop_id = "tomato"
	plot.growth_days = 4
	plot.current_growth = 4
	plot.is_watered = true
	plot.quality = 2

	plot._reset()

	_check("重置后状态为 TILLED", plot.state == FarmPlot.PlotState.TILLED)
	_check("重置后无作物", plot.crop_id == "")
	_check("重置后未浇水", not plot.is_watered)

	plot.free()

func _check(test_name: String, condition: bool) -> void:
	if condition:
		print("[PASS] %s" % test_name)
		passed += 1
	else:
		print("[FAIL] %s" % test_name)
		failed += 1
