# 导航系统 (Navigation System)

> **状态**: In Design
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: C05
> **Implements Pillar**: 游戏流程与时间管理

## Overview

导航系统管理玩家在游戏世界中的地点切换。系统维护5个地点组（farm农场、village_area桃源村、nature野外、mine矿洞、hanhai瀚海），共24个地点面板。玩家在不同地点组之间旅行时消耗时间和体力，同一组内切换无消耗。系统处理就寝时间检查、商店营业时间验证、旅行速度加成（马匹、装备）等。

系统是游戏核心循环的关键基础设施——它连接所有活动系统（农场、钓鱼、采矿、NPC社交等），并通过旅行消耗塑造玩家的时间管理决策。

## Player Fantasy

导航系统给玩家带来**探索的期待感和旅途的仪式感**。玩家应该感受到：

- **旅行的距离感** — 不同地点之间有明显的"路途"感，从农场到矿洞需要更长的时间
- **交通工具的价值** — 拥有马后明显感到旅行变快，这种提升是实实在在的
- **时间的紧迫感** — 每天的时间有限，旅行消耗让玩家权衡是否值得去远处
- **归家的温暖** — 无论走多远，最终都会回到自己的农场

**Reference games**: Stardew Valley 的地点切换让人感到世界的广阔；星露谷物语的马匹升级让远程旅行变得轻松愉快。

## Detailed Design

### Core Rules

1. **地点面板系统**
   - 游戏共有 24 个地点面板，分布在 5 个地点组中
   - 同组内面板切换不消耗时间/体力

2. **地点分组定义**
   | 地点组 | 面板 | 描述 |
   |--------|------|------|
   | farm | farm, animal, home, cottage, workshop, breeding, fishpond | 农场区域 |
   | village_area | village, shop, cooking, upgrade, museum, guild | 桃源村商圈 |
   | nature | forage, fishing | 野外区域 |
   | mine | mining | 矿洞 |
   | hanhai | hanhai | 瀚海沙漠 |

3. **旅行时间消耗** (单位：小时)
   | 起点 → 终点 | farm | village_area | nature | mine | hanhai |
   |-------------|------|--------------|--------|------|--------|
   | farm | 0 | 0.17 (10min) | 0.17 (10min) | 0.33 (20min) | 0.5 (30min) |
   | village_area | 0.17 | 0 | 0.17 | 0.33 | 0.5 |
   | nature | 0.17 | 0.17 | 0 | 0.33 | 0.5 |
   | mine | 0.33 | 0.33 | 0.33 | 0 | 0.5 |
   | hanhai | 0.5 | 0.5 | 0.5 | 0.5 | 0 |

4. **旅行体力消耗**
   | 起点 → 终点 | farm | village_area | nature | mine | hanhai |
   |-------------|------|--------------|--------|------|--------|
   | farm | 0 | 1 | 1 | 2 | 3 |
   | village_area | 1 | 0 | 1 | 2 | 3 |
   | nature | 1 | 1 | 0 | 2 | 3 |
   | mine | 2 | 2 | 2 | 0 | 3 |
   | hanhai | 3 | 3 | 3 | 3 | 0 |

5. **旅行速度加成**
   - **马匹**: 旅行时间 × 0.7，体力消耗向下取整后 ÷2
   - **戒指 (travel_speed)**: 额外时间减免，与马匹叠乘
   - **烹饪buff (speed)**: 减少旅行时间消耗百分比

6. **就寝时间检查**
   - hour >= 26:00 强制昏厥，触发 end_day 流程

7. **商店营业时间**
   | 商店 | 休息日 | 开门时间 | 关门时间 |
   |------|--------|----------|----------|
   | 桃源商圈 | 无 | 6:00 | 24:00 |
   | 工坊 | 周日 | 8:00 | 20:00 |

8. **无地点面板**
   - inventory, skills, achievement, charinfo 为无地点面板
   - 切换到这些面板时暂停游戏时钟

### States and Transitions

