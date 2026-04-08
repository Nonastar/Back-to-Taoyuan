# 鱼塘系统 (Fish Pond System)

> **Status**: Approved
> **Author**: Claude + User
> **Last Updated**: 2026-04-07
> **Implements Pillar**: 角色养成与自定义化

## Overview

鱼塘系统是游戏中的水产养殖系统，支持13种鱼的养殖、繁殖和品种培育。系统包含鱼塘建造升级、水质管理、每日产出、疾病系统、遗传育种和400个鱼类品种图鉴。玩家通过养殖鱼类获得稳定产出，通过繁殖创造新品种，最终收集所有400个鱼类品种。

## Player Fantasy

鱼塘系统给玩家带来**水族馆主人的满足感**。玩家应该感受到：

- **收获的快乐** — 每天收取鱼塘产出的期待感
- **照顾的责任** — 记得喂鱼、保持水质清洁的日常义务
- **育种的惊喜** — 通过繁殖创造新品种的兴奋
- **收集的乐趣** — 收集全部400个品种的终极挑战

**Reference games**: Stardew Valley 的鱼塘；Pokemon 的收集系统。

## Detailed Design

### Core Rules

#### 1. 可养殖鱼种 (Pondable Fish)

游戏支持13种可养殖鱼类：

| 分类 | 鱼类 | 成熟天数 | 产出概率 | 特点 |
|------|------|----------|----------|------|
| 溪流 | 鲫鱼、鲤鱼、草鱼 | 3-5天 | 30-40% | 快速成熟 |
| 池塘 | 金鲤、锦鲤、乌龟 | 6-8天 | 15-25% | 高价值 |
| 江河 | 鲈鱼、鲶鱼、黄鳝 | 5-6天 | 25-30% | 均衡 |
| 瀑布 | 虹鳟 | 6天 | 25% | 中等 |
| 沼泽 | 沼泽泥鳅、田螺 | 2-3天 | 40-50% | 极高产出 |
| 矿洞 | 洞穴盲鱼 | 8天 | 15% | 高变异 |

#### 2. 鱼塘建造与升级

**建造费用**：
```
money: 5000
materials: 木材×100, 竹子×50
```

**升级配置**：

| 等级 | 容量 | 费用 |
|------|------|------|
| 1 | 5条 | 建造 |
| 2 | 10条 | 10000g + 木材×100 + 铁锭×5 |
| 3 | 20条 | 25000g + 木材×200 + 金锭×5 + 铁锭×10 |

#### 3. 水质系统 (Water Quality)

水质是鱼塘健康的核心指标：

**水质衰减**：
```
base_decay = 2  # 每天基础衰减
if density > 80%: decay += 3  # 拥挤
elif density > 50%: decay += 2  # 半满
if not_fed_today: decay += 5  # 未喂食
```

**水质恢复**：
| 方式 | 恢复量 |
|------|--------|
| 喂食鱼饵 | +10 |
| 使用水质改良剂 | +30 |

**水质影响**：
- 水质 < 30：开始有生病概率
- 水质 = 0：最大生病概率

#### 4. 每日管理

**喂食**：
- 每天需喂食一次鱼饵
- 未喂食：水质量衰减加快，产出概率降低

**清理/治疗**：
- 使用水质改良剂提升水质
- 使用动物药治疗病鱼

#### 5. 疾病系统

**生病判定**：
```
if water_quality < DISEASE_THRESHOLD(30):
    resist = disease_res / 100
    chance = DISEASE_CHANCE_BASE(0.05) * (1 - resist) / (1 + fishing_level * 0.05)
    if random() < chance:
        fish.sick = true
```

**死亡机制**：
- 连续生病 5 天后死亡
- 死亡鱼被移除

**自愈机制**：
- 已喂食 + 水质 >= 30：自动痊愈

#### 6. 产出系统

**产出条件**：
1. 鱼已成熟
2. 已喂食
3. 未生病

**产出计算**：
```
# 基础产出概率
rate = fish.base_production_rate

# 体重基因加成
weight_bonus = genetics.weight / 200
effective_rate = rate + weight_bonus

if random() < effective_rate:
    product = fish.product_item_id
    quality = roll_quality(genetics.quality_gene)
```

**品质判定**：
```
roll = random() * 100
if quality_gene >= 75 and roll < quality_gene - 50: return supreme
if quality_gene >= 50 and roll < quality_gene - 25: return excellent
if quality_gene >= 25 and roll < quality_gene: return fine
return normal
```

#### 7. 基因属性

每条鱼有5个基因属性（0-100）：

