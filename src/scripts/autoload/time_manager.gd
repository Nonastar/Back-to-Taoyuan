extends Node

## TimeManager - 时间与季节系统
## 负责游戏内时间流逝、日期推进和季节变化
## 参考: F01 时间/季节系统 GDD

# ============ 常量 ============

## 季节枚举
enum Season {
	SPRING = 0,
	SUMMER = 1,
	AUTUMN = 2,
	WINTER = 3
}

## 游戏时间常量
const DAY_START_HOUR: int = 6       # 游戏日开始时间
const DAY_END_HOUR: int = 26        # 游戏日结束时间 (次日2:00)
const MIDNIGHT_HOUR: int = 24      # 午夜时间点
const LATE_NIGHT_HOUR: int = 25    # 深夜时间点
const HOUR_DURATION_MS: float = 700.0  # 每游戏小时 = 700ms 实时

## 季节天数
const DAYS_PER_SEASON: int = 28

## 季节名称映射
const SEASON_NAMES: Dictionary = {
	Season.SPRING: "春",
	Season.SUMMER: "夏",
	Season.AUTUMN: "秋",
	Season.WINTER: "冬"
}

const SEASON_NAMES_EN: Dictionary = {
	Season.SPRING: "Spring",
	Season.SUMMER: "Summer",
	Season.AUTUMN: "Autumn",
	Season.WINTER: "Winter"
}

## 时段定义
enum TimePeriod {
	DAWN,      # 早晨 6:00-12:00
	AFTERNOON, # 下午 12:00-17:00
	DUSK,      # 傍晚 17:00-20:00
	NIGHT,     # 夜晚 20:00-24:00
	LATE_NIGHT # 深夜 24:00-26:00
}

const TIME_PERIOD_NAMES: Dictionary = {
	TimePeriod.DAWN: "早晨",
	TimePeriod.AFTERNOON: "下午",
	TimePeriod.DUSK: "傍晚",
	TimePeriod.NIGHT: "夜晚",
	TimePeriod.LATE_NIGHT: "深夜"
}

## 时间状态
enum TimeState {
	TIME_RUNNING,  # 时间正常流逝
	TIME_PAUSED,  # 时间暂停
	MINI_GAME,    # 小游戏中
	SLEEPING,     # 睡眠过渡
	DAY_TRANSITION, # 日结算
	SEASON_TRANSITION # 季节切换
}

# ============ 当前时间状态 ============

var current_year: int = 1
var current_season: Season = Season.SPRING
var current_day: int = 1
var current_hour: int = DAY_START_HOUR

## 当前时间状态
var time_state: TimeState = TimeState.TIME_PAUSED:
	set(value):
		_state_changed(time_state, value)
		time_state = value

## 时间流速
var time_scale: float = 1.0

## 睡眠恢复率 (当前)
var recovery_rate: float = 0.90

## 是否午夜警告已显示
var midnight_warned: bool = false

# ============ 可配置变量 ============

var hour_duration_ms: float = HOUR_DURATION_MS
var days_per_season: int = DAYS_PER_SEASON
var day_start_hour: int = DAY_START_HOUR
var day_end_hour: int = DAY_END_HOUR
var midnight_warning_hour: int = MIDNIGHT_HOUR

# ============ 内部状态 ============

var _game_hour_accumulator: float = 0.0
var _pending_day: int = 1
var _pending_season: Season = Season.SPRING

# ============ 初始化 ============

func _ready() -> void:
	# 默认暂停状态，等待游戏开始
	time_state = TimeState.TIME_PAUSED
	push_warning("[TimeManager] Initialized: Year %d, %s Day %d, %02d:00" % [
		current_year, SEASON_NAMES[current_season], current_day, current_hour])

# ============ 时间处理 ============

func _process(delta: float) -> void:
	if time_state != TimeState.TIME_RUNNING:
		return

	# 累加时间 (考虑time_scale)
	_game_hour_accumulator += (delta * 1000.0 * time_scale)

	# 每700ms推进1游戏小时
	while _game_hour_accumulator >= HOUR_DURATION_MS:
		_game_hour_accumulator -= HOUR_DURATION_MS
		_advance_hour()

