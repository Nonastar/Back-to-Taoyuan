# 公会系统 (Guild System)

> **Status**: Approved
> **Author**: Claude + User
> **Last Updated**: 2026-04-07
> **Implements Pillar**: 战斗挑战与怪物猎杀

## Overview

公会系统是游戏的战斗挑战与怪物猎杀系统，包括21个讨伐目标、贡献点经济、10级公会等级和公会商店。玩家通过击杀怪物完成讨伐目标获得奖励，通过捐献矿石宝石获得贡献点和经验值，在公会商店购买战斗消耗品和永久强化装备。

## Player Fantasy

公会系统给玩家带来**冒险者的荣耀感**。玩家应该感受到：

- **怪物猎人的成就感** — 每击败一个区域的怪物都是对自己实力的证明
- **积累的力量** — 公会等级提升带来的永久属性加成让角色越来越强
- **专属的装备** — 只有公会商店才能获得的强力装备
- **永无止境的追求** — 21个讨伐目标完成后还有更高难度的怪物等待挑战

**Reference games**: Monster Hunter 的讨伐目标成就感；Stardew Valley 冒险者公会的装备奖励。

## Detailed Design

### Core Rules

#### 1. 讨伐目标 (Monster Goals)

玩家通过击杀怪物完成讨伐目标，共21个目标：

**按区域分类**：

| 区域 | 目标数 | 怪物示例 | 击杀目标 | 奖励范围 |
|------|--------|----------|----------|----------|
| 浅层 | 2 | 泥虫、石蟹 | 25 | 200-300g |
| 冰霜 | 2 | 冰蝠、幽灵 | 25 | 500g |
| 熔岩 | 2 | 火蝠、暗影武士 | 50 | 800-1000g |
| 水晶 | 2 | 水晶魔像、棱镜蛛 | 50 | 1500g |
| 暗影 | 2 | 暗影潜伏者、虚空幽魂 | 75 | 2000-2500g |
| 深渊 | 2 | 深渊巨蟒、骨龙 | 100 | 3000-4000g |
| Boss | 6 | 泥岩巨兽、冰霜女王等 | 3次 | 装备材料 |
| 骷髅矿穴 | 3 | 铱金魔像、骷髅飞蛇等 | 50 | 3000-5000g |

**讨伐流程**：
1. 玩家进入矿洞或骷髅矿穴
2. 击杀怪物，系统调用 `record_kill(monster_id)`
3. 达到目标数量后，目标变为可领取状态
4. 玩家返回公会领取奖励

#### 2. 贡献点系统 (Contribution Points)

贡献点是公会商店的专用货币，通过以下方式获得：

**获取途径**：

| 来源 | 贡献点计算 | 备注 |
|------|------------|------|
| 领取讨伐奖励 | `floor(reward_money / 20) + kill_target` | 讨伐奖励额外赠送 |
| 捐献矿石 | 见捐献表 | 立即获得 |
| 捐献宝石 | 见捐献表 | 立即获得 |

**捐献物品表**：

| 物品 | 贡献点 | 备注 |
|------|--------|------|
| 铜矿 | 2 | - |
| 铁矿 | 4 | - |
| 金矿 | 8 | - |
| 水晶矿 | 12 | - |
| 暗影矿 | 18 | - |
| 虚空矿 | 25 | - |
| 铱矿 | 35 | - |
| 石英 | 4 | - |
| 翡翠 | 12 | - |
| 红宝石 | 18 | - |
| 月石 | 25 | - |
| 黑曜石 | 35 | - |
| 龙玉 | 50 | - |
| 棱彩碎片 | 80 | - |

#### 3. 公会等级系统 (Guild Level)

公会等级通过捐献获得的公会经验提升：

**等级表**（10级）：

