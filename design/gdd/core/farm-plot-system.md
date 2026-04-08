# 农场地块系统 (FarmPlot System)

> **状态**: In Design
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: C04
> **Implements Pillar**: 农场经营与农业系统

## Overview

农场地块系统管理玩家的农场土地，包括地块开垦、作物种植、浇水施肥、收获等核心农业玩法。系统支持普通地块、果树种植、温室大棚、洒水器自动化，以及虫害/杂草/巨型作物等随机事件。系统是农场经营的核心，与技能系统、物品系统、天气系统等多个系统交互，是游戏最复杂的 Core 系统之一。

## Player Fantasy

农场地块系统给玩家带来**耕耘与收获的满足感**。玩家应该感受到：

- **劳动的节奏** — 每天早起浇水、除虫，看着作物一点点长大
- **收获的喜悦** — 作物成熟时金光闪闪，点击收获满屏的作物
- **策略的深度** — 什么季节种什么、如何搭配洒水器和肥料获得最大收益
- **意外的惊喜** — 巨型作物的形成、优质作物的出现让玩家兴奋不已

**Reference games**: Stardew Valley 的农业系统是经典标杆；星露谷物語的巨型作物和温室深受喜爱。

## Detailed Design

### Core Rules

#### 1. 地块系统
- 农场尺寸：4×4 → 6×6 → 8×8 → 10×10（可升级）
- 地块状态：`wasteland`(荒地) → `tilled`(已耕) → `planted`(已种) → `growing`(生长中) → `harvestable`(可收获)

#### 2. 地块操作
- **开垦** (`tillPlot`): 消耗体力，将荒地变为已耕状态
- **播种** (`plantCrop`): 消耗种子，将已耕地块种上作物
- **浇水** (`waterPlot`): 消耗体力，手动给地块浇水
- **施肥** (`applyFertilizer`): 消耗肥料，提升作物品质或加速生长
- **收获** (`harvestPlot`): 获得作物，扣除经验
- **铲除** (`removeCrop`): 移除作物，保留肥料

#### 3. 生长规则
- 作物生长天数由 F03 ItemDataSystem 提供 (`CropDef.growthDays`)
- 每日结算时浇水地块 +1 天生长
- 未浇水 2 天后作物枯萎（回到 tilled 状态）
- 虫害感染地块停止生长，3天后作物死亡
- 杂草生长地块减速

#### 4. 浇水系统
- 雨天自动浇水（由 F02 WeatherSystem 提供 `isRainy`）
- 洒水器覆盖范围自动浇水
- 保湿土肥料有概率保留浇水状态

#### 5. 洒水器系统
| 类型 | 覆盖范围 | 容量 |
|------|----------|------|
| 普通 | 4块（上下左右） | - |
| 高级 | 8块（周围一圈） | - |
| 优质 | 24块（5×5区域） | - |

#### 6. 肥料系统
| 肥料类型 | 效果 |
|----------|------|
| 基础肥料 | 品质+1级 |
| 优质肥料 | 品质+2级 |
| 高级生长激素 | 生长加速 10% |
| 保湿土 | 保留浇水状态 50% |

#### 7. 品质判定
- 由 C03 SkillSystem 的 `roll_crop_quality()` 判定
- 农耕等级越高，高品质概率越大
- 肥料加成叠加到 `quality_bonus` 参数
- Lv9 + 优质肥料 = 最高 Supreme 概率

#### 8. 巨型作物
- 3×3 同种作物成熟后，1% 概率形成巨型作物组
- 巨型作物一次收获 9×2=18 个作物
- 形成后同组地块共享 giantCropGroup

#### 9. 虫害系统
- 每日 8% 概率感染（稻草人减半）
- 感染地块停止生长
- 3天后作物死亡
- 可手动除虫（治愈）

#### 10. 杂草系统
- 每日 6% 概率长草（稻草人减半）
- 长草地块生长减速
- 4天后作物死亡
- 可手动除草

