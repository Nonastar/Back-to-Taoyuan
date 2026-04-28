extends Node

## AchievementSystem - 成就系统
## 管理玩家成就解锁、物品图鉴发现和完美度计算
## 参考: design/gdd/feature/achievement-system.md

# ============ Feature Flags（延后功能） ============

## 完美度系统 — 延至 Sprint 11
const FEATURE_PERFECTION_ENABLED: bool = false

# ============ 成就状态枚举 ============

enum AchievementState {
	LOCKED = 0,
	COMPLETED = 1
}

# ============ 成就定义 (50+ 个) ============

const ACHIEVEMENTS: Array[Dictionary] = [
	# ---- 收集类 (6个) ----
	{"id": "col_1",   "name": "初次发现",  "desc": "发现第一件物品",             "category": "collection", "condition": {"type": "itemCount",    "count": 1}},
	{"id": "col_5",   "name": "收藏入门",  "desc": "收集5件物品",                "category": "collection", "condition": {"type": "itemCount",    "count": 5}},
	{"id": "col_10",  "name": "小有收藏",  "desc": "收集10件物品",               "category": "collection", "condition": {"type": "itemCount",    "count": 10}},
	{"id": "col_20",  "name": "收藏家",    "desc": "收集20件物品",               "category": "collection", "condition": {"type": "itemCount",    "count": 20}},
	{"id": "col_40",  "name": "收藏达人",  "desc": "收集40件物品",               "category": "collection", "condition": {"type": "itemCount",    "count": 40}},
	{"id": "col_80",  "name": "收藏大家",  "desc": "收集80件物品",               "category": "collection", "condition": {"type": "itemCount",    "count": 80}},

	# ---- 农耕类 (6个) ----
	{"id": "farm_10",  "name": "农耕入门",  "desc": "收获10棵作物",               "category": "farming",    "condition": {"type": "cropHarvest",  "count": 10}},
	{"id": "farm_50",  "name": "农田耕耘者","desc": "收获50棵作物",               "category": "farming",    "condition": {"type": "cropHarvest",  "count": 50}},
	{"id": "farm_100", "name": "丰收在望", "desc": "收获100棵作物",              "category": "farming",    "condition": {"type": "cropHarvest",  "count": 100}},
	{"id": "farm_200", "name": "农场主",   "desc": "收获200棵作物",              "category": "farming",    "condition": {"type": "cropHarvest",  "count": 200}},
	{"id": "farm_500", "name": "农业大师", "desc": "收获500棵作物",              "category": "farming",    "condition": {"type": "cropHarvest",  "count": 500}},
	{"id": "farm_1000","name": "农神",     "desc": "收获1000棵作物",             "category": "farming",    "condition": {"type": "cropHarvest",  "count": 1000}},

	# ---- 钓鱼类 (6个) ----
	{"id": "fish_1",   "name": "初尝垂钓",  "desc": "钓到第一条鱼",              "category": "fishing",    "condition": {"type": "fishCaught",   "count": 1}},
	{"id": "fish_5",   "name": "钓鱼新手",  "desc": "钓到5条鱼",                 "category": "fishing",    "condition": {"type": "fishCaught",   "count": 5}},
	{"id": "fish_20",  "name": "钓鱼达人",  "desc": "钓到20条鱼",                "category": "fishing",    "condition": {"type": "fishCaught",   "count": 20}},
	{"id": "fish_50",  "name": "渔夫",      "desc": "钓到50条鱼",                "category": "fishing",    "condition": {"type": "fishCaught",   "count": 50}},
	{"id": "fish_100", "name": "钓鱼高手",  "desc": "钓到100条鱼",               "category": "fishing",    "condition": {"type": "fishCaught",   "count": 100}},
	{"id": "fish_500", "name": "鱼王",      "desc": "钓到500条鱼",               "category": "fishing",    "condition": {"type": "fishCaught",   "count": 500}},

	# ---- 采矿类 (5个) ----
	{"id": "mine_5",   "name": "初探矿洞",  "desc": "到达第5层",                 "category": "mining",     "condition": {"type": "mineFloor",    "floor": 5}},
	{"id": "mine_15",  "name": "矿工",      "desc": "到达第15层",                "category": "mining",     "condition": {"type": "mineFloor",    "floor": 15}},
	{"id": "mine_30",  "name": "矿工长",    "desc": "到达第30层",                "category": "mining",     "condition": {"type": "mineFloor",    "floor": 30}},
	{"id": "mine_50",  "name": "采矿达人",  "desc": "到达第50层",                "category": "mining",     "condition": {"type": "mineFloor",    "floor": 50}},
	{"id": "mine_100", "name": "矿脉探索者","desc": "到达第100层",               "category": "mining",     "condition": {"type": "mineFloor",    "floor": 100}},

	# ---- 金钱类 (5个) ----
	{"id": "money_1k",   "name": "略有积蓄",  "desc": "累计获得1000金币",          "category": "money",      "condition": {"type": "moneyEarned",  "amount": 1000}},
	{"id": "money_10k",  "name": "小康之家",  "desc": "累计获得10000金币",         "category": "money",      "condition": {"type": "moneyEarned",  "amount": 10000}},
	{"id": "money_50k",  "name": "富甲一方",  "desc": "累计获得50000金币",         "category": "money",      "condition": {"type": "moneyEarned",  "amount": 50000}},
	{"id": "money_100k", "name": "财主",     "desc": "累计获得100000金币",         "category": "money",      "condition": {"type": "moneyEarned",  "amount": 100000}},
	{"id": "money_500k", "name": "富豪",     "desc": "累计获得500000金币",         "category": "money",      "condition": {"type": "moneyEarned",  "amount": 500000}},

	# ---- 烹饪类 (4个) ----
	{"id": "cook_1",   "name": "初试厨艺",  "desc": "烹饪1道菜",                  "category": "cooking",     "condition": {"type": "recipesCooked", "count": 1}},
	{"id": "cook_10",  "name": "家常厨师",  "desc": "烹饪10道菜",                "category": "cooking",     "condition": {"type": "recipesCooked", "count": 10}},
	{"id": "cook_50",  "name": "名厨",      "desc": "烹饪50道菜",                "category": "cooking",     "condition": {"type": "recipesCooked", "count": 50}},
	{"id": "cook_100", "name": "厨神",      "desc": "烹饪100道菜",               "category": "cooking",     "condition": {"type": "recipesCooked", "count": 100}},

	# ---- 技能等级类 (8个) ----
	{"id": "skill_farm_5",   "name": "农夫",        "desc": "农耕技能达到5级",         "category": "skill",      "condition": {"type": "skillLevel",     "skill": "farming",  "level": 5}},
	{"id": "skill_farm_10",  "name": "农业专家",    "desc": "农耕技能达到10级",        "category": "skill",      "condition": {"type": "skillLevel",     "skill": "farming",  "level": 10}},
	{"id": "skill_fish_5",   "name": "渔夫",        "desc": "钓鱼技能达到5级",         "category": "skill",      "condition": {"type": "skillLevel",     "skill": "fishing",  "level": 5}},
	{"id": "skill_fish_10",  "name": "钓鱼大师",    "desc": "钓鱼技能达到10级",        "category": "skill",      "condition": {"type": "skillLevel",     "skill": "fishing",  "level": 10}},
	{"id": "skill_mine_5",   "name": "矿工",        "desc": "采矿技能达到5级",         "category": "skill",      "condition": {"type": "skillLevel",     "skill": "mining",   "level": 5}},
	{"id": "skill_mine_10",  "name": "采矿大师",    "desc": "采矿技能达到10级",        "category": "skill",      "condition": {"type": "skillLevel",     "skill": "mining",   "level": 10}},
	{"id": "skill_all_5",    "name": "全能新手",    "desc": "所有技能达到5级",         "category": "skill",      "condition": {"type": "allSkillsLevel", "level": 5}},
	{"id": "skill_all_10",   "name": "全能大师",    "desc": "所有技能达到10级",        "category": "skill",      "condition": {"type": "allSkillsLevel", "level": 10}},

	# ---- 社交类 (2个) ----
	{"id": "friend_1",  "name": "交友",      "desc": "与一位NPC成为好友",          "category": "social",      "condition": {"type": "npcFriendship",  "count": 1}},
	{"id": "friend_all","name": "社交达人",  "desc": "与所有NPC成为好友",          "category": "social",      "condition": {"type": "npcAllFriendly"}},

	# ---- 任务类 (3个) ----
	{"id": "quest_1",  "name": "新手任务",  "desc": "完成第一个任务",             "category": "quest",       "condition": {"type": "questsCompleted", "count": 1}},
	{"id": "quest_10", "name": "任务达人",  "desc": "完成10个任务",               "category": "quest",       "condition": {"type": "questsCompleted", "count": 10}},
	{"id": "quest_50", "name": "任务大师",  "desc": "完成50个任务",               "category": "quest",       "condition": {"type": "questsCompleted", "count": 50}},

	# ---- 好感类 (2个) ----
	{"id": "best_friend_1", "name": "挚友",  "desc": "与一位NPC成为挚友",          "category": "friendship",  "condition": {"type": "npcBestFriend",   "count": 1}},
	{"id": "married",       "name": "结婚",  "desc": "与NPC结婚",                  "category": "friendship",  "condition": {"type": "married"}},

	# ---- 博物馆类 (2个) ----
	{"id": "museum_20", "name": "收藏家",   "desc": "向博物馆捐赠20件物品",        "category": "museum",      "condition": {"type": "museumDonations",  "count": 20}},
	{"id": "museum_40", "name": "灵物全鉴", "desc": "完成博物馆收藏",              "category": "museum",      "condition": {"type": "museumDonations",  "count": 40}},

	# ---- 仙灵类 (3个) ----
	{"id": "spirit_1",     "name": "仙缘初结",  "desc": "发现第一位仙灵",            "category": "hidden_npc",  "condition": {"type": "hiddenNpcRevealed", "count": 1}},
	{"id": "spirit_6",     "name": "仙灵圆满",  "desc": "发现所有仙灵",              "category": "hidden_npc",  "condition": {"type": "hiddenNpcRevealed", "count": 6}},
	{"id": "spirit_bond_1","name": "仙灵结缘", "desc": "与一位仙灵结缘",            "category": "hidden_npc",  "condition": {"type": "hiddenNpcBonded",   "count": 1}},

	# ---- 畜牧类 (3个) ----
	{"id": "animal_1",  "name": "牧场新人",  "desc": "拥有1只动物",                 "category": "animal",      "condition": {"type": "animalCount",      "count": 1}},
	{"id": "animal_5",  "name": "牧场主",    "desc": "拥有5只动物",                "category": "animal",      "condition": {"type": "animalCount",      "count": 5}},
	{"id": "animal_10", "name": "畜牧达人",  "desc": "拥有10只动物",               "category": "animal",      "condition": {"type": "animalCount",      "count": 10}},

	# ---- 完美度里程碑 (1个) ----
	{"id": "perfection_100", "name": "完美主义者", "desc": "达到100%完美度",         "category": "perfection",  "condition": {"type": "perfection100"}}
]

