# 沙漠/赌场系统 (Hanhai Casino System)

> **Status**: Approved
> **Author**: Claude + User
> **Last Updated**: 2026-04-07
> **Implements Pillar**: 角色养成与自定义化

## Overview

汉海赌场系统是游戏中的高级娱乐区域，整个汉海沙漠作为赌场地图呈现。系统包含德州扑克、左轮赌盘等赌博小游戏，以及配套的入场费、大厅分级和特殊NPC。玩家通过积累财富进入这个高风险高回报的区域，在各种赌博游戏中挑战运气，每种游戏都有多个难度档次，适合不同财富水平的玩家。

**P14 与 M02/M03 职责划分**:
- **P14 沙漠/赌场系统**: 负责赌场区域框架、入场管理、大厅分级、金币交易、会话统计
- **M02 德州扑克小游戏**: 负责扑克游戏的具体规则实现、AI决策、发牌逻辑、胜负判定
- **M03 左轮赌盘小游戏**: 负责左轮赌盘的具体游戏流程、弹匣管理、道具效果

## Player Fantasy

汉海赌场系统给玩家带来**一夜暴富的刺激感和赌徒的紧张感**。玩家应该感受到：

- **踏入异域的惊奇** — 汉海沙漠与农场风格迥异，充满神秘与机遇。沙漠的荒凉与赌场的霓虹形成对比
- **运气的博弈** — 德州扑克的策略与读心让玩家感觉自己是牌桌高手；左轮赌盘的纯粹运气让每一声枪响都心跳加速
- **财富的瞬间变化** — 一次好牌可以赢得盆满钵满，一次爆仓可能血本无归。这种刺激感是其他系统无法提供的
- **专属场地的仪式感** — 支付入场费进入高级区域的感觉，让玩家感受到身份的提升

**Reference games**: Stardew Valley 的赌场（Ja 的 Casino）；Red Dead Redemption 2 的扑克；任何赌场游戏的筹码系统。

**情感曲线**:
1. **初入赌场**: 好奇、谨慎、小额尝试
2. **熟悉规则**: 自信增加、开始提高赌注
3. **高潮时刻**: 大胜时的兴奋或大输时的懊恼
4. **退出结算**: 带着筹码离开或一无所有

## Detailed Design

### Core Rules

#### 1. 区域概述

汉海赌场是一个沙漠地图，包含以下设施：

| 设施 | 描述 |
|------|------|
| **赌场入口** | 支付入场费进入主赌博区 |
| **德州扑克厅** | 三档赌注的扑克游戏（M02） |
| **左轮赌厅** | 子弹轮盘赌游戏（M03） |
| **信息板** | 显示玩家金币余额和会话统计 |
| **休息区** | 赌场NPC休息处，提供对话 |

> **注**: 赌场直接使用玩家金币进行赌博，无需兑换筹码。

#### 2. 进入条件

**入场费**:
- 标准厅: 100 金币
- 中级厅: 500 金币
- 高级厅: 2000 金币

**进入流程**:
```
if player.money >= ENTRY_FEE[current_room]:
    player.spend_money(ENTRY_FEE)
    enter_casino()
else:
    show_message("金币不足，无法进入")
```

#### 3. 赌场大厅分级

| 大厅 | 入场费 | 赌注下限 | 赌注上限 | AI对手强度 |
|------|--------|----------|----------|------------|
| **标准厅** | 100g | 10g | 500g | 新手 |
| **中级厅** | 500g | 50g | 2000g | 普通 |
| **高级厅** | 2000g | 200g | 10000g | 高手 |

#### 4. 德州扑克 (Texas Hold'em)

**游戏规则**:
- 使用标准德州扑克规则
- 玩家 vs 3个AI对手
- 每局由系统发牌
- 赌注在每轮下注前确定

**下注档位**:
| 档位 | 最低下注 | 最高下注 |
|------|----------|----------|
| 低档 | 10g | 50g |
| 中档 | 50g | 200g |
| 高档 | 200g | 1000g |

