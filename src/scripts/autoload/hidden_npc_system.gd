extends Node

## HiddenNpcSystem - 隐藏NPC（仙灵）系统
## 实现6位神秘仙灵的发现、供奉、互动与结缘机制
## 参考: design/gdd/feature/hidden-npc-system.md

# ============ Feature Flags（延后功能） ============

## 供奉系统 — 延至 Sprint 10
const FEATURE_OFFERINGS_ENABLED: bool = false

## 心之事件系统 — 延至 Sprint 10
const FEATURE_HEART_EVENTS_ENABLED: bool = false

# ============ 枚举定义（使用常量而非enum）============

## 发现阶段
const PHASE_UNKNOWN: int = 0
const PHASE_RUMOR: int = 1
const PHASE_GLIMPSE: int = 2
const PHASE_ENCOUNTER: int = 3
const PHASE_REVEALED: int = 4

## 缘分等级
const AFFINITY_WARY: int = 0
const AFFINITY_CURIOUS: int = 1
const AFFINITY_TRUSTING: int = 2
const AFFINITY_DEVOTED: int = 3
const AFFINITY_ETERNAL: int = 4

## 品质等级
const QUALITY_NORMAL: int = 0
const QUALITY_FINE: int = 1
const QUALITY_EXCELLENT: int = 2
const QUALITY_SUPREME: int = 3

## 供奉分类
const OFFERING_RESONANT: int = 0
const OFFERING_PLEASED: int = 1
const OFFERING_NEUTRAL: int = 2
const OFFERING_REPELLED: int = 3

# ============ 仙灵定义 ============

const HIDDEN_NPCS: Array[Dictionary] = [
	{
		"id": "long_ling",
		"name": "龙灵",
		"true_name": "沧澜",
		"title": "潜渊龙灵",
		"discovery_trigger": "钓到翠龙鱼+雨夜瀑布",
		"bond_reward_1": "控天",
		"bond_reward_2": "灵鱼吸引",
		"manifestation_day": {"season": "spring", "day": 14}
	},
	{
		"id": "tao_yao",
		"name": "桃夭",
		"true_name": "灼华",
		"title": "桃林花灵",
		"discovery_trigger": "农场技能4级+桃花瓣",
		"bond_reward_1": "作物祝福",
		"manifestation_day": {"season": "spring", "day": 3}
	},
	{
		"id": "yue_tu",
		"name": "月兔",
		"true_name": "素问",
		"title": "捣药玉兔",
		"discovery_trigger": "采集技能7级+满月竹林",
		"bond_reward_1": "体力恢复",
		"manifestation_day": {"season": "autumn", "day": 14}
	},
	{
		"id": "hu_xian",
		"name": "狐仙",
		"true_name": "无名",
		"title": "九尾灵狐",
		"discovery_trigger": "拥有10万+金币",
		"bond_reward_1": "出售加成",
		"manifestation_day": {"season": "autumn", "day": 7}
	},
	{
		"id": "shan_weng",
		"name": "山翁",
		"true_name": "清虚",
		"title": "采药仙翁",
		"discovery_trigger": "矿洞50层+技能8级",
		"bond_reward_1": "灵力护盾",
		"manifestation_day": {"season": "winter", "day": 1}
	},
	{
		"id": "gui_nv",
		"name": "归女",
		"true_name": "锦归",
		"title": "织梦归女",
		"discovery_trigger": "苏苏好感2000+冬夜丝绸",
		"bond_reward_1": "动物祝福",
		"manifestation_day": {"season": "winter", "day": 21}
	}
]

# ============ 供奉系统 ============

const OFFERING_CATEGORIES: Dictionary = {
	OFFERING_RESONANT: {"base": 100, "examples": ["dragon_jade", "peach", "ganoderma"]},
	OFFERING_PLEASED: {"base": 50, "examples": ["ruby", "honey", "tea_leaf"]},
	OFFERING_NEUTRAL: {"base": 10, "examples": []},
	OFFERING_REPELLED: {"base": -40, "examples": ["charcoal", "garbage"]}
}

const QUALITY_MULTIPLIERS: Dictionary = {
	QUALITY_NORMAL: 1.0,
	QUALITY_FINE: 1.25,
	QUALITY_EXCELLENT: 1.5,
	QUALITY_SUPREME: 2.0
}

const MANIFESTATION_MULTIPLIER: float = 3.0

# ============ 缘分等级阈值 ============

const AFFINITY_THRESHOLDS: Dictionary = {
	AFFINITY_WARY: 0,
	AFFINITY_CURIOUS: 400,
	AFFINITY_TRUSTING: 1000,
	AFFINITY_DEVOTED: 1800,
	AFFINITY_ETERNAL: 2500
}

const AFFINITY_MAX: int = 3000

# ============ 求缘/结缘门槛 ============

const COURTSHIP_THRESHOLD: int = 1800
const BOND_THRESHOLD: int = 2500

# ============ 能力定义 ============

