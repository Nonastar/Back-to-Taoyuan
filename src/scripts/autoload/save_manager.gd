extends Node

## SaveManager - 存档系统
## 负责游戏数据的保存和加载
## 参考: ADR-0004 存档系统架构, F04 存档系统 GDD

# ============ 常量 ============

## 存档槽数量
const SAVE_SLOT_COUNT: int = 3

## 存档目录名称
const SAVE_DIR: String = "user://saves/"

## 存档文件后缀
const SAVE_EXTENSION: String = ".json"

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
	print("[SaveManager] Initialized")

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

	# 写入文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Failed to open save file for writing")
		EventBus.save_completed.emit(slot, false)
		return false

	file.store_string(json_str)
	file.close()

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

	# 读取文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Failed to open save file for reading")
		EventBus.load_completed.emit(slot, false)
		return false

	var json_str = file.get_as_text()
	file.close()

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
		print("[SaveManager] Save deleted from slot %d" % slot)
		return true

	return false

## 检查存档槽是否有存档
func has_save(slot: int) -> bool:
	if slot < 0 or slot >= SAVE_SLOT_COUNT:
		return false
	return FileAccess.file_exists(_get_save_path(slot))

## 获取存档文件路径
func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "save_slot_%d%s" % [slot, SAVE_EXTENSION]

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
	var file = FileAccess.open(file_path, FileAccess.READ)

	if file:
		var json_str = file.get_as_text()
		file.close()

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
