# 武器装备系统 (Weapon Equipment System)

> **状态**: In Design
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: C08
> **Implements Pillar**: 战斗属性与装备成长

## Overview

武器装备系统管理玩家的所有战斗相关装备，包括武器、帽子、鞋子、戒指，以及武器附魔和装备套装效果。系统提供装备获取、装备穿戴、属性加成计算、套装效果激活等功能。武器装备系统是战斗力的核心来源，通过采集、击杀Boss、完成任务等途径获取更强装备，形成玩家成长循环。

## Player Fantasy

武器装备系统给玩家带来**收集的成就感和成长的满足感**。玩家应该感受到：

- **开箱的惊喜** — 击杀怪物后期待掉落更好的武器
- **套装的追求** — 集齐套装激活强力效果的成就感
- **附魔的策略** — 选择不同附魔效果带来不同战斗风格
- **属性的累积** — 看着角色属性面板不断提升的满足

**Reference games**: Stardew Valley 的矿洞装备追求；Diablo 的套装收集；Rune Factory 的武器升级。

## Detailed Design

### Core Rules

#### 1. 武器系统

- **武器类型**: 剑 (Sword)、匕首 (Dagger)、棍棒 (Club)、弓 (Bow)
- **武器属性**:
  - `attack`: 基础攻击力 (10-150)
  - `critRate`: 暴击率 (0.0-0.5)
  - `source`: 获取来源 (shop/boss/monster)
  - `range`: 攻击范围（近战: 1, 远程: >1）- 弓为远程武器
- **武器列表** (30+ 把):
  - 商店武器: 锈剑(10攻)、铁剑(20攻)、钢剑(35攻)、蓝钢剑(55攻)、匕首(12攻)、铁棍(15攻)等
  - Boss掉落: 黑暗之刃(80攻)、精灵之剑(70攻)、远古之剑(90攻)等
  - 怪物掉落: 多种不同攻击力的怪物专属武器

#### 2. 帽子系统 (Hats)

- **帽子属性**:
  - `luck`: 幸运加成
  - `defense`: 防御加成
  - `stamina`: 体力加成
  - `speed`: 速度加成
  - `attack`: 攻击加成
- **特殊帽子**: 骑士帽子、游侠帽子、牛仔帽子、庆典帽子等

#### 3. 鞋子系统 (Shoes)

- **鞋子属性**:
  - `luck`, `defense`, `stamina`, `speed`, `attack`
- **特殊鞋子**: 矿工靴、橡胶靴、游侠靴等

#### 4. 戒指系统 (Rings)

- **戒指效果类型**:
  - `luck`: 幸运加成 (幸运戒指、星星戒指)
  - `defense`: 防御加成 (防御戒指)
  - `stamina`: 体力加成 (能量戒指)
  - `speed`: 速度加成 (速度戒指)
  - `attack`: 攻击加成 (力量戒指)
- **双槽位**: 玩家可同时装备两枚戒指
- **禁止同ID**: 不能将同一枚戒指同时装备在两个槽位

#### 5. 武器附魔系统 (Enchantments)

- **附魔类型**:
  - `sharp`: 锋利 (+3 攻击)
  - `fierce`: 凶猛 (+5 攻击)
  - `precise`: 精准 (+0.1 暴击率)
  - `vampiric`: 吸血 (5% 生命偷取)
  - `sturdy`: 坚韧 (受伤减少10%)
  - `lucky`: 幸运 (+1 幸运)
- **附魔价格**: 根据类型不同，价格 500-3000 不等
- **附魔限制**: 每把武器只能有一种附魔
- **附魔替换**: 可用新附魔替换旧附魔（不额外收费）
- **附魔移除**: 任何武器商人可以移除附魔，返还 50% 的附魔价格

#### 6. 装备套装系统 (Equipment Sets)