#### 11. 随机事件
- **雷暴**: 25% 概率触发，可能劈毁作物，避雷针可吸收
- **乌鸦袭击**: 无稻草人时 15% 概率毁一株作物
- **巨型作物形成**: 见规则 8

#### 12. 果树系统
- 果树单独种植，不占用地块
- 果树成熟需要 28 天（1个季节）
- 果树品质随年龄提升：0年normal, 1年fine, 2年excellent, 3+年supreme
- 最多种植数量有限制

#### 13. 温室系统
- 固定地块数量，可升级扩展
- 温室内部不受天气影响
- 可种植任何季节作物
- 支持育种系统（P12）

#### 14. 野树系统
- 野外种植树木，不占用地块
- 成熟后可安装采脂器
- 采脂周期产出树液产品
- 可砍伐获得木材

### States and Transitions

#### 地块状态
| 状态 | 描述 | 条件 |
|------|------|------|
| **wasteland** | 荒地，未开垦 | 初始状态 |
| **tilled** | 已耕地块 | 开垦后/收获后/枯萎后 |
| **planted** | 刚播种 | 播种后第一天 |
| **growing** | 生长中 | 播种后第2天到成熟前 |
| **harvestable** | 可收获 | 生长天数达到要求 |

**地块状态转换:**
```
wasteland → tilled: tillPlot()
tilled → planted: plantCrop()
planted → growing: 浇水后过夜
growing → harvestable: 生长天数达到
growing → waseland: 虫害死亡/枯萎
planted/growing/harvestable → tilled: harvestPlot() 或 removeCrop()
```

#### 果树状态
| 状态 | 描述 | 条件 |
|------|------|------|
| **growing** | 生长中 | 未成熟 |
| **mature** | 已成熟 | growthDays >= 28 |

#### 野树状态
| 状态 | 描述 | 条件 |
|------|------|------|
| **growing** | 生长中 | 未成熟 |
| **mature** | 已成熟 | growthDays >= def.growthDays |
| **tapped** | 采脂中 | 安装采脂器后 |

### Interactions with Other Systems

#### 上游依赖

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **F03 ItemDataSystem** | 硬依赖 | 获取作物定义、种子数据 |
| **C03 SkillSystem** | 硬依赖 | 调用 roll_crop_quality() 判定品质 |
| **F02 WeatherSystem** | 软依赖 | 获取 isRainy 判断雨天浇水 |
| **C01 PlayerStatsSystem** | 软依赖 | 消耗体力操作 |
| **P12 BreedingSystem** | 软依赖 | 育种种子种植 |

#### 下游依赖

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **P01 AnimalHusbandrySystem** | 软依赖 | 共享牧场设施 |
| **P12 BreedingSystem** | 软依赖 | 育种需要农场地块 |
| **C06 BuildingUpgradeSystem** | 软依赖 | 温室升级依赖 |
| **F04 SaveLoadSystem** | 硬依赖 | 存档所有农场数据 |

#### 关键接口契约

```gdscript
## 订阅的信号

# F02 WeatherSystem
signal weather_changed(is_rainy: bool)

# C03 SkillSystem
signal skill_level_up(skill_type: SkillType, new_level: int)

## 发出的信号

signal plot_harvested(plot_id: int, crop_id: String, quantity: int)
signal plot_withered(plot_id: int)
signal plot_infested(plot_id: int)
signal giant_crop_formed(crop_id: String)
signal lightning_strike(crop_name: String)
signal crow_attack(crop_name: String)
```

#### API 接口

