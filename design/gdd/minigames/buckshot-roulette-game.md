# 左轮赌盘小游戏 (Buckshot Roulette Mini-Game)

> **状态**: Approved
> **Author**: Claude Code
> **Last Updated**: 2026-04-07
> **System ID**: M03
> **Implements Pillar**: Mini-game 玩法

## Overview

左轮赌盘小游戏是沙漠赌场系统的高风险赌博游戏。玩家与庄家进行俄罗斯轮盘赌对决，使用装有随机数量子弹的左轮手枪，轮流选择对自己或对方开枪。小游戏包含弹匣管理、子弹类型识别、生命值系统，以及放大镜、啤酒、手枪等道具的特殊效果。

设计为 Standard 复杂度，包含：
1. **弹匣系统**：随机装填子弹，触发紧张感
2. **开枪机制**：选择开枪目标，押注生死
3. **道具系统**：放大镜查看子弹、啤酒恢复生命、手枪强制对手先开
4. **生命系统**：2条命，决定生死

小游戏独立于主游戏运行，完成后根据结果与 P14 交互进行金币结算。

## Player Fantasy

左轮赌盘小游戏给玩家带来**纯粹运气与心理博弈的极致紧张感**。玩家应该感受到：

- **枪口的恐惧** — 看着左轮手枪转动的弹匣，每一发都是生死之间
- **选择的煎熬** — 对自己开枪还是对庄家开枪？这个决定让玩家的心脏几乎停止
- **空包的庆幸** — 扣下扳机听到"咔"的一声，如释重负
- **实弹的绝望** — 枪声响起，命数减少，希望在最后一刻
- **绝杀的疯狂** — 最后一发子弹，All-in 一切

参考游戏：
- **俄罗斯轮盘赌**: 最纯粹的勇气与运气考验
- **左轮赌盘 (Buckshot Roulette)**: 经典的赌场小游戏，增加子弹数量和生命系统
- **任何高赌注游戏**: 肾上腺素飙升的感觉

**情感曲线**:
1. **装弹阶段**: 期待、紧张、不知道有多少子弹
2. **第一发**: 恐惧、赌一把的冲动
3. **连续空包**: 希望增加、开始大胆
4. **接近死亡**: 极度紧张、犹豫不决
5. **最后胜利**: 劫后余生、极度满足

## Detailed Design

### Core Rules

#### 1. 弹匣系统

##### 1.1 弹匣初始化

```
弹匣容量: 随机 2-8 颗
实际装填: 随机 1-容量 颗子弹

实际装填子弹数 = random(1, max(1, 总容量))
```

##### 1.2 子弹类型

| 类型 | 效果 | 概率 |
|------|------|------|
| **实弹** | 击中目标，减少 1 条命 | 80% |
| **空包弹** | 无事发生 | 20% |

> **注**: 空包弹不消耗子弹，是真正的"空"。

##### 1.3 弹匣状态

```
剩余子弹: 0-8 颗
当前弹位: 0-7 (当前轮到哪一发)

弹匣是一个循环队列
每开枪一次，当前弹位 +1 (循环)
```

#### 2. 生命系统

##### 2.1 生命规则

```
初始生命: 2 条

被实弹击中: 生命 - 1
生命归零: 游戏结束，失败

生命 > 0: 继续游戏
生命 = 0: 失败
```

##### 2.2 生命显示

```
玩家生命: ♥ ♥ (2个心形图标)
庄家生命: ♥ ♥ (2个心形图标)

被击中时: 对应的 ♥ 变灰/消失
```

#### 3. 开枪机制

##### 3.1 回合流程

```
1. 回合开始
   - 玩家决定行动（开枪/道具/投降）
   - 玩家选择开枪目标
2. 发射子弹
   - 判定当前弹位子弹类型
   - 触发命中/空包效果
3. 结果处理
   - 更新生命值
   - 检查是否有人死亡
   - 如未死亡，轮到对方
```

##### 3.2 开枪目标

| 目标 | 说明 |
|------|------|
| **对自己开枪** | 风险自己承担，可能损失生命 |
| **对庄家开枪** | 庄家承担风险，但庄家可能反击 |

> **注**: 默认选择是对自己开枪。选择对庄家开枪需要确认。

##### 3.3 子弹顺序

```
弹匣按顺序排列: [弹1, 弹2, 弹3, ..., 弹N]

每次开枪从弹匣顶部发射
发射后该子弹消耗（无论实弹空包）

下一发射击弹2，以此类推
```

#### 4. 道具系统

##### 4.1 道具列表

| 道具 | 价格 | 效果 | 限制 |
|------|------|------|------|
| **放大镜** | 50g | 查看下一发子弹类型（一次性）| 每局最多 1 次 |
| **啤酒** | 100g | 恢复 1 条生命 | 每局最多 2 次 |
| **手枪** | 500g | 强制庄家先开一枪 | 每局最多 1 次 |

##### 4.2 放大镜效果

```
使用放大镜后:
- 显示下一发子弹是"实弹"还是"空包"
- 仅显示下一发，不影响弹匣
- 只能使用一次
```

##### 4.3 啤酒效果

```
使用啤酒后:
- 恢复 1 条生命
- 如果生命已满，则无效果
- 每局最多使用 2 次
```

##### 4.4 手枪效果

```
使用手枪后:
- 跳过玩家回合
- 强制庄家先开一枪
- 如果庄家被击中，游戏直接结束
```

#### 5. 下注与结算

##### 5.1 下注规则

```
每轮开始前需下注
最低下注: 10g
最高下注: 根据大厅等级 (500g/2000g/10000g)

下注后开始回合
```

##### 5.2 结算规则

```
胜利: 获得下注金额 × 2
失败: 损失下注金额

示例:
  下注 100g
  胜利 → 获得 200g（净利润 100g）
  失败 → 损失 100g
```

#### 6. 游戏流程

```
┌─────────────────────────────────────────┐
│  1. 下注阶段                              │
│     └─ 玩家选择下注金额                    │
├─────────────────────────────────────────┤
│  2. 装弹阶段                              │
│     └─ 随机生成弹匣                       │
├─────────────────────────────────────────┤
│  3. 回合循环                              │
│     └─ 玩家行动 → 开枪 → 结果 → 庄家回合 │
│           ↓                               │
│     [玩家可用道具]                         │
│           ↓                               │
│     [玩家选择目标]                         │
│           ↓                               │
│     [发射子弹]                             │
│           ↓                               │
│     [判定命中/空包]                       │
│           ↓                               │
│     [更新生命]                            │
│           ↓                               │
│     [检查游戏结束]                         │
├─────────────────────────────────────────┤
│  4. 游戏结束                              │
│     └─ 显示胜负结果 → 结算金币            │
└─────────────────────────────────────────┘
```

#### 7. 结果回调 P14

