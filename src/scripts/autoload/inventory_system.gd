extends Node

## InventorySystem - 库存系统
## 负责物品管理、背包操作和物品堆叠
## 参考: C02 库存系统 GDD

# ============ 常量 ============

## 默认背包容量
const DEFAULT_BACKPACK_SIZE: int = 30

## 最大堆叠数量
const MAX_STACK_SIZE: int = 9999

## 物品槽位数据结构
class ItemSlot:
	var item_id: String = ""
	var quantity: int = 0

	func is_empty() -> bool:
		return item_id.is_empty() or quantity <= 0

	func clear():
		item_id = ""
		quantity = 0

# ============ 背包数据 ============

## 玩家背包
var backpack: Array[ItemSlot] = []

## 背包容量
var backpack_size: int = DEFAULT_BACKPACK_SIZE

## 最大堆叠数量 (可配置)
var max_stack_size: int = 9999

## 仓库扩展 (解锁后可用)
var has_warehouse: bool = false
var warehouse_size: int = 100
var warehouse: Array[ItemSlot] = []

# ============ 信号 ============

## 背包变化信号
signal backpack_changed()

## 物品添加成功
signal item_added(item_id: String, amount: int)

## 物品移除成功
signal item_removed(item_id: String, amount: int)

# ============ 初始化 ============

func _ready() -> void:
	_init_backpack()
	_init_warehouse()

## 初始化背包
func _init_backpack() -> void:
	backpack.clear()
	for i in backpack_size:
		backpack.append(ItemSlot.new())

## 初始化仓库
func _init_warehouse() -> void:
	warehouse.clear()
	for i in warehouse_size:
		warehouse.append(ItemSlot.new())

# ============ 核心操作 ============

## 添加物品到背包
func add_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or item_id.is_empty():
		return false

	# 先尝试堆叠到现有槽位
	var remaining = _add_to_existing_slots(backpack, item_id, amount)
	if remaining <= 0:
		EventBus.item_added.emit(item_id, amount)
		backpack_changed.emit()
		return true

	# 尝试放入空槽位
	remaining = _add_to_empty_slots(backpack, item_id, remaining)
	if remaining <= 0:
		EventBus.item_added.emit(item_id, amount)
		backpack_changed.emit()
		return true

	# 背包已满
	EventBus.inventory_full.emit(item_id)
	return false

## 从背包移除物品
func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or item_id.is_empty():
		return false

	var removed = _remove_from_slots(backpack, item_id, amount)
	if removed > 0:
		EventBus.item_removed.emit(item_id, removed)
		backpack_changed.emit()
		return true

	return false

## 检查物品是否存在
func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_count(item_id) >= amount

## 获取物品数量
func get_item_count(item_id: String) -> int:
	var total = 0
	total += _count_in_slots(backpack, item_id)
	total += _count_in_slots(warehouse, item_id)
	return total

