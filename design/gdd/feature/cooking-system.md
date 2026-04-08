# 烹饪系统 (Cooking System)

> **状态**: Approved
> **Author**: Claude Code
> **Last Updated**: 2026-04-07
> **System ID**: P04
> **Implements Pillar**: 农场经营与农业系统

## Overview

烹饪系统为玩家提供食材加工和增益 buff 的获取途径。系统包含113种食谱，每种食谱需要不同的食材组合。玩家使用锅进行烹饪，成品可提供5种不同的 buff 效果（体力恢复、生命恢复、速度提升等），持续1-5天。烹饪系统连接畜牧、农场、钓鱼等多个生产系统，是资源转化和玩家成长的重要一环。

## Player Fantasy

烹饪系统给玩家带来**创造的成就感和策略的满足感**。玩家应该感受到：

- **食材的丰富** — 背包里的各种食材可以变成美味的料理
- **烹饪的期待** — 看着锅里的食材变成成品，期待它的效果
- **buff 的策略** — 根据明天的计划选择合适的 buff，合理搭配
- **探索的乐趣** — 发现新食谱时的惊喜，记录收集的成就感

**Reference games**: Stardew Valley 的烹饪简单实用；Rune Factory 的食谱探索有趣。

## Detailed Design

### Core Rules

#### 1. 食谱系统

**食谱分类**:
| 分类 | 描述 | 示例 |
|------|------|------|
| **早餐类** | 简单食谱，基础 buff | 煎蛋、烤面包 |
| **主餐类** | 完整营养，强力 buff | 炒菜、红烧肉 |
| **甜点类** | 特殊 buff，恢复类 | 蛋糕、果冻 |
| **饮品** | 快速恢复，随时使用 | 果汁、汤 |
| **药膳** | 稀有食材，高级 buff | 人参汤、龙虾汤 |

**食谱来源**:
- **初始解锁**: 基础食谱（10种）
- **学习获得**: 特定 NPC 赠送、完成任务
- **食谱发现**: 玩家自己尝试组合食材

#### 2. 食材系统

**食材分类**:
| 分类 | 来源 | 示例 |
|------|------|------|
| **农作物** | C04 FarmPlotSystem | 蔬菜、水果 |
| **动物产品** | P01 AnimalHusbandrySystem | 蛋、奶、毛 |
| **鱼类** | P02 FishingSystem | 各种鱼 |
| **矿石** | P03 MiningSystem | 稀有矿物（特殊料理） |
| **采集物** | C04 FarmPlotSystem | 蘑菇、草药 |

#### 3. 烹饪工具

| 工具 | 位置 | 能力 |
|------|------|------|
| ** farmhouse 锅** | 家中 | 可烹饪所有食谱 |
| **矿洞营火** | 矿洞内 | 仅可烹饪简单食谱 |
| **海边篝火** | 海边 | 可烹饪海鲜食谱 |

#### 4. Buff 系统

**Buff 类型**:
| Buff | 效果 | 持续时间 |
|------|------|----------|
| **体力恢复** | 每日体力上限+20 | 1-5天 |
| **生命恢复** | 每日自动恢复 HP | 1-5天 |
| **速度提升** | 移动速度+20% | 1-5天 |
| **幸运提升** | 幸运值+10 | 1-5天 |
| **防御提升** | 防御+5 | 1-5天 |

**Buff 叠加规则**:
- 相同类型 Buff 可叠加（取较高值）
- 不同类型 Buff 可共存
- Buff 时间可累加

#### 5. 食谱发现机制

玩家可以尝试任意食材组合：
- **成功**: 发现新食谱（如果有对应配方）
- **失败**: 食材消耗，但获得提示"食材不匹配"
- **随机成功**: 低概率做出"惊喜料理"（随机 Buff）

#### 6. 配方数量

| 食谱类型 | 数量 |
|----------|------|
| 早餐类 | 25种 |
| 主餐类 | 40种 |
| 甜点类 | 20种 |
| 饮品 | 15种 |
| 药膳 | 13种 |
| **总计** | **113种** |

### States and Transitions

#### 烹饪状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **Idle** | 待机 | 锅空闲 |
| **Cooking** | 烹饪中 | 正在烹饪 |
| **Ready** | 可食用 | 料理完成 |
| **BuffActive** | Buff 生效中 | 食用后 |

