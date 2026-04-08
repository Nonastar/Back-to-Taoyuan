# 钓鱼系统 (Fishing System)

> **状态**: Approved
> **Author**: Claude Code
> **Last Updated**: 2026-04-07
> **System ID**: P02
> **Implements Pillar**: 农场经营与农业系统

## Overview

钓鱼系统为玩家提供丰富的水产资源获取途径。系统包含60种鱼类，分布在6个不同的钓鱼地点，每个地点有不同的鱼种、出现季节和时间段。玩家使用鱼竿和鱼饵进行钓鱼，通过"时机小游戏"控制收杆时机，成功钓到鱼类后存入背包。钓鱼系统是游戏休闲收入的重要来源，同时提供鱼塘养殖（P13）和博物馆捐赠（P11）等下游玩法。

## Player Fantasy

钓鱼系统给玩家带来**宁静中的期待与惊喜的满足感**。玩家应该感受到：

- **等待的艺术** — 抛竿入水，看着浮标静静等待，这种宁静本身就是享受
- **时机的把握** — 屏息凝神，在浮标下沉的瞬间精准提竿
- **收获的惊喜** — 期待普通鲫鱼，却钓上了传说级的锦鲤
- **收集的成就** — 博物馆里逐渐填满的鱼类图鉴，记录着每一次下竿的回忆

**Reference games**: Stardew Valley 的钓鱼简单但上瘾；动物森友会的鱼类图鉴收集让人欲罢不能。

## Detailed Design

### Core Rules

#### 1. 钓鱼地点（6个）

| 地点 ID | 地点名称 | 可钓鱼类 | 解锁条件 |
|---------|----------|----------|----------|
| `forest_pond` | 森林池塘 | 溪流鱼类 | 初始解锁 |
| `river` | 河流 | 河鱼 | 初始解锁 |
| `mountain_lake` | 山顶湖泊 | 冷水鱼 | 到达山区 |
| `ocean` | 海洋 | 海水鱼 | 初始解锁 |
| `witch_swamp` | 女巫沼泽 | 沼泽鱼 | 完成女巫任务 |
| `secret_pond` | 秘密池塘 | 传说鱼 | 到达秘密地点 |

#### 2. 鱼类分类（按稀有度）

| 稀有度 | 说明 | 捕获难度 | 示例 |
|--------|------|----------|------|
| **普通** | 常见鱼类 | 低 | 鲫鱼、小龙虾 |
| **优质** | 不太常见 | 中 | 鲤鱼、鳜鱼 |
| **精品** | 稀有 | 高 | 金鱼、鳗鱼 |
| **传说** | 极稀有 | 极高 | 锦鲤、金龙鱼 |

#### 3. 季节与时间分布

- **春季**: 春季鱼类为主，部分全年鱼类
- **夏季**: 夏季鱼类丰富，鱼更活跃
- **秋季**: 秋季鱼类，部分鱼类迁徙
- **冬季**: 冰雪鱼类，冰钓特殊规则

**每日时间段**:
- **早晨** (6:00-12:00): 日出鱼类
- **中午** (12:00-18:00): 常规鱼类
- **傍晚** (18:00-24:00): 夜行鱼类
- **深夜** (0:00-6:00): 稀有夜行鱼

#### 4. 鱼竿系统

| 鱼竿 | 获取方式 | 特殊能力 |
|------|----------|----------|
| **竹竿** | 初始赠送 | 无 |
| **玻璃钢竿** | 商店购买 | 可装鱼饵 |
| **钛合金竿** | 商店购买 | 抛竿距离+2 |
| **传说鱼竿** | 任务奖励 | 所有加成 |

#### 5. 鱼饵系统

| 鱼饵类型 | 效果 | 获取方式 |
|----------|------|----------|
| **普通饵料** | 基础效果 | 商店购买、虫子 |
| **美味饵料** | 咬钩率+20% | 制作 |
| **传说饵料** | 咬钩率+50%，传说鱼概率+10% | 特殊来源 |

#### 6. 钓鱼小游戏机制

钓鱼小游戏是钓鱼系统的核心玩法：

```
1. 抛竿后，浮标在水中浮动
2. 鱼咬钩时，浮标下沉或剧烈晃动
3. 玩家需在正确时机按下提竿按钮
4. 提竿后，进入"搏鱼"阶段
5. 玩家需保持鱼在绿色区域中
6. 鱼的力量条消耗完毕后，成功捕获
```

