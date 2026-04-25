extends Node

## HuntingSystem - 狩猎系统 MVP
## 管理狩猎区域、猎物刷新、技能计时
## MVP 范围: 狩猎技能计时 + 猎物刷新 + 掉落计算
## 完整狩猎武器装备/小游戏延期至后续 Sprint

# ============ 常量 ============

## 狩猎区域
enum HuntingArea {
	BUSHES = 0,   # 灌木丛：小型猎物，刷新快
	FOREST = 1,  # 森林：中型猎物，中速刷新
	LAKE = 2     # 湖泊：水禽/大型猎物，慢刷新
}

## 狩猎区域信息（默认常量，运行时通过 JSON 覆盖）
const AREA_DATA_DEFAULT: Dictionary = {
	HuntingArea.BUSHES: {
		"name": "灌木丛",
		"description": "小型猎物出没区域",
		"respawn_minutes": 5,
		"prey_types": ["rabbit", "bird", "squirrel"]
	},
	HuntingArea.FOREST: {
		"name": "森林",
		"description": "中型猎物出没区域",
		"respawn_minutes": 10,
		"prey_types": ["deer", "boar", "fox"]
	},
	HuntingArea.LAKE: {
		"name": "湖泊",
		"description": "水禽和大型猎物出没区域",
		"respawn_minutes": 15,
		"prey_types": ["duck_wild", "goose", "heron"]
	}
}

## 猎物数据（默认常量，运行时通过 JSON 覆盖）
const PREY_DATA_DEFAULT: Dictionary = {
	"rabbit": {"name": "野兔", "drops": ["fur", "meat"], "drop_rate": 0.8, "value": 15},
	"bird": {"name": "野鸟", "drops": ["feather", "egg"], "drop_rate": 0.7, "value": 10},
	"squirrel": {"name": "松鼠", "drops": ["nut", "fur"], "drop_rate": 0.6, "value": 8},
	"deer": {"name": "鹿", "drops": ["antler", "meat", "leather"], "drop_rate": 0.5, "value": 50},
	"boar": {"name": "野猪", "drops": ["tusk", "meat", "leather"], "drop_rate": 0.5, "value": 40},
	"fox": {"name": "狐狸", "drops": ["fur", "tail"], "drop_rate": 0.4, "value": 30},
	"duck_wild": {"name": "野鸭", "drops": ["feather", "egg", "meat"], "drop_rate": 0.7, "value": 20},
	"goose": {"name": "鹅", "drops": ["feather", "egg"], "drop_rate": 0.6, "value": 25},
	"heron": {"name": "苍鹭", "drops": ["feather"], "drop_rate": 0.3, "value": 35}
}

## 品质掉落阈值（默认常量，运行时通过 JSON 覆盖）
const QUALITY_DATA_DEFAULT: Dictionary = {
	"supreme_threshold": 0.01,
	"excellent_threshold": 0.10,
	"fine_threshold": 0.15,
	"skill_drop_rate_bonus_per_level": 0.05,
	"prospector_double_drop_chance": 0.15
}

## 猎物状态
enum PreyState {
	AVAILABLE,  # 可狩猎
	COOLDOWN,   # 刷新中
	HUNTED      # 刚被狩猎
}

# ============ 信号 ============

signal prey_hunted(prey_id: String, drops: Array)
signal prey_spawned(area: int, prey_id: String)
signal area_respawned(area: int)

# ============ 状态 ============

## 每区域猎物状态 {area: PreyState}
var _area_states: Dictionary = {}

## 每区域最后刷新时间 {area: int} (game minutes)
var _last_spawn_time: Dictionary = {}

## 狩猎技能等级（自管理，不依赖 SkillSystem）
## 现在使用 SkillSystem.SkillType.HUNTING，直接从 SkillSystem 获取
var _hunting_skill_level: int = 0

## 共享随机数生成器
var _rng: RandomNumberGenerator

## 狩猎冷却状态
var _hunt_cooldown_active: bool = false