const ABILITIES: Dictionary = {
	"long_ling": [
		{"id": "long_ling_1", "name": "龙泽", "affinity_required": 800, "effect": "water_fish_quality_plus_1"},
		{"id": "long_ling_2", "name": "唤雨", "affinity_required": 1500, "effect": "rain_chance_plus_15"},
		{"id": "long_ling_3", "name": "龙瞳", "affinity_required": 2200, "effect": "legendary_fish_chance_plus_20"}
	],
	"tao_yao": [
		{"id": "tao_yao_1", "name": "花泽", "affinity_required": 600, "effect": "fruit_tree_plus_1"},
		{"id": "tao_yao_2", "name": "春息", "affinity_required": 1200, "effect": "spring_growth_speed_plus_15"},
		{"id": "tao_yao_3", "name": "灵桃", "affinity_required": 2000, "effect": "peach_spirit_chance"}
	],
	"yue_tu": [
		{"id": "yue_tu_1", "name": "灵采", "affinity_required": 500, "effect": "herb_gather_double"},
		{"id": "yue_tu_2", "name": "药引", "affinity_required": 1000, "effect": "tea_medicine_effect_plus_50"},
		{"id": "yue_tu_3", "name": "月华", "affinity_required": 1800, "effect": "moon_herb_chance"}
	],
	"hu_xian": [
		{"id": "hu_xian_1", "name": "狐眼", "affinity_required": 700, "effect": "shop_price_minus_5"},
		{"id": "hu_xian_2", "name": "灵探", "affinity_required": 1400, "effect": "mine_extra_drop_chance"},
		{"id": "hu_xian_3", "name": "幻商", "affinity_required": 2100, "effect": "traveler_more_items"}
	],
	"shan_weng": [
		{"id": "shan_weng_1", "name": "聚气", "affinity_required": 600, "effect": "mining_stamina_minus_15"},
		{"id": "shan_weng_2", "name": "灵脉", "affinity_required": 1200, "effect": "mine_rare_herb_chance"},
		{"id": "shan_weng_3", "name": "金丹", "affinity_required": 2000, "effect": "max_stamina_plus_20"}
	],
	"gui_nv": [
		{"id": "gui_nv_1", "name": "织速", "affinity_required": 500, "effect": "weaving_time_minus_30"},
		{"id": "gui_nv_2", "name": "梦丝", "affinity_required": 1100, "effect": "loom_dream_thread_chance"},
		{"id": "gui_nv_3", "name": "灵抚", "affinity_required": 1900, "effect": "animal_friendship_plus_25"}
	]
}

# ============ 每日衰减配置 ============

const DECAY_BONDED: int = 15
const DECAY_COURTING: int = 10

# ============ 供奉限制 ============

const MAX_OFFERINGS_PER_WEEK: int = 3

# ============ 发现条件定义 ============

const DISCOVERY_CONDITIONS: Dictionary = {
	"long_ling": {
		PHASE_RUMOR: [
			{"type": "fish_caught", "value": "jade_dragon"}
		],
		PHASE_GLIMPSE: [
			{"type": "weather", "value": "rainy"},
			{"type": "location", "value": "waterfall"}
		],
		PHASE_ENCOUNTER: [
			{"type": "item", "value": "dragon_jade"}
		]
	},
	"tao_yao": {
		PHASE_RUMOR: [
			{"type": "skill_level", "skill": "farming", "value": 4}
		],
		PHASE_GLIMPSE: [
			{"type": "item", "value": "peach_petal"}
		],
		PHASE_ENCOUNTER: [
			{"type": "season", "value": "spring"}
		]
	},
	"yue_tu": {
		PHASE_RUMOR: [
			{"type": "skill_level", "skill": "foraging", "value": 7}
		],
		PHASE_GLIMPSE: [
			{"type": "timeRange", "min": 20, "max": 26},
			{"type": "location", "value": "bamboo_forest"}
		],
		PHASE_ENCOUNTER: [
			{"type": "item", "value": "moon_bamboo"}
		]
	},
	"hu_xian": {
		PHASE_RUMOR: [
			{"type": "money", "value": 100000}
		],
		PHASE_GLIMPSE: [
			{"type": "money", "value": 150000}
		],
		PHASE_ENCOUNTER: [
			{"type": "item", "value": "ruby"}
		]
	},
	"shan_weng": {
		PHASE_RUMOR: [
			{"type": "mine_floor", "value": 50},
			{"type": "skill_total", "value": 24}
		],
		PHASE_GLIMPSE: [
			{"type": "item", "value": "ganoderma"}
		],
		PHASE_ENCOUNTER: [
			{"type": "skill_level", "skill": "mining", "value": 8}
		]
	},
	"gui_nv": {
		PHASE_RUMOR: [
			{"type": "npc_friendship", "npc": "su_su", "value": 2000}
		],
		PHASE_GLIMPSE: [
			{"type": "season", "value": "winter"}
		],
		PHASE_ENCOUNTER: [
			{"type": "item", "value": "silk"}
		]
	}
}

# ============ 静态实例 ============

static var _instance: Node = null

# ============ 内部状态 ============

var _npc_states: Dictionary = {}
var _initialized: bool = false

# ============ 信号 ============

signal npc_phase_changed(npc_id: String, old_phase: int, new_phase: int)
signal affinity_changed(npc_id: String, old_value: int, new_value: int)
signal ability_unlocked(npc_id: String, ability_id: String)
signal courting_started(npc_id: String)
signal bond_formed(npc_id: String)
signal discovery_triggered(npc_id: String, phase: int)

# ============ 初始化 ============

func _ready() -> void:
	_instance = self
	_initialize()
	_connect_signals()
	print("[HiddenNpcSystem] Initialized with %d hidden NPCs" % HIDDEN_NPCS.size())

