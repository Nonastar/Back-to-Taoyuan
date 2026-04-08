# 育种系统 (Breeding System)

> **Status**: Approved
> **Author**: Claude + User
> **Last Updated**: 2026-04-07
> **Implements Pillar**: 角色养成与自定义化

## Overview

育种系统是游戏中的核心养成系统，通过杂交育种创造独特的作物品种。系统包含种子箱、育种台、基因属性（甜度/产量/抗性/稳定度/变异率）、400+杂交配方和图鉴追踪。玩家可以通过种子制造机获得初始基因种子，通过同种杂交提升属性，通过异种杂交创造新作物，最终培育出传说中的高代杂交品种。

## Player Fantasy

育种系统给玩家带来**创造者的成就感**。玩家应该感受到：

- **培育的乐趣** — 从普通种子开始，通过一代代培育创造更强品种
- **发现惊喜** — 异种杂交可能创造出全新的作物，带来发现的喜悦
- **策略的深度** — 选择哪些种子配对、如何平衡属性需要深思熟虑
- **终极追求** — 培育出十代杂交品种是玩家的终极挑战

**Reference games**: Pokemon 的培育系统；Stardew Valley 的种子制造机进化版。

## Detailed Design

### Core Rules

#### 1. 基因属性系统 (Genetic Attributes)

每颗种子有5个基因属性（0-100）：

| 属性 | 效果 | 说明 |
|------|------|------|
| **甜度 (Sweetness)** | 售价加成 | 影响杂交配方的甜度要求 |
| **产量 (Yield)** | 双收概率 | 影响杂交配方的产量要求 |
| **抗性 (Resistance)** | 减缓枯萎 | 影响作物在不利条件下的表现 |
| **稳定度 (Stability)** | 属性波动 | 稳定度越高，后代属性波动越小 |
| **变异率 (Mutation Rate)** | 大幅突变概率 | 变异率越高，杂交时大幅突变的概率越高 |

**星级计算**：
```
total_stats = sweetness + yield + resistance
stars = 5 if total >= 250
       4 if total >= 200
       3 if total >= 150
       2 if total >= 100
       1 otherwise
```

#### 2. 种子来源

**A. 种子制造机产出**
- 基础作物种子有默认基因属性
- 农耕技能越高，获得遗传种子的概率越高
- 农耕10级时100%产出遗传种子

**B. 默认基因计算**
```gdscript
baseSweetness = 15 + priceScore * 40    # 基于售价
baseYield = 15 + growthScore * 35        # 基于生长天数
baseResistance = 10 + (priceScore + growthScore) * 15
defaultStability = 50
defaultMutationRate = 10
```

#### 3. 同种杂交 (Same-Crop Breeding)

同种杂交用于提升现有作物的属性：

**代数机制**：
- 种子制造机产出：G0（世代=0）
- 同种杂交：世代+1
- 异种杂交：取亲本最大世代+1

**属性计算**：
```
avgStability = (parentA.stability + parentB.stability) / 2
avgMutationRate = (parentA.mutationRate + parentB.mutationRate) / 2
fluctuationScale = (avgMutationRate / 50) * (1 - avgStability / 100)

# 属性继承（加随机波动）
newAttribute = round((parentA.attr + parentB.attr) / 2) + round((random - 0.5) * 2 * BASE_MUTATION * fluctuationScale)

# 稳定度提升
newStability = min(avgStability + 3, 95)
```

**变异事件**：
- 触发条件：`random() < avgMutationRate / 100`
- 效果：1-2个属性发生大幅跳跃（±15~30）
- 变异时变异率自身也浮动±5

#### 4. 异种杂交 (Cross-Crop Breeding)

异种杂交用于创造全新作物：

**杂交配方**：400+种杂交配方，每个配方定义：
- 亲本A和亲本B的作物ID
- 最低甜度要求和最低产量要求
- 产出的杂交作物ID和基础属性

**杂交成功条件**：
```
avgSweetness = (parentA.sweetness + parentB.sweetness) / 2
avgYield = (parentA.yield + parentB.yield) / 2

success = avgSweetness >= hybrid.minSweetness
       and avgYield >= hybrid.minYield
```

**杂交失败**：返回随机亲本副本，属性微降（随机一项-5）

#### 5. 杂交配方层级

**杂交种分代**：

| 代数 | 数量 | 说明 |
|------|------|------|
| 一代杂交 | 100+ | 基础作物之间的杂交 |
| 二代杂交 | 100+ | 一代杂交之间的杂交 |
| 三代+杂交 | 200+ | 高代杂交，属性要求更高 |

#### 6. 种子箱 (Seed Box)

**容量配置**：

