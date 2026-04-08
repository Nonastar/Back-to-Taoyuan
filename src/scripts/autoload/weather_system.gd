extends Node

## WeatherSystem - 天气系统
## 负责天气生成、天气预报和天气影响
## 参考: F02 天气系统 GDD

# ============ 天气类型常量 ============

## 天气类型
const WEATHER_SUNNY: String = "sunny"
const WEATHER_RAINY: String = "rainy"
const WEATHER_STORMY: String = "stormy"
const WEATHER_SNOWY: String = "snowy"
const WEATHER_WINDY: String = "windy"
const WEATHER_GREEN_RAIN: String = "green_rain"

# ============ 常量 ============

## 体力消耗修正
const RAINY_STAMINA_MOD: float = 0.9
const STORMY_STAMINA_MOD: float = 0.8
const SNOWY_STAMINA_MOD: float = 0.7
const GREEN_RAIN_STAMINA_MOD: float = 0.9

## 活动收益修正
const RAINY_ACTIVITY_MOD: float = 0.9
const STORMY_ACTIVITY_MOD: float = 0.8
const GREEN_RAIN_FISHING_MOD: float = 1.1

## 农作物增产
const GREEN_RAIN_CROP_MOD: float = 1.1

## 雷击概率
const LIGHTNING_STRIKE_CHANCE: float = 0.05

## 大风浇水损失概率
const WINDY_CROP_LOSS_CHANCE: float = 0.3

## 唤雨能力加成
const RAIN_BOOST_AMOUNT: float = 0.15

## 绿雨特殊事件
const GREEN_RAIN_YEAR: int = 1
const GREEN_RAIN_SEASON: int = 1  # Summer
const GREEN_RAIN_DAY: int = 5

## 固定天气日
const FIXED_WEATHER: Dictionary = {
	0: {1: "sunny"},  # Spring Day 1: sunny
	1: {13: "stormy", 26: "stormy"}  # Summer Day 13, 26: stormy
}

## 节日列表 (永远晴天)
const FESTIVAL_DAYS: Dictionary = {
	0: [1, 8, 15, 24],  # Spring festivals
	1: [],  # Summer
	2: [9, 16, 23],  # Autumn
	3: [8, 15, 22]  # Winter
}

# ============ 春季天气概率 ============

const SPRING_WEATHER_TABLE: Array = [
	{"weather": WEATHER_SUNNY, "threshold": 0.50},
	{"weather": WEATHER_RAINY, "threshold": 0.75},
	{"weather": WEATHER_STORMY, "threshold": 0.85},
	{"weather": WEATHER_WINDY, "threshold": 1.00}
]

# ============ 夏季天气概率 ============

const SUMMER_WEATHER_TABLE: Array = [
	{"weather": WEATHER_GREEN_RAIN, "threshold": 0.08},
	{"weather": WEATHER_SUNNY, "threshold": 0.42},
	{"weather": WEATHER_RAINY, "threshold": 0.68},
	{"weather": WEATHER_STORMY, "threshold": 0.83},
	{"weather": WEATHER_WINDY, "threshold": 1.00}
]

# ============ 秋季天气概率 ============

const AUTUMN_WEATHER_TABLE: Array = [
	{"weather": WEATHER_SUNNY, "threshold": 0.45},
	{"weather": WEATHER_RAINY, "threshold": 0.70},
	{"weather": WEATHER_STORMY, "threshold": 0.80},
	{"weather": WEATHER_WINDY, "threshold": 1.00}
]

# ============ 冬季天气概率 ============

const WINTER_WEATHER_TABLE: Array = [
	{"weather": WEATHER_SUNNY, "threshold": 0.50},
	{"weather": WEATHER_SNOWY, "threshold": 0.80},
	{"weather": WEATHER_WINDY, "threshold": 1.00}
]

# ============ 天气数据 ============

## 当前日天气
var today_weather: String = WEATHER_SUNNY

## 明日天气预报
var tomorrow_weather: String = WEATHER_SUNNY

## 玩家天气覆盖
var has_player_override: bool = false
var player_override_weather: String = ""

## 是否为绿雨特殊状态
var is_green_rain_active: bool = false

# ============ 状态 ============

