# 畜牧系统 (Animal Husbandry System)

> **状态**: Approved
> **Author**: Claude Code
> **Last Updated**: 2026-04-07
> **System ID**: P01
> **Implements Pillar**: 农场经营与农业系统

## Overview

畜牧系统管理玩家农场的动物养殖业务。系统包含多种动物（鸡、鸭、牛、羊、猪等），每种动物有不同的产出品（蛋、奶、毛等）和养殖要求。玩家需要建造鸡舍或谷仓容纳动物，每天喂养、抚摸增加好感度，动物产出品可出售或用于烹饪。畜牧系统是农场收入的重要来源，与库存系统、农场地块系统等多个系统交互。

## Player Fantasy

畜牧系统给玩家带来**温馨陪伴与稳定收入的满足感**。玩家应该感受到：

- **动物的可爱** — 每天抚摸动物，看着它们开心
- **产出惊喜** — 捡蛋、挤奶时期待高品质
- **农场氛围** — 农场里有鸡鸣牛叫，充满生机
- **稳定收入** — 畜牧提供每日稳定产出

**Reference games**: Stardew Valley 的畜牧系统温馨治愈；星露谷物語的动物互动深受玩家喜爱。

## Detailed Design

### Core Rules

#### 1. 动物类型（19种）

| 类型 | 动物 | 产出品 | 建筑要求 |
|------|------|--------|----------|
| **小动物** | 鸡、鸭、鹅、兔子、火鸡 | 蛋 | 鸡舍 |
| **中型动物** | 山羊、绵羊、猪 | 羊奶/毛/松露 | 谷仓 |
| **大型动物** | 牛、水牛、奶牛 | 牛奶 | 大谷仓 |
| **特殊动物** | 马、羊驼、猪(白)、猪(黑)、鸭(金) | 各有特色产出 | 特殊谷仓 |

#### 2. 建筑类型（4级）

| 建筑 | 可容纳动物数 | 可升级到 |
|------|-------------|----------|
| **鸡舍** (Coop) | 4只 | → Deluxe Coop |
| **豪华鸡舍** (Deluxe Coop) | 8只 | → Big Coop |
| **谷仓** (Barn) | 4只 | → Big Barn |
| **大谷仓** (Big Barn) | 8只 | → Deluxe Barn |

#### 3. 好感度系统

- **好感度范围**: 0-1000
- **好感度等级**:
  - Stranger: 0-199
  - Pal: 200-399
  - Friend: 400-699
  - Best Friend: 700-1000
- **好感度操作**:
  - 喂养: +1~3
  - 抚摸: +5~12
  - 治好疾病: +30
  - 抱起/放下: -10

#### 4. 产出品质加成

| 好感度等级 | 高品质概率加成 |
|------------|----------------|
| Stranger | +0% |
| Pal | +2% |
| Friend | +5% |
| Best Friend | +10% |

#### 5. 每日操作

```
1. 喂养动物 → 好感度+1~3
2. 抚摸动物 → 好感度+5~12（可选）
3. 捡取产出品（蛋、奶）→ 存入背包
4. 清理建筑 → 好感度+1
```

#### 6. 产出规则

- **产蛋动物**: 每日产1个蛋（好感度影响品质）
- **产奶动物**: 每日产1份奶（需挤奶）
- **剪毛动物**: 每3天可剪毛一次
- **松露猪**: 每日有概率产出松露

### States and Transitions

#### 动物状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **Hungry** | 需要喂养 | 今日未喂养 |
| **Fed** | 已喂养 | 今日已喂养 |
| **Sick** | 生病 | 随机触发或未清理 |
| **Sad** | 心情低落 | 好感度低或未抚摸 |

#### 建筑状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **Clean** | 干净 | 今日已清理 |
| **Dirty** | 脏乱 | 今日未清理 |
| **Full** | 已满 | 动物数 = 容量上限 |

#### 产出状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **Ready** | 可收获 | 今日有产出未捡取 |
| **Collected** | 已收集 | 产出已存入背包 |
| **Cooldown** | 冷却中 | 剪毛等需等待 |

**状态转换图**:
```
Hungry → Fed: 喂养操作
Fed → Sick: 随机概率或连续脏乱
Sick → Hungry: 治疗后恢复
Sad → Happy: 抚摸或清理
Happy → Sad: 连续未抚摸
Ready → Collected: 捡取产出
```

### Interactions with Other Systems