**游戏流程**:
1. 玩家选择座位和下注档位
2. 系统发底牌
3. 第一轮下注 (翻牌前)
4. 发翻牌 (3张公共牌)
5. 第二轮下注
6. 发转牌 (1张公共牌)
7. 第三轮下注
8. 发河牌 (1张公共牌)
9. 第四轮下注
10. 摊牌比大小

**胜负判定**:
- 按标准扑克牌型大小判定
- 牌型: 高牌 < 一对 < 两对 < 三条 < 顺子 < 同花 < 葫芦 < 四条 < 同花顺 < 皇家同花顺

#### 5. 左轮赌盘 (Buckshot Roulette)

**游戏规则**:
- 玩家 vs 庄家 (AI)
- 使用左轮手枪，弹匣有随机数量子弹
- 轮流开枪，轮到玩家时选择对自己或对方开枪
- 被击中者失败

**生命系统**:
- 每轮开始时，玩家和庄家各有 **2条命**
- 被实弹击中减少1条命
- 当命数归零时，该方失败
- 啤酒道具可恢复1条命（每轮最多使用1次）

**弹匣机制**:
```
total_bullets = random(2, 8)  # 随机2-8颗子弹
bullet_count = random(1, total_bullets)  # 实际装填数量
```

**子弹类型**:
| 类型 | 效果 | 概率 |
|------|------|------|
| 普通子弹 | 即时失败 | 80% |
| 空包弹 | 无事发生 | 20% |

**特殊道具** (可购买):
| 道具 | 价格 | 效果 |
|------|------|------|
| 放大镜 | 50g | 查看下一发子弹类型 (一次性) |
| 啤酒 | 100g | 恢复一次生命 (有2条命) |
| 手枪 | 500g | 强制对方先开一枪 |

**下注机制**:
- 开枪前需下注
- 胜利获得下注金额 × 2
- 失败损失下注金额

#### 6. 赌场NPC

**荷官 NPC**:
- 负责德州扑克发牌和结算
- 提供游戏规则说明

**庄家 NPC**:
- 负责左轮赌盘
- 提供难度选择

**领班 NPC**:
- 位于信息板附近
- 提供会话统计和技巧提示

#### 7. 赌注限制

**单局限制**:
- 单局最高下注: 大厅最高赌注
- 单日累计损失上限: 无 (风险由玩家承担)

**安全机制**:
- 当玩家金币 < 最低赌注时，禁止进入赌博游戏
- 提示玩家"金币不足，请下次再来"

### States and Transitions

#### 玩家赌场状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Outside** | 玩家在赌场外 | 未支付入场费 |
| **StandardHall** | 在标准厅 | 支付100g入场费 |
| **MidHall** | 在中级厅 | 支付500g入场费 |
| **HighHall** | 在高级厅 | 支付2000g入场费 |
| **PlayingPoker** | 在玩德州扑克 | 进入扑克桌 |
| **PlayingRoulette** | 在玩左轮赌盘 | 进入左轮赌桌 |

**状态转换**:
```
Outside → StandardHall: pay_entry_fee(100)
Outside → MidHall: pay_entry_fee(500)
Outside → HighHall: pay_entry_fee(2000)
StandardHall → MidHall: pay_entry_fee(400)
MidHall → HighHall: pay_entry_fee(1500)
[Hall] → PlayingPoker: sit_at_poker_table()
[Hall] → PlayingRoulette: start_roulette_round()
PlayingPoker → [Hall]: end_hand()
PlayingRoulette → [Hall]: end_round()
Any → Outside: exit_casino()
```

#### 德州扑克游戏状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Dealing** | 发牌阶段 | 玩家坐下 |
| **PreFlop** | 翻牌前下注 | 发完底牌 |
| **Flop** | 翻牌阶段 | 下注完成后 |
| **Turn** | 转牌阶段 | Flop下注完成后 |
| **River** | 河牌阶段 | Turn下注完成后 |
| **Showdown** | 摊牌 | River下注完成后 |
| **RoundEnd** | 本轮结束 | 胜负已判定 |