**状态转换图**:
```
Idle → Cooking: 开始烹饪
Cooking → Idle: 烹饪失败或取消
Cooking → Ready: 烹饪完成
Ready → Idle: 取出料理或食用
Ready → BuffActive: 食用料理
BuffActive → Idle: Buff 时间结束
```

#### 食谱状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **Locked** | 未解锁 | 未发现食谱 |
| **Known** | 已学习 | 已知晓食谱 |
| **Mastered** | 已掌握 | 成功烹饪 10 次 |

### Interactions with Other Systems

**上游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **C02 InventorySystem** | 硬依赖 | 消耗食材、存储料理 |
| **F03 ItemDataSystem** | 硬依赖 | 食谱定义、食材定义、Buff 定义 |
| **C03 SkillSystem** | 软依赖 | 烹饪技能影响成功率 |
| **C01 PlayerStatsSystem** | 软依赖 | Buff 效果应用到玩家属性 |

**下游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **P08 QuestSystem** | 软依赖 | 烹饪相关任务（制作 X 份料理等） |
| **P09 AchievementSystem** | 软依赖 | 烹饪成就（发现所有食谱等） |
| **F01 SaveLoadSystem** | 硬依赖 | 烹饪数据保存/加载 |

### 提供给下游的 API

```gdscript
class_name CookingSystem extends Node

## 单例访问
static func get_instance() -> CookingSystem

## 烹饪操作
func start_cooking(recipe_id: String) -> bool:
    """开始烹饪，返回是否成功"""

func cancel_cooking() -> bool:
    """取消烹饪，返还部分食材"""

func finish_cooking() -> Dictionary:
    """完成烹饪，返回料理 {success, item_id, quality}"""

func eat_dish(item_id: String) -> bool:
    """食用料理，激活 Buff"""

## 食谱操作
func learn_recipe(recipe_id: String) -> bool:
    """学习食谱（NPC 赠送、任务奖励）"""

func discover_recipe(ingredients: Array) -> Dictionary:
    """尝试发现食谱，返回 {success, recipe_id, is_new}"""

func get_known_recipes() -> Array:
    """获取已知食谱列表"""

## 查询
func get_available_recipes() -> Array:
    """获取当前可烹饪的食谱（基于已知+食材）"""

func get_active_buffs() -> Array[BuffInfo]:
    """获取当前激活的 Buff 列表"""

func get_recipe_ingredients(recipe_id: String) -> Array:
    """获取食谱所需食材"""

func get_recipe_buff(recipe_id: String) -> Dictionary:
    """获取食谱的 Buff 效果"""
```

## Formulas

### 1. 烹饪成功率公式

```
# 基础成功率
base_success_rate = 0.80

# 食材品质加成
quality_bonus = {
    "normal": 0.0,
    "fine": 0.05,
    "excellent": 0.10,
    "supreme": 0.20
}

# 农耕技能加成 (C03 SkillSystem - 农耕技能)
# 注意：烹饪使用农耕技能作为熟练度代表
# 如需独立烹饪技能，需在 C03 中添加 "厨艺" 技能
skill_bonus = farming_skill_level * 0.01

# 工具加成
tool_bonus = {
    "farmhouse_pot": 0.0,
    "mine_campfire": -0.10,
    "beach_campfire": 0.0
}

# 最终成功率
final_success_rate = base_success_rate + quality_bonus + skill_bonus + tool_bonus
final_success_rate = clamp(final_success_rate, 0.50, 0.99)
```

### 2. 料理品质公式

```
# 基础高品质概率
base_quality_chance = 0.10  # 10%

# 食材平均品质加成
avg_ingredient_quality = average(all_ingredients.quality)

# 技能加成 (C03 SkillSystem)
if has_talent("artisan"):
    quality_multiplier = 1.5  # 加工品售价+25% 延伸

if has_talent("alchemist"):
    buff_duration_bonus = 0.5  # 食物恢复效果+50%

# 最终高品质概率
final_quality_chance = base_quality_chance + (avg_ingredient_quality * 0.05)
```

### 3. Buff 效果公式

```
# 基础 Buff 强度
base_buff_strength = recipe.buff_strength  # 1-100

# 品质加成
quality_multiplier = {
    "normal": 1.0,
    "fine": 1.2,
    "excellent": 1.5,
    "supreme": 2.0
}

# 最终 Buff 强度
final_buff_strength = base_buff_strength * quality_multiplier

# Buff 持续时间
buff_duration = recipe.duration_days * quality_duration_multiplier
# 基础持续时间 1-5 天，Supreme 品质 +1 天
```

