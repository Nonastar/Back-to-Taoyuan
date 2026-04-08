# 建筑升级系统 (BuildingUpgradeSystem)

> **状态**: In Design
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: C06
> **Implements Pillar**: 农场发展与基础设施

## Overview

建筑升级系统管理农场的所有基础设施升级，包括农舍等级升级、工具升级、山洞开发、温室解锁、酒窖陈酿等。系统提供升级条件检查、材料消耗、升级效果生效等功能。通过逐步解锁和升级，玩家可以将简陋的茅屋发展成功能完善的家园。

系统是农场发展的核心驱动力——每个升级都解锁新功能或提供属性加成，让玩家感受到"家"的成长与变迁。

## Player Fantasy

建筑升级系统给玩家带来**归属感和成就感**。玩家应该感受到：

- **辛勤劳动的回报** — 攒钱攒材料，看着自己的农场从茅草屋变成气派的庄园
- **解锁新玩法的惊喜** — 每个升级都打开新的可能性（酒窖可以陈酿、温室可以种四季作物）
- **投资的满足感** — 升级投入的资源会在未来持续产出价值
- **定制专属家园** — 山洞可以选择蘑菇洞或水果洞，打造独特的农场风格

**Reference games**: Stardew Valley 的建筑升级让玩家有"家"的感觉；星露谷物语的温室是后期目标。

## Detailed Design

### Core Rules

1. **农舍升级**
   | 等级 | 名称 | 费用 | 材料 | 效果 |
   |------|------|------|------|------|
   | 0→1 | 砖房 | 10,000 | 木材×200 | 厨房解锁，烹饪恢复+20% |
   | 1→2 | 宅院 | 65,000 | 木材×100, 铁矿石×50 | 睡眠恢复+10%体力 |
   | 2→3 | 酒窖 | 100,000 | 木材×100, 金矿石×30 | 酒窖解锁，可陈酿美酒 |

2. **工具升级**
   | 工具 | 等级 | 费用 | 材料 |
   |------|------|------|------|
   | 通用 | 初始→铁 | 2,000 | 铜锭×5 |
   | 通用 | 铁→精钢 | 5,000 | 铁锭×5 |
   | 通用 | 精钢→铱金 | 10,000 | 金锭×5 |
   | 水壶 | 初始→铁 | 1,200 | 铜锭×3 |
   | 鱼竿 | 初始→铁 | 2,000 | 铜锭×5, 木材×5 |
   | 淘金盘 | 初始→铁 | 2,000 | 铜锭×5, 石英×2 |

3. **山洞开发**
   - **解锁条件**: 累计收入达到 25,000
   - **选择类型**: 蘑菇洞 或 水果洞（二选一，之后可升级）
   | 等级 | 名称 | 产出概率 | 双倍概率 | 升级费用 |
   |------|------|----------|----------|----------|
   | 1 | 山洞 | 蘑菇60%/蝙蝠50% | 0% | 免费 |
   | 2 | 山洞·贰 | 蘑菇70%/蝙蝠60% | 0% | 15,000 + 木材×100 + 铁锭×5 |
   | 3 | 山洞·叁 | 蘑菇80%/蝙蝠70% | 25% | 40,000 + 木材×200 + 金锭×10 |

4. **山洞品质提升**
   | 累计天数 | 产出品质 |
   |----------|----------|
   | 0天 | 普通 |
   | 56天 | 优良 |
   | 112天 | 优秀 |
   | 224天 | 极品 |

5. **温室解锁**
   - **费用**: 35,000 + 木材×200 + 铁矿石×30 + 金矿石×10
   - **基础地块**: 12个
   - **升级1**: 50,000 → 20个地块（5×4）
   - **升级2**: 100,000 → 30个地块（6×5）

6. **酒窖陈酿**
   - **解锁**: 农舍等级3
   - **可陈酿物品**: 各类果酒、料酒
   - **增值周期**: 7天/次
   - **每次增值**: 100铜钱（可升级）
   | 酒窖等级 | 每次增值 | 最大槽位 |
   |----------|----------|----------|
   | 1 | +100 | 6 |
   | 2 | +125 | 9 |
   | 3 | +150 | 12 |
   | 4 | +175 | 15 |
   | 5 | +200 | 18 |

7. **仓库解锁**
   - **材料**: 木材×300 + 铁矿石×20

### States and Transitions

