# ADR-0004: 数据持久化与存档系统架构

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏需要可靠的存档系统来保存玩家进度，包括物品、位置、NPC好感度、农场状态等。需要设计存档数据结构、加密方案、自动存档策略和跨平台云同步。

### 存档需求分析

| 数据类别 | 示例 | 大小估计 | 同步需求 |
|----------|------|----------|----------|
| 玩家属性 | HP、体力、金钱 | ~1KB | 是 |
| 背包物品 | 物品ID+数量 | ~5KB | 是 |
| 农场状态 | 地块状态、作物 | ~20KB | 是 |
| NPC好感度 | 34个NPC好感度 | ~2KB | 是 |
| 季节进度 | 节日完成、成就 | ~5KB | 是 |
| 时间/天气 | 当前日期、天气 | ~1KB | 是 |

## Decision

### 存档槽位设计

```
存档槽位: 3个
├── Slot_0: 自动存档 (AutoSave)
├── Slot_1: 玩家手动存档 #1
├── Slot_2: 玩家手动存档 #2
└── Slot_3: 玩家手动存档 #3 (DLC扩展)
```

### 存档文件结构

```json
{
  "version": "1.0.0",
  "save_id": "uuid-v4-string",
  "created_at": "2026-04-08T10:00:00Z",
  "updated_at": "2026-04-08T10:00:00Z",
  "playtime_seconds": 3600,
  "player": {
    "name": "玩家名",
    "gender": "male|female",
    "stats": {
      "health": 100,
      "max_health": 100,
      "stamina": 156,
      "max_stamina": 156,
      "money": 5000
    }
  },
  "inventory": {
    "items": [
      {"id": "crop_tomato", "amount": 10},
      {"id": "tool_hoe", "amount": 1}
    ],
    "tool_upgrades": {
      "hoe": 2,
      "watering_can": 3
    }
  },
  "time": {
    "day": 15,
    "season": "spring",
    "year": 1,
    "hour": 14,
    "minute": 30
  },
  "weather": {
    "today": "sunny",
    "tomorrow": "rainy"
  },
  "farm": {
    "farm_name": "桃花源",
    "map_type": "standard",
    "plots": [
      {
        "position": [0, 0],
        "state": "growing",
        "crop_id": "crop_tomato",
        "growth_day": 3,
        "watered": true,
        "quality": "fine"
      }
    ],
    "buildings": [
      {"type": "house", "level": 1},
      {"type": "barn", "level": 2}
    ]
  },
  "relationships": {
    "npc_1": {"friendship": 150, "events": ["met", "birthday"]},
    "npc_2": {"friendship": 50, "events": []}
  },
  "skills": {
    "farming": 3,
    "foraging": 2,
    "fishing": 1,
    "mining": 0,
    "combat": 1
  },
  "achievements": ["first_crop", "first_fish"],
  "quests": {
    "active": ["quest_1"],
    "completed": ["quest_0"]
  },
  "flags": {
    "talked_to_mayor": true,
    "unlocked_desert": false
  }
}
```

### 存档管理器设计

