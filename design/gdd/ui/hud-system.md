# HUD系统 (HUD System)

> **状态**: Approved
> **Author**: Claude Code
> **Last Updated**: 2026-04-07
> **System ID**: U01
> **Implements Pillar**: UI 基础设施

## Overview

HUD系统是游戏的主界面覆盖层，在游戏过程中始终可见，为玩家提供关键的实时信息。系统采用模块化设计，底部显示玩家装备的工具/物品快捷栏，顶部显示时间、天气、金钱、体力、HP等核心状态，左下角显示当前位置和日期。HUD在游戏过程中不消失（除特定场景如剧情对话、全屏UI），但在小游戏中可以最小化显示。

设计为Extended复杂度，包含：
- **顶部栏**：时间、天气、金钱、体力条、HP条
- **左下角**：位置/日期/季节指示
- **右下角**：快捷操作按钮（背包、地图、任务等）
- **底部**：物品快捷栏（12格）
- **通知区域**：飘字提示

采用经典星露谷布局风格，信息层次清晰，玩家可以快速获取关键信息。

## Player Fantasy

HUD系统给玩家带来**信息尽在掌控的安心感**。玩家应该感受到：

- **信息一目了然** — 扫一眼就能知道时间、天气、金钱、还有多少体力
- **视觉反馈丰富** — 状态变化有流畅的动画（金币增加、体力消耗）
- **沉浸感强** — HUD与游戏画面融为一体，不突兀
- **关键时刻提示** — 重要事件通过飘字和图标闪烁提醒

参考游戏：
- **Stardew Valley**: 简洁但有效的HUD设计
- **河洛农场**: 色彩丰富、视觉反馈强烈的中国风HUD

## Detailed Design

### Core Rules

#### 1. HUD 组件层级

```
CanvasLayer (HUD Root)
├── TopBar (顶部栏)
│   ├── TimeDisplay (时间)
│   ├── WeatherIcon (天气)
│   ├── MoneyDisplay (金钱)
│   ├── StaminaBar (体力条)
│   └── HPBar (HP条)
├── LocationInfo (左下角)
│   ├── LocationName (位置名)
│   ├── DateDisplay (日期)
│   └── SeasonIcon (季节)
├── QuickButtons (右下角)
│   ├── InventoryBtn (背包)
│   ├── MapBtn (地图)
│   ├── QuestBtn (任务)
│   └── ...更多按钮
├── Hotbar (底部快捷栏)
│   └── Slot[0-11] (12个槽位)
└── NotificationArea (通知区域)
    └── FloatingText[] (飘字队列)
```

#### 2. 显示内容与数据源

| HUD 组件 | 数据源 | 格式 | 特殊效果 |
|----------|--------|------|----------|
| **时间** | F01 TimeSeasonSystem | `HH:MM` | 支持12/24小时制 |
| **天气** | F02 WeatherSystem | 图标 | 晴/雨/雷/雪/风/绿雨 |
| **金钱** | C01 PlayerStatsSystem | `+123` / `-50` | 绿色增加/红色减少 |
| **体力条** | C01 PlayerStatsSystem | 百分比条 | <25%变黄，<10%变红闪烁 |
| **HP条** | C01 PlayerStatsSystem | 百分比条 | <25%心跳动画 |
| **位置** | C05 NavigationSystem | 位置名称 | - |
| **日期** | F01 TimeSeasonSystem | `第N天` | - |
| **季节** | F01 TimeSeasonSystem | 图标 | 春/夏/秋/冬 |

#### 3. 快捷栏 (Hotbar)

- **槽位数量**: 12个
- **快捷键绑定**: 数字键 1-9, 0, -, = (键盘)
- **鼠标支持**: 点击槽位切换
- **选中效果**: 高亮边框 + 阴影加深
- **物品显示**: 工具显示图标，消耗品显示数量角标
- **冷却指示**: 技能/工具冷却时显示遮罩动画

#### 4. 通知系统 (Notifications)

**飘字类型**:
| 类型 | 颜色 | 示例 |
|------|------|------|
| 获取 | 金色 | `+5 金币` |
| 消耗 | 红色 | `-10 体力` |
| 完成 | 绿色 | `任务完成！` |
| 警告 | 橙色 | `背包已满` |
| 系统 | 白色 | `节日快乐！` |

**显示规则**:
- 最多同时显示 3 条飘字
- 每条持续 2 秒
- 后续通知排队等待
- 飘字向上飘动并淡出

