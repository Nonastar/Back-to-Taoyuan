extends "res://tests/unit/test_base.gd"

## ShopSystem 商店系统单元测试
## 测试商店购买/出售逻辑、营业时间判断

var _shop: Node = null

func before_each():
	_shop = Node.new()
	_shop.set_script(load("res://src/scripts/autoload/shop_system.gd"))
	_shop._ready()

func after_each():
	_shop.free()

# ============ 商店常量测试 ============

func test_shop_id_enum_values():
	assert_eq(_shop.ShopId.GENERAL_STORE, 0, "杂货铺ID应为0")
	assert_eq(_shop.ShopId.ANIMAL_SHOP, 1, "动物商店ID应为1")

func test_shops_dictionary_structure():
	assert_true(_shop.SHOPS.has("general_store"), "应包含杂货铺")
	assert_true(_shop.SHOPS.has("animal_shop"), "应包含动物商店")
	assert_eq(_shop.SHOPS["general_store"]["start_hour"], 9, "杂货铺开始营业时间为9点")
	assert_eq(_shop.SHOPS["general_store"]["end_hour"], 17, "杂货铺结束营业时间为17点")

# ============ 营业时间测试 ============

func test_shop_open_during_business_hours():
	## 模拟营业时间内 (12:00)
	TimeManager.current_hour = 12
	assert_true(_shop.is_shop_open("general_store"), "12点应对杂货铺开放")

func test_shop_closed_before_opening_hour():
	## 模拟营业时间前 (8:00)
	TimeManager.current_hour = 8
	assert_false(_shop.is_shop_open("general_store"), "8点应不对杂货铺开放")

func test_shop_closed_after_closing_hour():
	## 模拟营业时间后 (18:00)
	TimeManager.current_hour = 18
	assert_false(_shop.is_shop_open("general_store"), "18点应不对杂货铺开放")

func test_shop_closed_for_unknown_shop():
	assert_false(_shop.is_shop_open("nonexistent_shop"), "未知商店应关闭")

# ============ 商店库存测试 ============

func test_get_shop_inventory_returns_array():
	var items = _shop.get_shop_inventory(_shop.ShopId.GENERAL_STORE)
	assert_true(items is Array, "应返回数组")

func test_animal_shop_items():
	var items = _shop.get_shop_inventory(_shop.ShopId.ANIMAL_SHOP)
	assert_eq(items.size(), 5, "动物商店应有5种动物")
	# 验证动物种类
	var animal_ids = items.map(func(item): return item.get("item_id"))
	assert_true("chicken" in animal_ids, "应包含鸡")
	assert_true("cow" in animal_ids, "应包含牛")
	assert_true("sheep" in animal_ids, "应包含羊")

func test_get_general_store_items_compatibility():
	## 测试旧版本兼容方法
	var items = _shop.get_general_store_items()
	assert_true(items is Array, "应返回数组")

# ============ 购买逻辑测试 ============

func test_buy_item_invalid_quantity():
	var result = _shop.buy_item("general_store", "wheat", 0)
	assert_false(result.get("success", true), "数量为0应购买失败")

func test_buy_item_empty_item_id():
	var result = _shop.buy_item("general_store", "", 1)
	assert_false(result.get("success", true), "空物品ID应购买失败")

func test_buy_item_shop_closed():
	## 模拟商店关门
	TimeManager.current_hour = 20
	var result = _shop.buy_item("general_store", "wheat", 1)
	assert_false(result.get("success", true), "商店关闭时应购买失败")

func test_buy_item_not_found():
	## 模拟营业时间
	TimeManager.current_hour = 12
	var result = _shop.buy_item("general_store", "nonexistent_item", 1)
	assert_false(result.get("success", true), "不存在的物品应购买失败")

# ============ 出售逻辑测试 ============

func test_sell_item_invalid_quantity():
	var result = _shop.sell_item("general_store", "wheat", 0)
	assert_false(result.get("success", false), "数量为0应出售失败")

func test_sell_item_empty_item_id():
	var result = _shop.sell_item("general_store", "", 1)
	assert_false(result.get("success", false), "空物品ID应出售失败")

func test_sell_item_shop_closed():
	TimeManager.current_hour = 20
	var result = _shop.sell_item("general_store", "wheat", 1)
	assert_false(result.get("success", false), "商店关闭时应出售失败")

func test_sell_item_not_found():
	TimeManager.current_hour = 12
	var result = _shop.sell_item("general_store", "nonexistent_item", 1)
	assert_false(result.get("success", false), "不存在的物品应出售失败")

# ============ 信号测试 ============

func test_purchase_completed_signal_exists():
	assert_true(_shop.has_signal("purchase_completed"), "应有purchase_completed信号")

func test_sale_completed_signal_exists():
	assert_true(_shop.has_signal("sale_completed"), "应有sale_completed信号")

# ============ 存档测试 ============

func test_get_save_data_returns_dictionary():
	var data = _shop.get_save_data()
	assert_true(data is Dictionary, "应返回字典")
	assert_true(data.has("shops"), "应包含shops字段")

func test_load_save_data_accepts_empty_data():
	_shop.load_save_data({})
	assert_true(true, "空数据加载不应崩溃")