```gdscript
# autoload/save_manager.gd
class_name SaveManager
extends Node

const SAVE_DIRECTORY: String = "user://saves/"
const SLOT_COUNT: int = 3
const AUTO_SLOT: int = 0
const CURRENT_VERSION: String = "1.0.0"

var _current_slot: int = -1
var _is_busy: bool = false

func _ready() -> void:
    _ensure_save_directory()

func _ensure_save_directory() -> void:
    var dir = DirAccess.open("user://")
    if not dir.dir_exists("saves"):
        dir.make_dir("saves")

# 获取存档槽位列表
func get_save_slots() -> Array[Dictionary]:
    var slots: Array[Dictionary] = []
    for i in range(SLOT_COUNT):
        var path = _get_save_path(i)
        if FileAccess.file_exists(path):
            var metadata = _load_metadata_only(i)
            slots.append(metadata)
        else:
            slots.append({"slot": i, "exists": false})
    return slots

# 保存游戏
func save_game(slot: int, data: Dictionary) -> bool:
    if _is_busy:
        push_warning("SaveManager: Already saving/loading")
        return false

    _is_busy = true

    # 添加元数据
    data["version"] = CURRENT_VERSION
    data["save_id"] = UUID.v4()
    data["updated_at"] = Time.get_datetime_string_from_system(true)

    # 计算游玩时间
    if has_meta("playtime_start"):
        data["playtime_seconds"] = Time.get_unix_time_from_system() - get_meta("playtime_start")

    # 序列化
    var json_str = JSON.stringify(data, "\t")
    var encrypted = _encrypt(json_str)

    # 写入文件
    var path = _get_save_path(slot)
    var file = FileAccess.open(path, FileAccess.WRITE)
    if file:
        file.store_buffer(encrypted)
        file.close()
        _current_slot = slot
        _is_busy = false
        save_completed.emit(slot)
        return true

    _is_busy = false
    push_error("SaveManager: Failed to save to slot %d" % slot)
    return false

# 加载游戏
func load_game(slot: int) -> Dictionary:
    if _is_busy:
        return {}

    _is_busy = true

    var path = _get_save_path(slot)
    if not FileAccess.file_exists(path):
        _is_busy = false
        return {}

    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        _is_busy = false
        return {}

    var encrypted = file.get_buffer(file.get_length())
    file.close()

    var json_str = _decrypt(encrypted)
    var data = JSON.parse_string(json_str)

    _is_busy = false
    _current_slot = slot

    if data:
        load_completed.emit(data)
        _apply_save_data(data)

    return data if data else {}

# 自动存档
func auto_save() -> bool:
    if _current_slot < 0:
        return false
    return save_game(AUTO_SLOT, _get_current_game_data())

func _get_save_path(slot: int) -> String:
    return SAVE_DIRECTORY + "save_slot_%d.sav" % slot

# 加密/解密 (AES-256)
func _encrypt(data: String) -> PackedByteArray:
    var key = _get_encryption_key()
    # 使用 Godot Crypto 类进行 AES 加密
    var crypto = Crypto.new()
    var key_bytes = key.to_utf8_buffer()
    var iv = crypto.generate_random_bytes(16)

    # 简化实现，实际使用 crypto.encrypt()
    return data.to_utf8_buffer()

func _decrypt(data: PackedByteArray) -> String:
    var key = _get_encryption_key()
    # 解密实现
    return data.get_string_from_utf8()

func _get_encryption_key() -> String:
    # 从配置文件或硬编码获取
    # 实际应从外部安全存储获取
    return "taoyuan_save_key_2026_secure"

# 仅加载元数据 (用于存档列表)
func _load_metadata_only(slot: int) -> Dictionary:
    var path = _get_save_path(slot)
    if not FileAccess.file_exists(path):
        return {}

    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return {}

    var encrypted = file.get_buffer(file.get_length())
    file.close()

    var json_str = _decrypt(encrypted)
    var data = JSON.parse_string(json_str)

    if data:
        return {
            "slot": slot,
            "exists": true,
            "player_name": data.get("player", {}).get("name", "Unknown"),
            "playtime_seconds": data.get("playtime_seconds", 0),
            "day": data.get("time", {}).get("day", 0),
            "season": data.get("time", {}).get("season", ""),
            "created_at": data.get("created_at", ""),
            "updated_at": data.get("updated_at", ""),
            "farm_name": data.get("farm", {}).get("farm_name", "")
        }
    return {"slot": slot, "exists": false}

func _get_current_game_data() -> Dictionary:
    # 从各系统收集当前游戏数据
    var data = {
        "player": GameManager.get_player_data(),
        "inventory": InventorySystem.get_save_data(),
        "time": TimeManager.get_save_data(),
        "weather": WeatherManager.get_save_data(),
        "farm": FarmManager.get_save_data(),
        "relationships": RelationshipManager.get_save_data(),
        "skills": SkillManager.get_save_data(),
        "achievements": AchievementManager.get_save_data(),
        "quests": QuestManager.get_save_data(),
        "flags": GameFlags.get_flags()
    }
    return data

func _apply_save_data(data: Dictionary) -> void:
    # 恢复各系统状态
    if data.has("player"):
        GameManager.apply_player_data(data.player)
    if data.has("inventory"):
        InventorySystem.apply_save_data(data.inventory)
    if data.has("time"):
        TimeManager.apply_save_data(data.time)
    # ... 其他系统

# 删除存档
func delete_save(slot: int) -> bool:
    var path = _get_save_path(slot)
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)
        return true
    return false

signal save_completed(slot: int)
signal load_completed(data: Dictionary)
```

### 自动存档策略

```gdscript
# autoload/auto_save_controller.gd
class_name AutoSaveController
extends Node

var auto_save_interval: int = 300  # 5分钟
var last_auto_save: int = 0

func _ready() -> void:
    TimeManager.day_ended.connect(_on_day_ended)

func _process(delta: float) -> void:
    # 每5分钟自动存档
    if TimeManager.elapsed_seconds - last_auto_save >= auto_save_interval:
        if SaveManager.auto_save():
            last_auto_save = TimeManager.elapsed_seconds
            NotificationManager.show_message("自动存档完成")

func _on_day_ended() -> void:
    # 每天结束时强制存档
    if SaveManager.auto_save():
        NotificationManager.show_message("每日存档完成")
        last_auto_save = TimeManager.elapsed_seconds
```

### WebDAV 云同步 (可选)

```gdscript
# systems/cloud/webdav_sync.gd
class_name WebDAVSync
extends Node

const WEBDAV_ENDPOINT: String = "https://cloud.example.com/webdav/taoyuan/"
var _http_client: HTTPRequest

func sync_to_cloud(slot: int) -> bool:
    # 上传存档到 WebDAV 服务器
    var local_path = SaveManager._get_save_path(slot)
    var cloud_path = WEBDAV_ENDPOINT + "save_slot_%d.sav" % slot

    # PUT request to upload
    # ...
    return true

func sync_from_cloud(slot: int) -> bool:
    # 从 WebDAV 下载存档
    var cloud_path = WEBDAV_ENDPOINT + "save_slot_%d.sav" % slot

    # GET request to download
    # ...
    return true

func list_cloud_saves() -> Array:
    # PROPFIND request to list remote files
    return []
```

## Alternatives Considered

### Alternative 1: SQLite 数据库存储

- **描述**: 使用 SQLite 数据库而非 JSON 文件
- **优点**: 查询效率高，支持增量更新
- **缺点**: 跨平台支持复杂，调试困难
- **拒绝理由**: 存档数据以整体为主，JSON足够

### Alternative 2: 无加密存档

- **描述**: 明文存储存档文件
- **优点**: 调试方便，用户可修改
- **缺点**: 无法防止作弊
- **拒绝理由**: 保留作弊可能，但加密防止意外损坏

## Consequences

### Positive
- **数据完整**: 所有状态可保存
- **安全性**: AES加密防止篡改
- **可移植**: JSON格式便于调试和迁移
- **自动存档**: 防止进度丢失

### Negative
- **存档大小**: 完整存档可能较大(~50KB)
- **加载时间**: 首次加载需解析JSON
- **加密开销**: 加解密有轻微CPU开销

## Validation Criteria

1. 存档保存时间 < 100ms
2. 存档加载时间 < 200ms
3. 存档文件大小 < 100KB
4. 加密存档无法被明文编辑
5. 自动存档不造成明显卡顿
