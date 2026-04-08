extends "res://tests/unit/test_base.gd"

## Quality枚举测试

func test_get_multiplier():
	# 测试各品质的修正系数
	assert_eq(Quality.get_multiplier(Quality.NORMAL), 1.0, "普通品质应为1.0")
	assert_eq(Quality.get_multiplier(Quality.FINE), 1.25, "优秀品质应为1.25")
	assert_eq(Quality.get_multiplier(Quality.EXCELLENT), 1.5, "精良品质应为1.5")
	assert_eq(Quality.get_multiplier(Quality.SUPREME), 2.0, "史诗品质应为2.0")

func test_get_multiplier_invalid():
	# 测试无效品质的默认返回值
	assert_eq(Quality.get_multiplier(999), 1.0, "无效品质应返回默认值1.0")

func test_get_color():
	# 测试品质颜色返回
	var normal_color = Quality.get_color(Quality.NORMAL)
	assert_true(normal_color is Color, "应返回Color类型")

	var supreme_color = Quality.get_color(Quality.SUPREME)
	assert_true(supreme_color is Color, "应返回Color类型")

func test_get_quality_name():
	# 测试品质名称
	assert_eq(Quality.get_quality_name(Quality.NORMAL), "普通")
	assert_eq(Quality.get_quality_name(Quality.FINE), "优秀")
	assert_eq(Quality.get_quality_name(Quality.EXCELLENT), "精良")
	assert_eq(Quality.get_quality_name(Quality.SUPREME), "史诗")
	assert_eq(Quality.get_quality_name(999), "未知", "无效品质应返回'未知'")

func test_from_string():
	# 测试从字符串解析品质
	assert_eq(Quality.from_string("normal"), Quality.NORMAL)
	assert_eq(Quality.from_string("Normal"), Quality.NORMAL)
	assert_eq(Quality.from_string("普通"), Quality.NORMAL)
	assert_eq(Quality.from_string("fine"), Quality.FINE)
	assert_eq(Quality.from_string("excellent"), Quality.EXCELLENT)
	assert_eq(Quality.from_string("supreme"), Quality.SUPREME)
	assert_eq(Quality.from_string("invalid"), Quality.NORMAL, "无效字符串应返回默认NORMAL")

func test_multiplier_calculation():
	# 测试售价计算
	var base_price = 100
	assert_eq(Quality.get_multiplier(Quality.NORMAL) * base_price, 100.0)
	assert_eq(Quality.get_multiplier(Quality.FINE) * base_price, 125.0)
	assert_eq(Quality.get_multiplier(Quality.EXCELLENT) * base_price, 150.0)
	assert_eq(Quality.get_multiplier(Quality.SUPREME) * base_price, 200.0)