## 推进1小时
func _advance_hour() -> void:
	current_hour += 1

	# 检查是否到达游戏日结束
	if current_hour >= DAY_END_HOUR:
		_trigger_sleep(false)
		return

	# 检查午夜警告
	if current_hour == MIDNIGHT_HOUR and not midnight_warned:
		midnight_warned = true
		# TODO: 显示午夜警告UI

	# 发送小时变化信号
	EventBus.time_hour_changed.emit(current_hour)

	# 发送时间变化信号 (与其他信号统一)
	EventBus.time_changed.emit(current_day, current_hour, 0)

## 状态变化处理
func _state_changed(from: TimeState, to: TimeState) -> void:
	push_warning("[TimeManager] State: %s -> %s" % [TimeState.keys()[from], TimeState.keys()[to]])

	if to == TimeState.TIME_PAUSED:
		EventBus.time_paused.emit()
	elif to == TimeState.TIME_RUNNING:
		EventBus.time_resumed.emit()

# ============ 睡眠系统 ============

## 触发睡眠
func _trigger_sleep(forced: bool = false) -> void:
	time_state = TimeState.SLEEPING

	# 计算恢复率
	var recovery_rate: float
	if current_hour <= 24:
		recovery_rate = 0.90  # 24时前就寝
	elif current_hour <= 25:
		recovery_rate = 0.60  # 25时就寝
	else:
		recovery_rate = 0.50  # 强制睡眠

	# 发送睡眠信号
	EventBus.time_sleep_triggered.emit(current_hour, forced)

	# 执行日结算
	_do_day_transition()

## 日结算
func _do_day_transition() -> void:
	time_state = TimeState.DAY_TRANSITION

	# 保存当前时间用于恢复计算
	var bedtime = current_hour
	var recovery_rate: float
	if bedtime <= 24:
		recovery_rate = 0.90
	elif bedtime <= 25:
		recovery_rate = 0.60
	else:
		recovery_rate = 0.50

	# 推进日期
	var old_season = current_season
	current_day += 1

	# 检查季节边界
	if current_day > DAYS_PER_SEASON:
		current_day = 1
		_do_season_transition()

	# 重置时间
	current_hour = DAY_START_HOUR
	midnight_warned = false
	_game_hour_accumulator = 0.0

	# 发送日结算信号
	EventBus.time_day_changed.emit(current_day, SEASON_NAMES[current_season], current_year)

	# 发送睡眠结束信号 (带恢复率)
	# EventBus.sleep_completed.emit(recovery_rate)

	# 继续游戏
	time_state = TimeState.TIME_RUNNING
	push_warning("[TimeManager] New day: Year %d, %s Day %d, %02d:00" % [
		current_year, SEASON_NAMES[current_season], current_day, current_hour])

## 季节切换
func _do_season_transition() -> void:
	time_state = TimeState.SEASON_TRANSITION

	var old_season = current_season
	current_season = (current_season + 1) % 4

	# 如果回到春季，年份+1
	if current_season == Season.SPRING:
		current_year += 1
		EventBus.year_changed.emit(current_year)

	# 发送季节变化信号
	EventBus.time_season_changed.emit(SEASON_NAMES[current_season], current_year)

	push_warning("[TimeManager] Season changed: %s -> %s (Year %d)" % [
		SEASON_NAMES[old_season], SEASON_NAMES[current_season], current_year])

# ============ 公共API ============

## 开始时间流逝
func start_time() -> void:
	if time_state == TimeState.TIME_PAUSED:
		time_state = TimeState.TIME_RUNNING

## 暂停时间
func pause_time() -> void:
	if time_state == TimeState.TIME_RUNNING:
		time_state = TimeState.TIME_PAUSED

