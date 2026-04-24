extends Node

## DialogueSystem - 对话/事件系统 MVP
## 管理 NPC 对话文本、事件触发和分支选择
## P15: 与 C07(NPC好感度)、P08(任务系统) 协作
## MVP: 对话状态机 + 优先级选择 + 变量替换 + 选择效果

# ============ 常量 ============

## 对话类型
enum DialogueType {
	DAILY = 0,        # 每日普通对话
	FRIENDSHIP = 1,   # 好感等级对话
	WEATHER = 2,      # 天气对话
	BIRTHDAY = 3,     # 生日对话
	FESTIVAL = 4,     # 节日对话
	HEART = 5,        # 心事件对话
	SPECIAL = 6       # 特殊对话
}

## 对话状态
enum DialogueState {
	IDLE = 0,              # 无对话进行
	DIALOGUE_ACTIVE = 1,  # 对话进行中
	CHOICE_ACTIVE = 2,      # 选择等待中
	EVENT_ACTIVE = 3,       # 事件进行中
	DIALOGUE_ENDED = 4     # 对话结束
}

## 好感等级
enum FriendshipLevel {
	STRANGER = 0,
	ACQUAINTANCE = 1,
	FRIENDLY = 2,
	BEST_FRIEND = 3
}

## 调优参数
const TEXT_SPEED: int = 30          # 每秒显示字符数
const MAX_DAILY_DIALOGUES: int = 5   # 每日对话池大小
const DIALOGUE_HISTORY_SIZE: int = 10

## 季节枚举到字符串映射（用于变量替换）
const SEASON_KEYS: Dictionary = {
	0: "春季", 1: "夏季", 2: "秋季", 3: "冬季"
}

# ============ 数据 ============

## 示例对话数据（MVP: merchant_chen 商贩陈伯）
## 数据格式规范:
##   daily: Array[String] — 每日对话池
##   by_friendship_level: Dictionary[level_key -> Array[String]] — 好感等级对话
##   weather_dialogue: Dictionary[weather_key -> Array[String]] — 天气对话（必须是数组）
const DIALOGUE_DATA: Dictionary = {
	"merchant_chen": {
		"name": "陈伯",
		"daily": [
			"今天天气不错，适合赶集啊。",
			"我这儿的货，都是从城里进来的，品质有保证！",
			"哎呀，生意难做啊……但看到你们年轻人，我就高兴。",
			"你家的农场打理得不错，继续努力！"
		],
		"by_friendship_level": {
			"stranger": [
				"你好，初次见面，我是陈伯。"
			],
			"acquaintance": [
				"又见面了，今天想买点什么？"
			],
			"friendly": [
				"哟，老朋友来了！给你留了好货。"
			],
			"best_friend": [
				"你是我最好的朋友！这东西便宜卖你。"
			]
		},
		"weather_dialogue": {
			"rainy": ["下雨天啊，正好在家歇歇。对了，雨天适合钓大鱼！"],
			"sunny": ["大晴天！今天生意应该不错。"]
		}
	},
	"healer_xu": {
		"name": "徐大夫",
		"daily": [
			"年轻人，要注意身体啊！",
			"我这儿的药，都是亲手炮制的。"
		],
		"by_friendship_level": {
			"stranger": [
				"你好，我是徐大夫。"
			],
			"acquaintance": [
				"又来了？最近身体可好？"
			],
			"friendly": [
				"朋友来了！来，喝杯茶。"
			],
			"best_friend": [
				"最好的朋友！有什么不舒服尽管来找我。"
			]
		},
		"weather_dialogue": {
			"rainy": ["雨天湿气重，多喝点祛湿茶。"]
		}
	}
}

# ============ 信号 ============

## P15 发出的信号
signal dialogue_started(npc_id: String, dialogue_type: int)
signal dialogue_ended(npc_id: String)
signal dialogue_text_ready(npc_id: String, text: String)
signal choice_shown(npc_id: String, choices: Array)
signal choice_selected(npc_id: String, choice_id: String, effects: Dictionary)

# ============ 状态 ============

## 对话状态
var _state: int = DialogueState.IDLE

## 当前对话 NPC
var _current_npc_id: String = ""

## 对话队列
var _dialogue_queue: Array = []