**图标闪烁**:
- 任务更新：任务按钮闪烁 3 次
- NPC出现：地图按钮闪烁
- 节日提醒：日期区域闪烁

#### 5. 可见性控制

| 场景 | TopBar | LocationInfo | Hotbar | QuickButtons |
|------|--------|--------------|--------|--------------|
| 正常游戏 | ✅ 显示 | ✅ 显示 | ✅ 显示 | ✅ 显示 |
| 剧情/对话 | ✅ 显示 | ✅ 显示 | ❌ 隐藏 | ❌ 隐藏 |
| 小游戏 | ⚠️ 最小化 | ❌ 隐藏 | ❌ 隐藏 | ❌ 隐藏 |
| 全屏UI | ❌ 隐藏 | ❌ 隐藏 | ❌ 隐藏 | ❌ 隐藏 |
| 暂停菜单 | ❌ 隐藏 | ❌ 隐藏 | ❌ 隐藏 | ✅ 显示 |

### States and Transitions

#### HUD 可见性状态

| 状态 | 描述 | 组件可见性 |
|------|------|------------|
| **Visible** | 完全可见 | 所有组件正常显示 |
| **Hidden** | 完全隐藏 | 所有组件隐藏 |
| **Minimal** | 最小化 | 仅时间显示 |

#### 状态转换

| 转换 | 触发条件 |
|------|----------|
| `Visible` → `Hidden` | 进入全屏UI、截图模式 |
| `Hidden` → `Visible` | 退出全屏UI |
| `Visible` → `Minimal` | 进入小游戏 |
| `Minimal` → `Visible` | 小游戏结束 |
| `Any` → `Visible` | 游戏主场景 |

#### 控制机制

HUD订阅场景管理器的信号，自动切换可见性：
```gdscript
SceneManager.scene_changed.connect(_on_scene_changed)

func _on_scene_changed(new_scene):
    match new_scene.type:
        SceneType.FULLSCREEN_UI -> set_state(HUDState.Hidden)
        SceneType.MINIGAME -> set_state(HUDState.Minimal)
        SceneType.MAIN_GAME -> set_state(HUDState.Visible)
```

### Interactions with Other Systems

#### HUD 订阅的信号 (被动接收)

| 来源系统 | 信号 | 更新内容 |
|----------|------|----------|
| **C01 玩家属性** | `stamina_changed(current, max)` | 体力条 |
| **C01 玩家属性** | `health_changed(current, max)` | HP条 |
| **C01 玩家属性** | `money_changed(amount)` | 金钱显示 |
| **F01 时间季节** | `time_changed(hour, minute)` | 时间显示 |
| **F01 时间季节** | `day_changed(day, season)` | 日期显示 |
| **F01 时间季节** | `season_changed(season)` | 季节图标 |
| **F02 天气** | `weather_changed(weather)` | 天气图标 |
| **C02 库存** | `hotbar_selection_changed(slot_index)` | 选中槽位高亮 |
| **C05 导航** | `location_changed(new_group: int, old_group: int)` | 位置组变化 |
| **P08 任务** | `quest_updated(quest_id)` | 任务按钮闪烁 |
| **任意系统** | `notification_requested(text, type)` | 飘字显示 |
| **任意系统** | `icon_flash_requested(icon_id)` | 图标闪烁 |

#### HUD 发出的信号 (向上传递)

| 信号 | 参数 | 接收者 | 说明 |
|------|------|--------|------|
| `hotbar_slot_activated` | `slot_index: int` | C02 库存系统 | 快捷栏点击或按键 |
| `quick_button_pressed` | `button_id: String` | 场景管理器 | 快捷按钮点击 |
| `hud_state_changed` | `new_state: int` | 其他UI系统 | HUD状态变化 |

#### 数据查询接口 (主动获取)

HUD也通过单例直接查询当前状态：

```gdscript
# 获取当前显示值（用于初始化）
var stamina = PlayerStats.get_current_stamina()
var health = PlayerStats.get_current_health()
var money = PlayerStats.get_money()
var time = TimeSystem.get_current_time()
var weather = WeatherSystem.get_current_weather()
var location = NavigationSystem.get_current_location()
```

## Formulas

### 1. 进度条百分比计算

```
stamina_percent = (current_stamina / max_stamina) × 100%
health_percent = (current_health / max_health) × 100%
```

### 2. 飘字动画

