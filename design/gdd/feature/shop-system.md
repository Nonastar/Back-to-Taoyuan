# 商店系统 (Shop System)

> **状态**: In Design
> **Author**: Claude Code
> **Last Updated**: 2026-04-07
> **System ID**: P06
> **Implements Pillar**: 物品管理与资源循环

## Overview

商店系统管理玩家与 NPC 商人之间的交易行为。系统包含多种类型的商店（杂货店、工具店、矿石店等），每个商店有不同的营业时间、商品种类和价格策略。玩家可以购买种子、工具、武器等物品，也可以出售自己的物品获得金币。商店系统是游戏经济的核心枢纽，连接了玩家收入（出售）和支出（购买）。

## Player Fantasy

商店系统给玩家带来**交易的成就感和策略选择的满足感**。玩家应该感受到：

- **选择的乐趣** — 每天决定买什么、不买什么，是早期发展的重要策略
- **财富的流动** — 看着辛苦赚来的金币变成想要的工具或种子
- **商人的熟悉** — 随着与 NPC 好感度提升，解锁更多商品或折扣
- **季节的准备** — 每个季节开始前，到商店购买对应种子做计划

**Reference games**: Stardew Valley 的 Pierre 商店是每日必访；Rune Factory 的武器店提供成长感。

## Detailed Design

### Core Rules

#### 1. 商店类型

| 商店 | 店主 NPC | 商品类型 | 营业时间 |
|------|----------|----------|----------|
| **杂货店** | 小雪 | 种子、肥料、饲料 | 9:00-17:00 |
| **工具店** | 老铁匠 | 工具升级（锄头、镐子等） | 9:00-17:00 |
| **武器店** | 武器商人 | 武器、附魔 | 9:00-22:00 |
| **矿石店** | 矿石商贩 | 矿物、宝石 | 9:00-17:00 |
| **特殊商店** | 多种 | 特殊商品（戒指、特殊物品） | 不固定 |

#### 2. 商品分类与价格

- **季节性商品**: 种子根据季节调整库存（春/夏/秋/冬各有专属种子）
- **品质价格浮动**:
  - Normal: 100% 价格
  - Fine: 120% 价格
  - Excellent: 150% 价格
  - Supreme: 200% 价格

#### 3. 购买流程

```
1. 玩家进入商店，打开商品列表
2. 选择商品和数量
3. 检查玩家金币是否足够
4. 检查背包是否有空间（或选择溢出到临时背包）
5. 扣款(spendMoney) + 添加物品(addItem)
6. 播放购买音效，显示购买成功
```

#### 4. 出售流程

```
1. 玩家打开出售界面（背包中的物品）
2. 选择物品和数量
3. 计算出售价格：
   base_price = 基础价格 × 品质比例
   final_price = base_price × (1 + 好感度加成)
4. 添加金币(earnMoney) + 移除物品(removeItem)
5. 播放出售音效，显示获得金币
```

**注**：出售价格受品质影响，高品质物品出售价更高

#### 5. 好感度影响

- **好感度阈值**: stranger(0), acquaintance(500), friendly(1000), bestFriend(2000)
- **出售加成**:
  - stranger: +0%
  - acquaintance: +2%
  - friendly: +5%
  - bestFriend: +10%

#### 6. 商品解锁

- **基础商品**: 初始即可购买
- **好感度解锁**: 好感度达到后解锁新商品
- **任务解锁**: 完成特定任务后解锁
- **季节解锁**: 特定季节才有的商品

#### 7. 商品解锁条件表

| 商店 | 解锁类型 | 解锁条件 | 解锁商品 |
|------|----------|----------|----------|
| **杂货店** | 季节 | 春季 | 春蔬种子 |
| **杂货店** | 季节 | 夏季 | 夏果种子 |
| **杂货店** | 季节 | 秋季 | 秋粮种子 |
| **杂货店** | 季节 | 冬季 | 冬季作物种子 |
| **工具店** | 好感度 | acquaintance (500) | 铁制工具升级 |
| **工具店** | 好感度 | friendly (1000) | 钢制工具升级 |
| **工具店** | 好感度 | bestFriend (2000) | 铱制工具升级 |
| **武器店** | 好感度 | acquaintance (500) | 铁剑 |
| **武器店** | 好感度 | friendly (1000) | 钢剑 |
| **武器店** | 任务 | 主线任务3 | 蓝钢剑 |
| **矿石店** | 好感度 | friendly (1000) | 高级矿石 |
| **矿石店** | 任务 | 主线任务5 | 宝石类 |

#### 8. 库存机制

- **杂货店**: 每日进货，种子数量有限
- **工具店**: 工具升级需等待 2 天
- **武器店**: 武器无限库存
- **矿石店**: 矿物有限，每周刷新

### States and Transitions

#### 商店营业状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **Closed** | 商店已打烊 | 当前时间在营业时间外 |
| **Open** | 商店营业中 | 当前时间在营业时间内 |
| **Special** | 特殊营业 | 节日/事件期间不限制营业时间 |