### 导航系统状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Idle** | 玩家在当前地点自由活动 | 无旅行进行 |
| **Traveling** | 旅行中（短暂状态） | 调用 travel_to |
| **ShopClosed** | 商店未营业 | 尝试进入 shop/upgrade 面板但未到营业时间 |
| **PastBedtime** | 已过就寝时间 | hour >= 26 |
| **Paused** | 游戏暂停 | 切换到无地点面板 |

### 状态转换图

```
Idle → Traveling: navigateToPanel(targetTab in different group)
Traveling → Idle: 旅行完成，时间和体力已扣除
Idle → ShopClosed: navigateToPanel('shop') but shop closed
Idle → PastBedtime: navigateToPanel() called when hour >= 26
Idle → Paused: navigateToPanel('inventory'|'skills'|'achievement'|'charinfo')
Paused → Idle: navigateToPanel(any game panel)
```

### Interactions with Other Systems

### 系统交互矩阵

| 依赖系统 | 依赖类型 | 输入 | 输出 | 接口说明 |
|----------|----------|------|------|----------|
| **F01 TimeSeasonSystem** | 硬依赖 | - | 时间推进 | 调用 advanceTime() 推进游戏时间 |
| **C01 PlayerStatsSystem** | 硬依赖 | 体力消耗请求 | 体力扣除结果 | 调用 consumeStamina() |
| **C02 InventorySystem** | 软依赖 | 查询戒指效果 | travel_speed 加成值 | getRingEffectValue('travel_speed') |
| **P01 AnimalStore** | 软依赖 | 查询马匹拥有 | 马匹加成 | hasHorse 属性 |
| **P04 CookingSystem** | 软依赖 | 查询 activeBuff | speed buff 值 | activeBuff.type === 'speed' |

### API 设计

```gdscript
class_name NavigationSystem extends Node

## 单例访问
static func get_instance() -> NavigationSystem

## 导航 API
func navigate_to_panel(panel_key: String) -> Dictionary:
    """
    导航到目标面板。
    返回 Dictionary:
      - success: bool
      - time_cost: float (小时)
      - stamina_cost: int
      - message: String
      - passed_out: bool
      - shop_closed: bool
    """

func get_travel_cost(target_tab: String) -> Dictionary:
    """
    查询切换到目标面板的消耗。
    返回 Dictionary:
      - time_cost: float (小时)
      - stamina_cost: int
      - has_travel: bool
    """

func get_current_location_group() -> String:
    """返回当前所在地点组"""

func is_panel_accessible(panel_key: String) -> Dictionary:
    """
    检查面板是否可访问（商店营业时间等）。
    返回 Dictionary:
      - accessible: bool
      - reason: String (如果不可访问)
    """

## 内部 API
func _calculate_travel_time(from_group: String, to_group: String) -> float
func _calculate_stamina_cost(from_group: String, to_group: String) -> int
func _apply_travel_multipliers(base_time: float) -> float
```

## Formulas

### 1. 旅行时间计算

```
base_time = TRAVEL_TIME[`${from_group}->${to_group}`]

# 旅行速度加成叠乘
final_time = base_time × horse_multiplier × ring_multiplier × cooking_multiplier

# horse_multiplier: hasHorse ? 0.7 : 1.0
# ring_multiplier: 1 - travel_speed_ring_bonus (e.g., 0.9 if 10% bonus)
# cooking_multiplier: 1 - speed_buff_pct (e.g., 0.9 if 10% speed buff)
```

### 2. 旅行体力计算

```
base_stamina = TRAVEL_STAMINA[`${from_group}->${to_group}`]

# 马匹体力消耗减半（向上取整后再减半，向下取整）
if has_horse:
    stamina_cost = max(1, base_stamina / 2)
else:
    stamina_cost = base_stamina

# 仙缘灵护减免
stamina_cost = max(1, floor(stamina_cost × (1 - spirit_shield_stamina_save)))
```