#### 左轮赌盘游戏状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Loading** | 装弹阶段 | 开始游戏 |
| **PlayerTurn** | 玩家回合 | 轮到玩家开枪 |
| **DealerTurn** | 庄家回合 | 轮到庄家开枪 |
| **BulletFire** | 子弹击发 | 有人扣动扳机 |
| **GameEnd** | 游戏结束 | 有人被击中或投降 |

### Interactions with Other Systems

#### 依赖系统 (Upstream Dependencies)

| System | Interface | Usage |
|--------|-----------|-------|
| **C01 玩家属性系统** | `spend_money()`, `earn_money()`, `get_money()` | 赌博消耗/获得金币 |
| **C02 库存系统** | `add_item()`, `remove_item()` | 购买赌场道具 |
| **F01 时间/季节系统** | `get_day()`, `get_hour()` | 赌场开放时间? (可选) |

#### 事件订阅 (Event Subscriptions)

```gdscript
# 赌场系统发出
signal casino_entered(hall_level: int)
signal casino_exited(total_won: int, total_lost: int)
signal poker_hand_started(players: int, blind: int)
signal poker_hand_ended(winner: String, pot: int)
signal roulette_round_started(bullets: int, bet: int)
signal roulette_round_ended(player_won: bool, prize: int)
signal big_win(amount: int)  # 大赢触发

# 订阅其他系统信号
F01.sleep_triggered → on_sleep()  # 重置赌场会话
```

#### API 接口

```gdscript
class_name HanhaiCasinoSystem extends Node

## 区域访问
func can_enter(hall_level: int) -> bool:
    """检查是否满足进入条件"""

func enter_casino(hall_level: int) -> bool:
    """进入指定大厅，返回是否成功"""

func exit_casino() -> void:
    """离开赌场"""

func get_current_hall() -> int:
    """获取当前所在大厅等级"""

## 德州扑克
func sit_at_poker_table(position: int, bet_level: int) -> bool:
    """坐下开始一局"""

func poker_action(action: String, amount: int = 0) -> bool:
    """执行扑克动作 (fold/call/raise/allin)"""

func leave_poker_table() -> void:
    """离开扑克桌"""

func get_poker_game_state() -> Dictionary:
    """获取当前扑克游戏状态"""

## 左轮赌盘
func start_roulette_round(bet_amount: int) -> bool:
    """开始一轮左轮赌盘"""

func roulette_action(action: String) -> bool:
    """执行左轮赌盘动作 (shoot_self/shoot_dealer/buy_item/give_up)"""

func get_roulette_state() -> Dictionary:
    """获取当前左轮赌盘状态"""

## 道具
func buy_roulette_item(item_id: String) -> bool:
    """购买左轮赌盘道具"""

func use_roulette_item(item_id: String) -> bool:
    """使用左轮赌盘道具"""

## 统计
func get_session_stats() -> Dictionary:
    """获取当前会话统计"""

## 存档
func serialize() -> Dictionary
func deserialize(data: Dictionary)
```

## Formulas

### 1. 入场费计算

```
# 不同大厅的入场费
ENTRY_FEE[hall_level] = {
    1: 100,    # 标准厅
    2: 500,    # 中级厅
    3: 2000    # 高级厅
}

# 同厅再次进入无需付费
already_inside[hall_level] = has_paid_entry[hall_level] && current_hall != outside
```

### 2. 德州扑克底池计算

```
# 每轮下注累计到底池
pot += current_bet

# 玩家赢得金额
player_winnings = pot - player_contributions

# 庄家抽水 (可选)
rake = floor(pot * RAKE_RATE)  # RAKE_RATE = 0.05
net_winnings = pot - rake
```

### 3. 左轮赌盘子弹概率

