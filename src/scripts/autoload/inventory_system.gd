extends Node

## InventorySystem - 库存系统
## 负责物品管理、背包操作和物品堆叠
## 参考: C02 库存系统 GDD

# ============ 常量 ============

## 初始背包容量 (GDD: 24)
const INITIAL_CAPACITY: int = 24

## 最大背包容量 (GDD: 60)
const MAX_CAPACITY: int = 60

## 每次扩容格数 (GDD: 4)
const EXPANSION_AMOUNT: int = 4

## 最大堆叠数量 (GDD: 999)
const MAX_STACK_SIZE: int = 999

## 临时背包容量 (GDD: 10)
const TEMP_CAPACITY: int = 10

## 背包快满提醒阈值 (GDD: 3)
const FULL_WARNING_THRESHOLD: int = 3

# ============ 物品槽位数据结构 ============

## 物品槽位
class ItemSlot:
	var item_id: String = ""
	var quantity: int = 0
	var quality: int = Quality.NORMAL

	func is_empty() -> bool:
		return item_id.is_empty() or quantity <= 0

	func clear():
		item_id = ""
		quantity = 0
		quality = Quality.NORMAL

# ============ 背包数据 ============

## 玩家背包
var backpack: Array[ItemSlot] = []

## 当前背包容量
var backpack_size: int = INITIAL_CAPACITY

## 累计扩容次数
var expansion_count: int = 0

## 临时背包 (溢出缓冲区)
var temp_backpack: Array[ItemSlot] = []

# ============ 信号 ============

## 背包变化信号
signal backpack_changed()

## 物品添加成功
signal item_added(item_id: String, amount: int, quality: int)

## 物品移除成功
signal item_removed(item_id: String, amount: int, quality: int)

## 背包已满
signal inventory_full(item_id: String)

## 全部背包已满
signal all_full()

## 物品出售成功
signal item_sold(item_id: String, amount: int, money_earned: int)

## 背包扩容
signal backpack_expanded(new_size: int)

# ============ 初始化 ============

func _ready() -> void:
	_init_backpack()
	_init_temp_backpack()

## 初始化背包
func _init_backpack() -> void:
	backpack.clear()
	for i in backpack_size:
		backpack.append(ItemSlot.new())

## 初始化临时背包
func _init_temp_backpack() -> void:
	temp_backpack.clear()
	for i in TEMP_CAPACITY:
		temp_backpack.append(ItemSlot.new())

# ============ 核心操作 ============

## 添加物品到背包
func add_item(item_id: String, amount: int = 1, quality: int = Quality.NORMAL) -> bool:
	if amount <= 0 or item_id.is_empty():
		return false

	# 验证物品是否存在
	if not ItemDataSystem.item_exists(item_id):
		push_error("[InventorySystem] Item not found: %s" % item_id)
		return false

	# 获取物品最大堆叠限制
	var max_stack = _get_item_max_stack(item_id)
	var actual_max_stack = mini(MAX_STACK_SIZE, max_stack)

	# 先尝试堆叠到现有槽位 (优先匹配品质)
	var remaining = _add_to_existing_slots(backpack, item_id, amount, quality, actual_max_stack)
	if remaining <= 0:
		_emit_item_added(item_id, amount, quality)
		return true

	# 尝试放入空槽位
	remaining = _add_to_empty_slots(backpack, item_id, remaining, quality, actual_max_stack)
	if remaining <= 0:
		_emit_item_added(item_id, amount, quality)
		return true

	# 背包已满，尝试放入临时背包
	remaining = _add_to_existing_slots(temp_backpack, item_id, remaining, quality, actual_max_stack)
	if remaining <= 0:
		_emit_item_added(item_id, amount, quality)
		return true

	remaining = _add_to_empty_slots(temp_backpack, item_id, remaining, quality, actual_max_stack)
	if remaining <= 0:
		_emit_item_added(item_id, amount, quality)
		return true

	# 所有背包都满了
	inventory_full.emit(item_id)
	all_full.emit()
	return false