#### 7. 时机判定

| 浮标状态 | 提竿时机 | 结果 |
|----------|----------|------|
| 轻微晃动 | 最佳时机 | +成功率 |
| 剧烈晃动 | 正常时机 | 正常成功率 |
| 即将消失 | 太晚 (too_late) | 失败 |
| 未咬钩时提竿 | 太早 (too_early) | 吓跑鱼 |

> **注**：时机判定由 M01 钓鱼小游戏实现，本表为宏观行为描述。

#### 8. 搏鱼机制

成功提竿后，进入搏鱼阶段：
- **鱼的力量条**: 鱼会左右冲刺消耗力量
- **玩家的收线条**: 玩家控制，收线快但压力大
- **目标区域**: 保持鱼在绿色区域
- **失败条件**: 压力条满或鱼挣脱

#### 9. 品质判定

鱼类品质由以下因素决定：
- 钓鱼技能等级 (C03)
- 鱼饵类型
- 钓鱼地点
- 天赋加成 (angler 传说鱼概率大幅提升, mariner 最低精品)

### States and Transitions

#### 钓鱼状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **Idle** | 待机 | 未抛竿 |
| **Waiting** | 等待中 | 浮标在水面 |
| **Bite** | 鱼咬钩 | 浮标下沉 |
| **Reeling** | 搏鱼中 | 提竿后 |
| **Success** | 捕获成功 | 力量条耗尽 |
| **Failed** | 捕获失败 | 脱钩或逃逸 |

**状态转换图**:
```
Idle → Waiting: 抛竿
Waiting → Bite: 鱼咬钩（随机时间 2-10秒）
Bite → Reeling: 玩家提竿
Bite → Idle: 提竿太晚，鱼逃跑
Bite → Idle: 提竿太早，吓跑鱼
Reeling → Success: 力量条耗尽
Reeling → Failed: 压力条满或鱼挣脱
Waiting → Idle: 取消抛竿
```

#### 鱼类出现状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **Available** | 可钓 | 季节+时间+地点匹配 |
| **SeasonLocked** | 季节不符 | 当前季节无法出现 |
| **TimeLocked** | 时间不符 | 当前时间段无法出现 |
| **Caught** | 已捕获 | 当日已捕获传说鱼 |

### Interactions with Other Systems

**上游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **C02 InventorySystem** | 硬依赖 | 鱼存入背包、消耗鱼饵 |
| **F03 ItemDataSystem** | 硬依赖 | 鱼类定义、鱼饵定义、地点数据 |
| **C01 PlayerStatsSystem** | 硬依赖 | 体力消耗、钓鱼小游戏状态 |
| **C03 SkillSystem** | 硬依赖 | 钓鱼技能等级加成 |
| **M01 FishingMiniGame** | 硬依赖 | 时机小游戏和搏鱼小游戏实现 |

**下游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **P09 AchievementSystem** | 软依赖 | 钓鱼成就（钓到X条鱼等） |
| **P11 MuseumSystem** | 软依赖 | 鱼类捐赠到博物馆 |
| **P13 FishPondSystem** | 软依赖 | 鱼塘放养 |

### 提供给下游的 API

```gdscript
class_name FishingSystem extends Node

## 单例访问
static func get_instance() -> FishingSystem

## 钓鱼操作
func cast_rod(location_id: String) -> bool:
    """抛竿，返回是否成功"""

func reel_fish() -> Dictionary:
    """提竿，返回 {success, fish_id, quality}"""

func cancel_fishing() -> bool:
    """取消钓鱼"""

## 查询
func get_available_fish(location_id: String, season: String, hour: int) -> Array[FishDef]:
    """获取当前可钓的鱼类列表"""

func get_rod_info() -> Dictionary:
    """获取当前鱼竿信息"""

func get_bait_count() -> int:
    """获取鱼饵数量"""

## 状态查询
func get_fishing_state() -> String:
    """获取当前钓鱼状态"""

func get_current_bite_progress() -> float:
    """获取当前咬钩进度 (0.0-1.0)"""

func get_fish_stamina() -> float:
    """获取鱼的力量条 (0.0-1.0)"""

func get_player_pressure() -> float:
    """获取玩家压力条 (0.0-1.0)"""

func has_talent(perk_id: String) -> bool:
    """检查是否拥有指定天赋 (调用 C03 SkillSystem)"""
```

## Formulas

### 1. 咬钩时间公式