```
# 弹匣总容量 (2-8)
max_chamber = random(2, 8)

# 实际装填子弹数 (1到总容量)
loaded_bullets = random(1, max_chamber)

# 空包概率
empty_chance = EMPTY_BULLET_RATE * EMPTY_CHAMBERS
# EMPTY_BULLET_RATE = 0.2, EMPTY_CHAMBERS = floor(loaded_bullets * 0.2)

# 下一发是实弹的概率
live_probability = (loaded_bullets - empty_chambers) / max_chamber
```

### 4. 左轮赌盘收益

```
# 胜利收益
prize = bet_amount * ODDS
# ODDS = 2 (标准)

# 购买道具后重新计算
adjusted_odds = ODDS * ITEM_BONUS[item_id]
```

### 5. AI对手强度调整

```
# 不同大厅的AI激进度
AI_AGGRESSION[hall_level] = {
    1: 0.3,   # 新手: 保守
    2: 0.5,   # 普通: 中等
    3: 0.8    # 高手: 激进
}

# AI加注概率
raise_prob = AI_AGGRESSION[hall_level] * hand_strength

# AI跟注概率
call_prob = 0.5 + (hand_strength - 0.5) * AI_AGGRESSION[hall_level]
```

### 6. 大赢判定

```
# 触发"大赢"动画和音效的阈值
BIG_WIN_THRESHOLD = 1000  # 单次赢得超过1000金币

if winnings >= BIG_WIN_THRESHOLD:
    trigger_big_win_effect()
    emit_signal("big_win", winnings)
```

### 7. 金币实时结算

```
# 赌博胜利：实时获得金币
if player_wins:
    player.earn_money(prize)
    session_won += prize

# 赌博失败：实时扣除金币
if player_loses:
    player.spend_money(bet_amount)
    session_lost += bet_amount
```

### 8. 每日赌场会话统计

```
# 会话结束时汇总（仅用于显示）
session_profit = session_won - session_lost

# 每日重置（不影响玩家金币，因为已实时结算）
session_won = 0
session_lost = 0
```

### 9. 赌场优势率 (House Edge)

```
# 赌场长期优势率（保证赌场盈利）
HOUSE_EDGE_POKER = 0.02    # 扑克: 2%
HOUSE_EDGE_ROULETTE = 0.10  # 左轮赌盘: 10%

# 实际玩家胜率应接近 (1 - HOUSE_EDGE)
# 这通过AI对手强度和赔率调整实现
```

## Edge Cases

### 1. 金币边界

- **金币不足入场**: 提示"金币不足，无法进入[大厅名]"，返回 false
- **赌博中金币耗尽**: 立即结束当前游戏，判定为负
- **赢得金币超过整数上限**: 使用 64 位整数存储

### 2. 德州扑克边界

- **所有AI弃牌**: 玩家自动获胜，获得底池
- **玩家弃牌**: 失去当前下注，结束本局
- **平局**: 底池平均分配，如无法平分则多出的一枚归庄家
- **玩家全下(All-in)**: 只能赢得与全下金额相等的底池部分

### 3. 左轮赌盘边界

- **弹匣全空**: 视为空包，玩家获胜
- **连续5发空包**: 提示"运气太好"，玩家获胜
- **连续5发实弹**: 提示"运气太差"，玩家失败
- **投降**: 失去当前下注，游戏结束

### 4. 道具使用边界

- **道具已用完**: 禁用购买按钮
- **持有道具数量上限**: 1个 (一次性道具)
- **对已死的自己使用道具**: 无效

### 5. 会话边界

- **玩家在赌场时睡眠**: 强制退出赌场，会话统计保存
- **玩家在赌博时退出游戏**: 视为弃牌，损失当前下注
- **中途关闭游戏**: 下次进入时恢复，但赌博进度丢失

### 6. AI行为边界

- **AI无钱可下**: AI自动弃牌
- **所有AI都弃牌**: 玩家独赢底池
- **AI连续获胜过多**: 不做干预 (玩家可以提升技能或换大厅)

## Dependencies

### 上游依赖（P14 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **C01** | 玩家属性系统 | 硬依赖 | `spend_money()`, `earn_money()`, `get_money()` |
| **C02** | 库存系统 | 硬依赖 | `add_item()`, `remove_item()`, `has_item()` |
| **F01** | 时间/季节系统 | 软依赖 | 睡眠触发会话重置 |

