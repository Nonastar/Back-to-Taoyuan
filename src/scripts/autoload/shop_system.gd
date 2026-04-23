extends Node

## ShopSystem - MVP Shop Autoload
##  - Time-based open/close checks
##  - Buy / Sell item flows integrated with InventorySystem and PlayerStats
##  - Seasonal seed listing helper (for design-time display)

# Signals
signal purchase_completed(item_id: String, quantity: int, total_cost: int)
signal sale_completed(item_id: String, quantity: int, money_earned: int)
signal shop_opened(shop_id: String)
signal shop_closed(shop_id: String)

# Shop ID enum for code safety
enum ShopId {
	GENERAL_STORE = 0,
	ANIMAL_SHOP = 1
}

## 数据初始化（由 init() 调用，可注入外部数据源）
func init(data_source: Object = null) -> void:
	if data_source != null and data_source.has_method("load_shop_data"):
		var data = data_source.load_shop_data()
		if not data.is_empty():
			_shops_data = data
			print("[ShopSystem] Shop data loaded from injected source")
			return
	_initialize_from_json()

func _initialize_from_json() -> void:
	if DataLoader:
		var data = DataLoader.load_json("shop_data.json")
		if data.has("shops") and not data["shops"].is_empty():
			_shops_data = data["shops"]
			_sell_price_multiplier = data.get("sell_price_multiplier", 0.5)
			print("[ShopSystem] Loaded shops from JSON: " + str(_shops_data.keys()))
			return
	# 兜底硬编码（仅在新项目或 JSON 缺失时使用）
	_shops_data = {
		"general_store": {
			"name": "杂货店",
			"start_hour": 9,
			"end_hour": 17,
			"categories_for_sale": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
		},
		"animal_shop": {
			"name": "动物商店",
			"start_hour": 9,
			"end_hour": 17,
			"animals": [
				{"animal_id": "chicken_white", "name": "白鸡", "price": 400, "stock": 5},
				{"animal_id": "chicken_brown", "name": "棕鸡", "price": 400, "stock": 5},
				{"animal_id": "duck", "name": "鸭子", "price": 500, "stock": 4},
				{"animal_id": "cow", "name": "牛", "price": 1000, "stock": 3},
				{"animal_id": "sheep", "name": "绵羊", "price": 800, "stock": 3},
				{"animal_id": "pig", "name": "猪", "price": 1200, "stock": 2},
				{"animal_id": "goat", "name": "山羊", "price": 900, "stock": 4}
			]
		}
	}
	_sell_price_multiplier = 0.5
	print("[ShopSystem] No shop_data.json found, using built-in defaults")

func _ready() -> void:
	init()

# ============ 商店配置（运行时数据）============

var _shops_data: Dictionary = {}  # 从 JSON 加载
var _sell_price_multiplier: float = 0.5

# ============ 商店物品列表 ============

func get_shop_inventory(shop_id: ShopId) -> Array:
	var items: Array = []
	
	# 根据商店类型返回不同物品
	match shop_id:
		ShopId.GENERAL_STORE:
			items = _get_general_store_items()
		ShopId.ANIMAL_SHOP:
			items = _get_animal_shop_items()
	
	return items

func _get_general_store_items() -> Array:
	# 获取所有可购买的物品
	var items: Array = []
	var all_items = ItemDataSystem.get_all_items()
	
	for item_def in all_items:
		if item_def == null:
			continue
		
		# 只显示可出售类物品（跳过种子类，杂货店不卖种子）
		if item_def.category == ItemCategory.SEED:
			continue
		
		var item_info = {
			"item_id": item_def.id,
			"name": item_def.name,
			"price": item_def.sell_price,
			"stock": -1,  # 无限库存
			"icon": "📦"
		}
		items.append(item_info)
	
	return items

func _get_animal_shop_items() -> Array:
	# 从 JSON 加载的动物商店数据
	var shop_data: Dictionary = _shops_data.get("animal_shop", {})
	var animals: Array = shop_data.get("animals", [])
	# 转换为 shop_item 格式
	var items: Array = []
	for animal: Dictionary in animals:
		items.append({
			"item_id": animal.get("animal_id", ""),
			"name": animal.get("name", ""),
			"price": animal.get("price", 0),
			"stock": animal.get("stock", -1)
		})
	return items

# 兼容旧版本方法名
func get_general_store_items() -> Array:
	return _get_general_store_items()

func is_shop_open(shop_id: String) -> bool:
	if not _shops_data.has(shop_id):
		return false
	var info: Dictionary = _shops_data[shop_id]
	var hour: int = TimeManager.current_hour if TimeManager else 8
	return hour >= int(info.get("start_hour", 0)) and hour < int(info.get("end_hour", 0))

