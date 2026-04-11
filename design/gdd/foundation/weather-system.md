# 天气系统 (Weather System)

> **状态**: Ready for Review
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: F02
> **Implements Pillar**: Farm Simulation Core Loop

## Overview

天气系统是游戏的核心环境系统，每天生成并显示天气类型（晴/雨/雷雨/雪/风/绿雨）。系统根据季节概率分布自动生成天气，但尊重固定天气日和节日（节日永远晴天）。玩家可以查看明日天气预报以规划次日活动。天气影响农作效率、体力消耗、特殊活动（如钓鱼、采矿）的收益加成，以及NPC心情状态。

## Player Fantasy

天气系统让玩家感受到自然的韵律和农耕的不确定性。玩家应该：

- **期待与焦虑并存** — 每天晚上查看天气预报，思考"明天要不要去采矿还是继续种地"
- **季节的氛围感** — 春雨绵绵让人安心，夏日雷雨带来紧张，冬季飘雪带来宁静
- **惊喜的稀有时刻** — 绿雨是 Year 1 Summer 的彩蛋事件，让玩家记住这个特殊的日子
- **节日的美好** — 节日永远是晴天，暗示着风和日丽的好兆头

**Reference games**: Stardew Valley 的雨天系统让玩家既感到计划被打乱，又享受难得的休息日。

## Detailed Design

### Core Rules

1. **天气类型定义**
   - `sunny`: 晴天 — 正常农作效率，需浇水
   - `rainy`: 雨天 — 自动浇水，省体力但采矿/钓鱼收益-10%
   - `stormy`: 雷雨天 — 自动浇水，室外活动风险（雷击概率），采矿/钓鱼-20%
   - `snowy`: 雪天 — 仅冬季，自动浇水，室外移动-30%体力
   - `windy`: 大风天 — 随机吹走已浇水状态（需重新浇水）
   - `green_rain`: 绿雨 — 夏季特殊，自动浇水+增产buff，特殊视觉效果

2. **天气生成优先级（按顺序检查）**
   1. **玩家强制**: `set_tomorrow_weather()` 被调用 → 使用指定天气
   2. **节日日**: FESTIVAL_DAYS[season].includes(day) → `sunny`
   3. **固定天气日**: FIXED_WEATHER[season]?.has(day) → 指定天气
   4. **特殊事件**: 条件满足时 → 指定天气
      - Year 1 Summer Day 5 → `green_rain`
      - 玩家拥有唤雨能力 (long_ling_2) → 下雨概率+15%
   5. **季节随机**: roll_weather(season) → 按概率分布

3. **天气预报系统**
   - `today_weather`: 当前日天气，每日结算时更新
   - `tomorrow_weather`: 明日天气，每日结算时根据次日日期roll
   - 玩家可通过 UI 或雨图腾等物品查看/设置明日天气

4. **天气影响规则**
   - **浇水**: rainy/stormy/green_rain/snowy 时自动完成（无需手动浇水）
   - **体力消耗修正**:
     - rainy: -10%
     - stormy: -20%
     - snowy: -30%
   - **采矿收益**: rainy -10%, stormy -20%
   - **钓鱼收益**: rainy -10%, stormy -20%
   - **农作效率**: green_rain 时 +10% 产量
   - **雷击风险**: stormy 时 5% 概率在室外触发昏厥
   - **NPC心情**: 晴 → +好感修正，暴风雨 → -好感修正

### States and Transitions

天气系统本身不是复杂状态机，而是数据驱动的。以下是关键的"状态快照"：

| 状态 | 描述 | 数据内容 | 触发时机 |
|------|------|----------|----------|
| **WeatherSet** | 当日天气已确定 | `today_weather: Weather` | 每日结算 (day_changed) |
| **ForecastSet** | 明日天气预报已生成 | `tomorrow_weather: Weather` | 每日结算后 |
| **PlayerOverride** | 玩家强制天气 | `override_weather: Weather?` | 玩家使用雨图腾等 |
| **GreenRainActive** | 绿雨特殊状态 | `is_green_rain: bool` | green_rain 天气生效时 |