## 是否已初始化
var _initialized: bool = false

## 唤雨能力是否激活
var _rain_boost_active: bool = false

## 调试模式
var _debug_mode: bool = false

# ============ 信号 ============

## 天气变化信号
signal weather_changed(new_weather: String, old_weather: String)

## 天气预报更新信号
signal forecast_updated(tomorrow_weather: String)

## 雷击警告信号
signal lightning_strike_warning()

# ============ 初始化 ============

func _ready() -> void:
	_initialize()
	_connect_signals()

## 初始化
func _initialize() -> void:
	if _initialized:
		return

	# 初始化为晴天
	today_weather = WEATHER_SUNNY
	tomorrow_weather = WEATHER_SUNNY

	_initialized = true

## 连接信号
func _connect_signals() -> void:
	# 连接TimeManager信号
	if EventBus.has_signal("day_changed"):
		EventBus.day_changed.connect(_on_day_changed)
	if EventBus.has_signal("season_changed"):
		EventBus.season_changed.connect(_on_season_changed)
	if EventBus.has_signal("year_changed"):
		EventBus.year_changed.connect(_on_year_changed)

# ============ 信号处理 ============

## 日期变化回调
func _on_day_changed(day: int, season: String) -> void:
	# 更新今日天气为明天的预报
	var old_weather = today_weather
	today_weather = tomorrow_weather

	# 触发绿雨检查
	_check_green_rain()

	# 如果天气变化，发送信号
	if today_weather != old_weather:
		weather_changed.emit(today_weather, old_weather)

	# 生成新的明日预报
	_roll_tomorrow_weather()

## 季节变化回调
func _on_season_changed(season: String, year: int) -> void:
	# 季节变化时重新roll明日预报
	_roll_tomorrow_weather()

## 年份变化回调
func _on_year_changed(year: int) -> void:
	# 新年开始时重置绿雨状态
	is_green_rain_active = false

## 检查绿雨特殊事件
func _check_green_rain() -> void:
	# 注意：这里需要获取当前年/季节/日期
	# 从TimeManager获取
	var year = 1
	var season_idx = 0
	var day = 1

	if TimeManager != null:
		year = TimeManager.current_year
		season_idx = TimeManager.current_season
		day = TimeManager.current_day

	# Year 1 Summer Day 5 触发绿雨
	if year == GREEN_RAIN_YEAR and season_idx == GREEN_RAIN_SEASON and day == GREEN_RAIN_DAY:
		today_weather = WEATHER_GREEN_RAIN
		is_green_rain_active = true
		if _debug_mode:
			print("[WeatherSystem] Green rain triggered: Year %d, Summer Day %d" % [year, day])

# ============ 天气生成 ============

## Roll明日天气
func _roll_tomorrow_weather() -> void:
	# 如果有玩家覆盖，保持玩家指定的天气
	if has_player_override:
		tomorrow_weather = player_override_weather
		forecast_updated.emit(tomorrow_weather)
		return

	# 获取当前季节索引
	var season_idx = 0
	var tomorrow_season_idx = 0
	var day = 1

	if TimeManager != null:
		season_idx = TimeManager.current_season
		tomorrow_season_idx = season_idx
		day = TimeManager.current_day

		# 计算明日日期
		var tomorrow_day = day + 1
		if tomorrow_day > 28:
			tomorrow_day = 1
			tomorrow_season_idx = (season_idx + 1) % 4

	# 检查明日是否为节日
	if _is_festival_day(tomorrow_day, tomorrow_season_idx):
		tomorrow_weather = WEATHER_SUNNY
		forecast_updated.emit(tomorrow_weather)
		return

	# 检查是否为固定天气日
	var fixed = _get_fixed_weather(tomorrow_day, tomorrow_season_idx)
	if fixed != "":
		tomorrow_weather = fixed
		forecast_updated.emit(tomorrow_weather)
		return

	# 按概率分布随机生成
	tomorrow_weather = _roll_weather_by_season(tomorrow_season_idx)
	forecast_updated.emit(tomorrow_weather)

	if _debug_mode:
		print("[WeatherSystem] Tomorrow weather rolled: ", tomorrow_weather)