func _initialize() -> void:
	if _initialized:
		return

	# 初始化所有仙灵状态
	for npc in HIDDEN_NPCS:
		var npc_id = npc["id"]
		_npc_states[npc_id] = {
			"phase": PHASE_UNKNOWN,
			"affinity": 0,
			"courting": false,
			"bonded": false,
			"offered_today": false,
			"interacted_today": false,
			"offered_this_week": 0,
			"last_offering_day": -1,
			"unlocked_abilities": [],
			"heart_events_triggered": []
		}

	_initialized = true

func _connect_signals() -> void:
	if EventBus and EventBus.has_signal("time_day_changed"):
		EventBus.time_day_changed.connect(_on_day_changed)

# ============ 单例访问 ============

static func get_instance() -> Node:
	return _instance

# ============ 基础查询 API ============

func get_all_hidden_npcs() -> Array:
	return HIDDEN_NPCS.duplicate()

func get_hidden_npc_state(npc_id: String) -> Dictionary:
	return _npc_states.get(npc_id, {})

func get_affinity_level(npc_id: String) -> int:
	var state = _npc_states.get(npc_id)
	if not state:
		return AFFINITY_WARY
	return _get_affinity_level(state.get("affinity", 0))

func _get_affinity_level(affinity: int) -> int:
	if affinity >= 2500:
		return AFFINITY_ETERNAL
	elif affinity >= 1800:
		return AFFINITY_DEVOTED
	elif affinity >= 1000:
		return AFFINITY_TRUSTING
	elif affinity >= 400:
		return AFFINITY_CURIOUS
	else:
		return AFFINITY_WARY

func get_revealed_npcs() -> Array:
	var result = []
	for npc in HIDDEN_NPCS:
		var state = _npc_states.get(npc["id"])
		if state and state.get("phase") == PHASE_REVEALED:
			result.append(npc.duplicate())
	return result

func get_rumor_npcs() -> Array:
	var result = []
	for npc in HIDDEN_NPCS:
		var state = _npc_states.get(npc["id"])
		if state and state.get("phase") >= PHASE_RUMOR:
			result.append(npc.duplicate())
	return result

# ============ 发现系统 ============

func check_discovery_conditions() -> Array:
	var triggered = []
	for npc in HIDDEN_NPCS:
		var npc_id = npc["id"]
		var state = _npc_states.get(npc_id)
		if not state or state.get("phase") >= PHASE_REVEALED:
			continue

		var current_phase = state.get("phase")
		var next_phase = _get_next_phase(current_phase)
		if next_phase <= current_phase:
			continue

		var conditions = DISCOVERY_CONDITIONS.get(npc_id, {}).get(next_phase, [])
		var all_met = true
		for condition in conditions:
			if not evaluate_condition(condition):
				all_met = false
				break

		if all_met:
			triggered.append({"npc_id": npc_id, "phase": next_phase})
			_advance_phase(npc_id, next_phase)

	return triggered

func evaluate_condition(condition: Dictionary) -> bool:
	var condition_type = condition.get("type", "")

	match condition_type:
		"fish_caught":
			# 检查是否钓到指定鱼类（需要 FishingSystem）
			if has_node("FishingSystem"):
				# 简化：检查玩家钓到的传说鱼记录
				return false
			return false

		"weather":
			var required_weather = condition.get("value", "")
			if has_node("WeatherSystem"):
				return WeatherSystem.current_weather == required_weather
			return false

		"location":
			# 检查玩家当前位置（需要 SceneManager 或 Player）
			return false

		"item":
			# 检查背包中是否有指定物品（需要 InventorySystem）
			var item_id = condition.get("value", "")
			if has_node("InventorySystem"):
				return InventorySystem.has_item(item_id)
			return false

		"skill_level":
			var skill_name = condition.get("skill", "")
			var required_level = condition.get("value", 0)
			if has_node("SkillSystem"):
				var level = _get_skill_level_by_name(skill_name)
				return level >= required_level
			return false

		"skill_total":
			var required_total = condition.get("value", 0)
			if has_node("SkillSystem"):
				var total = _get_total_skill_level()
				return total >= required_total
			return false

		"money":
			var required_money = condition.get("value", 0)
			if has_node("PlayerStats"):
				return PlayerStats.money >= required_money
			return false

		"npc_friendship":
			var npc_name = condition.get("npc", "")
			var required_friendship = condition.get("value", 0)
			if has_node("NpcFriendshipSystem"):
				var npc_data = NpcFriendshipSystem.get_npc(npc_name)
				var friendship = npc_data.get("friendship", 0)
				return friendship >= required_friendship
			return false

		"mine_floor":
			var required_floor = condition.get("value", 0)
			# 检查矿洞进度（需要 MiningSystem 或全局状态）
			if has_node("PlayerStats"):
				var max_floor = PlayerStats.get_value("max_mine_floor", 0)
				return max_floor >= required_floor
			return false

		"timeRange":
			var min_hour = condition.get("min", 0)
			var max_hour = condition.get("max", 26)
			if has_node("TimeManager"):
				var hour = TimeManager.current_hour
				return hour >= min_hour and hour <= max_hour
			return false

		"season":
			var required_season = condition.get("value", "")
			if has_node("TimeManager"):
				var season_names = TimeManager.SEASON_NAMES_EN
				var current_season_name = season_names.get(TimeManager.current_season, "")
				return current_season_name.to_lower() == required_season.to_lower()
			return false

		_:
			return false