### 4. 料理价值公式

```
# 基础价值 (来自 F03)
base_value = recipe.base_value

# 品质加成
quality_multiplier = {
    "normal": 1.0,
    "fine": 1.5,
    "excellent": 2.0,
    "supreme": 3.0
}

# 最终价值
final_value = floor(base_value * quality_multiplier)
```

### 5. 食谱发现概率公式

```
# 未知食谱尝试发现
if recipe.is_unknown:
    # 食材匹配度计算
    match_score = calculate_match(ingredients, recipe.required_ingredients)
    
    # 发现概率
    discover_chance = match_score * 0.10
    
    # 技能加成
    skill_bonus = farming_skill_level * 0.02
    
    # 最终发现概率
    final_discover_chance = min(0.30, discover_chance + skill_bonus)
```

### 6. 食材消耗公式

```
# 烹饪成功
if cooking_success:
    for each ingredient in recipe.ingredients:
        remove_from_inventory(ingredient.id, ingredient.quantity)

# 烹饪失败
if cooking_failed:
    # 返还 50% 食材
    for each ingredient in recipe.ingredients:
        return_quantity = ceil(ingredient.quantity * 0.5)
        add_to_inventory(ingredient.id, return_quantity)
```

### 公式变量表

| 变量名 | 类型 | 范围 | 说明 |
|--------|------|------|------|
| `final_success_rate` | float | 0.50-0.99 | 最终烹饪成功率 |
| `final_quality_chance` | float | 0.0-1.0 | 高品质概率 |
| `final_buff_strength` | int | 1-200 | 最终 Buff 强度 |
| `buff_duration` | int | 1-6 | Buff 持续天数 |
| `final_value` | int | 1+ | 料理售价 |
| `farming_skill_level` | int | 0-10 | 农耕技能等级 |

### 预期产出范围

| 料理类型 | 基础价值 | Buff 强度 | 持续时间 |
|----------|----------|------------|----------|
| 早餐类 | 50-150g | 10-30 | 1-2天 |
| 主餐类 | 100-300g | 20-50 | 2-3天 |
| 甜点类 | 80-200g | 15-40 | 1-2天 |
| 饮品 | 30-100g | 10-25 | 1天 |
| 药膳 | 300-1000g | 50-100 | 3-5天 |

## Edge Cases

### 1. 食材边界情况

| 情况 | 处理方式 |
|------|----------|
| 食材不足 | 无法开始烹饪，提示缺少食材 |
| 食材数量刚好 | 烹饪后食材归零 |
| 过期食材 | 显示警告，可以选择是否使用 |
| 稀有食材 | 提示确认是否使用 |

### 2. 背包边界情况

| 情况 | 处理方式 |
|------|----------|
| 料理完成但背包满 | 料理留在锅中，可稍后取出 |
| 多个料理堆积 | 锅中可保留多个完成的料理 |
| 料理过期 | 料理有保质期，过期后消失 |

### 3. 烹饪边界情况

| 情况 | 处理方式 |
|------|----------|
| 烹饪中取消 | 返还 50% 食材 |
| 烹饪失败 | 返还 50% 食材，显示失败提示 |
| 野外烹饪（矿洞/海边） | 仅支持简单食谱 |
| 锅中已有料理 | 需先取出才能开始新烹饪 |

### 4. Buff 边界情况

| 情况 | 处理方式 |
|------|----------|
| 相同 Buff 叠加 | 取较高值，时间累加 |
| 不同 Buff 叠加 | 全部生效，最多 5 个 |
| Buff 期间食用同类 | 时间刷新，效果取高 |
| 达到 Buff 上限 | 需等旧 Buff 结束 |
| Buff 期间睡觉 | Buff 持续天数 -1 |

### 5. 食谱发现边界情况

| 情况 | 处理方式 |
|------|----------|
| 食材组合无对应食谱 | 提示"这个组合做不出东西" |
| 发现的食谱已经会了 | 不重复显示，返还提示 |
| 惊喜料理 | 随机获得一个随机 Buff |

### 6. 料理保质期

| 情况 | 处理方式 |
|------|----------|
| 料理完成保质期 | 根据料理类型，1-7 天 |
| 保质期内未食用 | 料理过期消失 |
| 食用过期料理 | 显示警告，效果减半或不生效 |