#### 购买交易状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **Idle** | 等待选择 | 玩家未选择商品 |
| **Selected** | 已选商品 | 玩家选择了商品和数量 |
| **Processing** | 处理中 | 正在验证和执行交易 |
| **Success** | 购买成功 | 交易完成 |
| **Failed** | 购买失败 | 余额不足或背包满 |

#### 出售交易状态

| 状态 | 描述 | 条件 |
|------|------|------|
| **Idle** | 等待选择 | 玩家未选择物品 |
| **Selected** | 已选物品 | 玩家选择了物品和数量 |
| **Processing** | 处理中 | 正在验证和执行交易 |
| **Success** | 出售成功 | 交易完成 |

**状态转换图**:
```
Idle → Selected: 玩家选择商品/物品
Selected → Processing: 玩家点击购买/出售
Processing → Success: 交易验证通过
Processing → Failed: 交易验证失败（余额不足/背包满）
Success → Idle: 显示结果后重置
Failed → Idle: 显示错误后重置
```

## Formulas

### 1. 购买价格计算

```
# 基础价格来自 F03 ItemDataSystem
base_price = ITEM_DEFS[item_id].base_price

# 品质加成
quality_multiplier = QUALITY_MULTIPLIER[quality]
# NORMAL: 1.0, FINE: 1.2, EXCELLENT: 1.5, SUPREME: 2.0

# 最终购买价格
final_price = base_price × quality_multiplier
```

### 2. 出售价格计算

```
# 基础价格来自 F03 ItemDataSystem
base_price = ITEM_DEFS[item_id].base_price

# 品质加成（出售时品质也影响价格）
quality_multiplier = QUALITY_SELL_MULTIPLIER[quality]
# NORMAL: 1.0, FINE: 1.2, EXCELLENT: 1.5, SUPREME: 2.0

# 好感度加成
friendship_bonus = FRIENDSHIP_SELL_BONUS[friendship_level]
# stranger: 0%, acquaintance: 2%, friendly: 5%, bestFriend: 10%

# 最终出售价格
final_sell_price = floor(base_price × quality_multiplier × (1 + friendship_bonus))
```

### 3. 好感度出售加成表

```
FRIENDSHIP_SELL_BONUS = {
    "stranger": 0.0,      # 0%
    "acquaintance": 0.02, # 2%
    "friendly": 0.05,      # 5%
    "bestFriend": 0.10     # 10%
}
```

### 4. 品质加成表（购买时）

```
QUALITY_MULTIPLIER = {
    "NORMAL": 1.0,
    "FINE": 1.2,
    "EXCELLENT": 1.5,
    "SUPREME": 2.0
}

# 出售时品质也影响价格
QUALITY_SELL_MULTIPLIER = {
    "NORMAL": 1.0,
    "FINE": 1.2,
    "EXCELLENT": 1.5,
    "SUPREME": 2.0
}
```

### 5. 营业时间检查

```
is_open = current_hour >= shop.open_hour AND current_hour < shop.close_hour
```

### 6. 购买验证

```
can_buy = (player.money >= total_price) AND (inventory.has_space OR allow_overflow)
```

### 7. 出售验证

```
can_sell = inventory.has_item(item_id, quantity)
sell_price = calculate_sell_price(item_id, quality)
```

## Edge Cases

### 1. 商店打烊时尝试进入
- **场景**: 在商店营业时间外点击商店
- **处理**: 显示"商店已打烊"提示，显示明日营业时间

### 2. 金币不足时购买
- **场景**: 玩家金币 < 商品总价
- **处理**: 禁用购买按钮，或点击后显示"金币不足"

### 3. 背包满时购买
- **场景**: 主背包和临时背包均满
- **处理**: 显示"背包已满"提示，不允许购买

### 4. 背包满时购买（允许溢出）
- **场景**: 主背包满但临时背包有空间
- **处理**: 弹出选项："放入临时背包"或"取消"

### 5. 出售物品不存在于背包
- **场景**: 尝试出售背包中没有的物品
- **处理**: 该物品不可选，或显示"物品不足"

### 6. 出售数量超过拥有数量
- **场景**: 尝试出售比拥有数量更多的物品
- **处理**: 限制最大出售数量

### 7. 库存有限商品售罄
- **场景**: 种子等限量商品已卖完
- **处理**: 显示"已售罄"标签，次日刷新

### 8. 季节性商品下架
- **场景**: 季节更替后，之前的种子下架
- **处理**: 商品从列表移除，已购买的种子仍可使用

### 9. 好感度变化导致商品解锁
- **场景**: 好感度提升后，新商品解锁
- **处理**: 下次进入商店时自动刷新商品列表

### 10. 快速连续购买
- **场景**: 玩家快速点击购买按钮多次
- **处理**: 使用交易锁，防止重复扣款

## Dependencies