func _get_skill_level_by_name(skill_name: String) -> int:
	if not has_node("SkillSystem"):
		return 0
	var skill_type_map = {
		"farming": SkillSystem.SkillType.FARMING,
		"foraging": SkillSystem.SkillType.FORAGING,
		"fishing": SkillSystem.SkillType.FISHING,
		"mining": SkillSystem.SkillType.MINING,
		"combat": SkillSystem.SkillType.COMBAT,
		"hunting": SkillSystem.SkillType.HUNTING
	}
	var skill_type = skill_type_map.get(skill_name.to_lower())
	if skill_type != null:
		return SkillSystem.get_level(skill_type)
	return 0

func _get_total_skill_level() -> int:
	if not has_node("SkillSystem"):
		return 0
	var total = 0
	for skill_type in SkillSystem.SkillType.values():
		total += SkillSystem.get_level(skill_type)
	return total

func _get_next_phase(current_phase: int) -> int:
	match current_phase:
		PHASE_UNKNOWN: return PHASE_RUMOR
		PHASE_RUMOR: return PHASE_GLIMPSE
		PHASE_GLIMPSE: return PHASE_ENCOUNTER
		PHASE_ENCOUNTER: return PHASE_REVEALED
		_:
			return current_phase

func _advance_phase(npc_id: String, new_phase: int) -> void:
	var state = _npc_states.get(npc_id)
	if not state:
		return

	var old_phase = state.get("phase")
	state["phase"] = new_phase

	# 发送信号
	npc_phase_changed.emit(npc_id, old_phase, new_phase)
	discovery_triggered.emit(npc_id, new_phase)

	if EventBus:
		EventBus.notification_requested.emit(
			_get_discovery_message(npc_id, new_phase),
			4,  # SYSTEM
			5,
			3.0,
			"discovery_" + npc_id,
			""
		)

	print("[HiddenNpcSystem] %s advanced to phase %d" % [npc_id, new_phase])

func _get_discovery_message(npc_id: String, phase: int) -> String:
	var npc_name = ""
	for npc in HIDDEN_NPCS:
		if npc["id"] == npc_id:
			npc_name = npc["name"]
			break

	match phase:
		PHASE_RUMOR:
			return "隐约听到关于" + npc_name + "的传说..."
		PHASE_GLIMPSE:
			return "似乎在远处看到了" + npc_name + "的身影..."
		PHASE_ENCOUNTER:
			return "与" + npc_name + "初次相遇！"
		PHASE_REVEALED:
			return npc_name + "愿意与你往来！"
		_:
			return ""

# ============ 供奉系统 ============

func perform_offering(npc_id: String, item_id: String, quality: int = 0) -> Dictionary:
	if not FEATURE_OFFERINGS_ENABLED:
		return {"success": false, "message": "供奉系统暂未开放", "affinity_change": 0}

	var state = _npc_states.get(npc_id)
	if not state:
		return {"success": false, "message": "仙灵不存在", "affinity_change": 0}

	if state.get("phase") < PHASE_REVEALED:
		return {"success": false, "message": "尚未与此仙灵建立联系", "affinity_change": 0}

	if state.get("offered_today"):
		return {"success": false, "message": "今日已供奉过了", "affinity_change": 0}

	var current_day = 1
	if has_node("TimeManager"):
		current_day = TimeManager.current_day

	# 检查每周供奉次数
	if state.get("last_offering_day", -1) != current_day:
		# 新的一天，重置计数
		var days_since = current_day - state.get("last_offering_day", 0)
		if days_since >= 7 or state.get("last_offering_day", -1) == -1:
			state["offered_this_week"] = 0

	if state.get("offered_this_week", 0) >= MAX_OFFERINGS_PER_WEEK:
		return {"success": false, "message": "本周供奉次数已满", "affinity_change": 0}

	# 计算供奉缘分
	var offering_category = _get_offering_category(item_id)
	var base_affinity = OFFERING_CATEGORIES.get(offering_category, {}).get("base", 10)
	var quality_multiplier = QUALITY_MULTIPLIERS.get(quality, 1.0)
	var manifestation_multiplier = 1.0

	# 检查是否显灵日
	if is_manifestation_day(npc_id):
		manifestation_multiplier = MANIFESTATION_MULTIPLIER

	var affinity_change = int(base_affinity * quality_multiplier * manifestation_multiplier)

	# 更新缘分
	_add_affinity(npc_id, affinity_change)

	# 更新状态
	state["offered_today"] = true
	state["offered_this_week"] = state.get("offered_this_week", 0) + 1
	state["last_offering_day"] = current_day

	# 获取物品名称
	var item_name = item_id
	if has_node("ItemDataSystem"):
		var item_def = ItemDataSystem.get_item_def(item_id)
		if item_def:
			var name_val = item_def.get("name")
			item_name = name_val if name_val != null else item_id

	var quality_name = _get_quality_name(quality)
	var message = "向" + _get_npc_name(npc_id) + "供奉了" + quality_name + item_name
	if manifestation_multiplier > 1.0:
		message += "（显灵日加成）"
	message += "，" + (("缘分+" if affinity_change >= 0 else "缘分") + str(affinity_change))

	if EventBus:
		EventBus.notification_requested.emit(message, 2 if affinity_change >= 0 else 3, 5, 3.0, "offering_" + npc_id, "")

	print("[HiddenNpcSystem] Offering: %s +%d affinity" % [npc_id, affinity_change])

	return {
		"success": true,
		"message": message,
		"affinity_change": affinity_change
	}

