# 采矿系统 (Mining System)

> **状态**: Approved
> **Author**: Claude Code
> **Last Updated**: 2026-04-07
> **System ID**: P03
> **Implements Pillar**: 农场经营与农业系统

## Overview

采矿系统为玩家提供深入矿洞探险的玩法。系统包含120层深的矿洞，分为6个不同的矿石区域，每层有不同的矿石分布和敌人遭遇。玩家使用镐子挖掘矿石获取资源，同时面对矿洞中的怪物战斗。达到特定层数时会遇到Boss怪物，击败Boss可获得稀有材料。采矿系统是游戏后期重要的收入来源，同时连接公会系统（P10）进行贡献点兑换。

## Player Fantasy

采矿系统给玩家带来**冒险探索与财富积累的刺激感**。玩家应该感受到：

- **深入未知的期待** — 每下一层都是新的挑战，不知道会遇到什么矿石或怪物
- **财富的积累** — 背包越来越重，金币越来越多，满载而归的满足感
- **战斗的紧张** — 矿洞中的怪物需要应对，合理使用武器和走位
- **Boss 的挑战** — 击败强大的 Boss，获得珍贵材料时的成就感

**Reference games**: Stardew Valley 的矿洞简单但有深度；Terraria 的挖矿和战斗结合紧密。

## Detailed Design

### Core Rules

#### 1. 矿洞结构（6个区域）

| 区域 | 层数范围 | 主要矿石 | 敌人类型 | 特殊 |
|------|----------|----------|----------|------|
| **铜矿区** | 1-20 | 铜矿、锡矿、煤炭 | 史莱姆、小蝙蝠 | 初始区域 |
| **铁矿区** | 21-40 | 铁矿、铅矿、金矿 | 骷髅、蝙蝠群 | 需要铁镐 |
| **铱矿区** | 41-60 | 铱矿、宝石、黄金 | 幽灵、矿虫 | 需要钢镐 |
| **水晶矿区** | 61-80 | 水晶、紫水晶、蓝宝石 | 石头人、蝙蝠王 | 矿物密集 |
| **熔岩矿区** | 81-100 | 熔岩石、黑曜石、钻石 | 火焰史莱姆、熔岩怪 | 需要铱镐 |
| **虚空矿区** | 101-120 | 虚空矿石、神秘水晶 | 虚空生物、守护者 | 最终区域 |

#### 2. 矿石分布

每层矿石分布遵循以下规律：
- **基础矿物**: 每层必定出现
- **区域矿物**: 根据区域概率出现
- **稀有矿物**: 根据层数概率递增
- **宝石**: 低概率随机出现

#### 3. 工具系统

| 工具 | 可采矿层 | 耐久度 | 挖掘速度 | 额外效果 |
|------|----------|--------|----------|----------|
| **石镐** | 1-20 | 50 | 基础 | - |
| **铜镐** | 1-40 | 80 | +10% | - |
| **铁镐** | 1-80 | 120 | +20% | - |
| **钢镐** | 1-120 | 200 | +35% | 范围+1 |
| **铱镐** | 1-120 | 500 | +50% | 全区域 |

> **注**: 低等级工具可以挖掘高区域矿石，但速度极慢（×3时间）。高等级工具可解锁虚空矿区等特殊区域。

#### 4. 矿石品质判定

矿石品质由以下因素决定：
- 采矿技能等级 (C03)
- 工具等级
- 矿物稀有度
- 天赋加成 (miner +1, geologist 稀有提升, prospector 双倍)

#### 5. 敌人系统

**普通敌人**:
- 史莱姆、骷髅、蝙蝠、幽灵等
- 击败后可能掉落矿石或道具

**Boss 敌人**:
| Boss | 出现层数 | HP | 掉落 |
|------|----------|-----|------|
| **石头巨人** | 20 | 100 | 精炼石 ×5 |
| **蝙蝠王** | 40 | 200 | 翅膀 ×3 |
| **幽灵领主** | 60 | 350 | 灵魂石 ×3 |
| **火焰巨龙** | 80 | 500 | 龙鳞 ×5 |
| **虚空守卫** | 100 | 800 | 虚空核心 ×3 |
| **矿洞之主** | 120 | 1500 | 传说矿石 ×10 |

#### 6. 战斗机制