- **14 种套装**:
  1. **矿工套装** (miner): 矿工头盔+矿工靴+矿工戒指
  2. **渔夫套装** (fisher): 渔夫帽子+渔夫靴+渔夫戒指
  3. **商人套装** (merchant): 商人帽子+商人靴+商人戒指
  4. **丰收套装** (harvest): 丰收帽子+丰收靴+丰收戒指
  5. **龙战士套装** (dragon_warrior): 龙战士之剑+龙头盔+龙靴+龙戒指
  6. **黑曜石套装** (obsidian): 黑曜石之剑+黑曜石头盔+黑曜石靴+黑曜石戒指
  7. **凤凰套装** (phoenix): 凤凰之剑+凤凰头盔+凤凰靴+凤凰戒指
  8. **暗影套装** (shadow): 暗影匕首+暗影兜帽+暗影靴+暗影戒指
  9. **冰霜女王套装** (frost_queen): 冰霜之剑+冰霜头盔+冰霜靴+冰霜戒指
  10. **龙王套装** (dragon_king): 龙王之剑+龙王头盔+龙王靴+龙王戒指
  11. **森林猎人套装** (forest_hunter): 森林弓+森林帽子+森林靴+森林戒指
  12. **兽王套装** (beast_king): 兽王之剑+兽王头盔+兽王靴+兽王戒指
  13. **公会冠军套装** (guild_champion): 公会之剑+公会头盔+公会靴+公会戒指
  14. **探险家套装** (explorer): 探险家帽子+探险家靴+探险家戒指

- **14 种独立套装奖励**:

| 套装 | 类型 | 2件套 | 3件套 | 4件套 |
|------|------|-------|-------|-------|
| **矿工** | 功能 | 幸运+1 | 采矿速度+10% | 采矿体力-50% |
| **渔夫** | 功能 | 幸运+1 | 钓鱼成功率+5% | 钓鱼体力-50% |
| **商人** | 功能 | 幸运+1 | 商品价格+5% | 出售价格+10% |
| **丰收** | 功能 | 幸运+1 | 作物价值+5% | 作物额外掉落+10% |
| **探险家** | 功能 | 幸运+1 | 移动速度+5% | 旅行体力-30% |
| **龙战士** | 战斗 | 攻击+2 | 暴击伤害+10% | 攻击+5,暴击率+5% |
| **黑曜石** | 战斗 | 防御+2 | 受伤减免5% | 防御+5,坚韧效果 |
| **凤凰** | 战斗 | 攻击+2 | 生命偷取+3% | 死亡复活(1次/天) |
| **暗影** | 战斗 | 攻击+2 | 暴击率+3% | 隐身(采矿不遇怪) |
| **冰霜女王** | 战斗 | 防御+2 | 攻击减速敌人 | 冰冻范围攻击 |
| **龙王** | 战斗 | 攻击+2 | 火属性伤害+10% | 范围火焰攻击 |
| **森林猎人** | 混合 | 幸运+1,攻击+1 | 暴击率+5% | 远程攻击强化 |
| **兽王** | 战斗 | 防御+2 | 生命+10% | 宠物伤害+20% |
| **公会冠军** | 战斗 | 攻击+2 | 经验值+10% | 声望获取+20% |

- **套装成员来源**: 每个装备物品定义（由 F03 ItemDataSystem 提供）包含 `set_id` 字段
  - 例：`矿工头盔.def.set_id = "miner"`, `矿工靴.def.set_id = "miner"`
  - C08 通过查询已装备物品的 set_id 来计算套装激活状态

#### 7. 装备方案 (Presets)

- 最多保存 5 个装备预设方案
- 一键切换完整装备配置
- 方案中缺少的装备会提示玩家

#### 8. 合成系统（由 C02 负责）

- **注**：戒指、帽子、鞋子的合成操作由 **C02 InventorySystem** 管理
- C08 负责装备效果计算（套装奖励、附魔属性）

### States and Transitions

#### 装备槽位状态

| 槽位 | 状态 | 描述 |
|------|------|------|
| **武器** | Empty/Equipped | 武器槽 |
| **戒指1** | Empty/Equipped | 第一个戒指槽 |
| **戒指2** | Empty/Equipped | 第二个戒指槽 |
| **帽子** | Empty/Equipped | 帽子槽 |
| **鞋子** | Empty/Equipped | 鞋子槽 |