**状态转换**:
- `DayTransition` 触发 → `WeatherSet` 更新 (today = yesterday.forecast)
- `DayTransition` 触发 → `ForecastSet` 更新 (roll tomorrow)
- 玩家使用物品 → `PlayerOverride` 设置 → `ForecastSet` 被覆盖
- 睡眠/日结算 → `PlayerOverride` 清除

### Interactions with Other Systems

| 系统 | 数据流入 (Weather → System) | 数据流出 (System → Weather) |
|------|---------------------------|---------------------------|
| **F01 TimeSeasonSystem** | — | 提供 season, day, year 用于天气roll |
| **C01 PlayerStats** | 体力消耗修正、昏厥风险 | — |
| **C03 Skills** | 采矿/钓鱼技能收益修正 | — |
| **C04 FarmPlot** | 自动浇水判定 | — |
| **C05 Navigation** | 移动体力消耗修正 | — |
| **C07 NPCFriendship** | NPC心情/好感修正 | — |
| **P07 HiddenNPC** | long_ling_2 能力触发下雨概率 | 提供唤雨能力状态 |
| **F04 SaveLoad** | 保存 weather, tomorrow_weather | 加载恢复天气状态 |

**信号订阅关系**:
- `day_changed` → 更新 today_weather, roll tomorrow_weather
- `season_changed` → 季节概率表切换

## Formulas

### 1. 天气生成概率表

**变量定义**:
- `roll`: 0.0 ~ 1.0 随机数
- `rainBoost`: 唤雨能力加成 (0% 或 15%)

**春季 (Spring)**:

| 条件 | 天气 | 基础概率 | rainBoost后 |
|------|------|----------|-------------|
| roll < 0.5 - rainBoost | sunny | 50% | 35%-50% |
| roll < 0.75 | rainy | 25% | 25% |
| roll < 0.85 | stormy | 10% | 10% |
| otherwise | windy | 15% | 15%+rainBoost |

**夏季 (Summer)**:

| 条件 | 天气 | 基础概率 |
|------|------|----------|
| roll < 0.08 | green_rain | 8% |
| roll < 0.42 - rainBoost | sunny | 34%-42% |
| roll < 0.68 | rainy | 26% |
| roll < 0.83 | stormy | 15% |
| otherwise | windy | 9%+rainBoost |

**秋季 (Autumn)**:

| 条件 | 天气 | 基础概率 | rainBoost后 |
|------|------|----------|------------|
| roll < 0.45 - rainBoost | sunny | 45% | 30%-45% |
| roll < 0.7 | rainy | 25% | 25% |
| roll < 0.8 | stormy | 10% | 10% |
| otherwise | windy | 20% | 20%+rainBoost |

**冬季 (Winter)**:

| 条件 | 天气 | 基础概率 | rainBoost后 |
|------|------|----------|------------|
| roll < 0.5 - rainBoost | sunny | 50% | 35%-50% |
| roll < 0.8 | snowy | 30% | 30% |
| otherwise | windy | 20% | 20%+rainBoost |

### 2. 体力消耗修正

```
actualStaminaCost = baseStaminaCost × weatherModifier
```

| 天气 | Modifier | 说明 |
|------|----------|------|
| sunny | 1.0 | 无修正 |
| rainy | 0.9 | -10% |
| stormy | 0.8 | -20% |
| snowy | 0.7 | -30% |
| windy | 1.0 | 无修正 |
| green_rain | 0.9 | -10% |

### 3. 采矿/钓鱼收益修正

```
actualYield = baseYield × activityModifier
```

| 天气 | 采矿修正 | 钓鱼修正 |
|------|----------|----------|
| sunny | 1.0 | 1.0 |
| rainy | 0.9 | 0.9 |
| stormy | 0.8 | 0.8 |
| snowy | 1.0 | 1.0 |
| windy | 1.0 | 1.0 |
| green_rain | 1.0 | 1.1 (绿雨钓鱼+10%) |

### 4. 雷击风险 (stormy only)

```
if stormy and isOutdoors:
    if random() < LIGHTNING_STRIKE_CHANCE (0.05):
        triggerForcedPassout()
```

### 5. 绿雨增产

```
if weather == green_rain:
    cropYield = baseYield × 1.1
```

## Edge Cases