```
# 位置随时间上移
position.y = start_y - (elapsed_time × FLOAT_SPEED)

# 透明度随时间淡出
alpha = lerp(1.0, 0.0, elapsed_time / FLOAT_DURATION)
```

**参数定义**:

| 参数 | 默认值 | 说明 |
|------|-------|------|
| `FLOAT_SPEED` | 50 px/s | 飘字上升速度 |
| `FLOAT_DURATION` | 2.0 s | 飘字持续时间 |
| `HP_BLINK_THRESHOLD` | 25% | HP低于此值开始闪烁 |
| `STAMINA_WARN_THRESHOLD` | 25% | 体力低于此值变黄色 |
| `STAMINA_CRIT_THRESHOLD` | 10% | 体力低于此值变红色闪烁 |

## Edge Cases

### 1. 数值边界

| 情况 | 处理方式 |
|------|----------|
| 体力 = 0 | 显示空条 + 灰色，禁止负数显示 |
| HP = 0 | 显示空条 + 红色闪烁，触发游戏死亡处理 |
| 金钱 = 0 | 显示 "0"，允许显示正数 |
| 金钱 < 0 | 理论上不可能发生（由C01保证），显示 "0" |
| 体力 > 上限 | 显示 100%，不允许溢出 |

### 2. 溢出情况

| 情况 | 处理方式 |
|------|----------|
| 金钱 > 99999 | 缩写显示：`12.3K`、`1.2M` |
| 通知队列满 | 新通知排队，超过10条时丢弃最旧通知 |
| 快捷栏空槽 | 显示空槽图标，点击无响应 |

### 3. 性能考虑

| 情况 | 处理方式 |
|------|----------|
| 信号频率过高 | 节流：同类型信号 100ms 内最多处理 1 次 |
| 飘字同时过多 | 最多同时显示 3 条，超出排队 |
| 动画掉帧 | 跳过中间帧，保证最终状态正确 |

### 4. 初始化异常

| 情况 | 处理方式 |
|------|----------|
| 未收到初始化信号 | 使用默认值：`0 体力`、`100 HP`、`0 金币`、`6:00` |
| 信号顺序混乱 | HUD始终信任最新接收到的值 |
| 系统单例未就绪 | 延迟 1 秒后重试，最多重试 3 次 |

### 5. 平台适配

| 情况 | 处理方式 |
|------|----------|
| 宽屏 (21:9) | HUD组件锚点到屏幕边缘，保持比例 |
| 窄屏 (16:9) | 缩小非必要组件，保留核心信息 |
| 移动端 | 增大触摸区域 (最小 44×44 px) |
| 游戏窗口调整大小 | 实时重新计算锚点和位置 |

### 6. 快捷键冲突

| 情况 | 处理方式 |
|------|----------|
| 快捷键被其他UI占用 | HUD快捷栏不响应，游戏内操作优先 |
| 手柄模式 | 快捷栏高亮当前选中槽位，使用方向键切换 |

## Dependencies

### 上游依赖 (U01 HUD依赖其他系统)

| 系统 | 依赖类型 | 数据流入 | 信号接口 |
|------|----------|----------|----------|
| **C01 玩家属性** | 硬依赖 | 体力/HP/金钱值 | `stamina_changed(current, max)`, `health_changed(current, max)`, `money_changed(amount)` |
| **F01 时间季节** | 硬依赖 | 时间/日期/季节 | `time_changed(hour, minute)`, `day_changed(day, season)`, `season_changed(season)` |
| **F02 天气** | 硬依赖 | 天气类型 | `weather_changed(weather)` |
| **C02 库存** | 硬依赖 | 快捷栏选中 | `hotbar_selection_changed(slot_index)` |
| **C05 导航** | 硬依赖 | 当前位置 | `location_changed(new_group: int, old_group: int)` |
| **P08 任务** | 软依赖 | 任务更新 | `quest_updated(quest_id)` |

### 下游依赖 (其他系统依赖 U01)

| 系统 | 依赖类型 | 数据流出 | 说明 |
|------|----------|----------|------|
| **U02-U16 所有UI** | 硬依赖 | HUD可见性状态 | 其他UI显示时需要隐藏HUD |
| **场景管理器** | 硬依赖 | 场景切换事件 | 决定HUD显示/隐藏状态 |

### 信号接口详细定义

**C01 → HUD**:
```gdscript
signal stamina_changed(current: int, max: int)
signal health_changed(current: int, max: int)
signal money_changed(amount: int)  # amount为变化量，不是总额
```