func buy_item(shop_id, item_id: String, quantity: int) -> Dictionary:
	# shop_id can be int (ShopId enum) or String
	var shop_id_str = ""
	if typeof(shop_id) == TYPE_STRING:
		shop_id_str = shop_id
	elif typeof(shop_id) == TYPE_INT:
		match shop_id:
			ShopId.GENERAL_STORE: shop_id_str = "general_store"
			ShopId.ANIMAL_SHOP: shop_id_str = "animal_shop"

	if quantity <= 0 or item_id.is_empty():
		return {"success": false, "message": "Invalid parameters"}
	if not is_shop_open(shop_id_str):
		return {"success": false, "message": "Shop is closed"}

	# ============ 动物商店：调用畜牧系统购买动物 ============
	if shop_id_str == "animal_shop":
		if quantity > 1:
			return {"success": false, "message": "Animals can only be bought one at a time"}
		if not (AnimalHusbandrySystem and AnimalHusbandrySystem.has_method("can_buy_animal")):
			push_error("[ShopSystem] AnimalHusbandrySystem not available")
			return {"success": false, "message": "AnimalHusbandrySystem not available"}
		if not AnimalHusbandrySystem.can_buy_animal(item_id):
			# 细化失败原因
			var animal_data = AnimalHusbandrySystem.get_animal_data(item_id) if AnimalHusbandrySystem.has_method("get_animal_data") else {}
			var building_type = animal_data.get("building_type", -1)
			if not AnimalHusbandrySystem.is_building_built(building_type):
				return {"success": false, "message": "Building not built"}
			if AnimalHusbandrySystem.get_building_animal_count(building_type) >= AnimalHusbandrySystem.get_building_capacity(building_type):
				return {"success": false, "message": "Building is full"}
			return {"success": false, "message": "Not enough money"}
		if not (AnimalHusbandrySystem and AnimalHusbandrySystem.has_method("buy_animal")):
			return {"success": false, "message": "Buy animal method unavailable"}
		var bought = AnimalHusbandrySystem.buy_animal(item_id)
		if not bought:
			return {"success": false, "message": "Purchase failed"}
		var total_cost = 0
		if AnimalHusbandrySystem.has_method("get_animal_data"):
			var ad = AnimalHusbandrySystem.get_animal_data(item_id)
			total_cost = ad.get("buy_price", 0)
		purchase_completed.emit(item_id, 1, total_cost)
		return {"success": true, "message": "Purchased", "total_cost": total_cost}

	# ============ 普通商店：购买物品加入背包 ============
	var item_def = ItemDataSystem.get_item_def(item_id)
	if item_def == null:
		return {"success": false, "message": "Item not found"}

	# Default to NORMAL quality for MVP buy price calculation
	var quality: int = Quality.NORMAL
	var unit_price: int = ItemDataSystem.calculate_sell_price(item_def.sell_price, quality)
	var total_cost: int = unit_price * quantity

	var current_money: int = PlayerStats.get_money()
	if current_money < total_cost:
		return {"success": false, "message": "Not enough money"}

	var added = InventorySystem.add_item(item_id, quantity, quality)
	if not added:
		return {"success": false, "message": "Inventory full"}

	var spent = PlayerStats.spend_money(total_cost)
	if not spent:
		# Rollback inventory if payment failed unexpectedly
		InventorySystem.remove_item(item_id, quantity, quality)
		return {"success": false, "message": "Payment failed"}

	purchase_completed.emit(item_id, quantity, total_cost)
	return {"success": true, "message": "Purchased", "total_cost": total_cost}

func sell_item(shop_id, item_id: String, quantity: int) -> Dictionary:
	# shop_id can be int (ShopId enum) or String
	var shop_id_str = ""
	if typeof(shop_id) == TYPE_STRING:
		shop_id_str = shop_id
	elif typeof(shop_id) == TYPE_INT:
		match shop_id:
			ShopId.GENERAL_STORE: shop_id_str = "general_store"
			ShopId.ANIMAL_SHOP: shop_id_str = "animal_shop"
	
	if quantity <= 0 or item_id.is_empty():
		return {"success": false, "money_earned": 0}
	if not is_shop_open(shop_id_str):
		return {"success": false, "message": "Shop is closed", "money_earned": 0}

	var item_def = ItemDataSystem.get_item_def(item_id)
	if item_def == null:
		return {"success": false, "money_earned": 0}

	var remaining: int = quantity
	var money_earned: int = 0
	var sold: int = 0
	var qualities_to_sell := [Quality.NORMAL, Quality.FINE, Quality.EXCELLENT, Quality.SUPREME]
	for q in qualities_to_sell:
		if remaining <= 0:
			break
		var avail = InventorySystem.get_item_count(item_id, q)
		if avail <= 0:
			continue
		var to_sell = mini(avail, remaining)
		var base_price: int = ItemDataSystem.calculate_sell_price(item_def.sell_price, q)
		var price: int = int(base_price * _sell_price_multiplier)
		money_earned += price * to_sell
		remaining -= to_sell
		sold += to_sell

	if sold > 0:
		# quality=-1: InventorySystem 优先移除低品质物品（先卖普通，再卖良品…）
		# 这是有意设计：玩家通常想保留高品质物品后出售
		InventorySystem.remove_item(item_id, sold, -1)
		PlayerStats.earn_money(money_earned)
		sale_completed.emit(item_id, sold, money_earned)
		return {"success": true, "money_earned": money_earned}

	return {"success": false, "money_earned": 0}

# Save/load integration (minimal)
func get_save_data() -> Dictionary:
	return {"shops": {}}

func load_save_data(data: Dictionary) -> void:
	pass

## 获取出售价格倍率（供UI调用）
func get_sell_price_multiplier() -> float:
	return _sell_price_multiplier