**上游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **C04 FarmPlotSystem** | 硬依赖 | 动物住在农场建筑内，建筑需要建筑空间 |
| **C02 InventorySystem** | 硬依赖 | 产出品存入背包 (add_item)，消耗饲料 (remove_item) |
| **F03 ItemDataSystem** | 硬依赖 | 动物定义、饲料定义、产出品定义 |

**下游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **P13 FishPondSystem** | 软依赖 | 鱼塘养殖类似畜牧，可能共享代码 |

### 提供给下游的 API

```gdscript
class_name AnimalHusbandrySystem extends Node

## 单例访问
static func get_instance() -> AnimalHusbandrySystem

## 动物操作
func feed_animal(animal_id: String) -> bool:
    """喂养动物，返回是否成功"""

func pet_animal(animal_id: String) -> bool:
    """抚摸动物，增加好感度"""

func collect_product(animal_id: String) -> Dictionary:
    """收集产出，返回 {success, item_id, quality}"""

func heal_animal(animal_id: String) -> bool:
    """治疗生病的动物"""

## 建筑操作
func build_animal_building(type: BuildingType) -> bool:
    """建造动物建筑"""

func upgrade_building(building_id: String) -> bool:
    """升级动物建筑"""

func clean_building(building_id: String) -> bool:
    """清理建筑"""

## 查询
func get_animal_info(animal_id: String) -> Dictionary:
    """获取动物信息（好感度、状态、产出）"""

func get_building_info(building_id: String) -> Dictionary:
    """获取建筑信息（动物数、容量、状态）"""

func get_all_products() -> Array[ProductInfo]:
    """获取所有可收集的产出"""
```

## Formulas

### 1. 好感度变化公式

#### 喂养好感度增量
```
friendship_delta = clamp(random_integer(1, 3), 0, 1000 - current_friendship)
```
- 每次喂养增加 1~3 点好感度
- 不会超过上限 1000

#### 抚摸好感度增量
```
friendship_delta = clamp(random_integer(5, 12), 0, 1000 - current_friendship)
```
- 每次抚摸增加 5~12 点好感度

#### 治疗好感度增量
```
friendship_delta = 30
```
- 每次治疗增加 30 点好感度

#### 抱起/放下好感度减量
```
friendship_delta = -10
```
- 每次抱起或放下减少 10 点好感度（最低为 0）

#### 清理建筑好感度增量
```
friendship_delta = 1
```
- 清理建筑使该建筑内所有动物好感度 +1

### 2. 产出品质加成公式

基础高品质概率由 F03 ItemDataSystem 提供，好友度加成在此基础上叠加：

```
effective_bonus = base_bonus + friendship_bonus[friendship_level]

# 好友度等级对应的加成
friendship_bonus = {
    "Stranger":      0%,
    "Pal":           +2%,
    "Friend":        +5%,
    "Best Friend":   +10%
}

# 最终高品质概率
final_high_quality_chance = min(100%, base_high_quality_chance + effective_bonus)
```

### 3. 好感度等级判定
```
if friendship >= 700:   level = "Best Friend"
elif friendship >= 400:  level = "Friend"
elif friendship >= 200:  level = "Pal"
else:                    level = "Stranger"
```

### 4. 建筑容量公式

| 建筑类型 | 基础容量 | 升级容量 |
|----------|----------|----------|
| 鸡舍 (Coop) | 4 | 8 |
| 豪华鸡舍 (Deluxe Coop) | 8 | 12 |
| 谷仓 (Barn) | 4 | 8 |
| 大谷仓 (Big Barn) | 8 | 12 |

```
current_capacity = base_capacity[building_type]
# 未来可通过升级系统扩展
```

### 5. 剪毛周期公式
```
if days_since_last_shear >= 3:
    can_shear = true
    cooldown_remaining = 0
else:
    can_shear = false
    cooldown_remaining = 3 - days_since_last_shear
```

### 6. 生病概率公式

基于连续脏乱天数计算：
```
if building.dirty_days >= 3:
    sick_probability = 0.15  # 15% 概率生病
elif building.dirty_days >= 2:
    sick_probability = 0.05  # 5% 概率生病
else:
    sick_probability = 0.01  # 1% 基础概率
```

### 7. 松露猪产出公式
```
truffle_chance = base_chance * (1 + friendship_bonus / 100)

# 基础产出概率: 30%
# Best Friend 时: 30% * (1 + 10/100) = 33%
```

### 8. 每日产出判定
```
if animal.is_producing_today:
    if product_type == "egg":
        produce_quantity = 1
    elif product_type == "milk":
        produce_quantity = 1
    elif product_type == "wool":
        # 需要检查剪毛冷却
        produce_quantity = 1 if can_shear else 0
    elif product_type == "truffle":
        # 松露猪使用独立概率
        produce_quantity = 1 if random() < truffle_chance else 0
```