# ============ 单例 ============

static var _instance: Node = null

func get_instance() -> Node:
	return _instance

# ============ 成就状态 ============

## 成就完成状态 {achievement_id: state(int)}
var _achievement_states: Dictionary = {}

## 已发现物品 {item_id: {quantity, discovered_time}}
var _discovered_items: Dictionary = {}

## 统计计数器
var _stats: Dictionary = {
	"total_crops_harvested": 0,
	"total_fish_caught": 0,
	"total_money_earned": 0,
	"highest_mine_floor": 0,
	"total_recipes_cooked": 0,
	"total_quests_completed": 0,
	"total_monsters_killed": 0,
	"total_breedings_done": 0
}

## 完美度缓存 (-1.0 表示需要重新计算)
var _perfection_cache: float = -1.0

## 已完成的待评估成就队列 (避免在循环中修改集合)
var _pending_achievements: Array = []

# ============ 信号 ============

## 成就解锁信号
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)

# ============ 初始化 ============

func _ready() -> void:
	_instance = self
	_init_achievement_states()
	_connect_event_signals()
	print("[AchievementSystem] Initialized with %d achievements" % ACHIEVEMENTS.size())

func _init_achievement_states() -> void:
	for ach in ACHIEVEMENTS:
		if not _achievement_states.has(ach["id"]):
			_achievement_states[ach["id"]] = AchievementState.LOCKED

