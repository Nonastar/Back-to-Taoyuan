extends Node
## FishCompendiumSystem - 鱼类图鉴系统
## 追踪玩家钓过的所有鱼类，记录捕获数量和最佳品质
## 与 FishingSystem 集成，通过 EventBus.fish_caught 接收捕获事件

# ============ 常量 ============

## 鱼类 Emoji 映射
const FISH_EMOJI: Dictionary = {
	"bluegill": "🐟",
	"carp": "🐟",
	"frog": "🐸",
	"koi": "🐠",
	"catfish": "🐟",
	"trout": "🐟",
	"bass": "🐟",
	"snow_fish": "🐟",
	"golden_fish": "🐠",
	"eel": "🐍",
	"salmon": "🐟",
	"mountain_trout": "🐟",
	"ice_fish": "🐟",
	"magic_fish": "✨🐟",
	"swamp_creature": "🦎",
	"tuna": "🐟",
	"swordfish": "⚔️🐟",
	"shark": "🦈",
	"legendary_fish": "🐉",
	"mythical_fish": "🐲",
	"treasure_fish": "💎🐟"
}
const DEFAULT_EMOJI: String = "🐟"

## 稀有度颜色
const RARITY_COLORS: Dictionary = {
	"common": Color(1, 1, 1, 1),       # 普通
	"fine": Color(0.26, 0.65, 0.96, 1),  # 优质
	"rare": Color(0.67, 0.28, 0.74, 1), # 精品
	"legendary": Color(1, 0.84, 0, 1)     # 传说
}

# ============ 单例 ============

static var _instance: FishCompendiumSystem = null

static func get_instance() -> FishCompendiumSystem:
	return _instance

# ============ 信号 ============

signal fish_discovered(fish_id: String)  # 发现新鱼
signal compendium_updated()  # 图鉴更新

# ============ 状态 ============

var _discovered_fish: Dictionary = {}  # {fish_id: FishRecord}
var _total_fish_count: int = 0  # 鱼类总数

# FishRecord 结构:
# {
#     "discovered": bool,
#     "catch_count": int,
#     "best_quality": int,
#     "first_catch_time": int,  # 时间戳
#     "last_catch_time": int
# }

# ============ 初始化 ============

func _ready() -> void:
	_instance = self
	_count_total_fish()
	_connect_signals()
	print("[FishCompendiumSystem] Initialized with %d fish species" % _total_fish_count)

func _connect_signals() -> void:
	# 连接 EventBus 的钓鱼捕获信号
	if EventBus and EventBus.has_signal("fish_caught"):
		EventBus.fish_caught.connect(_on_fish_caught)
		print("[FishCompendiumSystem] Connected to EventBus.fish_caught")
	else:
		push_warning("[FishCompendiumSystem] EventBus.fish_caught not found")

func _count_total_fish() -> void:
	# 计算 FISH_DATA 中的鱼类总数
	if FishingSystem and FishingSystem.FISH_DATA:
		_total_fish_count = FishingSystem.FISH_DATA.size()
	else:
		# 回退：手动统计（如果 FishingSystem 未加载）
		_total_fish_count = 21  # 大约数量

# ============ 公共 API ============

## 记录捕获
func record_catch(fish_id: String, quantity: int = 1, quality: int = 0) -> bool:
	if not _is_valid_fish(fish_id):
		return false

	var is_new = not is_discovered(fish_id)

	# 获取或创建记录
	var record = _get_or_create_record(fish_id)

	# 更新记录
	record["catch_count"] += quantity
	record["last_catch_time"] = Time.get_unix_time_from_system()

	# 更新最佳品质
	if quality > record.get("best_quality", 0):
		record["best_quality"] = quality

	# 如果是新发现
	if is_new:
		record["discovered"] = true
		record["first_catch_time"] = Time.get_unix_time_from_system()
		fish_discovered.emit(fish_id)
		print("[FishCompendiumSystem] New fish discovered: %s" % fish_id)

	compendium_updated.emit()
	return true

## 检查是否已发现
func is_discovered(fish_id: String) -> bool:
	if _discovered_fish.has(fish_id):
		return _discovered_fish[fish_id].get("discovered", false)
	return false

## 获取捕获次数
func get_catch_count(fish_id: String) -> int:
	if _discovered_fish.has(fish_id):
		return _discovered_fish[fish_id].get("catch_count", 0)
	return 0

## 获取最佳品质
func get_best_quality(fish_id: String) -> int:
	if _discovered_fish.has(fish_id):
		return _discovered_fish[fish_id].get("best_quality", 0)
	return 0