## 继续时间
func resume_time() -> void:
	if time_state == TimeState.TIME_PAUSED:
		time_state = TimeState.TIME_RUNNING

## 进入小游戏
func enter_minigame() -> void:
	if time_state == TimeState.TIME_RUNNING:
		time_state = TimeState.MINI_GAME

## 退出小游戏
func exit_minigame() -> void:
	if time_state == TimeState.MINI_GAME:
		time_state = TimeState.TIME_RUNNING

## 玩家主动睡觉
func player_sleep() -> void:
	if time_state == TimeState.TIME_RUNNING:
		_trigger_sleep(false)

## 强制昏厥 (体力耗尽)
func force_faint() -> void:
	if current_hour < DAY_END_HOUR:
		_trigger_sleep(true)

## 设置时间流速
func set_time_scale(scale: float) -> void:
	time_scale = clamp(scale, 0.5, 3.0)

## 获取时间字符串 (格式: HH:00)
func get_time_string() -> String:
	return "%02d:00" % current_hour

## 获取日期字符串 (格式: 年份 第N天 季节)
func get_date_string() -> String:
	return "第%d年 %s第%d天" % [current_year, SEASON_NAMES[current_season], current_day]

## 获取完整时间字符串
func get_full_date_string() -> String:
	return "%s %s" % [get_date_string(), get_time_string()]

## 获取总游戏天数 (用于存档)
func get_total_days() -> int:
	return ((current_year - 1) * 4 + current_season) * DAYS_PER_SEASON + current_day

## 获取时段
func get_time_period() -> TimePeriod:
	match current_hour:
		6, 7, 8, 9, 10, 11:
			return TimePeriod.DAWN
		12, 13, 14, 15, 16:
			return TimePeriod.AFTERNOON
		17, 18, 19:
			return TimePeriod.DUSK
		20, 21, 22, 23:
			return TimePeriod.NIGHT
		_:
			return TimePeriod.LATE_NIGHT

## 获取时段名称
func get_time_period_name() -> String:
	return TIME_PERIOD_NAMES[get_time_period()]

## 是否为白天
func is_daytime() -> bool:
	return current_hour >= DAY_START_HOUR and current_hour < 20

## 是否为夜晚
func is_nighttime() -> bool:
	return current_hour >= 20

## 获取剩余游戏小时数 (到26:00)
func get_remaining_hours() -> int:
	return DAY_END_HOUR - current_hour

## 设置游戏时间 (用于读档)
func set_time(year: int, season: Season, day: int, hour: int) -> void:
	current_year = year
	current_season = season
	current_day = day
	current_hour = hour
	midnight_warned = hour >= 24
	_game_hour_accumulator = 0.0

	EventBus.time_changed.emit(current_day, current_hour, 0)
	push_warning("[TimeManager] Time set: " + get_full_date_string())

## 推进指定分钟数 (用于操作时间消耗)
func advance_minutes(minutes: int) -> void:
	var hours_to_add = minutes / 60
	var remaining_minutes = minutes % 60

	current_hour += hours_to_add
	_game_hour_accumulator += remaining_minutes * (HOUR_DURATION_MS / 60.0)

	# 检查是否跨天
	while current_hour >= DAY_END_HOUR:
		_trigger_sleep(false)

## 推进指定小时数
func advance_hours(hours: int) -> void:
	advance_minutes(hours * 60)

# ============ 配置应用 ============

## 应用时间配置
func apply_config(config: TimeConfig) -> void:
	if config == null:
		push_error("[TimeManager] Cannot apply null config")
		return

	hour_duration_ms = config.hour_duration_ms
	days_per_season = config.days_per_season
	day_start_hour = config.day_start_hour
	day_end_hour = config.day_end_hour
	midnight_warning_hour = config.midnight_warning_hour

	recovery_rate = config.early_bed_recovery_rate
	time_scale = config.default_time_scale

	push_warning("[TimeManager] Config applied: hour_duration=%sms, days_per_season=%d" % [
		hour_duration_ms, days_per_season])