func _get_offering_category(item_id: String) -> int:
	for category in OFFERING_CATEGORIES:
		var examples = OFFERING_CATEGORIES[category].get("examples", [])
		if item_id in examples:
			return category
	# 默认一般供奉
	return OFFERING_NEUTRAL

func _get_quality_name(quality: int) -> String:
	match quality:
		QUALITY_FINE: return "精致的"
		QUALITY_EXCELLENT: return "优质的"
		QUALITY_SUPREME: return "极品的"
		_: return ""


## 获取剩余供奉次数（今日）
func get_offering_remaining(npc_id: String) -> int:
	var state = _npc_states.get(npc_id)
	if not state:
		return 0
	if state.get("offered_today"):
		return 0
	return 1

## 获取剩余互动次数（今日）
func get_interaction_remaining(npc_id: String) -> int:
	var state = _npc_states.get(npc_id)
	if not state:
		return 0
	if state.get("interacted_today"):
		return 0
	return 1

## 获取可供奉物品列表（从背包查询）
func get_offering_items(_npc_id: String) -> Array:
	var items: Array = []
	var inv = get_node_or_null("/root/InventorySystem")
	if not inv:
		return items
	if not inv.has_method("get_all_items"):
		return items
	var all_items = inv.get_all_items()
	for item in all_items:
		var item_id = item.get("id", "")
		items.append({
			"id": item_id,
			"name": item.get("name", item_id),
			"count": item.get("count", 1),
			"quality": item.get("quality", "normal"),
			"affinity_gain": _calculate_offering_affinity(item_id, item.get("quality", 0))
		})
	return items

func _calculate_offering_affinity(item_id: String, quality: int) -> int:
	var category = _get_offering_category(item_id)
	var base = OFFERING_CATEGORIES.get(category, {}).get("base", 10)
	var multiplier = QUALITY_MULTIPLIERS.get(quality, 1.0)
	return int(base * multiplier)

# ============ 独特互动系统 ============

func perform_special_interaction(npc_id: String) -> Dictionary:
	var state = _npc_states.get(npc_id)
	if not state:
		return {"success": false, "message": "仙灵不存在", "affinity_change": 0}

	if state.get("phase") < PHASE_REVEALED:
		return {"success": false, "message": "尚未与此仙灵建立联系", "affinity_change": 0}

	if state.get("interacted_today"):
		return {"success": false, "message": "今日已互动过了", "affinity_change": 0}

	var affinity_change = 0
	var message = ""

	match npc_id:
		"long_ling":
			affinity_change = _calculate_meditation_affinity()
			message = "参悟龙灵之道，缘分+" + str(affinity_change)
		"yue_tu":
			affinity_change = _calculate_music_affinity()
			message = "为月兔奏乐，缘分+" + str(affinity_change)
		"tao_yao":
			affinity_change = _calculate_ritual_affinity()
			message = "举行祭仪，缘分+" + str(affinity_change)
		"hu_xian", "gui_nv":
			affinity_change = _calculate_dreamwalk_affinity()
			message = "入梦相会，缘分+" + str(affinity_change)
		"shan_weng":
			affinity_change = _calculate_cultivation_affinity()
			var result = "修炼"
			if affinity_change >= 40:
				result = "修炼成功"
			else:
				result = "修炼失败"
			message = result + "，缘分+" + str(affinity_change)
		_:
			affinity_change = 20
			message = "与仙灵交流，缘分+" + str(affinity_change)

	_add_affinity(npc_id, affinity_change)
	state["interacted_today"] = true

	if EventBus:
		EventBus.notification_requested.emit(
			_get_npc_name(npc_id) + "：" + message,
			2,
			5,
			3.0,
			"interaction_" + npc_id,
			""
		)

	print("[HiddenNpcSystem] Interaction: %s +%d affinity" % [npc_id, affinity_change])

	return {
		"success": true,
		"message": message,
		"affinity_change": affinity_change
	}

func _calculate_meditation_affinity() -> int:
	var total = 0
	if has_node("SkillSystem"):
		total += SkillSystem.get_level(SkillSystem.SkillType.FARMING)
		total += SkillSystem.get_level(SkillSystem.SkillType.FORAGING)
		total += SkillSystem.get_level(SkillSystem.SkillType.FISHING)
		total += SkillSystem.get_level(SkillSystem.SkillType.MINING)
	return total * 3

func _calculate_music_affinity() -> int:
	# 使用 RandomNumberGenerator 确保确定性
	var rng = RandomNumberGenerator.new()
	return 30 + rng.randi() % 21  # 30-50

func _calculate_ritual_affinity() -> int:
	return 40

func _calculate_dreamwalk_affinity() -> int:
	return 35

