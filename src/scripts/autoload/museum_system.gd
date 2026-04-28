extends Node
## MuseumSystem - 博物馆系统
## 40件可捐赠展品、8个里程碑奖励
## 参考: design/gdd/feature/museum-system.md

# ============ Feature Flags（延后功能） ============

## 里程碑奖励发放 — 延至 Sprint 10
const FEATURE_MILESTONE_REWARDS_ENABLED: bool = false

# ============ 里程碑状态常量 ============
## 使用 int 而非 enum（遵循项目规范）

const MILESTONE_LOCKED: int = 0
const MILESTONE_CLAIMABLE: int = 1
const MILESTONE_CLAIMED: int = 2

# ============ 40件博物馆展品定义 ============

const MUSEUM_ITEMS: Array[Dictionary] = [
	# 矿石 (7件)
	{"id": "copper_ore", "name": "铜矿", "category": "ore"},
	{"id": "iron_ore", "name": "铁矿", "category": "ore"},
	{"id": "gold_ore", "name": "金矿", "category": "ore"},
	{"id": "crystal_ore", "name": "水晶矿", "category": "ore"},
	{"id": "iridium_ore", "name": "铱矿", "category": "ore"},
	{"id": "shadow_ore", "name": "暗影矿", "category": "ore"},
	{"id": "void_ore", "name": "虚空矿", "category": "ore"},

	# 宝石 (7件)
	{"id": "quartz", "name": "石英", "category": "gem"},
	{"id": "emerald", "name": "翡翠", "category": "gem"},
	{"id": "ruby", "name": "红宝石", "category": "gem"},
	{"id": "moonstone", "name": "月光石", "category": "gem"},
	{"id": "obsidian", "name": "黑曜石", "category": "gem"},
	{"id": "dragon_jade", "name": "龙玉", "category": "gem"},
	{"id": "rainbow_shard", "name": "五彩碎片", "category": "gem"},

	# 金属锭 (4件)
	{"id": "copper_bar", "name": "铜锭", "category": "bar"},
	{"id": "iron_bar", "name": "铁锭", "category": "bar"},
	{"id": "gold_bar", "name": "金锭", "category": "bar"},
	{"id": "iridium_bar", "name": "铱锭", "category": "bar"},

	# 化石 (8件)
	{"id": "trilobite", "name": "三叶虫化石", "category": "fossil"},
	{"id": "amber", "name": "琥珀", "category": "fossil"},
	{"id": "ammonite", "name": "菊石化石", "category": "fossil"},
	{"id": "fern_fossil", "name": "蕨叶化石", "category": "fossil"},
	{"id": "mammoth_skull", "name": "猛犸象头骨化石", "category": "fossil"},
	{"id": "shark_tooth", "name": "鲨鱼牙化石", "category": "fossil"},
	{"id": "ancient_drum", "name": "远古石鼓", "category": "fossil"},
	{"id": "dinosaur_egg", "name": "恐龙蛋化石", "category": "fossil"},

	# 古物 (10件)
	{"id": "ancient_pottery", "name": "古陶片", "category": "artifact"},
	{"id": "jade_fragment", "name": "玉璧残片", "category": "artifact"},
	{"id": "bronze_mirror", "name": "铜镜", "category": "artifact"},
	{"id": "ancient_coin", "name": "远古铜钱", "category": "artifact"},
	{"id": "bronze_sword", "name": "古青铜剑", "category": "artifact"},
	{"id": "ancient_arrow", "name": "古箭簇", "category": "artifact"},
	{"id": "seal_carving", "name": "古印篆", "category": "artifact"},
	{"id": "ritual_vessel", "name": "礼器", "category": "artifact"},
	{"id": "ancient_bell", "name": "古钟", "category": "artifact"},
	{"id": "jade_conch", "name": "玉螺", "category": "artifact"},

	# 仙灵物品 (4件)
	{"id": "fox_bead", "name": "狐珠", "category": "spirit"},
	{"id": "spirit_peach", "name": "灵桃", "category": "spirit"},
	{"id": "moon_herb", "name": "月草", "category": "spirit"},
	{"id": "dream_silk", "name": "梦丝", "category": "spirit"}
]