### 公式变量表

| 变量名 | 类型 | 范围 | 说明 |
|--------|------|------|------|
| `friendship` | int | 0-1000 | 当前好感度 |
| `friendship_delta` | int | -10 ~ +30 | 好感度变化量 |
| `friendship_level` | string | 见等级表 | 当前好感度等级 |
| `building.capacity` | int | 4-12 | 建筑容量 |
| `building.dirty_days` | int | 0+ | 连续脏乱天数 |
| `truffle_chance` | float | 0.0-1.0 | 松露产出概率 |
| `final_high_quality_chance` | float | 0.0-1.0 | 最终高品质概率 |
| `days_since_last_shear` | int | 0+ | 距上次剪毛天数 |

### 预期产出范围

| 动物类型 | 每日产出价值 (普通) | 每日产出价值 (Best Friend) |
|----------|-------------------|---------------------------|
| 鸡 | 50g | 50g + 品质加成 |
| 鸭 | 80g | 80g + 品质加成 |
| 牛 | 150g | 150g + 品质加成 |
| 山羊 | 120g | 120g + 品质加成 |
| 猪(松露) | 30%概率 × 500g = 150g/日 | 33%概率 × 500g = 165g/日 |

## Edge Cases

### 1. 好感度边界情况

| 情况 | 处理方式 |
|------|----------|
| 好感度达到 1000 | 不再增加（clamp 到 1000） |
| 好感度降到 0 以下 | 不会发生，抱起只减 10，最少到 0 |
| 好感度计算溢出 | 使用 clamp 函数确保在 0-1000 范围内 |

### 2. 产出边界情况

| 情况 | 处理方式 |
|------|----------|
| 背包已满 | 产出会保留在建筑内，下次可继续收集，显示提示"背包已满" |
| 连续多天不收集 | 产出不会累积，最多保留当天的产出 |
| 剪毛冷却中 | 显示"还需 X 天"提示 |
| 生病的动物 | 停止产出，需治疗后才恢复 |

### 3. 建筑边界情况

| 情况 | 处理方式 |
|------|----------|
| 建筑已满（达到容量上限） | 无法放入新动物，提示"建筑已满" |
| 建筑内没有动物 | 可以出售/拆除建筑 |
| 建筑正在生产中 | 无法升级，需先清空动物 |
| 拆建筑时有动物 | 需先转移动物，否则提示"请先转移动物" |

### 4. 喂养边界情况

| 情况 | 处理方式 |
|------|----------|
| 背包没有饲料 | 无法喂养，显示"需要饲料"提示 |
| 动物已生病 | 可以喂养但不能产出，治疗后恢复 |
| 多次喂养同一天 | 第二次喂养无效，显示"今日已喂养" |
| 饿死（连续 3 天未喂养） | 动物永久消失，显示提示 |

### 5. 交易边界情况

| 情况 | 处理方式 |
|------|----------|
| 动物交易时带装备 | 装备自动卸下存回背包 |
| 购买动物后背包满 | 动物直接进入建筑（如果建筑有空位） |
| 卖出怀孕动物 | 幼崽不会产出（简化处理） |

### 6. 特殊动物边界

| 情况 | 处理方式 |
|------|----------|
| 羊驼产出特殊物品 | 由 F03 ItemDataSystem 定义具体物品 |
| 金鸭产出金色蛋 | 由 F03 ItemDataSystem 定义金色蛋属性 |
| 马作为坐骑 | 不产出物品，用于农场移动（未来系统） |

### 7. 多日不上线处理

当玩家多日不上线时：
```
1. 每日喂养操作：跳过（系统自动标记为已喂养？）
   - 方案A：自动喂养（消耗饲料）
   - 方案B：动物饿瘦/生病但不死亡
   - 方案C：简单处理，多日不喂养直接死亡

# 推荐方案A：自动喂养系统（未来实现）
```

### 8. 动物逃跑处理

如果动物围栏破损（建筑损坏系统）：
```
1. 建筑耐久度降至 0
2. 动物有概率逃跑
3. 逃跑的动物变成流浪动物
4. 玩家可以找回流浪动物
```

### 9. 并发操作冲突

| 情况 | 处理方式 |
|------|----------|
| 同时点击喂养和抚摸 | 按顺序执行，好感度增量叠加 |
| 收集产出时动物刚生病 | 产出不生成，保持待产状态 |
| 升级建筑时动物正在产出 | 允许升级，不影响产出 |

