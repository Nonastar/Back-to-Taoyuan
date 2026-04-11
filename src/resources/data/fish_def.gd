extends Resource
class_name FishDef

## FishDef - 鱼类定义
## 参考: P02 钓鱼系统 GDD

# ============ 基本信息 ============

## 唯一标识符
@export var id: String = ""

## 显示名称
@export var name: String = ""

## 物品描述
@export_multiline var description: String = ""

## 基础售价
@export var base_price: int = 50

## 鱼类图标路径
@export var icon_path: String = ""

## 是否可堆叠
@export var stackable: bool = true

## 最大堆叠数量
@export var max_stack: int = 9999

# ============ 钓鱼属性 ============

## 稀有度
@export var rarity: int = FishRarity.NORMAL

## 钓鱼难度 (1-10)
@export var difficulty: int = 1

## 钓鱼技能经验值
@export var exp_value: int = 10

## 可钓鱼地点列表
@export var locations: PackedStringArray = []

## 可钓鱼季节 (0=春, 1=夏, 2=秋, 3=冬)
@export var seasons: PackedInt32Array = []

## 可钓鱼时间段 (小时数组，如 [6, 7, 8, 9, 10, 11] 表示早晨)
@export var available_hours: PackedInt32Array = []

## 是否为传说鱼
@export var is_legendary: bool = false

## 每日限制数量 (传说鱼通常为1)
@export var daily_limit: int = 0

# ============ 分类 ============

## 物品分类
@export var category: int = ItemCategory.FISH

# ============ 属性 ============

## 食用恢复体力
@export var stamina_restore: float = 5.0

## 食用恢复生命
@export var health_restore: float = 0.0

## 是否可食用
@export var edible: bool = true

# ============ 钓鱼点常量 ============

class FishRarity:
	const NORMAL: int = 0      # 普通
	const GOOD: int = 1        # 优质
	const FINE: int = 2        # 精品
	const LEGENDARY: int = 3   # 传说

class FishingLocation:
	const FOREST_POND: String = "forest_pond"    # 森林池塘
	const RIVER: String = "river"                # 河流
	const MOUNTAIN_LAKE: String = "mountain_lake"  # 山顶湖泊
	const OCEAN: String = "ocean"                # 海洋
	const WITCH_SWAMP: String = "witch_swamp"    # 女巫沼泽
	const SECRET_POND: String = "secret_pond"    # 秘密池塘

# ============ 稀有度映射 ============

const RARITY_NAMES: Dictionary = {
	FishRarity.NORMAL: "普通",
	FishRarity.GOOD: "优质",
	FishRarity.FINE: "精品",
	FishRarity.LEGENDARY: "传说"
}

## 稀有度售价系数
const RARITY_PRICE_MULT: Dictionary = {
	FishRarity.NORMAL: 1.0,
	FishRarity.GOOD: 1.5,
	FishRarity.FINE: 2.5,
	FishRarity.LEGENDARY: 5.0
}

## 稀有度颜色
const RARITY_COLORS: Dictionary = {
	FishRarity.NORMAL: Color(1.0, 1.0, 1.0),
	FishRarity.GOOD: Color(0.2, 0.8, 0.2),
	FishRarity.FINE: Color(0.2, 0.4, 1.0),
	FishRarity.LEGENDARY: Color(0.8, 0.6, 0.2)
}

## 稀有度出现概率权重
const RARITY_WEIGHTS: Dictionary = {
	FishRarity.NORMAL: 60,
	FishRarity.GOOD: 25,
	FishRarity.FINE: 12,
	FishRarity.LEGENDARY: 3
}

# ============ 地点常量 ============

## 地点名称映射
const LOCATION_NAMES: Dictionary = {
	FishingLocation.FOREST_POND: "森林池塘",
	FishingLocation.RIVER: "河流",
	FishingLocation.MOUNTAIN_LAKE: "山顶湖泊",
	FishingLocation.OCEAN: "海洋",
	FishingLocation.WITCH_SWAMP: "女巫沼泽",
	FishingLocation.SECRET_POND: "秘密池塘"
}

## 地点 Emoji 映射
const LOCATION_EMOJIS: Dictionary = {
	FishingLocation.FOREST_POND: "🌲",
	FishingLocation.RIVER: "🏞️",
	FishingLocation.MOUNTAIN_LAKE: "🏔️",
	FishingLocation.OCEAN: "🌊",
	FishingLocation.WITCH_SWAMP: "🧙",
	FishingLocation.SECRET_POND: "✨"
}

# ============ 季节常量 ============

const SEASON_NAMES: Dictionary = {
	0: "春",
	1: "夏",
	2: "秋",
	3: "冬"
}

# ============ 时间段常量 ============

## 时间段定义
const TIME_PERIODS: Dictionary = {
	"morning": [6, 7, 8, 9, 10, 11],
	"afternoon": [12, 13, 14, 15, 16, 17],
	"evening": [18, 19, 20, 21, 22, 23],
	"night": [0, 1, 2, 3, 4, 5]
}

const TIME_PERIOD_NAMES: Dictionary = {
	"morning": "早晨",
	"afternoon": "下午",
	"evening": "傍晚",
	"night": "深夜"
}

# ============ 验证方法 ============

func validate() -> bool:
	if id.is_empty():
		push_error("[FishDef] Validation failed: id is empty")
		return false

	if difficulty < 1 or difficulty > 10:
		push_error("[FishDef] Validation failed: difficulty out of range for %s" % id)
		return false

	if locations.is_empty():
		push_warning("[FishDef] Warning: %s has no locations" % id)

	if seasons.is_empty():
		push_warning("[FishDef] Warning: %s has no seasons" % id)

	return true

# ============ 显示信息 ============

func get_display_name() -> String:
	return name

func get_rarity_name() -> String:
	return RARITY_NAMES.get(rarity, "未知")

func get_location_names() -> Array:
	var names = []
	for loc in locations:
		names.append(LOCATION_NAMES.get(loc, loc))
	return names

func get_season_names() -> Array:
	var names = []
	for season in seasons:
		names.append(SEASON_NAMES.get(season, str(season)))
	return names

func get_price() -> int:
	var mult = RARITY_PRICE_MULT.get(rarity, 1.0)
	return int(base_price * mult)

func get_rarity_color() -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

func is_available_now(season: int, hour: int) -> bool:
	# 检查季节
	if not seasons.is_empty() and season not in seasons:
		return false

	# 检查时间段
	if not available_hours.is_empty() and hour not in available_hours:
		return false

	return true