# ============ 8个里程碑定义 ============

const MILESTONES: Array[Dictionary] = [
	{"count": 5, "name": "初窥门径", "money": 300, "item": null, "item_count": 0},
	{"count": 10, "name": "小有收藏", "money": 500, "item": "ancient_seed", "item_count": 1},
	{"count": 15, "name": "矿石鉴赏家", "money": 1000, "item": null, "item_count": 0},
	{"count": 20, "name": "博古通今", "money": 1500, "item": "rainbow_shard", "item_count": 1},
	{"count": 25, "name": "文物守护者", "money": 3000, "item": null, "item_count": 0},
	{"count": 30, "name": "远古探秘", "money": 5000, "item": "iridium_bar", "item_count": 3},
	{"count": 36, "name": "博物馆之星", "money": 10000, "item": null, "item_count": 0},
	{"count": 40, "name": "灵物全鉴", "money": 8000, "item": "moonstone", "item_count": 3}
]

# ============ 单例 ============

static var _instance = null

static func get_instance():
	return _instance

# ============ 信号 ============

## 物品捐赠成功
signal item_donated(item_id: String)

## 里程碑达成（可领取）
signal milestone_reached(count: int)

## 里程碑奖励已领取
signal milestone_claimed(count: int)

## 博物馆全部完成
signal museum_complete()

# ============ 状态 ============

## 已捐赠物品集合
var _donated_items: Array[String] = []

## 已领取里程碑数量集合
var _claimed_milestones: Array[int] = []

## 物品ID到索引的映射（用于快速查找）
var _item_id_to_index: Dictionary = {}

# ============ 初始化 ============

func _ready() -> void:
	_instance = self
	_build_item_index()
	_connect_signals()
	print("[MuseumSystem] Initialized with %d museum items and %d milestones" % [MUSEUM_ITEMS.size(), MILESTONES.size()])

## 构建物品ID到索引的映射
func _build_item_index() -> void:
	_item_id_to_index.clear()
	for i in MUSEUM_ITEMS.size():
		var item = MUSEUM_ITEMS[i]
		_item_id_to_index[item["id"]] = i

## 连接信号
func _connect_signals() -> void:
	# 连接 EventBus 的背包变化信号（用于检测物品获得）
	if EventBus and EventBus.has_signal("item_added"):
		# EventBus.item_added.connect(_on_item_added)  # 博物馆不需要监听物品获得
		pass
	print("[MuseumSystem] Signals connected")

# ============ 捐赠 API ============

## 检查物品是否可以捐赠
func can_donate(item_id: String) -> bool:
	# 物品在博物馆列表中
	if not _is_museum_item(item_id):
		return false
	# 物品未被捐赠
	if is_donated(item_id):
		return false
	# 背包中有该物品
	if _check_inventory_available(item_id):
		return true
	return false

## 捐赠物品
func donate_item(item_id: String) -> bool:
	if not can_donate(item_id):
		return false

	# 扣除背包物品
	if not _remove_from_inventory(item_id, 1):
		push_warning("[MuseumSystem] Failed to remove item from inventory: %s" % item_id)
		return false

	# 添加到已捐赠列表
	_donated_items.append(item_id)

	# 获取展品名称用于日志
	var item_name = get_item_name(item_id)
	print("[MuseumSystem] Donated: %s (%s)" % [item_name, item_id])

	# 发送信号
	item_donated.emit(item_id)

	# 检查里程碑
	_check_milestones()

	# 检查是否全部完成
	if get_donated_count() >= 40:
		museum_complete.emit()
		print("[MuseumSystem] Museum complete!")

	return true