### 3. 有效时间消耗（用于 advanceTime）

```
# 速度增益减少时间消耗
effective_hours = hours × (1 - speed_buff_pct)
```

### 4. 午夜提示检查

```
# 跨午夜时只提示一次
if prev_hour < MIDNIGHT_HOUR and new_hour >= MIDNIGHT_HOUR:
    show_midnight_warning = true
```

### 变量定义表

| 变量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `TRAVEL_TIME` | Record | 见规则3 | 基础旅行时间表 |
| `TRAVEL_STAMINA` | Record | 见规则4 | 基础旅行体力表 |
| `MIDNIGHT_HOUR` | int | 24 | 午夜小时 |
| `PASSOUT_HOUR` | int | 26 | 就寝昏厥小时 |
| `HORSE_TIME_MULTIPLIER` | float | 0.7 | 马匹时间倍率 |
| `HORSE_STAMINA_DIVISOR` | int | 2 | 马匹体力除数 |

## Edge Cases

### 1. 体力不足时尝试旅行
- **场景**: 玩家剩余体力不足以支付旅行消耗
- **处理**: 调用 `consume_stamina` 返回 false，阻止旅行，显示提示"体力不足"

### 2. 旅行后超过就寝时间
- **场景**: 旅行消耗时间后 hour >= 26
- **处理**: 立即触发昏厥流程，`passed_out = true`，地点设为 farm

### 3. 跨午夜旅行
- **场景**: 在 23:00 从 farm 旅行到 mine (0.33h)
- **处理**: hour 变为 23:20，跨过午夜但不触发昏厥，只显示午夜警告

### 4. 商店营业时间边界
- **场景**: 刚好在关门时间（20:00）尝试进入工坊
- **处理**: `hour >= closeHour` 返回 closed，提示"已经打烊"

### 5. 连续快速切换面板
- **场景**: 玩家快速点击不同面板
- **处理**: 每次切换独立处理，不排队等待

### 6. 马匹 + 多个加成叠加
- **场景**: 玩家有马 + travel_speed 戒指 + speed buff
- **处理**: 所有加成叠乘：`time × 0.7 × 0.9 × 0.9 = time × 0.567`

### 7. 体力刚好耗尽
- **场景**: 剩余体力正好等于旅行消耗
- **处理**: 旅行成功，体力归零，触发 exhausted 状态

### 8. 旅行到当前所在组
- **场景**: 尝试切换到同组的另一个面板
- **处理**: 无消耗，`time_cost = 0`, `stamina_cost = 0`

## Dependencies

### 上游依赖（C05 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F01** | TimeSeasonSystem | 硬依赖 | 调用 `advanceTime(hours)` 推进时间 |
| **C01** | PlayerStatsSystem | 硬依赖 | 调用 `consumeStamina(amount)` 消耗体力 |

### 下游依赖（其他系统依赖 C05）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **U07** | MapUI | 硬依赖 | 调用 `navigate_to_panel()` 切换地点 |
| **P01-P19** | 所有活动系统 | 硬依赖 | 通过导航系统被玩家访问 |

### 关键接口契约

```gdscript
## 订阅的信号

# F01 TimeSeasonSystem
signal hour_changed(new_hour: int)

## 发出的信号

signal location_changed(new_group: String, old_group: String)
signal travel_started(time_cost: float, stamina_cost: int)
signal travel_completed(panel_key: String)
signal shop_access_denied(panel_key: String, reason: String)
signal past_bedtime()
```

## Tuning Knobs

### 旅行配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `TRAVEL_TIME_FARM_VILLAGE` | 0.17 | 0.1-0.5 | 农场→桃源村 基础时间(小时) |
| `TRAVEL_TIME_FARM_NATURE` | 0.17 | 0.1-0.5 | 农场→野外 基础时间 |
| `TRAVEL_TIME_FARM_MINE` | 0.33 | 0.2-1.0 | 农场→矿洞 基础时间 |
| `TRAVEL_TIME_FARM_HANHAI` | 0.5 | 0.3-1.5 | 农场→瀚海 基础时间 |
| `TRAVEL_STAMINA_FARM_VILLAGE` | 1 | 0-3 | 农场→桃源村 基础体力 |
| `TRAVEL_STAMINA_FARM_MINE` | 2 | 1-5 | 农场→矿洞 基础体力 |
| `TRAVEL_STAMINA_FARM_HANHAI` | 3 | 2-6 | 农场→瀚海 基础体力 |