```
# 基础咬钩时间（秒）
base_bite_time = random(2.0, 10.0)

# 鱼饵加成
bait_multiplier = {
    "none": 1.0,
    "common": 0.9,
    "deluxe": 0.8,
    "legendary": 0.6
}

# 技能加成
skill_reduction = 1.0 - (fishing_skill_level * 0.02)

# 最终咬钩时间
final_bite_time = base_bite_time * bait_multiplier * skill_reduction
```

### 2. 咬钩成功率公式

```
# 基础咬钩率
base_bite_chance = 0.60

# 鱼饵加成
bait_bonus = {
    "none": 0.0,
    "common": 0.10,
    "deluxe": 0.20,
    "legendary": 0.50
}

# 季节加成
season_bonus = {
    "spring": 0.0,
    "summer": 0.05,  # 鱼更活跃
    "fall": 0.0,
    "winter": -0.05  # 鱼不活跃
}

# 时机加成 (与 M01 统一命名)
timing_bonus = {
    "perfect": 0.15,  # 最佳时机 (M01: "perfect")
    "normal": 0.0,
    "too_early": -0.30,   # 太早
    "too_late": -0.50     # 太晚
}

# 最终成功率
final_bite_success = base_bite_chance + bait_bonus + season_bonus + timing_bonus
final_bite_success = clamp(final_bite_success, 0.05, 0.95)
```

### 3. 搏鱼难度公式

```
# 基础难度系数
base_difficulty = fish.difficulty  # 1-10

# 技能降低难度
skill_reduction = fishing_skill_level * 0.1

# 鱼竿加成
rod_bonus = {
    "bamboo": 0.0,
    "fiberglass": -0.2,
    "titanium": -0.4,
    "legendary": -0.6
}

# 最终难度
final_difficulty = base_difficulty - skill_reduction + rod_bonus
final_difficulty = clamp(final_difficulty, 0.5, 10.0)
```

### 4. 搏鱼力量消耗公式

```
# 每次按键消耗的鱼力量
stamina_drain_per_tap = 0.05

# 技能加成
skill_bonus = 1.0 + (fishing_skill_level * 0.02)

# 鱼竿加成
rod_bonus = {
    "bamboo": 1.0,
    "fiberglass": 1.1,
    "titanium": 1.2,
    "legendary": 1.3
}

# 成功一次按键消耗
drain_amount = stamina_drain_per_tap * skill_bonus * rod_bonus

# 鱼脱离条件
if player_pressure >= 1.0:
    fish_escapes = true
```

### 5. 品质判定公式

```
# 基础高品质概率
base_quality_chance = 0.10  # 10%

# 技能加成
skill_bonus = fishing_skill_level * 0.02

# 天赋加成 (C03 SkillSystem)
if has_talent("mariner"):
    min_quality = "excellent"  # 最低精品
else:
    min_quality = "normal"

# 传说鱼品质固定为精品
if fish.rarity == "legendary":
    quality = "excellent"
else:
    roll = random(0.0, 1.0)
    if roll < (base_quality_chance + skill_bonus):
        quality = "excellent"
    elif roll < (base_quality_chance + skill_bonus + 0.15):
        quality = "fine"
    else:
        quality = "normal"

# 应用最低品质
quality = max(quality, min_quality)
```

### 6. 鱼类刷新公式

```
# 每小时鱼类刷新
if hour in fish.available_hours:
    # 检查季节
    if season in fish.available_seasons:
        spawn_weight = fish.spawn_weight
        if fish.rarity == "legendary" and fish.caught_today:
            spawn_weight = 0  # 传说鱼每天只能一条
```

### 7. 体力消耗公式

```
# 钓鱼基础体力消耗
base_stamina = 2

# 技能减免 (C01)
skill_reduction = 1.0 - (fishing_skill_level * 0.01)

# 装备减免 (C08)
equipment_bonus = get_equipment_bonus("fishing_stamina_reduction")

# 最终消耗
final_stamina = max(1, floor(base_stamina * skill_reduction * (1 - equipment_bonus)))
```

### 公式变量表

