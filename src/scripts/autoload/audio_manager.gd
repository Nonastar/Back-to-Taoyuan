extends Node

## AudioManager - 音频系统
## 负责背景音乐、效果音、语音和氛围音管理
## 参考: ADR-0009 音频系统架构, F05 音效系统 GDD

# ============ 常量 ============

## SFX节流间隔 (毫秒)
const SFX_THROTTLE_MS: int = 80

## SFX对象池大小
const SFX_POOL_SIZE: int = 32

## BGM交叉淡入淡出时长 (秒)
const BGM_CROSSFADE_DURATION: float = 0.5

## 默认音量
const DEFAULT_SFX_VOLUME: float = 0.3
const DEFAULT_BGM_VOLUME: float = 0.15
const DEFAULT_MASTER_VOLUME: float = 1.0

# ============ 天气修饰器 ============

## 天气修饰器数据
class WeatherModifier:
	var tempo_mult: float = 1.0
	var volume_mult: float = 1.0
	var wave_type: String = "triangle"
	var ambient_volume: float = 0.0
	var detune: float = 0.0

## 天气修饰器字典
var WEATHER_MODIFIERS: Dictionary = {
	"sunny": WeatherModifier.new(),
	"rainy": _create_weather_modifier(1.15, 0.85, "triangle", 0.04, 5),
	"stormy": _create_weather_modifier(0.9, 0.75, "sawtooth", 0.06, 10),
	"snowy": _create_weather_modifier(1.25, 0.7, "sine", 0.02, 8),
	"windy": _create_weather_modifier(0.95, 0.9, "triangle", 0.05, 3),
	"green_rain": _create_weather_modifier(1.1, 0.8, "triangle", 0.05, 6)
}

func _create_weather_modifier(tempo: float, vol: float, wave: String, ambient: float, det: float) -> WeatherModifier:
	var m = WeatherModifier.new()
	m.tempo_mult = tempo
	m.volume_mult = vol
	m.wave_type = wave
	m.ambient_volume = ambient
	m.detune = det
	return m

# ============ 时段修饰器 ============

## 时段修饰器数据
class TimeModifier:
	var volume_mult: float = 1.0
	var tempo_mult: float = 1.0
	var detune_offset: float = 0.0
	var bass_volume_mult: float = 1.0

## 时段修饰器字典
var TIME_MODIFIERS: Dictionary = {
	"morning": _create_time_modifier(1.0, 1.0, 0, 0.8),
	"afternoon": _create_time_modifier(0.95, 1.05, 0, 1.0),
	"evening": _create_time_modifier(0.85, 1.1, 3, 1.1),
	"night": _create_time_modifier(0.7, 1.2, 6, 1.3),
	"late_night": _create_time_modifier(0.55, 1.3, 10, 1.5)
}

func _create_time_modifier(vol: float, tempo: float, detune: float, bass: float) -> TimeModifier:
	var m = TimeModifier.new()
	m.volume_mult = vol
	m.tempo_mult = tempo
	m.detune_offset = detune
	m.bass_volume_mult = bass
	return m

# ============ 音频总线 ============

## 主音量 (0.0 - 1.0)
var master_volume: float = DEFAULT_MASTER_VOLUME

## BGM音量
var bgm_volume: float = DEFAULT_BGM_VOLUME

## SFX音量
var sfx_volume: float = DEFAULT_SFX_VOLUME

## 语音音量
var voice_volume: float = 1.0

## 氛围音量
var ambient_volume: float = 0.7

# ============ 启用控制 ============

## SFX启用状态
var sfx_enabled: bool = true

## BGM启用状态
var bgm_enabled: bool = true

## 静音状态
var is_muted: bool = false

# ============ 播放器节点 ============

## BGM播放器
var _bgm_player: AudioStreamPlayer = null

## BGM淡入播放器 (用于交叉淡入淡出)
var _bgm_crossfade_player: AudioStreamPlayer = null