func _connect_event_signals() -> void:
	if EventBus.has_signal("farm_crop_harvested"):
		EventBus.farm_crop_harvested.connect(_on_farm_crop_harvested)
	if EventBus.has_signal("fishing_completed"):
		EventBus.fishing_completed.connect(_on_fishing_completed)
	if EventBus.has_signal("fish_caught"):
		EventBus.fish_caught.connect(_on_fish_caught)
	if EventBus.has_signal("player_money_changed"):
		EventBus.player_money_changed.connect(_on_money_changed)
	if EventBus.has_signal("cooking_completed"):
		EventBus.cooking_completed.connect(_on_cooking_completed)
	if EventBus.has_signal("skill_level_up"):
		EventBus.skill_level_up.connect(_on_skill_level_up)
	if EventBus.has_signal("quest_completed"):
		EventBus.quest_completed.connect(_on_quest_completed)
	if EventBus.has_signal("npc_talked"):
		EventBus.npc_talked.connect(_on_npc_interaction)
	if EventBus.has_signal("friendship_changed"):
		EventBus.friendship_changed.connect(_on_friendship_changed)
	if EventBus.has_signal("item_added"):
		EventBus.item_added.connect(_on_item_added)

# ============ 事件回调 ============

func _on_farm_crop_harvested(_plot_id: String, _crop_id: String, _quantity: int, _quality: int) -> void:
	_stats.total_crops_harvested += 1
	_invalidate_perfection_cache()
	evaluate_achievements()