| 变量名 | 类型 | 范围 | 说明 |
|--------|------|------|------|
| `base_bite_time` | float | 2.0-10.0 | 基础咬钩时间（秒） |
| `final_bite_time` | float | 1.0-10.0 | 最终咬钩时间 |
| `final_bite_success` | float | 0.05-0.95 | 最终咬钩成功率 |
| `final_difficulty` | float | 0.5-10.0 | 最终搏鱼难度 |
| `stamina_drain_per_tap` | float | 0.05 | 每次按键消耗鱼力量 |
| `player_pressure` | float | 0.0-1.0 | 玩家压力条 |
| `fishing_skill_level` | int | 0-10 | 钓鱼技能等级 |
| `fish_stamina` | float | 0.0-1.0 | 鱼的力量条 |
| `final_stamina` | int | 1+ | 最终体力消耗 |

### 预期产出范围

| 鱼种类型 | 售价范围 | 传说鱼概率 | 传说鱼售价 |
|----------|----------|------------|------------|
| 普通 | 30-80g | - | - |
| 优质 | 100-200g | - | - |
| 精品 | 300-500g | - | - |
| 传说 | - | 1-3% | 1000-5000g |

## Edge Cases

### 1. 钓鱼时机边界情况

| 情况 | 处理方式 |
|------|----------|
| 提竿太早（鱼未咬钩）(too_early) | 吓跑鱼，显示"鱼被吓跑了"提示 |
| 提竿太晚（浮标消失）(too_late) | 鱼逃跑，显示"太晚了，鱼跑了"提示 |
| 连续多次太早提竿 | 鱼类出现概率暂时降低 |
| 完美时机提竿 (perfect) | 成功率+15%加成 |

### 2. 搏鱼边界情况

| 情况 | 处理方式 |
|------|----------|
| 压力条满（持续收线） | 鱼挣脱，钓鱼失败 |
| 鱼在绿色区域外太久 | 压力条快速上升 |
| 按键过快 | 无效按键，不消耗鱼力量 |
| 按键过慢 | 鱼恢复少量力量 |
| 传说鱼脱钩 | 当日传说鱼不再出现 |

### 3. 物品边界情况

| 情况 | 处理方式 |
|------|----------|
| 背包已满 | 鱼存入临时背包，提示需要整理 |
| 没有鱼饵 | 竹竿可以无饵钓鱼（咬钩率降低） |
| 没有鱼竿 | 无法进入钓鱼模式 |
| 背包和临时背包都满 | 钓鱼失败，提示背包空间不足 |

### 4. 地点边界情况

| 情况 | 处理方式 |
|------|----------|
| 到达未解锁地点 | 显示锁定提示，需要完成前置任务 |
| 地点鱼类全季节限定 | 不在该季节时，显示"这里没有鱼" |
| 深夜钓鱼 | 某些鱼类只在深夜出现（特殊体验） |
| 天气影响 | 暴风雨时钓鱼难度+20%（未来 F02 天气系统） |

### 5. 传说鱼类边界情况

| 情况 | 处理方式 |
|------|----------|
| 传说鱼脱钩 | 当日不再刷新该传说鱼 |
| 传说鱼存入背包满 | 存入临时背包（传说鱼不会消失） |
| 传说鱼任务限制 | 某些传说鱼需要特定任务才能出现 |

### 6. 体力边界情况

| 情况 | 处理方式 |
|------|----------|
| 体力不足 | 无法抛竿，显示"体力不足"提示 |
| 钓鱼中体力耗尽 | 强制结束钓鱼，鱼逃跑 |
| 体力极低（<5） | 禁止钓鱼，必须休息 |

### 7. 多日不上线处理

当玩家多日不上线时：
```
1. 钓鱼小游戏：不需要每日刷新
2. 鱼类刷新：上线时重新计算可用鱼类
3. 传说鱼刷新：每日限制重置
```

### 8. 特殊鱼类边界

| 情况 | 处理方式 |
|------|----------|
| 蟹类（不是鱼） | 特殊处理，作为鱼类收集 |
| 海星、贝壳类 | 作为水产收集，不走钓鱼流程 |
| 钓鱼小游戏出现虫 | 随机事件，可选择收集或放生 |

### 9. 钓鱼小游戏辅助功能

| 功能 | 说明 |
|------|------|
| 辅助模式 | 简化时机判定，绿色区域更大 |
| 关闭小游戏 | 高钓技等级时可跳过，直接判定结果 |
| 触摸屏支持 | 拖拽替代按键操作 |

## Dependencies

### 上游依赖

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **C02** | InventorySystem | 硬依赖 | 鱼存入背包、消耗鱼饵 |
| **F03** | ItemDataSystem | 硬依赖 | 鱼类定义、鱼饵定义、地点数据 |
| **C01** | PlayerStatsSystem | 硬依赖 | 体力消耗、钓鱼小游戏状态 |
| **C03** | SkillSystem | 硬依赖 | 钓鱼技能等级加成、天赋 |