```gdscript
# 游戏结束时，向 P14 发送结果
结果 = {
    "success": bool,              # 玩家是否获胜
    "bet_amount": int,            # 下注金额
    "net_profit": int,            # 净收益 (正数=赢, 负数=输)
    "shots_fired": int,           # 总发射子弹数
    "magnifying_glass_used": bool,# 是否使用过放大镜
    "beer_used": int,             # 使用啤酒次数
    "gun_used": bool,             # 是否使用过手枪
    "game_duration": float,       # 游戏时长（秒）
    "final_player_lives": int,    # 最终玩家生命
    "final_dealer_lives": int     # 最终庄家生命
}

emit_signal("roulette_round_ended", 结果)
```

### States and Transitions

#### 游戏状态机

```
┌─────────────┐
│    IDLE    │ ← 未开始
└──────┬──────┘
       │ 开始游戏
       ↓
┌─────────────┐
│   BETTING  │ ← 下注阶段
└──────┬──────┘
       │ 下注完成
       ↓
┌─────────────┐
│   LOADING  │ ← 装弹阶段
└──────┬──────┘
       │ 弹匣装填完成
       ↓
┌──────────────┐
│ PLAYER_TURN │ ← 玩家回合
└──────┬───────┘
       │ 玩家行动完成
       ↓
┌─────────────┐
│   FIRING   │ ← 发射子弹
└──────┬──────┘
       │ 子弹发射完成
       ↓
   ┌──┴──┐
   ↓      ↓
[命中]  [空包]
   ↓      ↓
┌────────────┐    ┌────────────┐
│ LIFE_LOST │    │   CHECK   │
└─────┬─────┘    └─────┬─────┘
      │ 生命>0         │
      ↓               ↓
┌──────────────┐  ┌──────────────┐
│ DEALER_TURN │  │ DEALER_TURN │
└──────┬──────┘  └──────┬──────┘
       │ 庄家行动完成    │
       ↓               ↓
   ┌──┴──┐            │
[命中]  [空包]────────┘
   ↓      ↓
┌────────────┐    ┌────────────┐
│ GAME_OVER │    │PLAYER_TURN │ ← 继续循环
└──────────┘    └────────────┘
       │
       ↓
┌──────────────┐
│   SHOWDOWN  │ ← 显示结果
└──────┬───────┘
       │ 结算完成
       ↓
┌─────────────┐
│    IDLE    │ ← 返回 P14
└───────────┘
```

#### 详细状态定义

| 状态 | 描述 | 入口条件 | 出口条件 | 持续时间 |
|------|------|----------|----------|----------|
| `Idle` | 未开始 | 系统初始化 | 调用 start_game | - |
| `Betting` | 下注阶段 | start_game | 下注完成 | 5-30s |
| `Loading` | 装弹阶段 | 下注完成 | 弹匣装填完成 | 1-2s |
| `PlayerTurn` | 玩家回合 | 轮到玩家 | 玩家行动完成 | 10-60s |
| `Firing` | 发射子弹 | 扣动扳机 | 子弹发射完成 | 1-2s |
| `LifeLost` | 生命减少 | 实弹命中 | 检查游戏是否结束 | 1s |
| `DealerTurn` | 庄家回合 | 轮到庄家 | 庄家行动完成 | 2-5s |
| `Showdown` | 显示结果 | 游戏结束 | 结算完成 | 2-3s |

#### 玩家行动状态

| 状态 | 描述 |
|------|------|
| `Choosing` | 选择行动中 |
| `ShootSelf` | 选择对自己开枪 |
| `ShootDealer` | 选择对庄家开枪 |
| `UsingItem` | 使用道具中 |
| `Surrendering` | 投降中 |
| `Acted` | 本轮行动完成 |

#### 状态转换表

| 当前状态 | 事件 | 下一状态 | 触发条件 |
|----------|------|----------|----------|
| Idle | `start_game()` | Betting | P14 调用 |
| Betting | 下注完成 | Loading | 玩家确认下注 |
| Loading | 装填完成 | PlayerTurn | 弹匣生成 |
| PlayerTurn | 玩家选择开枪 | Firing | 选择目标 |
| PlayerTurn | 使用道具 | PlayerTurn | 选择不同行动 |
| PlayerTurn | 投降 | Showdown | 投降确认 |
| PlayerTurn | 超时 | Firing | 默认对自己开枪 |
| Firing | 空包 | Check | 子弹是空包 |
| Firing | 实弹命中 | LifeLost | 子弹是实弹 |
| LifeLost | 生命 > 0 | DealerTurn | 未死亡 |
| LifeLost | 生命 = 0 | Showdown | 死亡 |
| Check | 仅玩家行动 | DealerTurn | - |
| Check | 仅庄家行动 | PlayerTurn | - |
| DealerTurn | 庄家行动完成 | Firing | - |
| Showdown | 结算完成 | Idle | 动画播放完 |

#### 信号定义

```gdscript
# M03 发出的信号
signal game_started()
signal bullets_loaded(chamber_count: int, live_count: int)
signal player_turn()
signal dealer_turn()
signal bullet_fired(target: String, bullet_type: String, hit: bool)
signal life_changed(target: String, lives: int)
signal item_used(item_id: String, success: bool)
signal roulette_round_ended(result: Dictionary)

# P14 调用的方法
func start_round(bet_amount: int) -> bool
func player_shoot_self() -> void
func player_shoot_dealer() -> void
func use_item(item_id: String) -> bool
func surrender() -> void
```

### Interactions with Other Systems

#### 依赖系统 (Upstream Dependencies)

| System | Interface | Usage |
|--------|-----------|-------|
| **P14 HanhaiCasinoSystem** | `start_round()`, `end_round()`, `spend_money()`, `earn_money()` | 金币交易、大厅管理 |
| **P14 (Items)** | `buy_roulette_item()`, `use_roulette_item()` | 道具购买和使用 |
| **P14 (UI)** | 弹窗/界面切换 | 显示游戏界面 |

#### P14 → M03 调用接口

```gdscript
# P14 调用 M03 的方法
class_name BuckshotRouletteGame extends Node

## 开始一轮游戏
func start_round(bet_amount: int) -> bool:
    """
    P14 调用此方法开始一轮左轮赌盘
    @param bet_amount: 下注金额
    @return: 是否成功开始
    """
    if bet_amount < MIN_BET or bet_amount > MAX_BET:
        return false
    if not P14.can_spend_money(bet_amount):
        return false
    
    current_bet = bet_amount
    P14.spend_money(bet_amount)
    load_chamber()
    change_state(Betting)
    return true

## 玩家行动
func player_shoot_self() -> void:
    """玩家选择对自己开枪"""

func player_shoot_dealer() -> void:
    """玩家选择对庄家开枪"""

func use_item(item_id: String) -> bool:
    """
    使用道具
    @param item_id: 道具ID (magnifying_glass/beer/gun)
    @return: 是否使用成功
    """
    if not P14.has_item(item_id):
        return false
    # 执行道具效果
    P14.consume_item(item_id)
    return true

func surrender() -> void:
    """玩家投降"""

func exit_game() -> void:
    """玩家中途退出（视为投降）"""
```