## 获取已发现鱼类数量
func get_discovered_count() -> int:
	var count = 0
	for fish_id in _discovered_fish.keys():
		if _discovered_fish[fish_id].get("discovered", false):
			count += 1
	return count

## 获取鱼类总数
func get_total_fish_count() -> int:
	return _total_fish_count

## 获取已发现鱼类列表
func get_discovered_list() -> Array:
	var result = []
	for fish_id in _discovered_fish.keys():
		if _discovered_fish[fish_id].get("discovered", false):
			result.append(fish_id)
	return result

## 获取未发现鱼类列表
func get_undiscovered_list() -> Array:
	var result = []
	# 获取所有鱼 ID
	var all_fish_ids = _get_all_fish_ids()
	for fish_id in all_fish_ids:
		if not is_discovered(fish_id):
			result.append(fish_id)
	return result

## 获取按地点分类的鱼类
func get_fish_by_location(location: String) -> Array:
	if FishingSystem and FishingSystem.FISH_BY_LOCATION.has(location):
		return FishingSystem.FISH_BY_LOCATION[location]
	return []

## 获取进度 (0.0 - 1.0)
func get_progress() -> float:
	if _total_fish_count == 0:
		return 0.0
	return float(get_discovered_count()) / float(_total_fish_count)

## 获取进度文本
func get_progress_text() -> String:
	var discovered = get_discovered_count()
	var total = get_total_fish_count()
	var percentage = int(get_progress() * 100)
	return "已钓: %d/%d 种鱼 (%d%%)" % [discovered, total, percentage]

## 获取鱼类图标
static func get_fish_emoji(fish_id: String) -> String:
	return FISH_EMOJI.get(fish_id, DEFAULT_EMOJI)

## 获取稀有度名称
static func get_rarity_name(rarity: float) -> String:
	if rarity >= 0.5:
		return "普通"
	elif rarity >= 0.2:
		return "优质"
	elif rarity >= 0.1:
		return "精品"
	else:
		return "传说"

## 获取稀有度颜色
static func get_rarity_color(rarity: float) -> Color:
	if rarity >= 0.5:
		return RARITY_COLORS["common"]
	elif rarity >= 0.2:
		return RARITY_COLORS["fine"]
	elif rarity >= 0.1:
		return RARITY_COLORS["rare"]
	else:
		return RARITY_COLORS["legendary"]

## 获取难度星级文本
static func get_difficulty_stars(difficulty: int) -> String:
	var stars = min(difficulty, 5)  # 最多5星
	return "★".repeat(stars) + "☆".repeat(5 - stars)

# ============ 内部方法 ============

func _is_valid_fish(fish_id: String) -> bool:
	# 检查鱼 ID 是否有效
	if FishingSystem and FishingSystem.FISH_DATA:
		return FishingSystem.FISH_DATA.has(fish_id)
	# 如果 FishingSystem 未加载，允许所有 ID
	return true

func _get_or_create_record(fish_id: String) -> Dictionary:
	if not _discovered_fish.has(fish_id):
		_discovered_fish[fish_id] = {
			"discovered": false,
			"catch_count": 0,
			"best_quality": 0,
			"first_catch_time": 0,
			"last_catch_time": 0
		}
	return _discovered_fish[fish_id]

func _get_all_fish_ids() -> Array:
	if FishingSystem and FishingSystem.FISH_DATA:
		return FishingSystem.FISH_DATA.keys()
	# 回退：返回已发现的鱼
	return _discovered_fish.keys()

func _on_fish_caught(fish_id: String, quantity: int, quality: int) -> void:
	record_catch(fish_id, quantity, quality)

# ============ 存档支持 ============

func serialize() -> Dictionary:
	return {
		"discovered_fish": _discovered_fish,
		"total_fish_count": _total_fish_count
	}

func deserialize(data: Dictionary) -> void:
	_discovered_fish = data.get("discovered_fish", {})
	_total_fish_count = data.get("total_fish_count", 0)
	_count_total_fish()  # 确保总数正确
	print("[FishCompendiumSystem] Loaded: discovered=%d, total=%d" % [get_discovered_count(), _total_fish_count])

# ============ 调试 ============

func debug_print_all() -> void:
	print("[FishCompendiumSystem] Debug - All fish:")
	for fish_id in _get_all_fish_ids():
		var discovered = is_discovered(fish_id)
		var count = get_catch_count(fish_id)
		var emoji = get_fish_emoji(fish_id)
		print("  %s %s: %s, caught x%d" % [emoji, fish_id, "✅" if discovered else "❓", count])