### 下游依赖（其他系统依赖 P14）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P09** | 成就系统 | 软依赖 | 赌博相关成就 |
| **M02** | 德州扑克小游戏 | 调用方 | P14调用M02进行扑克游戏 |
| **M03** | 左轮赌盘小游戏 | 调用方 | P14调用M03进行左轮赌盘 |

> **P14 调用 M02/M03**: P14 是管理者，M02/M03 是被管理的游戏模块。P14 提供金币交易接口，M02/M03 实现具体游戏逻辑后回调 P14 进行结算。

### 关键接口契约

```gdscript
## 订阅的信号

# C01 玩家属性系统
signal money_changed(amount: int)

# F01 时间/季节系统
signal sleep_triggered(bedtime: int, forced: bool)

## 发出的信号

signal casino_entered(hall_level: int)
signal casino_exited(total_won: int, total_lost: int)
signal poker_hand_started(players: int, blind: int)
signal poker_hand_ended(winner: String, pot: int)
signal roulette_round_started(bullets: int, bet: int)
signal roulette_round_ended(player_won: bool, prize: int)
signal big_win(amount: int)
```

## Tuning Knobs

### 大厅配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `ENTRY_FEE_STANDARD` | 100 | 50-500 | 标准厅入场费 |
| `ENTRY_FEE_MID` | 500 | 200-2000 | 中级厅入场费 |
| `ENTRY_FEE_HIGH` | 2000 | 1000-10000 | 高级厅入场费 |
| `MIN_BET_STANDARD` | 10 | 5-50 | 标准厅最低赌注 |
| `MIN_BET_MID` | 50 | 20-200 | 中级厅最低赌注 |
| `MIN_BET_HIGH` | 200 | 100-1000 | 高级厅最低赌注 |
| `MAX_BET_STANDARD` | 500 | 200-2000 | 标准厅最高赌注 |
| `MAX_BET_MID` | 2000 | 1000-10000 | 中级厅最高赌注 |
| `MAX_BET_HIGH` | 10000 | 5000-50000 | 高级厅最高赌注 |

### AI难度配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `AI_AGGRESSION_STANDARD` | 0.3 | 0.1-0.5 | 标准厅AI激进度 |
| `AI_AGGRESSION_MID` | 0.5 | 0.3-0.7 | 中级厅AI激进度 |
| `AI_AGGRESSION_HIGH` | 0.8 | 0.6-1.0 | 高级厅AI激进度 |
| `AI_STARTING_CHIPS` | 1000 | 500-5000 | AI起始筹码 |

### 左轮赌盘配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `MIN_CHAMBER` | 2 | 1-4 | 弹匣最小容量 |
| `MAX_CHAMBER` | 8 | 6-12 | 弹匣最大容量 |
| `EMPTY_CHANCE` | 0.2 | 0.1-0.4 | 空包概率 |
| `ROULETTE_ODDS` | 2 | 1-3 | 左轮赌盘赔率 |
| `BIG_WIN_THRESHOLD` | 1000 | 500-5000 | 大赢触发阈值 |
| `INITIAL_LIVES` | 2 | 1-3 | 初始生命数 |
| `BEER_LIVES_RESTORE` | 1 | 1-2 | 啤酒恢复生命数 |

### 赌场平衡配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `HOUSE_EDGE_POKER` | 0.02 | 0.01-0.05 | 德州扑克赌场优势率 |
| `HOUSE_EDGE_ROULETTE` | 0.10 | 0.05-0.20 | 左轮赌盘赌场优势率 |

### 道具配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `MAGNIFYING_GLASS_PRICE` | 50 | 25-200 | 放大镜价格 |
| `BEER_PRICE` | 100 | 50-300 | 啤酒价格 |
| `GUN_PRICE` | 500 | 200-2000 | 手枪价格 |
| `MAGNIFYING_GLASS_USES` | 1 | 1-3 | 放大镜使用次数 |