采矿战斗复用 C08 WeaponEquipmentSystem：
- 使用当前装备的武器战斗
- 武器攻击消耗体力
- 击败敌人获得经验 (C03 SkillSystem)

#### 7. 矿洞进度

- **电梯系统**: 每20层有一个电梯，可快速上下
- **传送羽毛**: 一次性道具，可从任意层返回地面
- **每日重置**: 每天进入矿洞时，所有敌人刷新

### States and Transitions

#### 矿洞状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **OnSurface** | 地面 | 未进入矿洞 |
| **InMine** | 矿洞中 | 正常挖矿状态 |
| **InCombat** | 战斗中 | 遭遇敌人 |
| **InBossRoom** | Boss 房 | 进入 Boss 房间 |
| **Victory** | 胜利 | 击败 Boss |
| **Defeated** | 失败 | HP 归零 |

**状态转换图**:
```
OnSurface → InMine: 进入矿洞
InMine → InCombat: 遭遇敌人
InCombat → InMine: 击败敌人或逃跑
InMine → InBossRoom: 进入 Boss 房间
InBossRoom → Victory: 击败 Boss
InBossRoom → InMine: 逃跑（损失部分矿石）
Victory → InMine: 继续挖矿
InMine → OnSurface: 使用电梯/羽毛/时间到
InMine → Defeated: HP 归零，自动返回地面
```

#### 矿石状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **Available** | 可挖掘 | 矿石存在 |
| **BeingMined** | 挖掘中 | 正在消耗耐久 |
| **Depleted** | 已采尽 | 矿石消失 |
| **TooHard** | 太硬 | 工具等级不足 |

### Interactions with Other Systems

**上游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **C02 InventorySystem** | 硬依赖 | 矿石存入背包、消耗工具耐久 |
| **C08 WeaponEquipmentSystem** | 硬依赖 | 武器战斗、攻击计算 |
| **F03 ItemDataSystem** | 硬依赖 | 矿石定义、敌人定义、工具定义 |
| **C01 PlayerStatsSystem** | 硬依赖 | HP、体力消耗 |
| **C03 SkillSystem** | 硬依赖 | 采矿技能等级、战斗经验 |

**下游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **P10 GuildSystem** | 软依赖 | 矿石兑换贡献点 |
| **P11 MuseumSystem** | 软依赖 | 矿石/宝石捐赠 |
| **F01 SaveLoadSystem** | 硬依赖 | 采矿数据保存/加载 |

### 提供给下游的 API

```gdscript
class_name MiningSystem extends Node

## 单例访问
static func get_instance() -> MiningSystem

## 矿洞操作
func enter_mine() -> bool:
    """进入矿洞，返回是否成功"""

func descend_floor() -> bool:
    """下降一层"""

func ascend_floor() -> bool:
    """上升一层（如果有楼梯）"""

func use_elevator(floor: int) -> bool:
    """使用电梯到达指定层（20的倍数）"""

## 挖掘操作
func mine_tile(x: int, y: int) -> Dictionary:
    """挖掘矿石，返回 {success, item_id, quality, durability_used}"""

func repair_pickaxe() -> bool:
    """修复镐子耐久"""

## 战斗操作
func engage_enemy(enemy_id: String) -> bool:
    """与敌人战斗"""

func attack_enemy() -> Dictionary:
    """攻击敌人，返回 {damage, crit, defeated}"""

func take_damage(amount: int) -> void:
    """受到敌人攻击"""

func flee_combat() -> bool:
    """尝试逃跑，返回是否成功"""

## Boss 操作
func enter_boss_room() -> bool:
    """进入 Boss 房间"""

func defeat_boss() -> Array:
    """击败 Boss，返回掉落物品列表"""

## 查询
func get_current_floor() -> int:
    """获取当前层数"""

func get_tile_info(x: int, y: int) -> Dictionary:
    """获取矿石/敌人信息"""

func get_pickaxe_durability() -> int:
    """获取当前镐子耐久度"""

func get_enemies_on_floor() -> Array:
    """获取当前层敌人列表"""

func get_available_minerals() -> Array:
    """获取当前层可挖掘矿物"""
```

## Formulas

### 1. 矿石品质判定公式