| 等级 | 容量 | 升级费用 |
|------|------|----------|
| 0 | 30 | - |
| 1 | 45 | 5000g + 材料 |
| 2 | 60 | 15000g + 材料 |
| 3 | 75 | 30000g + 材料 |
| 4 | 90 | 50000g + 材料 |
| 5 | 105 | 80000g + 材料 |

#### 7. 育种台 (Breeding Stations)

**配置**：

| 项目 | 值 |
|------|---|
| 最大数量 | 3个 |
| 建造费用 | 100000g + 材料 |
| 加工时间 | 2天 |

**育种流程**：
1. 将两颗种子放入育种台
2. 等待2天（期间不能取出）
3. 获得结果种子（放入种子箱）

### States and Transitions

#### 育种槽状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Empty** | 空闲 | 无亲本种子 |
| **Breeding** | 培育中 | 已放入亲本，等待完成 |
| **Ready** | 可收获 | 培育完成，等待收取 |

**状态转换**：
```
Empty → Breeding: startBreeding(slot, seedA, seedB)
Breeding → Ready: daysProcessed >= 2
Ready → Empty: collectResult(slot)
```

#### 种子状态

| 状态 | 描述 |
|------|------|
| **InBox** | 在种子箱中 |
| **InStation** | 在育种台中 |
| **Collected** | 已收取 |

### Interactions with Other Systems

#### 依赖系统 (Upstream Dependencies)

| System | Interface | Usage |
|--------|-----------|-------|
| C04 农场地块 | crop planting | 种子被种植 |
| C03 技能系统 | farming_level | 种子制造机概率 |
| F03 物品数据 | crop definitions | 作物定义、杂交种定义 |
| C02 库存系统 | items | 种子箱、育种台建造 |
| P09 成就系统 | breeding events | 育种相关成就 |

#### 事件订阅 (Event Subscriptions)

```gdscript
# 农场地块系统发出
signal crop_harvested_with_seed(crop_id: String, quality: String)

# 育种系统发出
signal breeding_complete(hybrid_id: String, generation: int)
signal hybrid_discovered(hybrid_id: String)
signal mutation_occurred(stats_changed: Array)
```

#### API 接口

```gdscript
class_name BreedingSystem extends Node

## 种子箱
func add_to_box(genetics: SeedGenetics) -> bool
func remove_from_box(genetics_id: String) -> BreedingSeed
func get_box_seeds() -> Array

## 育种台
func craft_station() -> bool
func start_breeding(slot: int, seed_a: String, seed_b: String) -> bool
func collect_result(slot: int) -> SeedGenetics
func get_station_status(slot: int) -> Dictionary

## 种子制造机
func try_seed_maker_genetic_seed(crop_id: String, farming_level: int) -> bool

## 种子箱升级
func upgrade_seed_box() -> Dictionary
func can_upgrade_seed_box() -> bool

## 图鉴
func get_compendium() -> Array
func get_discovered_count() -> int
func get_highest_tier() -> int

## 统计
func get_total_breeding_count() -> int
func record_hybrid_grown(hybrid_id: String)

## 存档
func serialize() -> Dictionary
func deserialize(data: Dictionary)
```

## Formulas

### 1. 默认基因属性

```
baseSweetness = clamp(15 + priceScore * 40, 0, 100)
baseYield = clamp(15 + growthScore * 35, 0, 100)
baseResistance = clamp(10 + (priceScore + growthScore) * 15, 0, 100)
where:
  priceScore = min(crop.sellPrice / 350, 1)
  growthScore = min(crop.growthDays / 12, 1)
```

### 2. 稳定度计算

```
fluctuationScale = (avgMutationRate / 50) * (1 - avgStability / 100)
newStability = min(avgStability + GENERATIONAL_STABILITY_GAIN(3), MAX_STABILITY(95))
```

### 3. 变异判定

```
mutationOccurs = random() < avgMutationRate / 100
if mutationOccurs:
    mutateCount = random() < 0.5 ? 1 : 2
    for each stat in random 1-2 attributes:
        direction = random() < POSITIVE_CHANCE(0.6) ? +1 : -1
        jump = MUTATION_JUMP_MIN(15) + random() * MUTATION_JUMP_RANGE(15)
        newValue = clamp(oldValue + jump * direction, 0, 100)
```

### 4. 异种杂交结果

```
avgSweetness = (parentA.sweetness + parentB.sweetness) / 2
avgYield = (parentA.yield + parentB.yield) / 2
avgStability = (parentA.stability + parentB.stability) / 2

if matched_hybrid and avgSweetness >= minSweetness and avgYield >= minYield:
    result.isHybrid = true
    result.sweetness = clamp(hybrid.base.sweetness * 0.6 + avgSweetness * 0.4 + fluctuate(), 0, 100)
    result.yield = clamp(hybrid.base.yield * 0.6 + avgYield * 0.4 + fluctuate(), 0, 100)
else:
    result = random_parent.copy()
    result.randomStat -= 5  # 失败惩罚
```