| 等级 | 升级所需经验 | 累计总经验 |
|------|--------------|------------|
| 1 | 100 | 100 |
| 2 | 200 | 300 |
| 3 | 300 | 600 |
| 4 | 400 | 1000 |
| 5 | 500 | 1500 |
| 6 | 700 | 2200 |
| 7 | 800 | 3000 |
| 8 | 1000 | 4000 |
| 9 | 1500 | 5500 |
| 10 | 2000 | 7500 |

**被动加成**（每级）：

| 加成类型 | 每级效果 | 满级效果 |
|----------|----------|----------|
| 攻击加成 | +1 | +10 |
| 最大HP加成 | +5 | +50 |

#### 4. 公会商店 (Guild Shop)

商店物品分三类：

**A. 消耗品（铜钱购买，不限购）**：

| 物品 | 价格 | 解锁等级 | 效果 |
|------|------|----------|------|
| 战斗补剂 | 200g | 1 | 恢复30 HP |
| 强化药水 | 500g | 1 | 恢复60 HP |
| 铁壁药剂 | 800g | 1 | 恢复全部HP |
| 冒险口粮 | 350g | 2 | 恢复25体力+25HP |
| 精力药剂 | 600g | 4 | 恢复120体力 |
| 勇者盛宴 | 1000g | 5 | 恢复50体力+50HP |
| 猎魔符 | 1500g | 3 | 掉落率+20% |
| 怪物诱饵 | 2000g | 7 | 本层怪物翻倍 |

**B. 永久强化品（贡献点购买，有限购）**：

| 物品 | 贡献点 | 解锁等级 | 限购 | 效果 |
|------|--------|----------|------|------|
| 公会徽章 | 150 | 6 | 每周10件 | 攻击永久+3 |
| 守护符 | 180 | 7 | 每周3件/共10件 | 防御永久+3% |
| 生命护符 | 200 | 8 | 每天1件/共100件 | HP永久+15 |
| 幸运铜钱 | 300 | 10 | 每周3件/共10件 | 掉落率永久+5% |

**C. 专属装备（贡献点+材料，限购1件）**：

| 物品 | 贡献点 | 材料 | 解锁等级 | 效果 |
|------|--------|------|----------|------|
| 公会战戒 | 200 | 金锭×5、红宝石×2 | 5 | 攻击+4、防御+6% |
| 公会战盔 | 250 | 金锭×5、月石×1 | 6 | 攻击+3、HP+15 |
| 公会战靴 | 250 | 金锭×5、黑曜石×1 | 7 | 攻击+2、防御+5%、移速+10% |
| 公会战刃 | 350 | 金锭×10、龙玉×1 | 9 | 攻击36、暴击10% |

#### 5. 限购系统 (Purchase Limits)

**限购类型**：

| 类型 | 重置周期 | 用途 |
|------|----------|------|
| 每日限购 | 每天 | 生命护符等 |
| 每周限购 | 每周7天 | 公会徽章、守护符等 |
| 永久总限 | 不重置 | 专属装备、生命护符上限 |

**重置计算**：
```
day_number = (year - 1) * 112 + season_index * 28 + day
week_number = floor((day_number - 1) / 7)
```

### States and Transitions

#### 讨伐目标状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **InProgress** | 进行中 | 击杀数 < 目标数 |
| **Claimable** | 可领取 | 击杀数 >= 目标数 且 未领取 |
| **Claimed** | 已领取 | 奖励已领取 |

**讨伐目标状态转换**：
```
InProgress → Claimable: record_kill 导致 kill_count >= kill_target
Claimable → Claimed: claim_goal() 成功
```

#### 公会等级状态

| 状态 | 描述 |
|------|------|
| **Leveling** | 经验累积中 |
| **Leveled** | 升级待确认 |

### Interactions with Other Systems

#### 依赖系统 (Upstream Dependencies)