#### 套装激活状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **Inactive** | 套装未激活 | equipped_count < 2 |
| **Tier1** | 2件套激活 | equipped_count >= 2 |
| **Tier2** | 3件套激活 | equipped_count >= 3 |
| **Tier3** | 4件套激活 | equipped_count >= 4 |

#### 附魔状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **None** | 无附魔 | 武器未附魔 |
| **Enchanted** | 已附魔 | 武器有附魔效果 |

### Interactions with Other Systems

**上游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **F03 ItemDataSystem** | 硬依赖 | 查询物品定义、价格、图标 |
| **C02 InventorySystem** | 硬依赖 | 获取已装备物品列表、武器/戒指/帽子/鞋子数据 |

**下游依赖 (依赖 C08 的系统)**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **C01 PlayerStatsSystem** | 软依赖 | 获取装备提供的属性加成 |
| **P03 MiningSystem** | 软依赖 | 矿工套装效果影响采矿 |
| **P10 GuildSystem** | 软依赖 | 公会套装效果 |

### 提供给下游的 API

```gdscript
class_name EquipmentSystem extends Node

## 单例访问
static func get_instance() -> EquipmentSystem

## 装备查询
func get_equipped_weapon() -> WeaponInstance:
    """返回当前装备的武器"""

func get_equipped_hat() -> HatInstance:
    """返回当前装备的帽子"""

func get_equipped_shoes() -> ShoeInstance:
    """返回当前装备的鞋子"""

func get_equipped_rings() -> Array[RingInstance]:
    """返回当前装备的两枚戒指"""

func get_weapon_attack(weapon_index: int) -> int:
    """返回武器攻击力（含附魔加成）"""

func get_weapon_crit_rate(weapon_index: int) -> float:
    """返回武器暴击率"""

## 附魔操作
func apply_enchantment(weapon_index: int, enchant_type: String) -> bool:
    """为武器添加附魔，返回是否成功"""

func remove_enchantment(weapon_index: int) -> bool:
    """移除武器附魔，返回是否成功"""

func get_enchantment_type(weapon_index: int) -> String:
    """返回武器附魔类型，无附魔返回空字符串"""

## 套装查询
func get_active_sets() -> Array[SetBonus]:
    """返回所有激活的套装效果"""

func get_set_bonus(set_id: String, piece_count: int) -> Dictionary:
    """返回指定套装的指定件数奖励"""

func check_set_requirement(set_id: String, piece_count: int) -> bool:
    """检查是否满足套装条件"""

## 装备效果汇总
func get_total_attack_bonus() -> int:
    """返回所有装备提供的总攻击加成"""

func get_total_defense_bonus() -> int:
    """返回所有装备提供的总防御加成"""

func get_total_luck_bonus() -> int:
    """返回所有装备和套装提供的总幸运加成"""

func get_total_stamina_bonus() -> int:
    """返回所有装备提供的总体力加成"""

func get_total_speed_bonus() -> float:
    """返回所有装备提供的总速度加成"""

func get_vampiric_chance() -> float:
    """返回吸血几率（来自附魔）"""

func get_damage_reduction() -> float:
    """返回受伤减免（来自附魔）"""

## 合成操作
## 注：合成操作由 C02 InventorySystem 负责
## C08 只负责装备效果计算和附魔

## 存档接口
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

## Formulas

### 1. 武器攻击力计算

```
base_attack = WEAPON_DEFS[def_id].attack
enchant_bonus = ENCHANT_BONUS[enchant_type]  # sharp:+3, fierce:+5, precise:0, ...
total_attack = base_attack + enchant_bonus
```

### 2. 武器暴击率计算

```
base_crit = WEAPON_DEFS[def_id].crit_rate
enchant_crit = ENCHANT_CRIT[enchant_type]  # precise:+0.1, others:0
total_crit_rate = min(base_crit + enchant_crit, MAX_CRIT_RATE)  # 上限 0.5
```

### 3. 装备属性加成汇总

```
total_luck = hat.luck + shoes.luck + ring1.luck + ring2.luck + set_bonuses.luck
total_defense = hat.defense + shoes.defense + ring1.defense + ring2.defense + set_bonuses.defense
total_attack = hat.attack + shoes.attack + ring1.attack + ring2.attack
total_stamina = hat.stamina + shoes.stamina + ring1.stamina + ring2.stamina
total_speed = hat.speed + shoes.speed + ring1.speed + ring2.speed
```

### 4. 套装效果计算

```
set_pieces = count_items_in_set(equipped_items, set_id)