### 5. 星级评分

```
totalStats = sweetness + yield + resistance
return 5 if total >= 250
     4 if total >= 200
     3 if total >= 150
     2 if total >= 100
     1 otherwise
```

## Edge Cases

### 1. 种子箱边界

- **种子箱满**：无法添加新种子
- **取出已放入的种子**：startBreeding 失败时自动归还

### 2. 育种台边界

- **重复放入**：育种台有种子时不能再次放入
- **提前取出**：不允许，必须等2天完成
- **种子箱满时收获**：日志提示，种子暂存

### 3. 杂交边界

- **无可用杂交配方**：返回随机亲本
- **属性不满足要求**：返回亲本副本并提示原因
- **同种杂交**：世代+1，稳定度提升

### 4. 存档迁移

- **旧存档无限种系统**：初始化空种子箱
- **杂交种图鉴丢失**：同种杂交时自动补充图鉴

## Dependencies

| ID | System Name | Type | Interface |
|----|-------------|------|-----------|
| D01 | C04 FarmPlotSystem | Hard | crop planting, harvest |
| D02 | C03 SkillSystem | Soft | farming_level for seed maker |
| D03 | F03 ItemDataSystem | Hard | crop definitions |
| D04 | C02 InventorySystem | Hard | seed box, station crafting |
| D05 | P09 AchievementSystem | Soft | breeding events |

## Tuning Knobs

### 基因参数

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `BASE_MUTATION_MAGNITUDE` | 8 | 5-15 | 基础变异幅度 |
| `GENERATIONAL_STABILITY_GAIN` | 3 | 1-5 | 每代稳定度提升 |
| `MAX_STABILITY` | 95 | 80-99 | 稳定度上限 |
| `MUTATION_JUMP_MIN` | 15 | 10-20 | 变异最小跳动 |
| `MUTATION_JUMP_MAX` | 30 | 20-40 | 变异最大跳动 |
| `MUTATION_POSITIVE_CHANCE` | 0.6 | 0.4-0.8 | 变异正向概率 |

### 容量参数

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `BASE_BREEDING_BOX` | 30 | 20-50 | 基础种子箱容量 |
| `SEED_BOX_INCREMENT` | 15 | 10-20 | 每级容量增量 |
| `BREEDING_DAYS` | 2 | 1-3 | 育种天数 |
| `MAX_STATIONS` | 3 | 2-5 | 最大育种台数量 |

### 种子制造机参数

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `SEED_MAKER_BASE_CHANCE` | 0.15 | 0.1-0.3 | 基础遗传概率 |
| `SEED_MAKER_PER_LEVEL` | 0.085 | 0.05-0.1 | 每级额外概率 |

## Visual/Audio Requirements

### UI Requirements

| Screen | Component | Description |
|--------|-----------|-------------|
| 育种界面 | BreedingView | 主界面，种子箱和育种台 |
| 种子箱面板 | SeedBoxPanel | 种子列表和操作 |
| 育种台面板 | StationPanel | 育种台状态和进度 |
| 杂交配方面板 | RecipePanel | 可用配方列表 |
| 图鉴面板 | CompendiumPanel | 已发现杂交种 |

### Visual Feedback

- 种子箱中的种子按星级和世代分类显示
- 育种台进度条显示剩余天数
- 变异发生时闪烁特效
- 新杂交种发现时特殊动画

### Audio Feedback

- 种子放入/取出音效
- 育种完成音效
- 变异发生音效
- 杂交种发现音效

## Acceptance Criteria

### Functional Criteria

- [ ] 种子制造机正确产出遗传种子
- [ ] 种子箱容量和升级功能正常
- [ ] 育种台建造和操作正常
- [ ] 同种杂交正确计算属性
- [ ] 异种杂交正确匹配配方
- [ ] 杂交失败正确处理
- [ ] 图鉴正确记录已发现杂交种
- [ ] 存档/读档状态正确保存恢复

### Performance Criteria

- [ ] 种子列表加载 < 100ms
- [ ] 杂交计算 < 5ms
- [ ] 图鉴查询 < 10ms

### Compatibility Criteria

- [ ] 与农场地块的种子种植集成
- [ ] 与技能系统的农耕等级集成
- [ ] 与成就系统的育种成就集成

## Open Questions

| ID | Question | Owner | Target Date |
|----|----------|-------|-------------|
| O1 | 杂交配方是否需要动态生成而非固定列表？ | Designer | Pre-MVP |
| O2 | 是否需要杂交种子的种子返还机制？ | Balance | Pre-MVP |
| O3 | 杂交种作物是否需要独立的出售价格？ | Balance | Pre-MVP |