## Dependencies

### 上游依赖

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **C04** | FarmPlotSystem | 硬依赖 | 动物建筑是特殊的农场建筑，需要占用地块 |
| **C02** | InventorySystem | 硬依赖 | 产出品存入背包，消耗饲料 |
| **F03** | ItemDataSystem | 硬依赖 | 动物定义、饲料定义、产出品定义 |
| **C05** | DayTimeSystem | 硬依赖 | 每日刷新产出、喂养状态 |

### 下游依赖

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P02** | CropFarmingSystem | 软依赖 | 饲料可能来自农作物 |
| **P06** | ShopSystem | 软依赖 | 动物商店购买动物，产出品可出售 |
| **P07** | CookingSystem | 软依赖 | 动物产出品可作为烹饪食材 |
| **P08** | QuestSystem | 软依赖 | 畜牧相关任务（喂养 N 只动物等） |
| **P13** | FishPondSystem | 软依赖 | 鱼塘类似畜牧，可参考设计 |
| **F01** | SaveLoadSystem | 硬依赖 | 畜牧数据需要保存/加载 |

### 数据流

```
F03 ItemDataSystem (动物定义)
    ↓
C04 FarmPlotSystem (建筑空间)
    ↓
C05 DayTimeSystem (每日刷新)
    ↓
AnimalHusbandrySystem (核心逻辑)
    ↓
C02 InventorySystem (产出存入背包)
    ↓
P06 ShopSystem (出售产出) / P07 CookingSystem (烹饪食材)
```

### 待确认的依赖

| 系统 | 依赖说明 | 状态 |
|------|----------|------|
| **P10** | 动物好感度是否影响 NPC 好感度？（需要对话系统支持） | 待定 |
| **P11** | 动物是否有战斗能力？（某些情况下可保护农场） | 不需要 |
| **P12** | 天气是否影响产出？（如雨天产蛋率下降） | MVP 不需要 |

## Tuning Knobs

### 好感度系统调参

| 参数 | 默认值 | 安全范围 | 说明 | 过高/过低影响 |
|------|--------|----------|------|---------------|
| `friendship.max` | 1000 | 500-2000 | 好感度上限 | 影响达到 Best Friend 的难度 |
| `friendship.feed.min` | 1 | 0-5 | 喂养好感度最小增量 | 影响每日好感度增长上限 |
| `friendship.feed.max` | 3 | 1-10 | 喂养好感度最大增量 | 影响每日好感度增长上限 |
| `friendship.pet.min` | 5 | 0-10 | 抚摸好感度最小增量 | 影响抚摸价值 |
| `friendship.pet.max` | 12 | 5-20 | 抚摸好感度最大增量 | 影响抚摸价值 |
| `friendship.heal` | 30 | 10-50 | 治疗好感度增量 | 影响治疗的价值 |
| `friendship.pickup` | -10 | -5 ~ -30 | 抱起好感度减量 | 影响是否可以抱动物 |
| `friendship.clean` | 1 | 0-5 | 清理建筑好感度增量 | 影响清理的价值 |

### 好感度等级阈值

| 等级 | 默认阈值 | 安全范围 | 说明 |
|------|----------|----------|------|
| `friend_threshold` | 200 | 100-300 | 升级到 Pal |
| `friend_threshold` | 400 | 300-500 | 升级到 Friend |
| `best_friend_threshold` | 700 | 600-800 | 升级到 Best Friend |

### 品质加成调参

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| `quality_bonus.stranger` | 0% | 0-5% | Stranger 等级加成 |
| `quality_bonus.pal` | 2% | 0-10% | Pal 等级加成 |
| `quality_bonus.friend` | 5% | 2-15% | Friend 等级加成 |
| `quality_bonus.best_friend` | 10% | 5-25% | Best Friend 等级加成 |

### 建筑容量调参

| 建筑类型 | 默认容量 | 安全范围 | 说明 |
|----------|----------|----------|------|
| `coop.capacity` | 4 | 2-8 | 鸡舍容量 |
| `deluxe_coop.capacity` | 8 | 4-12 | 豪华鸡舍容量 |
| `barn.capacity` | 4 | 2-8 | 谷仓容量 |
| `big_barn.capacity` | 8 | 4-12 | 大谷仓容量 |

### 生产周期调参

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| `shear.cooldown_days` | 3 | 2-7 | 剪毛冷却天数 |
| `truffle.base_chance` | 0.30 | 0.1-0.5 | 松露猪基础产出概率 |
| `egg.production_rate` | 1.0 | 0.5-2.0 | 产蛋倍率（可调整个别动物） |
| `milk.production_rate` | 1.0 | 0.5-2.0 | 产奶倍率 |