### 建筑升级系统状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **FarmhouseLevel0** | 茅屋阶段 | 初始状态，无厨房 |
| **FarmhouseLevel1** | 砖房阶段 | 农舍升至Lv1，厨房可用 |
| **FarmhouseLevel2** | 宅院阶段 | 农舍升至Lv2，睡眠恢复+10% |
| **FarmhouseLevel3** | 酒窖阶段 | 农舍升至Lv3，酒窖可用 |
| **CaveLocked** | 山洞锁定 | 未满足累计收入条件 |
| **CaveActive** | 山洞运行中 | 已选择蘑菇洞或水果洞 |
| **GreenhouseLocked** | 温室锁定 | 未解锁温室 |
| **GreenhouseActive** | 温室运行中 | 温室已解锁 |
| **CellarActive** | 酒窖运行中 | 农舍Lv3+，有陈酿槽位 |

### 状态转换图

```
FarmhouseLevel0 → FarmhouseLevel1: 升级农舍成功
FarmhouseLevel1 → FarmhouseLevel2: 升级农舍成功
FarmhouseLevel2 → FarmhouseLevel3: 升级农舍成功
CaveLocked → CaveActive: 累计收入≥25000 且 选择山洞类型
CaveActive → CaveActive: 升级山洞成功
GreenhouseLocked → GreenhouseActive: 解锁温室成功
```

### Interactions with Other Systems

### 系统交互矩阵

| 依赖系统 | 依赖类型 | 输入 | 输出 | 接口说明 |
|----------|----------|------|------|----------|
| **F03 ItemDataSystem** | 硬依赖 | - | 物品定义 | 查询材料ID、物品名 |
| **C02 InventorySystem** | 硬依赖 | 材料检查/扣除 | 结果 | 检查材料数量、扣除物品 |
| **C01 PlayerStatsSystem** | 软依赖 | 费用支付/睡眠恢复 | 属性加成 | spendMoney()、stamina recovery |
| **C04 FarmPlotSystem** | 硬依赖 | 温室地块初始化 | 温室地块 | initGreenhouse() |
| **P04 CookingSystem** | 软依赖 | 厨房加成查询 | 恢复倍率 | getKitchenBonus() |

### API 设计

```gdscript
class_name BuildingUpgradeSystem extends Node

## 单例访问
static func get_instance() -> BuildingUpgradeSystem

## 农舍升级 API
func upgrade_farmhouse() -> bool:
    """升级农舍，返回是否成功"""

func get_farmhouse_level() -> int
func get_next_farmhouse_upgrade() -> FarmhouseUpgradeDef | null

## 工具升级 API
func upgrade_tool(tool_type: String, from_tier: String) -> bool:
    """升级工具，返回是否成功"""

func get_tool_upgrade_cost(tool_type: String, current_tier: String) -> ToolUpgradeCost | null

## 山洞 API
func is_cave_unlocked() -> bool
func can_unlock_cave() -> bool:
    """检查累计收入是否满足"""

func unlock_cave() -> bool
func choose_cave_type(type: String) -> bool:
    """选择山洞类型：'mushroom' 或 'fruit_bat'"""

func upgrade_cave() -> bool
func get_cave_daily_output() -> Array[Dictionary]:
    """获取山洞每日产出"""

## 温室 API
func is_greenhouse_unlocked() -> bool
func unlock_greenhouse() -> bool

## 酒窖 API
func has_cellar() -> bool:
    """农舍等级是否≥3"""

func start_aging(item_id: String, quality: String) -> bool:
    """放入物品进行陈酿"""

func remove_aging(slot_index: int) -> Dictionary | null:
    """取出陈酿物品，返回 {itemId, quality, addedValue}"""

func get_cellar_slots() -> Array
func get_cellar_max_slots() -> int

## 仓库 API
func is_warehouse_unlocked() -> bool
func unlock_warehouse() -> bool

## 属性加成查询
func get_kitchen_bonus() -> float:
    """返回烹饪体力恢复加成"""

func get_stamina_recovery_bonus() -> float:
    """返回睡眠体力恢复加成"""

## 存档接口
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

## Formulas

### 1. 工具时间减免

```
# 工具等级每级减少行动时间
actual_minutes = max(MIN_ACTION_MINUTES, base_minutes - tool_time_savings[tool_tier])

# tool_time_savings: basic=0, iron=10, steel=20, iridium=30
```

### 2. 山洞产出计算

```
# 产出判定
if random() < daily_chance:
    if cave_type == 'mushroom':
        # 按权重随机选择蘑菇
        item = weighted_random_select(mushroom_pool)
    else:
        # 随机选择水果
        item = random_select(fruit_pool)

    # 双倍判定
    quantity = random() < double_chance ? 2 : 1

    return { item_id: item, quantity, quality: cave_quality }
```

### 3. 山洞品质计算

```
# 根据累计活跃天数确定品质
cave_quality = 'normal'
for threshold in CAVE_QUALITY_THRESHOLDS:
    if days_active >= threshold.days:
        cave_quality = threshold.quality