## 已触发的永久事件（防止重复触发）
var _triggered_events: Dictionary = {}

## 对话变量
var _dialogue_vars: Dictionary = {}

## 对话历史
var _dialogue_history: Array = []

## 待处理心事件
var _pending_heart_events: Array = []

## 共享随机数生成器（避免每帧创建实例）
var _rng: RandomNumberGenerator

# ============ 初始化 ============

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_connect_signals()
	print("[DialogueSystem] Initialized")

func _connect_signals() -> void:
	# 订阅 C07 NpcFriendshipSystem
	if NpcFriendshipSystem:
		NpcFriendshipSystem.friendship_changed.connect(_on_friendship_changed)
		NpcFriendshipSystem.heart_event_triggered.connect(_on_heart_event_triggered)
	# 订阅 P08 QuestSystem
	if QuestSystem:
		QuestSystem.quest_completed.connect(_on_quest_completed)
	# 订阅天气变化
	if EventBus:
		EventBus.weather_changed.connect(_on_weather_changed)

# ============ 公共 API ============

## 与 NPC 开始对话（由 InteractionSystem 或 UI 调用）
func start_dialogue(npc_id: String) -> Dictionary:
	if _state != DialogueState.IDLE:
		return {"success": false, "message": "对话正在进行中"}

	if not DIALOGUE_DATA.has(npc_id):
		return {"success": false, "message": "该NPC无对话数据"}

	_current_npc_id = npc_id
	var dialogue_type = _select_dialogue_type(npc_id)
	var text = _get_dialogue_text(npc_id, dialogue_type)

	if text.is_empty():
		text = "今天没什么想说的。"

	_state = DialogueState.DIALOGUE_ACTIVE
	dialogue_started.emit(npc_id, dialogue_type)

	var resolved_text = _resolve_variables(text)
	dialogue_text_ready.emit(npc_id, resolved_text)
	_add_to_history(npc_id, resolved_text)

	return {
		"success": true,
		"npc_id": npc_id,
		"type": dialogue_type,
		"text": resolved_text
	}

## 继续对话（打字完成或点击继续）
func advance_dialogue() -> Dictionary:
	if _state == DialogueState.IDLE:
		return {"success": false, "message": "无进行中的对话"}
	if _state == DialogueState.CHOICE_ACTIVE:
		return {"success": false, "message": "请先选择选项"}

	# 检查是否有后续对话
	var choices = _get_choices(_current_npc_id, _get_current_dialogue_id())
	if not choices.is_empty():
		_state = DialogueState.CHOICE_ACTIVE
		choice_shown.emit(_current_npc_id, choices)
		return {
			"success": true,
			"state": "choice",
			"choices": choices
		}

	return end_dialogue()

## 选择对话选项
func select_choice(choice_id: String) -> Dictionary:
	if _state != DialogueState.CHOICE_ACTIVE:
		return {"success": false, "message": "无选择进行中"}

	var choices = _get_choices(_current_npc_id, _get_current_dialogue_id())
	var selected: Dictionary = {}
	for c in choices:
		if c.get("id") == choice_id:
			selected = c
			break

	if selected.is_empty():
		return {"success": false, "message": "无效选项"}

	choice_selected.emit(_current_npc_id, choice_id, selected)

	# 执行选择效果
	var effects = selected.get("effects", [])
	_execute_choice_effects(effects)

	# 继续对话
	_state = DialogueState.DIALOGUE_ACTIVE
	var next_text = selected.get("next_text", "")
	if not next_text.is_empty():
		var resolved = _resolve_variables(next_text)
		dialogue_text_ready.emit(_current_npc_id, resolved)
		_add_to_history(_current_npc_id, resolved)
		return {"success": true, "state": "active", "text": resolved}
	else:
		return end_dialogue()

## 结束当前对话
func end_dialogue() -> Dictionary:
	var npc_id = _current_npc_id
	_state = DialogueState.IDLE
	_current_npc_id = ""
	dialogue_ended.emit(npc_id)
	return {"success": true, "message": "对话结束"}

## 是否正在进行对话
func is_talking() -> bool:
	return _state != DialogueState.IDLE

## 获取当前 NPC ID
func get_current_npc() -> String:
	return _current_npc_id

