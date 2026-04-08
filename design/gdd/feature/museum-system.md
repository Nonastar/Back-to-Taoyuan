# 博物馆系统 (Museum System)

> **Status**: Approved
> **Author**: Claude + User
> **Last Updated**: 2026-04-07
> **Implements Pillar**: 长线追求与完美度目标

## Overview

博物馆系统是游戏中的收藏与探索系统，包含40种可捐赠物品（矿石、宝石、金属锭、化石、古物、仙灵），8个里程碑奖励，以及与考古学家 NPC 的互动。玩家通过向博物馆捐赠各种珍稀物品解锁成就和奖励，最终完成全收藏成为"灵物全鉴"。

## Player Fantasy

博物馆系统给玩家带来**收藏家的满足感**。玩家应该感受到：

- **发现的惊喜** — 挖到稀有矿石、化石时的兴奋
- **展示的骄傲** — 看着博物馆的展柜逐渐填满
- **探索的奖励** — 通过捐赠获得里程碑奖励作为探索的回报
- **完整的成就感** — 完成全部40件收藏时的自豪

**Reference games**: Stardew Valley 博物馆的收集成就感。

## Detailed Design

### Core Rules

#### 1. 博物馆物品 (Museum Items)

博物馆接受40种物品，分为6个类别：

**物品分类**：

| 分类 | 数量 | 物品示例 | 来源提示 |
|------|------|----------|----------|
| 矿石 | 7 | 铜矿、铁矿、金矿、水晶矿、暗影矿、虚空矿、铱矿 | 矿洞各层采集 |
| 宝石 | 7 | 石英、翡翠、红宝石、月光石、黑曜石、龙玉、五彩碎片 | 矿洞各层采集 |
| 金属锭 | 4 | 铜锭、铁锭、金锭、铱锭 | 熔炉冶炼 |
| 化石 | 8 | 三叶虫化石、琥珀、菊石化石、蕨叶化石等 | 宝箱/掉落 |
| 古物 | 10 | 古陶片、玉璧残片、铜镜、远古铜钱等 | 宝箱/采集 |
| 仙灵 | 4 | 狐珠、灵桃、月草、梦丝 | 仙灵赐福 |

**仙灵物品特别说明**：
- 仙灵物品与 P07 隐藏NPC系统深度联动
- `spirit_peach`（灵桃）：桃夭赐福后桃树概率产出
- `moon_herb`（月草）：月兔赐福后采集概率获得
- `dream_silk`（梦丝）：归女赐福后织布机概率产出
- `fox_bead`（狐珠）：矿洞深处获得，与狐仙有关

#### 2. 捐赠流程 (Donation Process)

**捐赠条件**：
1. 物品在博物馆接受列表中
2. 物品未被捐赠过
3. 背包中有该物品

**捐赠流程**：
```
1. 玩家与博物馆 NPC（考古学家）交互
2. 查看当前可捐赠物品列表
3. 选择物品进行捐赠
4. 系统验证：canDonate(itemId)
5. 扣除背包物品：inventory.removeItem(itemId, 1)
6. 添加到已捐赠列表：donatedItems.push(itemId)
7. 触发成就检查
8. 检查里程碑是否可领取
```

#### 3. 里程碑奖励 (Milestone Rewards)

完成捐赠数量里程碑时领取奖励：

**里程碑列表**：

| 计数 | 名称 | 金钱奖励 | 物品奖励 |
|------|------|----------|----------|
| 5 | 初窥门径 | 300g | - |
| 10 | 小有收藏 | 500g | 远古种子×1 |
| 15 | 矿石鉴赏家 | 1000g | - |
| 20 | 博古通今 | 1500g | 五彩碎片×1 |
| 25 | 文物守护者 | 3000g | - |
| 30 | 远古探秘 | 5000g | 铱锭×3 |
| 36 | 博物馆之星 | 10000g | - |
| 40 | 灵物全鉴 | 8000g | 月光石×3 |

**里程碑领取**：
- 捐赠数达到里程碑时自动解锁
- 玩家可随时领取奖励（不必立即）
- 奖励只能领取一次

### States and Transitions

#### 物品捐赠状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Undonated** | 未捐赠 | 初始状态或物品从未捐赠 |
| **Donated** | 已捐赠 | donateItem() 成功 |

**状态转换**：
```
Undonated → Donated: donateItem(itemId) 成功
Donated → (不可逆): 捐赠后永久记录
```

#### 里程碑状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Locked** | 未达成 | donatedCount < milestone.count |
| **Claimable** | 可领取 | donatedCount >= milestone.count 且 未领取 |
| **Claimed** | 已领取 | claimMilestone() 成功 |

**里程碑状态转换**：
```
Locked → Claimable: donateItem() 导致 donatedCount >= count
Claimable → Claimed: claimMilestone(count) 成功
```

### Interactions with Other Systems

#### 依赖系统 (Upstream Dependencies)

| System | Interface | Usage |
|--------|-----------|-------|
| C02 库存系统 | items, hasItem, removeItem | 捐赠物品检查和扣除 |
| C01 玩家属性 | earnMoney | 里程碑金钱奖励 |
| F03 物品数据 | item definitions | 物品验证 |
| P07 隐藏NPC | spirit items from blessings | 仙灵物品来源 |
| P09 成就系统 | museumDonations event | 博物馆相关成就 |
| P03 采矿系统 | fossil drops, ore sources | 物品来源 |

