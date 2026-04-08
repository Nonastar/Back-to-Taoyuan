# 市场系统 (Market System)

> **Status**: Approved
> **Author**: Claude + User
> **Last Updated**: 2026-04-07
> **Implements Pillar**: 物品管理与资源循环

## Overview

市场系统为游戏提供每日物价波动的经济环境。系统模拟供需关系，商品价格根据季节、天气、玩家购买行为等因素每日变化。玩家可以通过观察价格走势，低买高卖赚取利润。市场是连接生产和消费的桥梁，鼓励玩家关注经济动态而非单纯囤货。

**与 F01 时间系统的关系**: 每日价格重基于 F01 的每日结算时触发。

## Player Fantasy

市场系统给玩家带来**经济策略家的成就感**。玩家应该感受到：

- **低买高卖的智慧** — 观察价格走势，在低价时买入，高价时卖出
- **市场供需的紧张** — 大量购买某商品会导致价格上升
- **季节差异的利用** — 某些商品在特定季节价格更低

**Reference games**: 现实市场的供需关系；各类RPG中的商店价格波动。

**情感曲线**:
1. **发现低价**: 看到某商品价格低于平时
2. **判断时机**: 决定是现在买还是等待
3. **出售获利**: 高价时卖出赚取差价
4. **成为富商**: 通过市场交易积累财富

## Detailed Design

### Core Rules

#### 1. 商品价格分类

**价格波动商品** (可在市场交易的商品):

| 商品类别 | 示例 | 基准价格 | 波动范围 |
|----------|------|----------|-----------|
| **农作物** | 小麦、胡萝卜、白菜 | 商店价 | 0.5x - 2.0x |
| **水果** | 樱桃、桃子、橙子 | 商店价 | 0.6x - 2.5x |
| **动物产品** | 鸡蛋、牛奶、羊毛 | 商店价 | 0.5x - 1.8x |
| **手工艺品** | 果酱、腌菜、奶酪 | 加工成本 | 0.8x - 2.0x |
| **矿物** | 铜锭、铁锭、金锭 | 商店价 | 0.7x - 1.5x |

**固定价格商品** (不参与价格波动):
- 工具类
- 种子类
- 特殊物品

#### 2. 价格影响因素

**波动因子**:

| 因子 | 影响 | 说明 |
|------|------|------|
| **季节** | ±20% | 当季产出多的商品价格下降 |
| **天气** | ±15% | 雨天渔业产出多，鱼价下降 |
| **购买量** | +5%/件 | 大量购买推高价格 |
| **出售量** | -5%/件 | 大量出售压低价格 |
| **随机波动** | ±10% | 每日随机因素 |

**季节价格修正**:

| 季节 | 农作物 | 水果 | 鱼类 |
|------|--------|------|------|
| **春季** | 0.8x | 1.2x | 1.0x |
| **夏季** | 1.0x | 0.8x | 1.0x |
| **秋季** | 0.9x | 0.9x | 1.1x |
| **冬季** | 1.3x | 1.5x | 0.9x |

#### 3. 每日价格计算

```
# 价格计算公式
base_price = SHOP_PRICE[item_id]

# 累加各项因子
price = base_price
      × season_modifier
      × weather_modifier
      × (1 + demand_factor)
      × (1 + random_factor)

# demand_factor = (total_bought_today - total_sold_today) × 0.05
# random_factor = random(-0.1, 0.1)
```

#### 4. 玩家行为影响

**购买行为**:
- 玩家购买某商品，价格上升
- 每件 +5% 价格
- 影响持续到当日结算

**出售行为**:
- 玩家出售某商品，价格下降
- 每件 -5% 价格
- 影响持续到当日结算

**市场饱和**:
- 单日购买/出售超过 20 件后，边际影响减半

#### 5. 市场交易

**交易流程**:
1. 玩家选择要出售的物品
2. 显示当前市场价格
3. 选择出售数量
4. 获得金币 = 价格 × 数量

**收购规则**:
- 玩家可以将背包物品出售给市场
- 市场价格通常低于商店购买价
- 质量影响出售价格

#### 6. 价格历史记录

**记录内容**:
- 最近 7 天的价格
- 每日最高/最低价
- 均价

**显示信息**:
- 当前价格 vs 均价
- 价格趋势箭头 (↑↓→)
- 价格预测提示 (可选)

### States and Transitions

#### 市场状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Normal** | 正常交易 | 每日6:00-24:00 |
| **Closed** | 市场关闭 | 24:00-6:00 |
| **Event** | 特殊事件 | 节日/活动期间 |

#### 商品状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Normal** | 正常价格 | 无特殊因素 |
| **Surge** | 价格飙升 | 大量购买 |
| **Crash** | 价格崩盘 | 大量出售 |
| **Seasonal** | 季节低价 | 当季丰产 |

### Interactions with Other Systems

#### 依赖系统 (Upstream Dependencies)

| System | Interface | Usage |
|--------|-----------|-------|
| **F01 时间/季节系统** | `get_season()`, `get_day()` | 季节因子、每日重置 |
| **F02 天气系统** | `get_weather()` | 天气因子 |
| **C02 库存系统** | `get_item_count()` | 获取物品数量 |

#### API 接口