## 运行时数据（从 JSON 加载，const 为默认值兜底）
var _area_data: Dictionary = AREA_DATA_DEFAULT.duplicate()
var _prey_data: Dictionary = PREY_DATA_DEFAULT.duplicate()

## 当前生效的狩猎区域数据（供外部只读访问）
func get_area_data() -> Dictionary:
	return _area_data

## 当前生效的猎物数据（供外部只读访问）
func get_prey_data() -> Dictionary:
	return _prey_data

var _quality_data: Dictionary = QUALITY_DATA_DEFAULT.duplicate()

# ============ 初始化 ============

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_initialize_from_json()
	_initialize_areas()
	_connect_signals()
	print("[HuntingSystem] Initialized")

func _initialize_from_json() -> void:
	if DataLoader:
		var data = DataLoader.load_json("hunting_data.json")
		if not data.is_empty():
			_area_data = _parse_area_data(data.get("areas", {}))
			_prey_data = data.get("prey", {})
			_quality_data = data.get("quality", QUALITY_DATA_DEFAULT.duplicate())
			print("[HuntingSystem] Loaded config from JSON")
			return
	print("[HuntingSystem] No hunting_data.json found, using built-in defaults")

func _initialize_areas() -> void:
	for area in _area_data.keys():
		_area_states[area] = PreyState.AVAILABLE
		_last_spawn_time[area] = -999  # 初始全部可用

## 解析区域数据（JSON 键为字符串，转换为枚举 int）
func _parse_area_data(areas_json: Dictionary) -> Dictionary:
	var result = {}
	for key in areas_json.keys():
		var area_id = int(key)
		if area_id >= 0:
			result[area_id] = areas_json[key]
	return result

func _connect_signals() -> void:
	if EventBus and EventBus.has_signal("time_sleep_triggered"):
		EventBus.time_sleep_triggered.connect(_on_sleep_triggered)
	# 监听技能升级信号（未来 SkillSystem 支持 HUNTING 后可同步等级）
	if EventBus and EventBus.has_signal("skill_level_up"):
		EventBus.skill_level_up.connect(_on_skill_level_up)

func _on_sleep_triggered(_bedtime: int, _forced: bool) -> void:
	# 每日结算：所有区域刷新猎物
	_daily_respawn()
	# 重置狩猎冷却
	_hunt_cooldown_active = false

## 监听技能升级信号，同步狩猎技能等级
func _on_skill_level_up(skill_type: int, _old_level: int, _new_level: int) -> void:
	if SkillSystem and skill_type == SkillSystem.SkillType.HUNTING:
		_hunting_skill_level = _new_level
		print("[HuntingSystem] Hunting skill synced from SkillSystem: Lv.%d" % _new_level)

# ============ 狩猎区域 API ============

## 获取所有狩猎区域信息
func get_all_areas() -> Array:
	var result: Array = []
	for area_id in _area_data.keys():
		var data = _area_data[area_id].duplicate()
		data["area_id"] = area_id
		data["state"] = _area_states.get(area_id, PreyState.AVAILABLE)
		data["available"] = is_area_available(area_id)
		# 计算剩余冷却时间（使用绝对游戏分钟）
		var last_spawn = _last_spawn_time.get(area_id, -999999)
		var respawn_min = _area_data[area_id].get("respawn_minutes", 10)
		var elapsed = _get_current_game_minutes() - last_spawn
		data["cooldown_remaining"] = maxf(0.0, respawn_min - elapsed)
		result.append(data)
	return result

## 检查区域是否可狩猎（经过足够时间则自动恢复可用）
func is_area_available(area: int) -> bool:
	var state = _area_states.get(area, PreyState.AVAILABLE)
	if state == PreyState.AVAILABLE:
		return true
	# 处于刷新中：检查是否已经过了足够时间，自动恢复可用
	var last_spawn = _last_spawn_time.get(area, -999999)
	var respawn_min = _area_data[area].get("respawn_minutes", 10)
	var elapsed = _get_current_game_minutes() - last_spawn
	if elapsed >= respawn_min:
		_area_states[area] = PreyState.AVAILABLE
		area_respawned.emit(area)
		return true
	return false