# 每个套装有独立的奖励（由 F03 ItemDataSystem 提供 set_id）
# SET_BONUSES[set_id] = {
#     2: {luck: +1, ...},      # 2件套奖励
#     3: {...},                 # 3件套奖励
#     4: {...}                   # 4件套奖励
# }

if set_pieces >= 4:
    bonus = SET_BONUSES[set_id][4]
elif set_pieces >= 3:
    bonus = SET_BONUSES[set_id][3]
elif set_pieces >= 2:
    bonus = SET_BONUSES[set_id][2]
else:
    bonus = {}
```

### 5. 附魔价格计算

```
enchant_price = ENCHANT_PRICE[enchant_type]
# sharp: 500, fierce: 1500, precise: 800, vampiric: 2000, sturdy: 1200, lucky: 3000
```

### 6. 吸血效果计算

```
vampiric_chance = 0.05 if weapon has vampiric enchantment else 0
healed_on_hit = floor(damage_dealt × vampiric_chance)
```

### 7. 受伤减免计算

```
damage_reduction = 0.10 if weapon has sturdy enchantment else 0
actual_damage = floor(damage × (1 - damage_reduction))
```

## Edge Cases

### 1. 武器出售时装备中
- **场景**: 尝试出售当前装备的武器
- **处理**: 返回失败，提示"不能卖出装备中的武器"

### 2. 同ID戒指双槽装备
- **场景**: 尝试将同一枚戒指装备到两个槽位
- **处理**: 返回失败，禁止同ID双装备

### 3. 附魔已附魔武器
- **场景**: 为已有附魔的武器添加新附魔
- **处理**: 替换原有附魔（不退款）

### 4. 套装物品不足时应用预设
- **场景**: 装备方案中的部分装备不存在
- **处理**: 成功应用方案，但提示缺失物品

### 5. 旧存档缺少附魔数据
- **场景**: v1.0 存档加载到 v1.1
- **处理**: 使用默认空附魔

### 6. 套装奖励叠加
- **场景**: 激活多个不同套装
- **处理**: 所有激活的套装效果全部叠加

### 7. 装备方案名称重复
- **场景**: 创建已存在的预设名称
- **处理**: 提示"名称已存在"，拒绝创建

### 8. 背包满时获得装备
- **场景**: 击杀Boss掉落装备但背包满
- **处理**: 物品存入临时背包（如果临时背包也满则提示警告）

## Dependencies

### 上游依赖（C08 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F03** | ItemDataSystem | 硬依赖 | 查询物品定义、价格、图标、分类、装备 set_id |
| **C02** | InventorySystem | 硬依赖 | 获取已装备物品列表、武器/戒指/帽子/鞋子数据 |

### 下游依赖（其他系统依赖 C08）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **C01** | PlayerStatsSystem | 软依赖 | 获取装备提供的属性加成影响HP等 |
| **C02** | InventorySystem | 软依赖 | 订阅装备槽位变化信号，触发效果重算 |
| **P03** | MiningSystem | 软依赖 | 矿工套装效果影响采矿 |
| **P10** | GuildSystem | 软依赖 | 公会套装效果 |

### 关键接口契约

```gdscript
## 订阅的信号

# C02 InventorySystem
signal equipment_changed(slot: String)  # "weapon", "ring1", "ring2", "hat", "shoe"

## 发出的信号