```

### 4. 酒窖增值计算

```
# 每7天增值一次
if slot.days_aging >= CELLAR_VALUE_CYCLE_DAYS:
    slot.added_value += cellar_value_per_cycle
    slot.upgrade_count++
    slot.days_aging = 0
```

### 5. 睡眠恢复加成

```
# 基础恢复 + 房屋加成
final_recovery = min(base_recovery + house_stamina_bonus, 1.0)

# house_stamina_bonus: farmhouse_level >= 2 ? 0.1 : 0
```

### 6. 厨房加成

```
# 烹饪体力恢复加成
kitchen_bonus = farmhouse_level >= 1 ? 1.2 : 1.0
```

### 变量定义表

| 变量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `MIN_ACTION_MINUTES` | int | 10 | 行动最低时间（分钟） |
| `TOOL_TIME_SAVINGS` | Record | 见规则1 | 工具等级时间减免 |
| `CELLAR_VALUE_CYCLE_DAYS` | int | 7 | 酒窖增值周期 |
| `CAVE_UNLOCK_EARNINGS` | int | 25,000 | 山洞解锁累计收入 |
| `KITCHEN_BONUS` | float | 1.2 | 厨房体力恢复倍率 |
| `STAMINA_RECOVERY_BONUS` | float | 0.1 | 宅院睡眠恢复加成 |

## Edge Cases

### 1. 升级时材料不足
- **场景**: 玩家尝试升级但材料不够
- **处理**: 返回 false，UI 显示所需材料及已有数量

### 2. 升级时金钱不足
- **场景**: 玩家尝试升级但金钱不够
- **处理**: 返回 false，提示"金钱不足"

### 3. 山洞类型已选择
- **场景**: 玩家已经选择了蘑菇洞/水果洞，尝试再次选择
- **处理**: 返回 false，只能升级不能重新选择

### 4. 酒窖槽位已满
- **场景**: 所有陈酿槽位都有物品
- **处理**: start_aging 返回 false，提示"酒窖已满"

### 5. 放入不可陈酿物品
- **场景**: 尝试放入酒窖不支持的物品
- **处理**: 返回 false，只有特定酒类可以陈酿

### 6. 农舍未达等级时访问酒窖
- **场景**: 农舍Lv2时尝试打开酒窖UI
- **处理**: UI 隐藏酒窖入口，或显示"需要酒窖"

### 7. 温室解锁后旧存档
- **场景**: 加载未解锁温室的旧存档
- **处理**: deserialize 时检查 greenhouseUnlocked 标志

### 8. 山洞品质永久提升
- **场景**: 玩家知道品质随时间提升后，故意不收获等待品质提升
- **处理**: 这是预期行为，不做限制

### 9. 工具已升至最高级
- **场景**: 尝试升级已经是 iridium 级的工具
- **处理**: getUpgradeCost 返回 null，UI 隐藏升级按钮

### 10. 酒窖取出时增值未完成
- **场景**: 物品放入不足7天就取出
- **处理**: 取出时 addedValue=0，物品品质不变

## Dependencies

### 上游依赖（C06 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F03** | ItemDataSystem | 硬依赖 | 查询物品ID、名称定义 |
| **C02** | InventorySystem | 硬依赖 | 检查/扣除材料，检查/添加物品 |
| **C01** | PlayerStatsSystem | 软依赖 | 支付升级费用，查询睡眠恢复加成 |

### 下游依赖（其他系统依赖 C06）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **C01** | PlayerStatsSystem | 软依赖 | getStaminaRecoveryBonus() |
| **C04** | FarmPlotSystem | 硬依赖 | 温室地块管理 |
| **P04** | CookingSystem | 软依赖 | getKitchenBonus() |
| **F04** | SaveLoadSystem | 硬依赖 | 存档所有升级状态 |

### 关键接口契约

```gdscript
## 订阅的信号

# C01 PlayerStatsSystem
signal money_changed(amount: int)  # 用于检测山洞解锁条件

# F01 TimeSeasonSystem
signal day_changed(day: int)  # 用于酒窖/山洞每日更新

## 发出的信号