### 上游依赖（P06 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **C01** | PlayerStatsSystem | 硬依赖 | 购买扣款 `spend_money()`，出售获得金币 `earn_money()` |
| **C02** | InventorySystem | 硬依赖 | 购买添加物品 `add_item()`，出售移除物品 `remove_item()` |
| **F03** | ItemDataSystem | 硬依赖 | 查询商品定义、价格、图标 |

### 下游依赖（其他系统依赖 P06）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P17** | TravelingMerchantSystem | 软依赖 | 旅行商人基于商店系统扩展 |

### 关键接口契约

```gdscript
## 订阅的信号

# C01 PlayerStatsSystem
signal money_changed(amount: int)

# C02 InventorySystem
signal inventory_changed()

## 发出的信号

signal shop_opened(shop_id: String)
signal shop_closed(shop_id: String)
signal purchase_completed(item_id: String, quantity: int, total_price: int)
signal sale_completed(item_id: String, quantity: int, money_earned: int)
signal item_unlocked(shop_id: String, item_id: String)
```

### 提供给下游的 API

```gdscript
class_name ShopSystem extends Node

## 单例访问
static func get_instance() -> ShopSystem

## 商店操作
func is_shop_open(shop_id: String) -> bool:
    """检查商店是否营业"""

func get_shop_inventory(shop_id: String) -> Array[ShopItem]:
    """获取商店商品列表"""

func buy_item(shop_id: String, item_id: String, quantity: int) -> Dictionary:
    """购买物品，返回 {success, message, item}"""

func sell_item(shop_id: String, item_id: String, quantity: int) -> Dictionary:
    """出售物品，返回 {success, message, money_earned}"""

func get_item_price(item_id: String, quality: Quality) -> int:
    """获取商品价格（含品质加成）"""

func get_sell_price(item_id: String, quality: Quality) -> int:
    """获取出售价格（含品质和好感度加成）"""

func get_unlocked_items(shop_id: String) -> Array[String]:
    """获取已解锁的商品列表"""
```

## Tuning Knobs

### 商店营业配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `DEFAULT_OPEN_HOUR` | 9 | 6-12 | 默认开门时间 |
| `DEFAULT_CLOSE_HOUR` | 17 | 16-22 | 默认关门时间 |
| `WEAPON_SHOP_CLOSE_HOUR` | 22 | 20-26 | 武器店关门时间（延长时间） |

### 价格配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `QUALITY_MULT_NORMAL` | 1.0 | 固定 | 普通品质价格倍率 |
| `QUALITY_MULT_FINE` | 1.2 | 1.0-1.5 | 优良品质价格倍率 |
| `QUALITY_MULT_EXCELLENT` | 1.5 | 1.2-2.0 | 优秀品质价格倍率 |
| `QUALITY_MULT_SUPREME` | 2.0 | 1.5-3.0 | 史诗品质价格倍率 |

### 好感度出售加成

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `SELL_BONUS_STRANGER` | 0.0 | 0-0 | 陌生人出售加成 |
| `SELL_BONUS_ACQUAINTANCE` | 0.02 | 0-0.05 | 熟人出售加成 |
| `SELL_BONUS_FRIENDLY` | 0.05 | 0.02-0.1 | 友好出售加成 |
| `SELL_BONUS_BESTFRIEND` | 0.10 | 0.05-0.2 | 挚友出售加成 |

### 库存配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `SEED_STOCK_DAILY` | 50 | 20-100 | 每日种子进货数量 |
| `ORE_STOCK_WEEKLY` | 20 | 10-50 | 每周矿石进货数量 |
| `TOOL_UPGRADE_DAYS` | 2 | 1-5 | 工具升级等待天数 |

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 商店营业时间正确 | 在营业时间内/外进入商店 |
| **AC-02** | 购买流程正确 | 选择商品、确认购买，验证扣款和物品 |
| **AC-03** | 出售流程正确 | 选择物品出售，验证金币增加和物品移除 |
| **AC-04** | 价格计算正确 | 验证品质加成和好感度加成 |
| **AC-05** | 金币不足阻止购买 | 余额不足时点击购买 |
| **AC-06** | 背包满阻止购买 | 背包满时点击购买 |
| **AC-07** | 商品解锁正确 | 好感度提升后验证新商品出现 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | 购买后物品入背包 | buy_item 后验证 C02.add_item |
| **CS-02** | 出售后金币增加 | sell_item 后验证 C01.earn_money |
| **CS-03** | 购买扣款 | buy_item 后验证 C01.spend_money |
| **CS-04** | 存档后读档 | serialize/deserialize 验证商店状态 |

### 性能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **PC-01** | 购买处理 < 100ms | buy_item 执行时间 |
| **PC-02** | 商店列表加载 < 50ms | get_shop_inventory 执行时间 |

### 边界情况测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **BC-01** | 快速连续购买 | 快速点击购买按钮多次 |
| **BC-02** | 出售全部物品 | 出售背包中最后一组物品 |
| **BC-03** | 季节更替 | 验证种子列表变化 |

## Open Questions

[To be designed]
