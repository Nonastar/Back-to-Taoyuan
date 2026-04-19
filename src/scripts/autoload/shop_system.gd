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

# Simple shop registry (MVP)
const SHOPS: Dictionary = {
	"general_store": {"name": "General Store", "start_hour": 9, "end_hour": 17},
	"animal_shop":   {"name": "Animal Shop",  "start_hour": 9, "end_hour": 17}
}

# Shop ID enum for code safety
enum ShopId {
	GENERAL_STORE = 0,
	ANIMAL_SHOP = 1
}

func _ready() -> void:
	pass

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
		
		# 只显示可以购买的物品 (category 不是 NONE)
		if item_def.category == 0:  # ItemCategory.NONE
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
	# 动物商店物品
	var items: Array = [
		{"item_id": "chicken", "name": "鸡", "price": 500, "stock": 5},
		{"item_id": "cow", "name": "牛", "price": 1500, "stock": 3},
		{"item_id": "sheep", "name": "羊", "price": 1000, "stock": 3},
		{"item_id": "pig", "name": "猪", "price": 2000, "stock": 2},
		{"item_id": "goat", "name": "山羊", "price": 800, "stock": 4}
	]
	return items

# 兼容旧版本方法名
func get_general_store_items() -> Array:
	return _get_general_store_items()

func is_shop_open(shop_id: String) -> bool:
	if not SHOPS.has(shop_id):
		return false
	var info = SHOPS[shop_id]
	var hour = TimeManager.current_hour if TimeManager else 8
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
	
	var result := {"success": false, "message": "Unknown error"}
	if quantity <= 0 or item_id.is_empty():
		return {"success": false, "message": "Invalid parameters"}
	if not is_shop_open(shop_id_str):
		return {"success": false, "message": "Shop is closed"}

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
	return {"success": true, "message": "Purchased"}

func sell_item(shop_id, item_id: String, quantity: int) -> Dictionary:
	# shop_id can be int (ShopId enum) or String
	var shop_id_str = ""
	if typeof(shop_id) == TYPE_STRING:
		shop_id_str = shop_id
	elif typeof(shop_id) == TYPE_INT:
		match shop_id:
			ShopId.GENERAL_STORE: shop_id_str = "general_store"
			ShopId.ANIMAL_SHOP: shop_id_str = "animal_shop"
	
	var result := {"success": false, "money_earned": 0}
	if quantity <= 0 or item_id.is_empty():
		return result
	if not is_shop_open(shop_id_str):
		return result

	var item_def = ItemDataSystem.get_item_def(item_id)
	if item_def == null:
		return result

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
		var price = ItemDataSystem.calculate_sell_price(item_def.sell_price, q)
		money_earned += price * to_sell
		remaining -= to_sell
		sold += to_sell

	if sold > 0:
		InventorySystem.remove_item(item_id, sold, -1)
		PlayerStats.earn_money(money_earned)
		sale_completed.emit(item_id, sold, money_earned)
		return {"success": true, "money_earned": money_earned}

	return result

# Save/load integration (minimal)
func get_save_data() -> Dictionary:
	return {"shops": {}}

func load_save_data(data: Dictionary) -> void:
	pass