## 检查物品是否已捐赠
func is_donated(item_id: String) -> bool:
	return item_id in _donated_items

## 获取可捐赠物品列表（背包中有的未捐赠物品）
func get_donatable_items() -> Array:
	var result = []
	for item in MUSEUM_ITEMS:
		var item_id = item["id"]
		if not is_donated(item_id) and _check_inventory_available(item_id):
			result.append(item.duplicate())
	return result

## 获取已捐赠物品列表
func get_donated_items() -> Array:
	var result = []
	for item_id in _donated_items:
		var item_info = get_item_info(item_id)
		if item_info != null:
			result.append(item_info.duplicate())
	return result

# ============ 里程碑 API ============

## 获取已捐赠数量
func get_donated_count() -> int:
	return _donated_items.size()

## 获取总展品数量
func get_total_count() -> int:
	return MUSEUM_ITEMS.size()

## 获取可领取的里程碑列表
func get_claimable_milestones() -> Array:
	var result = []
	for milestone in MILESTONES:
		var count = milestone["count"]
		if get_milestone_state(count) == MILESTONE_CLAIMABLE:
			result.append(milestone.duplicate())
	return result

## 领取里程碑奖励
func claim_milestone(count: int) -> bool:
	# 检查里程碑是否存在
	var milestone = _get_milestone_by_count(count)
	if milestone == null:
		push_warning("[MuseumSystem] Milestone not found: %d" % count)
		return false

	# 检查是否可领取
	if get_milestone_state(count) != MILESTONE_CLAIMABLE:
		return false

	# 发放奖励
	_issue_milestone_reward(milestone)

	# 标记已领取
	_claimed_milestones.append(count)

	# 发送信号
	milestone_claimed.emit(count)
	print("[MuseumSystem] Claimed milestone: %s (%d items)" % [milestone["name"], count])

	return true

## 获取里程碑状态
func get_milestone_state(count: int) -> int:
	var donated_count = get_donated_count()
	if donated_count < count:
		return MILESTONE_LOCKED
	if count in _claimed_milestones:
		return MILESTONE_CLAIMED
	return MILESTONE_CLAIMABLE

## 获取所有里程碑状态
func get_all_milestone_states() -> Array:
	var result = []
	for milestone in MILESTONES:
		var count = milestone["count"]
		result.append({
			"count": count,
			"name": milestone["name"],
			"state": get_milestone_state(count),
			"money": milestone["money"],
			"item": milestone["item"],
			"item_count": milestone["item_count"]
		})
	return result

# ============ 查询 API ============

## 获取捐赠进度
func get_donation_progress() -> Dictionary:
	var current = get_donated_count()
	var total = get_total_count()
	var percentage = 0.0
	if total > 0:
		percentage = float(current) / float(total) * 100.0
	return {
		"current": current,
		"total": total,
		"percentage": percentage
	}

## 获取物品信息
func get_item_info(item_id: String) -> Dictionary:
	for item in MUSEUM_ITEMS:
		if item["id"] == item_id:
			return item.duplicate()
	return {}

## 获取物品名称
func get_item_name(item_id: String) -> String:
	var info = get_item_info(item_id)
	if info != null and not info.is_empty():
		return info.get("name", item_id)
	return item_id

## 获取物品分类
func get_item_category(item_id: String) -> String:
	var info = get_item_info(item_id)
	if info != null and not info.is_empty():
		return info.get("category", "")
	return ""

## 按分类获取物品
func get_items_by_category(category: String) -> Array:
	var result = []
	for item in MUSEUM_ITEMS:
		if item["category"] == category:
			result.append(item.duplicate())
	return result

## 获取分类列表
func get_categories() -> Array:
	var categories = []
	for item in MUSEUM_ITEMS:
		var cat = item["category"]
		if cat not in categories:
			categories.append(cat)
	return categories

# ============ 存档 API ============

## 序列化存档数据
func serialize() -> Dictionary:
	return {
		"donated_items": _donated_items.duplicate(),
		"claimed_milestones": _claimed_milestones.duplicate()
	}