```
# 基础高品质概率
base_quality_chance = 0.05  # 5%

# 技能加成 (C03)
skill_bonus = mining_skill_level * 0.01

# 工具等级加成
tool_bonus = {
    "stone": 0.0,
    "copper": 0.02,
    "iron": 0.05,
    "steel": 0.08,
    "iridium": 0.12
}

# 天赋加成 (C03 SkillSystem)
if has_talent("geologist"):
    rare_chance *= 2  # 稀有矿物概率翻倍

# 最终高品质概率
final_quality_chance = base_quality_chance + skill_bonus + tool_bonus
```

### 2. 矿石数量公式 (含 Miner/Prospector 天赋)

```
# 基础产出数量
base_quantity = mineral.base_quantity  # 1

# Miner 天赋: 50%概率额外获得1个
if has_talent("miner"):
    if random() < 0.5:
        base_quantity += 1

# Prospector 天赋: 15%概率双倍
if has_talent("prospector"):
    if random() < 0.15:
        base_quantity *= 2

final_quantity = base_quantity
```

### 3. 挖掘时间公式

```
# 基础挖掘时间（秒）
base_mine_time = mineral.hardness * 0.5

# 工具速度加成
tool_speed = {
    "stone": 1.0,
    "copper": 0.9,
    "iron": 0.8,
    "steel": 0.65,
    "iridium": 0.5
}

# 技能加成
skill_reduction = 1.0 - (mining_skill_level * 0.02)

# 最终挖掘时间
final_mine_time = base_mine_time * tool_speed * skill_reduction
```

### 4. 耐久度消耗公式

```
# 基础耐久度消耗
base_durability_cost = 1

# 矿石硬度加成
hardness_multiplier = mineral.hardness / 10.0

# 工具效率加成
tool_efficiency = {
    "stone": 1.0,
    "copper": 0.9,
    "iron": 0.8,
    "steel": 0.7,
    "iridium": 0.5
}

# 最终耐久消耗
final_cost = max(1, floor(base_durability_cost * hardness_multiplier * tool_efficiency))
```

### 5. 敌人遭遇公式

```
# 每层基础遭遇率
base_encounter_chance = 0.30

# 层数加成
floor_bonus = (current_floor / 100) * 0.1

# 最终遭遇率
final_encounter_chance = base_encounter_chance + floor_bonus
final_encounter_chance = clamp(final_encounter_chance, 0.20, 0.60)
```

### 6. 战斗伤害公式

复用 C08 WeaponEquipmentSystem：

```
# 基础伤害 (来自 C08)
base_damage = weapon.attack

# 采矿技能加成 (C03)
skill_bonus = mining_skill_level * 0.5

# 暴击判定
crit_roll = random(0.0, 1.0)
is_crit = crit_roll < weapon.crit_rate + skill_crit_bonus
crit_multiplier = 2.0 if is_crit else 1.0

# 最终伤害
final_damage = floor((base_damage + skill_bonus) * crit_multiplier)
```

### 7. 逃跑成功率公式

```
# 基础逃跑率
base_flee_chance = 0.50

# 速度加成 (来自装备 C08)
speed_bonus = get_equipment_speed() * 0.01

# 敌人阻挡惩罚
enemy_blocked = has_enemy_blocking_escape()
blocked_penalty = -0.20 if enemy_blocked else 0

# 最终逃跑率
final_flee_chance = base_flee_chance + speed_bonus + blocked_penalty
final_flee_chance = clamp(final_flee_chance, 0.20, 0.80)
```

### 8. 矿石价值公式

```
# 基础价值 (来自 F03)
base_value = mineral.base_value

# 品质加成
quality_multiplier = {
    "normal": 1.0,
    "fine": 1.5,
    "excellent": 2.0,
    "supreme": 3.0
}

# 工具额外加成 (稀有工具挖出更高价值)
tool_value_bonus = {
    "stone": 1.0,
    "copper": 1.05,
    "iron": 1.10,
    "steel": 1.15,
    "iridium": 1.25
}

# 最终价值
final_value = floor(base_value * quality_multiplier * tool_value_bonus)
```

### 公式变量表

| 变量名 | 类型 | 范围 | 说明 |
|--------|------|------|------|
| `final_quality_chance` | float | 0.0-1.0 | 最终高品质概率 |
| `final_mine_time` | float | 0.5-10.0 | 最终挖掘时间（秒） |
| `final_cost` | int | 1+ | 耐久度消耗 |
| `final_encounter_chance` | float | 0.20-0.60 | 敌人遭遇概率 |
| `final_damage` | int | 1+ | 战斗伤害 |
| `final_flee_chance` | float | 0.20-0.80 | 逃跑成功率 |
| `final_value` | int | 1+ | 矿石售价 |
| `mining_skill_level` | int | 0-10 | 采矿技能等级 |

