extends Resource
class_name PlayerConfig

## PlayerConfig - 玩家属性配置
## 参考: C01 玩家属性系统 GDD

# ============ 基础属性 ============

@export_group("基础属性")
## 最大生命值
@export var max_health: float = 100.0
## 最大体力值
@export var max_stamina: float = 156.0
## 初始金钱
@export var initial_money: int = 500

# ============ 体力消耗 ============

@export_group("体力消耗")
## 耕地体力消耗
@export var stamina_cost_till: float = 2.5
## 播种体力消耗
@export var stamina_cost_plant: float = 1.0
## 浇水体力消耗
@export var stamina_cost_water: float = 1.5
## 收获体力消耗
@export var stamina_cost_harvest: float = 1.0
## 移动体力消耗/格
@export var stamina_cost_move_per_tile: float = 0.1

# ============ 背包设置 ============

@export_group("背包")
## 默认背包容量
@export var default_backpack_size: int = 30
## 最大堆叠数量
@export var max_stack_size: int = 9999
## 仓库初始容量
@export var initial_warehouse_size: int = 100
