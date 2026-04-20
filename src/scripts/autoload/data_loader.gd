extends Node

## DataLoader - 统一数据加载器
## 负责从 JSON 文件加载游戏配置数据，支持热重载
## 所有游戏数据（食谱、商店、动物等）均通过此加载器获取

# ============ 常量 ============

const DATA_DIR := "res://src/resources/data/"

# ============ 缓存 ============

var _cache: Dictionary = {}  # filename -> parsed data

# ============ 生命周期 ============

func _ready() -> void:
	print("[DataLoader] Initialized")

# ============ 公开接口 ============

## 加载 JSON 文件（带缓存，同一文件只解析一次）
func load_json(filename: String) -> Dictionary:
	if _cache.has(filename):
		return _cache[filename]

	var path = DATA_DIR + filename
	if not FileAccess.file_exists(path):
		push_error("[DataLoader] File not found: " + path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[DataLoader] Failed to open: " + path)
		return {}

	var json_str = file.get_as_text()
	file.close()

	if json_str.is_empty():
		_cache[filename] = {}
		return {}

	var json = JSON.new()
	if json.parse(json_str) != OK:
		push_error("[DataLoader] JSON parse error in " + filename + ": " + json.get_error_message())
		_cache[filename] = {}
		return {}

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("[DataLoader] Root of " + filename + " must be a Dictionary")
		_cache[filename] = {}
		return {}

	_cache[filename] = data
	print("[DataLoader] Loaded: " + filename + " (" + str(data.size()) + " entries)")
	return data

## 重新加载指定文件（清除缓存后重新加载）
func reload_json(filename: String) -> Dictionary:
	_cache.erase(filename)
	return load_json(filename)

## 重新加载所有文件
func reload_all() -> void:
	var keys = _cache.keys()
	for k in keys:
		reload_json(k)

## 获取缓存的文件列表
func get_loaded_files() -> Array:
	return _cache.keys()