### 预期产出范围

| 矿石类型 | 基础价值 | 高品质加成 | 稀有概率 |
|----------|----------|------------|----------|
| 煤炭 | 10g | ×1.5~3 | 1% |
| 铜矿 | 20g | ×1.5~3 | 3% |
| 铁矿 | 40g | ×1.5~3 | 5% |
| 金矿 | 100g | ×1.5~3 | 8% |
| 铱矿 | 300g | ×1.5~3 | 10% |
| 宝石 | 500g | ×1.5~3 | 1% |
| 钻石 | 1000g | ×1.5~3 | 0.5% |

## Edge Cases

### 1. 工具耐久度边界情况

| 情况 | 处理方式 |
|------|----------|
| 耐久度耗尽 | 工具不可用，显示"需要修复"，自动返回地面 |
| 耐久度低于 10% | 显示警告提示，建议修复 |
| 没有工具 | 无法进入矿洞，显示"需要镐子" |
| 工具等级不足 | 只能挖掘部分矿石，显示"太硬了" |

### 2. 战斗边界情况

| 情况 | 处理方式 |
|------|----------|
| HP 归零 | 自动返回地面，损失部分背包物品（随机 20%） |
| 逃跑失败 | 受到额外伤害，可能再次逃跑 |
| 逃跑成功 | 损失已挖掘的矿石（随机 30%） |
| 战斗中时间耗尽 | 强制返回地面，当日不可再进入 |

### 3. 背包边界情况

| 情况 | 处理方式 |
|------|----------|
| 背包已满 | 矿石存入临时背包，提示需要整理 |
| 背包和临时背包都满 | 矿石留在原地，提示"背包空间不足" |
| 临时背包满后挖掘 | 显示警告但允许继续挖掘（会丢失） |

### 4. 层数边界情况

| 情况 | 处理方式 |
|------|----------|
| 想返回地面 | 使用电梯（20层倍数）、楼梯或传送羽毛 |
| 电梯只能到 20 的倍数 | 其他层需要楼梯一层层爬 |
| 到达最终层 120 | 显示"已到达矿洞最深处"，可继续挖矿 |
| Boss 未击败想下楼 | 无法进入下一区域电梯，需先击败 Boss |

### 5. Boss 战斗边界情况

| 情况 | 处理方式 |
|------|----------|
| Boss 未击败想离开 | 显示"需要击败 Boss 才能继续"，可选择逃跑 |
| Boss 逃跑损失 | 损失部分矿石，但保留 Boss 房入口 |
| 连续挑战 Boss | Boss 每日重置，可以重新挑战 |
| Boss 掉落背包满 | 优先存入背包，不足的存入临时背包 |

### 6. 每日重置边界

当玩家每天进入矿洞时：
```
1. 所有敌人重置（新的一天）
2. 矿石保持（除非被采尽）
3. 当前层数保持
4. 已击败的 Boss 状态重置
5. 矿洞深度进度保持
```

### 7. 工具升级与采矿

| 情况 | 处理方式 |
|------|----------|
| 获得更好的镐子 | 立即可以使用，高等级工具可挖更深层 |
| 低等级工具挖高硬度矿石 | 极慢（×3 时间）或失败 |
| 升级矿洞内工具 | 需要返回地面找铁匠升级 |

### 8. 特殊矿石边界

| 情况 | 处理方式 |
|------|----------|
| 稀有宝石出现 | 低概率，可遇不可求 |
| 虚空矿石 | 仅在 101-120 层，需要特殊工具 |
| 传说矿石 | 仅 Boss 掉落，不可挖掘 |

### 9. 采矿技能边界

| 情况 | 处理方式 |
|------|----------|
| 采矿技能 0 级 | 可以挖矿，但效率低、品质低 |
| 采矿技能满级 | 最高效率和品质概率 |
| 采矿同时练战斗 | 两个技能可以同时提升 |

## Dependencies

