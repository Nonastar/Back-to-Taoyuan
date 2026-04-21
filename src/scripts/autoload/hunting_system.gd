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

## 狩猎区域信息
const AREA_DATA: Dictionary = {
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

## 猎物数据
const PREY_DATA: Dictionary = {
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

## 狩猎技能等级
var _hunting_skill_level: int = 0

## 共享随机数生成器
var _rng: RandomNumberGenerator

# ============ 初始化 ============

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_initialize_areas()
	_connect_signals()
	print("[HuntingSystem] Initialized")

func _initialize_areas() -> void:
	for area in AREA_DATA.keys():
		_area_states[area] = PreyState.AVAILABLE
		_last_spawn_time[area] = -999  # 初始全部可用

func _connect_signals() -> void:
	if EventBus and EventBus.has_signal("time_sleep_triggered"):
		EventBus.time_sleep_triggered.connect(_on_sleep_triggered)

func _on_sleep_triggered(_bedtime: int, _forced: bool) -> void:
	# 每日结算：所有区域刷新猎物
	_daily_respawn()

# ============ 狩猎区域 API ============

## 获取所有狩猎区域信息
func get_all_areas() -> Array:
	var result: Array = []
	for area_id in AREA_DATA.keys():
		var data = AREA_DATA[area_id].duplicate()
		data["area_id"] = area_id
		data["state"] = _area_states.get(area_id, PreyState.COOLDOWN)
		data["available"] = _area_states.get(area_id, PreyState.COOLDOWN) == PreyState.AVAILABLE
		# 计算剩余冷却时间
		var last_spawn = _last_spawn_time.get(area_id, -999)
		var respawn_min = AREA_DATA[area_id].get("respawn_minutes", 10)
		var current_time = TimeManager.current_minute_of_day if TimeManager else 0
		var elapsed = current_time - last_spawn
		data["cooldown_remaining"] = maxf(0.0, respawn_min - elapsed)
		result.append(data)
	return result

## 检查区域是否可狩猎
func is_area_available(area: int) -> bool:
	return _area_states.get(area, PreyState.COOLDOWN) == PreyState.AVAILABLE

## 获取区域信息
func get_area_info(area: int) -> Dictionary:
	var data = AREA_DATA.get(area, {})
	var result = data.duplicate()
	result["area_id"] = area
	result["state"] = _area_states.get(area, PreyState.COOLDOWN)
	result["available"] = _area_states.get(area, PreyState.COOLDOWN) == PreyState.AVAILABLE
	return result

# ============ 狩猎操作 ============

## 尝试狩猎指定区域
## 返回: {success, prey_id, drops, message}
func hunt_in_area(area: int) -> Dictionary:
	if not AREA_DATA.has(area):
		return {"success": false, "message": "无效狩猎区域"}

	if not is_area_available(area):
		var cooldown = _get_cooldown_remaining(area)
		return {
			"success": false,
			"message": "该区域猎物尚未刷新 (还需 %d 分钟)" % cooldown
		}

	# 检查狩猎技能
	var skill_level = _get_hunting_skill_level()
	if skill_level < 1:
		return {"success": false, "message": "需要先提升狩猎技能"}

	# 选择猎物类型
	var prey_types = AREA_DATA[area].get("prey_types", [])
	if prey_types.is_empty():
		return {"success": false, "message": "该区域无猎物"}

	var prey_id = prey_types[_rng.randi() % prey_types.size()]
	var prey_info = PREY_DATA.get(prey_id, {})

	# 计算掉落
	var drops = _calculate_drops(prey_id, skill_level)

	# 消耗狩猎技能计时（每次狩猎消耗体力/冷却）
	var cooldown_result = _use_hunting_cooldown(area)
	if not cooldown_result:
		return {"success": false, "message": "狩猎失败，请稍后再试"}

	# 更新区域状态
	_area_states[area] = PreyState.COOLDOWN
	_last_spawn_time[area] = TimeManager.current_minute_of_day if TimeManager else 0

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
	if not AREA_DATA.has(area):
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
	if SkillSystem and SkillSystem.has_method("get_skill_level"):
		return SkillSystem.get_skill_level("hunting")
	return 0

func _get_cooldown_remaining(area: int) -> int:
	var last_spawn = _last_spawn_time.get(area, -999)
	var respawn_min = AREA_DATA[area].get("respawn_minutes", 10)
	var current_time = TimeManager.current_minute_of_day if TimeManager else 0
	var elapsed = current_time - last_spawn
	return maxi(0, respawn_min - elapsed)

func _use_hunting_cooldown(area: int) -> bool:
	# 使用狩猎技能（消耗体力或触发冷却）
	if SkillSystem and SkillSystem.has_method("use_skill"):
		return SkillSystem.use_skill("hunting", 1)
	return true

func _calculate_drops(prey_id: String, skill_level: int) -> Array:
	var prey_info = PREY_DATA.get(prey_id, {})
	var drop_list = prey_info.get("drops", [])
	var drop_rate = prey_info.get("drop_rate", 0.5)
	var base_value = prey_info.get("value", 10)

	var drops: Array = []
	for drop_item in drop_list:
		# 技能加成：每级 +5% 掉落率
		var effective_rate = drop_rate + (skill_level * 0.05)
		if _rng.randf() < effective_rate:
			var quality = _calculate_drop_quality(skill_level)
			drops.append({
				"item_id": drop_item,
				"quantity": 1,
				"quality": quality
			})
			# Prospector 天赋: 双倍掉落
			if SkillSystem and SkillSystem.has_method("has_talent") and SkillSystem.has_talent("prospector"):
				if _rng.randf() < 0.15:
					drops.append({"item_id": drop_item, "quantity": 1, "quality": quality})
	return drops

func _calculate_drop_quality(skill_level: int) -> int:
	# 技能加成高品质概率
	var quality_chance = 0.05 + (skill_level * 0.02)
	var roll = _rng.randf()
	if roll < 0.01:
		return Quality.SUPREME
	elif roll < 0.01 + 0.09:
		return Quality.EXCELLENT
	elif roll < quality_chance:
		return Quality.FINE
	return Quality.NORMAL

func _daily_respawn() -> void:
	for area in AREA_DATA.keys():
		_area_states[area] = PreyState.AVAILABLE
		_last_spawn_time[area] = -999  # 重置
		var prey_types = AREA_DATA[area].get("prey_types", [])
		if not prey_types.is_empty():
			prey_spawned.emit(area, prey_types[_rng.randi() % prey_types.size()])
	area_respawned.emit(-1)  # -1 = 所有区域

# ============ 存档支持 ============

func serialize() -> Dictionary:
	return {
		"area_states": _area_states,
		"last_spawn_time": _last_spawn_time
	}

func deserialize(data: Dictionary) -> void:
	_area_states = data.get("area_states", {})
	_last_spawn_time = data.get("last_spawn_time", {})
	# 确保所有区域初始化
	for area in AREA_DATA.keys():
		if not _area_states.has(area):
			_area_states[area] = PreyState.AVAILABLE
		if not _last_spawn_time.has(area):
			_last_spawn_time[area] = -999
	print("[HuntingSystem] Loaded: areas=%d" % _area_states.size())