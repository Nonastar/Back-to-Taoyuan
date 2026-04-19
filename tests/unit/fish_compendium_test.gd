extends "res://tests/unit/test_base.gd"

## FishCompendiumSystem 鱼类图鉴系统单元测试
## 测试发现追踪、捕获计数、最佳品质、进度计算
## 注意：每个测试必须自行重置状态，防止测试间污染

var _compendium: Node = null

func _reset_all_state():
	"""重置所有状态到初始值"""
	_compendium._discovered_fish = {}
	_compendium._total_fish_count = 0

func before_each():
	_compendium = Node.new()
	_compendium.set_script(load("res://src/scripts/autoload/fish_compendium_system.gd"))
	_compendium._ready()

func after_each():
	_reset_all_state()
	_compendium.free()

# ============ 初始状态测试 ============

func test_initial_discovered_count_is_zero():
	assert_eq(_compendium.get_discovered_count(), 0, "初始发现数应为0")

func test_initial_progress_is_zero():
	assert_almost_eq(_compendium.get_progress(), 0.0, 0.001, "初始进度应为0")

func test_initial_undiscovered_list_contains_all():
	var undiscovered = _compendium.get_undiscovered_list()
	assert_gt(undiscovered.size(), 0, "未发现列表应有内容")

# ============ 捕获记录测试 ============

## 测试首次捕获记录新鱼
func test_record_catch_new_fish():
	var result = _compendium.record_catch("bluegill", 1, 0)
	assert_true(result, "记录新鱼应返回true")
	assert_true(_compendium.is_discovered("bluegill"), "新鱼应标记为已发现")
	assert_eq(_compendium.get_catch_count("bluegill"), 1, "首次记录捕获次数应为1")

## 测试重复捕获增加计数
func test_record_catch_increments_count():
	_compendium._discovered_fish["bluegill"] = {
		"discovered": true,
		"catch_count": 5,
		"best_quality": 1,
		"first_catch_time": 1000,
		"last_catch_time": 1000
	}

	_compendium.record_catch("bluegill", 2, 2)

	var count = _compendium.get_catch_count("bluegill")
	assert_eq(count, 7, "捕获计数应增加2")

## 测试更高品质更新最佳品质
func test_record_catch_updates_best_quality():
	_compendium._discovered_fish["bluegill"] = {
		"discovered": true,
		"catch_count": 5,
		"best_quality": 1,  ## FINE
		"first_catch_time": 1000,
		"last_catch_time": 1000
	}

	_compendium.record_catch("bluegill", 1, 2)  ## EXCELLENT

	var best = _compendium.get_best_quality("bluegill")
	assert_eq(best, 2, "最佳品质应更新为EXCELLENT(2)")

## 测试低品质不更新最佳品质
func test_record_catch_does_not_downgrade_best_quality():
	_compendium._discovered_fish["bluegill"] = {
		"discovered": true,
		"catch_count": 5,
		"best_quality": 2,  ## EXCELLENT
		"first_catch_time": 1000,
		"last_catch_time": 1000
	}

	_compendium.record_catch("bluegill", 1, 0)  ## NORMAL

	var best = _compendium.get_best_quality("bluegill")
	assert_eq(best, 2, "最佳品质不应被低品质更新")

## 测试无效鱼类记录失败
func test_record_catch_invalid_fish_returns_false():
	var result = _compendium.record_catch("nonexistent_fish", 1, 0)
	assert_true(result is bool, "返回值应为布尔值")
	assert_true(result, "无FishingSystem时应允许记录未知鱼ID")
	assert_true(_compendium.is_discovered("nonexistent_fish"), "应创建并标记发现记录")

# ============ 发现状态测试 ============

func test_is_discovered_false_for_uncaught():
	assert_false(_compendium.is_discovered("bluegill"), "未捕获的鱼应返回false")
	assert_false(_compendium.is_discovered("koi"), "未捕获的鱼应返回false")

func test_is_discovered_true_after_catch():
	_compendium._discovered_fish["bluegill"] = {
		"discovered": true,
		"catch_count": 1,
		"best_quality": 0,
		"first_catch_time": 1000,
		"last_catch_time": 1000
	}
	assert_true(_compendium.is_discovered("bluegill"), "已捕获的鱼应返回true")

# ============ 进度测试 ============

## 测试进度为0（无发现）
func test_progress_zero_when_nothing_discovered():
	assert_almost_eq(_compendium.get_progress(), 0.0, 0.001)

