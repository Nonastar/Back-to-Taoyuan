extends Node

## QuestSystem - 任务系统 MVP
## 管理主线任务 + 告示栏委托的状态和进度
## MVP 范围: 任务数据基础结构 + 接受/追踪/完成 API + 目标进度追踪
## 完整告示栏生成/特殊订单/奖励发放延期至后续 Sprint

# ============ 常量 ============

## 任务类型
enum QuestType {
	MAIN = 0,      # 主线任务
	DAILY = 1,     # 告示栏委托
	SPECIAL = 2    # 特殊订单（暂不实现）
}

## 任务状态
enum QuestState {
	PENDING = 0,    # 未接取（主线）
	AVAILABLE = 1,  # 可接取（告示栏）
	ACTIVE = 2,     # 进行中
	COMPLETED = 3,  # 已完成
	EXPIRED = 4     # 超时失败
}

## 主线任务数据（第一章前5个）
const MAIN_QUESTS_DATA: Array = [
	{
		"id": "main_1_1",
		"type": QuestType.MAIN,
		"title": "新的开始",
		"description": "收获5次作物",
		"target_type": "harvestCrops",
		"target_count": 5,
		"reward_money": 300,
		"reward_npc_id": "",
		"reward_friendship": 0,
		"reward_items": []
	},
	{
		"id": "main_1_2",
		"type": QuestType.MAIN,
		"title": "远亲不如近邻",
		"description": "与陈伯成为相识",
		"target_type": "npcFriendship",
		"target_id": "merchant_chen",
		"target_count": 1,
		"target_level": 1,  # acquaintance
		"reward_money": 200,
		"reward_npc_id": "merchant_chen",
		"reward_friendship": 20,
		"reward_items": []
	},
	{
		"id": "main_1_3",
		"type": QuestType.MAIN,
		"title": "溪边垂钓",
		"description": "累计钓到5条鱼",
		"target_type": "catchFish",
		"target_count": 5,
		"reward_money": 250,
		"reward_npc_id": "",
		"reward_friendship": 0,
		"reward_items": []
	},
	{
		"id": "main_1_4",
		"type": QuestType.MAIN,
		"title": "初探矿洞",
		"description": "到达第5层",
		"target_type": "reachMineFloor",
		"target_count": 5,
		"reward_money": 300,
		"reward_npc_id": "",
		"reward_friendship": 0,
		"reward_items": []
	},
	{
		"id": "main_1_5",
		"type": QuestType.MAIN,
		"title": "乡间美味",
		"description": "烹饪3道菜",
		"target_type": "cookRecipes",
		"target_count": 3,
		"reward_money": 200,
		"reward_npc_id": "",
		"reward_friendship": 0,
		"reward_items": []
	}
]

# ============ 信号 ============

signal quest_accepted(quest_id: String, quest_title: String)
signal quest_progress_updated(quest_id: String, progress: int, target: int)
signal quest_completed(quest_id: String, quest_title: String)
signal quest_expired(quest_id: String)

# ============ 状态 ============

## 任务数据 {quest_id: quest_dict}
var _quests: Dictionary = {}

## 已接取任务 {quest_id: {state, progress, accepted_at}}
var _active_quests: Dictionary = {}

## 已完成任务 ID 列表
var _completed_quest_ids: Array = []

# ============ 初始化 ============

func _ready() -> void:
	_initialize_quests()
	_connect_signals()
	print("[QuestSystem] Initialized with %d main quests" % _quests.size())

func _initialize_quests() -> void:
	# 加载主线任务数据
	for quest_data in MAIN_QUESTS_DATA:
		var quest_id = quest_data.get("id", "")
		if not quest_id.is_empty():
			_quests[quest_id] = quest_data.duplicate(true)
			# 默认所有主线任务为 PENDING 状态
			_quests[quest_id]["state"] = QuestState.PENDING
			_quests[quest_id]["progress"] = 0

