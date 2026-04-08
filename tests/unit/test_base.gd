extends Node

## TestBase - 测试基类
## 提供常用断言方法

# ============ 断言方法 ============

## 断言为真
func assert_true(condition: bool, message: String = "") -> bool:
	if not condition:
		push_error("Assert failed: expected true, got false" + (" - " + message if message else ""))
		return false
	return true

## 断言为假
func assert_false(condition: bool, message: String = "") -> bool:
	if condition:
		push_error("Assert failed: expected false, got true" + (" - " + message if message else ""))
		return false
	return true

## 断言相等
func assert_eq(actual, expected, message: String = "") -> bool:
	if actual != expected:
		push_error("Assert failed: expected %s, got %s" % [str(expected), str(actual)] + (" - " + message if message else ""))
		return false
	return true

## 断言不相等
func assert_ne(actual, not_expected, message: String = "") -> bool:
	if actual == not_expected:
		push_error("Assert failed: expected not %s, but got it" % str(not_expected) + (" - " + message if message else ""))
		return false
	return true

## 断言大于
func assert_gt(actual, expected, message: String = "") -> bool:
	if actual <= expected:
		push_error("Assert failed: expected > %s, got %s" % [str(expected), str(actual)] + (" - " + message if message else ""))
		return false
	return true

## 断言小于
func assert_lt(actual, expected, message: String = "") -> bool:
	if actual >= expected:
		push_error("Assert failed: expected < %s, got %s" % [str(expected), str(actual)] + (" - " + message if message else ""))
		return false
	return true

## 断言大于等于
func assert_ge(actual, expected, message: String = "") -> bool:
	if actual < expected:
		push_error("Assert failed: expected >= %s, got %s" % [str(expected), str(actual)] + (" - " + message if message else ""))
		return false
	return true

## 断言小于等于
func assert_le(actual, expected, message: String = "") -> bool:
	if actual > expected:
		push_error("Assert failed: expected <= %s, got %s" % [str(expected), str(actual)] + (" - " + message if message else ""))
		return false
	return true

## 断言近似相等 (浮点数)
func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> bool:
	var diff = absf(actual - expected)
	if diff > tolerance:
		push_error("Assert failed: expected ~%s (±%s), got %s" % [str(expected), str(tolerance), str(actual)] + (" - " + message if message else ""))
		return false
	return true

## 断言为空
func assert_null(value, message: String = "") -> bool:
	if value != null:
		push_error("Assert failed: expected null, got %s" % str(value) + (" - " + message if message else ""))
		return false
	return true

## 断言非空
func assert_not_null(value, message: String = "") -> bool:
	if value == null:
		push_error("Assert failed: expected not null" + (" - " + message if message else ""))
		return false
	return true

## 断言包含 (数组)
func assert_array_contains(array: Array, value, message: String = "") -> bool:
	if value not in array:
		push_error("Assert failed: array does not contain %s" % str(value) + (" - " + message if message else ""))
		return false
	return true

## 断言字典包含键
func assert_dict_has_key(dict: Dictionary, key, message: String = "") -> bool:
	if not dict.has(key):
		push_error("Assert failed: dict does not have key %s" % str(key) + (" - " + message if message else ""))
		return false
	return true

## 辅助方法: 创建并初始化测试用InventorySystem
func create_test_inventory() -> Node:
	var inv = Node.new()
	inv.set_script(load("res://src/scripts/autoload/inventory_system.gd"))
	return inv
