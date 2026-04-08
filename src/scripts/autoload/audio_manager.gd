extends Node

## AudioManager - 音频系统
## 负责背景音乐、效果音、语音和氛围音管理
## 参考: ADR-0009 音频系统架构, F05 音效系统 GDD

# ============ 音频总线 ============

## 音量设置 (0.0 - 1.0)
var master_volume: float = 1.0:
	set(value):
		master_volume = clamp(value, 0.0, 1.0)
		_update_bus_volume("Master", master_volume)

var bgm_volume: float = 0.8:
	set(value):
		bgm_volume = clamp(value, 0.0, 1.0)
		_update_bus_volume("BGM", bgm_volume)

var sfx_volume: float = 1.0:
	set(value):
		sfx_volume = clamp(value, 0.0, 1.0)
		_update_bus_volume("SFX", sfx_volume)

var voice_volume: float = 1.0:
	set(value):
		voice_volume = clamp(value, 0.0, 1.0)
		_update_bus_volume("Voice", voice_volume)

var ambient_volume: float = 0.7:
	set(value):
		ambient_volume = clamp(value, 0.0, 1.0)
		_update_bus_volume("Ambient", ambient_volume)

# ============ 播放器节点 ============

## BGM播放器 (延迟初始化)
var _bgm_player: AudioStreamPlayer = null

## SFX播放器池
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 8

## 氛围音播放器 (延迟初始化)
var _ambient_player: AudioStreamPlayer = null

## 语音播放器 (延迟初始化)
var _voice_player: AudioStreamPlayer = null

# ============ 状态 ============

## 当前BGM名称
var _current_bgm: String = ""

## BGM过渡是否正在进行
var _is_transitioning: bool = false

# ============ 初始化 ============

func _ready() -> void:
	_setup_audio_buses()
	_setup_sfx_pool()
	_load_settings()

## 设置音频总线
func _setup_audio_buses() -> void:
	# 确保音频总线存在 (在导入音频前可能不存在)
	pass

## 设置SFX播放器池
func _setup_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.volume_db = 0
		add_child(player)
		_sfx_players.append(player)

	# 初始化BGM播放器
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "BGM"
	add_child(_bgm_player)

	# 初始化氛围音播放器
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Ambient"
	add_child(_ambient_player)

	# 初始化语音播放器
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Voice"
	add_child(_voice_player)

## 加载音量设置
func _load_settings() -> void:
	# TODO: 从设置文件加载音量
	pass

## 保存音量设置
func _save_settings() -> void:
	# TODO: 保存到设置文件
	pass

# ============ 音量控制 ============

func _update_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		# 线性值转dB: 0.0 -> -80dB, 1.0 -> 0dB
		var db = linear_to_db(linear_volume) if linear_volume > 0 else -80
		AudioServer.set_bus_volume_db(bus_index, db)

## 静音
func mute() -> void:
	_set_master_volume(0.0)

## 取消静音
func unmute() -> void:
	_set_master_volume(master_volume)

## 设置主音量
func _set_master_volume(value: float) -> void:
	master_volume = value

# ============ BGM控制 ============

## 播放BGM
func play_bgm(bgm_name: String, fade_duration: float = 1.0) -> void:
	if bgm_name == _current_bgm and _bgm_player.playing:
		return

	_current_bgm = bgm_name

	# TODO: 加载BGM资源
	# var stream = load("res://assets/audio/bgm/%s.ogg" % bgm_name)
	# if stream:
	#     _play_bgm_stream(stream, fade_duration)

## 停止BGM
func stop_bgm(fade_duration: float = 1.0) -> void:
	if fade_duration > 0:
		_fade_out(_bgm_player, fade_duration)
	else:
		_bgm_player.stop()
	_current_bgm = ""

## 暂停BGM
func pause_bgm() -> void:
	_bgm_player.stream_paused = true

## 继续BGM
func resume_bgm() -> void:
	_bgm_player.stream_paused = false

# ============ SFX控制 ============

## 播放音效
func play_sfx(sfx_name: String, volume_db: float = 0.0) -> void:
	# TODO: 加载SFX资源
	# var stream = load("res://assets/audio/sfx/%s.ogg" % sfx_name)
	# if stream:
	#     _play_sfx_stream(stream, volume_db)
	pass

## 播放随机音效
func play_sfx_random(sfx_names: Array[String], volume_db: float = 0.0) -> void:
	if sfx_names.is_empty():
		return
	var random_name = sfx_names[randi() % sfx_names.size()]
	play_sfx(random_name, volume_db)

## 停止所有SFX
func stop_all_sfx() -> void:
	for player in _sfx_players:
		player.stop()

func _play_sfx_stream(stream: AudioStream, volume_db: float) -> void:
	# 找到一个空闲的播放器
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return

	# 如果没有空闲的，使用第一个 (覆盖)
	_sfx_players[0].stream = stream
	_sfx_players[0].volume_db = volume_db
	_sfx_players[0].play()

# ============ 氛围音控制 ============

## 播放氛围音
func play_ambient(ambient_name: String) -> void:
	# TODO: 加载并播放氛围音
	pass

## 停止氛围音
func stop_ambient() -> void:
	_ambient_player.stop()

# ============ 语音控制 ============

## 播放语音
func play_voice(voice_name: String) -> void:
	# TODO: 加载并播放语音
	pass

## 停止语音
func stop_voice() -> void:
	_voice_player.stop()

# ============ 过渡效果 ============

func _fade_out(player: AudioStreamPlayer, duration: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80, duration)
	await tween.finished
	if player and is_instance_valid(player):
		player.stop()
		player.volume_db = 0

func _fade_in(player: AudioStreamPlayer, target_volume_db: float, duration: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	player.volume_db = -80
	player.play()
	var tween = create_tween()
	tween.tween_property(player, "volume_db", target_volume_db, duration)

# ============ 特殊音效快捷方式 ============

## 播放拾取音效
func play_pickup() -> void:
	play_sfx("pickup")

## 播放放下音效
func play_drop() -> void:
	play_sfx("drop")

## 播放成功音效
func play_success() -> void:
	play_sfx("success")

## 播放失败音效
func play_failure() -> void:
	play_sfx("failure")

## 播放菜单确认音效
func play_menu_confirm() -> void:
	play_sfx("menu_confirm")

## 播放菜单取消音效
func play_menu_cancel() -> void:
	play_sfx("menu_cancel")

## 播放菜单移动音效
func play_menu_move() -> void:
	play_sfx("menu_move")

## 播放收获音效
func play_harvest() -> void:
	play_sfx("harvest")

## 播放浇水音效
func play_water() -> void:
	play_sfx("water")

## 播放锄地音效
func play_hoe() -> void:
	play_sfx("hoe")

## 播放种植音效
func play_plant() -> void:
	play_sfx("plant")
