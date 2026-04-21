extends Node

## NpcFriendshipSystem - NPC好感度系统 MVP
## 管理 NPC 数据结构和好感度计算
## MVP 范围: NPC数据基础结构 + 好感度查询/变化 API + 与商店系统对接
## 完整对话/恋爱/结婚系统延期至后续 Sprint

# ============ 常量 ============

## 好感度常量
const FRIENDSHIP_MAX: int = 2500
const FRIENDSHIP_PER_HEART: int = 250  # 每心好感度
const TALK_GAIN: int = 20  # 对话好感增加

## 好感度等级
enum FriendshipLevel {
	STRANGER = 0,    # 陌生人 0-499
	ACQUAINTANCE = 1,  # 熟人 500-999
	FRIENDLY = 2,    # 友好 1000-1999
	BEST_FRIEND = 3  # 挚友 2000-2500
}

## 等级阈值
const LEVEL_THRESHOLDS: Dictionary = {
	FriendshipLevel.STRANGER: {"min": 0, "max": 499},
	FriendshipLevel.ACQUAINTANCE: {"min": 500, "max": 999},
	FriendshipLevel.FRIENDLY: {"min": 1000, "max": 1999},
	FriendshipLevel.BEST_FRIEND: {"min": 2000, "max": 2500}
}

# ============ 信号 ============

signal friendship_changed(npc_id: String, old_value: int, new_value: int)
signal npc_talked(npc_id: String, gain: int)
signal npc_gifted(npc_id: String, item_id: String, gain: int, reaction: String)
signal heart_event_triggered(npc_id: String, event_id: String)

# ============ 状态 ============

## NPC 数据 {npc_id: NpcData}
var _npcs: Dictionary = {}

## 每日对话状态 {npc_id: bool}
var _talked_today: Dictionary = {}

## 每日送礼状态 {npc_id: int} 今日已送礼次数
var _gifted_today: Dictionary = {}

## 商店折扣缓存 {npc_id: float} 0.0-0.2 (0%-20%折扣)
var _discount_cache: Dictionary = {}

# ============ 初始化 ============

func _ready() -> void:
	_initialize_npcs()
	_connect_time_signals()
	print("[NpcFriendshipSystem] Initialized with %d NPCs" % _npcs.size())

func _connect_time_signals() -> void:
	if EventBus and EventBus.has_signal("time_sleep_triggered"):
		EventBus.time_sleep_triggered.connect(_on_sleep_triggered)

func _on_sleep_triggered(_bedtime: int, _forced: bool) -> void:
	_daily_reset()

func _daily_reset() -> void:
	_talked_today.clear()
	_gifted_today.clear()
	_discount_cache.clear()

# ============ 公共 API ============

## 获取 NPC 列表
func get_all_npcs() -> Array:
	return _npcs.values()

## 获取指定 NPC 数据
func get_npc(npc_id: String) -> Dictionary:
	return _npcs.get(npc_id, {})

## 检查 NPC 是否存在
func has_npc(npc_id: String) -> bool:
	return _npcs.has(npc_id)

## 获取 NPC 好感度
func get_friendship(npc_id: String) -> int:
	var npc = _npcs.get(npc_id, {})
	return npc.get("friendship", 0)

## 获取好感度等级名称
func get_friendship_level_name(npc_id: String) -> String:
	var level = get_friendship_level(npc_id)
	match level:
		FriendshipLevel.STRANGER: return "陌生人"
		FriendshipLevel.ACQUAINTANCE: return "熟人"
		FriendshipLevel.FRIENDLY: return "友好"
		FriendshipLevel.BEST_FRIEND: return "挚友"
	return "陌生人"

## 获取好感度等级枚举
func get_friendship_level(npc_id: String) -> FriendshipLevel:
	var friendship = get_friendship(npc_id)
	if friendship >= 2000:
		return FriendshipLevel.BEST_FRIEND
	elif friendship >= 1000:
		return FriendshipLevel.FRIENDLY
	elif friendship >= 500:
		return FriendshipLevel.ACQUAINTANCE
	return FriendshipLevel.STRANGER

## 获取好感度进度 (0.0-1.0)
func get_friendship_progress(npc_id: String) -> float:
	var friendship = get_friendship(npc_id)
	var level = get_friendship_level(npc_id)
	var thresholds = LEVEL_THRESHOLDS[level]
	var range_size = thresholds["max"] - thresholds["min"]
	if range_size <= 0:
		return 1.0
	return clamp(float(friendship - thresholds["min"]) / float(range_size), 0.0, 1.0)

