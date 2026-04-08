# 时间/季节系统 (Time/Season System)

> **状态**: In Review (修复中)
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: F01

## Overview

时间/季节系统是游戏的基础计时系统，管理游戏内的时间流逝、季节循环和天气变化。游戏时间从6:00开始，到次日2:00结束（26:00），每季节28天，每年4季。玩家在游戏中执行各种行动都会消耗时间，推进游戏时钟。系统与天气系统、存档系统、所有需要时间的游戏系统交互。

## Player Fantasy

时间/季节系统让玩家感受到岁月的流转和劳作的节奏感。玩家应该感受到：

- **春种秋收的农业节奏** — 春天是播种的希望季节，夏天是繁忙的生长季，秋天是丰收的喜悦，冬天是休养生息的宁静
- **每一天都很重要** — 时间流逝的压力让玩家珍惜每个决定，"今天还能做什么？"
- **自然的韵律** — 天气变化影响计划，雨天适合采矿，晴天适合农作

参考游戏: Stardew Valley 的时间系统让玩家既感到紧迫又不焦虑。

## Detailed Design

### Core Rules

1. **游戏时钟**
   - 游戏日从 6:00 开始，到 26:00（次日 2:00）结束
   - 每游戏小时 = 700ms 实时时间（可配置速度）
   - 26:00 强制睡眠（或体力耗尽时提前昏厥）

2. **日期推进**
   - 每日 28 天（可配置）
   - 季节顺序: 春 → 夏 → 秋 → 冬 → 春（年循环）
   - 季节切换时执行每日结算（作物、动物、机器等）

3. **时段划分**
   - 早晨: 6:00-12:00
   - 下午: 12:00-17:00
   - 傍晚: 17:00-20:00
   - 夜晚: 20:00-24:00
   - 深夜: 24:00-26:00

4. **时间流逝规则**
   - 玩家主动行动消耗时间（耕地、钓鱼、采矿等）
   - 移动消耗时间（farm→village: 0.17h）
   - 睡眠推进到次日 6:00

5. **深夜惩罚**
   - 24时就寝: 次日体力恢复90%
   - 25时就寝: 次日体力恢复60%
   - 26时（强制睡眠）: 体力恢复50%，扣钱惩罚

### States and Transitions

| 状态 | 描述 | 进入条件 | 退出条件 |
|------|------|----------|----------|
| **TimeRunning** | 时间正常流逝 | 游戏开始/取消暂停 | 暂停/进入小游戏/睡眠 |
| **TimePaused** | 时间暂停 | 打开菜单/UI/对话 | 关闭菜单/UI/对话 |
| **MiniGame** | 小游戏中 | 进入钓鱼/采矿小游戏 | 小游戏结束 |
| **Sleeping** | 睡眠过渡 | 点击睡觉/强制昏厥 | 进入下一天 6:00 |
| **DayTransition** | 日结算 | Sleeping结束 | 结算完成 |
| **SeasonTransition** | 季节切换 | DayTransition完成 且 day=28 | 新季节第1天 或 新年春季 |

**状态关系说明**:
- `Sleeping` → `DayTransition`: 日结算开始
- `DayTransition` (day < 28) → `TimeRunning`: 普通日结算完成后继续
- `DayTransition` (day = 28) → `SeasonTransition`: 季节最后一天，进入季节切换
- `SeasonTransition` (season < winter) → `TimeRunning`: 新季节第1天
- `SeasonTransition` (season = winter) → `TimeRunning`: 新年第1天春季

**关键转换**:
- `TimeRunning` → `TimePaused`: 打开任何菜单
- `TimePaused` → `TimeRunning`: 关闭菜单
- `TimeRunning` → `Sleeping`: 点击床铺 或 hour >= 26
- `Sleeping` → `DayTransition` → `TimeRunning`: 完成日结算

### Interactions with Other Systems

| 系统 | 数据流入 | 数据流出 |
|------|----------|----------|
| **F02 天气系统** | 当前季节和日期用于生成天气 | 天气影响玩家体力消耗 |
| **C01 玩家属性系统** | 体力值决定是否强制睡眠 | 睡眠影响次日体力恢复 |
| **C05 导航系统** | 目的地决定移动时间消耗 | 移动时间更新游戏时钟 |
| **P01 畜牧系统** | 每日结算需要知道日期 | 更新动物状态 |
| **P02 钓鱼系统** | 时段影响鱼类出现 | 钓鱼消耗时间 |
| **P03 采矿系统** | 时段影响矿洞生成 | 采矿消耗时间 |
| **P08 任务系统** | 日期影响任务刷新 | 任务可能改变玩家位置 |
| **F04 存档系统** | 保存当前时间状态 | 加载恢复时间状态 |

## Formulas

1. **游戏时钟推进**
   - `游戏小时数 = 实时秒数 / 700ms`
   - 默认速度: 1x (700ms/h)
   - 可配置速度: 0.5x, 1x, 2x, 3x

2. **日期计算**
   - `seasonDay = ((year - 1) * 4 + seasonIndex) * 28 + day`
   - `seasonIndex = [spring:0, summer:1, autumn:2, winter:3]`

3. **就寝恢复率**
   ```
   if bedtime == 24: recoveryRate = 0.90
   elif bedtime == 25: recoveryRate = 0.60
   else: recoveryRate = 0.50  // bedtime >= 26 (强制睡眠)
   ```

4. **移动时间消耗**
   - `travelHours = TRAVEL_TIME[fromLocation -> toLocation]`
   - 例: farm→village = 0.17h