func _on_fishing_completed(_caught: bool, _fish_id: String) -> void:
	pass

func _on_fish_caught(_fish_id: String, _quantity: int, _quality: int) -> void:
	_stats.total_fish_caught += 1
	_invalidate_perfection_cache()
	evaluate_achievements()

func _on_money_changed(_current: int, delta: int) -> void:
	if delta > 0:
		_stats.total_money_earned += delta
		_invalidate_perfection_cache()
		evaluate_achievements()

func _on_cooking_completed(_recipe_id: String) -> void:
	_stats.total_recipes_cooked += 1
	_invalidate_perfection_cache()
	evaluate_achievements()

func _on_skill_level_up(_skill_type: int, _old_level: int, _new_level: int) -> void:
	_invalidate_perfection_cache()
	evaluate_achievements()

func _on_quest_completed(_quest_id: String) -> void:
	_stats.total_quests_completed += 1
	_invalidate_perfection_cache()
	evaluate_achievements()

func _on_npc_interaction(_npc_id: String, _gain: int) -> void:
	evaluate_achievements()

func _on_friendship_changed(_npc_id: String, _old_value: int, _new_value: int) -> void:
	_invalidate_perfection_cache()
	evaluate_achievements()

func _on_item_added(item_id: String, _amount: int) -> void:
	discover_item(item_id)
	evaluate_achievements()

# ============ 物品发现 ============

func discover_item(item_id: String) -> void:
	if item_id == "" or item_id.is_empty():
		return
	if _discovered_items.has(item_id):
		return
	var timestamp = Time.get_unix_time_from_system() if get_node_or_null("/root/TimeManager") else 0
	_discovered_items[item_id] = {
		"discovered_time": timestamp,
		"season": "",
		"year": 1
	}
	_invalidate_perfection_cache()
	print("[AchievementSystem] Item discovered: %s" % item_id)

func get_discovered_count() -> int:
	return _discovered_items.size()

func is_item_discovered(item_id: String) -> bool:
	return _discovered_items.has(item_id)

func get_discovered_items() -> Array:
	return _discovered_items.keys()

# ============ 核心评估 API ============

func evaluate_achievements() -> void:
	for ach in ACHIEVEMENTS:
		var ach_id = ach["id"]
		var state = _achievement_states.get(ach_id, AchievementState.LOCKED)
		if state == AchievementState.COMPLETED:
			continue
		var condition = ach.get("condition", {})
		if check_condition(condition):
			_pending_achievements.append(ach_id)

	while not _pending_achievements.is_empty():
		var ach_id = _pending_achievements.pop_back()
		_complete_achievement(ach_id)