## SFX播放器池
var _sfx_players: Array[AudioStreamPlayer] = []

## 氛围音播放器
var _ambient_player: AudioStreamPlayer = null

## 语音播放器
var _voice_player: AudioStreamPlayer = null

# ============ 状态 ============

## 当前BGM类型
var _current_bgm_type: String = ""

## 当前BGM状态 (normal/festival/minigame/hanhai/battle)
var _current_bgm_state: String = "normal"

## 当前季节BGM
var _current_season_bgm: String = "spring"

## 当前天气
var _current_weather: String = "sunny"

## 当前时段
var _current_time_period: String = "morning"

## 之前BGM状态 (用于小游戏/节日结束后恢复)
var _previous_bgm_state: String = "normal"
var _previous_bgm_type: String = ""

## BGM过渡是否正在进行
var _is_transitioning: bool = false

## BGM是否正在播放
var _is_bgm_playing: bool = false

## 上次播放SFX的时间戳
var _sfx_last_play_time: Dictionary = {}

## 调试模式
var _debug_mode: bool = false

# ============ 信号 ============

## BGM切换信号
signal bgm_changed(bgm_type: String)

## SFX触发信号
signal sfx_triggered(sfx_type: String)

# ============ 初始化 ============

func _ready() -> void:
	_setup_players()
	_connect_signals()

## 设置播放器
func _setup_players() -> void:
	# BGM播放器
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "BGM"
	add_child(_bgm_player)

	# BGM交叉淡入播放器
	_bgm_crossfade_player = AudioStreamPlayer.new()
	_bgm_crossfade_player.bus = "BGM"
	add_child(_bgm_crossfade_player)

	# 氛围音播放器
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Ambient"
	add_child(_ambient_player)

	# 语音播放器
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Voice"
	add_child(_voice_player)

	# SFX播放器池
	for i in SFX_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)

## 连接信号
func _connect_signals() -> void:
	# 连接TimeManager信号
	if EventBus.has_signal("season_changed"):
		EventBus.season_changed.connect(_on_season_changed)
	if EventBus.has_signal("time_hour_changed"):
		EventBus.time_hour_changed.connect(_on_hour_changed)

	# 连接WeatherSystem信号
	if EventBus.has_signal("weather_changed"):
		EventBus.weather_changed.connect(_on_weather_changed)

# ============ 音量控制 ============

## 设置SFX启用状态
func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	if not enabled:
		stop_all_sfx()

## 设置BGM启用状态
func set_bgm_enabled(enabled: bool) -> void:
	bgm_enabled = enabled
	if not enabled:
		stop_bgm()
	elif not _is_bgm_playing:
		start_bgm()

## 设置主音量
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()

## 设置BGM音量
func set_bgm_volume(volume: float) -> void:
	bgm_volume = clamp(volume, 0.0, 1.0)
	if _bgm_player:
		_bgm_player.volume_db = _linear_to_db(bgm_volume * master_volume)

## 设置SFX音量
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)

## 静音
func mute() -> void:
	is_muted = true
	stop_all_sfx()
	if _is_bgm_playing:
		_bgm_player.volume_db = -80
		_ambient_player.volume_db = -80

## 取消静音
func unmute() -> void:
	is_muted = false
	_update_all_volumes()
	if _is_bgm_playing:
		start_bgm()

## 线性值转分贝 (Godot 4 API)
func _linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return linear_to_db(linear)

## 更新所有音量
func _update_all_volumes() -> void:
	if _bgm_player and _is_bgm_playing:
		_bgm_player.volume_db = _linear_to_db(bgm_volume * master_volume)
	if _ambient_player:
		_ambient_player.volume_db = _linear_to_db(ambient_volume * master_volume)

# ============ BGM控制 ============