### 扑克配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `POKER_PLAYERS` | 4 | 2-6 | 每桌玩家数 |
| `BLIND_STANDARD` | 10 | 5-50 | 标准厅大小盲 |
| `BLIND_MID` | 50 | 20-200 | 中级厅大小盲 |
| `BLIND_HIGH` | 200 | 100-1000 | 高级厅大小盲 |
| `RAKE_RATE` | 0.05 | 0-0.1 | 庄家抽水比例 |

## Visual/Audio Requirements

### 视觉要求

- **赌场入口**: 沙漠风格的拱门建筑，霓虹灯招牌
- **扑克厅**: 绿色赌桌，扑克牌UI，金币流动动画
- **左轮赌厅**: 昏暗灯光，左轮手枪模型，子弹装填动画
- **大赢效果**: 金币喷涌动画，闪光特效

### 音频要求

- **背景音乐**: 赌场风格BGM，柔和的爵士乐
- **发牌音效**: 扑克牌翻动声
- **下注音效**: 金币落入底池的声音
- **胜利音效**: 欢快的胜利音乐
- **失败音效**: 低沉的失败音乐
- **左轮音效**: 枪栓拉动、开枪、击发空包

## UI Requirements

| 界面 | 组件 | 描述 |
|------|------|------|
| 赌场入口界面 | CasinoEntryView | 显示三个大厅选项和入场费 |
| 扑克桌界面 | PokerTableView | 显示牌桌、玩家、手牌、公共牌 |
| 扑克控制面板 | PokerControlPanel | 下注、弃牌、跟注、加注按钮 |
| 左轮赌桌界面 | RouletteTableView | 显示枪、弹匣、道具 |
| 左轮控制面板 | RouletteControlPanel | 开枪方向、购买道具按钮 |
| 赌场统计面板 | CasinoStatsPanel | 显示当前会话赢输统计 |

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 三个大厅可以正常进入 | 支付入场费后进入对应大厅 |
| **AC-02** | 金币不足时禁止进入 | 拥有<100金币尝试进入 |
| **AC-03** | 德州扑克完整流程 | 完成一局扑克并结算 |
| **AC-04** | 左轮赌盘完整流程 | 完成一轮并结算 |
| **AC-05** | 道具购买和使用 | 购买放大镜并使用 |
| **AC-06** | 大赢触发特效 | 单次赢得>1000金币 |
| **AC-07** | 赌场会话统计 | 查看当前会话赢输 |
| **AC-08** | 存档/读档 | 保存后读取验证 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | 赌博消耗金币 | 赌博后验证金币减少 |
| **CS-02** | 赌博获得金币 | 赌博胜利后验证金币增加 |
| **CS-03** | 睡眠重置会话 | 在赌场睡眠验证会话重置 |
| **CS-04** | 成就触发 | 赌博相关成就解锁 |

### 性能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **PC-01** | 扑克发牌 < 100ms | 记录发牌耗时 |
| **PC-02** | 筹码动画 < 60fps | 观察动画流畅度 |

### 边界情况测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **BC-01** | 金币刚好够入场 | 拥有100金币进入标准厅 |
| **BC-02** | 连续弃牌 | 多次弃牌验证状态 |
| **BC-03** | 弹匣全空 | 触发全空场景 |

## Open Questions

| ID | 问题 | Owner | Target Date |
|----|------|-------|-------------|
| **OQ-01** | 赌场是否有每日进入次数限制？ | 策划 | Pre-MVP |
| **OQ-02** | 扑克AI是否有作弊风险（明牌）？ | 技术 | Pre-MVP |
| **OQ-03** | 赌场BGM是否需要根据大厅变化？ | 音频 | Pre-MVP |
| **OQ-04** | 赌博相关成就列表有哪些？ | 策划 | 与P09协调 |
| **OQ-05** | 大赢阈值是否应为动态值（根据大厅调整）？ | 策划 | Pre-MVP |
