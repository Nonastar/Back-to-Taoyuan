extends Node

## ConfigManager - 配置管理器
## 负责加载和管理所有游戏配置

# ============ 信号 ============

## 配置已重新加载
signal configs_loaded()

## 配置已保存
signal config_saved(config_name: String)

## 配置验证失败
signal config_validation_failed(config_name: String, errors: Array)

# ============ 配置实例 ============

## 使用延迟初始化避免场景树依赖问题
var game_config: GameConfig
var time_config: TimeConfig
var player_config: PlayerConfig

## 标记配置是否已加载
var _configs_loaded: bool = false

# ============ 配置路径 ============

const GAME_CONFIG_PATH: String = "res://src/resources/configs/game_config.tres"
const TIME_CONFIG_PATH: String = "res://src/resources/configs/time_config.tres"
const PLAYER_CONFIG_PATH: String = "res://src/resources/configs/player_config.tres"

# ============ 可配置系统注册 ============

var _configurable_systems: Dictionary = {}

func _ready() -> void:
	# 延迟一帧加载配置，确保场景树完全初始化
	call_deferred("_load_all_configs")

## 注册可配置系统
func register_configurable(system_name: String, node: Node) -> void:
	_configurable_systems[system_name] = node
	print("[ConfigManager] Registered configurable system: %s" % system_name)

## 注销可配置系统
func unregister_configurable(system_name: String) -> void:
	_configurable_systems.erase(system_name)

# ============ 加载配置 ============

## 加载所有配置
func _load_all_configs() -> void:
	game_config = _load_config(GameConfig, GAME_CONFIG_PATH)
	time_config = _load_config(TimeConfig, TIME_CONFIG_PATH)
	player_config = _load_config(PlayerConfig, PLAYER_CONFIG_PATH)

	# 验证配置
	var validation_errors = _validate_all_configs()
	if validation_errors.size() > 0:
		push_error("[ConfigManager] Config validation failed: %s" % validation_errors)
		config_validation_failed.emit("all", validation_errors)

	# 如果配置文件不存在，创建默认配置
	if game_config == null:
		game_config = GameConfig.new()
		_save_config(game_config, "game")

	if time_config == null:
		time_config = TimeConfig.new()
		_save_config(time_config, "time")

	if player_config == null:
		player_config = PlayerConfig.new()
		_save_config(player_config, "player")

	_apply_configs()
	configs_loaded.emit()
	print("[ConfigManager] All configs loaded successfully")

## 加载单个配置
func _load_config(config_class: GDScript, path: String) -> Resource:
	if FileAccess.file_exists(path):
		return load(path)
	return null

# ============ 保存配置 ============

## 保存配置
func save_config(config_name: String) -> bool:
	match config_name:
		"game":
			return _save_config(game_config, config_name)
		"time":
			return _save_config(time_config, config_name)
		"player":
			return _save_config(player_config, config_name)
		_:
			push_error("[ConfigManager] Unknown config: %s" % config_name)
			return false

## 内部保存方法
func _save_config(config: Resource, config_name: String) -> bool:
	if config == null:
		return false

	var path: String
	match config_name:
		"game":
			path = GAME_CONFIG_PATH
		"time":
			path = TIME_CONFIG_PATH
		"player":
			path = PLAYER_CONFIG_PATH

	var err = ResourceSaver.save(config, path)
	if err == OK:
		config_saved.emit(config_name)
		print("[ConfigManager] Config saved: %s" % config_name)
		return true
	else:
		push_error("[ConfigManager] Failed to save config: %s (error: %d)" % [config_name, err])
		return false

# ============ 配置验证 ============

## 验证所有配置
func _validate_all_configs() -> Array:
	var errors: Array = []

	if time_config:
		var time_errors = _validate_time_config()
		errors.append_array(time_errors)

	if player_config:
		var player_errors = _validate_player_config()
		errors.append_array(player_errors)

	return errors

## 验证时间配置
func _validate_time_config() -> Array:
	var errors: Array = []

	if time_config.hour_duration_ms <= 0:
		errors.append("time_config.hour_duration_ms must be > 0")

	if time_config.hour_duration_ms > 10000:
		errors.append("time_config.hour_duration_ms too large (>10000ms)")

	if time_config.days_per_season <= 0 or time_config.days_per_season > 100:
		errors.append("time_config.days_per_season must be 1-100")

	if time_config.day_start_hour < 0 or time_config.day_start_hour >= 24:
		errors.append("time_config.day_start_hour must be 0-23")

	if time_config.day_end_hour <= time_config.day_start_hour:
		errors.append("time_config.day_end_hour must be > day_start_hour")

	if time_config.recovery_rate < 0 or time_config.recovery_rate > 1:
		errors.append("time_config.recovery_rate must be 0-1")

	return errors

## 验证玩家配置
func _validate_player_config() -> Array:
	var errors: Array = []

	if player_config.max_health <= 0:
		errors.append("player_config.max_health must be > 0")

	if player_config.max_stamina <= 0:
		errors.append("player_config.max_stamina must be > 0")

	if player_config.initial_money < 0:
		errors.append("player_config.initial_money must be >= 0")

	if player_config.default_backpack_size <= 0:
		errors.append("player_config.default_backpack_size must be > 0")

	return errors

# ============ 重新加载 ============

## 重新加载所有配置
func reload_all() -> void:
	_load_all_configs()

## 重新加载指定配置
func reload_config(config_name: String) -> bool:
	match config_name:
		"game":
			game_config = _load_config(GameConfig, GAME_CONFIG_PATH)
		"time":
			time_config = _load_config(TimeConfig, TIME_CONFIG_PATH)
		"player":
			player_config = _load_config(PlayerConfig, PLAYER_CONFIG_PATH)
		_:
			push_error("[ConfigManager] Unknown config: %s" % config_name)
			return false

	_apply_configs()
	return true

# ============ 应用配置 ============

## 应用配置到系统
func _apply_configs() -> void:
	if not is_inside_tree():
		await ready

	if time_config:
		if has_node("/root/TimeManager"):
			var tm = get_node("/root/TimeManager")
			tm.apply_config(time_config)

	if player_config:
		if has_node("/root/InventorySystem"):
			var inv = get_node("/root/InventorySystem")
			inv.apply_config(player_config)

	_configs_loaded = true

	# 通知所有注册的可配置系统
	for system_name in _configurable_systems:
		var system = _configurable_systems[system_name]
		if system.has_method("on_config_changed"):
			system.on_config_changed("all")

## 获取配置
func get_config(config_name: String) -> Resource:
	match config_name:
		"game":
			return game_config
		"time":
			return time_config
		"player":
			return player_config
	return null

## 获取配置值（带默认值）
func get_value(config_name: String, property: String, default: Variant) -> Variant:
	var config = get_config(config_name)
	if config and config.has(property):
		return config.get(property)
	return default