## 开始BGM (根据当前状态播放)
func start_bgm() -> void:
	if not bgm_enabled or is_muted:
		return

	match _current_bgm_state:
		"festival":
			_play_bgm(_current_bgm_type)
		"minigame":
			_play_bgm(_current_bgm_type)
		"hanhai":
			_play_bgm("hanhai")
		"battle":
			_play_bgm("battle")
		_:
			_play_seasonal_bgm()

	_is_bgm_playing = true

## 停止BGM
func stop_bgm() -> void:
	if _is_transitioning:
		return

	_is_bgm_playing = false
	_crossfade_to_bgm(null)

## 暂停BGM
func pause_bgm() -> void:
	if _bgm_player:
		_bgm_player.stream_paused = true

## 继续BGM
func resume_bgm() -> void:
	if _bgm_player and _is_bgm_playing:
		_bgm_player.stream_paused = false

## 播放指定BGM
func _play_bgm(bgm_name: String) -> void:
	# TODO: 加载BGM资源 (程序化合成或音频文件)
	# var stream = load("res://assets/audio/bgm/%s.ogg" % bgm_name)
	# if stream:
	#     _current_bgm_type = bgm_name
	#     _apply_crossfade(stream)

	if _debug_mode:
		print("[AudioManager] Playing BGM: " + str(bgm_name))
	bgm_changed.emit(bgm_name)

## 应用交叉淡入淡出
func _crossfade_to_bgm(new_stream: AudioStream) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true

	# 淡出当前BGM
	var tween = create_tween()
	tween.tween_property(_bgm_player, "volume_db", -80.0, BGM_CROSSFADE_DURATION)
	await tween.finished

	_bgm_player.stop()

	if new_stream:
		_bgm_player.stream = new_stream
		_bgm_player.volume_db = _linear_to_db(bgm_volume * master_volume)
		_bgm_player.play()

	_is_transitioning = false

## 检查BGM是否正在播放
func is_bgm_playing() -> bool:
	return _is_bgm_playing

# ============ 季节BGM ============

## 播放季节BGM
func switch_to_seasonal_bgm() -> void:
	_play_seasonal_bgm()

func _play_seasonal_bgm() -> void:
	# 应用天气和时段修饰器
	var weather_mod = WEATHER_MODIFIERS.get(_current_weather, WeatherModifier.new())
	var time_mod = TIME_MODIFIERS.get(_current_time_period, TimeModifier.new())

	var bgm_name = "bgm_%s" % _current_season_bgm
	_play_bgm(bgm_name)

## 开始节日BGM
func start_festival_bgm(season: String) -> void:
	_previous_bgm_state = _current_bgm_state
	_previous_bgm_type = _current_bgm_type
	_current_bgm_state = "festival"
	_current_bgm_type = "festival_%s" % season
	_play_bgm(_current_bgm_type)

## 结束节日BGM
func end_festival_bgm() -> void:
	_current_bgm_state = _previous_bgm_state
	_current_bgm_type = _previous_bgm_type
	if _is_bgm_playing:
		start_bgm()

## 开始小游戏BGM
func start_minigame_bgm(minigame_type: String) -> void:
	_previous_bgm_state = _current_bgm_state
	_previous_bgm_type = _current_bgm_type
	_current_bgm_state = "minigame"
	_current_bgm_type = "minigame_%s" % minigame_type
	_play_bgm(_current_bgm_type)

## 结束小游戏BGM
func end_minigame_bgm() -> void:
	_current_bgm_state = _previous_bgm_state
	_current_bgm_type = _previous_bgm_type
	if _is_bgm_playing:
		start_bgm()

## 开始瀚海区域BGM
func start_hanhai_bgm() -> void:
	_previous_bgm_state = _current_bgm_state
	_previous_bgm_type = _current_bgm_type
	_current_bgm_state = "hanhai"
	_play_bgm("hanhai")

## 结束瀚海区域BGM
func end_hanhai_bgm() -> void:
	_current_bgm_state = _previous_bgm_state
	_current_bgm_type = _previous_bgm_type
	if _is_bgm_playing:
		start_bgm()