1. **Season boundary weather roll**
   - Problem: rolling for day 29 (season start) during day 28结算
   - Resolution: rollWeather uses next season's probabilities for tomorrow

2. **Player override conflicts**
   - Problem: 玩家使用雨图腾后，节日到了
   - Resolution: PlayerOverride 优先级**高于** Festival（雨图腾是玩家主动选择，不被节日覆盖）

3. **Windy + 自动浇水作物**
   - Problem: windy 吹走浇水状态，但rainy/stormy/snowy 会自动浇水
   - Resolution: 每日结算时按顺序执行：① 自动浇水判定 ② windy 清空浇水状态

4. **Snowy in non-winter**
   - Problem: 代码逻辑保证 snowy 只在冬季，但概率表可能被错误配置
   - Resolution: snowy 只在 winter 概率表中出现；其他季节 rolling 到 snowy 时映射为 rainy

5. **Green rain outside summer**
   - Problem: green_rain 概率只在夏季
   - Resolution: green_rain 只在 summer rollWeather 中可被选中；其他季节 rolling 到 green_rain 时映射为 rainy

6. **存档加载天气不一致**
   - Problem: 读取的存档天气与当前日期不匹配
   - Resolution: 存档**不保存** weather/tomorrowWeather，每日结算时重新 roll

7. **雷击 + 体力耗尽 同时触发**
   - Problem: stormy 雷击昏厥 和 体力耗尽昏厥 同时满足
   - Resolution: 按先到者处理（体力耗尽优先，雷击不重复触发）

8. **唤雨能力 + festival override**
   - Problem: 玩家有 long_ling_2 能力但节日到了
   - Resolution: Festival override > 能力效果（节日强制 sunny），但 PlayerOverride > Festival

9. **绿雨与雨图腾叠加**
   - Problem: 玩家有 long_ling_2 能力 + 使用雨图腾
   - Resolution: PlayerOverride 覆盖所有计算，按指定天气执行

10. **连续多天强制雨天**
    - Problem: 玩家连续使用多个雨图腾
    - Resolution: 允许；PlayerOverride 持续生效直到被清除（每日结算不自动清除）

## Dependencies

### 上游依赖 (F02 依赖其他系统)

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **F01 TimeSeasonSystem** | 硬依赖 | 订阅 `season_changed(season, year)` 和 `day_changed(day, season)` 信号 |
| **P07 HiddenNPCSystem** | 软依赖 | 查询 `long_ling_2` 能力是否激活（下雨概率+15%） |

### 下游依赖 (其他系统依赖 F02)

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **F04 SaveLoadSystem** | 硬依赖 | 保存 today_weather, tomorrow_weather, player_override |
| **C01 PlayerStatsSystem** | 硬依赖 | 调用 `get_stamina_modifier()` 用于体力消耗计算 |
| **C03 SkillsSystem** | 硬依赖 | 调用 `get_activity_yield_modifier(activity)` 用于采矿/钓鱼收益 |
| **C04 FarmPlotSystem** | 硬依赖 | 调用 `is_rainy_day()` 触发自动浇水 |
| **C05 NavigationSystem** | 软依赖 | 调用 `get_travel_stamina_modifier()` 用于移动体力消耗 |
| **C07 NPCFriendshipSystem** | 软依赖 | 调用 `get_weather_mood_modifier(npc, weather)` 用于好感度计算 |
| **P04 CookingSystem** | 软依赖 | 雨雪天采集消耗额外体力 |
| **P07 HiddenNPCSystem** | 硬依赖 | long_ling_2 能力需要 weather system 提供下雨事件 |
| **P16 FarmMapSystem** | 软依赖 | 不同地图可能受天气影响（如山丘田庄地表矿脉） |
| **P17 TravelingMerchantSystem** | 软依赖 | 天气可能影响商人出现概率 |
| **P18 MarketSystem** | 软依赖 | 天气可能影响物价波动 |

### 信号订阅关系

| 信号名 | 订阅者 | 触发时机 | 动作 |
|--------|--------|----------|------|
| `day_changed(day, season)` | WeatherSystem | 每日结算 | 更新 today_weather, roll tomorrow_weather |
| `season_changed(season, year)` | WeatherSystem | 季节切换 | 切换季节概率表 |
| `year_changed(year)` | WeatherSystem | 年份递增 | 重置特殊事件标记 |