## 从背包移除物品 (优先消耗低品质)
func remove_item(item_id: String, amount: int = 1, quality: int = -1) -> bool:
	if amount <= 0 or item_id.is_empty():
		return false

	var removed = _remove_from_slots_with_quality(backpack, item_id, amount)
	if removed > 0:
		_emit_item_removed(item_id, removed, quality)
		return true

	# 从临时背包移除
	removed = _remove_from_slots_with_quality(temp_backpack, item_id, amount)
	if removed > 0:
		_emit_item_removed(item_id, removed, quality)
		return true

	return false

## 检查物品是否存在
func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_count(item_id) >= amount

## 获取物品总数量
func get_item_count(item_id: String, quality: int = -1) -> int:
	var total = 0
	total += _count_in_slots(backpack, item_id, quality)
	total += _count_in_slots(temp_backpack, item_id, quality)
	return total

## 检查背包是否已满
func is_full() -> bool:
	return get_empty_slots() <= 0

## 检查所有背包是否已满
func is_all_full() -> bool:
	return is_full() and _get_empty_slots(temp_backpack) <= 0

## 检查是否需要提醒背包快满了
func needs_warning() -> bool:
	return get_empty_slots() <= FULL_WARNING_THRESHOLD

## 获取物品最大堆叠限制
func _get_item_max_stack(item_id: String) -> int:
	var item_def = ItemDataSystem.get_item_def(item_id)
	if item_def != null:
		return item_def.max_stack
	return MAX_STACK_SIZE

# ============ 物品操作 ============

## 丢弃物品
func drop_item(slot_index: int, amount: int = 1) -> bool:
	if slot_index < 0 or slot_index >= backpack.size():
		return false

	var slot = backpack[slot_index]
	if slot.is_empty() or slot.quantity < amount:
		return false

	var item_id = slot.item_id
	var removed_quality = slot.quality
	slot.quantity -= amount
	if slot.quantity <= 0:
		slot.clear()

	backpack_changed.emit()
	_emit_item_removed(item_id, amount, removed_quality)
	return true

## 丢弃所有物品
func discard_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= backpack.size():
		return false

	var slot = backpack[slot_index]
	if slot.is_empty():
		return false

	var item_id = slot.item_id
	var quantity = slot.quantity
	var removed_quality = slot.quality
	slot.clear()

	backpack_changed.emit()
	_emit_item_removed(item_id, quantity, removed_quality)
	return true