func _connect_signals() -> void:
	# 监听 NPC 对话触发任务进度
	if EventBus:
		EventBus.npc_talked.connect(_on_npc_talked)
		EventBus.farm_crop_harvested.connect(_on_farm_crop_harvested)
		EventBus.fish_caught.connect(_on_fish_caught)
		EventBus.cooking_completed.connect(_on_cooking_completed)
		EventBus.mine_floor_reached.connect(_on_mine_floor_reached)
		EventBus.time_day_changed.connect(_on_day_changed)

# ============ 公共 API ============

## 获取所有任务（用于 UI 显示）
func get_all_quests() -> Array:
	return _quests.values()

## 获取指定任务
func get_quest(quest_id: String) -> Dictionary:
	return _quests.get(quest_id, {})

## 获取进行中的任务列表
func get_active_quests() -> Array:
	var result = []
	for quest_id in _active_quests.keys():
		if _quests.has(quest_id):
			result.append(_quests[quest_id])
	return result

## 接取任务
func accept_quest(quest_id: String) -> Dictionary:
	var validated = _validate_quest_for_accept(quest_id)
	if not validated.get("quest"):
		return {"success": false, "message": validated.get("message", "任务不存在")}

	# 接取任务
	var quest: Dictionary = validated["quest"]
	quest["state"] = QuestState.ACTIVE
	_active_quests[quest_id] = {
		"state": QuestState.ACTIVE,
		"progress": 0,
		"accepted_at": TimeManager.current_day if TimeManager else 0
	}
	quest_accepted.emit(quest_id, quest.get("title", quest_id))
	print("[QuestSystem] Quest accepted: %s" % quest_id)
	return {"success": true, "message": "任务接取成功"}

## 提交任务（完成目标后调用）
func complete_quest(quest_id: String) -> Dictionary:
	var validated = _validate_quest_for_complete(quest_id)
	if not validated.get("quest"):
		return {"success": false, "message": validated.get("message", "任务不存在")}

	var quest: Dictionary = validated["quest"]
	var progress: int = validated["progress"]
	var target: int = validated["target"]

	if progress < target:
		return {"success": false, "message": "任务目标未达成 (%d/%d)" % [progress, target]}

	# 完成任务
	quest["state"] = QuestState.COMPLETED
	_active_quests.erase(quest_id)
	_completed_quest_ids.append(quest_id)
	_award_rewards(quest_id)

	quest_completed.emit(quest_id, quest.get("title", quest_id))
	print("[QuestSystem] Quest completed: %s" % quest_id)

	# 如果是主线任务，自动初始化下一个
	if quest.get("type") == QuestType.MAIN:
		_activate_next_main_quest(quest_id)

	return {"success": true, "message": "任务完成！"}

## 查询任务进度
func get_quest_progress(quest_id: String) -> Dictionary:
	if not _quests.has(quest_id):
		return {"progress": 0, "target": 0, "state": -1}
	var quest = _quests[quest_id]
	return {
		"progress": quest.get("progress", 0),
		"target": quest.get("target_count", 1),
		"state": quest.get("state", QuestState.PENDING)
	}

## 更新任务进度（内部用 + 外部事件触发）
func add_progress(quest_id: String, amount: int = 1) -> void:
	if not _quests.has(quest_id):
		return
	if not _active_quests.has(quest_id):
		return

	var quest = _quests[quest_id]
	var new_progress = quest.get("progress", 0) + amount
	quest["progress"] = new_progress
	var target = quest.get("target_count", 1)

	quest_progress_updated.emit(quest_id, new_progress, target)
	print("[QuestSystem] Quest %s progress: %d/%d" % [quest_id, new_progress, target])

	# 如果达到目标，显示提示
	if new_progress >= target:
		if NotificationManager:
			NotificationManager.show_success("任务「%s」目标达成！" % quest.get("title", quest_id))