## 反序列化加载存档数据
func deserialize(data: Dictionary) -> void:
	_donated_items.assign(data.get("donated_items", []))
	_claimed_milestones.assign(data.get("claimed_milestones", []))
	print("[MuseumSystem] Loaded: donated=%d, claimed=%d" % [_donated_items.size(), _claimed_milestones.size()])

# ============ 内部方法 ============

## 检查是否是博物馆物品
func _is_museum_item(item_id: String) -> bool:
	return _item_id_to_index.has(item_id)

## 检查背包中是否有该物品
func _check_inventory_available(item_id: String) -> bool:
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		if inv.has_method("has_item"):
			return inv.has_item(item_id, 1)
		# 回退：通过 ItemDataSystem 检查物品是否存在
		if ItemDataSystem and ItemDataSystem.item_exists(item_id):
			return true
	return false

## 从背包移除物品
func _remove_from_inventory(item_id: String, amount: int) -> bool:
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		if inv.has_method("remove_item"):
			return inv.remove_item(item_id, amount)
	return false

## 检查里程碑
func _check_milestones() -> void:
	for milestone in MILESTONES:
		var count = milestone["count"]
		if get_milestone_state(count) == MILESTONE_CLAIMABLE:
			# 检查是否已经在通知列表中（避免重复发送）
			if count not in _claimed_milestones:
				milestone_reached.emit(count)
				print("[MuseumSystem] Milestone reached: %s (%d items)" % [milestone["name"], count])

## 根据捐赠数量获取里程碑
func _get_milestone_by_count(count: int) -> Dictionary:
	for milestone in MILESTONES:
		if milestone["count"] == count:
			return milestone
	return {}

## 发放里程碑奖励
func _issue_milestone_reward(milestone: Dictionary) -> void:
	if not FEATURE_MILESTONE_REWARDS_ENABLED:
		print("[MuseumSystem] Milestone rewards disabled — milestone: %s" % milestone.get("name", ""))
		return

	# 发放金钱
	var money = milestone.get("money", 0)
	if money > 0:
		if PlayerStats != null and PlayerStats.has_method("earn_money"):
			PlayerStats.earn_money(money)
			print("[MuseumSystem] Earned money: %dg" % money)
		else:
			push_warning("[MuseumSystem] PlayerStats.earn_money not available")

	# 发放物品
	var item_id = milestone.get("item", null)
	var item_count = milestone.get("item_count", 0)
	if item_id != null and item_count > 0:
		var inv = get_node_or_null("/root/InventorySystem")
		if inv:
			if inv.has_method("add_item"):
				for i in item_count:
					inv.add_item(item_id, 1, Quality.NORMAL)
				print("[MuseumSystem] Received item: %s x%d" % [item_id, item_count])
			else:
				push_warning("[MuseumSystem] InventorySystem.add_item not available")
		else:
			push_warning("[MuseumSystem] InventorySystem singleton not available")

# ============ 调试 ============

## 调试打印所有展品状态
func debug_print_all() -> void:
	print("[MuseumSystem] === Museum Items ===")
	for category in get_categories():
		print("  [%s]" % category)
		var items = get_items_by_category(category)
		for item in items:
			var donated = is_donated(item["id"])
			print("    %s %s: %s" % ["✓" if donated else "?", item["name"], item["id"]])
	print("[MuseumSystem] Progress: %d/%d (%.1f%%)" % [get_donation_progress()["current"], get_donation_progress()["total"], get_donation_progress()["percentage"]])
	print("[MuseumSystem] === Milestones ===")
	for ms in get_all_milestone_states():
		var state_names = ["LOCKED", "CLAIMABLE", "CLAIMED"]
		print("  [%s] %s (count=%d, money=%d, item=%s)" % [state_names[ms["state"]], ms["name"], ms["count"], ms["money"], ms["item"]])