```gdscript
class_name FarmPlotSystem extends Node

## 地块操作
func till_plot(plot_id: int) -> bool
func plant_crop(plot_id: int, crop_id: String) -> bool
func water_plot(plot_id: int) -> bool
func apply_fertilizer(plot_id: int, fertilizer_type: FertilizerType) -> bool
func harvest_plot(plot_id: int) -> Dictionary  # {crop_id, genetics}
func remove_crop(plot_id: int) -> bool
func cure_pest(plot_id: int) -> bool
func clear_weed(plot_id: int) -> bool

## 洒水器
func place_sprinkler(plot_id: int, sprinkler_type: SprinklerType) -> bool
func remove_sprinkler(plot_id: int) -> bool

## 每日更新
func daily_update(is_rainy: bool) -> Dictionary
func on_season_change(new_season: Season) -> Dictionary

## 随机事件
func lightning_strike() -> Dictionary
func crow_attack() -> Dictionary

## 巨型作物
func check_giant_crops() -> Array
func harvest_giant_crop(plot_id: int) -> Dictionary

## 果树
func plant_fruit_tree(tree_type: FruitTreeType) -> bool
func daily_fruit_tree_update(season: Season) -> Array

## 温室
func init_greenhouse()
func greenhouse_daily_update()

## 存档接口
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

## Formulas

### 1. 作物有效生长天数

```
base_growth_days = CropDef.growthDays

# 肥料加速
fertilizer_speedup = fertilizer_def.growthSpeedup ?? 0

# 温室/家升级加成
house_bonus = wallet.cropGrowthBonus  # 0-20%

# 仙缘能力加成
spirit_bonus = hidden_npc.getAbilityValue('tao_yao_2') / 100  # 春息

total_speedup = fertilizer_speedup + house_bonus + spirit_bonus
effective_days = floor(base_growth_days × (1 - total_speedup))
effective_days = max(1, effective_days)  # 最小1天
```

### 2. 作物品质判定

```
# 基础判定（调用 C03 SkillSystem）
base_quality = C03.roll_crop_quality(quality_bonus)

# 肥料加成
if fertilizer == 'quality_fertilizer':
    base_quality += 2
elif fertilizer == 'basic_fertilizer':
    base_quality += 1

base_quality = clamp(base_quality, NORMAL, SUPREME)
```

### 3. 巨型作物产出

```
if is_giant_crop:
    quantity = 9 × 2 = 18  # 9格，每格2个
else:
    quantity = 1
```

### 4. 巨型作物形成概率

```
# 条件：3×3 同种作物都已成熟
if all_9_plots_harvestable_and_same_crop():
    roll = random()
    if roll < 0.01:  # 1%
        form_giant_crop()
```

### 5. 虫害感染概率

```
base_chance = 0.08  # 8%
if scarecrow_count > 0:
    chance = base_chance × 0.5  # 稻草人减半
else:
    chance = base_chance
```

### 6. 杂草滋生概率

```
base_chance = 0.06  # 6%
if scarecrow_count > 0:
    chance = base_chance × 0.6  # 稻草人减少
else:
    chance = base_chance
```

### 7. 果树品质随年龄

```
if year_age >= 3:
    quality = SUPREME
elif year_age >= 2:
    quality = EXCELLENT
elif year_age >= 1:
    quality = FINE
else:
    quality = NORMAL