func check_condition(condition: Dictionary) -> bool:
	var ctype = condition.get("type", "")
	match ctype:
		"itemCount":
			return _discovered_items.size() >= condition.get("count", 0)
		"cropHarvest":
			return _stats.total_crops_harvested >= condition.get("count", 0)
		"fishCaught":
			return _stats.total_fish_caught >= condition.get("count", 0)
		"mineFloor":
			return _stats.highest_mine_floor >= condition.get("floor", 0)
		"moneyEarned":
			return _stats.total_money_earned >= condition.get("amount", 0)
		"recipesCooked":
			return _stats.total_recipes_cooked >= condition.get("count", 0)
		"skillLevel":
			return _check_skill_level(condition)
		"allSkillsLevel":
			return _check_all_skills_level(condition)
		"npcFriendship":
			return _check_npc_friendship(condition)
		"npcAllFriendly":
			return _check_npc_all_friendly()
		"questsCompleted":
			return _stats.total_quests_completed >= condition.get("count", 0)
		"npcBestFriend":
			return _check_npc_best_friend(condition)
		"married":
			return _check_married()
		"museumDonations":
			return _check_museum_donations(condition)
		"hiddenNpcRevealed":
			return _check_hidden_npc_revealed(condition)
		"hiddenNpcBonded":
			return _check_hidden_npc_bonded(condition)
		"perfection100":
			return get_perfection_percent() >= 100.0
		"animalCount":
			return _check_animal_count(condition)
	return false

func _check_skill_level(condition: Dictionary) -> bool:
	var skill_name = condition.get("skill", "")
	var level = condition.get("level", 0)
	if SkillSystem and SkillSystem.has_method("get_skill_level"):
		var skill_level = SkillSystem.get_skill_level(skill_name)
		return skill_level >= level
	return false

func _check_all_skills_level(condition: Dictionary) -> bool:
	var level = condition.get("level", 0)
	if not SkillSystem or not SkillSystem.has_method("get_skill_level"):
		return false
	for st in ["farming", "fishing", "mining", "foraging", "combat", "hunting"]:
		if SkillSystem.get_skill_level(st) < level:
			return false
	return true

func _check_npc_friendship(condition: Dictionary) -> bool:
	if not NpcFriendshipSystem or not NpcFriendshipSystem.has_method("get_all_npcs"):
		return false
	var required = condition.get("count", 1)
	var count = 0
	for npc in NpcFriendshipSystem.get_all_npcs():
		var friendship = npc.get("friendship", 0)
		if friendship >= 1000:
			count += 1
	return count >= required

func _check_npc_all_friendly() -> bool:
	if not NpcFriendshipSystem or not NpcFriendshipSystem.has_method("get_all_npcs"):
		return false
	var npcs = NpcFriendshipSystem.get_all_npcs()
	if npcs.is_empty():
		return false
	for npc in npcs:
		if npc.get("friendship", 0) < 1000:
			return false
	return true

func _check_npc_best_friend(condition: Dictionary) -> bool:
	if not NpcFriendshipSystem or not NpcFriendshipSystem.has_method("get_all_npcs"):
		return false
	var required = condition.get("count", 1)
	var count = 0
	for npc in NpcFriendshipSystem.get_all_npcs():
		if npc.get("friendship", 0) >= 2000:
			count += 1
	return count >= required

func _check_married() -> bool:
	if NpcFriendshipSystem and NpcFriendshipSystem.has_method("is_married"):
		return NpcFriendshipSystem.is_married()
	return false

func _check_museum_donations(condition: Dictionary) -> bool:
	var ms = get_node_or_null("/root/MuseumSystem")
	if not ms:
		return false

	if ms.has_method("get_donated_count"):
		return ms.get_donated_count() >= condition.get("count", 0)
	return false

func _check_hidden_npc_revealed(condition: Dictionary) -> bool:
	if not HiddenNpcSystem or not HiddenNpcSystem.has_method("get_revealed_npcs"):
		return false
	return HiddenNpcSystem.get_revealed_npcs().size() >= condition.get("count", 0)

func _check_hidden_npc_bonded(condition: Dictionary) -> bool:
	if not HiddenNpcSystem or not HiddenNpcSystem.has_method("get_bonded_count"):
		return false
	return HiddenNpcSystem.get_bonded_count() >= condition.get("count", 0)

func _check_animal_count(condition: Dictionary) -> bool:
	if AnimalHusbandrySystem and AnimalHusbandrySystem.has_method("get_animal_count"):
		return AnimalHusbandrySystem.get_animal_count() >= condition.get("count", 0)
	return false

func get_achievement_state(achievement_id: String) -> int:
	return _achievement_states.get(achievement_id, AchievementState.LOCKED)

func get_achievement(achievement_id: String) -> Dictionary:
	for ach in ACHIEVEMENTS:
		if ach["id"] == achievement_id:
			var result = ach.duplicate()
			result["state"] = _achievement_states.get(achievement_id, AchievementState.LOCKED)
			return result
	return {}

