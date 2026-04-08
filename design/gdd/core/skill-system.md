# 技能系统 (Skill System)

> **状态**: In Design
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: C03
> **Implements Pillar**: 技能成长与角色扮演

## Overview

技能系统管理玩家的 5 项专业技能（农耕、采集、钓鱼、采矿、战斗），每项技能 10 级，通过执行相应活动获取经验值。升级提供通用加成（体力消耗减免）和专属加成（作物品质、矿石产量等）。达到 5 级和 10 级时，玩家可选天赋专精，获得强大的被动效果。系统是角色成长的核心，与玩家属性、成就、导航等多个系统交互。

## Player Fantasy

技能系统给玩家带来**成长的成就感和专业化的满足感**。玩家应该感受到：

- **积累的力量** — 每一次耕地、钓鱼、采矿都在让自己变得更强
- **选择的重量** — 5级/10级天赋的选择让人思考，不同路线带来不同体验
- **全面的发展** — 五个技能相互关联，农民也可以成为战斗高手
- **效率的提升** — 技能越高，体力消耗越少，能做的事情越多

**Reference games**: Stardew Valley 的技能简洁直观，Rune Factory 的天赋选择有深度。

## Detailed Design

### Core Rules

#### 1. 技能定义
5 种技能类型：`farming`(农耕)、`foraging`(采集)、`fishing`(钓鱼)、`mining`(采矿)、`combat`(战斗)

#### 2. 等级系统
- 每项技能 10 级（Lv0-Lv10）
- 初始 Lv0，经验达到阈值后升级
- Lv10 为满级，无法继续获取经验

#### 3. 经验获取
- 执行对应活动时调用 `addExp(type, amount)` 获取经验
- 戒指提供经验加成：`exp_bonus`
- 实际获得经验 = `floor(base_amount × (1 + exp_bonus))`

#### 4. 通用加成
- **体力消耗减免**: 每级减少 1%，Lv10 减免 10%
- 减免公式：`stamina_reduction = level × 0.01`

#### 5. 专属加成
| 技能 | 加成效果 |
|------|----------|
| 农耕 | 作物品质概率提升 |
| 采集 | 采集物品质概率提升 |
| 钓鱼 | 钓鱼成功率提升 |
| 采矿 | 矿石产出提升 |
| 战斗 | 生命值上限+5/级 |

#### 6. 天赋系统
- **Lv5 天赋**: 5级时可选择一个专精
- **Lv10 天赋**: 10级时可选择一个进阶专精
- 天赋一旦选择不可更改

#### 7. 天赋列表

**Lv5 天赋:**
| ID | 名称 | 效果 |
|----|------|------|
| `harvester` | 丰收者 | 作物售价+10% |
| `rancher` | 牧人 | 畜产品售价+20% |
| `lumberjack` | 樵夫 | 采集时25%概率额外获得木材 |
| `herbalist` | 药师 | 采集物发现概率+20% |
| `fisher` | 渔夫 | 鱼类售价+25% |
| `trapper` | 捕手 | 搏鱼成功率+15% |
| `miner` | 矿工 | 50%概率矿石+1 |
| `geologist` | 地质学家 | 稀有矿石概率大幅提升 |
| `fighter` | 斗士 | 受伤减少15%，生命上限+25 |
| `defender` | 守护者 | 防御时恢复5点生命 |

**Lv10 天赋:**
| ID | 名称 | 效果 |
|----|------|------|
| `intensive` | 精耕 | 20%概率双倍收获 |
| `artisan` | 匠人 | 加工品售价+25% |
| `coopmaster` | 牧场主 | 动物亲密度获取+50% |
| `shepherd` | 牧羊人 | 畜产品品质提升一级 |
| `forester` | 伐木工 | 采集时必定额外获得木材 |
| `tracker` | 追踪者 | 每次采集额外+1物品 |
| `botanist` | 植物学家 | 采集物品质必定为精品 |
| `alchemist` | 炼金师 | 食物恢复效果+50% |
| `angler` | 垂钓大师 | 传说鱼出现概率大幅提升 |
| `aquaculture` | 水产商 | 鱼类售价+50% |
| `mariner` | 水手 | 钓到的鱼品质至少为优质 |
| `luremaster` | 诱饵师 | 鱼饵效果翻倍 |
| `prospector` | 探矿者 | 15%概率矿石翻倍 |
| `blacksmith` | 铁匠 | 金属矿石售价+50% |
| `excavator` | 挖掘者 | 使用炸弹时30%概率不消耗 |
| `mineralogist` | 宝石学家 | 击败怪物额外掉落矿石 |
| `warrior` | 武者 | 生命上限+40 |
| `brute` | 蛮力者 | 攻击伤害+25% |
| `acrobat` | 杂技师 | 25%概率闪避并反击 |
| `tank` | 重甲者 | 防御时伤害减免70% |