## 开始战斗BGM
func start_battle_bgm() -> void:
	_previous_bgm_state = _current_bgm_state
	_previous_bgm_type = _current_bgm_type
	_current_bgm_state = "battle"
	_play_bgm("battle")

## 结束战斗BGM
func end_battle_bgm() -> void:
	_current_bgm_state = _previous_bgm_state
	_current_bgm_type = _previous_bgm_type
	if _is_bgm_playing:
		start_bgm()

# ============ 氛围音 ============

## 播放氛围音
func play_ambient(ambient_name: String) -> void:
	# TODO: 加载并播放氛围音
	if _debug_mode:
		print("[AudioManager] Playing ambient: " + str(ambient_name))

## 停止氛围音
func stop_ambient() -> void:
	if _ambient_player:
		_ambient_player.stop()

## 设置当前天气氛围
func _apply_weather_ambient() -> void:
	var weather_mod = WEATHER_MODIFIERS.get(_current_weather, WeatherModifier.new())
	if weather_mod.ambient_volume > 0:
		_ambient_player.volume_db = _linear_to_db(weather_mod.ambient_volume * master_volume)
		# TODO: 播放对应的环境音
	else:
		stop_ambient()

# ============ SFX控制 ============

## 播放音效 (带节流)
func play_sfx(sfx_name: String, volume_db: float = 0.0) -> void:
	if not sfx_enabled or is_muted:
		return

	# 节流检查
	if _is_sfx_throttled(sfx_name):
		return

	_sfx_last_play_time[sfx_name] = Time.get_ticks_msec()

	# TODO: 加载SFX资源 (程序化合成)
	# var stream = load("res://assets/audio/sfx/%s.ogg" % sfx_name)
	# _play_sfx_stream(stream, volume_db)

	if _debug_mode:
		print("[AudioManager] Playing SFX: " + str(sfx_name))
	sfx_triggered.emit(sfx_name)

## 检查SFX是否被节流
func _is_sfx_throttled(sfx_name: String) -> bool:
	if not _sfx_last_play_time.has(sfx_name):
		return false
	var elapsed = Time.get_ticks_msec() - _sfx_last_play_time[sfx_name]
	return elapsed < SFX_THROTTLE_MS

## 播放随机音效
func play_sfx_random(sfx_names: Array[String], volume_db: float = 0.0) -> void:
	if sfx_names.is_empty():
		return
	var rng = RandomNumberGenerator.new()
	var random_name = sfx_names[rng.randi_range(0, sfx_names.size() - 1)]
	play_sfx(random_name, volume_db)

## 停止所有SFX
func stop_all_sfx() -> void:
	for player in _sfx_players:
		player.stop()

## 播放SFX流
func _play_sfx_stream(stream: AudioStream, volume_db: float) -> void:
	# 找到一个空闲的播放器
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = _linear_to_db(sfx_volume * master_volume) + volume_db
			player.play()
			return

	# 如果没有空闲的，覆盖第一个
	_sfx_players[0].stream = stream
	_sfx_players[0].volume_db = _linear_to_db(sfx_volume * master_volume) + volume_db
	_sfx_players[0].play()

# ============ 语音控制 ============

## 播放语音
func play_voice(voice_name: String) -> void:
	if not sfx_enabled or is_muted:
		return
	# TODO: 加载并播放语音
	if _debug_mode:
		print("[AudioManager] Playing voice: " + str(voice_name))

## 停止语音
func stop_voice() -> void:
	if _voice_player:
		_voice_player.stop()

# ============ 特殊音效快捷方式 ============

func play_pickup() -> void:
	play_sfx("pickup")

func play_drop() -> void:
	play_sfx("drop")

func play_success() -> void:
	play_sfx("success")

func play_failure() -> void:
	play_sfx("failure")

func play_menu_confirm() -> void:
	play_sfx("menu_confirm")

func play_menu_cancel() -> void:
	play_sfx("menu_cancel")