# ============ 查询 API ============

func get_all_achievements() -> Array:
	var result = []
	for ach in ACHIEVEMENTS:
		var item = ach.duplicate()
		item["state"] = _achievement_states.get(ach["id"], AchievementState.LOCKED)
		result.append(item)
	return result

func get_achievements_by_category(category: String) -> Array:
	var result = []
	for ach in ACHIEVEMENTS:
		if ach.get("category", "") == category:
			var item = ach.duplicate()
			item["state"] = _achievement_states.get(ach["id"], AchievementState.LOCKED)
			result.append(item)
	return result

func get_completed_count() -> int:
	var count = 0
	for state in _achievement_states.values():
		if state == AchievementState.COMPLETED:
			count += 1
	return count

func get_total_count() -> int:
	return ACHIEVEMENTS.size()

func get_achievement_progress() -> float:
	var total = get_total_count()
	if total == 0:
		return 0.0
	return (float(get_completed_count()) / float(total)) * 100.0

# ============ 完美度计算 ============

func _invalidate_perfection_cache() -> void:
	if not FEATURE_PERFECTION_ENABLED:
		return
	_perfection_cache = -1.0

func get_perfection_percent() -> float:
	if not FEATURE_PERFECTION_ENABLED:
		return 0.0
	if _perfection_cache >= 0.0:
		return _perfection_cache

	var weights = {
		"achievement": 0.25,
		"shipping": 0.20,
		"bundle": 0.15,
		"collection": 0.15,
		"skill": 0.15,
		"friendship": 0.10
	}

	var result = 0.0
	result += get_perfection_achievement() * weights["achievement"]
	result += get_perfection_shipping() * weights["shipping"]
	result += get_perfection_bundle() * weights["bundle"]
	result += get_perfection_collection() * weights["collection"]
	result += get_perfection_skill() * weights["skill"]
	result += get_perfection_friendship() * weights["friendship"]

	_perfection_cache = mini(result, 100.0)
	return _perfection_cache

func get_perfection_breakdown() -> Dictionary:
	if not FEATURE_PERFECTION_ENABLED:
		return {"perfection": 0.0, "achievement": {"value": 0, "max": 1, "rate": 0.0}}
	var shipped = 0
	var shippable = 1
	if Shop and Shop.has_method("get_shipped_count"):
		shipped = Shop.get_shipped_count()
	if Shop and Shop.has_method("get_shippable_count"):
		shippable = maxi(Shop.get_shippable_count(), 1)

	var total_items = 100
	if ItemDataSystem and ItemDataSystem.has_method("get_item_count"):
		total_items = ItemDataSystem.get_item_count()

	var total_npcs = 1
	if NpcFriendshipSystem and NpcFriendshipSystem.has_method("get_all_npcs"):
		total_npcs = maxi(NpcFriendshipSystem.get_all_npcs().size(), 1)

	return {
		"perfection": get_perfection_percent(),
		"achievement": {"value": get_completed_count(), "max": get_total_count(), "rate": get_perfection_achievement()},
		"shipping": {"value": shipped, "max": shippable, "rate": get_perfection_shipping()},
		"bundle": {"value": 0, "max": 35, "rate": get_perfection_bundle()},
		"collection": {"value": _discovered_items.size(), "max": total_items, "rate": get_perfection_collection()},
		"skill": {"value": _get_average_skill_level(), "max": 10, "rate": get_perfection_skill()},
		"friendship": {"value": _get_friendly_npc_count(), "max": total_npcs, "rate": get_perfection_friendship()}
	}

func get_perfection_achievement() -> float:
	var total = get_total_count()
	if total == 0:
		return 0.0
	return (float(get_completed_count()) / float(total)) * 100.0

func get_perfection_shipping() -> float:
	if Shop and Shop.has_method("get_shipped_count") and Shop.has_method("get_shippable_count"):
		var shipped = Shop.get_shipped_count()
		var shippable = maxi(Shop.get_shippable_count(), 1)
		return (float(shipped) / float(shippable)) * 100.0
	return 0.0

func get_perfection_bundle() -> float:
	return 0.0

func get_perfection_collection() -> float:
	var total = 100
	if ItemDataSystem and ItemDataSystem.has_method("get_item_count"):
		total = ItemDataSystem.get_item_count()
	if total == 0:
		return 0.0
	return (float(_discovered_items.size()) / float(total)) * 100.0