func _calculate_cultivation_affinity() -> int:
	if not has_node("SkillSystem"):
		return 10

	var mining_level = SkillSystem.get_level(SkillSystem.SkillType.MINING)
	var foraging_level = SkillSystem.get_level(SkillSystem.SkillType.FORAGING)
	var success_rate = mining_level * 5 + foraging_level * 5

	var rng = RandomNumberGenerator.new()
	if rng.randf() * 100 < success_rate:
		return 40  # 成功
	return 10  # 失败

# ============ 缘分系统 ============

func add_affinity(npc_id: String, amount: int) -> void:
	_add_affinity(npc_id, amount)

func _add_affinity(npc_id: String, amount: int) -> void:
	var state = _npc_states.get(npc_id)
	if not state:
		return

	var old_affinity = state.get("affinity", 0)
	var new_affinity = clampi(old_affinity + amount, 0, AFFINITY_MAX)
	state["affinity"] = new_affinity

	# 检查能力解锁
	_check_ability_unlocks(npc_id)

	# 发送信号
	if old_affinity != new_affinity:
		affinity_changed.emit(npc_id, old_affinity, new_affinity)

func _check_ability_unlocks(npc_id: String) -> void:
	var state = _npc_states.get(npc_id)
	if not state:
		return

	var current_affinity = state.get("affinity", 0)
	var abilities = ABILITIES.get(npc_id, [])
	var unlocked = state.get("unlocked_abilities", [])

	for ability in abilities:
		var ability_id = ability.get("id", "")
		var required = ability.get("affinity_required", 0)

		if current_affinity >= required and ability_id not in unlocked:
			unlocked.append(ability_id)
			state["unlocked_abilities"] = unlocked
			ability_unlocked.emit(npc_id, ability_id)

			if EventBus:
				var ability_name = ability.get("name", ability_id)
				EventBus.notification_requested.emit(
					_get_npc_name(npc_id) + "解锁能力：" + ability_name,
					2,
					5,
					4.0,
					"ability_" + ability_id,
					""
				)
				print("[HiddenNpcSystem] Ability unlocked: %s -> %s" % [npc_id, ability_id])

func is_manifestation_day(npc_id: String) -> bool:
	for npc in HIDDEN_NPCS:
		if npc["id"] == npc_id:
			var manifest_day = npc.get("manifestation_day", {})
			var season_name = manifest_day.get("season", "")
			var day = manifest_day.get("day", 0)

			if has_node("TimeManager"):
				var season_names = TimeManager.SEASON_NAMES_EN
				var current_season_name = season_names.get(TimeManager.current_season, "")
				if current_season_name.to_lower() == season_name.to_lower():
					if TimeManager.current_day == day:
						return true
			return false
	return false

# ============ 求缘与结缘 ============

func start_courting(npc_id: String) -> Dictionary:
	var state = _npc_states.get(npc_id)
	if not state:
		return {"success": false, "message": "仙灵不存在"}

	if state.get("phase") < PHASE_REVEALED:
		return {"success": false, "message": "尚未与此仙灵建立联系"}

	if state.get("bonded"):
		return {"success": false, "message": "已与" + _get_npc_name(npc_id) + "结缘"}

	# 检查是否正在与其他仙灵求缘
	for other_id in _npc_states:
		var other_state = _npc_states[other_id]
		if other_state.get("courting") and other_id != npc_id:
			return {"success": false, "message": "正在与" + _get_npc_name(other_id) + "求缘中"}

	var affinity = state.get("affinity", 0)
	if affinity < COURTSHIP_THRESHOLD:
		return {
			"success": false,
			"message": "缘分不足，需要" + str(COURTSHIP_THRESHOLD) + "点，当前" + str(affinity) + "点"
		}

	state["courting"] = true
	courting_started.emit(npc_id)

	if EventBus:
		EventBus.notification_requested.emit(
			_get_npc_name(npc_id) + "接受了你的求缘！",
			2,
			5,
			4.0,
			"courting_" + npc_id,
			""
		)

	print("[HiddenNpcSystem] Courting started with %s" % npc_id)

	return {
		"success": true,
		"message": "求缘开始，请继续供奉以达成结缘"
	}

func form_bond(npc_id: String) -> Dictionary:
	var state = _npc_states.get(npc_id)
	if not state:
		return {"success": false, "message": "仙灵不存在"}

	if state.get("phase") < PHASE_REVEALED:
		return {"success": false, "message": "尚未与此仙灵建立联系"}

	if state.get("bonded"):
		return {"success": false, "message": "已与" + _get_npc_name(npc_id) + "结缘"}

	var affinity = state.get("affinity", 0)
	if affinity < BOND_THRESHOLD:
		return {
			"success": false,
			"message": "缘分不足，需要" + str(BOND_THRESHOLD) + "点，当前" + str(affinity) + "点"
		}

	state["bonded"] = true
	state["courting"] = false
	bond_formed.emit(npc_id)

	if EventBus:
		EventBus.notification_requested.emit(
			"与" + _get_npc_name(npc_id) + "完成结缘，永世相伴！",
			2,
			5,
			5.0,
			"bond_" + npc_id,
			""
		)

	print("[HiddenNpcSystem] Bond formed with %s" % npc_id)

	return {
		"success": true,
		"message": "结缘成功！获得" + _get_npc_name(npc_id) + "的祝福",
		"bond_reward_1": _get_npc_bond_reward(npc_id, 1),
		"bond_reward_2": _get_npc_bond_reward(npc_id, 2)
	}