#### M03 → P14 回调接口

```gdscript
# M03 发出的信号 (被 P14 订阅)
signal roulette_round_started(bet_amount: int, chamber_count: int)
signal player_turn()
signal dealer_turn()
signal bullet_fired(target: String, bullet_type: String, is_live: bool, lives_remaining: int)
signal item_used(item_id: String)
signal player_life_changed(new_lives: int)
signal dealer_life_changed(new_lives: int)
signal roulette_round_ended(result: Dictionary)

# 结果字典格式
"""
result = {
    "success": bool,           # 玩家是否获胜
    "bet_amount": int,         # 下注金额
    "net_profit": int,         # 净收益 (正数=赢, 负数=输)
    "shots_fired": int,        # 总发射子弹数
    "magnifying_glass_used": bool,
    "beer_used": int,          # 啤酒使用次数
    "gun_used": bool,
    "game_duration": float,    # 游戏时长（秒）
    "final_player_lives": int,
    "final_dealer_lives": int
}
"""
```

#### 数据流图

```
┌─────────────────────────────────────────────────────────────┐
│                        P14 HanhaiCasinoSystem               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐   │
│  │ 金币管理    │  │ 道具管理     │  │ 庄家AI逻辑          │   │
│  │ spend_money│  │ buy_item() │  │ DealerAI.decide()   │   │
│  │ earn_money │  │ has_item() │  │                     │   │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘   │
│         │                │                   │              │
│         │    start_round(bet)                │              │
│         │ ──────────────────────────────────→              │
│         │                │                   │              │
│         │         ┌──────┴──────┐             │              │
│         │         │             │             │              │
│  ┌──────┴─────────▼─────────────▼─────────────▼───────┐     │
│  │                    M03 BuckshotRouletteGame        │     │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────────────┐   │     │
│  │  │ 弹匣管理  │ │ 子弹判定  │ │ 状态机            │   │     │
│  │  │ Chamber  │ │ BulletType│ │ State Machine     │   │     │
│  │  └───────────┘ └───────────┘ └───────────────────┘   │     │
│  │                                                      │     │
│  │  emit bullet_fired()    emit round_ended()           │     │
│  └──────┬───────────────────────────────────────────────┘     │
│         │                                                     │
│         │ ←──────────────────────────────────────────         │
│         │              earn_money(profit) / 无需退款         │
│         │                                                     │
└─────────┴─────────────────────────────────────────────────────┘
```

#### 接口契约

**M03 承诺**:
- 游戏结束时，无论胜负，立即调用 `emit signal("roulette_round_ended", result)`
- 结果中的 `net_profit` = 胜利时为 `bet_amount`，失败时为 `-bet_amount`
- 不持有玩家金币，所有金币交易通过 P14

**P14 承诺**:
- 提供 `can_spend_money(amount)` 方法检查金币是否足够
- 在 `start_round()` 成功后扣除下注金额
- 在收到 `round_ended` 信号后，根据 `net_profit` 增减玩家金币

## Formulas

### 1. 弹匣生成

```
# 弹匣容量 (随机)
max_chamber = random(CHAMBER_MIN, CHAMBER_MAX)
# CHAMBER_MIN = 2, CHAMBER_MAX = 8

# 实际装填子弹数 (1 到 容量)
loaded_count = random(1, max_chamber)

# 实弹数量 (至少1发，避免全空包)
live_count = max(1, floor(loaded_count * LIVE_RATE))
# LIVE_RATE = 0.8 (80%)

# 空包数量
empty_count = loaded_count - live_count
```

**示例**:
| 容量 | 实弹数 | 空包数 | 实弹概率 |
|------|--------|--------|----------|
| 2 | 2 | 0 | 100% |
| 3 | 2 | 1 | 67% |
| 4 | 3 | 1 | 75% |
| 5 | 4 | 1 | 80% |
| 6 | 5 | 1 | 83% |
| 7 | 6 | 1 | 86% |
| 8 | 6 | 2 | 75% |

> **注意**: 实弹数使用 `max(1, floor(...))` 确保至少1发实弹，保证游戏有紧张感。

### 2. 子弹判定

```
# 获取下一发子弹类型
current_bullet = chamber[current_position]

# 实弹命中
is_live = (current_bullet.type == BULLET_LIVE)
# BULLET_LIVE = 1, BULLET_EMPTY = 0

# 命中时减少生命
target_lives -= 1

# 无论实弹还是空包，都消耗一发
chamber.remove_at(current_position)
current_position = (current_position + 1) % chamber.size()
```

### 3. 下一发实弹概率

```
# 实时计算下一发是实弹的概率
remaining_bullets = chamber.size()
remaining_live = count_live_bullets(chamber)
remaining_empty = remaining_bullets - remaining_live

live_probability = remaining_live / remaining_bullets
empty_probability = remaining_empty / remaining_bullets
```

**变量定义**:
| 变量 | 类型 | 范围 | 说明 |
|------|------|------|------|
| `chamber` | Array[Bullet] | - | 弹匣数组 |
| `current_position` | int | 0 到 容量-1 | 当前弹位 |
| `remaining_bullets` | int | 0 到 8 | 剩余子弹数 |
| `remaining_live` | int | 0 到 8 | 剩余实弹数 |
| `live_probability` | float | 0.0 到 1.0 | 实弹概率 |

### 4. 收益计算

```
# 胜利收益
prize = bet_amount * PRIZE_MULTIPLIER
# PRIZE_MULTIPLIER = 2

# 净收益
net_profit = is_winner ? prize : -bet_amount

# 实际到手
actual_gain = prize - bet_amount  # 利润
actual_loss = bet_amount           # 损失
```

**示例**:
| 下注 | 胜利收益 | 实际利润 | 失败损失 |
|------|----------|----------|----------|
| 100g | 200g | +100g | -100g |
| 500g | 1000g | +500g | -500g |
| 1000g | 2000g | +1000g | -1000g |

### 5. 道具效果

#### 5.1 放大镜

```
# 使用放大镜后显示下一发类型
revealed_bullet = chamber[0]
display_message(
    "下一发是: %s" % (
        "实弹" if revealed_bullet.type == BULLET_LIVE 
        else "空包"
    )
)

# 不修改弹匣，只显示信息
# 放大镜效果是一次性的
magnifying_glass_used = true
```

#### 5.2 啤酒

```
# 使用啤酒
if player_lives < MAX_LIVES:
    player_lives += BEER_RESTORE_AMOUNT
    # BEER_RESTORE_AMOUNT = 1
    emit signal("life_changed", "player", player_lives)
else:
    # 生命已满，无效果
    emit signal("item_used", "beer", false)
    return false

beer_count += 1
```