| System | Interface | Usage |
|--------|-----------|-------|
| P03 采矿系统 | monster definitions, kill events | 讨伐目标怪物定义 |
| C08 武器装备 | equipment slots | 公会装备添加 |
| F01 时间/季节 | day/week calculation | 限购重置 |
| C01 玩家属性 | money, HP | 商店购买消耗 |
| C02 库存系统 | items | 捐献、购买、奖励发放 |
| F03 物品数据 | item definitions | 物品验证 |

#### 事件订阅 (Event Subscriptions)

```gdscript
# 采矿/战斗系统发出
signal monster_killed(monster_id: String, location: String)
signal monster_encountered(monster_id: String)

# 公会系统发出
signal guild_level_up(new_level: int)
signal contribution_points_changed(new_points: int)
signal goal_claimable(monster_id: String)
signal goal_claimed(monster_id: String)
```

#### API 接口

```gdscript
class_name GuildSystem extends Node

## 讨伐目标
func record_kill(monster_id: String) -> void
func record_encounter(monster_id: String) -> void
func get_kill_count(monster_id: String) -> int
func is_encountered(monster_id: String) -> bool
func claim_goal(monster_id: String) -> bool
func get_claimable_goals() -> Array
func get_completed_goal_count() -> int

## 捐献
func donate_item(item_id: String, quantity: int) -> Dictionary:
    """返回 {success: bool, points_gained: int}"""

## 商店
func buy_shop_item(item_id: String) -> bool
func is_shop_item_unlocked(item_id: String) -> bool
func get_daily_remaining(item_id: String, limit: int) -> int
func get_weekly_remaining(item_id: String, limit: int) -> int
func get_total_remaining(item_id: String, limit: int) -> int

## 公会等级
func get_guild_level() -> int
func get_guild_exp() -> int
func get_guild_attack_bonus() -> int
func get_guild_hp_bonus() -> int

## 状态查询
func get_contribution_points() -> int

## 存档
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

## Formulas

### 1. 讨伐奖励贡献点

```
contribution_points = floor(reward_money / 20) + kill_target

示例：
  泥虫讨伐: floor(200 / 20) + 25 = 10 + 25 = 35
  深渊巨蟒讨伐: floor(3000 / 20) + 100 = 150 + 100 = 250
```

### 2. 公会等级经验判定

```
is_level_up_available = guild_exp >= GUILD_LEVELS[guild_level].exp_required

逐级检查直到无法升级
```

### 3. 限购重置计算

```
# 每日编号
day_number = (year - 1) * 112 + season_index * 28 + day

# 每周编号
week_number = floor((day_number - 1) / 7)

# 重置判定
if current_day != last_reset_day:
    daily_purchases = {}  # 重置每日限购

if current_week != last_reset_week:
    weekly_purchases = {}  # 重置每周限购
```

### 4. 永久品购买限制

```
# 检查顺序
1. 公会等级是否满足 unlock_guild_level
2. 每日限购是否已满
3. 每周限购是否已满
4. 永久总限是否已满