### 7. 工具限制

| 情况 | 处理方式 |
|------|----------|
| 没有 farmhouse 锅 | 无法进行高级烹饪 |
| 野外没有烹饪工具 | 无法烹饪，显示提示 |
| 矿洞内营火受限 | 仅能烹饪简单食谱 |

### 8. 料理食用

| 情况 | 处理方式 |
|------|----------|
| 体力已满食用体力料理 | Buff 仍然激活 |
| 战斗中食用 | 允许，Buff 立即生效 |
| 快速连续食用 | 允许，但同类型 Buff 取高 |

### 9. 多日不上线处理

当玩家多日不上线时：
```
1. Buff 时间: 上线时计算过期 Buff 并移除
2. 锅中料理: 料理保质期正常计算
3. 食谱状态: 保持不变
```

## Dependencies

### 上游依赖

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **C02** | InventorySystem | 硬依赖 | 消耗食材、存储料理 |
| **F03** | ItemDataSystem | 硬依赖 | 食谱定义、食材定义、Buff 定义 |
| **C03** | SkillSystem | 软依赖 | 农耕技能影响成功率、天赋加成 |
| **C01** | PlayerStatsSystem | 软依赖 | Buff 效果应用到玩家属性 |
| **P01** | AnimalHusbandrySystem | 软依赖 | 动物产品作为食材（蛋、奶） |
| **P02** | FishingSystem | 软依赖 | 鱼类作为食材 |
| **C04** | FarmPlotSystem | 软依赖 | 农作物作为食材 |
| **P05** | ProcessingSystem | 软依赖 | 加工产品作为高级食材 |

### 下游依赖

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P08** | QuestSystem | 软依赖 | 烹饪相关任务（制作 X 份料理等） |
| **P09** | AchievementSystem | 软依赖 | 烹饪成就（发现所有食谱等） |
| **F01** | SaveLoadSystem | 硬依赖 | 烹饪数据保存/加载 |

### 数据流

```
P01 畜牧系统 (蛋、奶)
P02 钓鱼系统 (鱼)
C04 农场系统 (农作物)
    ↓
C02 库存系统 (食材存储)
    ↓
CookingSystem (核心逻辑 - 烹饪)
    ↓
C02 库存系统 (料理存储)
    ↓
C01 玩家属性系统 (Buff 效果)
    ↓
P06 商店系统 (出售料理)
```

### 待确认的依赖

| 系统 | 依赖说明 | 状态 |
|------|----------|------|
| **P05** | 加工系统产出的物品是否可以作为食材？ | 可以，所有可食用物品 |
| **P03** | 矿洞产出的矿石是否用于特殊料理？ | 是，药膳类 |

## Tuning Knobs

### 烹饪系统调参

| 参数 | 默认值 | 安全范围 | 说明 | 过高/过低影响 |
|------|--------|----------|------|---------------|
| `cooking.base_success` | 80% | 60-95% | 基础成功率 | 影响资源消耗 |
| `cooking.min_success` | 50% | 40-70% | 最低成功率 | 防止必失败 |
| `cooking.max_success` | 99% | 90-100% | 最高成功率 | 防止必成功 |

### 料理品质调参

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| `quality.base_chance` | 10% | 5-20% | 基础高品质概率 |
| `quality.fine_multiplier` | 1.2 | 1.0-1.5 | 优质品质倍率 |
| `quality.excellent_multiplier` | 1.5 | 1.2-2.0 | 精品品质倍率 |
| `quality.supreme_multiplier` | 2.0 | 1.5-3.0 | 极品品质倍率 |

### Buff 系统调参

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| `buff.max_count` | 5 | 3-10 | 最大同时 Buff 数 |
| `buff.stamina_bonus` | 20 | 10-50 | 体力恢复 Buff 强度 |
| `buff.speed_bonus` | 20% | 10-50% | 速度提升 Buff |
| `buff.luck_bonus` | 10 | 5-20 | 幸运提升 Buff |
| `buff.defense_bonus` | 5 | 2-15 | 防御提升 Buff |
| `buff.max_duration` | 5天 | 3-10天 | 最大持续时间 |

### 料理保质期调参

| 料理类型 | 默认天数 | 安全范围 |
|----------|----------|----------|
| 早餐类 | 3天 | 1-7天 |
| 主餐类 | 5天 | 3-10天 |
| 甜点类 | 2天 | 1-5天 |
| 饮品 | 1天 | 1-3天 |
| 药膳 | 7天 | 5-14天 |