### 提供给下游的 API

```gdscript
class_name WeatherSystem extends Node

## 数据访问
func get_today_weather() -> String:
    """返回当前日天气类型"""

func get_tomorrow_weather() -> String:
    """返回明日天气预报"""

func is_rainy() -> bool:
    """返回是否雨天（rainy/stormy/green_rain/snowy 任一）"""

func is_stormy() -> bool:
    """返回是否雷雨天（有雷击风险）"""

func is_green_rain() -> bool:
    """返回是否绿雨"""

## 修正值查询
func get_stamina_modifier() -> float:
    """返回当前天气的体力消耗修正系数"""

func get_mining_yield_modifier() -> float:
    """返回采矿收益修正系数"""

func get_fishing_yield_modifier() -> float:
    """返回钓鱼收益修正系数"""

func get_crop_yield_modifier() -> float:
    """返回农作物产量修正系数"""

func is_lightning_risk() -> bool:
    """返回当前是否有雷击风险（stormy + 室外）"""

## 玩家交互
func set_tomorrow_weather(weather: String) -> void:
    """玩家通过物品（如雨图腾）强制指定明日天气"""

func clear_tomorrow_weather_override() -> void:
    """清除玩家天气强制覆盖"""

func has_player_override() -> bool:
    """返回是否有玩家强制天气"""

## 信号定义
signal weather_changed(new_weather: String, old_weather: String)
signal forecast_updated(tomorrow_weather: String)
signal lightning_strike_warning()
```

### 双向一致性验证

| 系统 | F02 列出依赖 | 该系统列出依赖 F02 | 状态 |
|------|-------------|-------------------|------|
| F01 TimeSeasonSystem | ✅ (F02→F01) | ✅ (F01→F02) | 一致 |
| P07 HiddenNPC | ✅ (软依赖) | 待验证 | 需确认 |
| F04 SaveLoad | ✅ | 待验证 | 需确认 |
| C01 PlayerStats | ✅ | 待验证 | 需确认 |
| C04 FarmPlot | ✅ | 待验证 | 需确认 |

### 特殊事件触发器

| 事件 | 触发条件 | 天气结果 | 触发信号 |
|------|----------|----------|----------|
| Year 1 Summer Day 5 | year==1 && season==summer && day==5 | green_rain | `weather_changed` |
| 唤雨能力激活 | P07 hidden_npc 激活 long_ling_2 | 下雨概率+15% | 无（被动影响） |

## Tuning Knobs

### 天气概率调节

| 参数 | 默认值 | 安全范围 | 影响 |
|------|-------|----------|------|
| `SPRING_SUNNY_BASE` | 0.50 | 0.30-0.70 | 春季晴天基础概率 |
| `SPRING_RAINY` | 0.25 | 0.10-0.40 | 春季雨天概率 |
| `SPRING_STORMY` | 0.10 | 0.05-0.20 | 春季雷雨概率 |
| `SUMMER_GREEN_RAIN` | 0.08 | 0.02-0.15 | 夏季绿雨概率 |
| `SUMMER_SUNNY_BASE` | 0.42 | 0.25-0.55 | 夏季晴天基础概率 |
| `SUMMER_RAINY` | 0.26 | 0.15-0.40 | 夏季雨天概率 |
| `SUMMER_STORMY` | 0.15 | 0.08-0.25 | 夏季雷雨概率 |
| `AUTUMN_SUNNY_BASE` | 0.45 | 0.25-0.60 | 秋季晴天基础概率 |
| `AUTUMN_RAINY` | 0.25 | 0.10-0.40 | 秋季雨天概率 |
| `WINTER_SUNNY_BASE` | 0.50 | 0.30-0.65 | 冬季晴天基础概率 |
| `WINTER_SNOWY` | 0.30 | 0.15-0.50 | 冬季雪天概率 |
| `RAIN_BOOST_AMOUNT` | 0.15 | 0.05-0.30 | 唤雨能力加成（压缩晴天概率） |

