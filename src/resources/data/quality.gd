extends RefCounted
class_name Quality

## Quality - 物品品质枚举和计算
## 参考: F03 物品数据系统 GDD

# ============ 品质常量 ============

const NORMAL: int = 0
const FINE: int = 1
const EXCELLENT: int = 2
const SUPREME: int = 3

# ============ 修正系数 ============

const MULTIPLIERS: Dictionary = {
	NORMAL: 1.0,
	FINE: 1.25,
	EXCELLENT: 1.5,
	SUPREME: 2.0
}

# ============ 品质颜色 ============

const COLORS: Dictionary = {
	NORMAL: Color(1.0, 1.0, 1.0),
	FINE: Color(0.2, 0.8, 0.2),
	EXCELLENT: Color(0.2, 0.4, 1.0),
	SUPREME: Color(0.6, 0.2, 0.8)
}

# ============ 品质名称 ============

const NAMES: Dictionary = {
	NORMAL: "普通",
	FINE: "优秀",
	EXCELLENT: "精良",
	SUPREME: "史诗"
}

# ============ 静态方法 ============

## 获取品质修正系数
static func get_multiplier(quality: int) -> float:
	return MULTIPLIERS.get(quality, 1.0)

## 获取品质颜色
static func get_color(quality: int) -> Color:
	return COLORS.get(quality, Color.WHITE)

## 获取品质名称
static func get_quality_name(quality: int) -> String:
	return NAMES.get(quality, "未知")

## 从字符串获取品质
static func from_string(quality_str: String) -> int:
	match quality_str.to_lower():
		"normal", "普通":
			return NORMAL
		"fine", "优秀":
			return FINE
		"excellent", "精良":
			return EXCELLENT
		"supreme", "史诗":
			return SUPREME
		_:
			return NORMAL
