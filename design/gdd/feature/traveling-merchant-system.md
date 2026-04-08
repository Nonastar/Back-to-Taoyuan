# 旅行商人系统 (Traveling Merchant System)

> **Status**: Approved
> **Author**: Claude + User
> **Last Updated**: 2026-04-07
> **Implements Pillar**: 社交系统与NPC互动

## Overview

旅行商人系统为游戏添加了一位神秘的流动商人，定期出现在农场附近提供稀有商品和限时抢购。旅行商人每周出现固定次数，每次带来不同的商品列表，包括稀有种子、独特物品和限时道具。玩家需要及时把握机会购买心仪的商品，否则可能需要等待下周。

**与 P07 隐藏NPC的联动**: 当玩家与狐仙(hu_xian)结缘后，解锁"幻商"能力，旅行商人会额外提供1件稀有商品。

**与 P06 商店系统的关系**: 旅行商人销售部分商店不提供的特殊物品，是游戏物品获取的重要补充渠道。

## Player Fantasy

旅行商人系统给玩家带来**惊喜与期待感**。玩家应该感受到：

- **神秘商人的魅力** — 旅行商人来去无踪，每次出现都是惊喜
- **限时商品的紧迫感** — 看到稀有商品知道只有一周机会，抓紧购买
- **收藏的满足感** — 集齐旅行商人特有商品
- **与狐仙的默契** — 知道幻商能力带来的额外稀有商品

**Reference games**: Stardew Valley 的 Traveling Cart；各类游戏中限时商店的紧迫感设计。

**情感曲线**:
1. **发现商人**: 意外看到商人出现在农场
2. **浏览商品**: 期待找到稀有商品
3. **购买决策**: 金钱有限，需要取舍
4. **错过的遗憾**: 看到稀有商品但钱不够，下次再来

## Detailed Design

### Core Rules

#### 1. 旅行商人出现规则

**出现时间**:
- 每周出现 **2次**
- 固定时间：每周二和每周五
- 出现时间段：6:00 - 22:00
- 商人离开后商品列表清空

**出现条件**:
| 条件 | 说明 |
|------|------|
| 第一年 | 固定每周出现 |
| 第二年+ | 概率 +20% 增加额外出现 |
| 狐仙结缘 | hu_xian_3 解锁后，额外商品+1 |

#### 2. 商品列表生成

**商品池分类**:

| 商品类型 | 出现概率 | 示例 |
|----------|----------|------|
| **稀有种子** | 30% | 传说水果种子、稀有花卉种子 |
| **独特物品** | 25% | 独特家具、装饰品 |
| **限时道具** | 20% | 特殊肥料、增益道具 |
| **稀有材料** | 15% | 彩虹碎片、高级矿石 |
| **随机商品** | 10% | 随机稀有物品 |

**每周商品数量**:
- 基础数量：5-7件商品
- 狐仙幻商加成：+1件稀有商品

**商品价格**:
- 通常为商店价格的 **1.5-3倍**
- 稀有度越高，价格倍率越高

#### 3. 商品数据结构

```yaml
# 旅行商人商品
traveling_item:
  item_id: "rare_seed_1"      # 物品ID
  price: 2500                   # 售价
  quantity: 1                  # 可购买数量
  rarity: "rare"               # 稀有度
  is_sold: false               # 是否已售出
  is_legendary: false          # 是否为传说商品
```

#### 4. 购买流程

**购买规则**:
1. 玩家与商人对话打开商店界面
2. 浏览当前商品列表
3. 选择商品进行购买
4. 扣除金币，商品移交给玩家
5. 商品售出后从列表移除

**购买限制**:
- 每种商品每次最多购买1件
- 部分传说商品可能每周限量1件
- 金币不足时无法购买

#### 5. 旅行商人NPC

**角色设定**:
- 名称：逍遥商人 / 云游四海客
- 外观：中式商人服饰，背负货箱
- 性格：健谈、神秘、了解各地奇闻

**对话特点**:
- 每次来访有独特的开场白
- 会提及下一站的目的地
- 根据季节变化提及应季商品

#### 6. 商人位置

**固定位置**:
- 农场入口左侧空地
- 商人停留期间显示特殊标记
- 离开后位置恢复正常

### States and Transitions

#### 商人状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **NotPresent** | 商人不在 | 非周二/五，或22:00后 |
| **Arriving** | 正在到达 | 周二/五 6:00 |
| **Present** | 商人驻留中 | 到达完成 |
| **Leaving** | 正在离开 | 22:00 或玩家离开 |
| **Departed** | 已离开 | 离开完成 |

**状态转换**:
```
NotPresent → Arriving: (is_tuesday or is_friday) and time >= 6:00
Arriving → Present: arrival_animation_complete
Present → Leaving: time >= 22:00 or player_leave
Leaving → Departed: departure_animation_complete
Departed → NotPresent: reset_daily
```

#### 商品状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Available** | 可购买 | 商品生成且未售出 |
| **Sold** | 已售出 | 玩家购买 |
| **Expired** | 已过期 | 商人离开 |

### Interactions with Other Systems

#### 依赖系统 (Upstream Dependencies)

| System | Interface | Usage |
|--------|-----------|-------|
| **F01 时间/季节系统** | `get_day_of_week()`, `get_hour()` | 出现时间判定 |
| **P06 商店系统** | `get_item_price()` | 价格参考 |
| **P07 隐藏NPC系统** | `is_ability_active("hu_xian_3")` | 幻商能力加成 |

#### API 接口