**危险值警告**:
- 任何季节概率总和超过 1.0 将导致逻辑错误（随机数越界）
- 雨天概率 > 50% 可能导致玩家抱怨（无法种地）
- 绿雨概率 > 15% 会降低其稀有感和惊喜度

### 天气影响调节

| 参数 | 默认值 | 安全范围 | 影响 |
|------|-------|----------|------|
| `RAINY_STAMINA_MOD` | 0.90 | 0.70-1.00 | 雨天体力消耗倍率 |
| `STORMY_STAMINA_MOD` | 0.80 | 0.60-1.00 | 雷雨体力消耗倍率 |
| `SNOWY_STAMINA_MOD` | 0.70 | 0.50-1.00 | 雪天体力消耗倍率 |
| `GREEN_RAIN_STAMINA_MOD` | 0.90 | 0.70-1.00 | 绿雨体力消耗倍率 |
| `RAINY_ACTIVITY_MOD` | 0.90 | 0.70-1.00 | 雨天采矿/钓鱼收益 |
| `STORMY_ACTIVITY_MOD` | 0.80 | 0.60-1.00 | 雷雨采矿/钓鱼收益 |
| `GREEN_RAIN_FISHING_MOD` | 1.10 | 1.00-1.30 | 绿雨钓鱼收益加成 |
| `GREEN_RAIN_CROP_MOD` | 1.10 | 1.00-1.30 | 绿雨农作物增产 |
| `LIGHTNING_STRIKE_CHANCE` | 0.05 | 0.01-0.15 | 雷雨室外昏厥概率 |
| `WINDY_CROP_LOSS_CHANCE` | 0.30 | 0.10-0.50 | 大风天浇水作物损失概率 |

### 特殊事件调节

| 参数 | 默认值 | 安全范围 | 影响 |
|------|-------|----------|------|
| `GREEN_RAIN_YEAR_1` | 1 | 固定 | 第一年触发绿雨 |
| `GREEN_RAIN_SEASON` | summer | 固定 | 绿雨发生季节 |
| `GREEN_RAIN_DAY` | 5 | 1-28 | 绿雨发生日期 |
| `SPRING_DAY_1_WEATHER` | sunny | 固定 | 春季第1天固定晴天 |
| `SUMMER_STORM_DAY_13` | stormy | 固定 | 夏季第13天雷雨 |
| `SUMMER_STORM_DAY_26` | stormy | 固定 | 夏季第26天雷雨 |

### 节日天气配置

| 参数 | 默认值 | 说明 |
|------|-------|------|
| `FESTIVAL_ALWAYS_SUNNY` | true | 节日是否强制晴天 |
| `FESTIVAL_OVERRIDE_TOTEM` | false | 节日是否覆盖玩家雨图腾（当前=false，玩家雨图腾优先） |

### 调试参数

| 参数 | 默认值 | 说明 |
|------|-------|------|
| `WEATHER_DEBUG_MODE` | false | 是否启用天气调试（固定某种天气） |
| `WEATHER_DEBUG_TYPE` | sunny | 调试模式固定天气 |
| `FORCE_WEATHER_ENABLED` | false | 是否允许 GM 命令强制天气 |

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

### 功能测试

1. [ ] **天气生成基础**
   - [ ] 新游戏开始时天气正确设置为 sunny
   - [ ] 天气预报 (tomorrow_weather) 在新游戏开始时正确 roll 出次日天气
   - [ ] 每日结算后 today_weather 更新为昨天的 tomorrow_weather

2. [ ] **季节概率分布**
   - [ ] 春季：连续模拟 1000 天，sunny 占比在 48%-52% 范围内
   - [ ] 夏季：连续模拟 1000 天，green_rain 占比在 7%-9% 范围内
   - [ ] 冬季：连续模拟 1000 天，snowy 占比在 28%-32% 范围内
   - [ ] windy 天气在各季节正确填补剩余概率

3. [ ] **固定天气日**
   - [ ] 春季第 1 天强制 sunny
   - [ ] 夏季第 13 天强制 stormy
   - [ ] 夏季第 26 天强制 stormy

4. [ ] **节日天气覆盖**
   - [ ] 节日日（春季: 1,8,15,24）强制 sunny
   - [ ] 节日日使用雨图腾后，雨图腾天气优先

