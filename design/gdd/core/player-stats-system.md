# 玩家属性系统 (PlayerStats System)

> **状态**: In Design
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: C01
> **Implements Pillar**: 玩家状态与资源管理

## Overview

玩家属性系统管理主角的所有基础属性，包括生命值（HP）、体力值（Stamina）、金钱（Money）和玩家身份信息。系统提供属性查询、消耗、恢复接口，支持每日结算时的状态重置，以及各种装备、能力带来的属性加成。系统是所有需要消耗体力或生命值操作的底层依赖。

## Player Fantasy

玩家属性系统给玩家带来**资源管理的紧张感和成就感**。玩家应该感受到：

- **体力的稀缺** — 每天的体力有限，需要精打细算才能完成所有计划
- **生命的珍贵** — 战斗中 HP 的消耗让人紧张，每一次恢复都是及时的帮助
- **财富的积累** — 看着金币从 500 涨到成千上万，满满的成就感
- **升级的回报** — 体力上限提升后，可以做更多事情

**Reference games**: Stardew Valley 的体力/HP 系统让玩家珍惜每一天；Rune Factory 的属性成长带来 RPG 感。

## Detailed Design

### Core Rules

1. **玩家身份**
   - `playerName`: 玩家角色名（创建角色时设置）
   - `gender`: 性别（male/female），影响 NPC 称谓（小哥/姑娘）
   - `needsIdentitySetup`: 旧存档迁移标志

2. **体力系统（Stamina）**
   - 体力上限分 5 档：`[120, 160, 200, 250, 300]`
   - 体力上限可升级（`upgradeMaxStamina()`）
   - 额外体力加成（`bonusMaxStamina`）：仙桃、金丹等道具
   - 体力耗尽（<= 5）触发强制昏厥

3. **生命系统（HP）**
   - 基础最大 HP：100
   - 战斗等级加成：每级 +5 HP
   - 多种加成来源：
     - 战斗技能专精（fighter +25，warrior +40）
     - 戒指效果（max_hp_bonus）
     - 仙缘羁绊（spirit_shield）
     - 公会加成

4. **金钱系统（Money）**
   - 开局金额：500 铜钱
   - 支出：`spendMoney(amount)`，余额不足返回 false
   - 收入：`earnMoney(amount)`，触发成就记录

5. **每日结算重置（dailyReset）**
   - **普通就寝（24时前）**: 满体力 + 满 HP
   - **晚睡就寝（24-25时）**: 渐进恢复（90% → 60%）+ 满 HP
   - **强制昏厥（26时）**: 50% 体力 + 满 HP + 扣 10% 金钱（上限 1000）

6. **体力消耗规则**
   - 基础消耗 + 天气修正（F02 WeatherSystem）
   - 仙缘灵护减免（spirit_shield）
   - 最小消耗为 1

7. **属性加成来源**
   - 戒指效果（C08 EquipmentSystem）
   - 仙缘羁绊（P07 HiddenNPCSystem）
   - 公会加成（P10 GuildSystem）
   - 温室/家升级加成（C06 BuildingUpgradeSystem）

### States and Transitions

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Normal** | 正常游戏状态 | HP > 0，体力 > 0 |
| **Exhausted** | 体力耗尽 | stamina <= 5 |
| **LowHp** | 生命危险 | HP <= 25% 最大值 |
| **PassOut** | 强制昏厥 | stamina = 0 或 hour >= 26 |

**状态转换**:
```
Normal → Exhausted: consumeStamina 消耗全部体力
Normal → LowHp: takeDamage 导致 HP <= 25%
Exhausted → PassOut: 时间到达 26:00
PassOut → Normal: dailyReset 完成
```

### Interactions with Other Systems

**上游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **F01 TimeSeasonSystem** | 硬依赖 | 触发 dailyReset 获取就寝时间 |
| **F02 WeatherSystem** | 硬依赖 | 获取天气体力消耗修正 |
| **F03 ItemDataSystem** | 硬依赖 | 查询戒指效果、装备加成 |
| **C03 SkillSystem** | 硬依赖 | 获取战斗等级计算 HP |
| **C08 EquipmentSystem** | 硬依赖 | 获取戒指提供的属性加成 |