```

### 8. 投资回报率

```
seed_cost = CropDef.seedPrice
expected_yield = 1
expected_quality_mult = average_quality_multiplier  # 1.0-2.0
expected_price = CropDef.sellPrice × expected_quality_mult
profit = expected_price × expected_yield - seed_cost
ROI = profit / seed_cost × 100%
```

## Edge Cases

### 1. 季节结束时作物枯萎
- **场景**: 作物不是当前季节
- **处理**: 季节切换时枯萎，保留肥料

### 2. 巨型作物收获后残留
- **场景**: 收获巨型作物后同组其他格残留 giantCropGroup
- **处理**: 收获时清除同组所有地块的 giantCropGroup

### 3. 换季时耕地退化
- **场景**: 荒废的耕地在新季节有概率退化
- **处理**: 冬→春退化概率更高

### 4. 保温土保留浇水
- **场景**: 保湿土肥料有概率保留浇水状态
- **处理**: 概率判定由肥料定义决定

### 5. 虫害死亡后其他地块状态
- **场景**: 虫害地块死亡不影响其他正常地块
- **处理**: 单独处理每个地块

### 6. 果树在新季节不结果
- **场景**: 果树只在正确季节结果
- **处理**: 季节不匹配时不计算产出

### 7. 巨型作物组被破坏部分
- **场景**: 巨型作物组中某格被雷劈
- **处理**: 清除该格的 giantCropGroup，其他格保持

### 8. 温室换季处理
- **场景**: 温室作物不受季节影响
- **处理**: 温室地块不执行枯萎检查

### 9. 种子不足时播种
- **场景**: 玩家没有足够的种子
- **处理**: 返回 false，不消耗种子

### 10. 地块已达最大数量
- **场景**: 农场扩建到 10×10 后
- **处理**: expandFarm 返回 null

## Dependencies

### 上游依赖（C04 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F03** | ItemDataSystem | 硬依赖 | 获取作物定义、种子数据 |
| **C03** | SkillSystem | 硬依赖 | 调用 roll_crop_quality() 判定品质 |
| **F02** | WeatherSystem | 软依赖 | 获取 isRainy 判断雨天浇水 |
| **C01** | PlayerStatsSystem | 软依赖 | 消耗体力操作 |
| **P12** | BreedingSystem | 软依赖 | 育种种子种植 |

### 下游依赖（其他系统依赖 C04）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P01** | AnimalHusbandrySystem | 软依赖 | 共享牧场设施 |
| **P12** | BreedingSystem | 软依赖 | 育种需要农场地块 |
| **C06** | BuildingUpgradeSystem | 软依赖 | 温室升级依赖 |
| **F04** | SaveLoadSystem | 硬依赖 | 存档所有农场数据 |

## Tuning Knobs

### 农场配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `INITIAL_FARM_SIZE` | 4 | 固定 | 初始农场大小 |
| `MAX_FARM_SIZE` | 10 | 固定 | 最大农场大小 |
| `FARM_EXPAND_SIZES` | [4,6,8,10] | 固定 | 扩建尺寸列表 |

### 随机事件配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `LIGHTNING_CHANCE` | 0.25 | 0.1-0.5 | 雷暴概率 |
| `CROW_ATTACK_CHANCE` | 0.15 | 0.05-0.3 | 乌鸦袭击概率 |
| `GIANT_CROP_CHANCE` | 0.01 | 0.005-0.05 | 巨型作物形成概率 |
| `PEST_INFEST_CHANCE` | 0.08 | 0.02-0.2 | 每日虫害感染概率 |
| `WEED_GROW_CHANCE` | 0.06 | 0.02-0.15 | 每日杂草滋生概率 |

### 防护设施效果

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `SCARECROW_PEST_REDUCTION` | 0.5 | 0.3-0.8 | 稻草人减半虫害 |
| `SCARECROW_WEED_REDUCTION` | 0.6 | 0.4-0.9 | 稻草人减少杂草 |

### 枯萎/死亡配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `UNWATERED_WITHER_DAYS` | 2 | 1-4 | 未浇水枯萎天数 |
| `PEST_DEATH_DAYS` | 3 | 2-5 | 虫害致死天数 |
| `WEED_SLOW_FACTOR` | 0.5 | 0.3-0.7 | 杂草生长减速系数 |

### 巨型作物配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `GIANT_CROP_GRID_SIZE` | 3 | 固定 | 形成巨型作物需要3×3 |
| `GIANT_CROP_MULTIPLIER` | 2 | 1-5 | 巨型作物产量倍数 |

### 果树配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `FRUIT_TREE_MATURITY_DAYS` | 28 | 14-56 | 果树成熟天数 |
| `MAX_FRUIT_TREES` | 10 | 5-20 | 最大果树数量 |

### 温室配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `GREENHOUSE_PLOT_COUNT` | 4 | 2-10 | 温室初始地块数 |
| `GREENHOUSE_MAX_PLOTS` | 12 | 4-20 | 温室最大地块数 |

### 调试配置

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `DEBUG_INSTANT_GROW` | false | 作物立即成熟 |
| `DEBUG_NO_PESTS` | false | 禁用虫害 |
| `DEBUG_GIANT_CROPS` | false | 必定形成巨型作物 |

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 地块状态转换正确 | 按顺序执行操作，验证状态变化 |
| **AC-02** | 浇水后作物生长 | 浇水后等待一天，验证 growthDays 增加 |
| **AC-03** | 未浇水 2 天后枯萎 | 不浇水 2 天后验证作物消失 |
| **AC-04** | 收获获得正确物品 | 收获后检查背包 |
| **AC-05** | 洒水器覆盖浇水 | 放置洒水器后验证自动浇水 |
| **AC-06** | 肥料效果生效 | 施肥后验证品质提升 |
| **AC-07** | 巨型作物形成 | 3×3 成熟作物验证形成 |
| **AC-08** | 巨型作物大量产出 | 收获巨型作物验证 18 个 |

### 随机事件验收

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **RE-01** | 稻草人减少虫害 | 有/无稻草人时对比虫害率 |
| **RE-02** | 雷暴随机触发 | 多次测试验证概率 |
| **RE-03** | 避雷针吸收雷击 | 放置避雷针后验证不被劈 |
| **RE-04** | 乌鸦袭击验证 | 无稻草人时测试乌鸦袭击 |

### 季节验收

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **SC-01** | 换季作物枯萎 | 非当季作物在新季节枯萎 |
| **SC-02** | 温室作物不受影响 | 温室作物换季继续生长 |
| **SC-03** | 果树年龄增长 | 新年验证果树年龄+1 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | C03 品质判定 | 验证品质概率分布 |
| **CS-02** | C01 体力消耗 | 验证操作消耗体力 |
| **CS-03** | F04 存档读档 | 验证完整存档 |

### 性能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **PC-01** | 每日更新 < 10ms | 16×16 地块测试 |
| **PC-02** | 收获操作 < 5ms | 单次收获测试 |

## Open Questions

| # | 问题 | 状态 | 负责人 | 目标日期 |
|---|------|------|--------|----------|
| **OQ-01** | 是否需要"一键收获"功能？玩家反馈收获太繁琐 | 待决定 | UX | v1.0 |
| **OQ-02** | 巨型作物形成是否需要更高概率？1%太低 | 待决定 | 策划 | v1.0 |
| **OQ-03** | 温室地块最大数量是多少？ | 待决定 | 策划 | v1.0 |
| **OQ-04** | 是否需要自动播种功能？ | 待决定 | UX | v1.0 |
| **OQ-05** | 果树是否需要砍伐后重新种植？ | 待决定 | 策划 | v1.0 |

## Visual/Audio Requirements

### 视觉需求
- 地块状态用不同颜色区分（荒地/已耕/生长中/可收获）
- 浇水状态显示水滴图标
- 虫害显示虫子图标
- 杂草显示草图标
- 巨型作物用特殊光效标识
- 果树显示生长阶段

### 音频需求
- 开垦音效：泥土声
- 浇水音效：水滴声
- 收获音效：收割声 + 金币声
- 虫害警报：特殊警告音

## UI Requirements

### 农场视图布局
- 网格显示所有地块
- 点击选择工具/操作
- 快捷工具栏
- 洒水器/稻草人/避雷针状态

### 工具栏
- 锄头：开垦
- 种子包：播种
- 浇水壶：浇水
- 肥料：施肥
- 镰刀：收获
- 铲子：铲除

### 每日提示
- 待浇水地块数量
- 可收获作物提示
- 虫害/杂草警告