#### 5.3 手枪

```
# 使用手枪 - 强制庄家先开一枪
# 跳过玩家回合
skip_player_turn = true

# 庄家开一枪
dealer_result = fire_bullet("dealer")

if dealer_result.hit and dealer_result.target_lives <= 0:
    # 庄家中弹死亡，玩家直接获胜
    end_game(player_wins=true)
else:
    # 继续正常流程
    current_turn = "player"
```

### 6. 庄家AI决策

```
# 庄家决策逻辑
func dealer_decide() -> String:
    remaining_live = count_live_bullets(chamber)
    remaining_total = chamber.size()
    live_prob = remaining_live / remaining_total
    
    # 生命差距
    life_diff = dealer_lives - player_lives
    
    # 决策
    if life_diff >= 1:
        # 庄家生命优势 -> 对玩家开枪风险较小
        if live_prob < 0.5:
            return "shoot_player"  # 空包概率高，对自己开枪
        else:
            return "shoot_self"    # 实弹概率高，对玩家开枪
    elif life_diff <= -1:
        # 玩家生命优势 -> 庄家需要冒险
        return "shoot_player"      # 赌一把
    else:
        # 生命相等 -> 中立策略
        if live_prob < 0.4:
            return "shoot_self"
        elif live_prob > 0.6:
            return "shoot_player"
        else:
            return random_choice(["shoot_self", "shoot_player"])
```

### 7. 期望值计算

```
# 单次开枪的期望值
EV_per_shot = live_prob * (-LIVES_LOST) + empty_prob * 0

# 一轮游戏的期望值 (简化模型)
total_shots = loaded_count
expected_hits = live_count
expected_lives_lost = min(expected_hits, 2)  # 最多损失2条命

EV_per_round = expected_lives_lost / 2 * bet_amount

# 玩家胜率 (简化)
# 假设每方轮流开枪直到有人死亡
player_win_prob = calculate_win_probability(
    initial_lives=2,
    live_count=live_count,
    empty_count=empty_count,
    first_turn="player"
)
```

### 8. 玩家胜率计算

```
# 蒙特卡洛模拟逻辑 (实现时用模拟而非精确公式)

func calculate_win_probability(lives, live_count, empty_count, first_turn) -> float:
    # 状态: (player_lives, dealer_lives, remaining_live, remaining_empty, current_turn)
    # 递归计算每种状态的胜率
    
    if player_lives <= 0:
        return 0.0  # 玩家输
    if dealer_lives <= 0:
        return 1.0  # 玩家赢
    
    total_remaining = remaining_live + remaining_empty
    if total_remaining == 0:
        return 1.0  # 弹匣空，玩家赢
    
    live_prob = remaining_live / total_remaining
    
    if current_turn == "player":
        # 玩家开枪
        hit_on_player = 0.0
        miss_on_player = 0.0
        
        if remaining_live > 0:
            hit_on_player = live_prob * calculate_win_probability(
                player_lives - 1, dealer_lives, 
                remaining_live - 1, remaining_empty, "dealer"
            )
        
        if remaining_empty > 0:
            miss_on_player = empty_prob * calculate_win_probability(
                player_lives, dealer_lives,
                remaining_live, remaining_empty - 1, "dealer"
            )
        
        return hit_on_player + miss_on_player
    else:
        # 庄家开枪 (同上，反过来)
        ...
```

**预期胜率范围**:
| 子弹配置 | 玩家先手胜率 | 庄家先手胜率 |
|----------|--------------|--------------|
| 2发全实弹 | 0% | 0% (庄家先手,玩家死) |
| 3发2实1空 | ~50% | ~40% |
| 6发5实1空 | ~20% | ~15% |
| 8发6实2空 | ~30% | ~25% |

## Edge Cases

### 1. 弹匣边界

| 情况 | 处理方式 |
|------|----------|
| **弹匣为空** | 玩家自动获胜，触发"弹匣已空，你赢了！"提示 |
| **连续实弹** | 每发实弹减少生命，无特殊处理，连续死亡是游戏正常结果 |
| **连续空包** | 每发空包无事发生，连续空包会增加玩家信心但不改变概率 |
| **最后一发是实弹** | 如果击中会导致生命归零，则游戏立即结束 |

**示例场景**:
```
场景: 玩家生命 1，庄家生命 2，弹匣剩 1 发
判定: 如果是实弹 → 玩家死亡，失败
     如果是空包 → 庄家生命不变，继续循环（但弹匣空了）→ 玩家胜利
```

### 2. 生命边界

| 情况 | 处理方式 |
|------|----------|
| **生命 = 0** | 立即游戏结束，该方失败 |
| **生命 = 2（满血）** | 啤酒道具无效果，消耗但不恢复生命 |
| **生命 = 1 使用啤酒** | 恢复到 2 |
| **双方同时死亡** | 不可能发生，因为是轮流开枪 |

### 3. 道具使用边界

#### 3.1 放大镜

| 情况 | 处理方式 |
|------|----------|
| **弹匣为空时使用** | 允许使用但无意义，显示"弹匣已空" |
| **已使用过** | 禁用按钮，不可重复使用 |
| **使用后显示实弹** | 仅提示，不改变任何数值，玩家自行决策 |
| **使用后显示空包** | 仅提示，不改变任何数值 |

#### 3.2 啤酒

| 情况 | 处理方式 |
|------|----------|
| **生命已满时使用** | 允许但无效果，显示"生命已满" |
| **使用 2 次后** | 禁用按钮，达到本局上限 |
| **死亡后使用** | 死亡后不可使用道具 |

#### 3.3 手枪

| 情况 | 处理方式 |
|------|----------|
| **使用后庄家死亡** | 游戏立即结束，玩家获胜 |
| **使用后庄家存活** | 跳过玩家回合，轮到玩家开枪 |
| **已使用过** | 禁用按钮，不可重复使用 |
| **弹匣为空时使用** | 无意义操作，不应允许 |

### 4. 金币边界

| 情况 | 处理方式 |
|------|----------|
| **金币不足以购买道具** | 禁用购买按钮，显示所需金币 |
| **金币不足以支付下注** | 不允许开始游戏，返回 false |
| **金币 = 0** | 无法进行任何赌博操作，提示玩家去赚钱 |
| **赢得金币溢出** | 使用 int64 存储，极小概率 |

### 5. 游戏中途退出

| 情况 | 处理方式 |
|------|----------|
| **玩家点击退出** | 视为投降，损失下注金额 |
| **游戏崩溃/强退** | 视为投降，下次进入时金币已扣除 |
| **超时未操作** | 默认对自己开枪（P14 配置超时时间） |
| **切换窗口** | 游戏暂停（P14 暂停管理） |

### 6. 状态机异常