func play_menu_move() -> void:
	play_sfx("menu_move")

func play_harvest() -> void:
	play_sfx("harvest")

func play_water() -> void:
	play_sfx("water")

func play_hoe() -> void:
	play_sfx("hoe")

func play_plant() -> void:
	play_sfx("plant")

# ============ 游戏操作SFX ============

func play_sfx_click() -> void:
	play_sfx("click")

func play_sfx_dig() -> void:
	play_sfx("dig")

func play_sfx_buy() -> void:
	play_sfx("buy")

func play_sfx_coin() -> void:
	play_sfx("coin")

func play_sfx_level_up() -> void:
	play_sfx("level_up")

func play_sfx_attack() -> void:
	play_sfx("attack")

func play_sfx_hurt() -> void:
	play_sfx("hurt")

func play_sfx_victory() -> void:
	play_sfx("victory")

func play_sfx_fish_reel() -> void:
	play_sfx("fish_reel")

func play_sfx_fish_catch() -> void:
	play_sfx("fish_catch")

func play_sfx_mine() -> void:
	play_sfx("mine")

func play_sfx_sleep() -> void:
	play_sfx("sleep")

# ============ 信号处理 ============

func _on_season_changed(season: String, year: int) -> void:
	_current_season_bgm = season
	if _current_bgm_state == "normal" and _is_bgm_playing:
		switch_to_seasonal_bgm()
	if _debug_mode:
		print("[AudioManager] Season changed to: " + str(season))

func _on_hour_changed(hour: int) -> void:
	var new_period = _get_time_period(hour)
	if new_period != _current_time_period:
		_current_time_period = new_period
		if _current_bgm_state == "normal" and _is_bgm_playing:
			switch_to_seasonal_bgm()
	if _debug_mode:
		print("[AudioManager] Hour changed: %d -> %s" % [hour, new_period])

func _on_weather_changed(new_weather: String, old_weather: String) -> void:
	_current_weather = new_weather
	_apply_weather_ambient()
	if _current_bgm_state == "normal" and _is_bgm_playing:
		switch_to_seasonal_bgm()
	if _debug_mode:
		print("[AudioManager] Weather changed: %s -> %s" % [old_weather, new_weather])

## 根据小时获取时段
func _get_time_period(hour: int) -> String:
	match hour:
		6, 7, 8, 9:
			return "morning"
		10, 11, 12, 13, 14:
			return "afternoon"
		15, 16, 17, 18:
			return "evening"
		19, 20, 21, 22:
			return "night"
		23, 0, 1:
			return "late_night"
		_:
			return "morning"

# ============ 应用暂停处理 ============

var _was_bgm_playing: bool = false

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_was_bgm_playing = is_bgm_playing()
			if _was_bgm_playing:
				stop_bgm()
		NOTIFICATION_APPLICATION_RESUMED:
			if _was_bgm_playing and bgm_enabled:
				start_bgm()

# ============ 存档支持 ============

## 获取存档数据
func get_save_data() -> Dictionary:
	return {
		"master_volume": master_volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume,
		"ambient_volume": ambient_volume,
		"sfx_enabled": sfx_enabled,
		"bgm_enabled": bgm_enabled,
		"is_muted": is_muted
	}

## 加载存档数据
func load_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return

	master_volume = data.get("master_volume", DEFAULT_MASTER_VOLUME)
	bgm_volume = data.get("bgm_volume", DEFAULT_BGM_VOLUME)
	sfx_volume = data.get("sfx_volume", DEFAULT_SFX_VOLUME)
	ambient_volume = data.get("ambient_volume", 0.7)
	sfx_enabled = data.get("sfx_enabled", true)
	bgm_enabled = data.get("bgm_enabled", true)
	is_muted = data.get("is_muted", false)

	_update_all_volumes()

# ============ 调试 ============

## 设置调试模式
func set_debug(enabled: bool) -> void:
	_debug_mode = enabled