## 放弃任务
func abandon_quest(quest_id: String) -> Dictionary:
	if not _active_quests.has(quest_id):
		return {"success": false, "message": "该任务未接取"}

	var quest = _quests.get(quest_id, {})
	var quest_type = quest.get("type", QuestType.MAIN)

	quest["state"] = QuestState.PENDING if quest_type == QuestType.MAIN else QuestState.EXPIRED
	quest["progress"] = 0
	_active_quests.erase(quest_id)

	if quest_type == QuestType.MAIN:
		return {"success": true, "message": "已放弃任务"}
	else:
		return {"success": true, "message": "委托已过期"}

# ============ 私有方法 ============

## 接取任务验证（提取以降低 accept_quest 圈复杂度）
func _validate_quest_for_accept(quest_id: String) -> Dictionary:
	if not _quests.has(quest_id):
		return {"quest": null, "message": "任务不存在"}

	var quest = _quests[quest_id]
	# 已接取的检查优先（比状态检查更精确）
	if _active_quests.has(quest_id):
		return {"quest": null, "message": "该任务已在进行中"}

	var state = quest.get("state", QuestState.PENDING)
	if quest.get("type") == QuestType.MAIN and state != QuestState.PENDING:
		return {"quest": null, "message": "该任务不可接取"}
	if quest.get("type") == QuestType.DAILY and state != QuestState.AVAILABLE:
		return {"quest": null, "message": "该任务不在告示栏上"}
	if _active_quests.has(quest_id):
		return {"quest": null, "message": "该任务已在进行中"}

	return {"quest": quest}

## 完成任务验证（提取以降低 complete_quest 圈复杂度）
func _validate_quest_for_complete(quest_id: String) -> Dictionary:
	if not _quests.has(quest_id):
		return {"quest": null, "message": "任务不存在"}
	if not _active_quests.has(quest_id):
		return {"quest": null, "message": "该任务未接取"}

	var quest = _quests[quest_id]
	return {
		"quest": quest,
		"progress": quest.get("progress", 0),
		"target": quest.get("target_count", 1)
	}

func _award_rewards(quest_id: String) -> void:
	var quest = _quests.get(quest_id, {})
	var reward_money = quest.get("reward_money", 0)
	var reward_npc = quest.get("reward_npc_id", "")
	var reward_friendship = quest.get("reward_friendship", 0)
	var reward_items = quest.get("reward_items", [])

	# 发放金钱
	if reward_money > 0 and PlayerStats:
		PlayerStats.earn_money(reward_money)

	# 发放好感度（不受每日对话限制）
	if not reward_npc.is_empty() and reward_friendship > 0 and NpcFriendshipSystem:
		NpcFriendshipSystem.add_friendship(reward_npc, reward_friendship)

	# 发放物品
	for item_data in reward_items:
		var item_id = item_data.get("id", "")
		var qty = item_data.get("quantity", 1)
		if not item_id.is_empty() and InventorySystem:
			InventorySystem.add_item(item_id, qty)

func _activate_next_main_quest(completed_quest_id: String) -> void:
	# 找到当前任务在列表中的位置
	var idx = -1
	for i in range(MAIN_QUESTS_DATA.size()):
		if MAIN_QUESTS_DATA[i].get("id") == completed_quest_id:
			idx = i
			break

	# 激活下一个任务
	if idx >= 0 and idx + 1 < MAIN_QUESTS_DATA.size():
		var next_quest_data = MAIN_QUESTS_DATA[idx + 1]
		var next_id = next_quest_data.get("id", "")
		if _quests.has(next_id):
			_quests[next_id]["state"] = QuestState.PENDING
			print("[QuestSystem] Next main quest unlocked: %s" % next_id)

# ============ 事件回调 ============

func _on_npc_talked(npc_id: String, _gain: int) -> void:
	# 检查 npcFriendship 类型任务
	for quest_id in _active_quests.keys():
		var quest = _quests.get(quest_id, {})
		if quest.get("target_type") == "npcFriendship":
			if quest.get("target_id") == npc_id and NpcFriendshipSystem:
				var level = NpcFriendshipSystem.get_friendship_level(npc_id)
				var target_level = quest.get("target_level", 0)
				if level >= target_level:
					add_progress(quest_id)

