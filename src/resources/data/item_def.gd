extends Resource
class_name ItemDef

## ItemDef - 物品定义基类
## 参考: F03 物品数据系统 GDD

# ============ 基本信息 ============

## 唯一标识符 (snake_case)
@export var id: String = ""

## 显示名称
@export var name: String = ""

## 物品描述
@export_multiline var description: String = ""

## 物品分类 (使用ItemCategory常量)
@export var category: int = ItemCategory.MISC

## 基础售价
@export var sell_price: int = 0

## 图标路径
@export var icon_path: String = ""

## 是否可堆叠
@export var stackable: bool = true

## 最大堆叠数量
@export var max_stack: int = 9999

# ============ 食用属性 ============

## 是否可食用
@export var edible: bool = false

## 食用恢复体力
@export var stamina_restore: float = 0.0

## 食用恢复生命
@export var health_restore: float = 0.0

# ============ 物品标签 ============

## 物品标签 (用于复杂查询)
@export var tags: Array[String] = []

# ============ 品质 ============

## 物品品质 (0=普通, 1=优秀, 2=精良, 3=史诗)
@export var quality: int = Quality.NORMAL

# ============ 验证方法 ============

## 验证物品数据是否有效
func validate() -> bool:
	if id.is_empty():
		push_error("[ItemDef] Validation failed: id is empty")
		return false

	if sell_price < 0:
		push_error("[ItemDef] Validation failed: sell_price < 0 for %s" % id)
		return false

	if edible and stamina_restore <= 0 and health_restore <= 0:
		push_warning("[ItemDef] Warning: edible item %s has no restore values" % id)

	return true

# ============ 显示信息 ============

## 获取显示信息字典
func get_display_info(item_quality: int = Quality.NORMAL) -> Dictionary:
	return {
		"name": name,
		"description": description,
		"icon_path": icon_path,
		"category": category,
		"sell_price": _calculate_sell_price(item_quality),
		"quality_color": _get_quality_color(item_quality),
		"edible": edible,
		"stamina_restore": stamina_restore,
		"health_restore": health_restore
	}

## 计算实际售价
func _calculate_sell_price(item_quality: int) -> int:
	var multiplier = Quality.get_multiplier(item_quality)
	return int(sell_price * multiplier)

## 获取品质颜色
func _get_quality_color(item_quality: int) -> Color:
	return Quality.get_color(item_quality)