### 健康系统调参

| 参数 | 默认值 | 安全范围 | 说明 | 过高/过低影响 |
|------|--------|----------|------|---------------|
| `sick.chance.dirty_3days` | 15% | 5-30% | 连续脏乱3天生病概率 | 影响清理建筑重要性 |
| `sick.chance.dirty_2days` | 5% | 1-15% | 连续脏乱2天生病概率 | 影响清理建筑重要性 |
| `sick.chance.base` | 1% | 0-5% | 基础生病概率 | 影响游戏难度 |
| `sick.heal_cost` | 100g | 50-500g | 治疗费用 | 影响治疗的价值 |
| `sick.starve_days` | 3 | 2-5 | 饿死天数 | 影响玩家上线频率要求 |

### 调参交互警告

| 参数 A | 参数 B | 交互说明 |
|--------|--------|----------|
| `shear.cooldown_days` | 羊数量 | 冷却天数太长会导致毛产量过低 |
| `quality_bonus.best_friend` | 稀有动物价格 | 高加成 + 高价 = 收益过高 |
| `sick.starve_days` | 玩家在线频率 | 太短会让休闲玩家受挫 |
| `friend.feed.max` | 好感度上限 | 如果上限太低，快速满级失去意义 |

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

### 功能验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **AC-01** | 购买一只鸡放入鸡舍 | 鸡出现在鸡舍中，好感度为 0 | P0 |
| **AC-02** | 喂养动物后检查好感度 | 好感度增加 1~3 点 | P0 |
| **AC-03** | 抚摸动物后检查好感度 | 好感度增加 5~12 点 | P0 |
| **AC-04** | 连续抚摸达到 Best Friend | 好感度超过 700，显示 Best Friend 等级 | P1 |
| **AC-05** | 每日刷新后收集鸡蛋 | 背包中获得鸡蛋（可能高品质） | P0 |
| **AC-06** | 每日刷新后挤牛奶 | 背包中获得牛奶（可能高品质） | P0 |
| **AC-07** | 连续 3 天不清理建筑 | 动物有概率生病 | P1 |
| **AC-08** | 治疗生病的动物 | 动物恢复健康，产出恢复 | P1 |
| **AC-09** | 连续 3 天不喂养动物 | 动物消失 | P1 |
| **AC-10** | 升级鸡舍到豪华鸡舍 | 容量从 4 增加到 8 | P1 |
| **AC-11** | 放入超过容量的动物 | 提示"建筑已满"，无法放入 | P0 |
| **AC-12** | 剪羊毛（冷却中） | 显示还需 X 天，无法剪毛 | P1 |
| **AC-13** | 剪羊毛（冷却结束） | 获得羊毛，重置冷却 | P0 |
| **AC-14** | 松露猪每日产出 | 有概率产出松露（Best Friend 概率更高） | P1 |
| **AC-15** | 抱起动物 | 好感度减少 10 点 | P1 |

### 品质验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **QC-01** | Stranger 动物产出 100 次 | 高品质概率 = 基础概率 | P1 |
| **QC-02** | Best Friend 动物产出 100 次 | 高品质概率 = 基础概率 + 10% | P1 |
| **QC-03** | 好感度刚好在阈值边界 | 按阈值判定等级（>= 是，< 否） | P1 |

### 集成验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **IC-01** | 背包满时收集产出 | 产出保留在建筑内，提示背包已满 | P0 |
| **IC-02** | 没有饲料时喂养 | 显示"需要饲料"，喂养失败 | P0 |
| **IC-03** | 产出品出售 | 通过 P06 ShopSystem 正常出售 | P1 |
| **IC-04** | 保存/加载游戏 | 畜牧数据正确保存和恢复 | P0 |
| **IC-05** | 动物在烹饪中使用 | 通过 P07 CookingSystem 使用产出品 | P2 |

### 性能验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **PC-01** | 拥有 20 只动物 | 每日刷新 < 16ms | P0 |
| **PC-02** | 拥有 10 个畜牧建筑 | UI 加载 < 100ms | P1 |

### UI 验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **UC-01** | 点击动物 | 显示动物信息面板（好感度、状态） | P0 |
| **UC-02** | 好感度变化 | 数值动画过渡 | P2 |
| **UC-03** | 产出可用 | 显示收集提示图标 | P0 |
| **UC-04** | 建筑满/空状态 | 正确显示容量信息 | P0 |

## Open Questions

[To be designed]