signal farmhouse_upgraded(new_level: int)
signal tool_upgraded(tool_type: String, new_tier: String)
signal cave_unlocked()
signal cave_type_chosen(type: String)
signal cave_upgraded(new_level: int)
signal cave_output_generated(output: Array)
signal greenhouse_unlocked()
signal cellar_aging_started(slot_index: int)
signal cellar_aging_completed(slot_index: int)
signal cellar_item_removed(slot_index: int, added_value: int)
signal warehouse_unlocked()
```

## Tuning Knobs

### 农舍升级配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `FARMHOUSE_LEVEL1_COST` | 10,000 | 5,000-50,000 | 砖房升级费用 |
| `FARMHOUSE_LEVEL2_COST` | 65,000 | 30,000-150,000 | 宅院升级费用 |
| `FARMHOUSE_LEVEL3_COST` | 100,000 | 50,000-200,000 | 酒窖升级费用 |
| `KITCHEN_BONUS` | 1.2 | 1.1-1.5 | 厨房体力恢复倍率 |
| `STAMINA_RECOVERY_BONUS` | 0.1 | 0.05-0.2 | 宅院睡眠恢复加成 |

### 山洞配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `CAVE_UNLOCK_EARNINGS` | 25,000 | 10,000-100,000 | 山洞解锁累计收入 |
| `CAVE_QUALITY_DAY_FINE` | 56 | 28-112 | 优良品质天数 |
| `CAVE_QUALITY_DAY_EXCELLENT` | 112 | 56-224 | 优秀品质天数 |
| `CAVE_QUALITY_DAY_SUPREME` | 224 | 112-448 | 极品品质天数 |

### 温室配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `GREENHOUSE_UNLOCK_COST` | 35,000 | 20,000-100,000 | 温室解锁费用 |
| `GREENHOUSE_BASE_PLOTS` | 12 | 6-24 | 基础温室地块数 |
| `GREENHOUSE_UPGRADE1_PLOTS` | 20 | 12-36 | 温室升级1地块数 |
| `GREENHOUSE_UPGRADE2_PLOTS` | 30 | 24-48 | 温室升级2地块数 |

### 酒窖配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `CELLAR_VALUE_CYCLE_DAYS` | 7 | 3-14 | 酒窖增值周期 |
| `CELLAR_BASE_VALUE` | 100 | 50-200 | 基础每次增值 |
| `CELLAR_MAX_SLOTS_LV1` | 6 | 4-12 | 酒窖等级1最大槽位 |
| `CELLAR_MAX_SLOTS_LV5` | 18 | 12-24 | 酒窖等级5最大槽位 |

## Visual/Audio Requirements

### 视觉效果
- **升级动画**: 建筑升级时播放建设动画（如尘土飞扬、结构变化）
- **解锁特效**: 温室/酒窖解锁时播放金色光芒特效
- **山洞产出**: 每日产出时显示物品图标和品质颜色

### 音效
- **升级音效**: 升级成功播放建筑音效
- **解锁音效**: 新功能解锁播放成就解锁音效
- **陈酿音效**: 放入/取出酒窖物品播放木桶音效

## UI Requirements

### 升级界面
- **农舍升级面板**: 显示当前等级、下级升级费用和材料需求
- **工具升级面板**: 各工具当前等级和升级按钮
- **山洞面板**: 解锁条件显示、类型选择（蘑菇洞/水果洞）、升级选项
- **温室面板**: 解锁状态、当前地块数、扩建选项
- **酒窖面板**: 陈酿槽位显示、放入/取出操作、增值进度

### 交互要求
- **材料显示**: 显示需求数量和已有数量，不足时变红
- **升级预览**: 悬停显示升级后的效果
- **批量操作**: 酒窖支持批量取出

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 农舍升级成功 | 消耗材料和金钱，验证等级提升 |
| **AC-02** | 工具升级成功 | 消耗材料和金钱，验证工具等级变化 |
| **AC-03** | 山洞解锁条件 | 累计收入达到25000后验证可解锁 |
| **AC-04** | 山洞类型选择 | 选择后验证产出池变化 |
| **AC-05** | 温室解锁 | 消耗材料后温室地块可用 |
| **AC-06** | 酒窖陈酿 | 放入物品，7天后取出验证增值 |
| **AC-07** | 仓库解锁 | 消耗材料后仓库格子增加 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | 睡眠恢复加成 | 农舍Lv2+睡觉后验证体力恢复+10% |
| **CS-02** | 厨房加成 | 农舍Lv1+烹饪后验证体力恢复+20% |
| **CS-03** | 温室地块 | 解锁温室后验证可种植 |
| **CS-04** | 存档完整 | 保存后加载验证所有状态恢复 |

### 性能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **PC-01** | 升级检查 < 5ms | 检查材料和金钱的时间 |
| **PC-02** | 每日更新 < 10ms | 酒窖/山洞日结算时间 |

## Open Questions

| # | 问题 | 状态 | 负责人 | 目标日期 |
|---|------|------|--------|----------|
| **OQ-01** | 农舍是否可以多次升级到更高等级？ | 待决定 | 策划 | v1.0 |
| **OQ-02** | 工具升级是否需要考虑武器？ | 待决定 | 策划 | v1.0 |
| **OQ-03** | 山洞是否可以在升级后切换类型？ | 待决定 | 策划 | v1.0 |