### States and Transitions

#### 技能状态
| 状态 | 描述 | 条件 |
|------|------|------|
| **Leveling** | 经验累积中 | `exp < EXP_TABLE[level + 1]` |
| **Leveled** | 升级中 | `exp >= EXP_TABLE[level + 1]` 且 `level < 10` |
| **MaxLevel** | 满级 | `level == 10` |

#### 天赋状态
| 状态 | 描述 | 条件 |
|------|------|------|
| **NoPerk** | 无天赋 | 等级 < 5 或未选择天赋 |
| **Perk5Available** | 可选Lv5天赋 | `level >= 5` 且 `perk5 == null` |
| **Perk5Selected** | Lv5天赋已选 | `perk5 != null` |
| **Perk10Available** | 可选Lv10天赋 | `level >= 10` 且 `perk10 == null` |
| **Perk10Selected** | Lv10天赋已选 | `perk10 != null` |

**升级状态转换:**
```
Leveling → Leveled: addExp 导致 exp >= EXP_TABLE[level + 1]
Leveled → Leveling: 升级完成，重置为 Leveling (若 level < 10)
Leveled → MaxLevel: 达到 Lv10
```

**天赋状态转换:**
```
NoPerk → Perk5Available: 升级到 Lv5
Perk5Available → Perk5Selected: setPerk5(perk)
Perk5Selected → Perk10Available: 升级到 Lv10
Perk10Available → Perk10Selected: setPerk10(perk)
```

### Interactions with Other Systems

#### 上游依赖

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **F01 TimeSeasonSystem** | 软依赖 | 获取当前日期/季节（用于判断活动是否可做） |
| **C01 PlayerStatsSystem** | 软依赖 | 查询战斗等级计算HP，提供体力消耗减免接口 |
| **C08 EquipmentEffectSystem** | 软依赖 | 查询戒指 exp_bonus 经验加成 |

#### 下游依赖

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **C01 PlayerStatsSystem** | 硬依赖 | 查询 combat_level 计算 HP（HP_PER_COMBAT_LEVEL=5） |
| **P04 CookingSystem** | 软依赖 | 查询天赋效果（匠人/炼金师） |
| **P09 AchievementSystem** | 软依赖 | 监听 `skill_level_up` 信号触发成就 |
| **C04 FarmPlotSystem** | 硬依赖 | 查询农耕等级计算作物品质 |
| **P02 FishingSystem** | 硬依赖 | 查询钓鱼等级计算成功率 |
| **P03 MiningSystem** | 硬依赖 | 查询采矿等级计算矿石产出 |
| **P01 AnimalHusbandrySystem** | 软依赖 | 查询牧场主/牧羊人天赋效果 |

#### 关键接口契约

```gdscript
## 订阅的信号

# C08 EquipmentEffectSystem
signal exp_bonus_changed(new_bonus: float)

## 发出的信号

signal skill_level_up(skill_type: SkillType, new_level: int)
signal perk_selected(skill_type: SkillType, perk_id: String)
```

#### API 接口（提供给下游）

