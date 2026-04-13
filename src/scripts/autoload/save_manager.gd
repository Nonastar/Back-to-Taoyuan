extends Node

## SaveManager - 存档系统
## 负责游戏数据的保存和加载
## 参考: ADR-0004 存档系统架构, F04 存档系统 GDD

# ============ 常量 ============

## 存档槽数量
const SAVE_SLOT_COUNT: int = 3

## 存档目录名称
const SAVE_DIR: String = "user://saves/"

## 加密文件后缀
const ENCRYPTED_EXTENSION: String = ".sav"

## 加密启用标志
const ENCRYPTION_ENABLED: bool = true

## 加密密钥 (32字节用于AES-256)
## 实际项目建议使用动态生成的密钥并安全存储
var _encryption_key: PackedByteArray = PackedByteArray([0x23, 0x48, 0x5F, 0x72, 0x3A, 0x7C, 0x1E, 0x45, 0x92, 0x0D, 0xF8, 0x4A, 0x6B, 0x1F, 0x3D, 0x8C, 0x52, 0x9E, 0xB1, 0x67, 0x20, 0xC3, 0x5A, 0x8F, 0x1B, 0x4D, 0x7E, 0x2A, 0x9C, 0x63, 0xD5, 0x0F])

# ============ 存档槽元数据 ============

class SaveSlotData:
	var slot_index: int = 0
	var player_name: String = ""
	var day: int = 1
	var season: String = "春"
	var play_time: int = 0
	var save_timestamp: int = 0
	var thumbnail_path: String = ""

## 存档槽数据列表
var save_slots: Array[SaveSlotData] = []

# ============ 初始化 ============

func _ready() -> void:
	# 创建存档目录
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	# 加载存档槽信息
	_refresh_save_slots()

	if ENCRYPTION_ENABLED:
		print("[SaveManager] Initialized without encryption")
	else:
		print("[SaveManager] Initialized without encryption")

# ============ 存档操作 ============

## 保存游戏到指定槽位
func save_game(slot: int) -> bool:
	if slot < 0 or slot >= SAVE_SLOT_COUNT:
		push_error("[SaveManager] Invalid save slot: %d" % slot)
		return false

	EventBus.save_started.emit(slot)

	# 构建存档数据
	var save_data = _collect_save_data()

	# 添加元数据
	save_data["meta"] = {
		"slot": slot,
		"timestamp": Time.get_unix_time_from_system(),
		"version": "0.1.0"
	}

	# 序列化为JSON
	var json_str = JSON.stringify(save_data)

	# 生成文件路径
	var file_path = _get_save_path(slot)

	# 写入并加密文件
	var success = _write_encrypted_file(file_path, json_str)

	if not success:
		push_error("[SaveManager] Failed to save game to slot %d" % slot)
		EventBus.save_completed.emit(slot, false)
		return false

	# 更新存档槽信息
	_refresh_save_slots()

	EventBus.save_completed.emit(slot, true)
	print("[SaveManager] Game saved to slot %d" % slot)
	return true

## 加载游戏存档
func load_game(slot: int) -> bool:
	if slot < 0 or slot >= SAVE_SLOT_COUNT:
		push_error("[SaveManager] Invalid save slot: %d" % slot)
		return false

	if not has_save(slot):
		push_error("[SaveManager] No save found in slot %d" % slot)
		return false

	EventBus.load_started.emit(slot)

	# 生成文件路径
	var file_path = _get_save_path(slot)

	# 读取并解密文件
	var json_str = _read_encrypted_file(file_path)

	if json_str == "":
		push_error("[SaveManager] Failed to load game from slot %d" % slot)
		EventBus.load_completed.emit(slot, false)
		return false

	# 解析JSON
	var json = JSON.new()
	if json.parse(json_str) != OK:
		push_error("[SaveManager] Failed to parse save data")
		EventBus.load_completed.emit(slot, false)
		return false

	var save_data = json.data

	# 应用存档数据
	_apply_save_data(save_data)

	EventBus.load_completed.emit(slot, true)
	print("[SaveManager] Game loaded from slot %d" % slot)
	return true

## 删除存档
func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= SAVE_SLOT_COUNT:
		return false

	var file_path = _get_save_path(slot)

	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		_refresh_save_slots()
		print("[SaveManager] Decryption failed, trying raw read...")
		return true

	return false