## 根据季节概率表生成天气
func _roll_weather_by_season(season_idx: int) -> String:
	var table = _get_weather_table(season_idx)
	var roll = randf()

	# 应用唤雨能力加成
	if _rain_boost_active:
		# rainy boost: 晴天概率降低，雨天概率增加
		roll = mini(roll + RAIN_BOOST_AMOUNT, 0.99)

	for entry in table:
		if roll < entry["threshold"]:
			return entry["weather"]

	return WEATHER_SUNNY

## 获取季节天气表
func _get_weather_table(season_idx: int) -> Array:
	match season_idx:
		0: return SPRING_WEATHER_TABLE
		1: return SUMMER_WEATHER_TABLE
		2: return AUTUMN_WEATHER_TABLE
		3: return WINTER_WEATHER_TABLE
		_: return SPRING_WEATHER_TABLE

## 检查是否为节日
func _is_festival_day(day: int, season_idx: int) -> bool:
	var festivals = FESTIVAL_DAYS.get(season_idx, [])
	return day in festivals

## 获取固定天气日
func _get_fixed_weather(day: int, season_idx: int) -> String:
	var season_fixed = FIXED_WEATHER.get(season_idx, {})
	return season_fixed.get(day, "")

# ============ 天气查询API ============

## 获取今日天气
func get_today_weather() -> String:
	return today_weather

## 获取明日天气
func get_tomorrow_weather() -> String:
	return tomorrow_weather

## 是否为雨天 (rainy/stormy/green_rain/snowy)
func is_rainy() -> bool:
	return today_weather in [WEATHER_RAINY, WEATHER_STORMY, WEATHER_GREEN_RAIN, WEATHER_SNOWY]

## 是否为雷雨天
func is_stormy() -> bool:
	return today_weather == WEATHER_STORMY

## 是否为绿雨
func is_green_rain() -> bool:
	return today_weather == WEATHER_GREEN_RAIN

## 是否为雪天
func is_snowy() -> bool:
	return today_weather == WEATHER_SNOWY

## 是否为大风天
func is_windy() -> bool:
	return today_weather == WEATHER_WINDY

## 是否为晴天
func is_sunny() -> bool:
	return today_weather == WEATHER_SUNNY

# ============ 修正值API ============

## 获取体力消耗修正系数
func get_stamina_modifier() -> float:
	match today_weather:
		WEATHER_RAINY:
			return RAINY_STAMINA_MOD
		WEATHER_STORMY:
			return STORMY_STAMINA_MOD
		WEATHER_SNOWY:
			return SNOWY_STAMINA_MOD
		WEATHER_GREEN_RAIN:
			return GREEN_RAIN_STAMINA_MOD
		_:
			return 1.0

## 获取采矿收益修正
func get_mining_yield_modifier() -> float:
	match today_weather:
		WEATHER_RAINY:
			return RAINY_ACTIVITY_MOD
		WEATHER_STORMY:
			return STORMY_ACTIVITY_MOD
		_:
			return 1.0

## 获取钓鱼收益修正
func get_fishing_yield_modifier() -> float:
	match today_weather:
		WEATHER_RAINY:
			return RAINY_ACTIVITY_MOD
		WEATHER_STORMY:
			return STORMY_ACTIVITY_MOD
		WEATHER_GREEN_RAIN:
			return GREEN_RAIN_FISHING_MOD
		_:
			return 1.0

## 获取农作物产量修正
func get_crop_yield_modifier() -> float:
	if today_weather == WEATHER_GREEN_RAIN:
		return GREEN_RAIN_CROP_MOD
	return 1.0

## 获取移动体力修正
func get_travel_stamina_modifier() -> float:
	if today_weather == WEATHER_SNOWY:
		return SNOWY_STAMINA_MOD  # 雪天移动-30%体力
	return get_stamina_modifier()

## 获取NPC心情天气修正
func get_npc_mood_modifier() -> float:
	match today_weather:
		WEATHER_SUNNY:
			return 1.1  # 晴 +10%好感
		WEATHER_STORMY:
			return 0.9  # 暴风雨 -10%好感
		_:
			return 1.0

# ============ 雷击风险 ============