```gdscript
class_name SkillSystem extends Node

## 单例访问
static func get_instance() -> SkillSystem

## 技能查询
func get_skill_level(skill_type: SkillType) -> int
func get_skill_exp(skill_type: SkillType) -> int
func get_skill(skill_type: SkillType) -> SkillState

## 经验操作
func add_exp(skill_type: SkillType, base_amount: int) -> Dictionary:
    """增加经验，返回 {leveled_up: bool, new_level: int, old_level: int}"""

func get_exp_to_next_level(skill_type: SkillType) -> Dictionary:
    """返回 {current: int, required: int}，满级返回 null"""

## 体力减免
func get_stamina_reduction(skill_type: SkillType) -> float:
    """返回该技能对体力消耗的减免比例（每级1%，最高10%）"""

## 品质判定
func roll_crop_quality(quality_bonus: float = 0.0) -> Quality
func roll_forage_quality(level_bonus: int = 0) -> Quality

## 天赋操作
func set_perk_5(skill_type: SkillType, perk_id: SkillPerk5) -> bool
func set_perk_10(skill_type: SkillType, perk_id: SkillPerk10) -> bool
func get_perk_5(skill_type: SkillType) -> SkillPerk5
func get_perk_10(skill_type: SkillType) -> SkillPerk10

## 天赋效果查询
func has_perk(skill_type: SkillType, perk_id: String) -> bool
func get_perk_bonus(perk_id: String) -> Dictionary:
    """返回天赋效果的具体数值"""

## 存档接口
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

## Formulas

### 1. 经验表

```
EXP_TABLE = [0, 100, 380, 770, 1300, 2150, 3300, 4800, 6900, 10000, 15000]
# index = 目标等级
# 例如: Lv0→1 需要 100 EXP, Lv1→2 需要 280 EXP (380-100)
```

| 等级 | 累计经验 | 升到下一级所需 |
|------|----------|----------------|
| 0 | 0 | 100 |
| 1 | 100 | 280 |
| 2 | 380 | 390 |
| 3 | 770 | 530 |
| 4 | 1300 | 850 |
| 5 | 2150 | 1150 |
| 6 | 3300 | 1500 |
| 7 | 4800 | 2100 |
| 8 | 6900 | 3100 |
| 9 | 10000 | 5000 |
| 10 | 15000 | MAX |

### 2. 实际获得经验

```
adjusted_exp = floor(base_exp × (1 + exp_bonus))
# exp_bonus 由 C08 EquipmentEffectSystem 提供（戒指效果）
```

### 3. 体力消耗减免

```
stamina_reduction = level × 0.01
# Lv1: 1%, Lv5: 5%, Lv10: 10%
# 减免后消耗 = base_stamina × (1 - stamina_reduction)
```

### 4. 作物品质判定

```
roll = random()
quality_bonus = 来自肥料或其他加成

if level >= 9 and roll < 0.05 + quality_bonus × 0.5:
    return SUPREME (紫色)
elif level >= 6 and roll < 0.15 + quality_bonus:
    return EXCELLENT (蓝色)
elif level >= 3 and roll < 0.3 + quality_bonus:
    return FINE (绿色)
else:
    return NORMAL (白色)
```

### 5. 采集物品品质判定

```
roll = random()
level_bonus = 来自其他加成

# 如果有 botanist 天赋，必定为 EXCELLENT
if perk10 == 'botanist':
    return EXCELLENT

if level + level_bonus >= 9 and roll < 0.05:
    return SUPREME
elif level + level_bonus >= 6 and roll < 0.12:
    return EXCELLENT
elif level + level_bonus >= 3 and roll < 0.25:
    return FINE
else:
    return NORMAL
```

### 6. 战斗等级 HP 加成

```
combat_hp_bonus = combat_level × HP_PER_COMBAT_LEVEL  # 5
# C01 使用此值计算 max_hp
```

### 7. 天赋效果数值

```gdscript
# 斗士 (fighter)
fighter_hp_bonus = 25
fighter_damage_reduction = 0.15

# 武者 (warrior)
warrior_hp_bonus = 40

# 蛮力者 (brute)
brute_damage_bonus = 0.25

# 杂技师 (acrobat)
acrobat_dodge_chance = 0.25
acrobat_counter_chance = 0.25