func _get_npc_bond_reward(npc_id: String, reward_num: int) -> String:
	for npc in HIDDEN_NPCS:
		if npc["id"] == npc_id:
			if reward_num == 1:
				return npc.get("bond_reward_1", "")
			else:
				return npc.get("bond_reward_2", "")
	return ""

# ============ 心事件系统 ============

func check_heart_event(npc_id: String) -> Dictionary:
	if not FEATURE_HEART_EVENTS_ENABLED:
		return {"available": false}

	var state = _npc_states.get(npc_id)
	if not state:
		return {"available": false}

	var level = get_affinity_level(npc_id)
	var phase = state.get("phase")

	# 心事件只在REVEALED阶段可用
	if phase < PHASE_REVEALED:
		return {"available": false}

	var triggered = state.get("heart_events_triggered", [])

	# 简化的心事件触发条件
	if level >= AFFINITY_TRUSTING and "heart_1" not in triggered:
		return {
			"available": true,
			"event_id": "heart_1",
			"message": _get_npc_name(npc_id) + "想要与你深入交流..."
		}
	elif level >= AFFINITY_DEVOTED and "heart_2" not in triggered:
		return {
			"available": true,
			"event_id": "heart_2",
			"message": _get_npc_name(npc_id) + "向你敞开心扉..."
		}
	elif level >= AFFINITY_ETERNAL and "heart_3" not in triggered:
		return {
			"available": true,
			"event_id": "heart_3",
			"message": _get_npc_name(npc_id) + "与你心灵相通..."
		}

	return {"available": false}

func mark_heart_event_triggered(npc_id: String, event_id: String) -> void:
	if not FEATURE_HEART_EVENTS_ENABLED:
		return

	var state = _npc_states.get(npc_id)
	if not state:
		return

	var triggered = state.get("heart_events_triggered", [])
	if event_id not in triggered:
		triggered.append(event_id)
		state["heart_events_triggered"] = triggered
		print("[HiddenNpcSystem] Heart event triggered: %s -> %s" % [npc_id, event_id])

# ============ 能力系统 ============

func check_ability_unlocks() -> Array:
	var newly_unlocked = []
	for npc_id in _npc_states:
		var state = _npc_states[npc_id]
		var abilities = ABILITIES.get(npc_id, [])
		var unlocked = state.get("unlocked_abilities", [])
		var current_affinity = state.get("affinity", 0)

		for ability in abilities:
			var ability_id = ability.get("id", "")
			var required = ability.get("affinity_required", 0)

			if current_affinity >= required and ability_id not in unlocked:
				newly_unlocked.append({
					"npc_id": npc_id,
					"ability_id": ability_id,
					"ability_name": ability.get("name", ""),
					"effect": ability.get("effect", "")
				})

	return newly_unlocked

func is_ability_active(ability_id: String) -> bool:
	for npc_id in _npc_states:
		var state = _npc_states[npc_id]
		var abilities = state.get("unlocked_abilities", [])
		if ability_id in abilities:
			return true
	return false

func get_ability_value(ability_id: String) -> int:
	# 根据能力ID返回被动值
	var ability_values = {
		"long_ling_1": 1,   # 钓鱼品质+1
		"long_ling_2": 15,  # 下雨概率+15%
		"long_ling_3": 20,  # 传说鱼+20%
		"tao_yao_1": 1,     # 果树+1
		"tao_yao_2": 15,    # 春季生长+15%
		"tao_yao_3": 10,    # 灵桃概率%
		"yue_tu_1": 100,    # 采集翻倍（百分比）
		"yue_tu_2": 50,     # 茶药效果+50%
		"yue_tu_3": 15,     # 月草概率%
		"hu_xian_1": 5,     # 价格-5%
		"hu_xian_2": 15,    # 额外掉落%
		"hu_xian_3": 1,     # 旅行商额外商品
		"shan_weng_1": 15,  # 挖矿体力-15%
		"shan_weng_2": 10,  # 稀有草药%
		"shan_weng_3": 20,  # 最大体力+20
		"gui_nv_1": 30,     # 织布时间-30%
		"gui_nv_2": 15,     # 梦丝概率%
		"gui_nv_3": 25      # 动物好感+25%
	}
	return ability_values.get(ability_id, 0)

func get_active_abilities() -> Array:
	var active = []
	for npc_id in _npc_states:
		var state = _npc_states[npc_id]
		var abilities = state.get("unlocked_abilities", [])
		var npc_name = _get_npc_name(npc_id)

		for ability_id in abilities:
			var ability_def = _get_ability_def(npc_id, ability_id)
			if ability_def:
				active.append({
					"npc_id": npc_id,
					"npc_name": npc_name,
					"ability_id": ability_id,
					"ability_name": ability_def.get("name", ""),
					"effect": ability_def.get("effect", ""),
					"value": get_ability_value(ability_id)
			})

	return active

func _get_ability_def(npc_id: String, ability_id: String) -> Dictionary:
	var abilities = ABILITIES.get(npc_id, [])
	for ability in abilities:
		if ability.get("id", "") == ability_id:
			return ability
	return {}

# ============ 结缘奖励系统 ============

func get_bond_bonus() -> Dictionary:
	# 获取当前结缘对象的奖励
	for npc_id in _npc_states:
		var state = _npc_states[npc_id]
		if state.get("bonded"):
			return get_bond_bonus_by_npc(npc_id)
	return {}