5. [ ] **绿雨特殊事件**
   - [ ] 第一年夏季第 5 天必定为 green_rain
   - [ ] 绿雨天气有增产效果 (+10% 农作物)
   - [ ] 绿雨天气有特殊视觉效果

6. [ ] **唤雨能力**
   - [ ] 激活 long_ling_2 能力后，雨天概率增加 15%
   - [ ] 唤雨能力不影响 green_rain、stormy、windy 概率

7. [ ] **玩家天气覆盖**
   - [ ] 使用雨图腾后 tomorrow_weather 被覆盖
   - [ ] 每日结算不自动清除 player_override
   - [ ] player_override 在节日日仍然生效

8. [ ] **天气影响**
   - [ ] rainy/stormy/green_rain/snowy 天气时作物自动浇水
   - [ ] stormy 天气时室外有雷击昏厥风险 (5%)
   - [ ] windy 天气时已浇水作物有 30% 概率被吹走浇水状态

### 跨系统集成测试

1. [ ] **F01 TimeSeasonSystem 集成**
   - [ ] day_changed 信号触发 weather 更新
   - [ ] season_changed 信号触发概率表切换

2. [ ] **C01 PlayerStatsSystem 集成**
   - [ ] 雨天体力消耗应用 0.9 倍率
   - [ ] 雷雨体力消耗应用 0.8 倍率
   - [ ] 雪天体力消耗应用 0.7 倍率

3. [ ] **C03 SkillsSystem 集成**
   - [ ] 雨天采矿收益为 90%
   - [ ] 雷雨采矿收益为 80%
   - [ ] 绿雨钓鱼收益为 110%

4. [ ] **C04 FarmPlotSystem 集成**
   - [ ] 雨天不需手动浇水
   - [ ] 雪天不需手动浇水
   - [ ] 大风天后检查浇水状态

5. [ ] **F04 SaveLoadSystem 集成**
   - [ ] 存档正确保存 today_weather, tomorrow_weather, has_player_override
   - [ ] 读档正确恢复天气状态
   - [ ] 读档后立即更新日结算

### 性能测试

1. [ ] **帧时间**
   - [ ] 每帧天气查询处理时间 < 0.1ms
   - [ ] 信号触发无明显延迟

2. [ ] **内存**
   - [ ] WeatherSystem 单例内存占用 < 1KB
   - [ ] 无内存泄漏（连续 1000 次日结算）

### 边界条件测试

1. [ ] **边界日期**
   - [ ] 第 28 天结算时正确计算次季节天气
   - [ ] 冬季第 28 天后春季第 1 天为 sunny

2. [ ] **边界天气**
   - [ ] 非冬季不会随机到 snowy
   - [ ] 非夏季不会随机到 green_rain
   - [ ] 所有概率分布总和始终为 1.0

3. [ ] **同时触发**
   - [ ] 体力耗尽昏厥时，雷击不重复触发
   - [ ] 连续使用多个雨图腾正确叠加

### 用户体验测试

1. [ ] **UI 显示**
   - [ ] HUD 正确显示当前天气图标
   - [ ] HUD 正确显示明日天气预报
   - [ ] 天气变化有过渡动画

2. [ ] **音频反馈**
   - [ ] 晴天有晴天 BGM/环境音
   - [ ] 雨天有雨声环境音
   - [ ] 雷雨有雷声和闪电音效
   - [ ] 绿雨有独特的环境音

3. [ ] **视觉反馈**
   - [ ] 雨天屏幕有雨滴效果
   - [ ] 雷雨有闪电效果
   - [ ] 雪天有飘雪效果
   - [ ] 绿雨有绿色粒子效果

## Visual/Audio Requirements

### 天气视觉效果

| 天气类型 | 粒子效果 | 色调调整 | 特殊效果 |
|----------|----------|----------|----------|
| **sunny** | 无 | 明亮 (+10% 曝光) | 太阳光晕 |
| **rainy** | 雨滴粒子 | 灰暗 (-5% 曝光) | 地面水渍 |
| **stormy** | 暴雨粒子 + 闪电 | 暗沉 (-15% 曝光) | 闪光效果、屏幕微晃 |
| **snowy** | 飘雪粒子 | 冷色调 | 积雪覆盖 |
| **windy** | 风向粒子 | 正常 | 树叶飘动 |
| **green_rain** | 绿色雨滴粒子 | 翠绿滤镜 (+5% 绿色通道) | 萤火虫粒子 |