## 检查雷击风险 (需要在室外)
func check_lightning_risk(is_outdoors: bool) -> bool:
	if not is_stormy():
		return false

	if not is_outdoors:
		return false

	var roll = randf()
	if roll < LIGHTNING_STRIKE_CHANCE:
		lightning_strike_warning.emit()
		return true

	return false

## 雷击昏厥处理
func trigger_lightning_passout() -> bool:
	if not is_stormy():
		return false

	if TimeManager != null:
		TimeManager.force_faint()
		return true

	return false

# ============ 玩家天气覆盖 ============

## 设置明日天气 (玩家使用雨图腾等)
func set_tomorrow_weather(weather: String) -> void:
	has_player_override = true
	player_override_weather = weather
	tomorrow_weather = weather
	forecast_updated.emit(tomorrow_weather)

	if _debug_mode:
		print("[WeatherSystem] Player override: tomorrow = ", weather)

## 清除玩家天气覆盖
func clear_tomorrow_weather_override() -> void:
	has_player_override = false
	player_override_weather = ""
	_roll_tomorrow_weather()

## 是否有玩家覆盖
func has_player_weather_override() -> bool:
	return has_player_override

# ============ 唤雨能力 ============

## 设置唤雨能力状态
func set_rain_boost_active(active: bool) -> void:
	_rain_boost_active = active
	if _debug_mode:
		print("[WeatherSystem] Rain boost: ", active)

## 唤雨能力是否激活
func is_rain_boost_active() -> bool:
	return _rain_boost_active

# ============ 浇水系统 ============

## 是否自动浇水
func is_auto_watering_day() -> bool:
	return today_weather in [WEATHER_RAINY, WEATHER_STORMY, WEATHER_GREEN_RAIN, WEATHER_SNOWY]

## 大风是否吹走浇水状态
func does_windy_blow_away_watering() -> bool:
	return today_weather == WEATHER_WINDY

## 大风吹走浇水概率
func get_windy_water_loss_chance() -> float:
	if is_windy():
		return WINDY_CROP_LOSS_CHANCE
	return 0.0

# ============ 天气名称 ============

## 获取天气中文名称
func get_weather_name(weather: String) -> String:
	match weather:
		WEATHER_SUNNY:
			return "晴天"
		WEATHER_RAINY:
			return "雨天"
		WEATHER_STORMY:
			return "暴风雨"
		WEATHER_SNOWY:
			return "雪天"
		WEATHER_WINDY:
			return "大风"
		WEATHER_GREEN_RAIN:
			return "绿雨"
		_:
			return "未知"

## 获取当前天气中文名称
func get_today_weather_name() -> String:
	return get_weather_name(today_weather)

## 获取明日天气中文名称
func get_tomorrow_weather_name() -> String:
	return get_weather_name(tomorrow_weather)

# ============ 存档支持 ============

## 获取存档数据
func get_save_data() -> Dictionary:
	return {
		"today_weather": today_weather,
		"tomorrow_weather": tomorrow_weather,
		"has_player_override": has_player_override,
		"player_override_weather": player_override_weather,
		"is_green_rain_active": is_green_rain_active
	}

## 加载存档数据
func load_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return

	today_weather = data.get("today_weather", WEATHER_SUNNY)
	tomorrow_weather = data.get("tomorrow_weather", WEATHER_SUNNY)
	has_player_override = data.get("has_player_override", false)
	player_override_weather = data.get("player_override_weather", "")
	is_green_rain_active = data.get("is_green_rain_active", false)

	if _debug_mode:
		print("[WeatherSystem] Loaded: today=%s, tomorrow=%s" % [today_weather, tomorrow_weather])

# ============ 调试 ============

## 设置调试模式
func set_debug(enabled: bool) -> void:
	_debug_mode = enabled

## 强制设置天气 (调试用)
func debug_set_weather(weather: String) -> void:
	var old_weather = today_weather
	today_weather = weather

	if weather == WEATHER_GREEN_RAIN:
		is_green_rain_active = true

	weather_changed.emit(today_weather, old_weather)

## 强制设置明日天气 (调试用)
func debug_set_tomorrow_weather(weather: String) -> void:
	tomorrow_weather = weather
	has_player_override = true
	player_override_weather = weather
	forecast_updated.emit(tomorrow_weather)