## 获取区域信息
func get_area_info(area: int) -> Dictionary:
	var data = _area_data.get(area, {})
	var result = data.duplicate()
	result["area_id"] = area
	result["state"] = _area_states.get(area, PreyState.AVAILABLE)
	result["available"] = is_area_available(area)
	return result

# ============ 狩猎操作 API（公开设置技能等级，供测试/调试用）============

## 设置狩猎技能等级（未来由 SkillSystem 驱动）
func set_hunting_skill_level(level: int) -> void:
	_hunting_skill_level = clampi(level, 0, 10)
	print("[HuntingSystem] Skill level set to: %d" % _hunting_skill_level)

# ============ 狩猎操作 ============

## 尝试狩猎指定区域
## 返回: {success, prey_id, drops, message}
func hunt_in_area(area: int) -> Dictionary:
	if not _area_data.has(area):
		return {"success": false, "message": "无效狩猎区域"}

	if not is_area_available(area):
		var cooldown = _get_cooldown_remaining(area)
		return {
			"success": false,
			"message": "该区域猎物尚未刷新 (还需 %d 分钟)" % cooldown
		}

	# 任意等级均可狩猎（技能等级影响掉落率和品质，不限制参与）
	var skill_level = _get_hunting_skill_level()

	# 选择猎物类型
	var prey_types = _area_data[area].get("prey_types", [])
	if prey_types.is_empty():
		return {"success": false, "message": "该区域无猎物"}

	var prey_id = prey_types[_rng.randi() % prey_types.size()]
	var prey_info = _prey_data.get(prey_id, {})

	# 计算掉落
	var drops = _calculate_drops(prey_id, skill_level)

	# 消耗狩猎技能计时（已由 is_area_available 预检查，这里仅记录狩猎时间戳）
	_use_hunting_cooldown(area)

	# 更新区域状态
	_area_states[area] = PreyState.COOLDOWN
	_last_spawn_time[area] = _get_current_game_minutes()

	prey_hunted.emit(prey_id, drops)

	# 添加掉落物品到背包
	var item_count = 0
	for drop in drops:
		var drop_id = drop.get("item_id", "")
		var drop_qty = drop.get("quantity", 1)
		var drop_quality = drop.get("quality", Quality.NORMAL)
		if not drop_id.is_empty() and InventorySystem:
			InventorySystem.add_item(drop_id, drop_qty, drop_quality)
			item_count += drop_qty

	# 给予狩猎经验
	var exp_amount = prey_info.get("exp", 0)
	if exp_amount > 0 and SkillSystem:
		SkillSystem.add_exp(SkillSystem.SkillType.HUNTING, exp_amount)

	var prey_name = prey_info.get("name", prey_id)
	return {
		"success": true,
		"prey_id": prey_id,
		"prey_name": prey_name,
		"drops": drops,
		"items_added": item_count,
		"message": "狩猎成功! 获得了 %s" % prey_name
	}

## 检查指定区域当前是否有猎物
func check_area_status(area: int) -> Dictionary:
	if not _area_data.has(area):
		return {"available": false, "cooldown": 0, "reason": "无效区域"}

	if is_area_available(area):
		return {"available": true, "cooldown": 0, "reason": ""}

	var cooldown = _get_cooldown_remaining(area)
	return {
		"available": false,
		"cooldown": cooldown,
		"reason": "猎物刷新中"
	}

# ============ 私有方法 ============

func _get_hunting_skill_level() -> int:
	# 直接从 SkillSystem 获取狩猎技能等级
	if SkillSystem and SkillSystem.has_method("get_level"):
		return SkillSystem.get_level(SkillSystem.SkillType.HUNTING)
	return _hunting_skill_level