### 食谱调参

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| `recipe.initial_count` | 10 | 5-20 | 初始解锁食谱数 |
| `recipe.total_count` | 113 | - | 总食谱数 |
| `recipe.discover_chance` | 10% | 5-20% | 发现概率 |
| `recipe.failed_return` | 50% | 30-70% | 失败返还比例 |

### 调参交互警告

| 参数 A | 参数 B | 交互说明 |
|--------|--------|----------|
| `cooking.base_success` | 料理售价 | 高成功率+高价=收益过高 |
| `buff.max_duration` | 料理保质期 | Buff 5天+保质期3天=矛盾 |
| `quality.supreme_multiplier` | buff 强度 | 极品+高 buff=过于强力 |

## Acceptance Criteria

### 功能验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **AC-01** | 使用食材开始烹饪 | 食材消耗，开始烹饪 | P0 |
| **AC-02** | 烹饪成功完成 | 料理存入背包 | P0 |
| **AC-03** | 烹饪失败 | 返还 50% 食材 | P1 |
| **AC-04** | 取消烹饪 | 返还 50% 食材 | P1 |
| **AC-05** | 食用料理 | 激活对应 Buff | P0 |
| **AC-06** | Buff 生效 | 体力/速度等属性提升 | P0 |
| **AC-07** | Buff 时间结束 | Buff 自动移除 | P0 |
| **AC-08** | 发现新食谱 | 食谱加入已知列表 | P1 |
| **AC-09** | 学习 NPC 赠送食谱 | 食谱解锁 | P1 |
| **AC-10** | 料理过期 | 料理消失 | P1 |

### Buff 验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **BC-01** | 同类 Buff 叠加 | 效果取高，时间累加 | P0 |
| **BC-02** | 不同类 Buff 叠加 | 全部生效 | P0 |
| **BC-03** | 达到 Buff 上限 | 新 Buff 替换最旧的 | P1 |
| **BC-04** | Buff 期间睡觉 | 持续时间 -1 天 | P1 |

### 品质验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **QC-01** | 使用高品质食材 | 高品质料理概率提升 | P1 |
| **QC-02** | Artisan 天赋烹饪 | 料理价值提升 | P1 |
| **QC-03** | Alchemist 天赋烹饪 | Buff 效果+50% | P1 |

### 集成验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **IC-01** | 农作物作为食材 | C04 产出的蔬菜可用于烹饪 | P0 |
| **IC-02** | 鱼类作为食材 | P02 钓到的鱼可用于烹饪 | P0 |
| **IC-03** | 动物产品作为食材 | P01 产出的蛋、奶可用于烹饪 | P0 |
| **IC-04** | 料理出售 | 通过 P06 ShopSystem 正常出售 | P1 |
| **IC-05** | 保存/加载 | 烹饪数据正确保存和恢复 | P0 |

### UI 验收标准

| ID | 测试场景 | 预期结果 | 优先级 |
|----|----------|----------|--------|
| **UC-01** | 显示可用食谱 | 正确显示当前可烹饪食谱 | P0 |
| **UC-02** | 显示食材需求 | 正确显示所需食材 | P0 |
| **UC-03** | 显示 Buff 列表 | 正确显示当前激活的 Buff | P0 |
| **UC-04** | 显示料理保质期 | 料理图标显示过期倒计时 | P1 |

## Open Questions

| # | 问题 | 负责人 | 状态 | 备注 |
|---|------|--------|------|------|
| OQ-01 | 113 种食谱具体定义 | F03 ItemDataSystem | 待定 | 需从原项目迁移食谱数据 |
| OQ-02 | Buff 效果具体数值 | Game Design | 待定 | 体力+20/速度+20%是否合适 |
| OQ-03 | 料理保质期具体实现 | Tech | 待定 | 是否实时倒计时 |
| OQ-04 | 食谱发现机制细节 | Game Design | 待定 | 是否有提示系统 |
| OQ-05 | 惊喜料理具体效果 | Game Design | 待定 | 随机 Buff 范围 |
| OQ-06 | 料理制作动画/音效 | Audio/Art | 待定 | 烹饪时的反馈 |
| OQ-07 | 野外烹饪 UI | UX Design | 待定 | 矿洞/海边烹饪界面 |
| OQ-08 | Buff 图标设计 | Art | 待定 | Buff 可视化 |