| 属性 | 效果 |
|------|------|
| **体重 (Weight)** | 影响产出概率加成 |
| **生长率 (Growth Rate)** | 影响成熟速度 |
| **抗病性 (Disease Res)** | 降低生病概率 |
| **品质基因 (Quality Gene)** | 影响产出品质 |
| **变异率 (Mutation Rate)** | 影响后代变异幅度 |

#### 8. 繁殖系统

**繁殖条件**：
1. 两条成熟鱼
2. 两条鱼同类（同 fishId）
3. 两条鱼都未生病
4. 鱼塘未满

**繁殖周期**：3天

**繁殖结果**：
- 匹配品种配方：产出高代品种
- 无匹配：继承父母同代品种

#### 9. 品种系统 (400品种)

**品种代数分布**：

| 代数 | 数量 | 命名前缀 |
|------|------|----------|
| Gen 1 | 200 | 银、金、赤、花、墨、翡、月、霜、星、云、玉、碧、雪、绯、焰、岚 |
| Gen 2 | 100 | 灵、仙、瑶、幻、梦、神、圣、天 |
| Gen 3 | 50 | 琼光、瑶华、灵境、仙域 |
| Gen 4 | 30 | 太古、鸿蒙、混沌 |
| Gen 5 | 20 | 化龙、浴火 |

**品种命名规则**：`[前缀][鱼种后缀]`
- 例：金鲫、仙鲤、太古虹鳟

### States and Transitions

#### 鱼塘状态

| 状态 | 描述 |
|------|------|
| **NotBuilt** | 未建造 |
| **Built** | 已建造 |

#### 鱼状态

| 状态 | 描述 |
|------|------|
| **Immature** | 未成熟 |
| **Mature** | 已成熟 |
| **Sick** | 生病中 |
| **Dead** | 死亡（移除） |

#### 繁殖状态

| 状态 | 描述 |
|------|------|
| **Idle** | 无繁殖 |
| **Breeding** | 繁殖中（3天） |

### Interactions with Other Systems

#### 依赖系统 (Upstream Dependencies)

| System | Interface | Usage |
|--------|-----------|-------|
| C02 库存系统 | items | 鱼饵、改良剂、动物药 |
| C03 技能系统 | fishing_level | 疾病概率计算 |
| P02 钓鱼系统 | fish sources | 可养殖鱼来源 |
| P09 成就系统 | breeding events | 育种相关成就 |

#### 事件订阅 (Event Subscriptions)

```gdscript
# 鱼塘系统发出
signal fish_added(count: int)
signal fish_removed(fish_name: String)
signal fish_died(fish_name: String)
signal fish_bred(breed_name: String)
signal product_collected(item_id: String, quality: String)
signal water_quality_changed(new_value: int)
```

#### API 接口

```gdscript
class_name FishPondSystem extends Node

## 建造/升级
func build_pond() -> bool
func upgrade_pond() -> bool
func can_build() -> bool
func can_upgrade() -> bool

## 鱼管理
func add_fish(fish_id: String, quantity: int) -> int
func remove_fish(pond_fish_id: String) -> bool
func get_fish_list() -> Array
func get_capacity() -> int
func get_fish_count() -> int

## 维护
func feed_fish() -> bool
func clean_pond() -> bool
func treat_sick_fish() -> int
func get_water_quality() -> int

## 繁殖
func start_breeding(fish_id_a: String, fish_id_b: String) -> bool
func get_breeding_status() -> Dictionary

## 收获
func collect_products() -> Array
func get_pending_products() -> Array

## 每日更新
func daily_update() -> PondDailyResult

## 图鉴
func get_discovered_breeds() -> Array
func get_discovered_count() -> int

## 存档
func serialize() -> Dictionary
func deserialize(data: Dictionary)
```

## Formulas

### 1. 水质衰减

```
daily_decay = BASE_DECAY(2)
  + (density > 0.8 ? CROWDED_DECAY(3) : 0)
  + (density > 0.5 ? HALF_DECAY(2) : 0)
  + (not fed today ? HUNGRY_DECAY(5) : 0)

new_quality = clamp(old_quality - daily_decay, 0, 100)
```

### 2. 生病概率

```
resistance_factor = fish.disease_res / 100
fishing_bonus = 1 + skill_level * 0.05

chance = BASE_DISEASE_CHANCE(0.05) * (1 - resistance_factor) / fishing_bonus
```

### 3. 成熟天数

```
effective_days = base_maturity_days * (1 - growth_rate_bonus * 0.3)
where growth_rate_bonus = genetics.growth_rate / 100
```

### 4. 产出判定

```
production_rate = base_rate + (genetics.weight / 200)
if random() < production_rate:
    return generate_product(quality_gene)
```