can_purchase = all_checks_passed
```

## Edge Cases

### 1. 讨伐目标边界

- **重复击杀同一怪物**：正常累加计数
- **未达成目标前领取**：返回失败
- **重复领取**：返回失败，已领取目标不可再领

### 2. 捐献边界

- **物品数量不足**：只捐献可用数量，返回实际获得贡献点
- **物品不在捐献表**：返回失败
- **背包已满**：不扣物品，返回失败

### 3. 商店购买边界

- **贡献点不足**：返回失败
- **材料不足**：返回失败
- **背包已满（装备）**：退还所有消耗，返回失败
- **等级未解锁**：返回失败

### 4. 限购边界

- **跨季节/年份**：限购正确重置
- **长时间不上线**：限购重置不受影响

### 5. 存档迁移

- **旧存档无贡献点**：如果已领取讨伐目标，按公式补发贡献点
- **旧存档无公会等级**：设为0级
- **旧存档无限购数据**：初始化为空对象

## Dependencies

| ID | System Name | Type | Interface |
|----|-------------|------|-----------|
| D01 | P03 MiningSystem | Hard | monster_killed event, monster definitions |
| D02 | C08 WeaponEquipment | Hard | add equipment to slots |
| D03 | F01 TimeSeasonSystem | Hard | day/week calculation |
| D04 | C01 PlayerStatsSystem | Hard | money spending, HP bonus |
| D05 | C02 InventorySystem | Hard | item donate, purchase, reward |
| D06 | F03 ItemDataSystem | Hard | item definitions |

## Tuning Knobs

### 讨伐目标配置

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `goal_base_points_multiplier` | 0.05 | 0.02-0.1 | reward_money / X 作为基础贡献点 |
| `goal_kill_target_bonus` | 1 | 0-2 | 每击杀目标数额外贡献点 |

### 公会等级配置

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `max_guild_level` | 10 | 固定 | 最高等级 |
| `attack_per_level` | 1 | 0-3 | 每级攻击加成 |
| `hp_per_level` | 5 | 0-20 | 每级HP加成 |

### 商店限购配置

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `daily_limit_life_talisman` | 1 | 1-5 | 生命护符每日限购 |
| `weekly_limit_badge` | 10 | 5-20 | 公会徽章每周限购 |
| `weekly_limit_charm` | 3 | 1-10 | 守护符每周限购 |
| `total_limit_equip` | 1 | 固定 | 装备永久限购 |

### 消耗品配置

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `combat_tonic_price` | 200 | 100-500 | 战斗补剂价格 |
| `slayer_charm_price` | 1500 | 800-3000 | 猎魔符价格 |
| `monster_lure_price` | 2000 | 1000-4000 | 怪物诱饵价格 |

## Visual/Audio Requirements

### UI Requirements

| Screen | Component | Description |
|--------|-----------|-------------|
| 公会界面 | GuildView | 主界面，显示讨伐目标和公会信息 |
| 讨伐面板 | GoalPanel | 怪物讨伐进度列表 |
| 商店面板 | ShopPanel | 公会商店商品列表 |
| 捐献面板 | DonationPanel | 捐献矿石宝石界面 |
| 等级面板 | LevelPanel | 公会等级和被动加成 |

### Visual Feedback

- 讨伐目标可领取时显示金色高亮
- 升级时显示等级提升动画
- 购买成功时显示物品图标飞入背包

### Audio Feedback

- 击杀怪物：战斗音效
- 领取奖励：奖励获得音效
- 升级：升级音效
- 购买：商店购买音效

## Acceptance Criteria

### Functional Criteria

- [ ] 击杀怪物正确记录到讨伐目标
- [ ] 21个讨伐目标条件判断正确
- [ ] 讨伐奖励领取正确发放金币和物品
- [ ] 贡献点计算正确
- [ ] 捐献物品获得对应贡献点和经验
- [ ] 公会等级正确升级
- [ ] 被动攻击/HP加成正确应用
- [ ] 商店物品购买流程正确
- [ ] 每日/每周/永久限购正确执行
- [ ] 存档/读档状态正确保存恢复

### Performance Criteria

- [ ] 击杀记录响应时间 < 1ms
- [ ] 商店购买检查响应时间 < 5ms
- [ ] 公会界面加载时间 < 500ms

### Compatibility Criteria

- [ ] 与采矿系统的怪物击杀事件集成
- [ ] 与装备系统的装备添加集成
- [ ] 与库存系统的物品管理集成

## Open Questions

| ID | Question | Owner | Target Date |
|----|----------|-------|-------------|
| O1 | 骷髅矿穴怪物是否需要单独的讨伐目标？ | Designer | Pre-MVP |
| O2 | 公会商店是否需要与沙漠/赌场商店互补？ | Balance | Pre-MVP |
| O3 | 公会等级上限是否需要超过10级？ | Designer | Post-MVP |