func get_bond_bonus_by_npc(npc_id: String) -> Dictionary:
	var state = _npc_states.get(npc_id)
	if not state or not state.get("bonded"):
		return {}

	var rewards = {}
	var bond_reward_1 = _get_npc_bond_reward(npc_id, 1)
	if bond_reward_1 != "":
		rewards[bond_reward_1] = true

	var bond_reward_2 = _get_npc_bond_reward(npc_id, 2)
	if bond_reward_2 != "":
		rewards[bond_reward_2] = true

	return rewards

func get_bond_bonus_by_type(bonus_type: String) -> Dictionary:
	# 按类型查找结缘奖励
	var bonus_map = {
		"控天": {"type": "weather", "effect": "sunny_30_percent"},
		"灵鱼吸引": {"type": "fishing", "effect": "spirit_fish_50_percent"},
		"作物祝福": {"type": "farming", "effect": "quality_20_percent"},
		"体力恢复": {"type": "stamina", "effect": "recover_15"},
		"出售加成": {"type": "sell", "effect": "price_plus_15"},
		"灵力护盾": {"type": "stamina", "effect": "cost_minus_20", "hp_plus": 30},
		"动物祝福": {"type": "animal", "effect": "quality_25_percent"}
	}
	return bonus_map.get(bonus_type, {})

func daily_bond_bonus() -> Dictionary:
	# 每日结缘奖励处理
	var bonus = get_bond_bonus()
	var results = {}

	if bonus.has("体力恢复"):
		if has_node("PlayerStats"):
			var recover_amount = 15
			var max_stam = PlayerStats.get_max_stamina()
			PlayerStats.stamina = mini(PlayerStats.stamina + recover_amount, max_stam)
			results["stamina_recovered"] = recover_amount
			print("[HiddenNpcSystem] Daily bond bonus: +%d stamina" % recover_amount)

	if bonus.has("灵力护盾"):
		if has_node("PlayerStats"):
			PlayerStats.spirit_shield_stamina_save = 0.2
			PlayerStats.current_hp = mini(PlayerStats.current_hp + 30, PlayerStats.get_max_hp())
			results["spirit_shield"] = true
			results["hp_restored"] = 30
			print("[HiddenNpcSystem] Daily bond bonus: spirit shield active")

	return results

# ============ 每日更新 ============

func _on_day_changed(day: int, season: String, year: int) -> void:
	daily_reset()

func daily_reset() -> void:
	for npc_id in _npc_states:
		var state = _npc_states[npc_id]

		# 缘分衰减
		if state.get("courting") and not state.get("bonded"):
			var new_affinity = maxi(0, state.get("affinity", 0) - DECAY_COURTING)
			state["affinity"] = new_affinity
			print("[HiddenNpcSystem] %s courting decay: -%d" % [npc_id, DECAY_COURTING])
		elif state.get("bonded"):
			var new_affinity = maxi(0, state.get("affinity", 0) - DECAY_BONDED)
			state["affinity"] = new_affinity
			print("[HiddenNpcSystem] %s bonded decay: -%d" % [npc_id, DECAY_BONDED])

		# 重置每日状态
		state["offered_today"] = false
		state["interacted_today"] = false

		# 检查发现条件
		check_discovery_conditions()

# ============ 存档系统 ============

func serialize() -> Dictionary:
	var npc_states_data = {}
	for npc_id in _npc_states:
		npc_states_data[npc_id] = _npc_states[npc_id].duplicate(true)

	return {
		"npc_states": npc_states_data
	}

func deserialize(data: Dictionary) -> void:
	if data.is_empty():
		print("[HiddenNpcSystem] Empty save data, using defaults")
		return

	var npc_states_data = data.get("npc_states", {})

	# 加载所有仙灵状态
	for npc_id in npc_states_data:
		if _npc_states.has(npc_id):
			_npc_states[npc_id] = npc_states_data[npc_id].duplicate(true)
		else:
			_npc_states[npc_id] = npc_states_data[npc_id].duplicate(true)

			_initialized = true
			print("[HiddenNpcSystem] Loaded hidden NPC data")

# ============ 辅助方法 ============

func _get_npc_name(npc_id: String) -> String:
	for npc in HIDDEN_NPCS:
		if npc["id"] == npc_id:
			return npc.get("name", npc_id)
	return npc_id

# ============ 调试方法 ============

func debug_set_phase(npc_id: String, phase: int) -> void:
	var state = _npc_states.get(npc_id)
	if state:
		state["phase"] = phase
		print("[HiddenNpcSystem] Debug: %s phase set to %d" % [npc_id, phase])

func debug_set_affinity(npc_id: String, amount: int) -> void:
	var state = _npc_states.get(npc_id)
	if state:
		state["affinity"] = amount
		print("[HiddenNpcSystem] Debug: %s affinity set to %d" % [npc_id, amount])

func debug_get_all_states() -> Dictionary:
	var result = {}
	for npc_id in _npc_states:
		var state = _npc_states[npc_id]
		result[npc_id] = {
			"phase": state.get("phase"),
			"affinity": state.get("affinity"),
			"courting": state.get("courting"),
			"bonded": state.get("bonded"),
			"abilities": state.get("unlocked_abilities", [])
		}
	return result