### 加成配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `HORSE_TIME_MULTIPLIER` | 0.7 | 0.5-0.9 | 马匹时间倍率 |
| `HORSE_STAMINA_DIVISOR` | 2 | 1.5-3.0 | 马匹体力除数(向下取整) |
| `MAX_TRAVEL_SPEED_REDUCTION` | 0.5 | 0.3-0.7 | 戒指最大速度减免 |

### 商店营业时间

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `SHOP_OPEN_HOUR` | 6 | 5-8 | 桃源商圈开门时间 |
| `SHOP_CLOSE_HOUR` | 24 | 22-26 | 桃源商圈关门时间 |
| `WORKSHOP_OPEN_HOUR` | 8 | 7-10 | 工坊开门时间 |
| `WORKSHOP_CLOSE_HOUR` | 20 | 18-22 | 工坊关门时间 |

## Visual/Audio Requirements

### 视觉效果
- **旅行过渡**: 面板切换时无黑屏淡出，直接切换视图
- **地点指示**: HUD 显示当前所在地点组（如"桃源村"）
- **旅行提示**: 旅行消耗显示浮动文本（如"前往矿洞，花了20分钟"）

### 音效
- **点击音效**: 面板切换按钮点击触发 sfxClick
- **旅行音效**: 切换到不同地点组时播放环境过渡音效（farm→mine 播放下山音效）
- **警告音效**: 商店未营业或已过就寝时间触发警告音效

## UI Requirements

### 导航组件
- **底部导航栏**: 24 个面板按钮，带图标和标签
- **地点组显示**: 当前所在地点的文字提示
- **旅行消耗预览**: 悬停/长按显示时间和体力消耗
- **商店状态指示**: 商店按钮显示"休息中"或营业时间

### 交互要求
- **按钮禁用**: 体力不足时旅行按钮变灰
- **快速切换**: 同组面板快速切换无延迟
- **反馈动画**: 按钮点击有缩放反馈

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 同组面板切换无消耗 | farm→animal，验证时间/体力不变 |
| **AC-02** | 跨组旅行正确消耗 | farm→mine，验证时间-0.33h，体力-2 |
| **AC-03** | 马匹加成正确 | 有马时 farm→mine 时间变为 0.23h |
| **AC-04** | 商店营业检查 | 20:00 后尝试进工坊，提示打烊 |
| **AC-05** | 就寝时间阻止 | 26:00 后尝试导航，触发昏厥 |
| **AC-06** | 体力不足阻止 | 体力=1 时尝试 farm→mine，阻止移动 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | 时间推进 | 旅行后验证 gameStore.hour 增加 |
| **CS-02** | 体力消耗 | 旅行后验证 playerStore.stamina 减少 |
| **CS-03** | 时钟暂停 | 切换 inventory，验证时钟暂停 |

### 性能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **PC-01** | 面板切换 < 16ms | 60fps 下切换面板无卡顿 |
| **PC-02** | 旅行计算 < 1ms | getTravelCost 调用时间 |

## Open Questions

| # | 问题 | 状态 | 负责人 | 目标日期 |
|---|------|------|--------|----------|
| **OQ-01** | 是否需要传送道具/技能减少特定旅行时间？ | 待决定 | 策划 | v1.0 |
| **OQ-02** | 瀚海是否有回程传送点？ | 待决定 | 策划 | v1.0 |
| **OQ-03** | 快速旅行（付费传送）是否需要？ | 待决定 | 策划 | v1.0+ |