| 情况 | 处理方式 |
|------|----------|
| **信号发送顺序错误** | 状态机使用 assert 检查前置状态 |
| **同时触发两个状态转换** | 队列化处理，依次执行 |
| **状态转换表不覆盖的情况** | assert(false)，记录错误日志 |

**状态一致性检查**:
```gdscript
func assert_state(expected_state: String) -> void:
    if current_state != expected_state:
        push_error("状态不一致: 期望 %s, 实际 %s" % [expected_state, current_state])
        assert(false)
```

### 7. 极端概率场景

| 场景 | 概率 | 处理方式 |
|------|------|----------|
| **第一发全实弹** | ~20% | 玩家选择对自己开枪 → 立即失败 |
| **连续 8 发全实弹** | ~1.7% | 两次开枪就结束，后续空包不会执行 |
| **前 6 发全空包** | ~0.6% | 继续游戏，概率重新计算 |
| **无限循环（不可能）** | 0% | 弹匣有限，必然结束 |

### 8. 并发和竞态条件

| 情况 | 处理方式 |
|------|----------|
| **动画未播放完就点击** | 队列化，动画播放完成后执行 |
| **信号发送后修改数据** | 复制数据后发送，避免引用修改 |
| **同时触发多个道具效果** | 按顺序依次执行，不并发 |

### 9. 存档边界

| 情况 | 处理方式 |
|------|----------|
| **游戏进行中存档** | 保存当前状态（弹匣、生命、道具） |
| **读档恢复** | 恢复所有状态，继续游戏 |
| **存档损坏** | 使用默认值，重新开始游戏 |

### 10. 音效/动画缺失

| 情况 | 处理方式 |
|------|----------|
| **音效加载失败** | 静默继续，不阻塞游戏 |
| **动画加载失败** | 静态替代，不阻塞游戏 |
| **低性能模式** | 跳过非必要动画

## Dependencies

### 上游依赖（M03 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P14** | 汉海/赌场系统 | **硬依赖** | 金币交易、道具管理、庄家AI、游戏会话管理 |
| **U02** | 通用UI组件 | 软依赖 | 按钮、对话框组件 |
| **U12** | 赌场界面 | 软依赖 | 赌场入口/退出界面 |

### 下游依赖（其他系统依赖 M03）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P14** | 汉海/赌场系统 | 调用方 | M03 是 P14 管理的左轮赌盘游戏模块 |
| **P09** | 成就系统 | 软依赖 | 赌博相关成就（如"左轮赌神"） |

### 关键接口契约

**与 P14 的接口**:

```gdscript
## M03 需要的 P14 接口

# 金币验证
func can_spend_money(amount: int) -> bool
func get_money() -> int

# 金币交易
func spend_money(amount: int) -> bool
func earn_money(amount: int) -> void

# 道具管理
func has_item(item_id: String) -> bool
func consume_item(item_id: String) -> void

# 大厅信息
func get_hall_level() -> int  # 返回 1=标准, 2=中级, 3=高级
func get_max_bet() -> int

## M03 提供的接口

# 游戏控制
func start_round(bet_amount: int) -> bool
func player_shoot_self() -> void
func player_shoot_dealer() -> void
func use_item(item_id: String) -> bool
func surrender() -> void

# 状态查询
func get_game_state() -> Dictionary
func get_next_bullet_probability() -> float

## M03 发出的信号

signal roulette_round_started(bet_amount: int, chamber_count: int)
signal player_turn()
signal dealer_turn()
signal bullet_fired(target: String, bullet_type: String, is_live: bool, lives_remaining: int)
signal item_used(item_id: String, success: bool)
signal player_life_changed(new_lives: int)
signal dealer_life_changed(new_lives: int)
signal roulette_round_ended(result: Dictionary)
```

### 依赖关系说明

**硬依赖 P14**:
- M03 无法独立存在，必须在 P14 的赌场环境中运行
- 金币扣除/获得必须通过 P14
- 道具必须由 P14 管理
- 大厅级别赌注配置从 P14 获取

**庄家AI归属**:
- 庄家AI决策逻辑**在M03内部实现**
- AI使用概率和生命差距来决定行动（见Formulas章节）
- AI难度可通过 Tuning Knobs 调整

**软依赖 U02/U12**:
- UI 组件可替换，但默认使用 U02
- 界面切换通过 P14 管理

**与其他小游戏的关系**:
- M02（德州扑克）和 M03（左轮赌盘）无直接依赖
- 共享 P14 的基础设施（金币、道具）
- 各自独立运行

## Tuning Knobs

### 弹匣配置

| 参数名 | 默认值 | 安全范围 | 极端值效果 |
|--------|--------|----------|------------|
| `CHAMBER_MIN` | 2 | 1-4 | 1=必死局，4=较轻松 |
| `CHAMBER_MAX` | 8 | 6-12 | 12=超长局 |
| `LIVE_RATE` | 0.8 | 0.5-0.95 | 0.95=必死局 |
| `MIN_CHAMBER_LOAD` | 1 | - | 固定值，必须至少1发 |

**配置示例**:
```gdscript
# 简单模式
CHAMBER_MIN = 2, CHAMBER_MAX = 4, LIVE_RATE = 0.6

# 标准模式
CHAMBER_MIN = 2, CHAMBER_MAX = 8, LIVE_RATE = 0.8

# 地狱模式
CHAMBER_MIN = 4, CHAMBER_MAX = 12, LIVE_RATE = 0.9
```

### 生命配置

| 参数名 | 默认值 | 安全范围 | 极端值效果 |
|--------|--------|----------|------------|
| `INITIAL_LIVES` | 2 | 1-5 | 1=一枪定胜负，5=需要多次命中 |
| `MAX_LIVES` | 2 | = INITIAL_LIVES | 必须等于初始生命 |
| `BEER_RESTORE_AMOUNT` | 1 | 1-2 | 2=一瓶满血 |
| `MAX_BEER_USES` | 2 | 1-3 | 3=多次恢复机会 |

### 下注配置

| 参数名 | 默认值 | 安全范围 | 来源 |
|--------|--------|----------|------|
| `MIN_BET` | 10 | 5-100 | P14 大厅配置 |
| `MAX_BET` | 500/2000/10000 | - | P14 大厅配置 |
| `PRIZE_MULTIPLIER` | 2 | 1-5 | 2=50%期望值 |

**大厅级别的赌注**:
| 大厅 | MIN_BET | MAX_BET |
|------|---------|---------|
| 标准厅 | 10g | 500g |
| 中级厅 | 50g | 2000g |
| 高级厅 | 200g | 10000g |

### 道具配置