**下游依赖 (依赖 C01 的系统)**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| 所有游戏系统 | 硬依赖 | 调用 consumeStamina 检查体力 |
| **C05 NavigationSystem** | 硬依赖 | 移动消耗体力 |
| **C04 FarmPlotSystem** | 硬依赖 | 农作消耗体力 |
| **P03 MiningSystem** | 硬依赖 | 采矿消耗体力 |
| **P02 FishingSystem** | 硬依赖 | 钓鱼消耗体力 |
| **P04 CookingSystem** | 硬依赖 | 烹饪消耗体力 |
| **C08 EquipmentSystem** | 软依赖 | 戒指属性影响玩家 |

### 提供给下游的 API

```gdscript
class_name PlayerStats extends Node

## 单例访问
static func get_instance() -> PlayerStats

## 属性查询
func get_max_stamina() -> int:
    """返回当前体力上限"""

func get_current_stamina() -> int:
    """返回当前体力值"""

func get_stamina_percent() -> float:
    """返回体力百分比（0-100）"""

func get_max_hp() -> int:
    """返回当前最大 HP（含所有加成）"""

func get_current_hp() -> int:
    """返回当前 HP 值"""

func get_hp_percent() -> float:
    """返回 HP 百分比"""

func get_money() -> int:
    """返回当前金钱"""

func get_player_name() -> String:
    """返回玩家名"""

func get_honorific() -> String:
    """返回 NPC 对玩家的称谓（小哥/姑娘）"""

## 体力操作
func consume_stamina(amount: int) -> bool:
    """消耗体力，返回是否成功（体力不足返回 false）"""

func restore_stamina(amount: int) -> void:
    """恢复体力（不超过上限）"""

func upgrade_max_stamina() -> bool:
    """提升体力上限一档，返回是否成功"""

func add_bonus_max_stamina(amount: int) -> void:
    """添加额外体力上限（道具加成）"""

## HP 操作
func take_damage(amount: int) -> int:
    """受到伤害，返回实际伤害值（不会超过当前 HP）"""

func restore_health(amount: int) -> void:
    """恢复 HP（不超过最大 HP）"""

## 金钱操作
func spend_money(amount: int) -> bool:
    """花费金钱，返回是否成功（余额不足返回 false）"""

func earn_money(amount: int) -> void:
    """获得金钱"""

## 每日结算
func daily_reset(mode: String, bed_hour: int = 24) -> Dictionary:
    """每日重置，返回 {money_lost: int, recovery_pct: float}"""

## 状态查询
func is_exhausted() -> bool:
    """返回是否体力耗尽"""

func is_low_hp() -> bool:
    """返回是否 HP 危险"""

## 存档接口
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

## Formulas

### 1. 体力上限计算

```
max_stamina = STAMINA_CAPS[stamina_cap_level] + bonus_max_stamina

# STAMINA_CAPS = [120, 160, 200, 250, 300]
# stamina_cap_level: 0-4
```

### 2. 最大 HP 计算

```
max_hp = base_max_hp
        + combat_level × HP_PER_COMBAT_LEVEL    # 5
        + fighter_perk_bonus                    # +25
        + warrior_perk_bonus                   # +40
        + ring_hp_bonus
        + spirit_shield_bonus
        + guild_bonus
```

### 3. 体力消耗计算

```
effective_amount = max(1, floor(amount × (1 - spirit_shield_stamina_save)))

# 天气修正由 F02 WeatherSystem 提供
weather_modifier = WeatherSystem.get_stamina_modifier()
final_amount = ceil(effective_amount × weather_modifier)
```

### 4. 每日结算恢复率

```
if mode == "normal":
    recovery_pct = 1.0