```gdscript
class_name TravelingMerchantSystem extends Node

## 单例访问
static func get_instance() -> TravelingMerchantSystem

## 商人状态
func is_merchant_present() -> bool
func get_merchant_position() -> Vector2
func get_time_until_departure() -> int

## 商品系统
func get_current_items() -> Array[TravelingItem]
func get_item_price(item_id: String) -> int
func buy_item(item_id: String) -> Dictionary
func is_item_available(item_id: String) -> bool

## 商品生成
func generate_weekly_items() -> Array[TravelingItem]
func get_item_pool_by_rarity(rarity: String) -> Array

## 解锁检查
func check_appear_conditions() -> bool
func get_bonus_item_count() -> int

## 每日更新
func daily_update() -> void
func check_departure() -> bool

## 存档
func serialize() -> Dictionary
func deserialize(data: Dictionary)
```

## Formulas

### 1. 商品数量计算

```
base_count = random(5, 7)
hu_xian_bonus = is_ability_active("hu_xian_3") ? 1 : 0
total_count = base_count + hu_xian_bonus
```

### 2. 价格倍率计算

```
rarity_multiplier = {
    "common": 1.5, "uncommon": 2.0,
    "rare": 2.5, "epic": 3.0, "legendary": 4.0
}
price = shop_price * rarity_multiplier[rarity]
```

### 3. 商品池选取

```
def select_items():
    selected = []
    for i in range(total_count):
        roll = random(0, 100)
        if roll < 30: selected += pick_from("rare_seeds")
        elif roll < 55: selected += pick_from("unique_items")
        elif roll < 75: selected += pick_from("limited_items")
        elif roll < 90: selected += pick_from("rare_materials")
        else: selected += pick_from("random_items")
    return selected
```

## Edge Cases

### 1. 商人边界

- **商人不在时点击**: 提示"商人今天不在"
- **金币不足购买**: 禁用购买按钮，显示所需金币
- **商人离开瞬间购买**: 使用乐观锁定

### 2. 商品边界

- **商品已售完**: 从列表移除
- **同一商品多次出现**: 每件独立计数
- **商品与玩家背包满**: 提示背包已满

### 3. 时间边界

- **跨季节停留**: 商品列表保持不变
- **玩家在商店时商人离开**: 强制退出
- **多天不上线**: 出现次数不累积

## Dependencies

### 上游依赖（P17 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F01** | 时间/季节系统 | 硬依赖 | 出现时间判定 |
| **P06** | 商店系统 | 软依赖 | 价格参考 |
| **P07** | 隐藏NPC系统 | 软依赖 | 幻商能力加成 |

### 下游依赖（其他系统依赖 P17）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **U06** | 商店UI | 硬依赖 | 商品显示 |

## Tuning Knobs

### 出现配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `APPEAR_DAYS` | [2, 5] | 固定 | 出现日期(周几) |
| `APPEAR_START_HOUR` | 6 | 4-8 | 开始时间 |
| `DEPART_HOUR` | 22 | 20-24 | 离开时间 |
| `BASE_ITEM_COUNT` | 5-7 | 3-10 | 基础商品数量 |

### 价格配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `PRICE_COMMON` | 1.5 | 1.2-2.0 | 普通商品倍率 |
| `PRICE_UNCOMMON` | 2.0 | 1.5-2.5 | 少见商品倍率 |
| `PRICE_RARE` | 2.5 | 2.0-3.0 | 稀有商品倍率 |
| `PRICE_EPIC` | 3.0 | 2.5-4.0 | 史诗商品倍率 |
| `PRICE_LEGENDARY` | 4.0 | 3.0-5.0 | 传说商品倍率 |

### 商品池配置

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `POOL_RARE_SEED` | 30% | 稀有种子概率 |
| `POOL_UNIQUE` | 25% | 独特物品概率 |
| `POOL_LIMITED` | 20% | 限时道具概率 |
| `POOL_MATERIAL` | 15% | 稀有材料概率 |
| `POOL_RANDOM` | 10% | 随机商品概率 |

## Visual/Audio Requirements

### 视觉要求

- **商人外观**: 中式商人服饰，背负货箱
- **出现提示**: 商人到达时小地图标记
- **商店界面**: 特殊旅行商人主题UI

### 音频要求

- **到达音效**: 商人到达时的招呼音
- **购买音效**: 购买成功时金币音效
- **离开音效**: 商人离开时的告别语

## UI Requirements

| 界面 | 组件 | 描述 |
|------|------|------|
| 商人对话 | MerchantDialogUI | 对话和打开商店 |
| 商品列表 | ItemListUI | 显示当前商品 |
| 商品详情 | ItemDetailPanel | 显示价格和说明 |

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 商人按规律出现 | 周二/五验证出现 |
| **AC-02** | 商品列表生成 | 验证商品数量和类型 |
| **AC-03** | 购买功能 | 购买后验证金币和物品 |
| **AC-04** | 商人离开 | 22:00后验证离开 |
| **AC-05** | 存档/读档 | 保存后读取验证 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | P07 幻商加成 | 狐仙结缘后验证+1商品 |
| **CS-02** | F01 时间判定 | 非出现日验证商人不在 |
| **CS-03** | P06 价格参考 | 验证价格计算正确 |

## Open Questions

| ID | 问题 | Owner | Target Date |
|----|------|-------|-------------|
| **OQ-01** | 旅行商人的具体商品列表？ | 策划 | Pre-MVP |
| **OQ-02** | 是否有商人的好感度系统？ | 策划 | Post-MVP |
| **OQ-03** | 商人是否提供物品出售功能？ | 策划 | Pre-MVP |