| 参数名 | 默认值 | 安全范围 | 极端值效果 |
|--------|--------|----------|------------|
| `MAGNIFYING_GLASS_PRICE` | 50 | 25-500 | 太贵=没人买 |
| `MAGNIFYING_GLASS_USES` | 1 | 1-3 | 3=情报优势大 |
| `BEER_PRICE` | 100 | 50-500 | 太贵=不值得 |
| `BEER_RESTORE_AMOUNT` | 1 | 1-2 | 见生命配置 |
| `MAX_BEER_USES` | 2 | 1-3 | 见生命配置 |
| `GUN_PRICE` | 500 | 200-2000 | 太贵=不值得 |
| `GUN_USES` | 1 | 1-2 | 2=双倍优势 |

**道具价值评估**:
```
放大镜价值 = 期望避免损失 = 50% * 1条命价值
啤酒价值 = 恢复的生命 = 1条命
手枪价值 = 跳过自己回合 + 庄家中弹可能 = 约0.5-1条命
```

### 收益配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `PRIZE_MULTIPLIER` | 2 | 1-5 | 2=赔率1:1，玩家期望收益接近0 |
| `HOUSE_EDGE` | 0.10 | 0.05-0.20 | 赌场优势率，实际影响赔率调整 |

**赌场优势率实现**:
```gdscript
# 如果 HOUSE_EDGE = 0.10，则调整赔率
effective_odds = PRIZE_MULTIPLIER * (1 - HOUSE_EDGE)
# 2 * 0.9 = 1.8 → 胜利只获得下注*1.8

# 或通过调整实弹概率
adjusted_live_rate = LIVE_RATE + (HOUSE_EDGE * 0.5)
```

### 难度调节（AI庄家）

| 参数名 | 默认值 | 安全范围 | 影响 |
|--------|--------|----------|------|
| `DEALER_AGGRESSION` | 0.5 | 0.0-1.0 | 0=保守，1=疯狂 |
| `DEALER_RISK_THRESHOLD` | 0.5 | 0.3-0.7 | 超过此概率才冒险 |

**AI行为对照**:
| Aggression | 策略 |
|------------|------|
| 0.2 | 几乎总是对自己开枪（保守） |
| 0.5 | 根据概率决策（标准） |
| 0.8 | 几乎总是对玩家开枪（激进） |

### 超时配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `PLAYER_TURN_TIMEOUT` | 60 | 30-120 | 秒，超时默认对自己开枪 |
| `BETTING_TIMEOUT` | 30 | 15-60 | 秒 |
| `ANIMATION_DURATION` | 1.5 | 1-3 | 秒 |

### UI显示配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `SHOW_BULLET_PROBABILITY` | true | bool | 是否显示概率 |
| `SHOW_DEALER_LIVES` | true | bool | 是否显示庄家生命 |
| `ENABLE_SOUND` | true | bool | 音效开关 |
| `ENABLE_VIBRATION` | true | bool | 手机震动开关 |

### 成就关联配置

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `ACHIEVEMENT_LUCKY_SURVIVOR` | 连续3次空包存活 | P09 成就触发 |
| `ACHIEVEMENT_RISK_TAKER` | All-in 5次 | P09 成就触发 |
| `ACHIEVEMENT_ROULETTE_MASTER` | 累计赢100次 | P09 成就触发 |

## Visual/Audio Requirements

### 视觉设计