## 获取当前对话状态
func get_state() -> int:
	return _state

## 获取 NPC 对话数据（用于 NPC 对话框）
func get_npc_dialogue_data(npc_id: String) -> Dictionary:
	return DIALOGUE_DATA.get(npc_id, {})

## 设置对话变量
func set_variable(key: String, value: Variant) -> void:
	_dialogue_vars[key] = value

## 获取对话变量
func get_variable(key: String, default = null) -> Variant:
	return _dialogue_vars.get(key, default)

# ============ 私有方法 ============

func _select_dialogue_type(npc_id: String) -> int:
	# 优先级: 心事件 > 生日 > 节日 > 好感变化 > 天气 > 普通
	if not _pending_heart_events.is_empty():
		return DialogueType.HEART
	if _is_npc_birthday(npc_id):
		return DialogueType.BIRTHDAY
	if _is_festival_day():
		return DialogueType.FESTIVAL
	if _has_friendship_upgrade(npc_id):
		return DialogueType.FRIENDSHIP
	if _is_special_weather():
		return DialogueType.WEATHER
	return DialogueType.DAILY

func _get_dialogue_text(npc_id: String, dialogue_type: int) -> String:
	var data = DIALOGUE_DATA.get(npc_id, {})
	if data.is_empty():
		return ""

	match dialogue_type:
		DialogueType.DAILY:
			return _random_daily(npc_id, data)
		DialogueType.FRIENDSHIP:
			return _friendship_dialogue(npc_id, data)
		DialogueType.WEATHER:
			return _weather_dialogue(npc_id, data)
		DialogueType.HEART:
			return _heart_event_dialogue(npc_id, data)
		DialogueType.BIRTHDAY:
			return "生日快乐！这是我为你准备的礼物！"
		DialogueType.FESTIVAL:
			return _festival_dialogue(npc_id, data)

	return _random_daily(npc_id, data)

func _random_daily(npc_id: String, data: Dictionary) -> String:
	var pool = data.get("daily", [])
	if pool.is_empty():
		return ""
	return pool[_rng.randi() % pool.size()]

func _friendship_dialogue(npc_id: String, data: Dictionary) -> String:
	var level = NpcFriendshipSystem.get_friendship_level(npc_id) if NpcFriendshipSystem else FriendshipLevel.STRANGER
	var level_key = _level_to_key(level)
	var by_level = data.get("by_friendship_level", {})
	var pool: Array = by_level.get(level_key, [])
	if pool.is_empty():
		return _random_daily(npc_id, data)
	return pool[_rng.randi() % pool.size()]

func _weather_dialogue(npc_id: String, data: Dictionary) -> String:
	var weather = WeatherSystem.today_weather if WeatherSystem else "sunny"
	var weather_pool: Array = data.get("weather_dialogue", {}).get(weather, [])
	if not weather_pool.is_empty():
		return weather_pool[_rng.randi() % weather_pool.size()]
	return _random_daily(npc_id, data)

func _heart_event_dialogue(npc_id: String, data: Dictionary) -> String:
	if _pending_heart_events.is_empty():
		return _random_daily(npc_id, data)
	var event = _pending_heart_events[0]
	_pending_heart_events.remove_at(0)
	return event.get("dialogue", _random_daily(npc_id, data))

func _festival_dialogue(npc_id: String, data: Dictionary) -> String:
	return "节日快乐！今天大家都很高兴呢。"

func _level_to_key(level: int) -> String:
	match level:
		FriendshipLevel.STRANGER: return "stranger"
		FriendshipLevel.ACQUAINTANCE: return "acquaintance"
		FriendshipLevel.FRIENDLY: return "friendly"
		FriendshipLevel.BEST_FRIEND: return "best_friend"
	return "stranger"

func _is_npc_birthday(npc_id: String) -> bool:
	# TODO: 实现生日检查（需要 NPC 数据中的 birthday 字段）
	return false

func _is_festival_day() -> bool:
	# TODO: 实现节日检查
	return false

func _has_friendship_upgrade(_npc_id: String) -> bool:
	# 由 _on_friendship_changed 设置标志
	return false

func _is_special_weather() -> bool:
	if WeatherSystem:
		var w = WeatherSystem.today_weather
		return w in ["rainy", "stormy", "snowy"]
	return false

