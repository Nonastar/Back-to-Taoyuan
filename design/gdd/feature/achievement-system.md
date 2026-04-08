# 成就系统 (Achievement System)

> **Status**: Approved
> **Author**: Claude + User
> **Last Updated**: 2026-04-07
> **Implements Pillar**: 长线追求与完美度目标

## Overview

成就系统是玩家的长期目标追踪与完美度评估系统，包括成就（120+个）、祠堂任务（35个）、物品图鉴和统计计数器。系统通过监控游戏内各种活动（采集、战斗、社交等）自动检测成就完成状态，并计算玩家的完美度百分比作为游戏的终极追求目标。

## Player Fantasy

玩家应该感受到：
- **探索的成就感**：每发现新物品、完成新里程碑时的惊喜与满足
- **进度的可见性**：通过数字化的成就计数和完美度百分比直观看到自己的成长
- **社区的归属感**：通过完成祠堂任务帮助重建社区，感受到自己是这片土地的一部分
- **终极目标的方向**：完美度提供一个永远不会"完成"的长期目标，持续激励玩家回归

## Detailed Design

### Core Rules

#### 1. 物品发现 (Item Discovery)

玩家在游戏中首次接触任何物品时自动记录到图鉴：

- 获得物品时（购买、收获、钓鱼、采矿、礼品、任务奖励等）自动调用 `discover_item(item_id)`
- 已发现的物品不会重复记录
- 记录发现时间和首次获得时的季节/年份

```
发现触发场景：
├── 购买物品 → 首次购买时
├── 农场收获 → 首次收获该作物
├── 钓鱼获得 → 首次钓到该鱼
├── 采矿获得 → 首次获得该矿石/宝石
├── 战斗掉落 → 首次获得该物品
├── NPC送礼 → 首次送出该物品
├── 任务奖励 → 首次获得该物品
├── 加工产出 → 首次产出该物品
└── 装备获得 → 首次获得该装备
```

#### 2. 成就系统 (Achievement System)

**成就分类**（按类别共120+个成就）：

| 分类 | 数量 | 条件类型示例 |
|------|------|-------------|
| 收集 | 14 | itemCount (5/10/20/30/45/60/80/100/120/150) |
| 农耕 | 6 | cropHarvest (10/50/100/200/500/1000) |
| 钓鱼 | 6 | fishCaught (5/20/50/100/200/500) |
| 采矿 | 10 | mineFloor (5/15/30/45/60/90/100/120), skullCavernFloor |
| 金钱 | 9 | moneyEarned (1000/5000/10000/20000/50000/100000/200000/500000/1000000) |
| 烹饪 | 6 | recipesCooked (5/10/25/50/75/100) |
| 技能等级 | 10 | skillLevel (farming/mining/fishing/foraging/combat 各5/10级) |
| 社交 | 4 | npcFriendship (acquaintance/friendly), npcAllFriendly |
| 任务 | 6 | questsCompleted (5/10/20/40/60/80/100) |
| 好感 | 5 | npcBestFriend (1/2/3/4/6), married, hasChild |
| 战斗 | 8 | monstersKilled (10/50/100/200/300/500/1000/2000) |
| 出货 | 6 | shippedCount (5/10/20/30/50), fullShipment |
| 畜牧 | 6 | animalCount (1/3/5/10/15/20) |
| 育种 | 15 | breedingsDone, hybridsDiscovered, hybridTier, hybridsShipped |
| 博物馆 | 3 | museumDonations (20/36/40) |
| 公会 | 2 | guildGoalsCompleted (5/21) |
| 仙灵 | 6 | hiddenNpcRevealed, hiddenNpcBonded, itemDiscovered |
| 完美度里程碑 | 1 | 达到100%完美度 |

**成就奖励结构**：
```gdscript
struct AchievementReward:
    var money: int = 0           # 金币奖励
    var items: Array[ItemReward] = []  # 物品奖励

struct ItemReward:
    var item_id: String
    var quantity: int
```

#### 3. 祠堂任务 (Community Bundles)

祠堂任务需要向社区中心（祠堂）捐赠指定物品，完成后获得奖励：

**祠堂任务分类**（共35个）：

| 分类 | 数量 | 示例 |
|------|------|------|
| 季节物产 | 4 | 春/夏/秋/冬各季作物的集合 |
| 加工品 | 10 | 匠心/酒/茶/腌制/熏制/蜂蜜/芝士/矿石/百工 |
| 渔获 | 2 | 普通渔获 + 珍稀渔获 |
| 矿石宝石 | 2 | 矿石集合 + 宝石收藏 |
| 畜产品 | 3 | 牧场之礼/百蛋/乳品 |
| 杂交作物 | 6 | 春夏秋冬杂交 + 二代珍品 + 传奇良种 |