### 5. 品种星级

```
total = weight + growth_rate + disease_res + quality_gene
return 5 if total >= 320
     4 if total >= 260
     3 if total >= 200
     2 if total >= 140
     1 otherwise
```

## Edge Cases

### 1. 鱼塘边界

- **鱼塘已满**：不能放入更多鱼
- **鱼塘未建**：所有鱼操作返回失败

### 2. 鱼管理边界

- **放入非可养殖鱼**：返回失败
- **取出正在繁殖的亲鱼**：取消繁殖

### 3. 疾病边界

- **多只鱼同时生病**：全部记录并可治疗
- **治疗时无病鱼**：返回0
- **连续生病致死**：移除并记录日志

### 4. 繁殖边界

- **繁殖中亲鱼死亡**：繁殖取消
- **繁殖完成时鱼塘满**：繁殖失败
- **无匹配品种配方**：继承父母同代品种

## Dependencies

| ID | System Name | Type | Interface |
|----|-------------|------|-----------|
| D01 | C02 InventorySystem | Hard | fish items, feed, medicine |
| D02 | C03 SkillSystem | Soft | fishing_level for disease |
| D03 | P02 FishingSystem | Soft | fish sources |
| D04 | P09 AchievementSystem | Soft | breeding events |

## Tuning Knobs

### 水质参数

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `WATER_QUALITY_DECAY_BASE` | 2 | 1-5 | 基础衰减 |
| `WATER_QUALITY_DECAY_CROWDED` | 3 | 2-6 | 拥挤额外衰减 |
| `WATER_QUALITY_DECAY_HALF` | 2 | 1-4 | 半满额外衰减 |
| `WATER_QUALITY_DECAY_HUNGRY` | 5 | 3-10 | 未喂食额外衰减 |
| `DISEASE_THRESHOLD` | 30 | 20-50 | 生病阈值 |
| `DISEASE_CHANCE_BASE` | 0.05 | 0.02-0.1 | 基础生病概率 |
| `SICK_DEATH_DAYS` | 5 | 3-7 | 致死天数 |

### 产出参数

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `FEED_WATER_RESTORE` | 10 | 5-20 | 喂食恢复 |
| `PURIFIER_WATER_RESTORE` | 30 | 20-50 | 改良剂恢复 |
| `FISH_BREEDING_DAYS` | 3 | 2-5 | 繁殖周期 |

### 容量参数

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `POND_CAPACITY_1` | 5 | 3-8 | 等级1容量 |
| `POND_CAPACITY_2` | 10 | 8-15 | 等级2容量 |
| `POND_CAPACITY_3` | 20 | 15-30 | 等级3容量 |

## Visual/Audio Requirements

### UI Requirements

| Screen | Component | Description |
|--------|-----------|-------------|
| 鱼塘界面 | FishPondView | 主界面，显示鱼塘和鱼 |
| 鱼列表面板 | FishListPanel | 塘中鱼类列表 |
| 产出面板 | ProductPanel | 待收取产出 |
| 繁殖面板 | BreedingPanel | 繁殖操作 |
| 图鉴面板 | BreedCompendium | 已发现品种 |

### Visual Feedback

- 水质用颜色指示：绿色(100-60)、黄色(60-30)、红色(30-0)
- 病鱼显示特殊图标
- 繁殖中显示倒计时
- 新品种发现时特殊动画

### Audio Feedback

- 放入/取出鱼音效
- 喂食音效
- 产出收获音效
- 新品种发现音效

## Acceptance Criteria

### Functional Criteria

- [ ] 鱼塘建造和升级功能正常
- [ ] 13种鱼正确养殖
- [ ] 水质衰减和恢复正确
- [ ] 疾病和死亡机制正确
- [ ] 每日产出正确计算
- [ ] 繁殖系统正确工作
- [ ] 400品种图鉴正确追踪
- [ ] 存档/读档状态正确保存恢复

### Performance Criteria

- [ ] 鱼塘操作响应时间 < 5ms
- [ ] 每日更新处理 < 10ms
- [ ] 图鉴查询 < 10ms

### Compatibility Criteria

- [ ] 与库存系统的物品管理集成
- [ ] 与技能系统的钓鱼等级集成
- [ ] 与成就系统的育种成就集成

## Open Questions

| ID | Question | Owner | Target Date |
|----|----------|-------|-------------|
| O1 | 是否需要特殊的传说鱼种？ | Designer | Pre-MVP |
| O2 | 鱼塘是否需要装饰外观？ | Art | Pre-MVP |
| O3 | 图鉴收集是否有奖励？ | Designer | Pre-MVP |