5. **行动时间消耗**
   - `actionHours = ACTION_TIME_COSTS[actionType]`
   - 例: till = 0.17h, water = 0.08h
   - 工具减免: `actualMinutes = max(MIN_ACTION_MINUTES, actionMinutes - toolSavings - skillSavings)`

## Edge Cases

1. **体力耗尽**
   - 当体力 <= 0 时，无论时间，都触发强制昏厥
   - 昏厥等同于26时强制睡眠
   - 昏厥地点固定为farm

2. **午夜零点**
   - hour 达到 24 时显示警告提示玩家
   - midnightWarned 标志防止重复警告

3. **闰年/季节边界**
   - 第28天结束后自动进入下季节第1天
   - 冬季结束后回到春季，年份+1

4. **时间暂停期间的操作**
   - 打开菜单时不推进时间
   - 关闭菜单后时间自动继续

5. **存档/读档时间**
   - 存档保存完整时间状态 (year, season, day, hour)
   - 读档恢复时间状态后立即更新日结算

6. **时区/夏令时**
   - 不考虑现实时间，全部游戏内时间

## Dependencies

**上游依赖 (F01 依赖其他系统)**:
- 无 (Foundation 层，最底层)

**下游依赖 (其他系统依赖 F01)**:
| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| F02 天气系统 | 硬依赖 | 需要 F01 提供的 season, day 生成天气 |
| F04 存档系统 | 硬依赖 | 需要保存/恢复 year, season, day, hour |
| F05 音效系统 | 软依赖 | 可根据时段播放不同 BGM |
| C01 玩家属性 | 硬依赖 | 需要检查 hour >= 26 触发睡眠 |
| C05 导航系统 | 硬依赖 | 移动消耗时间，更新 hour |
| P01-P19 所有内容系统 | 硬依赖 | 每日结算需要知道日期变化 |

**新系统接入时**:
- 如果新系统需要知道日期变化，必须订阅 `day_changed` 信号
- 如果新系统需要知道季节变化，必须订阅 `season_changed` 信号
- 如果新系统需要知道时间流逝，必须订阅 `hour_changed` 信号

### 信号接口定义

| 信号名 | 参数 | 触发时机 | 订阅者示例 |
|--------|------|----------|-----------|
| `hour_changed` | `hour: int` | 游戏时钟每推进1小时 | F05音效(换BGM)、C05导航(检查商店开门) |
| `day_changed` | `day: int, season: Season` | 日期推进时 (0:00) | P01畜牧(产蛋)、P02钓鱼(重置次数) |
| `season_changed` | `season: Season, year: int` | 季节切换时 | F02天气(换季概率)、P04烹饪(换季食谱) |
| `year_changed` | `year: int` | 年份递增时 | P09成就(年度统计) |
| `sleep_triggered` | `bedtime: int, forced: bool` | 触发睡眠时 | C01玩家(昏厥动画) |
| `time_paused` | - | 时间暂停时 | F05音效(暂停BGM) |
| `time_resumed` | - | 时间恢复时 | F05音效(继续BGM) |

## Tuning Knobs

| 参数 | 默认值 | 范围 | 影响 |
|------|-------|------|------|
| `HOUR_DURATION_MS` | 700ms | 300-2000ms | 游戏速度 |
| `DAY_START_HOUR` | 6 | 固定 | 游戏日开始时间 |
| `DAY_END_HOUR` | 26 | 固定 | 游戏日结束时间 |
| `DAYS_PER_SEASON` | 28 | 7-56 | 季节长度 |
| `TIME_SCALE_MIN` | 0.5x | 固定 | 最低速度 |
| `TIME_SCALE_MAX` | 3x | 固定 | 最高速度 |
| `MIDNIGHT_WARNING_HOUR` | 24 | 固定 | 显示警告时间 |
| `LATE_NIGHT_RECOVERY_MAX` | 90% | 50-100% | 24时就寝恢复 |
| `LATE_NIGHT_RECOVERY_MIN` | 60% | 30-80% | 25时就寝恢复 |
| `PASSOUT_STAMINA_RECOVERY` | 50% | 固定 | 强制睡眠恢复 |

**危险值警告**:
- `HOUR_DURATION_MS < 300`: 可能导致动画来不及播放
- `DAYS_PER_SEASON > 56`: 可能导致季节内容太少显得空洞
- `DAYS_PER_SEASON < 7`: 可能导致游戏节奏过快

## Acceptance Criteria

**功能测试**:
1. [ ] 游戏开始时时间正确设置为 6:00
2. [ ] 时间每 700ms推进 1 小时
3. [ ] 时间到达 26:00 时触发睡眠
4. [ ] 睡眠后日期正确推进（day++, hour=6）
5. [ ] 第 28 天结束后正确切换季节
6. [ ] 冬季结束后年份 +1
7. [ ] 打开菜单时时间暂停
8. [ ] 关闭菜单时时间继续
9. [ ] 体力耗尽时触发强制昏厥
10. [ ] 存档/读档正确保存/恢复时间状态

**性能测试**:
- [ ] 每帧处理时间 < 0.5ms
- [ ] 信号触发无延迟

**跨系统测试**:
- [ ] 天气系统正确接收季节/日期
- [ ] 导航系统正确消耗时间
- [ ] 畜牧/钓鱼/采矿等系统正确响应日结算

## Open Questions

1. **现实时间暂停**
   - 是否支持现实时间暂停？（游戏内时间冻结但外部时间继续）
   - Owner: 需要与 UI/UX 团队讨论

2. **时间快进功能**
   - 是否需要「加速时间直到某事件」功能？
   - Owner: 需要与游戏设计团队讨论

3. **时间可调节性**
   - 季节天数是否应该在游戏内可调节？
   - Owner: 取决于目标用户群体