### 上游依赖

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **C02** | InventorySystem | 硬依赖 | 矿石存入背包、消耗工具耐久 |
| **C08** | WeaponEquipmentSystem | 硬依赖 | 武器战斗、攻击计算、暴击 |
| **F03** | ItemDataSystem | 硬依赖 | 矿石定义、敌人定义、工具定义 |
| **C01** | PlayerStatsSystem | 硬依赖 | HP、体力消耗、战斗死亡 |
| **C03** | SkillSystem | 硬依赖 | 采矿技能等级、战斗经验 |

### 下游依赖

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P10** | GuildSystem | 软依赖 | 矿石兑换贡献点 |
| **P11** | MuseumSystem | 软依赖 | 矿石/宝石捐赠 |
| **F01** | SaveLoadSystem | 硬依赖 | 采矿数据保存/加载 |

### 数据流

```
F03 ItemDataSystem (矿石/敌人/工具定义)
    ↓
C03 SkillSystem (采矿技能加成)
    ↓
MiningSystem (核心逻辑)
    ↓
C08 WeaponEquipmentSystem (战斗系统)
    ↓
C02 InventorySystem (存入背包)
    ↓
P10 GuildSystem (兑换) / P11 MuseumSystem (捐赠)
```

### 待确认的依赖

| 系统 | 依赖说明 | 状态 |
|------|----------|------|
| **C06** | 工具升级是否在矿洞内？还是需要返回地面？ | 返回地面升级 |
| **F02** | 天气是否影响矿洞？（如地震打开新区域） | MVP 不需要 |

## Tuning Knobs

### 矿洞结构调参

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| `mine.total_floors` | 120 | 60-200 | 总层数 |
| `mine.floors_per_area` | 20 | 10-30 | 每区域层数 |
| `mine.elevator_interval` | 20 | 与 floors_per_area 同步 | 电梯间隔 |
| `mine.total_areas` | 6 | 3-10 | 区域数量 |

### 工具调参

| 参数 | 默认值 | 安全范围 | 说明 | 过高/过低影响 |
|------|--------|----------|------|---------------|
| `tool.stone.durability` | 50 | 20-100 | 石镐耐久 | 影响游戏节奏 |
| `tool.copper.durability` | 80 | 50-150 | 铜镐耐久 | - |
| `tool.iron.durability` | 120 | 80-200 | 铁镐耐久 | - |
| `tool.steel.durability` | 200 | 150-300 | 钢镐耐久 | - |
| `tool.iridium.durability` | 500 | 300-800 | 铱镐耐久 | - |

### 挖掘调参

| 参数 | 默认值 | 安全范围 | 说明 | 过高/过低影响 |
|------|--------|----------|------|---------------|
| `mine.base_quality` | 5% | 2-10% | 基础高品质概率 | 影响稀有产出 |
| `mine.skill_bonus` | 1%/级 | 0.5-2%/级 | 技能加成 | 影响技能价值 |
| `mine.encounter_rate` | 30% | 15-50% | 敌人遭遇率 | 影响节奏 |

### 战斗调参

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| `combat.base_flee_chance` | 50% | 30-70% | 基础逃跑率 |
| `combat.defeat_loss_ratio` | 20% | 10-40% | 失败损失物品比例 |
| `combat.flee_loss_ratio` | 30% | 15-50% | 逃跑损失矿石比例 |

### Boss 调参

| Boss | 默认 HP | 安全范围 | 说明 |
|------|--------|----------|------|
| 石头巨人 | 100 | 50-200 | 第 20 层 |
| 蝙蝠王 | 200 | 100-400 | 第 40 层 |
| 幽灵领主 | 350 | 200-600 | 第 60 层 |
| 火焰巨龙 | 500 | 300-1000 | 第 80 层 |
| 虚空守卫 | 800 | 500-1500 | 第 100 层 |
| 矿洞之主 | 1500 | 1000-3000 | 第 120 层 |

### 矿石调参

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| `ore.copper.base_value` | 20g | 10-50g | 铜矿基础价值 |
| `ore.iron.base_value` | 40g | 20-100g | 铁矿基础价值 |
| `ore.gold.base_value` | 100g | 50-200g | 金矿基础价值 |
| `ore.iridium.base_value` | 300g | 150-500g | 铱矿基础价值 |
| `ore.diamond.base_value` | 1000g | 500-2000g | 钻石基础价值 |

### 调参交互警告