### 下游依赖

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P09** | AchievementSystem | 软依赖 | 钓鱼成就（钓到X条鱼等） |
| **P11** | MuseumSystem | 软依赖 | 鱼类捐赠到博物馆 |
| **P13** | FishPondSystem | 软依赖 | 鱼塘放养鱼类 |
| **F01** | SaveLoadSystem | 硬依赖 | 钓鱼数据保存/加载 |

### 数据流

```
F03 ItemDataSystem (鱼类/饵料定义)
    ↓
C01 PlayerStatsSystem (体力检查)
    ↓
C03 SkillSystem (技能加成)
    ↓
FishingSystem (核心逻辑)
    ↓
C02 InventorySystem (存入背包)
    ↓
P06 ShopSystem (出售) / P11 MuseumSystem (捐赠) / P13 FishPondSystem (鱼塘)
```

### 待确认的依赖

| 系统 | 依赖说明 | 状态 |
|------|----------|------|
| **F02** | 天气是否影响钓鱼？（暴风雨+难度） | MVP 不需要 |
| **P14** | 赌博鱼类是否走钓鱼系统？ | 不需要，独立系统 |

## Tuning Knobs

### 咬钩系统调参

| 参数 | 默认值 | 安全范围 | 说明 | 过高/过低影响 |
|------|--------|----------|------|---------------|
| `bite.base_time` | 6.0s | 2-15s | 基础咬钩时间 | 太长=无聊，太短=紧张 |
| `bite.base_chance` | 60% | 40-80% | 基础咬钩成功率 | 太难=挫败，太易=无挑战 |
| `bite.early_penalty` | -30% | -20%~-50% | 太早提竿惩罚 | 影响玩家是否匆忙 |
| `bite.late_penalty` | -50% | -30%~-70% | 太晚提竿惩罚 | 影响最佳时机窗口 |
| `bite.perfect_bonus` | +15% | +10%~+25% | 完美时机奖励 | 鼓励精准操作 |

### 搏鱼系统调参

| 参数 | 默认值 | 安全范围 | 说明 | 过高/过低影响 |
|------|--------|----------|------|---------------|
| `reel.stamina_per_tap` | 0.05 | 0.03-0.10 | 每次按键消耗鱼力量 | 影响搏鱼时长 |
| `reel.pressure_rate` | 0.01 | 0.005-0.02 | 绿色区域外压力增长速度 | 影响容错率 |
| `reel.recovery_rate` | 0.02 | 0.01-0.05 | 鱼力量恢复速度 | 影响持续收线策略 |
| `reel.fail_pressure` | 1.0 | 固定 | 失败压力阈值 | 不可调整 |

### 品质系统调参

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| `quality.base_chance` | 10% | 5-20% | 精品基础概率 |
| `quality.fine_chance` | 15% | 10-25% | 优质基础概率 |
| `quality.skill_bonus` | 2%/级 | 1-3%/级 | 技能加成 |

### 季节/时间调参

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| `season.summer_bonus` | +5% | 0-10% | 夏季咬钩加成 |
| `season.winter_penalty` | -5% | 0-10% | 冬季咬钩惩罚 |
| `time.night_available` | true | - | 深夜是否可钓鱼 |

### 鱼类调参

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| `fish.legendary_spawn_rate` | 2% | 1-5% | 传说鱼基础出现率 |
| `fish.legendary_daily_limit` | 1 | 1-3 | 传说鱼每日上限 |
| `fish.difficulty_range` | 1-10 | 1-15 | 难度范围 |

### 体力消耗调参

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| `stamina.base_cost` | 2 | 1-5 | 基础体力消耗 |
| `stamina.skill_reduction` | 1%/级 | 0.5-2%/级 | 技能减免 |
| `stamina.min_cost` | 1 | 固定 | 最低消耗 |

### 调参交互警告

| 参数 A | 参数 B | 交互说明 |
|--------|--------|----------|
| `bite.base_time` | `reel.stamina_per_tap` | 咬钩太快会让搏鱼变得不重要 |
| `quality.base_chance` | 传说鱼出现率 | 高品质+传说=收益过高 |
| `reel.pressure_rate` | 技能等级 | 高难度+新手=严重挫败感 |
| `stamina.base_cost` | 体力上限 | 高消耗+低上限=无法钓鱼 |

