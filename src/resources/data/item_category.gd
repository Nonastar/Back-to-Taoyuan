extends RefCounted
class_name ItemCategory

## ItemCategory - 物品分类枚举
## 参考: F03 物品数据系统 GDD

# ============ 分类常量 ============

const SEED: int = 0
const CROP: int = 1
const FISH: int = 2
const ORE: int = 3
const GEM: int = 4
const FOOD: int = 5
const MATERIAL: int = 6
const WEAPON: int = 7
const RING: int = 8
const HAT: int = 9
const SHOE: int = 10
const MACHINE: int = 11
const MISC: int = 12
const TOOL: int = 13
const BOOK: int = 14
const QUEST: int = 15
const RELIC: int = 16

# ============ 分类名称 ============

const NAMES: Dictionary = {
	SEED: "种子",
	CROP: "作物",
	FISH: "鱼",
	ORE: "矿石",
	GEM: "宝石",
	FOOD: "食物",
	MATERIAL: "材料",
	WEAPON: "武器",
	RING: "戒指",
	HAT: "帽子",
	SHOE: "鞋子",
	MACHINE: "机器",
	MISC: "杂物",
	TOOL: "工具",
	BOOK: "书籍",
	QUEST: "任务物品",
	RELIC: "文物"
}

# ============ 分类堆叠限制 ============

const STACK_LIMITS: Dictionary = {
	SEED: 999,
	CROP: 9999,
	FISH: 9999,
	ORE: 999,
	GEM: 999,
	FOOD: 9999,
	MATERIAL: 9999,
	WEAPON: 1,
	RING: 1,
	HAT: 1,
	SHOE: 1,
	MACHINE: 1,
	MISC: 9999,
	TOOL: 1,
	BOOK: 9999,
	QUEST: 1,
	RELIC: 1
}

# ============ 静态方法 ============

## 获取分类名称
static func get_category_name(category: int) -> String:
	return NAMES.get(category, "未知")

## 获取分类是否可堆叠
static func is_stackable(category: int) -> bool:
	return STACK_LIMITS.get(category, 9999) > 1

## 获取分类堆叠限制
static func get_stack_limit(category: int) -> int:
	return STACK_LIMITS.get(category, 9999)
