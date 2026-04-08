extends SceneTree

## TestRunner - 测试运行器
## 运行所有单元测试和集成测试
## 使用方法: godot --path . --script tests/test_runner.gd

# ============ 配置 ============

const UNIT_TEST_DIR = "res://tests/unit/"
const INTEGRATION_TEST_DIR = "res://tests/integration/"
const TEST_PATTERN = "*.test.gd"

# ============ 测试统计 ============

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var current_test: String = ""

# ============ 运行测试 ============

func _init():
	print("========================================")
	print(" 归园田居 - 测试运行器")
	print("========================================")
	print("")

	# 等待autoload初始化
	await get_root().ready

	# 运行单元测试
	print("[单元测试] 开始运行...")
	_run_directory(UNIT_TEST_DIR)
	print("")

	# 运行集成测试
	print("[集成测试] 开始运行...")
	_run_directory(INTEGRATION_TEST_DIR)
	print("")

	# 输出结果
	_print_summary()

	# 退出
	quit()

## 运行目录中的所有测试
func _run_directory(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if dir == null:
		push_warning("[TestRunner] Cannot open directory: " + dir_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".gd"):
			var test_file = dir_path + file_name
			_run_test_file(test_file)
		file_name = dir.get_next()

	dir.list_dir_end()

## 运行单个测试文件
func _run_test_file(file_path: String) -> void:
	print("  运行: " + file_path.get_file())

	# 加载测试脚本
	var test_script = load(file_path)
	if test_script == null:
		push_error("[TestRunner] Failed to load: " + file_path)
		failed_tests += 1
		return

	# 创建测试实例
	var test_instance = test_script.new()
	if test_instance == null:
		push_error("[TestRunner] Failed to instantiate: " + file_path)
		failed_tests += 1
		return

	# 运行setup
	if test_instance.has_method("before_each"):
		test_instance.before_each()

	# 运行所有test_方法
	var methods = test_instance.get_method_list()
	for method in methods:
		if method.name.begins_with("test_"):
			current_test = method.name
			_run_test(test_instance, method.name)

	# 运行teardown
	if test_instance.has_method("after_each"):
		test_instance.after_each()

	test_instance.free()

## 运行单个测试
func _run_test(test_instance, method_name: String) -> void:
	total_tests += 1
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
		print("      ✓ 通过")
	else:
		failed_tests += 1
		print("      ✗ 失败: " + error_message)

## 检查测试结果是否通过
func _is_passed(result) -> bool:
	if result is bool:
		return result
	if result == null:
		return true
	return false

## 输出测试摘要
func _print_summary() -> void:
	var total = passed_tests + failed_tests
	var pct = 0.0
	if total > 0:
		pct = float(passed_tests) / float(total) * 100.0

	print("========================================")
	print(" 测试结果")
	print("========================================")
	print(" 总计:  %d" % total_tests)
	print(" 通过:  %d" % passed_tests)
	print(" 失败:  %d" % failed_tests)
	print(" 通过率: %.1f%%" % pct)
	print("========================================")

	if failed_tests > 0:
		print("")
		push_error("测试失败! 请修复失败的测试。")
	else:
		print("")
		print("所有测试通过!")