elif mode == "late":
    t = clamp(bed_hour - 24, 0, 1)  # 0 到 1
    recovery_pct = LATE_NIGHT_RECOVERY_MAX - t × (LATE_NIGHT_RECOVERY_MAX - LATE_NIGHT_RECOVERY_MIN)
    # = 0.9 - t × 0.3
elif mode == "passout":
    recovery_pct = PASSOUT_STAMINA_RECOVERY  # 0.5

# 加上房屋加成
final_recovery = min(recovery_pct + house_stamina_bonus, 1.0)
```

### 5. 昏厥惩罚计算

```
money_lost = min(floor(money × PASSOUT_MONEY_PENALTY_RATE), PASSOUT_MONEY_PENALTY_CAP)
           = min(floor(money × 0.1), 1000)
```

### 6. 体力百分比

```
stamina_percent = round(stamina / max_stamina × 100)
```

## Edge Cases

### 1. 体力耗尽 + HP 危险同时
- **场景**: 体力很低时被怪物攻击
- **处理**: 分别处理，体力耗尽触发昏厥，HP 归零触发死亡

### 2. 昏厥时身上金钱为 0
- **场景**: 玩家只有很少的钱
- **处理**: `money_lost = min(money × 0.1, 1000) = 0`，不扣负

### 3. 体力上限已达最高档
- **场景**: 玩家调用 `upgrade_max_stamina()`
- **处理**: 返回 false，不进行任何操作

### 4. 多个额外体力加成叠加
- **场景**: 玩家同时有多个道具提供 bonus_max_stamina
- **处理**: 加法叠加（`bonusMaxStamina += amount`）

### 5. 旧存档缺少 bonusMaxStamina 字段
- **场景**: v1.0 存档加载到 v1.1
- **处理**: 从 maxStamina 和 staminaCapLevel 反推

### 6. 体力消耗小于 1
- **场景**: 高级技能减免后消耗为 0.3
- **处理**: `Math.max(1, floor(effective_amount))`，最小消耗为 1

### 7. HP 超过最大 HP
- **场景**: 恢复 HP 时可能超过上限
- **处理**: `Math.min(hp + amount, getMaxHp())`

### 8. 昏厥地点固定
- **场景**: 玩家在矿山深处昏厥
- **处理**: 昏厥后传送到 farm 床上

## Dependencies

### 上游依赖（C01 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F01** | TimeSeasonSystem | 硬依赖 | 触发 dailyReset，获取就寝时间 |
| **F02** | WeatherSystem | 硬依赖 | 查询 get_stamina_modifier() |
| **C03** | SkillSystem | 硬依赖 | 获取 combatLevel 计算 HP |
| **C08** | EquipmentSystem | 硬依赖 | 查询戒指属性加成 |

### 下游依赖（其他系统依赖 C01）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **C05** | NavigationSystem | 硬依赖 | 移动消耗体力 |
| **C04** | FarmPlotSystem | 硬依赖 | 农作消耗体力 |
| **P03** | MiningSystem | 硬依赖 | 采矿消耗体力 |
| **P02** | FishingSystem | 硬依赖 | 钓鱼消耗体力 |
| **P04** | CookingSystem | 硬依赖 | 烹饪消耗体力 |
| **P05** | ProcessingSystem | 软依赖 | 加工消耗体力 |
| **C06** | BuildingUpgradeSystem | 硬依赖 | 升级影响体力恢复 |
| **F04** | SaveLoadSystem | 硬依赖 | 存档所有玩家属性 |

### 关键接口契约

```gdscript
## 订阅的信号

# F01 TimeSeasonSystem
signal sleep_triggered(bedtime: int, forced: bool)

# C03 SkillSystem
signal combat_level_changed(new_level: int)

## 发出的信号