## 丢弃临时背包物品
func discard_temp_item(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= temp_backpack.size():
		return false

	var slot = temp_backpack[slot_index]
	if slot.is_empty():
		return false

	var item_id = slot.item_id
	var quantity = slot.quantity
	var removed_quality = slot.quality
	slot.clear()

	backpack_changed.emit()
	_emit_item_removed(item_id, quantity, removed_quality)
	return true

## 使用物品
func use_item(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= backpack.size():
		return false

	var slot = backpack[slot_index]
	if slot.is_empty():
		return false

	var item_def = ItemDataSystem.get_item_def(slot.item_id)
	if item_def == null:
		return false

	# 检查是否可食用
	if item_def.edible:
		_consume_edible_item(slot, item_def)
		return true

	# TODO: 其他物品使用逻辑
	return false

## 消耗可食用物品
func _consume_edible_item(slot: ItemSlot, item_def: ItemDef) -> void:
	if PlayerStats != null:
		# 恢复体力
		if item_def.stamina_restore > 0:
			PlayerStats.restore_stamina(int(item_def.stamina_restore))
		# 恢复HP
		if item_def.health_restore > 0:
			PlayerStats.restore_health(int(item_def.health_restore))

	# 移除物品
	slot.quantity -= 1
	if slot.quantity <= 0:
		slot.clear()

	backpack_changed.emit()
	EventBus.item_used.emit(slot.item_id)

# ============ 物品出售 ============

## 出售物品
func sell_item(item_id: String, quantity: int = 1) -> Dictionary:
	if quantity <= 0 or item_id.is_empty():
		return {"success": false, "money_earned": 0, "quantity_sold": 0}

	# 检查物品数量
	var available = get_item_count(item_id)
	if available < quantity:
		quantity = available

	if quantity <= 0:
		return {"success": false, "money_earned": 0, "quantity_sold": 0}

	# 获取物品定义计算售价
	var item_def = ItemDataSystem.get_item_def(item_id)
	if item_def == null:
		push_error("[InventorySystem] Cannot sell unknown item: %s" % item_id)
		return {"success": false, "money_earned": 0, "quantity_sold": 0}

	# 计算总价 (按品质)
	var total_money = 0
	var total_sold = 0

	# 优先出售低品质物品
	var qualities_to_sell = [Quality.NORMAL, Quality.FINE, Quality.EXCELLENT, Quality.SUPREME]
	for q in qualities_to_sell:
		if total_sold >= quantity:
			break
		var qty_in_quality = _count_in_slots(backpack, item_id, q) + _count_in_slots(temp_backpack, item_id, q)
		if qty_in_quality > 0:
			var to_sell = mini(qty_in_quality, quantity - total_sold)
			var price = ItemDataSystem.calculate_sell_price(item_def.sell_price, q)
			total_money += price * to_sell
			total_sold += to_sell

	# 实际移除物品
	if total_sold > 0:
		_remove_from_slots_with_quality(backpack, item_id, total_sold)
		_remove_from_slots_with_quality(temp_backpack, item_id, total_sold)

		# 获得金钱
		if PlayerStats != null:
			PlayerStats.earn_money(total_money)

		item_sold.emit(item_id, total_sold, total_money)
		backpack_changed.emit()

	return {
		"success": true,
		"money_earned": total_money,
		"quantity_sold": total_sold
	}

# ============ 背包管理 ============

## 整理背包 (合并相同物品，按分类/ID/品质排序)
func sort_items() -> void:
	# 收集所有非空槽物品
	var items: Array = []
	for slot in backpack:
		if not slot.is_empty():
			items.append({
				"item_id": slot.item_id,
				"quantity": slot.quantity,
				"quality": slot.quality
			})
			slot.clear()

	# 排序 (按分类 -> ID -> 品质)
	items.sort_custom(func(a, b):
		var item_a = ItemDataSystem.get_item_def(a["item_id"])
		var item_b = ItemDataSystem.get_item_def(b["item_id"])
		var cat_a = item_a.category if item_a else 99
		var cat_b = item_b.category if item_b else 99
		if cat_a != cat_b:
			return cat_a < cat_b
		if a["item_id"] != b["item_id"]:
			return a["item_id"] < b["item_id"]
		return a["quality"] < b["quality"]
	)

	# 重新放入
	for item in items:
		add_item(item["item_id"], item["quantity"], item["quality"])

## 扩展背包容量 (+4格)
func expand_capacity() -> bool:
	if backpack_size >= MAX_CAPACITY:
		print("[InventorySystem] Already at max capacity: %d" % MAX_CAPACITY)
		return false

	var new_size = mini(backpack_size + EXPANSION_AMOUNT, MAX_CAPACITY)
	var added = new_size - backpack_size
	backpack_size = new_size
	expansion_count += 1

	# 添加新槽位
	for i in added:
		backpack.append(ItemSlot.new())

	backpack_expanded.emit(backpack_size)
	backpack_changed.emit()
	return true

## 解锁仓库 (初始100格)
func unlock_warehouse() -> void:
	has_warehouse = true
	backpack_changed.emit()

# ============ 仓库转移 ============

## 从临时背包移动到主背包
func move_from_temp(temp_index: int) -> bool:
	if temp_index < 0 or temp_index >= temp_backpack.size():
		return false

	var slot = temp_backpack[temp_index]
	if slot.is_empty():
		return false

	# 先尝试合并到主背包
	var remaining = _add_to_existing_slots(backpack, slot.item_id, slot.quantity, slot.quality, MAX_STACK_SIZE)
	if remaining <= 0:
		slot.clear()
		backpack_changed.emit()
		return true

	# 尝试放入空槽
	remaining = _add_to_empty_slots(backpack, slot.item_id, remaining, slot.quality, MAX_STACK_SIZE)
	if remaining <= 0:
		slot.clear()
		backpack_changed.emit()
		return true

	# 主背包也满了，部分移动
	if remaining < slot.quantity:
		slot.quantity = remaining
	else:
		# 无法移动
		return false

	backpack_changed.emit()
	return true

## 从临时背包移动所有物品
func move_all_from_temp() -> int:
	var moved = 0
	for i in temp_backpack.size():
		if move_from_temp(i):
			moved += 1
	return moved

# ============ 查询 ============

## 获取背包中的物品信息
func get_backpack_contents() -> Array:
	var contents: Array = []
	for i in backpack.size():
		var slot = backpack[i]
		if not slot.is_empty():
			contents.append({
				"index": i,
				"item_id": slot.item_id,
				"quantity": slot.quantity,
				"quality": slot.quality
			})
	return contents

## 获取临时背包内容
func get_temp_contents() -> Array:
	var contents: Array = []
	for i in temp_backpack.size():
		var slot = temp_backpack[i]
		if not slot.is_empty():
			contents.append({
				"index": i,
				"item_id": slot.item_id,
				"quantity": slot.quantity,
				"quality": slot.quality
			})
	return contents

## 获取空槽数量
func get_empty_slots() -> int:
	return _get_empty_slots(backpack)

## 获取已用槽数量
func get_used_slots() -> int:
	return backpack_size - get_empty_slots()

## 获取临时背包空槽数量
func get_temp_empty_slots() -> int:
	return _get_empty_slots(temp_backpack)

# ============ 存档支持 ============

## 获取存档数据
func get_save_data() -> Dictionary:
	var items: Array = []
	for slot in backpack:
		if not slot.is_empty():
			items.append({
				"id": slot.item_id,
				"qty": slot.quantity,
				"quality": slot.quality
			})

	var temp_items: Array = []
	for slot in temp_backpack:
		if not slot.is_empty():
			temp_items.append({
				"id": slot.item_id,
				"qty": slot.quantity,
				"quality": slot.quality
			})

	return {
		"backpack_size": backpack_size,
		"expansion_count": expansion_count,
		"items": items,
		"temp_items": temp_items
	}

## 加载存档数据
func load_save_data(data: Dictionary) -> void:
	_init_backpack()
	_init_temp_backpack()

	if "backpack_size" in data:
		backpack_size = data["backpack_size"]
		expansion_count = data.get("expansion_count", 0)

		# 确保背包有足够的槽位
		while backpack.size() < backpack_size:
			backpack.append(ItemSlot.new())

	if "items" in data:
		for item_data in data["items"]:
			add_item(item_data["id"], item_data["qty"], item_data.get("quality", Quality.NORMAL))

	if "temp_items" in data:
		for item_data in data["temp_items"]:
			var slot = _find_empty_slot(temp_backpack)
			if slot != null:
				slot.item_id = item_data["id"]
				slot.quantity = item_data["qty"]
				slot.quality = item_data.get("quality", Quality.NORMAL)

	backpack_changed.emit()

# ============ 内部工具函数 ============

func _add_to_existing_slots(slots: Array, item_id: String, amount: int, quality: int, max_stack: int) -> int:
	var remaining = amount
	for slot in slots:
		if slot.item_id == item_id and slot.quality == quality and remaining > 0:
			var can_add = max_stack - slot.quantity
			if can_add > 0:
				var to_add = mini(can_add, remaining)
				slot.quantity += to_add
				remaining -= to_add
	return remaining

func _add_to_empty_slots(slots: Array, item_id: String, amount: int, quality: int, max_stack: int) -> int:
	var remaining = amount
	for slot in slots:
		if slot.is_empty() and remaining > 0:
			var to_add = mini(max_stack, remaining)
			slot.item_id = item_id
			slot.quantity = to_add
			slot.quality = quality
			remaining -= to_add
	return remaining

func _remove_from_slots_with_quality(slots: Array, item_id: String, amount: int, quality: int = -1) -> int:
	var remaining = amount

	# 如果指定了品质，只移除该品质
	if quality >= 0:
		for slot in slots:
			if slot.item_id == item_id and slot.quality == quality and remaining > 0:
				var to_remove = mini(slot.quantity, remaining)
				slot.quantity -= to_remove
				remaining -= to_remove
				if slot.quantity <= 0:
					slot.clear()
		return amount - remaining

	# 否则优先移除低品质物品
	var qualities_to_remove = [Quality.NORMAL, Quality.FINE, Quality.EXCELLENT, Quality.SUPREME]
	for q in qualities_to_remove:
		if remaining <= 0:
			break
		for slot in slots:
			if slot.item_id == item_id and slot.quality == q and remaining > 0:
				var to_remove = mini(slot.quantity, remaining)
				slot.quantity -= to_remove
				remaining -= to_remove
				if slot.quantity <= 0:
					slot.clear()

	return amount - remaining

func _count_in_slots(slots: Array, item_id: String, quality: int = -1) -> int:
	var count = 0
	for slot in slots:
		if slot.item_id == item_id:
			if quality < 0 or slot.quality == quality:
				count += slot.quantity
	return count

func _get_empty_slots(slots: Array) -> int:
	var count = 0
	for slot in slots:
		if slot.is_empty():
			count += 1
	return count

func _find_empty_slot(slots: Array) -> ItemSlot:
	for slot in slots:
		if slot.is_empty():
			return slot
	return null

func _emit_item_added(item_id: String, amount: int, quality: int) -> void:
	EventBus.item_added.emit(item_id, amount)
	item_added.emit(item_id, amount, quality)
	backpack_changed.emit()

func _emit_item_removed(item_id: String, amount: int, quality: int) -> void:
	EventBus.item_removed.emit(item_id, amount)
	item_removed.emit(item_id, amount, quality)

# ============ 配置应用 ============

## 应用玩家配置
func apply_config(config: PlayerConfig) -> void:
	if config == null:
		push_error("[InventorySystem] Cannot apply null config")
		return

	# 背包容量配置
	var new_size = config.default_backpack_size
	if new_size > backpack_size and new_size <= MAX_CAPACITY:
		var added = new_size - backpack_size
		backpack_size = new_size
		for i in added:
			backpack.append(ItemSlot.new())

	max_stack_size = config.max_stack_size

	print("[InventorySystem] Config applied: backpack_size=%d" % backpack_size)

# ============ 仓库支持 (预留) ============

## 是否有仓库
var has_warehouse: bool = false

## 仓库大小
var warehouse_size: int = 100

## 仓库
var warehouse: Array[ItemSlot] = []

## 仓库最大堆叠数量
var max_stack_size: int = MAX_STACK_SIZE

## 仓库转移 - 从背包到仓库
func transfer_to_warehouse(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= backpack.size():
		return false
	if not has_warehouse:
		return false

	var slot = backpack[slot_index]
	if slot.is_empty():
		return false

	# 尝试添加到仓库
	var remaining = _add_to_existing_slots(warehouse, slot.item_id, slot.quantity, slot.quality, max_stack_size)
	if remaining <= 0:
		slot.clear()
		backpack_changed.emit()
		return true

	remaining = _add_to_empty_slots(warehouse, slot.item_id, remaining, slot.quality, max_stack_size)
	if remaining <= 0:
		slot.clear()
		backpack_changed.emit()
		return true

	# 仓库也满了
	return false

## 仓库转移 - 从仓库到背包
func transfer_to_backpack(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= warehouse.size():
		return false

	var slot = warehouse[slot_index]
	if slot.is_empty():
		return false

	# 尝试添加到背包
	var remaining = _add_to_existing_slots(backpack, slot.item_id, slot.quantity, slot.quality, max_stack_size)
	if remaining <= 0:
		slot.clear()
		backpack_changed.emit()
		return true

	remaining = _add_to_empty_slots(backpack, slot.item_id, remaining, slot.quality, max_stack_size)
	if remaining <= 0:
		slot.clear()
		backpack_changed.emit()
		return true

	return false