**祠堂任务完成流程**：
1. 玩家与祠堂 NPC 交互打开祠堂界面
2. 查看各任务的需求物品和当前进度
3. 将物品从背包拖放到对应任务槽位
4. 系统验证物品数量是否满足要求
5. 满足后自动完成，发放奖励

#### 4. 统计计数器 (Statistics)

系统维护以下持续累积的统计值：

```gdscript
struct AchievementStats:
    total_crops_harvested: int    # 累计收获作物次数
    total_fish_caught: int        # 累计钓到鱼类数量
    total_money_earned: int       # 累计获得金币（含所有来源）
    highest_mine_floor: int       # 矿洞到达最高层
    total_recipes_cooked: int     # 累计烹饪次数
    skull_cavern_best_floor: int  # 骷髅矿穴到达最高层
    total_monsters_killed: int    # 累计击杀怪物数量
    total_breedings_done: int     # 累计完成育种次数
    total_hybrids_discovered: int # 累计发现杂交品种数
    highest_hybrid_tier: int      # 达到的最高杂交代数
```

#### 5. 完美度计算 (Perfection Calculation)

完美度是综合评估玩家游戏进度的百分比指标：

```
perfection_percent = (
    achievement_rate * 0.25 +   # 成就完成率 权重25%
    shipping_rate * 0.20 +      # 出货率 权重20%
    bundle_rate * 0.15 +        # 祠堂任务完成率 权重15%
    collection_rate * 0.15 +    # 物品收集率 权重15%
    skill_rate * 0.15 +         # 平均技能等级 权重15%
    friend_rate * 0.10          # NPC好感度达标率 权重10%
)
```

**各分项计算**：
- `achievement_rate = completed_achievements / total_achievements`
- `shipping_rate = shipped_items_count / shippable_items_count`
- `bundle_rate = completed_bundles / total_bundles`
- `collection_rate = discovered_items / total_items`
- `skill_rate = average_skill_level / 10`
- `friend_rate = friendly_npcs_count / total_npcs`

### States and Transitions

#### Achievement States

```
UNLOCKED → (条件满足) → COMPLETED
```

| 状态 | 描述 | UI显示 |
|------|------|--------|
| Locked | 未完成，显示条件 | 灰色图标 + 进度条 |
| Completed | 已完成 | 金色图标 + 完成时间 |

#### Bundle States

```
NOT_STARTED → (提交物品) → IN_PROGRESS → (全部提交) → COMPLETED
```

| 状态 | 描述 | UI显示 |
|------|------|--------|
| Not Started | 未提交任何物品 | 空槽位 |
| In Progress | 部分完成 | 部分填充 + 物品图标 |
| Complete | 全部物品已提交 | 全部填充 + 完成标记 |

### Interactions with Other Systems

#### 依赖系统 (Upstream Dependencies)

| System | Interface | Usage |
|--------|-----------|-------|
| C03 技能系统 | skill_level, skill_type | 检查技能等级成就 |
| P01 畜牧系统 | animal_count | 检查畜牧相关成就 |
| P02 钓鱼系统 | fish_caught, fish_caught_event | 记录钓鱼统计 |
| P03 采矿系统 | mine_floor_reached | 记录矿洞进度 |
| P04 烹饪系统 | recipes_cooked | 记录烹饪统计 |
| P08 任务系统 | quests_completed | 检查任务成就 |
| C07 NPC好感度 | friendship_level, spouse, children | 检查社交/婚姻成就 |
| P06 商店系统 | shipped_items | 检查出货成就 |
| P07 隐藏NPC | hidden_npc_revealed, hidden_npc_bonded | 检查仙灵成就 |
| P10 公会系统 | guild_goals_completed | 检查公会成就 |
| P11 博物馆系统 | museum_donations | 检查博物馆成就 |
| P12 育种系统 | hybrids_discovered, breedings_done | 检查育种成就 |
| F03 物品数据系统 | item_definitions | 物品ID验证 |

#### 事件订阅 (Event Subscriptions)

成就系统在以下事件发生时检查条件：

```gdscript
# 物品相关
signal item_acquired(item_id: String, quantity: int)
signal item_shipped(item_id: String)
signal item_donated_to_museum(item_id: String)

# 活动相关
signal crop_harvested(crop_id: String)
signal fish_caught(fish_id: String)
signal mine_floor_reached(floor: int)
signal monster_killed(monster_id: String)

# 玩家进度
signal skill_level_up(skill_type: String, new_level: int)
signal quest_completed(quest_id: String)
signal npc_friendship_changed(npc_id: String, level: String)

# 特殊事件
signal married(npc_id: String)
signal child_born()
signal breeding_completed()
signal hybrid_discovered(hybrid_id: String, tier: int)
```