func _on_farm_crop_harvested(_plot_id: String, _crop_id: String, _quantity: int, _quality: int) -> void:
	# 检查 harvestCrops 类型任务
	for quest_id in _active_quests.keys():
		var quest = _quests.get(quest_id, {})
		if quest.get("target_type") == "harvestCrops":
			add_progress(quest_id, 1)

func _on_fish_caught(_fish_id: String, quantity: int, _quality: int) -> void:
	# 检查 catchFish 类型任务
	for quest_id in _active_quests.keys():
		var quest = _quests.get(quest_id, {})
		if quest.get("target_type") == "catchFish":
			add_progress(quest_id, quantity)

func _on_cooking_completed(_recipe_id: String) -> void:
	# 检查 cookRecipes 类型任务
	for quest_id in _active_quests.keys():
		var quest = _quests.get(quest_id, {})
		if quest.get("target_type") == "cookRecipes":
			add_progress(quest_id, 1)

func _on_mine_floor_reached(floor: int) -> void:
	# 检查 reachMineFloor 类型任务（取最深到达层）
	for quest_id in _active_quests.keys():
		var quest = _quests.get(quest_id, {})
		if quest.get("target_type") == "reachMineFloor":
			var current_progress = quest.get("progress", 0)
			if floor > current_progress:
				add_progress(quest_id, floor - current_progress)

func _on_day_changed(_day: int, _season: String, _year: int) -> void:
	# 每日检查告示栏委托超时
	pass  # 告示栏委托暂未实现

# ============ 存档支持 ============

func serialize() -> Dictionary:
	# 返回深拷贝，防止外部 .clear() 破坏序列化数据
	return {
		"quests": _quests.duplicate(true),
		"active_quests": _active_quests.duplicate(true),
		"completed_quest_ids": _completed_quest_ids.duplicate()
	}

func deserialize(data: Dictionary) -> void:
	_quests = data.get("quests", {})
	_active_quests = data.get("active_quests", {})
	_completed_quest_ids = data.get("completed_quest_ids", [])
	print("[QuestSystem] Loaded: %d quests, %d active" % [_quests.size(), _active_quests.size()])

# ============ 调试方法 ============

## 调试：完成指定任务（跳过目标检查，直接标记完成）
func debug_complete_quest(quest_id: String) -> void:
	if not _quests.has(quest_id):
		print("[QuestSystem] Quest not found: %s" % quest_id)
		return
	var quest = _quests[quest_id]
	quest["progress"] = quest.get("target_count", 1)
	quest["state"] = QuestState.COMPLETED
	_active_quests.erase(quest_id)
	_completed_quest_ids.append(quest_id)
	quest_completed.emit(quest_id, quest.get("title", quest_id))
	print("[QuestSystem] DEBUG Quest completed: %s" % quest_id)

## 调试：接取所有主线任务
func debug_accept_all_main_quests() -> void:
	for quest_id in _quests.keys():
		var quest = _quests[quest_id]
		if quest.get("type") == QuestType.MAIN and quest.get("state") == QuestState.PENDING:
			accept_quest(quest_id)
			quest["progress"] = quest.get("target_count", 1) - 1  # 留一个用于测试
			_active_quests[quest_id]["progress"] = quest["progress"]

## 调试：获取任务状态摘要
func debug_get_status() -> Dictionary:
	var status = {
		"total": _quests.size(),
		"active": _active_quests.size(),
		"completed": _completed_quest_ids.size(),
		"quests": []
	}
	for quest_id in _quests.keys():
		var q = _quests[quest_id]
		status["quests"].append({
			"id": quest_id,
			"title": q.get("title", ""),
			"state": q.get("state", -1),
			"progress": q.get("progress", 0),
			"target": q.get("target_count", 1)
		})
	return status