func _get_cooldown_remaining(area: int) -> int:
	if _area_states.get(area, PreyState.AVAILABLE) == PreyState.AVAILABLE:
		return 0
	var last_spawn = _last_spawn_time.get(area, -999999)
	var respawn_min = _area_data[area].get("respawn_minutes", 10)
	var elapsed = _get_current_game_minutes() - last_spawn
	return maxi(0, respawn_min - elapsed)

## 计算当前绝对游戏分钟数（天*1440 + 小时*60），用于精确计算经过时间
func _get_current_game_minutes() -> int:
	if TimeManager:
		var days = TimeManager.get_total_days()
		var hour = TimeManager.current_hour
		return days * 1440 + hour * 60
	return 0

func _use_hunting_cooldown(area: int) -> bool:
	# 狩猎冷却通过每区域的 _area_states[area] + respawn_minutes 独立管理
	# 此函数仅用于标记该次狩猎已完成（已被 hunt_in_area 调用前检查覆盖）
	return true

func _calculate_drops(prey_id: String, skill_level: int) -> Array:
	var prey_info = _prey_data.get(prey_id, {})
	var drop_list = prey_info.get("drops", [])
	var drop_rate = prey_info.get("drop_rate", 0.5)

	var drops: Array = []
	for drop_item in drop_list:
		# 技能加成：每级 +5% 掉落率（可由 JSON 配置）
		var skill_bonus_per_level = _quality_data.get("skill_drop_rate_bonus_per_level", 0.05)
		var effective_rate = drop_rate + (skill_level * skill_bonus_per_level)
		if _rng.randf() < effective_rate:
			var quality = _calculate_drop_quality(skill_level)
			drops.append({
				"item_id": drop_item,
				"quantity": 1,
				"quality": quality
			})
			# Prospector 天赋: 双倍掉落
			var prospector_chance = _quality_data.get("prospector_double_drop_chance", 0.15)
			if SkillSystem and SkillSystem.has_method("has_talent") and SkillSystem.has_talent("prospector"):
				if _rng.randf() < prospector_chance:
					drops.append({"item_id": drop_item, "quantity": 1, "quality": quality})
	return drops

func _calculate_drop_quality(skill_level: int) -> int:
	var roll = _rng.randf()
	var supreme_th = _quality_data.get("supreme_threshold", 0.01)
	var excellent_th = _quality_data.get("excellent_threshold", 0.10)
	var fine_th = _quality_data.get("fine_threshold", 0.15)
	if roll < supreme_th:
		return Quality.SUPREME
	elif roll < excellent_th:
		return Quality.EXCELLENT
	elif roll < fine_th:
		return Quality.FINE
	return Quality.NORMAL

func _daily_respawn() -> void:
	for area in _area_data.keys():
		_area_states[area] = PreyState.AVAILABLE
		_last_spawn_time[area] = -999  # 重置
		var prey_types = _area_data[area].get("prey_types", [])
		if not prey_types.is_empty():
			prey_spawned.emit(area, prey_types[_rng.randi() % prey_types.size()])
	area_respawned.emit(-1)  # -1 = 所有区域

# ============ 存档支持 ============

func serialize() -> Dictionary:
	return {
		"area_states": _area_states,
		"last_spawn_time": _last_spawn_time,
		"hunting_skill_level": _hunting_skill_level,
		"hunt_cooldown_active": _hunt_cooldown_active
	}

func deserialize(data: Dictionary) -> void:
	_area_states = data.get("area_states", {})
	_last_spawn_time = data.get("last_spawn_time", {})
	_hunting_skill_level = data.get("hunting_skill_level", 0)
	_hunt_cooldown_active = data.get("hunt_cooldown_active", false)
	# 确保所有区域初始化
	for area in _area_data.keys():
		if not _area_states.has(area):
			_area_states[area] = PreyState.AVAILABLE
		if not _last_spawn_time.has(area):
			_last_spawn_time[area] = -999
	print("[HuntingSystem] Loaded: areas=%d, skill_level=%d" % [_area_states.size(), _hunting_skill_level])
