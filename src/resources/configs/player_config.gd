extends Resource
class_name PlayerConfig

## PlayerConfig - 玩家属性配置
## 参考: C01 玩家属性系统 GDD

# ============ 基础属性 ============

@export_group("基础属性")
## 最大生命值
@export var max_health: float = 100.0

## 体力上限 (第0档)
@export var max_stamina: float = 120.0

## 初始金钱
@export var initial_money: int = 500

## 玩家默认名称
@export var default_player_name: String = "农夫"

## 默认性别 (male/female)
@export var default_gender: String = "male"

# ============ 体力系统 ============

@export_group("体力系统")
## 体力耗尽阈值
@export var exhausted_threshold: int = 5

## 体力上限档位 [0-4]
@export var stamina_cap_level_0: int = 120
@export var stamina_cap_level_1: int = 160
@export var stamina_cap_level_2: int = 200
@export var stamina_cap_level_3: int = 250
@export var stamina_cap_level_4: int = 300

# ============ HP系统 ============

@export_group("HP系统")
## 基础最大HP
@export var base_max_hp: int = 100

## 每级战斗等级HP加成
@export var hp_per_combat_level: int = 5

## Fighter专精HP加成
@export var fighter_hp_bonus: int = 25

## Warrior专精HP加成
@export var warrior_hp_bonus: int = 40

## 低HP警告阈值 (百分比)
@export var low_hp_threshold: float = 0.25

# ============ 每日结算 ============

@export_group("每日结算")
## 晚睡就寝最大恢复率 (24时)
@export var late_night_recovery_max: float = 0.9

## 晚睡就寝最小恢复率 (25时)
@export var late_night_recovery_min: float = 0.6

## 昏厥后体力恢复率
@export var passout_stamina_recovery: float = 0.5

## 昏厥扣钱比例
@export var passout_money_penalty_rate: float = 0.1

## 昏厥扣钱上限
@export var passout_money_penalty_cap: int = 1000

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

# ============ 工具方法 ============

## 获取体力上限档位数组
func get_stamina_caps() -> Array[int]:
	return [stamina_cap_level_0, stamina_cap_level_1, stamina_cap_level_2,
			stamina_cap_level_3, stamina_cap_level_4]