**F01 → HUD**:
```gdscript
signal time_changed(hour: int, minute: int)  # 24小时制
signal day_changed(day: int, season: String)  # season: "spring"/"summer"/"autumn"/"winter"
signal season_changed(season: String)
```

**F02 → HUD**:
```gdscript
signal weather_changed(weather: String)  # "sunny"/"rainy"/"stormy"/"snowy"/"windy"/"green_rain"
```

**C02 → HUD**:
```gdscript
signal hotbar_selection_changed(slot_index: int)  # 0-11
```

**HUD → 其他系统**:
```gdscript
signal hotbar_slot_activated(slot_index: int)
signal quick_button_pressed(button_id: String)  # "inventory"/"map"/"quest"/"menu"/...
```

## Tuning Knobs

### 布局参数

| 参数 | 默认值 | 范围 | 说明 |
|------|-------|------|------|
| `HOTBAR_SLOTS` | 12 | 6-16 | 快捷栏槽位数量 |
| `HOTBAR_Y_OFFSET` | 20px | 0-100px | 快捷栏距底部距离 |
| `TOPBAR_HEIGHT` | 50px | 30-80px | 顶部栏高度 |
| `QUICK_BUTTON_SIZE` | 48px | 32-64px | 快捷按钮大小 |

### 动画参数

| 参数 | 默认值 | 范围 | 影响 |
|------|-------|------|------|
| `NOTIFICATION_DURATION` | 2.0s | 1.0-5.0s | 飘字显示时长 |
| `NOTIFICATION_MAX` | 3 | 1-5 | 同时显示飘字最大数量 |
| `NOTIFICATION_SPACING` | 30px | 10-50px | 飘字间距 |
| `FLOAT_SPEED` | 50px/s | 20-100px/s | 飘字上升速度 |
| `VALUE_CHANGE_SPEED` | 0.3s | 0.1-1.0s | 数值变化动画时长 |

### 性能参数

| 参数 | 默认值 | 范围 | 说明 |
|------|-------|------|------|
| `SIGNAL_THROTTLE_MS` | 100ms | 50-500ms | 同类型信号最小间隔 |
| `MAX_NOTIFICATION_QUEUE` | 10 | 5-20 | 通知队列最大长度 |

### 显示格式参数

| 参数 | 默认值 | 选项 | 说明 |
|------|-------|------|------|
| `TIME_FORMAT` | `"24h"` | `"12h"`/`"24h"` | 时间显示格式 |
| `MONEY_ABBREVIATION` | `true` | `true`/`false` | 大额金钱是否缩写 |
| `MONEY_ABBREV_THRESHOLD` | 10000 | 1000-100000 | 缩写阈值 |
| `SHOW_LOCATION` | `true` | `true`/`false` | 是否显示位置信息 |

## Visual/Audio Requirements

### 视觉资源需求

| 资源类型 | 格式 | 分辨率 | 数量 | 状态 |
|----------|------|--------|------|------|
| **天气图标** | PNG | 32×32 | 6 | 晴/雨/雷/雪/风/绿雨 |
| **季节图标** | PNG | 24×24 | 4 | 春/夏/秋/冬 |
| **时间图标** | PNG | 24×24 | 1 | 太阳/月亮共用 |
| **HP条填充** | PNG | 可平铺 | 4 | 100%/75%/50%/25% |
| **体力条填充** | PNG | 可平铺 | 4 | 满/良好/警告/危险 |
| **快捷栏槽位** | PNG | 48×48 | 2 | 选中/未选中 |
| **快捷按钮** | PNG | 32×32 | 8 | 背包/地图/任务/菜单/社交/公会/收藏/设置 |

### 图标风格规范

- **整体风格**: 像素风格 (Pixel Art)，与游戏画面协调
- **颜色**: 参考游戏整体色调，中国古风
- **动画帧**: 天气图标/季节图标需有循环动画 (2-4帧)

### 状态条颜色规范