```gdscript
class_name MarketSystem extends Node

## 单例访问
static func get_instance() -> MarketSystem

## 价格查询
func get_current_price(item_id: String) -> int:
    """获取商品当前价格"""

func get_base_price(item_id: String) -> int:
    """获取商品基准价格"""

func get_price_trend(item_id: String) -> String:
    """获取价格趋势 (up/down/stable)"""

func get_price_history(item_id: String, days: int = 7) -> Array:
    """获取价格历史"""

func get_average_price(item_id: String) -> float:
    """获取历史均价"""

## 市场交易
func sell_item(item_id: String, quantity: int, quality: String) -> Dictionary:
    """出售物品，返回 {success, money_earned}"""

func get_sell_price(item_id: String, quality: String) -> int:
    """获取出售价格(考虑质量)"""

## 价格管理
func apply_price_factor(item_id: String, factor: float) -> void:
    """应用价格因子(购买/出售影响)"""

func reset_daily_prices() -> void:
    """每日重置价格"""

func calculate_new_prices() -> void:
    """计算新一天的价格"""

## 市场信息
func is_market_open() -> bool:
    """市场是否营业"""

func get_market_status() -> String:
    """获取市场状态"""

## 存档
func serialize() -> Dictionary
func deserialize(data: Dictionary)
```

## Formulas

### 1. 完整价格计算

```
def calculate_price(item_id):
    base = SHOP_PRICE[item_id]
    season = SEASON_MOD[get_season()][get_item_category(item_id)]
    weather = WEATHER_MOD[get_weather()][get_item_category(item_id)]

    # 供需因子
    demand = (bought_today - sold_today) * 0.05
    demand = clamp(demand, -0.5, 0.5)  # 限制范围

    # 随机波动
    random = random_range(-0.1, 0.1)

    # 最终价格
    final = base * season * weather * (1 + demand) * (1 + random)
    return round(final)
```

### 2. 出售价格计算

```
# 出售价格 = 市场价格 × 质量倍率
sell_price = current_price * QUALITY_MULT[quality]

# QUALITY_MULT = { normal: 0.6, fine: 0.8, excellent: 1.0, supreme: 1.2 }
```

### 3. 价格趋势判定

```
# 与昨日均价比较
yesterday_avg = get_average_price(item_id, yesterday_only=True)
if current_price > yesterday_avg * 1.05: return "up"
elif current_price < yesterday_avg * 0.95: return "down"
else: return "stable"
```

## Edge Cases

### 1. 价格边界

- **价格低于1**: 最小价格为1金币
- **价格超出范围**: 强制限制在基准价的0.5x-3.0x
- **无基准价商品**: 使用上次价格或默认100

### 2. 交易边界

- **背包物品已满**: 出售金币直接添加
- **出售量超过持有**: 只出售持有的数量
- **市场关闭**: 无法交易但可查看价格

### 3. 数据边界

- **价格历史满7天**: 自动清理最早的记录
- **存档迁移**: 价格历史重新开始

## Dependencies

### 上游依赖（P18 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F01** | 时间/季节系统 | 硬依赖 | 季节因子、每日重置 |
| **F02** | 天气系统 | 软依赖 | 天气因子 |
| **C02** | 库存系统 | 软依赖 | 物品数量 |

### 下游依赖（其他系统依赖 P18）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P06** | 商店系统 | 软依赖 | 价格参考 |
| **U06** | 商店UI | 硬依赖 | 价格显示 |

## Tuning Knobs

### 价格波动配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `PRICE_MIN` | 0.5 | 0.3-0.8 | 最低价格倍率 |
| `PRICE_MAX` | 3.0 | 2.0-5.0 | 最高价格倍率 |
| `DEMAND_FACTOR` | 0.05 | 0.02-0.1 | 供需影响系数 |
| `RANDOM_FACTOR` | 0.1 | 0.05-0.2 | 随机波动幅度 |
| `SATURATION_THRESHOLD` | 20 | 10-50 | 饱和阈值 |

### 季节配置

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `SEASON_PRICE_BONUS` | ±20% | 季节价格修正 |
| `WEATHER_PRICE_BONUS` | ±15% | 天气价格修正 |

### 质量倍率

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `SELL_NORMAL` | 0.6 | 普通品质出售倍率 |
| `SELL_FINE` | 0.8 | 优良品质出售倍率 |
| `SELL_EXCELLENT` | 1.0 | 优秀品质出售倍率 |
| `SELL_SUPREME` | 1.2 | 极品品质出售倍率 |

## Visual/Audio Requirements

### 视觉要求

- **价格标签**: 绿色(低价)、红色(高价)、白色(正常)
- **趋势箭头**: ↑(涨价)、↓(跌价)、→(持平)
- **价格历史图表**: 可选的价格走势图

### 音频要求

- **交易音效**: 出售成功时的金币音效
- **价格变化提示**: 显著价格变化时播放

## UI Requirements

| 界面 | 组件 | 描述 |
|------|------|------|
| 市场面板 | MarketPanel | 显示可交易商品和价格 |
| 价格详情 | PriceDetailView | 显示历史价格和趋势 |
| 出售确认 | SellConfirmDialog | 确认出售数量和金额 |

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 价格每日变化 | 连续观察3天 |
| **AC-02** | 季节影响价格 | 跨季节验证 |
| **AC-03** | 购买影响价格 | 大量购买后验证 |
| **AC-04** | 出售功能 | 出售物品获得金币 |
| **AC-05** | 价格历史 | 查看7天内价格 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | F01 每日重置 | 验证每日价格重算 |
| **CS-02** | F02 天气影响 | 不同天气验证价格差异 |

## Open Questions

| ID | 问题 | Owner | Target Date |
|----|------|-------|-------------|
| **OQ-01** | 是否需要NPC商人从市场进货？ | 策划 | Pre-MVP |
| **OQ-02** | 价格预测功能是否需要？ | 策划 | Post-MVP |
| **OQ-03** | 玩家是否有专属商店价格？ | 策划 | Pre-MVP |