func _get_choices(npc_id: String, dialogue_id: String) -> Array:
	# TODO: 从对话数据中读取分支选项（MVP 暂不实现）
	return []

func _get_current_dialogue_id() -> String:
	# TODO: 返回当前对话 ID 用于查找后续（MVP 暂用空字符串）
	return ""

func _execute_choice_effects(effects: Array) -> void:
	for effect in effects:
		var type = effect.get("type", "")
		match type:
			"friendship_change":
				var npc_id = effect.get("npc_id", _current_npc_id)
				var value = effect.get("value", 0)
				if NpcFriendshipSystem and value != 0:
					NpcFriendshipSystem.add_friendship(npc_id, value)
			"trigger_event":
				var event_id = effect.get("event_id", "")
				if not event_id.is_empty():
					_trigger_event(event_id)
			"set_variable":
				var key = effect.get("key", "")
				var val = effect.get("value", null)
				if not key.is_empty():
					set_variable(key, val)

func _trigger_event(event_id: String) -> void:
	if _triggered_events.get(event_id, false):
		return
	_triggered_events[event_id] = true
	# TODO: 触发事件对话序列

func _resolve_variables(text: String) -> String:
	var result = text

	# 玩家名称
	if PlayerStats:
		result = result.replace("{player_name}", PlayerStats.player_name)

	# 季节
	if TimeManager:
		result = result.replace("{current_season}", SEASON_KEYS.get(TimeManager.current_season, "春季"))
		result = result.replace("{current_day}", str(TimeManager.current_day))
		result = result.replace("{day_count}", "第%d天" % TimeManager.current_day)

	# 天气
	if WeatherSystem:
		result = result.replace("{weather}", WeatherSystem.today_weather)

	# 自定义变量
	for key in _dialogue_vars:
		result = result.replace("{%s}" % key, str(_dialogue_vars[key]))

	return result

func _add_to_history(npc_id: String, text: String) -> void:
	_dialogue_history.append({
		"npc_id": npc_id,
		"text": text,
		"timestamp": Time.get_ticks_msec()
	})
	if _dialogue_history.size() > DIALOGUE_HISTORY_SIZE:
		_dialogue_history.remove_at(0)

# ============ 事件回调 ============

func _on_friendship_changed(npc_id: String, _old: int, _new: int) -> void:
	# 好感变化时可触发新对话
	pass

func _on_heart_event_triggered(npc_id: String, event_id: String) -> void:
	# C07 触发心事件，P15 提供对话
	print("[DialogueSystem] Heart event triggered: %s / %s" % [npc_id, event_id])
	_pending_heart_events.append({
		"npc_id": npc_id,
		"event_id": event_id,
		"dialogue": "你来了！我……我有件事想跟你说。"
	})

func _on_quest_completed(_quest_id: String, _quest_title: String) -> void:
	# 任务完成时检查特殊对话
	print("[DialogueSystem] Quest completed: %s" % _quest_id)

func _on_weather_changed(_weather: String) -> void:
	# 天气变化时记录
	pass

# ============ 存档支持 ============

func serialize() -> Dictionary:
	return {
		"triggered_events": _triggered_events,
		"dialogue_vars": _dialogue_vars,
		"dialogue_history": _dialogue_history
	}

func deserialize(data: Dictionary) -> void:
	_triggered_events = data.get("triggered_events", {})
	_dialogue_vars = data.get("dialogue_vars", {})
	_dialogue_history = data.get("dialogue_history", [])
	print("[DialogueSystem] Loaded: %d events, %d vars" % [_triggered_events.size(), _dialogue_vars.size()])

# ============ 调试 ============

## 调试：打印所有 NPC 对话类型
func debug_print_all_dialogues() -> void:
	for npc_id in DIALOGUE_DATA:
		var data = DIALOGUE_DATA[npc_id]
		print("[DialogueSystem] NPC: %s (%s)" % [npc_id, data.get("name", "")])
		print("  Daily: %d" % data.get("daily", []).size())
		var by_level = data.get("by_friendship_level", {})
		for lvl in by_level:
			print("  %s: %d" % [lvl, by_level[lvl].size()])