## 检查存档槽是否有存档
func has_save(slot: int) -> bool:
	if slot < 0 or slot >= SAVE_SLOT_COUNT:
		return false
	return FileAccess.file_exists(_get_save_path(slot))

## 获取存档文件路径
func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "save_slot_%d%s" % [slot, ENCRYPTED_EXTENSION]

# ============ 加密/解密操作 ============

## 写入加密文件
func _write_encrypted_file(file_path: String, data: String) -> bool:
	if not ENCRYPTION_ENABLED:
		# 不加密，直接写入
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file == null:
			return false
		file.store_string(data)
		file.close()
		return true

	# 使用FileAccess.open_encrypted()进行AES加密
	var file = FileAccess.open_encrypted(file_path, FileAccess.WRITE, _encryption_key)
	if file == null:
		push_error("[SaveManager] Failed to open encrypted file for writing")
		return false

	file.store_string(data)
	file.close()
	return true

## 读取并解密文件
func _read_encrypted_file(file_path: String) -> String:
	if not FileAccess.file_exists(file_path):
		return ""

	if not ENCRYPTION_ENABLED:
		# 不加密，直接读取
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			return ""
		var content = file.get_as_text()
		file.close()
		return content

	# 使用FileAccess.open_encrypted()读取
	var file = FileAccess.open_encrypted(file_path, FileAccess.READ, _encryption_key)
	if file == null:
		# 可能是旧版本未加密的存档，尝试直接读取
		print("[SaveManager] Decryption failed, trying raw read...")
		file = FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			return ""
		var content = file.get_as_text()
		file.close()
		return content

	var content = file.get_as_text()
	file.close()
	return content

# ============ 数据收集与应用 ============

## 收集所有需要保存的数据
func _collect_save_data() -> Dictionary:
	return {
		"player": {
			"name": "Player",
			"day": TimeManager.current_day,
			"season": TimeManager.current_season,
			"year": TimeManager.current_year,
			"money": 500,
			"stamina": 156.0,
			"max_stamina": 156.0,
			"health": 100.0,
			"max_health": 100.0
		},
		"farm": {
			"plots": [],
		},
		"inventory": InventorySystem.get_save_data(),
		"skills": {},
		"npcs": {},
		"quests": {},
		"calendar": {},
	}

## 应用存档数据
func _apply_save_data(data: Dictionary) -> void:
	# 应用玩家数据
	if "player" in data:
		var player_data = data["player"]
		TimeManager.current_day = player_data.get("day", 1)
		TimeManager.current_year = player_data.get("year", 1)

	# 应用库存数据
	if "inventory" in data:
		InventorySystem.load_save_data(data["inventory"])

# ============ 存档槽管理 ============

## 刷新存档槽信息
func _refresh_save_slots() -> void:
	save_slots.clear()

	for i in SAVE_SLOT_COUNT:
		var slot_data = SaveSlotData.new()
		slot_data.slot_index = i

		if has_save(i):
			slot_data = _load_slot_metadata(i)

		save_slots.append(slot_data)

## 加载存档槽元数据
func _load_slot_metadata(slot: int) -> SaveSlotData:
	var slot_data = SaveSlotData.new()
	slot_data.slot_index = slot

	var file_path = _get_save_path(slot)
	var json_str = _read_encrypted_file(file_path)

	if json_str == "":
		return slot_data

	var json = JSON.new()
	if json.parse(json_str) == OK and "meta" in json.data:
		var meta = json.data["meta"]
		slot_data.save_timestamp = meta.get("timestamp", 0)
		slot_data.day = json.data.get("player", {}).get("day", 1)

	return slot_data

# ============ 工具函数 ============

## 获取存档槽信息
func get_slot_info(slot: int) -> SaveSlotData:
	if slot >= 0 and slot < save_slots.size():
		return save_slots[slot]
	return null

## 获取存档时间字符串
func get_save_time_string(slot: int) -> String:
	var info = get_slot_info(slot)
	if info == null or info.save_timestamp == 0:
		return "—"

	var dt = Time.get_datetime_dict_from_unix_time(info.save_timestamp)
	return "%04d-%02d-%02d %02d:%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"]]