# 重甲者 (tank)
tank_damage_reduction = 0.70
tank_hp_regen = 5  # 防御时恢复5点HP
```

## Edge Cases

### 1. 满级后继续获取经验
- **场景**: Lv10 后调用 addExp
- **处理**: 经验值不增加，返回 `{leveled_up: false}`

### 2. 天赋选择时等级不足
- **场景**: `setPerk5(type, perk)` 但 `level < 5`
- **处理**: 返回 false，不进行任何操作

### 3. 重复选择天赋
- **场景**: `setPerk5(type, perk)` 但 `perk5 != null`
- **处理**: 返回 false，天赋不可重复选择

### 4. 经验刚好达到升级阈值
- **场景**: `addExp` 后 `exp == EXP_TABLE[level + 1]`
- **处理**: 正常升级，触发 `skill_level_up` 信号

### 5. 一次获得大量经验（可升多级）
- **场景**: `addExp(type, 5000)` 从 Lv0 开始
- **处理**: 循环检查并升级到最高可达等级，逐级触发信号

### 6. 旧存档缺少 combat 技能
- **场景**: v1.0 存档加载到 v1.1（新增 combat 技能）
- **处理**: 创建新的 combat 技能，Lv0，无天赋

### 7. 天赋效果冲突
- **场景**: 多个来源提供相同类型加成
- **处理**: 取最大值（如果已有 botanist，再获得也不会提高）

### 8. 技能数据损坏
- **场景**: 存档中 skill.exp < 0 或 skill.level > 10
- **处理**: 修复为合法值（exp >= 0, level = clamp(level, 0, 10)）

### 9. 经验加成为负数
- **场景**: `exp_bonus < 0`（理论上不可能，但需防护）
- **处理**: 最低为 0，即 `max(0, exp_bonus)`

### 10. 天赋效果与装备效果叠加
- **场景**: 斗士天赋 (+25 HP) + 特定戒指 (+20 HP)
- **处理**: C01 分别计算后叠加

## Dependencies

### 上游依赖（C03 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F01** | TimeSeasonSystem | 软依赖 | 获取日期/季节 |
| **C01** | PlayerStatsSystem | 软依赖 | 查询战斗等级，体力减免 |
| **C08** | EquipmentEffectSystem | 软依赖 | 查询 exp_bonus |

### 下游依赖（其他系统依赖 C03）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **C01** | PlayerStatsSystem | 硬依赖 | combat_level 影响 HP |
| **C04** | FarmPlotSystem | 硬依赖 | 农耕等级影响作物品质 |
| **P02** | FishingSystem | 硬依赖 | 钓鱼等级影响成功率 |
| **P03** | MiningSystem | 硬依赖 | 采矿等级影响产出 |
| **P04** | CookingSystem | 软依赖 | 天赋效果影响加工 |
| **P09** | AchievementSystem | 软依赖 | 技能升级触发成就 |
| **P01** | AnimalHusbandrySystem | 软依赖 | 天赋效果影响畜牧 |

## Tuning Knobs

### 经验系统配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `EXP_TABLE` | [0,100,380,...] | - | 经验阈值表，共11项 |
| `MAX_LEVEL` | 10 | 固定 | 最高等级 |
| `PER_LEVEL_STAMINA_REDUCTION` | 0.01 | 0.005-0.02 | 每级体力减免 |

### 战斗技能配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `HP_PER_COMBAT_LEVEL` | 5 | 1-10 | 每级 HP 加成 |
| `FIGHTER_HP_BONUS` | 25 | 10-50 | 斗士天赋 HP |
| `FIGHTER_DAMAGE_REDUCTION` | 0.15 | 0.1-0.3 | 斗士伤害减免 |
| `WARRIOR_HP_BONUS` | 40 | 20-80 | 武者天赋 HP |
| `BRUTE_DAMAGE_BONUS` | 0.25 | 0.1-0.5 | 蛮力者伤害加成 |
| `ACROBAT_DODGE_CHANCE` | 0.25 | 0.1-0.4 | 杂技师闪避概率 |
| `TANK_DAMAGE_REDUCTION` | 0.70 | 0.5-0.9 | 重甲者伤害减免 |
| `TANK_HP_REGEN` | 5 | 1-20 | 重甲者防御回血 |

### 品质判定配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `CROP_LV3_FINE_CHANCE` | 0.3 | 0.2-0.5 | 3级 Fine 概率 |
| `CROP_LV6_EXCELLENT_CHANCE` | 0.15 | 0.1-0.3 | 6级 Excellent 概率 |
| `CROP_LV9_SUPREME_CHANCE` | 0.05 | 0.02-0.1 | 9级 Supreme 概率 |
| `FORAGE_LV3_FINE_CHANCE` | 0.25 | 0.15-0.4 | 3级 Fine 概率 |
| `FORAGE_LV6_EXCELLENT_CHANCE` | 0.12 | 0.05-0.2 | 6级 Excellent 概率 |

### 调试配置

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `DEBUG_INSTANT_LEVEL_UP` | false | 添加经验时立即升级 |
| `DEBUG_UNLOCK_ALL_PERKS` | false | 解锁所有天赋 |
| `DEBUG_MAX_SKILLS` | false | 所有技能设为 Lv10 |

## Visual/Audio Requirements

### 视觉需求
- 技能图标：5 个技能各一个独特图标
- 经验条：平滑动画升级效果
- 天赋框：Lv5/Lv10 特殊边框高亮
- 升级特效：升级时播放粒子/闪光效果

### 音频需求
- 升级音效：每个技能升级时播放独特的提升音效
- 天赋选择音效：确认天赋时播放特殊音效
- 经验获取提示音（可选）：大量经验获取时播放

## UI Requirements

### 技能面板布局
- 5 个技能垂直排列（也可选择网格布局）
- 每个技能卡片包含：
  - 技能图标 + 名称 + 当前等级
  - 经验条（当前经验 / 升级所需）
  - 简要加成说明（体力减免 + 技能加成）
  - 天赋选择区域（Lv5/Lv10 可点击）

### 天赋选择对话框
- 天赋列表显示：图标 + 名称 + 效果描述
- 悬停预览：鼠标悬停显示详细效果数值
- 确认/取消按钮
- 警告提示："天赋选择后不可更改"

### 升级提示
- 升级时弹出提示：技能图标 + "Lv.X!" + 新天赋可用提示
- 经验条动画：从当前位置平滑填充到 100%
- 音效配合视觉特效

### 交互流程
1. 点击技能卡片 → 显示详细信息
2. 达到 Lv5/Lv10 → 技能卡片高亮提示
3. 点击"选择天赋" → 弹出天赋选择对话框
4. 确认选择 → 天赋生效，卡片更新

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 5 个技能正确初始化 | 游戏开始时验证所有技能为 Lv0 |
| **AC-02** | 经验累积正确 | addExp 验证经验值增加 |
| **AC-03** | 升级触发正确 | addExp 达到阈值触发 `skill_level_up` 信号 |
| **AC-04** | 满级后不再升级 | Lv10 后 addExp 不触发升级 |
| **AC-05** | 天赋选择正确 | setPerk5/10 验证天赋保存 |
| **AC-06** | 天赋等级限制 | Lv<5 时 setPerk5 返回 false |
| **AC-07** | 天赋不可重复 | 已选天赋再次选择返回 false |
| **AC-08** | 体力减免正确 | 验证 Lv10 时减免 10% |

### 品质判定验收

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **QC-01** | 作物品质分布正确 | 多次 roll，验证概率分布 |
| **QC-02** | 采集品质分布正确 | 多次 roll，验证概率分布 |
| **QC-03** | botanist 天赋必定出精品 | 验证 100% EXCELLENT |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | C01 HP 计算正确 | 战斗 Lv5 时 HP 应为 100+25 |
| **CS-02** | 戒指经验加成 | 装备 exp_bonus 戒指后验证加成 |
| **CS-03** | 存档/读档 | serialize/deserialize 验证完整 |

### 边界情况测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **BC-01** | 负数经验加成 | 设置 exp_bonus=-0.5 验证不生效 |
| **BC-02** | 数据损坏修复 | 加载损坏存档验证自动修复 |
| **BC-03** | 多级连升 | addExp(10000) 从 Lv0 验证升到 Lv9 |

### 性能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **PC-01** | addExp < 1ms | 1000 次调用测试 |
| **PC-02** | serialize < 5ms | 存档序列化测试 |

## Open Questions

| # | 问题 | 状态 | 负责人 | 目标日期 |
|---|------|------|--------|----------|
| **OQ-01** | 是否需要天赋重置道具？选错天赋会导致体验不佳 | 待决定 | 策划 | v1.0 |
| **OQ-02** | 战斗天赋（fighter/warrior/brute/acrobat/tank）的伤害减免如何与 C08 装备系统叠加？ | 待决定 | 策划/技术 | v1.0 |
| **OQ-03** | 天赋预览功能：选择天赋前是否需要预览效果？ | 待决定 | UX | v1.0 |
| **OQ-04** | 是否需要"遗忘技能"机制，将经验返还用于其他技能？ | 待决定 | 策划 | v1.1 |
| **OQ-05** | 钓鱼/采矿小游戏是否需要基于技能等级调整难度？ | 待决定 | 策划 | v1.0 |
