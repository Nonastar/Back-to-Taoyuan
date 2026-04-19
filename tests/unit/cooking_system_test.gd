extends "res://tests/unit/test_base.gd"

## CookingSystem 烹饪系统单元测试
## 测试食谱系统、烹饪流程、Buff管理

var _cooking: Node = null

func _reset_cooking_state():
	_cooking._is_cooking = false
	_cooking._current_recipe_id = ""
	_cooking._remaining_days = 0
	_cooking._active_buffs.clear()

func before_each():
	_cooking = Node.new()
	_cooking.set_script(load("res://src/scripts/autoload/cooking_system.gd"))
	_cooking._ready()

func after_each():
	_reset_cooking_state()
	_cooking.free()

# ============ 食谱初始化测试 ============

func test_recipes_initialized():
	assert_gt(_cooking.recipes.size(), 0, "应有初始食谱")
	assert_true(_cooking.recipes.has("egg_dish"), "应有煎蛋食谱")
	assert_true(_cooking.recipes.has("bread"), "应有烤面包食谱")

func test_recipe_structure():
	var recipe = _cooking.recipes["egg_dish"]
	assert_true(recipe.has("id"), "食谱应有id")
	assert_true(recipe.has("name"), "食谱应有name")
	assert_true(recipe.has("ingredients"), "食谱应有ingredients")
	assert_true(recipe.has("output_item_id"), "食谱应有output_item_id")
	assert_true(recipe.has("buff_on_eat"), "食谱应有buff_on_eat")

func test_recipe_has_valid_buff():
	var recipe = _cooking.recipes["egg_dish"]
	var buff = recipe.get("buff_on_eat")
	assert_true(buff.has("type"), "Buff应有type")
	assert_true(buff.has("min"), "Buff应有min")
	assert_true(buff.has("max"), "Buff应有max")

# ============ 烹饪流程测试 ============

func test_cook_item_no_cooking_in_progress():
	## 先确保没有正在烹饪
	_cooking._is_cooking = false
	_cooking._current_recipe_id = ""
	
	## 添加测试食材到背包
	InventorySystem.add_item("egg", 2, Quality.NORMAL)
	
	var result = _cooking.cook_item("egg_dish")
	assert_true(result, "烹饪应成功")

func test_cook_item_already_cooking():
	## 模拟正在烹饪
	_cooking._is_cooking = true
	_cooking._current_recipe_id = "bread"
	
	## 添加食材
	InventorySystem.add_item("wheat", 2, Quality.NORMAL)
	
	var result = _cooking.cook_item("egg_dish")
	assert_false(result, "正在烹饪时不应再开始")

func test_cook_item_recipe_not_found():
	_cooking._is_cooking = false
	var result = _cooking.cook_item("nonexistent_recipe")
	assert_false(result, "不存在的食谱应失败")

func test_cook_item_missing_ingredients():
	_cooking._is_cooking = false
	## 确保没有食材
	while InventorySystem.get_item_count("egg") > 0:
		InventorySystem.remove_item("egg", 999)
	
	var result = _cooking.cook_item("egg_dish")
	assert_false(result, "食材不足应失败")

# ============ 烹饪状态测试 ============

func test_is_cooking_state():
	_cooking._is_cooking = false
	assert_false(_cooking._is_cooking, "初始不应在烹饪")
	
	_cooking._is_cooking = true
	_cooking._current_recipe_id = "egg_dish"
	_cooking._remaining_days = 1
	assert_true(_cooking._is_cooking, "设置后应在烹饪状态")

# ============ Buff系统测试 ============

func test_active_buffs_initially_empty():
	assert_eq(_cooking._active_buffs.size(), 0, "初始Buff列表应为空")

func test_get_active_buffs_returns_array():
	var buffs = _cooking.get_active_buffs()
	assert_true(buffs is Array, "应返回数组")

func test_eat_dish_applies_buff():
	## 添加料理到背包
	InventorySystem.add_item("egg_dish", 1, Quality.NORMAL)
	
	var result = _cooking.eat_dish("egg_dish")
	assert_true(result.get("success", false), "食用应成功")

func test_eat_dish_missing_item():
	var result = _cooking.eat_dish("nonexistent_dish")
	assert_false(result.get("success", true), "物品不足应失败")

func test_get_dish_buff():
	var buff = _cooking._get_dish_buff("egg_dish")
	assert_true(buff.size() > 0, "煎蛋应有Buff")
	assert_eq(buff.get("type"), "stamina_restore", "煎蛋应恢复体力")

func test_get_dish_buff_not_found():
	var buff = _cooking._get_dish_buff("nonexistent_dish")
	assert_eq(buff.size(), 0, "不存在的料理应返回空字典")

# ============ 日期推进测试 ============

func test_advance_day_decrements_cooking_time():
	_cooking._is_cooking = true
	_cooking._current_recipe_id = "egg_dish"
	_cooking._remaining_days = 2
	
	_cooking.advance_day(1)
	assert_eq(_cooking._remaining_days, 1, "剩余天数应减少1")

func test_advance_day_finishes_cooking():
	_cooking._is_cooking = true
	_cooking._current_recipe_id = "egg_dish"
	_cooking._remaining_days = 1
	
	_cooking.advance_day(1)
	assert_false(_cooking._is_cooking, "剩余天数为0时应结束烹饪")

func test_advance_day_removes_expired_buffs():
	## 添加一个即将过期的Buff
	var buff = {"type": "stamina_restore", "value": 30, "remaining_days": 1}
	_cooking._active_buffs.append(buff)
	
	_cooking.advance_day(1)
	assert_eq(_cooking._active_buffs.size(), 0, "过期Buff应被移除")

func test_advance_day_decays_buff_duration():
	## 添加一个有多天剩余的Buff
	var buff = {"type": "speed", "value": 15, "remaining_days": 3}
	_cooking._active_buffs.append(buff)
	
	_cooking.advance_day(1)
	assert_eq(_cooking._active_buffs[0].get("remaining_days"), 2, "Buff剩余天数应减少")

# ============ 信号测试 ============

func test_cooking_started_signal_exists():
	assert_true(_cooking.has_signal("cooking_started"), "应有cooking_started信号")

func test_cooking_finished_signal_exists():
	assert_true(_cooking.has_signal("cooking_finished"), "应有cooking_finished信号")

func test_buff_applied_signal_exists():
	assert_true(_cooking.has_signal("buff_applied"), "应有buff_applied信号")

# ============ 存档测试 ============

func test_get_save_data_structure():
	var data = _cooking.get_save_data()
	assert_true(data.has("is_cooking"), "应有is_cooking字段")
	assert_true(data.has("current_recipe_id"), "应有current_recipe_id字段")
	assert_true(data.has("remaining_days"), "应有remaining_days字段")
	assert_true(data.has("active_buffs"), "应有active_buffs字段")

func test_load_save_data_restores_cooking_state():
	_cooking._is_cooking = true
	_cooking._current_recipe_id = "egg_dish"
	_cooking._remaining_days = 1
	
	var data = _cooking.get_save_data()
	
	## 重置状态后加载
	_cooking._is_cooking = false
	_cooking._current_recipe_id = ""
	_cooking._remaining_days = 0
	_cooking.load_save_data(data)
	
	assert_true(_cooking._is_cooking, "应恢复烹饪状态")
	assert_eq(_cooking._current_recipe_id, "egg_dish", "应恢复食谱ID")
	assert_eq(_cooking._remaining_days, 1, "应恢复剩余天数")

func test_load_save_data_empty():
	_cooking.load_save_data({})
	assert_false(_cooking._is_cooking, "空数据不应改变状态")