#### 事件订阅 (Event Subscriptions)

```gdscript
# 博物馆系统发出
signal item_donated(item_id: String)
signal milestone_reached(count: int)
signal milestone_claimed(count: int)
signal museum_complete()  # 40件全部捐赠
```

#### API 接口

```gdscript
class_name MuseumSystem extends Node

## 捐赠
func donate_item(item_id: String) -> bool
func can_donate(item_id: String) -> bool
func is_donated(item_id: String) -> bool
func get_donatable_items() -> Array

## 里程碑
func get_donated_count() -> int
func get_total_count() -> int
func get_claimable_milestones() -> Array
func claim_milestone(count: int) -> bool

## 查询
func get_donation_progress() -> Dictionary:
    """返回 {current: int, total: int, percentage: float}"""

## 存档
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

## Formulas

### 1. 捐赠进度

```
donated_count = donatedItems.length
total_count = MUSEUM_ITEMS.length
progress_percentage = donated_count / total_count * 100
```

### 2. 里程碑解锁判定

```
is_milestone_claimable(count) =
    donated_count >= count
    and count not in claimedMilestones
```

### 3. 捐赠完成判定

```
is_museum_complete = donated_count >= 40
```

## Edge Cases

### 1. 物品捐赠边界

- **物品已捐赠**：返回 false，提示"该物品已在展柜中"
- **物品不在列表**：返回 false
- **物品不在背包**：返回 false，提示"背包中没有该物品"

### 2. 里程碑领取边界

- **未达到数量**：返回 false
- **已领取过**：返回 false
- **同时达到多个里程碑**：全部可领取

### 3. 物品重复获得

- **获得已捐赠物品**：仍可保留或出售，不影响博物馆记录
- **捐赠后物品消失**：不影响博物馆记录

### 4. 仙灵物品

- **未解锁仙灵**：物品仍可获得但不显示来源提示
- **已捐赠仙灵物品**：仙灵相关成就正确触发

## Dependencies

| ID | System Name | Type | Interface |
|----|-------------|------|-----------|
| D01 | C02 InventorySystem | Hard | hasItem, removeItem, addItem |
| D02 | C01 PlayerStatsSystem | Hard | earnMoney |
| D03 | F03 ItemDataSystem | Hard | item definitions |
| D04 | P07 HiddenNPCSystem | Soft | spirit item sources |
| D05 | P09 AchievementSystem | Soft | museumDonations event |
| D06 | P03 MiningSystem | Soft | fossil/ore sources |

## Tuning Knobs

### 里程碑配置

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `milestone_5_reward` | 300 | 200-500 | 5件里程碑金钱奖励 |
| `milestone_40_reward` | 8000 | 5000-15000 | 40件里程碑金钱奖励 |
| `milestone_final_item` | moonstone×3 | - | 40件物品奖励 |

### 物品分类配置

| Parameter | Default | Description |
|-----------|---------|-------------|
| `total_museum_items` | 40 | 总物品数 |
| `ore_count` | 7 | 矿石数量 |
| `gem_count` | 7 | 宝石数量 |
| `bar_count` | 4 | 金属锭数量 |
| `fossil_count` | 8 | 化石数量 |
| `artifact_count` | 10 | 古物数量 |
| `spirit_count` | 4 | 仙灵数量 |

## Visual/Audio Requirements

### UI Requirements

| Screen | Component | Description |
|--------|-----------|-------------|
| 博物馆界面 | MuseumView | 主界面，显示展柜和捐赠功能 |
| 展柜面板 | DisplayPanel | 各分类展柜，显示已捐赠/未捐赠物品 |
| 捐赠面板 | DonationPanel | 背包中可捐赠物品列表 |
| 里程碑面板 | MilestonePanel | 捐赠进度和里程碑奖励 |

### Visual Feedback

- 未捐赠物品显示灰色占位符
- 已捐赠物品显示彩色图标
- 新捐赠时物品飞入对应展柜的动画
- 里程碑达成时金色高亮

### Audio Feedback

- 捐赠成功：收藏音效
- 里程碑达成：成就音效
- 博物馆完成：特别庆祝音效

## Acceptance Criteria

### Functional Criteria

- [ ] 40种物品全部可正确识别
- [ ] 捐赠流程正确检查和扣除物品
- [ ] 已捐赠物品永久记录
- [ ] 8个里程碑正确计算和发放
- [ ] 里程碑奖励只能领取一次
- [ ] 存档/读档状态正确保存恢复

### Performance Criteria

- [ ] 捐赠检查响应时间 < 1ms
- [ ] 博物馆界面加载时间 < 500ms

### Compatibility Criteria

- [ ] 与库存系统的物品管理集成
- [ ] 与成就系统的博物馆成就集成
- [ ] 与仙灵物品来源系统联动

## Open Questions

| ID | Question | Owner | Target Date |
|----|----------|-------|-------------|
| O1 | 是否需要博物馆参观者NPC？ | Narrative | Pre-MVP |
| O2 | 博物馆是否有每日/每周任务？ | Designer | Pre-MVP |
| O3 | 博物馆是否解锁特定游戏内容？ | Designer | Pre-MVP |