func get_perfection_skill() -> float:
	return (_get_average_skill_level() / 10.0) * 100.0

func get_perfection_friendship() -> float:
	var total = _get_total_npc_count()
	if total == 0:
		return 0.0
	return (float(_get_friendly_npc_count()) / float(total)) * 100.0

func _get_average_skill_level() -> float:
	if not SkillSystem or not SkillSystem.has_method("get_skill_level"):
		return 0.0
	var total_level = 0
	var skill_count = 0
	for st in ["farming", "fishing", "mining", "foraging", "combat", "hunting"]:
		total_level += SkillSystem.get_skill_level(st)
		skill_count += 1
	if skill_count == 0:
		return 0.0
	return float(total_level) / float(skill_count)

func _get_friendly_npc_count() -> int:
	if not NpcFriendshipSystem or not NpcFriendshipSystem.has_method("get_all_npcs"):
		return 0
	var count = 0
	for npc in NpcFriendshipSystem.get_all_npcs():
		if npc.get("friendship", 0) >= 1000:
			count += 1
	return count

func _get_total_npc_count() -> int:
	if NpcFriendshipSystem and NpcFriendshipSystem.has_method("get_all_npcs"):
		return NpcFriendshipSystem.get_all_npcs().size()
	return 1

# ============ 成就解锁 ============

func _complete_achievement(achievement_id: String) -> void:
	if _achievement_states.get(achievement_id, AchievementState.LOCKED) == AchievementState.COMPLETED:
		return

	_achievement_states[achievement_id] = AchievementState.COMPLETED
	_invalidate_perfection_cache()

	var ach_data = get_achievement(achievement_id)
	var ach_name = ach_data.get("name", achievement_id)
	var desc = ach_data.get("desc", "")

	print("[AchievementSystem] Achievement unlocked: %s - %s (%s)" % [achievement_id, ach_name, desc])
	achievement_unlocked.emit(achievement_id, ach_data)

	if EventBus.has_signal("ui_achievement_unlocked"):
		EventBus.ui_achievement_unlocked.emit(achievement_id)
	if EventBus.has_signal("notification_requested"):
		EventBus.notification_requested.emit(
			"成就解锁: " + name,
			2,
			10,
			5.0,
			"achievement_" + achievement_id,
			""
		)

# ============ 存档支持 ============

func serialize() -> Dictionary:
	return {
		"achievement_states": _achievement_states.duplicate(true),
		"discovered_items": _discovered_items.duplicate(true),
		"stats": _stats.duplicate(true)
	}

func deserialize(data: Dictionary) -> void:
	if data.is_empty():
		print("[AchievementSystem] Empty save data, using defaults")
		return

	if data.has("achievement_states"):
		for k in data["achievement_states"]:
			_achievement_states[k] = data["achievement_states"][k]

	if data.has("discovered_items"):
		_discovered_items.clear()
		for k in data["discovered_items"]:
			_discovered_items[k] = data["discovered_items"][k]

	if data.has("stats"):
		for k in data["stats"]:
			_stats[k] = data["stats"][k]

	_invalidate_perfection_cache()
	print("[AchievementSystem] Loaded %d achievements, %d items discovered" % [get_completed_count(), _discovered_items.size()])

# ============ 调试方法 ============

func debug_unlock_achievement(achievement_id: String) -> void:
	_complete_achievement(achievement_id)

func debug_reset_achievements() -> void:
	_achievement_states.clear()
	_discovered_items.clear()
	_stats = {
		"total_crops_harvested": 0,
		"total_fish_caught": 0,
		"total_money_earned": 0,
		"highest_mine_floor": 0,
		"total_recipes_cooked": 0,
		"total_quests_completed": 0,
		"total_monsters_killed": 0,
		"total_breedings_done": 0
	}
	_init_achievement_states()
	_invalidate_perfection_cache()
	print("[AchievementSystem] Debug: All achievements reset")

func debug_discover_item(item_id: String) -> void:
	discover_item(item_id)
	evaluate_achievements()

func debug_set_stat(stat_name: String, value: int) -> void:
	if _stats.has(stat_name):
		_stats[stat_name] = value
		_invalidate_perfection_cache()
		evaluate_achievements()
		print("[AchievementSystem] Debug: %s = %d" % [stat_name, value])

func debug_get_stats() -> Dictionary:
	return _stats.duplicate(true)