### 天气音频

| 天气类型 | 环境音 | BGM 变体 | 特效音 |
|----------|--------|----------|--------|
| **sunny** | 鸟鸣、风声 | 晴天 BGM | — |
| **rainy** | 持续雨声 | 雨天 BGM (低沉) | 雨滴落地 |
| **stormy** | 暴雨 + 雷声 | 紧张 BGM | 闪电音效、雷鸣 |
| **snowy** | 风声、安静 | 冬季 BGM | 脚步踩雪 |
| **windy** | 大风声 | 正常 BGM | 树叶沙沙 |
| **green_rain** | 奇幻雨声 + 虫鸣 | 神秘 BGM | 萤火虫音效 |

### 过渡动画

| 过渡类型 | 时长 | 效果 |
|----------|------|------|
| sunny → rainy | 2 秒 | 天空渐暗，雨滴渐现 |
| rainy → stormy | 1.5 秒 | 雨量增大，闪电预兆 |
| any → sunny | 3 秒 | 云散开，阳光渐现 |
| any → green_rain | 2.5 秒 | 色调渐绿，萤火虫出现 |

## UI Requirements

### HUD 天气显示

```
┌─────────────────────────────────────┐
│  [天气图标] 晴  🌤️                   │
│            明日: 雨  🌧️              │
└─────────────────────────────────────┘
```

**要求**:
- 当前天气图标位于 HUD 左上角或右上角
- 明日天气预报以较小图标 + 文字显示
- 绿雨使用特殊绿色图标区分

### 天气通知

| 触发时机 | 显示内容 | 持续时间 |
|----------|----------|----------|
| 新一天开始 | "今日天气: [天气]" | 3 秒 |
| 雷雨预警 | "⚠️ 暴风雨来袭，请注意！" | 5 秒 |
| 绿雨降临 | "✨ 绿雨降临！今日农作物增产！" | 4 秒 |
| 天气预报更新 | "明日天气预报: [天气]" | 3 秒 |

### 设置选项

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| 天气动画 | 开关 | 开 | 启用/禁用天气粒子效果 |
| 天气音效 | 滑块 | 80% | 天气环境音音量 |
| 雷暴警告 | 开关 | 开 | 雷雨时显示警告通知 |

## Open Questions

1. **绿雨的视觉风格**
   - 绿色雨滴的色调饱和度应该是多少？
   - 萤火虫粒子的密度和运动轨迹？
   - Owner: 需要与 Art Director 讨论

2. **节日天气是否需要变体**
   - 节日晴天的视觉效果是否与普通晴天不同？
   - 建议：节日晴天可以有装饰性花瓣/彩带飘落
   - Owner: 需要与 Art Director 讨论

3. **天气预报 UI 位置**
   - 明日天气预报应该固定显示在 HUD，还是需要玩家主动查看？
   - 当前设计：固定显示在 HUD（参考 Stardew Valley）
   - Owner: 需要与 UX Designer 确认

4. **雷暴昏厥是否需要提前警告**
   - 当前设计：5% 概率直接昏厥
   - 可选改进：昏厥前 5 秒屏幕闪烁警告，给玩家反应时间
   - Owner: 需要与 Game Designer 讨论

5. **天气对 NPC 外观的影响**
   - 雨天 NPC 是否需要打伞？
   - 雪天 NPC 是否需要戴围巾/手套？
   - Owner: 需要与 Art Team 讨论

6. **绿雨是否可以触发其他特殊事件**
   - 绿雨期间隐藏 NPC 是否更容易出现？
   - 绿雨期间钓鱼是否有稀有鱼种？
   - Owner: 需要与 Game Designer 讨论

7. **雪天室外移动是否需要特殊动画**
   - 当前设计：雪天移动体力-30%
   - 可选：雪天移动速度降低，播放雪地脚印动画
   - Owner: 需要与 Gameplay Team 讨论