## Formulas

### Perfection Calculation Formula

```
P = (A / A_max) × W_achievement + (S / S_max) × W_shipping + (B / B_max) × W_bundle + (C / C_max) × W_collection + (L_avg / 10) × W_skill + (F / F_max) × W_friendship

Where:
  P = perfection percentage (0-100)
  A = completed achievements count
  A_max = total achievements count (120+)
  S = shipped unique items count
  S_max = total shippable items count
  B = completed bundles count
  B_max = total bundles count (35)
  C = discovered items count
  C_max = total items in game
  L_avg = average skill level across all skills
  F = NPCs at friendly+ level
  F_max = total NPC count

Weights (from Tuning Knobs):
  W_achievement = 0.25  # perfection_achievement_weight
  W_shipping = 0.20     # perfection_shipping_weight
  W_bundle = 0.15       # perfection_bundle_weight
  W_collection = 0.15   # perfection_collection_weight
  W_skill = 0.15        # perfection_skill_weight
  W_friendship = 0.10   # perfection_friendship_weight
```

### Achievement Condition Evaluation

```
is_condition_met(condition) = 
  switch condition.type:
    "itemCount" → discovered_count >= condition.count
    "cropHarvest" → total_crops >= condition.count
    "fishCaught" → total_fish >= condition.count
    "moneyEarned" → total_money >= condition.amount
    "mineFloor" → highest_mine >= condition.floor
    "skullCavernFloor" → skull_best >= condition.floor
    "recipesCooked" → total_cooked >= condition.count
    "skillLevel" → skill_level(skill_type) >= condition.level
    "npcFriendship" → all_npcs >= required_rank
    "questsCompleted" → completed_quests >= condition.count
    "npcBestFriend" → best_friend_count >= condition.count
    "npcAllFriendly" → all_npcs >= friendly
    "married" → spouse != null
    "hasChild" → children.count > 0
    "monstersKilled" → total_kills >= condition.count
    "shippedCount" → shipped_count >= condition.count
    "fullShipment" → shipped_count >= shippable_count
    "animalCount" → animal_count >= condition.count
    "allSkillsMax" → all_skills == 10
    "allBundlesComplete" → bundle_count >= total_bundles
    "hybridsDiscovered" → hybrid_count >= condition.count
    "breedingsDone" → breeding_count >= condition.count
    "hybridTier" → highest_tier >= condition.tier
    "hybridsShipped" → shipped_hybrid_count >= condition.count
    "museumDonations" → donation_count >= condition.count
    "guildGoalsCompleted" → goal_count >= condition.count
    "hiddenNpcRevealed" → revealed_count >= condition.count
    "hiddenNpcBonded" → bonded_npc != null
    "itemDiscovered" → is_discovered(item_id)
```

### Bundle Submission Validation

```
is_bundle_complete(bundle) = 
  all_items = bundle.required_items
  submitted = bundle_submissions[bundle.id]
  
  return all_items.every(item => submitted[item.id] >= item.quantity)
```

## Edge Cases

### 1. 物品发现时机

- **存档迁移**：旧存档中已拥有的装备需要在反序列化时同步到图鉴
- **重复获得**：同一物品多次获得只记录首次发现时间
- **物品消失**：物品被消耗/出售后图鉴记录保留，不受影响

### 2. 成就完成检测

- **同时满足**：多个成就条件在同一时刻满足时，一次性检查并全部完成
- **数值溢出**：统计值使用64位整数防止溢出
- **永久进度**：已完成成就永久标记，不因任何原因重置

### 3. 祠堂任务

- **物品删除**：已提交物品无法取回
- **重复提交**：同一物品可多次提交直到满足数量
- **任务锁定**：部分任务有前置条件（如前置任务完成）

### 4. 完美度

- **数值精度**：最终结果向下取整到整数
- **归零情况**：新游戏完美度从0%开始
- **上限100%**：完美度永远不会超过100%

### 5. 奖励发放

- **背包满**：奖励物品直接发放到仓库，若仓库也满则提示玩家
- **大量金币**：使用 `player.earn_money()` 方法统一处理

## Dependencies