## 与 NPC 对话 (每日一次)
func talk_to(npc_id: String) -> Dictionary:
	if not _npcs.has(npc_id):
		return {"success": false, "message": "NPC不存在"}

	if _talked_today.get(npc_id, false):
		return {"success": false, "message": "今日已对话"}

	_talked_today[npc_id] = true
	var old = get_friendship(npc_id)
	var new = _modify_friendship(npc_id, TALK_GAIN)
	npc_talked.emit(npc_id, TALK_GAIN)

	return {
		"success": true,
		"friendship_gain": TALK_GAIN,
		"new_friendship": new,
		"message": "对话成功"
	}

## 检查今日是否已对话
func has_talked_today(npc_id: String) -> bool:
	return _talked_today.get(npc_id, false)

## 检查今日是否已送礼
func get_gift_count_today(npc_id: String) -> int:
	return _gifted_today.get(npc_id, 0)

## 获取商店折扣 (0.0-0.2)
func get_shop_discount(npc_id: String) -> float:
	if _discount_cache.has(npc_id):
		return _discount_cache[npc_id]
	var level = get_friendship_level(npc_id)
	var discount = 0.0
	match level:
		FriendshipLevel.BEST_FRIEND: discount = 0.20
		FriendshipLevel.FRIENDLY: discount = 0.10
		_:
			discount = 0.0
	_discount_cache[npc_id] = discount
	return discount

# ============ 私有方法 ============

func _initialize_npcs() -> void:
	# 从 NPC 数据文件加载或使用默认数据
	var npc_list = _load_npc_data()
	for npc_data in npc_list:
		var npc_id = npc_data.get("id", "")
		if not npc_id.is_empty():
			_npcs[npc_id] = npc_data

func _load_npc_data() -> Array:
	# 尝试从 JSON 加载
	if DataLoader:
		var data = DataLoader.load_json("npc_data.json")
		if data.has("npcs"):
			return data["npcs"]
	# 默认 NPC 数据 (12个可婚NPC)
	return [
		{"id": "linxia", "name": "林霞", "gender": "female", "location": "village_center", "friendship": 0},
		{"id": "zhangwei", "name": "张伟", "gender": "male", "location": "farm", "friendship": 0},
		{"id": "wenhui", "name": "文辉", "gender": "male", "location": "library", "friendship": 0},
		{"id": "fenghua", "name": "冯华", "gender": "female", "location": "forest", "friendship": 0},
		{"id": "junior", "name": "阿俊", "gender": "male", "location": "river", "friendship": 0},
		{"id": "xiaomei", "name": "小梅", "gender": "female", "location": "mountain", "friendship": 0},
		{"id": "oldman_zhao", "name": "老赵", "gender": "male", "location": "village_east", "friendship": 0},
		{"id": "aunt_wang", "name": "王婶", "gender": "female", "location": "village_west", "friendship": 0},
		{"id": "teacher_lin", "name": "林老师", "gender": "female", "location": "school", "friendship": 0},
		{"id": "traveler_yu", "name": "旅人阿宇", "gender": "male", "location": "travel", "friendship": 0},
		{"id": "merchant_chen", "name": "商人陈", "gender": "male", "location": "market", "friendship": 0},
		{"id": "healer_xu", "name": "徐大夫", "gender": "male", "location": "clinic", "friendship": 0}
	]

func _modify_friendship(npc_id: String, delta: int) -> int:
	var old = get_friendship(npc_id)
	var new_val = clamp(old + delta, 0, FRIENDSHIP_MAX)
	if _npcs.has(npc_id):
		_npcs[npc_id]["friendship"] = new_val
		# 清除折扣缓存，好感度变化后重新计算
		if _discount_cache.has(npc_id):
			_discount_cache.erase(npc_id)
	friendship_changed.emit(npc_id, old, new_val)
	return new_val

# ============ 存档支持 ============

func serialize() -> Dictionary:
	return {
		"npcs": _npcs,
		"talked_today": _talked_today,
		"gifted_today": _gifted_today
	}

func deserialize(data: Dictionary) -> void:
	_npcs = data.get("npcs", {})
	_talked_today = data.get("talked_today", {})
	_gifted_today = data.get("gifted_today", {})
	_discount_cache.clear()
	print("[NpcFriendshipSystem] Loaded %d NPCs" % _npcs.size())