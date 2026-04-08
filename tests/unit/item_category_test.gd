extends "res://tests/unit/test_base.gd"

## ItemCategory枚举测试

func test_get_category_name():
	# 测试各分类名称
	assert_eq(ItemCategory.get_category_name(ItemCategory.SEED), "种子")
	assert_eq(ItemCategory.get_category_name(ItemCategory.CROP), "作物")
	assert_eq(ItemCategory.get_category_name(ItemCategory.FISH), "鱼")
	assert_eq(ItemCategory.get_category_name(ItemCategory.ORE), "矿石")
	assert_eq(ItemCategory.get_category_name(ItemCategory.MATERIAL), "材料")
	assert_eq(ItemCategory.get_category_name(ItemCategory.FOOD), "食物")
	assert_eq(ItemCategory.get_category_name(ItemCategory.WEAPON), "武器")
	assert_eq(ItemCategory.get_category_name(ItemCategory.MISC), "杂物")
	assert_eq(ItemCategory.get_category_name(999), "未知", "无效分类应返回'未知'")

func test_is_stackable():
	# 测试分类是否可堆叠
	assert_true(ItemCategory.is_stackable(ItemCategory.SEED), "种子应可堆叠")
	assert_true(ItemCategory.is_stackable(ItemCategory.CROP), "作物应可堆叠")
	assert_true(ItemCategory.is_stackable(ItemCategory.MATERIAL), "材料应可堆叠")
	assert_false(ItemCategory.is_stackable(ItemCategory.WEAPON), "武器不应可堆叠")
	assert_false(ItemCategory.is_stackable(ItemCategory.RING), "戒指不应可堆叠")
	assert_false(ItemCategory.is_stackable(ItemCategory.HAT), "帽子不应可堆叠")
	assert_false(ItemCategory.is_stackable(ItemCategory.TOOL), "工具不应可堆叠")
	assert_false(ItemCategory.is_stackable(ItemCategory.QUEST), "任务物品不应可堆叠")

func test_get_stack_limit():
	# 测试各分类堆叠限制
	assert_eq(ItemCategory.get_stack_limit(ItemCategory.SEED), 999, "种子堆叠限制")
	assert_eq(ItemCategory.get_stack_limit(ItemCategory.ORE), 999, "矿石堆叠限制")
	assert_eq(ItemCategory.get_stack_limit(ItemCategory.CROP), 9999, "作物堆叠限制")
	assert_eq(ItemCategory.get_stack_limit(ItemCategory.WEAPON), 1, "武器堆叠限制")
	assert_eq(ItemCategory.get_stack_limit(ItemCategory.RING), 1, "戒指堆叠限制")

func test_category_count():
	# 测试分类数量
	assert_eq(ItemCategory.RELIC, 16, "最后一个分类索引应为16")
	assert_eq(ItemCategory.get_category_name(ItemCategory.RELIC), "文物", "RELIC分类名称")