| 状态 | HP颜色 | 体力颜色 | 触发条件 |
|------|--------|----------|----------|
| 满 | 红色 (#E74C3C) | 绿色 (#2ECC71) | 75%-100% |
| 良好 | 红色 | 浅绿 (#58D68D) | 50%-75% |
| 警告 | 深红 (#C0392B) | 黄色 (#F39C12) | 25%-50% |
| 危险 | 深红 + 心跳动画 | 红色 + 闪烁 (#E74C3C) | <25% |

**HP心跳动画触发**: 当 HP < 25% 最大值时触发心跳动画（红色心形图标缩放动画）。

### 音效资源

| 音效 | 文件 | 时长 | 触发时机 |
|------|------|------|----------|
| 快捷栏切换 | `sfx/ui/hotbar_select.ogg` | 0.1s | 点击/按键切换槽位 |
| 快捷键按下 | `sfx/ui/hotbar_activate.ogg` | 0.1s | 数字键激活槽位 |
| 通知弹出 | `sfx/ui/notification.ogg` | 0.3s | 飘字显示时 |
| 警告提示 | `sfx/ui/warning.ogg` | 0.5s | 低体力/低HP警告 |

### 字体资源

| 用途 | 字体 | 大小 | 颜色 |
|------|------|------|------|
| 时间显示 | 宋体/思源宋体 | 18pt | 白色 + 阴影 |
| 金钱显示 | 宋体 | 16pt | 金色 (#FFD700) |
| 日期显示 | 宋体 | 14pt | 白色 |
| 飘字 | 宋体 | 14pt | 按类型变色 |

## UI Requirements

### 布局结构

```
┌─────────────────────────────────────────────────────────┐
│  ⏰ 6:00  [☀️]    💰 1234   [████████░░] [██████░░]   │  ← TopBar (50px)
├─────────────────────────────────────────────────────────┤
│                                                     [📦] │  ← QuickButtons
│  📍 农场                                            [🗺️] │    (右侧)
│  📅 第1天                                          [📋] │
│  [🌸]                                               [⚙️] │
│                                                     [☰] │
│                                                     [🎯] │
├─────────────────────────────────────────────────────────┤
│  📍 农场    第1天  [🌸春]                             │  ← LocationInfo
│                                                         │    (左下角)
├─────────────────────────────────────────────────────────┤
│  [1] [2] [3] [4] [5] [6] [7] [8] [9] [0] [-] [=]     │  ← Hotbar (64px)
│   🔨  ⚔️  🌾  🎣  ⛏️                                 │    (底部)
└─────────────────────────────────────────────────────────┘
```

### 布局尺寸规范

| 区域 | 宽度 | 高度 | 锚点 |
|------|------|------|------|
| TopBar | 屏幕宽度 | 50px | TopCenter |
| LocationInfo | 200px | 60px | BottomLeft, margin 20px |
| QuickButtons | 60px | 240px | BottomRight, margin 20px |
| Hotbar | 12×56px + 间距 | 64px | BottomCenter |

### 组件规格

#### TopBar 组件

| 组件 | 宽度 | 位置 | 内容 |
|------|------|------|------|
| 时间显示 | 80px | 左起 20px | 图标 + `HH:MM` |
| 天气图标 | 32px | 时间右侧 10px | 当前天气图标 |
| 金钱显示 | 100px | 居中 | `💰` + 金额 |
| 体力条 | 150px | 金钱右侧 20px | 填充条 + 数值 |
| HP条 | 100px | 体力条右侧 10px | 填充条 + 数值 |

#### Hotbar 组件

| 规格 | 值 |
|------|-----|
| 槽位大小 | 48×48px |
| 槽位间距 | 4px |
| 选中边框 | 3px 金色 |
| 未选中边框 | 1px 灰色 |
| 物品图标 | 居中显示，最大 40×40px |
| 数量角标 | 右下角，白色小字 |

#### QuickButtons 组件

| 按钮 | 大小 | 功能 | 键盘快捷键 |
|------|------|------|------------|
| 背包 | 48×48px | 打开背包UI | B |
| 地图 | 48×48px | 打开地图UI | M |
| 任务 | 48×48px | 打开任务UI | J |
| 社交 | 48×48px | 打开社交UI | C |
| 菜单 | 48×48px | 打开暂停菜单 | ESC |

**注**: 社交/公会/收藏/设置等按钮可在后续根据需求添加，当前MVP阶段保留4-5个核心按钮。

### 交互规范

| 操作 | 输入 | 响应 |
|------|------|------|
| 切换快捷栏 | 数字键 1-9, 0, -, = | 高亮对应槽位，播放音效 |
| 使用物品/工具 | 按E或点击右键 | 触发快捷栏选中项 |
| 打开背包 | 点击按钮或按B | 发出 `quick_button_pressed("inventory")` |
| 打开地图 | 点击按钮或按M | 发出 `quick_button_pressed("map")` |
| 打开任务 | 点击按钮或按J | 发出 `quick_button_pressed("quest")` |
| 打开菜单 | ESC或点击菜单按钮 | 发出 `quick_button_pressed("menu")` |
| 悬停物品 | 鼠标悬停 | 显示Tooltip，显示物品名称和描述 |

### 键盘映射

| 键位 | 功能 |
|------|------|
| 1-9 | 快捷栏 1-9 |
| 0 | 快捷栏 10 |
| - | 快捷栏 11 |
| = | 快捷栏 12 |
| B | 打开背包 |
| M | 打开地图 |
| J | 打开任务 |
| ESC | 打开菜单 |
| E | 使用当前工具/物品 |

### 手柄支持

| 操作 | 输入 | 响应 |
|------|------|------|
| 切换槽位 | LB/RB 或 十字键 | 左右切换快捷栏 |
| 使用 | A键 | 使用当前槽位 |
| 打开背包 | X键 | 快捷按钮 |
| 打开地图 | Y键 | 快捷按钮 |

## Acceptance Criteria

### 功能测试

1. [ ] **基础显示**
   - [ ] 时间显示为 `HH:MM` 格式，与 F01 同步
   - [ ] 天气图标根据 F02 显示正确图标 (晴/雨/雷/雪/风/绿雨)
   - [ ] 金钱显示为正整数，带货币符号
   - [ ] 体力条显示百分比，颜色根据阈值变化
   - [ ] HP条显示百分比，颜色根据阈值变化

2. [ ] **快捷栏**
   - [ ] 12个槽位正确排列
   - [ ] 按键 1-9, 0, -, = 正确切换槽位
   - [ ] 鼠标点击槽位正确切换
   - [ ] 选中槽位有高亮效果
   - [ ] 物品图标正确显示在槽位中

3. [ ] **通知系统**
   - [ ] 飘字在屏幕中央偏上位置显示
   - [ ] 飘字向上飘动并淡出
   - [ ] 颜色正确区分类型 (金/绿/红/橙/白)
   - [ ] 同时最多显示3条飘字
   - [ ] 后续飘字正确排队

4. [ ] **可见性控制**
   - [ ] 全屏UI时HUD完全隐藏
   - [ ] 小游戏时HUD最小化
   - [ ] 场景切换时HUD状态正确响应

### 跨系统集成测试

1. [ ] **C01 玩家属性**
   - [ ] 体力消耗后体力条实时减少
   - [ ] 体力耗尽时体力条变红闪烁
   - [ ] HP减少后HP条实时减少
   - [ ] HP低于25%时心跳动画
   - [ ] 金钱变化时显示增减飘字

2. [ ] **F01 时间季节**
   - [ ] 时间变化时TopBar时间更新
   - [ ] 午夜时分日期更新
   - [ ] 季节切换时季节图标更新

3. [ ] **F02 天气**
   - [ ] 天气变化时天气图标更新
   - [ ] 天气图标有循环动画

4. [ ] **C05 导航**
   - [ ] 地图切换时位置信息更新
   - [ ] 位置名称正确显示

### 性能测试

1. [ ] **响应时间**
   - [ ] 信号接收后 UI 更新 < 16ms (一帧)
   - [ ] 快捷键响应 < 50ms

2. [ ] **内存占用**
   - [ ] HUD场景内存 < 5MB
   - [ ] 纹理资源 < 2MB

3. [ ] **帧率影响**
   - [ ] HUD对帧率影响 < 0.5fps

### 用户体验测试

1. [ ] **可读性**
   - [ ] 所有文字在默认尺寸下清晰可读
   - [ ] 重要信息 (体力/HP) 一目了然

2. [ ] **反馈感**
   - [ ] 数值变化有平滑过渡动画
   - [ ] 快捷栏切换有音效反馈

3. [ ] **无障碍**
   - [ ] 所有功能可通过键盘操作
   - [ ] 手柄支持完整

## Open Questions

1. **快捷按钮数量**
   - 当前设计6个按钮，是否足够？
   - Owner: UX Designer

2. **手柄按钮映射**
   - QuickButtons的手柄按钮需要与UX Designer确认
   - Owner: UX Designer

3. **中文本地化**
   - 所有文本需要支持中英文切换
   - Owner: Localization Lead

4. **Toolbox 快捷栏**
   - 工具是否需要单独的快捷栏？
   - Owner: Game Designer