## Acceptance Criteria

### 功能验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **AC-01** | 在河流地点抛竿 | 浮标出现，等待咬钩 | P0 |
| **AC-02** | 鱼咬钩时提竿 | 进入搏鱼阶段 | P0 |
| **AC-03** | 搏鱼成功 | 鱼类存入背包 | P0 |
| **AC-04** | 提竿太早 | 显示"鱼被吓跑了"，不消耗体力 | P1 |
| **AC-05** | 提竿太晚 | 显示"太晚了"，不消耗体力 | P1 |
| **AC-06** | 搏鱼失败（压力满） | 鱼逃跑，显示失败提示 | P1 |
| **AC-07** | 体力不足时抛竿 | 显示"体力不足"，无法抛竿 | P0 |
| **AC-08** | 背包满时捕获鱼 | 鱼存入临时背包 | P1 |
| **AC-09** | 没有鱼饵时抛竿 | 可以抛竿（竹竿），咬钩率降低 | P1 |
| **AC-10** | 传说鱼脱钩 | 当日该传说鱼不再出现 | P1 |

### 钓鱼小游戏验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **MC-01** | 浮标下沉时精确提竿 | 成功率提升 15% | P0 |
| **MC-02** | 搏鱼中持续按压收线 | 鱼力量条下降 | P0 |
| **MC-03** | 鱼在绿色区域外 | 压力条上升 | P0 |
| **MC-04** | 压力条满 | 鱼逃跑，钓鱼失败 | P0 |
| **MC-05** | 鱼力量条耗尽 | 钓鱼成功，获得鱼类 | P0 |

### 品质验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **QC-01** | Lv10 技能钓鱼 100 次 | 精品概率 = 基础10% + 技能加成 | P1 |
| **QC-02** | Mariner 天赋钓鱼 | 最低品质为精品 | P1 |
| **QC-03** | 传说鱼捕获 | 品质固定为精品 | P1 |
| **QC-04** | Angler 天赋拥有 | 传说鱼出现概率大幅提升 | P1 |

### 集成验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **IC-01** | 鱼类出售 | 通过 P06 ShopSystem 正常出售 | P0 |
| **IC-02** | 鱼类捐赠博物馆 | 通过 P11 MuseumSystem 正常捐赠 | P1 |
| **IC-03** | 鱼塘放养 | 通过 P13 FishPondSystem 放养成功 | P1 |
| **IC-04** | 保存/加载游戏 | 钓鱼数据正确保存和恢复 | P0 |
| **IC-05** | 钓鱼技能升级 | 属性加成正确应用 | P0 |

### 性能验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **PC-01** | 钓鱼小游戏帧率 | 保持 60fps | P0 |
| **PC-02** | 大量鱼类数据查询 | < 16ms | P1 |

### UI 验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **UC-01** | 抛竿后显示浮标 | 浮标动画正常 | P0 |
| **UC-02** | 咬钩时浮标下沉 | 浮标下沉动画 | P0 |
| **UC-03** | 搏鱼时显示进度条 | 力量条、压力条正确显示 | P0 |
| **UC-04** | 捕获成功显示鱼类 | 显示鱼类图标和品质 | P0 |
| **UC-05** | 鱼类图鉴界面 | 显示收集进度和详情 | P2 |

## Open Questions

| # | 问题 | 负责人 | 状态 | 备注 |
|---|------|--------|------|------|
| OQ-01 | 鱼类具体数量和定义 | F03 ItemDataSystem | 待定 | 需从原项目迁移 60 种鱼数据 |
| OQ-02 | 钓鱼小游戏具体 UI 实现 | UI Team | 待定 | 需要视觉稿确认 |
| OQ-03 | 传说鱼具体售价 | Economy Team | 待定 | 影响经济平衡 |
| OQ-04 | 冰钓特殊规则 | Game Design | 待定 | 冬季可能需要特殊机制 |
| OQ-05 | 钓鱼小游戏辅助模式详细参数 | UX Design | 待定 | 辅助模式绿色区域大小 |
| OQ-06 | 触摸屏操作手势定义 | UX Design | 待定 | 拖拽收线 vs 按钮收线 |
| OQ-07 | 渔具升级系统 | Game Design | 待定 | 是否需要独立的渔具升级？ |
| OQ-08 | 鱼类作为烹饪食材的配方 | P04 Cooking | 待定 | 部分鱼类可烹饪 |