#### 整体风格
- **主题**: 昏暗的地下赌场氛围
- **配色**: 深红(#8B0000)、黑色(#1A1A1A)、金色(#FFD700)、暗紫(#4B0082)
- **字体**: 粗体标题，醒目的数字显示

#### 核心视觉元素

| 元素 | 描述 | 优先级 |
|------|------|--------|
| **左轮手枪** | 3D模型，支持旋转展示，枪口朝向当前目标 | 必须 |
| **弹匣** | 圆盘形，显示所有弹位，可用不同颜色区分实弹/空包 | 必须 |
| **生命图标** | 心形 ♥，被击中时破碎/变灰动画 | 必须 |
| **道具图标** | 放大镜🔍、啤酒🍺、手枪🔫 | 必须 |
| **概率显示** | 数字+进度条，显示下一发实弹概率 | 建议 |
| **背景** | 赌场桌子纹理，昏暗灯光效果 | 必须 |

#### 动画效果

| 动画 | 持续时间 | 描述 |
|------|----------|------|
| **装弹动画** | 2s | 子弹逐个装入弹匣的动画 |
| **转轮动画** | 1s | 左轮转轮旋转 |
| **开枪动画** | 1.5s | 枪口火焰、枪机后座 |
| **命中效果** | 0.5s | 红色闪烁、生命图标破碎 |
| **空包效果** | 0.5s | 白色烟雾、烟雾消散 |
| **胜利动画** | 3s | 金币喷涌、聚光效果 |
| **失败动画** | 2s | 红色渐暗、生命归零 |

#### 状态视觉反馈

| 状态 | 视觉表现 |
|------|----------|
| **等待玩家行动** | 开枪按钮高亮 |
| **放大镜已使用** | 放大镜图标灰化 |
| **生命已满** | 啤酒使用无效提示 |
| **概率高** (>70%) | 概率数字红色 |
| **概率低** (<30%) | 概率数字绿色 |

### 音频设计

#### 音效列表

| 音效 | 文件名 | 描述 | 时长 |
|------|--------|------|------|
| **背景音乐** | `roulette_bg.ogg` | 紧张的低频节奏 | 循环 |
| **装弹音效** | `chamber_load.wav` | 金属咔嗒声 | 0.3s |
| **转轮音效** | `cylinder_spin.wav` | 旋转摩擦声 | 0.8s |
| **开枪音效** | `gunshot.wav` | 枪声（房间混响） | 1s |
| **空包音效** | `blank_fire.wav` | 较闷的枪声 | 0.5s |
| **心跳声** | `heartbeat.wav` | 玩家回合时播放 | 循环 |
| **命中音效** | `hit_impact.wav` | 击中时播放 | 0.3s |
| **生命恢复** | `heal.wav` | 啤酒使用 | 0.5s |
| **道具购买** | `purchase.wav` | 购买成功 | 0.3s |
| **胜利音效** | `victory_fanfare.wav` | 胜利音乐 | 3s |
| **失败音效** | `defeat.wav` | 失败音乐 | 2s |
| **金币音效** | `coin_sound.wav` | 金币变化 | 0.2s |
| **按钮点击** | `button_click.wav` | UI点击反馈 | 0.1s |

#### 音频混合

| 音轨 | 音量 | 说明 |
|------|------|------|
| **背景音乐** | 0.4 | 持续播放，降低紧张感 |
| **心跳声** | 0.6 | 玩家回合时叠加 |
| **枪声/特效** | 0.8 | 瞬时音效 |
| **UI音效** | 0.5 | 低优先级 |

### 触觉反馈 (可选)

| 场景 | 震动模式 |
|------|----------|
| **开枪** | 短促震动 (50ms) |
| **命中** | 中等震动 (100ms) |
| **胜利** | 连续短震 (3次) |
| **失败** | 长震动 (300ms) |

## UI Requirements

### 界面布局

```
┌─────────────────────────────────────────────────────────────┐
│  [退出]                              金币: 10000g   [菜单]  │ ← 顶部栏
├─────────────────────────────────────────────────────────────┤
│                                                             │
│              ┌─────────────────────────┐                   │
│              │      庄家生命            │                   │
│              │        ♥ ♥               │                   │
│              └─────────────────────────┘                   │
│                                                             │
│                      ┌─────────┐                            │
│                      │  概率   │                            │
│                      │  60%    │                            │
│                      │ ██████░░│                            │
│                      └─────────┘                            │
│                                                             │
│              ┌─────────────────────────┐                   │
│              │                         │                   │
│              │      左轮手枪          │                   │
│              │       [枪模型]         │                   │
│              │                         │                   │
│              │    ○ ● ○ ● ○ ○        │ ← 弹匣可视化       │
│              │                         │                   │
│              └─────────────────────────┘                   │
│                                                             │
│              ┌─────────────────────────┐                   │
│              │      玩家生命            │                   │
│              │        ♥ ♥               │                   │
│              └─────────────────────────┘                   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  [道具栏]                                                   │
│  ┌────────┐ ┌────────┐ ┌────────┐                          │
│  │🔍 50g │ │🍺 100g │ │🔫 500g │                          │
│  │ 可用  │ │ 已满  │ │ 可用  │                          │
│  └────────┘ └────────┘ └────────┘                          │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │  对自己开枪      │    │  对庄家开枪      │              │
│  │  [  开枪  ]      │    │  [  确认  ]      │              │
│  └──────────────────┘    └──────────────────┘              │
│                                                             │
│              [投降 - 损失 100g]                              │
└─────────────────────────────────────────────────────────────┘
```

### 界面组件

| 组件 | ID | 描述 |
|------|-----|------|
| **顶部栏** | `TopBar` | 金币显示、退出按钮 |
| **庄家生命区** | `DealerLifeArea` | 庄家的生命图标 |
| **概率显示** | `ProbabilityDisplay` | 下一发实弹概率 |
| **手枪区域** | `GunArea` | 左轮手枪3D模型 |
| **弹匣显示** | `ChamberDisplay` | 弹匣可视化 |
| **玩家生命区** | `PlayerLifeArea` | 玩家的生命图标 |
| **道具栏** | `ItemBar` | 道具购买/使用按钮 |
| **开枪按钮区** | `ShootButtonArea` | 对自己/对庄家开枪 |
| **投降按钮** | `SurrenderButton` | 投降选项 |

### 交互流程

#### 1. 游戏开始 (Betting 状态)

```
显示: 下注滑块/输入框
显示: [确认下注] 按钮
按钮: [取消] 返回 P14

输入范围: MIN_BET ~ MAX_BET (大厅决定)
默认值: MIN_BET
```

#### 2. 装弹阶段 (Loading 状态)

```
动画: 子弹逐个装入弹匣
显示: "装弹中..."
完成后: 过渡到 PlayerTurn
```

#### 3. 玩家回合 (PlayerTurn 状态)

```
显示: "你的回合"
显示: 当前概率
启用: 开枪按钮、道具按钮

按钮状态:
- 对自己开枪: 始终可用
- 对庄家开枪: 需要二次确认
- 放大镜: 未使用且弹匣非空时可用
- 啤酒: 生命未满且有次数剩余
- 手枪: 未使用且弹匣非空时可用
```

#### 4. 二次确认对话框 (对庄家开枪)

```
标题: "确认开枪"
内容: "确定要对庄家开枪吗？这会让庄家承担风险。"
按钮: [取消] [确认]
```

#### 5. 子弹发射 (Firing 状态)

```
动画: 开枪动画
音效: 枪声
判定:
  - 实弹: 命中效果
  - 空包: 空包效果
```

#### 6. 生命变化

```
命中:
  目标生命 - 1
  生命图标破碎动画
  播放命中音效

空包:
  显示 "空包"
  白色烟雾动画
```

#### 7. 庄家回合 (DealerTurn 状态)

```
显示: "庄家的回合"
自动: 1-2秒后庄家做出决策
显示: 决策 (对自己/对玩家开枪)
```

#### 8. 游戏结束 (Showdown 状态)

```
胜利:
  显示: "你赢了！"
  动画: 金币喷涌
  显示: "+200g"

失败:
  显示: "你输了..."
  动画: 红色渐暗
  显示: "-100g"

按钮: [再来一局] [返回大厅]
```

### UI 状态映射

| 游戏状态 | UI 状态 | 可用操作 |
|----------|---------|----------|
| `Idle` | 隐藏 | - |
| `Betting` | 显示下注界面 | 下注、取消 |
| `Loading` | 显示加载动画 | 无 |
| `PlayerTurn` | 显示游戏界面 | 开枪、道具、投降 |
| `Firing` | 播放动画 | 无 |
| `DealerTurn` | 显示等待 | 无 |
| `Showdown` | 显示结果 | 再来、返回 |

### 辅助信息显示

| 信息 | 显示位置 | 条件 |
|------|----------|------|
| **下一发概率** | 弹匣上方 | 始终显示 |
| **道具价格** | 道具按钮下方 | 可购买时 |
| **下注金额** | 顶部栏附近 | 游戏进行中 |
| **当前收益** | 结果界面 | 游戏结束时 |

### 错误提示

| 错误 | 提示内容 |
|------|----------|
| **金币不足** | "金币不足，无法下注" |
| **道具已用** | "该道具本局已使用" |
| **生命已满** | "生命已满，无需使用啤酒" |
| **弹匣为空** | "弹匣已空！" |

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 | 优先级 |
|----|----------|----------|--------|
| **AC-01** | 玩家可以开始一轮左轮赌盘 | 从P14进入，押注后开始游戏 | 必须 |
| **AC-02** | 弹匣随机生成2-8发子弹 | 测试10次，验证容量和实弹数 | 必须 |
| **AC-03** | 实弹概率约80% | 统计100发子弹，验证比例 | 必须 |
| **AC-04** | 玩家可以对自己开枪 | 点击按钮，验证生命变化 | 必须 |
| **AC-05** | 玩家可以对庄家开枪 | 点击按钮，验证庄家生命变化 | 必须 |
| **AC-06** | 生命归零时游戏结束 | 故意让自己死亡，验证结束 | 必须 |
| **AC-07** | 弹匣为空时玩家获胜 | 清空弹匣，验证胜利 | 必须 |
| **AC-08** | 放大镜显示下一发类型 | 使用后验证提示正确 | 应该 |
| **AC-09** | 啤酒恢复1条生命 | 受伤后使用，验证生命恢复 | 应该 |
| **AC-10** | 手枪强制庄家先开 | 使用后验证跳过玩家回合 | 应该 |
| **AC-11** | 投降损失下注金额 | 投降后验证金币扣除 | 应该 |
| **AC-12** | 胜利获得2倍下注 | 胜利后验证金币增加 | 必须 |
| **AC-13** | 失败损失下注金额 | 失败后验证金币扣除 | 必须 |
| **AC-14** | 庄家AI做出合理决策 | 观察10局，验证AI不是随机 | 应该 |

### 界面验收标准

| ID | 验收标准 | 测试方法 | 优先级 |
|----|----------|----------|--------|
| **UI-01** | 生命图标正确显示 | 受伤后心形变灰 | 必须 |
| **UI-02** | 概率实时更新 | 每次开枪后概率变化 | 必须 |
| **UI-03** | 弹匣可视化正确 | 对照逻辑验证弹位 | 应该 |
| **UI-04** | 道具按钮状态正确 | 根据条件启用/禁用 | 必须 |
| **UI-05** | 开枪动画正常播放 | 播放时无卡顿 | 应该 |
| **UI-06** | 结果界面正确显示 | 胜利/失败界面元素齐全 | 必须 |
| **UI-07** | 音效正确播放 | 验证各音效触发 | 应该 |
| **UI-08** | 金币显示正确 | 扣除/增加后验证显示 | 必须 |

### 状态机验收标准

| ID | 验收标准 | 测试方法 | 优先级 |
|----|----------|----------|--------|
| **SM-01** | Idle → Betting 正确 | 调用 start_round() | 必须 |
| **SM-02** | Betting → Loading 正确 | 下注完成 | 必须 |
| **SM-03** | Loading → PlayerTurn 正确 | 装弹完成 | 必须 |
| **SM-04** | PlayerTurn → Firing 正确 | 玩家选择开枪 | 必须 |
| **SM-05** | Firing → LifeLost/Check 正确 | 子弹发射完成 | 必须 |
| **SM-06** | LifeLost → DealerTurn/Showdown 正确 | 生命判定 | 必须 |
| **SM-07** | DealerTurn → Firing 正确 | 庄家决策完成 | 必须 |
| **SM-08** | Showdown → Idle 正确 | 结果界面关闭 | 必须 |
| **SM-09** | 状态转换无遗漏 | 完整走一遍所有路径 | 应该 |
| **SM-10** | 异常状态被拒绝 | 非法转换不发生 | 应该 |

### 跨系统集成验收

| ID | 验收标准 | 测试方法 | 优先级 |
|----|----------|----------|--------|
| **CS-01** | P14 正确扣除下注 | 开始后检查玩家金币 | 必须 |
| **CS-02** | P14 正确支付胜利 | 胜利后检查金币增加 | 必须 |
| **CS-03** | P14 正确记录失败 | 失败后金币正确扣除 | 必须 |
| **CS-04** | 道具从 P14 购买 | 购买后验证持有 | 应该 |
| **CS-05** | 道具使用消耗正确 | 使用后验证道具减少 | 应该 |
| **CS-06** | 信号正确发送到 P14 | 监听信号验证触发 | 应该 |

### 边界情况验收

| ID | 验收标准 | 测试方法 | 优先级 |
|----|----------|----------|--------|
| **BC-01** | 金币不足无法下注 | 拥有<MIN_BET尝试 | 必须 |
| **BC-02** | 连续实弹处理 | 模拟连续命中场景 | 应该 |
| **BC-03** | 连续空包处理 | 模拟连续空包场景 | 应该 |
| **BC-04** | 生命已满使用啤酒 | 满血时点啤酒 | 应该 |
| **BC-05** | 道具用尽禁用 | 使用后禁用按钮 | 应该 |
| **BC-06** | 游戏超时默认开枪 | 等待超时验证 | 应该 |

### 性能验收标准

| ID | 验收标准 | 测试方法 | 目标 |
|----|----------|----------|------|
| **PC-01** | 游戏启动 < 2s | 计时从P14进入 | < 2s |
| **PC-02** | 状态转换 < 100ms | 计时状态切换 | < 100ms |
| **PC-03** | 动画播放流畅 | 观察60fps | ≥ 30fps |
| **PC-04** | 内存占用 < 100MB | 性能监视器 | < 100MB |

### 存档验收标准

| ID | 验收标准 | 测试方法 | 优先级 |
|----|----------|----------|--------|
| **SV-01** | 游戏中途存档 | 存档后加载验证 | 应该 |
| **SV-02** | 加载后状态正确 | 验证所有状态恢复 | 应该 |
| **SV-03** | 损坏存档处理 | 模拟损坏验证恢复 | 应该 |

### 可访问性标准

| ID | 验收标准 | 测试方法 | 优先级 |
|----|----------|----------|--------|
| **A11Y-01** | 支持键盘操作 | Tab导航，Enter确认 | 应该 |
| **A11Y-02** | 文字大小可调 | 缩放后布局正常 | 应该 |
| **A11Y-03** | 高对比度模式 | 开启后元素清晰 | 应该 |

## Open Questions

| ID | 问题 | Owner | Target Date | Status |
|----|------|-------|-------------|--------|
| **OQ-01** | 放大镜是否应该显示所有剩余子弹类型？ | 策划 | Pre-MVP | Open |
| **OQ-02** | 庄家AI是否应该有不同的难度级别？ | 策划 | Pre-MVP | Open |
| **OQ-03** | 是否需要成就系统集成（"左轮赌神"等）？ | 策划 | 与P09协调 | Open |
| **OQ-04** | 弹匣可视化是否应该让玩家看到子弹颜色区分？ | UI/策划 | Pre-MVP | Open |
| **OQ-05** | 是否需要添加"保险"道具（支付一定金币可避免下一次命中）？ | 策划 | Post-MVP | Open |
| **OQ-06** | 玩家投降时是否应该有确认对话框？ | UX | Pre-MVP | Open |
| **OQ-07** | 是否需要观看广告获取免费道具的机制？ | 策划 | Post-MVP | Open |
| **OQ-08** | 高对比度模式下如何显示子弹类型（不用颜色区分）？ | UX/UI | Pre-MVP | Open |

### 问题详细说明

#### OQ-01: 放大镜查看范围
**选项A**: 只显示下一发（当前设计）
**选项B**: 显示所有剩余子弹（增加策略性）
**建议**: 先实现选项A，保持运气成分

#### OQ-02: 庄家AI难度
**选项A**: 固定策略（当前设计）
**选项B**: 根据大厅级别调整AI激进程度
**选项C**: AI表现随机（玩家无法预判）
**建议**: 选项B，与P14大厅级别挂钩

#### OQ-03: 成就集成
**待确认**:
- "幸运儿" - 连续3次空包存活
- "赌神" - 单日赢取10000g
- "亡命之徒" - 累计All-in 50次
**建议**: 与P09协调后确定
