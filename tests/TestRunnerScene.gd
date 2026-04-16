extends Node

## TestRunner - 测试运行器（场景版本）
## 运行所有单元测试
## 挂载到测试场景上运行

# ============ 配置 ============

const UNIT_TEST_DIR = "res://tests/unit/"
const INTEGRATION_TEST_DIR = "res://tests/integration/"

# ============ 测试统计 ============

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var current_test: String = ""

# ============ 输出口 ============

@onready var output_label: RichTextLabel = $Panel/ScrollContainer/Output
var _output_text: String = ""
const MAX_OUTPUT_LINES: int = 200  ## 限制输出行数，防止溢出

func _ready() -> void:
	print("========================================")
	print(" 归园田居 - 测试运行器")
	print("========================================")
	_add_output("========================================")
	_add_output(" 归园田居 - 测试运行器")
	_add_output("========================================")
	_add_output("")

	# 短暂延迟确保场景完全加载
	await get_tree().create_timer(0.5).timeout

	# 运行单元测试
	_add_output("[单元测试] 开始运行...")
	print("[单元测试] 开始运行...")
	_run_directory(UNIT_TEST_DIR)
	_add_output("")
	print("")

	# 运行集成测试
	_add_output("[集成测试] 开始运行...")
	print("[集成测试] 开始运行...")
	_run_directory(INTEGRATION_TEST_DIR)
	_add_output("")
	print("")

	# 输出结果
	_print_summary()

	# 更新UI（只更新一次，避免频繁刷新）
	_update_output_display()

func _add_output(text: String) -> void:
	_output_text += text + "\n"
	## 限制行数，防止RichTextLabel溢出
	var lines = _output_text.split("\n", false)
	if lines.size() > MAX_OUTPUT_LINES:
		_output_text = "\n".join(lines.slice(lines.size() - MAX_OUTPUT_LINES, lines.size()))

func _update_output_display() -> void:
	if output_label:
		output_label.text = _output_text

# ============ 运行测试 ============

func _run_directory(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if dir == null:
		var msg = "[TestRunner] Cannot open directory: " + dir_path
		push_warning(msg)
		_add_output(msg)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".gd"):
			var test_file = dir_path + file_name
			_run_test_file(test_file)
		file_name = dir.get_next()

	dir.list_dir_end()

func _run_test_file(file_path: String) -> void:
	var file_name_only = file_path.get_file()
	_add_output("  运行: " + file_name_only)
	print("  运行: " + file_name_only)

	# 加载测试脚本
	var test_script = load(file_path)
	if test_script == null:
		push_error("[TestRunner] Failed to load: " + file_path)
		_add_output("    [错误] 加载失败")
		failed_tests += 1
		return

	# 创建测试实例
	var test_instance = test_script.new()
	if test_instance == null:
		push_error("[TestRunner] Failed to instantiate: " + file_path)
		_add_output("    [错误] 实例化失败")
		failed_tests += 1
		return

	# 运行setup
	if test_instance.has_method("before_each"):
		test_instance.call("before_each")

	# 运行所有test_方法
	var methods = test_instance.get_method_list()
	for method in methods:
		if method.name.begins_with("test_"):
			current_test = method.name
			_run_test(test_instance, method.name)
			# 每个测试后重置状态，保留实例供下一个测试使用
			if test_instance.has_method("_reset_all_state"):
				test_instance.call("_reset_all_state")
			if test_instance.has_method("before_each"):
				test_instance.call("before_each")

	# 运行teardown（最终清理，包括 free）
	if test_instance.has_method("after_each"):
		test_instance.call("after_each")
	else:
		test_instance.free()

func _run_test(test_instance, method_name: String) -> void:
	total_tests += 1
	_add_output("    - " + method_name)
	print("    - " + method_name)

	var passed = false
	var error_message = ""

	# 执行测试
	if test_instance.has_method(method_name):
		# 设置随机种子以便测试可重复
		seed(12345)

		var result = test_instance.call(method_name)
		passed = _is_passed(result)

		if not passed:
			error_message = str(result)
	else:
		passed = false
		error_message = "Method not found"

	if passed:
		passed_tests += 1
		_add_output("      ✓ 通过")
		print("      ✓ 通过")
	else:
		failed_tests += 1
		_add_output("      ✗ 失败: " + error_message)
		print("      ✗ 失败: " + error_message)

func _is_passed(result) -> bool:
	if result is bool:
		return result
	if result == null:
		return true
	return false

func _print_summary() -> void:
	var total = passed_tests + failed_tests
	var pct = 0.0
	if total > 0:
		pct = float(passed_tests) / float(total) * 100.0

	var summary = """
========================================
 测试结果
========================================
 总计:  %d
 通过:  %d
 失败:  %d
 通过率: %.1f%%
========================================""" % [total_tests, passed_tests, failed_tests, pct]

	_add_output(summary)
	print(summary)

	if failed_tests > 0:
		_add_output("")
		_add_output("测试失败! 请修复失败的测试。")
		push_error("测试失败! 请修复失败的测试。")
	else:
		_add_output("")
		_add_output("所有测试通过!")
		print("所有测试通过!")