| ID | System Name | Type | Interface |
|----|-------------|------|-----------|
| D01 | C03 SkillSystem | Hard | skill_level signal, skill data access |
| D02 | C07 NPCFriendshipSystem | Hard | friendship level queries, spouse/children state |
| D03 | P01 AnimalHusbandrySystem | Soft | animal_count query |
| D04 | P02 FishingSystem | Hard | fish_caught event, fish database |
| D05 | P03 MiningSystem | Hard | mine_floor_reached event, floor definitions |
| D06 | P04 CookingSystem | Hard | recipes_cooked counter, recipe database |
| D07 | P06 ShopSystem | Hard | shipped_items tracking, shipping UI |
| D08 | P07 HiddenNPCSystem | Soft | hidden_npc_revealed, hidden_npc_bonded queries |
| D09 | P08 QuestSystem | Hard | quest completion tracking |
| D10 | P10 GuildSystem | Soft | guild_goals_completed query |
| D11 | P11 MuseumSystem | Soft | museum_donation_count query |
| D12 | P12 BreedingSystem | Soft | hybrid stats, breeding counters |
| D13 | F03 ItemDataSystem | Hard | item definitions, category data |
| D14 | F04 SaveLoadSystem | Hard | serialize/deserialize state persistence |

## Tuning Knobs

### Achievement Configuration

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `achievement_check_interval` | 0.1 | - | 成就检查频率（秒），设为0则仅在事件触发时检查 |
| `collectible_item_categories` | [见代码] | - | 计入图鉴的物品分类 |
| `shippable_categories` | [见代码] | - | 可出货的物品分类 |

### Perfection Weights

| Component | Weight | Min | Max | Effect at Extreme |
|-----------|--------|-----|-----|------------------|
| `perfection_achievement_weight` | 0.25 | 0 | 0.3 | 成就占比 |
| `perfection_shipping_weight` | 0.20 | 0.1 | 0.25 | 出货占比 |
| `perfection_bundle_weight` | 0.15 | 0.05 | 0.2 | 祠堂任务占比 |
| `perfection_collection_weight` | 0.15 | 0.05 | 0.2 | 物品收集占比 |
| `perfection_skill_weight` | 0.15 | 0.05 | 0.2 | 技能等级占比 |
| `perfection_friendship_weight` | 0.10 | 0.05 | 0.15 | 社交占比 |

### Bundle Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `bundle_submission_delay` | 0.3 | 提交动画时长（秒） |
| `bundle_complete_delay` | 1.0 | 完成庆祝动画时长（秒） |

## Visual/Audio Requirements

### UI Requirements

| Screen | Component | Description |
|--------|-----------|-------------|
| 成就界面 | AchievementTab | 显示所有成就及完成状态 |
| 祠堂界面 | BundlePanel | 显示祠堂任务进度 |
| 图鉴界面 | CollectionTab | 显示物品发现记录 |
| 统计界面 | StatsPanel | 显示各项统计数据 |
| 完美度界面 | PerfectionDisplay | 显示完美度百分比及分项 |

### Visual Feedback

- 成就完成时显示金色获得动画
- 祠堂任务完成时触发社区重建动画
- 完美度达到特定里程碑时触发特殊效果

### Audio Feedback

- 成就解锁：轻快上行的音效
- 祠堂任务完成：社区庆祝音效
- 完美度提升：悠扬的背景音乐变化

## Acceptance Criteria

### Functional Criteria

- [ ] 物品首次获得时自动记录到图鉴
- [ ] 所有120+个成就条件能正确判断完成状态
- [ ] 成就完成时自动发放奖励到玩家背包
- [ ] 祠堂任务物品提交功能正常
- [ ] 祠堂任务完成判定和奖励发放正确
- [ ] 完美度百分比计算准确
- [ ] 所有统计数据正确累积
- [ ] 存档/读档时状态正确保存和恢复
- [ ] 旧存档迁移时能正确补充缺失数据

### Performance Criteria

- [ ] 成就检查响应时间 < 1ms
- [ ] 图鉴查询响应时间 < 5ms
- [ ] 完美度计算响应时间 < 10ms
- [ ] 成就界面加载时间 < 500ms

### Compatibility Criteria

- [ ] 与所有上游依赖系统的事件集成正确
- [ ] 与存档系统的序列化/反序列化兼容
- [ ] 与UI系统的数据显示同步

## Open Questions

| ID | Question | Owner | Target Date |
|----|----------|-------|-------------|
| O1 | **隐藏成就设计**：是否需要隐藏成就（达到条件前不显示）？建议方案：<br/>• 完全隐藏型：条件达成前完全不在UI显示，达成后突然出现（如传说鱼发现）<br/>• 半透明型：显示"？？？"和模糊进度，达成后揭晓（如完美度100%）<br/>• 推荐采用半透明型，保留进度感但保留惊喜 | Designer | Pre-MVP |
| O2 | 完美度100%后是否有额外奖励？ | Designer | Pre-MVP |
| O3 | 是否需要在成就界面显示攻略提示？ | UX | Pre-MVP |
| O4 | 祠堂任务的前置条件如何设计？ | Designer | Pre-MVP |