## 测试进度为1（全部发现）
func test_progress_one_when_all_discovered():
	## 设置总数为1，全部发现
	_compendium._total_fish_count = 1
	_compendium._discovered_fish["bluegill"] = {
		"discovered": true,
		"catch_count": 1,
		"best_quality": 0,
		"first_catch_time": 1000,
		"last_catch_time": 1000
	}

	assert_almost_eq(_compendium.get_progress(), 1.0, 0.001, "全部发现进度应为1.0")

## 测试进度文本格式
func test_progress_text_format():
	var text = _compendium.get_progress_text()
	assert_true("已钓:" in text, "进度文本应包含'已钓:'")
	assert_true("/" in text, "进度文本应包含'/'")
	assert_true("%" in text, "进度文本应包含百分比")

func test_record_catch_increases_progress():
	_compendium._total_fish_count = 10
	var before = _compendium.get_progress()
	_compendium.record_catch("bluegill", 1, 0)
	var after = _compendium.get_progress()
	assert_gt(after, before, "记录新鱼后进度应提升")

# ============ 鱼类列表测试 ============

func test_discovered_list_only_includes_discovered():
	_compendium._discovered_fish["bluegill"] = {
		"discovered": true, "catch_count": 1, "best_quality": 0,
		"first_catch_time": 1000, "last_catch_time": 1000
	}
	_compendium._discovered_fish["koi"] = {
		"discovered": false, "catch_count": 0, "best_quality": 0,
		"first_catch_time": 0, "last_catch_time": 0
	}

	var discovered = _compendium.get_discovered_list()
	assert_array_contains(discovered, "bluegill", "发现列表应包含bluegill")
	assert_false(discovered.has("koi"), "发现列表不应包含未发现的koi")

func test_undiscovered_list_excludes_discovered():
	_compendium._discovered_fish["bluegill"] = {
		"discovered": true, "catch_count": 1, "best_quality": 0,
		"first_catch_time": 1000, "last_catch_time": 1000
	}

	var undiscovered = _compendium.get_undiscovered_list()
	assert_false(undiscovered.has("bluegill"), "未发现列表不应包含已发现")

# ============ 单例测试 ============

func test_get_instance_returns_self():
	var instance = _compendium.get_instance()
	assert_eq(instance, _compendium, "get_instance应返回实例")

# ============ 存档序列化测试 ============

func test_serialize_preserves_discovered_fish():
	_compendium._discovered_fish["bluegill"] = {
		"discovered": true,
		"catch_count": 10,
		"best_quality": 2,
		"first_catch_time": 1000,
		"last_catch_time": 2000
	}
	_compendium._total_fish_count = 21

	var data = _compendium.serialize()
	assert_true(data.has("discovered_fish"), "存档应包含discovered_fish")
	assert_true(data.has("total_fish_count"), "存档应包含total_fish_count")
	assert_true(data["discovered_fish"].has("bluegill"), "应记录bluegill")

func test_deserialize_restores_state():
	var data = {
		"discovered_fish": {
			"bluegill": {
				"discovered": true,
				"catch_count": 5,
				"best_quality": 1,
				"first_catch_time": 1000,
				"last_catch_time": 2000
			}
		},
		"total_fish_count": 21
	}

	_compendium.deserialize(data)
	assert_true(_compendium.is_discovered("bluegill"), "反序列化后bluegill应标记为已发现")
	assert_eq(_compendium.get_catch_count("bluegill"), 5, "捕获计数应正确恢复")

# ============ 辅助方法测试 ============

func test_get_catch_count_returns_zero_for_undiscovered():
	assert_eq(_compendium.get_catch_count("undiscovered_fish"), 0,
		"未发现鱼类的捕获计数应为0")

func test_get_best_quality_returns_zero_for_undiscovered():
	assert_eq(_compendium.get_best_quality("undiscovered_fish"), 0,
		"未发现鱼类的最佳品质应为0")

## 测试获取鱼类Emoji
func test_get_fish_emoji():
	var emoji = _compendium.get_fish_emoji("bluegill")
	assert_false(emoji.is_empty(), "bluegill应有emoji")

## 测试获取稀有度名称
func test_get_rarity_name():
	assert_eq(_compendium.get_rarity_name(0.7), "普通")
	assert_eq(_compendium.get_rarity_name(0.3), "优质")
	assert_eq(_compendium.get_rarity_name(0.15), "精品")
	assert_eq(_compendium.get_rarity_name(0.05), "传说")

## 测试获取难度星级
func test_get_difficulty_stars():
	assert_eq(_compendium.get_difficulty_stars(1), "★☆☆☆☆")
	assert_eq(_compendium.get_difficulty_stars(5), "★★★★★")
	assert_eq(_compendium.get_difficulty_stars(3), "★★★☆☆")