## 使用物品
func use_item(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= backpack.size():
		return false

	var slot = backpack[slot_index]
	if slot.is_empty():
		return false

	# TODO: 调用物品的使用逻辑
	# var item_data = ItemDatabase.get_item(slot.item_id)
	# if item_data and item_data.on_use():
	#     slot.quantity -= 1
	#     if slot.quantity <= 0:
	#         slot.clear()
	#     backpack_changed.emit()
	#     EventBus.item_used.emit(slot.item_id)
	#     return true

	return false

## 丢弃物品
func drop_item(slot_index: int, amount: int = 1) -> bool:
	if slot_index < 0 or slot_index >= backpack.size():
		return false

	var slot = backpack[slot_index]
	if slot.is_empty() or slot.quantity < amount:
		return false

	slot.quantity -= amount
	if slot.quantity <= 0:
		slot.clear()

	backpack_changed.emit()
	return true

## 丢弃所有物品
func drop_all_items(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= backpack.size():
		return false

	var slot = backpack[slot_index]
	if slot.is_empty():
		return false

	var item_id = slot.item_id
	slot.clear()

	backpack_changed.emit()
	EventBus.item_removed.emit(item_id, 1)  # 简化
	return true

# ============ 物品移动 ============

## 整理背包 (合并相同物品)
func organize_backpack() -> void:
	# 收集所有非空槽物品
	var items: Array = []
	for slot in backpack:
		if not slot.is_empty():
			items.append({"id": slot.item_id, "qty": slot.quantity})
			slot.clear()

	# 重新放入
	for item in items:
		add_item(item["id"], item["qty"])

## 仓库转移
func transfer_to_warehouse(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= backpack.size():
		return false
	if not has_warehouse:
		return false

	var slot = backpack[slot_index]
	if slot.is_empty():
		return false

	# 尝试添加到仓库
	var remaining = _add_to_existing_slots(warehouse, slot.item_id, slot.quantity)
	if remaining <= 0:
		slot.clear()
		backpack_changed.emit()
		return true

	remaining = _add_to_empty_slots(warehouse, slot.item_id, remaining)
	if remaining <= 0:
		slot.clear()
		backpack_changed.emit()
		return true

	# 仓库也满了
	return false

func transfer_to_backpack(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= warehouse.size():
		return false

	var slot = warehouse[slot_index]
	if slot.is_empty():
		return false

	# 尝试添加到背包
	var remaining = _add_to_existing_slots(backpack, slot.item_id, slot.quantity)
	if remaining <= 0:
		slot.clear()
		backpack_changed.emit()
		return true

	remaining = _add_to_empty_slots(backpack, slot.item_id, remaining)
	if remaining <= 0:
		slot.clear()
		backpack_changed.emit()
		return true

	return false

# ============ 背包扩展 ============

## 扩展背包容量
func expand_backpack(additional_slots: int) -> void:
	backpack_size += additional_slots
	for i in additional_slots:
		backpack.append(ItemSlot.new())
	backpack_changed.emit()

## 解锁仓库
func unlock_warehouse() -> void:
	has_warehouse = true
	backpack_changed.emit()

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
				"quantity": slot.quantity
			})
	return contents

## 获取空槽数量
func get_empty_slots() -> int:
	var count = 0
	for slot in backpack:
		if slot.is_empty():
			count += 1
	return count

## 获取已用槽数量
func get_used_slots() -> int:
	return backpack_size - get_empty_slots()

# ============ 存档支持 ============

## 获取存档数据
func get_save_data() -> Dictionary:
	var items: Array = []
	for slot in backpack:
		if not slot.is_empty():
			items.append({"id": slot.item_id, "qty": slot.quantity})

	var warehouse_items: Array = []
	if has_warehouse:
		for slot in warehouse:
			if not slot.is_empty():
				warehouse_items.append({"id": slot.item_id, "qty": slot.quantity})

	return {
		"backpack_size": backpack_size,
		"has_warehouse": has_warehouse,
		"items": items,
		"warehouse": warehouse_items
	}

## 加载存档数据
func load_save_data(data: Dictionary) -> void:
	_init_backpack()

	if "backpack_size" in data:
		backpack_size = data["backpack_size"]

	if "has_warehouse" in data:
		has_warehouse = data["has_warehouse"]
		if has_warehouse:
			_init_warehouse()

	if "items" in data:
		for item_data in data["items"]:
			add_item(item_data["id"], item_data["qty"])

	if "warehouse" in data and has_warehouse:
		for item_data in data["warehouse"]:
			_add_to_empty_slots(warehouse, item_data["id"], item_data["qty"])

	backpack_changed.emit()

# ============ 内部工具函数 ============

func _add_to_existing_slots(slots: Array, item_id: String, amount: int) -> int:
	var remaining = amount
	for slot in slots:
		if slot.item_id == item_id and remaining > 0:
			var can_add = MAX_STACK_SIZE - slot.quantity
			var to_add = mini(can_add, remaining)
			slot.quantity += to_add
			remaining -= to_add
	return remaining

func _add_to_empty_slots(slots: Array, item_id: String, amount: int) -> int:
	var remaining = amount
	for slot in slots:
		if slot.is_empty() and remaining > 0:
			var to_add = mini(MAX_STACK_SIZE, remaining)
			slot.item_id = item_id
			slot.quantity = to_add
			remaining -= to_add
	return remaining

func _remove_from_slots(slots: Array, item_id: String, amount: int) -> int:
	var remaining = amount
	for slot in slots:
		if slot.item_id == item_id and remaining > 0:
			var to_remove = mini(slot.quantity, remaining)
			slot.quantity -= to_remove
			remaining -= to_remove
			if slot.quantity <= 0:
				slot.clear()
	return amount - remaining

func _count_in_slots(slots: Array, item_id: String) -> int:
	var count = 0
	for slot in slots:
		if slot.item_id == item_id:
			count += slot.quantity
	return count

# ============ 配置应用 ============

## 应用玩家配置
func apply_config(config: PlayerConfig) -> void:
	if config == null:
		push_error("[InventorySystem] Cannot apply null config")
		return

	backpack_size = config.default_backpack_size
	max_stack_size = config.max_stack_size

	# 如果背包容量增加，扩展背包
	while backpack.size() < backpack_size:
		backpack.append(ItemSlot.new())

	push_warning("[InventorySystem] Config applied: backpack_size=%d" % backpack_size)