| 参数 A | 参数 B | 交互说明 |
|--------|--------|----------|
| `mine.encounter_rate` | 背包容量 | 高遭遇+小背包=频繁回城 |
| `ore.*.base_value` | P10 Guild 兑换 | 高价值矿石=快速获取贡献点 |
| `combat.defeat_loss_ratio` | 玩家在线时间 | 高损失+短在线=体验不佳 |

## Acceptance Criteria

### 功能验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **AC-01** | 进入矿洞 | 加载第 1 层，显示矿石和敌人 | P0 |
| **AC-02** | 挖掘矿石 | 矿石消失，背包获得矿石 | P0 |
| **AC-03** | 耐久度耗尽 | 工具不可用，自动返回地面 | P1 |
| **AC-04** | 遭遇敌人 | 进入战斗状态 | P0 |
| **AC-05** | 击败敌人 | 获得掉落物品，继续挖矿 | P0 |
| **AC-06** | 逃跑成功 | 损失部分矿石，返回挖矿 | P1 |
| **AC-07** | 使用电梯 | 快速到达指定层（20倍数） | P0 |
| **AC-08** | 进入 Boss 房 | 显示 Boss 信息 | P0 |
| **AC-09** | 击败 Boss | 获得掉落物品，继续挖矿 | P0 |
| **AC-10** | HP 归零 | 自动返回地面，损失物品 | P1 |
| **AC-11** | 每日重置 | 敌人刷新，矿石保持 | P0 |
| **AC-12** | 到达第 120 层 | 显示"已到达最深处" | P1 |

### 挖掘验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **MC-01** | 用铁镐挖铁矿 | 正常速度 | P0 |
| **MC-02** | 用石镐挖铁矿 | 速度极慢（3倍） | P1 |
| **MC-03** | 技能 Lv10 挖矿 | 高品质概率提升 | P0 |
| **MC-04** | Miner 天赋挖矿 | 50%概率额外获得 | P1 |
| **MC-05** | Prospector 天赋挖矿 | 15%概率双倍 | P1 |

### 战斗验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **BC-01** | 使用武器攻击 | 造成伤害，可能暴击 | P0 |
| **BC-02** | 受到敌人攻击 | HP 减少 | P0 |
| **BC-03** | 击败 Boss | 获得 Boss 掉落 | P0 |
| **BC-04** | 采矿技能战斗加成 | 伤害增加 | P1 |

### 集成验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **IC-01** | 矿石出售 | 通过 P06 ShopSystem 正常出售 | P0 |
| **IC-02** | 矿石捐赠 | 通过 P11 MuseumSystem 正常捐赠 | P1 |
| **IC-03** | 矿石兑换 | 通过 P10 GuildSystem 兑换贡献点 | P1 |
| **IC-04** | 保存/加载 | 采矿数据正确保存和恢复 | P0 |
| **IC-05** | 采矿技能升级 | 属性加成正确应用 | P0 |

### 性能验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **PC-01** | 矿洞加载时间 | < 2s | P0 |
| **PC-02** | 大量矿石挖掘 | < 16ms | P1 |

### UI 验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **UC-01** | 显示当前层数 | 正确显示楼层信息 | P0 |
| **UC-02** | 矿石高亮 | 可挖掘矿石正确高亮 | P0 |
| **UC-03** | 工具耐久显示 | 耐久度条正确显示 | P0 |
| **UC-04** | Boss 血条 | Boss HP 正确显示 | P0 |

## Open Questions

| # | 问题 | 负责人 | 状态 | 备注 |
|---|------|--------|------|------|
| OQ-01 | 矿石具体数量和定义 | F03 ItemDataSystem | 待定 | 需从原项目迁移矿石数据 |
| OQ-02 | 敌人 AI 具体行为 | AI Team | 待定 | 需要敌人行为设计 |
| OQ-03 | Boss 战斗特殊机制 | Game Design | 待定 | 是否需要 Boss 专属技能？ |
| OQ-04 | 矿洞随机生成算法 | Tech Lead | 待定 | 保证每局体验不同 |
| OQ-05 | 采矿小游戏 vs 直接点击 | UX Design | 待定 | 简化版 vs 完整版 |
| OQ-06 | 传送羽毛获取方式 | Economy | 待定 | 影响矿洞探索节奏 |
| OQ-07 | 每日进入次数限制 | Game Design | 待定 | 是否需要限制？ |
| OQ-08 | 矿洞音效/背景音乐 | Audio | 待定 | 不同区域不同音乐？ |