signal enchantment_changed(weapon_index: int, enchant_type: String)
signal set_bonus_activated(set_id: String, tier: int)
signal set_bonus_deactivated(set_id: String)
signal equipment_bonus_changed(total_attack: int, total_defense: int, total_luck: int)
```

## Tuning Knobs

### 武器配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `MAX_CRIT_RATE` | 0.5 | 0.3-0.8 | 最大暴击率上限 |
| `MIN_WEAPON_ATTACK` | 10 | 5-20 | 最低武器攻击力 |
| `MAX_WEAPON_ATTACK` | 150 | 100-300 | 最高武器攻击力 |

### 附魔配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `SHARP_ATTACK_BONUS` | 3 | 1-10 | 锋利附魔攻击加成 |
| `FIERCE_ATTACK_BONUS` | 5 | 3-15 | 凶猛附魔攻击加成 |
| `PRECISE_CRIT_BONUS` | 0.1 | 0.05-0.2 | 精准附魔暴击加成 |
| `VAMPIRIC_CHANCE` | 0.05 | 0.03-0.15 | 吸血几率 |
| `STURDY_REDUCTION` | 0.1 | 0.05-0.2 | 坚韧受伤减免 |
| `LUCKY_LUCK_BONUS` | 1 | 1-3 | 幸运附魔幸运加成 |

### 附魔价格配置

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `ENCHANT_PRICE_SHARP` | 500 | 锋利附魔价格 |
| `ENCHANT_PRICE_FIERCE` | 1500 | 凶猛附魔价格 |
| `ENCHANT_PRICE_PRECISE` | 800 | 精准附魔价格 |
| `ENCHANT_PRICE_VAMPIRIC` | 2000 | 吸血附魔价格 |
| `ENCHANT_PRICE_STURDY` | 1200 | 坚韧附魔价格 |
| `ENCHANT_PRICE_LUCKY` | 3000 | 幸运附魔价格 |

### 套装奖励配置

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `SET_BONUSES` | 见套装奖励表 | 每套独立奖励（见 Core Rules） |

### 附魔移除配置

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `ENCHANT_REMOVE_REFUND_RATE` | 0.5 | 附魔移除返还 50% 价格 |
| `ENCHANT_REPLACE_FREE` | true | 附魔替换不额外收费 |

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 武器装备正确 | equipWeapon 切换武器，验证攻击变化 |
| **AC-02** | 附魔加成正确 | 附魔武器后验证攻击/暴击增加 |
| **AC-03** | 套装激活正确 | 装备2/3/4件套装，验证效果激活 |
| **AC-04** | 戒指双槽禁止同ID | 尝试将同一戒指装备两槽 |
| **AC-05** | 装备效果汇总正确 | 装备多个物品，验证属性正确叠加 |
| **AC-06** | 附魔替换正确 | 重复附魔同一武器 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | 装备效果影响玩家属性 | 装备攻击戒指，验证C01.getMaxHp变化 |
| **CS-02** | 战斗伤害计算 | 装备武器后，验证P03采矿伤害增加 |
| **CS-03** | 存档/读档 | serialize/deserialize 验证附魔和套装数据 |

### 性能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **PC-01** | 属性计算 < 1ms | getTotalAttackBonus() 调用时间 |
| **PC-02** | 套装检查 < 5ms | 遍历所有套装检查 |

### 边界情况测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **BC-01** | 暴击率超过上限 | 装备精准附魔+高暴击武器 |
| **BC-02** | 多个套装同时激活 | 装备多个不同套装 |
| **BC-03** | 无武器时战斗 | 验证默认攻击值 |

## Open Questions

| # | 问题 | 状态 | 负责人 | 目标日期 |
|---|------|------|--------|----------|
| **OQ-01** | 武器是否有耐久度？ | 待决定 | 策划 | v1.0 |
| **OQ-02** | 套装效果是否可以叠加同套装多套？ | 待决定 | 策划 | v1.0 |
| **OQ-03** | 是否有装备强化/升级系统？ | 待决定 | 策划 | v1.0 |
| **OQ-04** | 稀有装备是否有特殊光效？ | 待决定 | 美术 | v1.0 |