signal stamina_changed(current: int, max: int)
signal hp_changed(current: int, max: int)
signal money_changed(amount: int)
signal exhausted()
signal low_hp_warning()
```

## Tuning Knobs

### 体力系统配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `STAMINA_CAP_LEVEL_0` | 120 | 50-200 | 第 0 档体力上限 |
| `STAMINA_CAP_LEVEL_1` | 160 | 100-250 | 第 1 档体力上限 |
| `STAMINA_CAP_LEVEL_2` | 200 | 150-300 | 第 2 档体力上限 |
| `STAMINA_CAP_LEVEL_3` | 250 | 200-400 | 第 3 档体力上限 |
| `STAMINA_CAP_LEVEL_4` | 300 | 250-500 | 第 4 档体力上限 |
| `EXHAUSTED_THRESHOLD` | 5 | 0-20 | 体力耗尽阈值 |
| `STARTING_MONEY` | 500 | 100-2000 | 开局金钱 |

### 生命系统配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `BASE_MAX_HP` | 100 | 固定 | 基础最大 HP |
| `HP_PER_COMBAT_LEVEL` | 5 | 1-10 | 每级 HP 加成 |
| `FIGHTER_HP_BONUS` | 25 | 10-50 | Fighter 专精 HP 加成 |
| `WARRIOR_HP_BONUS` | 40 | 20-80 | Warrior 专精 HP 加成 |
| `LOW_HP_THRESHOLD` | 0.25 | 0.1-0.5 | 低 HP 警告阈值 |

### 每日结算配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `LATE_NIGHT_RECOVERY_MAX` | 0.9 | 0.7-1.0 | 24时就寝恢复率 |
| `LATE_NIGHT_RECOVERY_MIN` | 0.6 | 0.3-0.8 | 25时就寝恢复率 |
| `PASSOUT_STAMINA_RECOVERY` | 0.5 | 0.3-0.7 | 昏厥后恢复率 |
| `PASSOUT_MONEY_PENALTY_RATE` | 0.1 | 0.05-0.2 | 昏厥扣钱比例 |
| `PASSOUT_MONEY_PENALTY_CAP` | 1000 | 500-5000 | 昏厥扣钱上限 |

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 体力消耗正确 | 执行消耗体力操作，验证体力减少 |
| **AC-02** | 体力耗尽触发昏厥 | 体力降到 0，验证昏厥流程 |
| **AC-03** | 体力上限升级正确 | 调用 upgradeMaxStamina，验证上限提升 |
| **AC-04** | HP 计算包含所有加成 | 装备戒指/激活羁绊，验证 HP 增加 |
| **AC-05** | 金钱支出成功/失败 | 余额充足/不足时调用 spendMoney |
| **AC-06** | 每日结算恢复正确 | 测试 normal/late/passout 三种模式 |
| **AC-07** | 昏厥惩罚正确 | 昏厥后验证扣钱金额和体力恢复 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | 天气体力修正 | 雨天/暴风雨时消耗体力，验证修正 |
| **CS-02** | 战斗等级 HP | 提升战斗等级，验证 HP 增加 |
| **CS-03** | 戒指效果 | 装备 HP 戒指，验证加成 |
| **CS-04** | 仙缘羁绊 | 激活 spirit_shield，验证减免 |

### 性能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **PC-01** | 属性查询 < 1ms | getMaxHp() 调用时间 |
| **PC-02** | 存档序列化 < 10ms | serialize() 执行时间 |

### 边界情况测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **BC-01** | 体力刚好耗尽 | stamina = amount，验证扣完 |
| **BC-02** | 金钱刚好够花 | money = amount，验证成功 |
| **BC-03** | HP 恢复不超过上限 | restoreHealth(999) |
| **BC-04** | 体力上限已达最高 | 连续升级 5 次 |

## Open Questions

| # | 问题 | 状态 | 负责人 | 目标日期 |
|---|------|------|--------|----------|
| **OQ-01** | 是否有无敌模式（调试用）？ | 待决定 | 技术 | v1.0 |
| **OQ-02** | HP 是否可以超过最大值的临时 buff？ | 待决定 | 策划 | v1.0 |
| **OQ-03** | 是否有复活机制（死亡后复活点）？ | 待决定 | 策划 | v1.0 |
| **OQ-04** | 体力是否需要显示具体数值而非百分比？ | 待决定 | UX | v1.0 |
