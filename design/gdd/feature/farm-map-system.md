# 农场地图系统 (Farm Map System)

> **Status**: Approved
> **Author**: Claude + User
> **Last Updated**: 2026-04-07
> **Implements Pillar**: 角色养成与自定义化

## Overview

农场地图系统管理玩家农场的视觉布局和地形配置。系统提供6种预设地图风格供开局选择，随着游戏进度解锁地形装饰和定制选项，地图装饰随季节自动变化。玩家可以通过地形改造解锁更多可用地块，打造属于自己的独特农场。

**地图系统分层**:
- **基础层**: 地形高度、水系分布（开局固定，不可更改）
- **装饰层**: 树木、花草、石头、栅栏（可解锁）
- **功能层**: 可用地块、建筑位置（可扩展）
- **主题层**: 季节性装饰变化（自动应用）

**与 F01/F02 的关系**: F01 提供季节信息用于自动切换季节主题，F02 提供天气影响地图视觉效果。

## Player Fantasy

农场地图系统给玩家带来**归属感和成就感**。玩家应该感受到：

- **独特的农场身份** — 6种地图风格让每个存档都与众不同
- **装扮的乐趣** — 解锁新装饰后迫不及待地美化农场
- **季节变换的美感** — 春天樱花、夏天绿荫、秋天红叶、冬天雪景
- **解锁的期待** — 看着地图逐渐丰满，每一处都有自己的痕迹

**Reference games**: Stardew Valley 的农场布局；Animal Crossing 的岛屿装饰。

**情感曲线**:
1. **初入农场**: 空旷但充满可能
2. **建设阶段**: 不断扩大可用地块
3. **美化阶段**: 精心装饰每一处
4. **完美农场**: 四季皆美的终极农场

## Detailed Design

### Core Rules

#### 1. 6种基础地图风格

**地图配置**:

| 地图ID | 名称 | 主题 | 可用地块 | 水系 | 特殊地形 |
|--------|------|------|----------|------|----------|
| **standard** | 标准农场 | 普通草原 | 600格 | 中央池塘 | 无 |
| **river** | 河流农场 | 水系丰富 | 500格 | 多条河流 | 钓鱼点+3 |
| **forest** | 森林农场 | 密林环绕 | 450格 | 小溪 | 采集点+5 |
| **mountain** | 山顶农场 | 高地梯田 | 550格 | 瀑布 | 采矿点+3 |
| **hillside** | 山地农场 | 崎岖山地 | 480格 | 山泉 | 洞穴入口 |
| **desert** | 沙漠绿洲 | 沙漠边缘 | 520格 | 绿洲 | 仙人掌采集 |

**地形解锁**:

| 解锁项 | 解锁条件 | 解锁内容 |
|--------|----------|----------|
| **额外地块** | 社区中心或10000g | +100格可用耕地 |
| **河流调整** | 第二年或25000g | 改变水系流向 |
| **山体开垦** | 矿洞50层 | 山地可破坏开垦 |
| **绿洲扩展** | 沙漠探索完成 | 额外水源 |

#### 2. 装饰系统

**装饰分类**:

| 类别 | 装饰类型 | 解锁方式 |
|------|----------|----------|
| **栅栏** | 木栅栏、石栅栏、铁栅栏、藤蔓栅栏 | 开局解锁 |
| **树木** | 橡树、松树、樱花树、柳树、果树 | 种子商店购买 |
| **花草** | 花丛、花坛、花拱门 | 社区中心 |
| **石头** | 装饰石、假山、小瀑布 | 任务解锁 |
| **户外家具** | 长椅、灯笼、风车、信箱 | 家具商店 |
| **季节装饰** | 春季花环、夏季阳伞、秋季南瓜、冬季彩灯 | 自动随季节 |

**装饰规则**:
- 装饰不影响游戏功能
- 装饰有碰撞检测（不可穿行）
- 每类装饰有最大数量限制

#### 3. 季节主题

**季节视觉变化**:

| 季节 | 地面色彩 | 植被 | 特殊装饰 |
|------|----------|------|----------|
| **春季** | 嫩绿 | 樱花、桃花 | 春季花环 |
| **夏季** | 深绿 | 绿荫、荷塘 | 夏季阳伞、遮阳棚 |
| **秋季** | 金黄红 | 红叶、落叶 | 南瓜、稻草人 |
| **冬季** | 雪白 | 常青树 | 冬季彩灯、积雪 |

**季节过渡动画**:
- 季节最后一天晚上下雪/落叶效果
- 季节第一天早晨完成视觉切换

#### 4. 地图编辑模式

**进入条件**: 持有锤子工具
**操作方式**: 
1. 按 H 进入/退出编辑模式
2. 拖拽放置装饰
3. 右键删除装饰
4. 按 ESC 退出确认

**编辑限制**:
- 耕地内不可放置装饰
- 建筑周围需要空间
- 水域内不可放置

### States and Transitions

#### 地图解锁状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Locked** | 装饰/地形未解锁 | 未满足解锁条件 |
| **Unlocked** | 已解锁 | 满足解锁条件 |
| **Active** | 当前使用中 | 已放置在地图上 |

#### 编辑模式状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Normal** | 正常游戏模式 | 默认状态 |
| **EditMode** | 地图编辑模式 | 按 H 键 |
| **Placing** | 放置装饰中 | 选择装饰后 |
| **Deleting** | 删除装饰中 | 右键点击 |

**状态转换**:
```
Normal → EditMode: hold_hammer + press_H
EditMode → Normal: press_ESC or finish_editing
EditMode → Placing: select_decoration_from_menu
Placing → EditMode: place_decoration or press_ESC
EditMode → Deleting: right_click_decoration
Deleting → EditMode: confirm_delete or cancel
```

#### 季节状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **SpringTheme** | 春季主题 | 季节为春季 |
| **SummerTheme** | 夏季主题 | 季节为夏季 |
| **AutumnTheme** | 秋季主题 | 季节为秋季 |
| **WinterTheme** | 冬季主题 | 季节为冬季 |

**状态转换**:
```
[Season]Theme → NextSeasonTheme: day 28 midnight + season_change
```

### Interactions with Other Systems

#### 依赖系统 (Upstream Dependencies)

| System | Interface | Usage |
|--------|-----------|-------|
| **F01 时间/季节系统** | `get_season()`, `get_day()` | 季节主题切换 |
| **F02 天气系统** | `get_weather()` | 天气视觉效果 |
| **C04 农场地块系统** | `get_plot_count()` | 可用地块数量 |

#### API 接口

```gdscript
class_name FarmMapSystem extends Node

## 单例访问
static func get_instance() -> FarmMapSystem

## 地图信息
func get_current_map_type() -> String:
    """获取当前地图类型"""

func get_map_config(map_type: String) -> MapConfig:
    """获取地图配置"""

func get_available_plots() -> int:
    """获取可用耕地格数"""

func get_unlocked_decorations() -> Array:
    """获取已解锁装饰列表"""

## 装饰系统
func place_decoration(x: int, y: int, decoration_id: String) -> bool:
    """放置装饰"""

func remove_decoration(x: int, y: int) -> bool:
    """移除装饰"""

func get_decoration_at(x: int, y: int) -> Decoration | null:
    """获取指定位置的装饰"""

func is_position_valid(x: int, y: int) -> bool:
    """检查位置是否可以放置装饰"""

## 解锁系统
func unlock_decoration(decoration_id: String) -> bool:
    """解锁装饰"""

func check_unlock_conditions() -> Array:
    """检查可解锁项"""

func is_decoration_unlocked(decoration_id: String) -> bool:
    """装饰是否已解锁"""

## 季节主题
func get_current_theme() -> String:
    """获取当前季节主题"""

func get_theme_decorations(theme: String) -> Array:
    """获取季节主题装饰"""

## 地形改造
func clear_rock(x: int, y: int) -> bool:
    """移除岩石，开垦新地块"""

func get_terrain_type(x: int, y: int) -> String:
    """获取地形类型"""

## 编辑模式
func enter_edit_mode() -> bool:
    """进入编辑模式"""

func exit_edit_mode() -> bool:
    """退出编辑模式"""

func is_in_edit_mode() -> bool:
    """是否在编辑模式中"""

## 存档
func serialize() -> Dictionary
func deserialize(data: Dictionary)
```

## Formulas

### 1. 可用地块计算

```
available_plots = BASE_PLOTS[map_type] + unlocked_expansion

# BASE_PLOTS = {
#   standard: 600, river: 500, forest: 450,
#   mountain: 550, hillside: 480, desert: 520
# }
```

### 2. 装饰数量限制

```
decorations_count[type] <= MAX_DECORATIONS[type]
# MAX_DECORATIONS = {
#   fence: 50, tree: 30, flower: 40,
#   stone: 20, furniture: 10
# }
```

### 3. 季节主题判定

```
current_theme = SEASON_THEMES[time_system.get_season()]
# SEASON_THEMES = {
#   spring: "spring_theme",
#   summer: "summer_theme",
#   autumn: "autumn_theme",
#   winter: "winter_theme"
# }
```

### 4. 放置位置验证

```
is_valid = not is_in_plot()
        and not is_in_building_area()
        and not is_in_water()
        and not is_decoration_blocked()
```

## Edge Cases

### 1. 装饰边界

- **装饰重叠**: 提示"此处已有装饰"
- **超出数量限制**: 禁用放置按钮
- **位置无效**: 预览变红，无法放置

### 2. 季节边界

- **季节切换时**: 已放置的装饰保持不变
- **装饰与季节冲突**: 季节装饰优先级更高

### 3. 地形边界

- **岩石移除失败**: 提示"此处无法开垦"
- **水域内放置**: 禁止，提示"水域内不可放置"

### 4. 存档边界

- **读取旧存档**: 未定义的装饰使用默认
- **地图类型变更**: 需要重新计算可用格子

## Dependencies

### 上游依赖（P16 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F01** | 时间/季节系统 | 硬依赖 | 季节主题切换 |
| **F02** | 天气系统 | 软依赖 | 天气视觉效果 |
| **C04** | 农场地块系统 | 软依赖 | 可用地块数量 |

### 下游依赖（其他系统依赖 P16）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P01** | 畜牧系统 | 软依赖 | 围栏样式 |
| **C04** | 农场地块系统 | 软依赖 | 地块布局参考 |

## Tuning Knobs

### 地图配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `BASE_PLOTS_STANDARD` | 600 | 400-800 | 标准农场可用格数 |
| `BASE_PLOTS_RIVER` | 500 | 300-700 | 河流农场可用格数 |
| `BASE_PLOTS_FOREST` | 450 | 300-600 | 森林农场可用格数 |
| `BASE_PLOTS_MOUNTAIN` | 550 | 400-750 | 山顶农场可用格数 |
| `BASE_PLOTS_HILLSIDE` | 480 | 350-650 | 山地农场可用格数 |
| `BASE_PLOTS_DESERT` | 520 | 400-700 | 沙漠农场可用格数 |

### 装饰配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `MAX_FENCES` | 50 | 20-100 | 最大栅栏数量 |
| `MAX_TREES` | 30 | 10-50 | 最大树木数量 |
| `MAX_FLOWERS` | 40 | 20-80 | 最大花草数量 |
| `MAX_STONES` | 20 | 10-40 | 最大石头装饰数量 |
| `MAX_FURNITURE` | 10 | 5-20 | 最大户外家具数量 |

### 解锁配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `EXPANSION_COST` | 10000 | 5000-20000 | 额外地块解锁费用 |
| `RIVER_CHANGE_COST` | 25000 | 15000-50000 | 河流调整费用 |
| `UNLOCK_YEAR` | 2 | 1-3 | 年份解锁门槛 |

## Visual/Audio Requirements

### 视觉要求

- **季节主题**: 每个季节有独特的地面色彩和植被
- **装饰预览**: 编辑模式下实时预览放置效果
- **季节过渡**: 平滑的视觉渐变动画

### 音频要求

- **放置音效**: 装饰放置成功时播放轻柔音效
- **删除音效**: 装饰移除时播放确认音
- **季节切换**: 季节变化时播放环境音

## UI Requirements

| 界面 | 组件 | 描述 |
|------|------|------|
| 地图选择界面 | MapSelectView | 开局选择6种地图 |
| 装饰菜单 | DecorationMenu | 分类显示所有装饰 |
| 编辑工具栏 | EditToolbar | 编辑模式工具栏 |
| 解锁进度面板 | UnlockProgressPanel | 显示可解锁项 |

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 6种地图正确加载 | 选择每种地图验证配置 |
| **AC-02** | 装饰放置/删除 | 放置后删除验证 |
| **AC-03** | 位置验证 | 在无效位置尝试放置 |
| **AC-04** | 解锁系统 | 完成条件后验证解锁 |
| **AC-05** | 季节主题切换 | 跨季节验证视觉变化 |
| **AC-06** | 存档/读档 | 保存后读取验证 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | F01 季节变化 | 季节切换时主题更新 |
| **CS-02** | C04 地块系统 | 装饰不影响可用地块 |
| **CS-03** | P01 畜牧围栏 | 畜牧围栏样式集成 |

## Open Questions

| ID | 问题 | Owner | Target Date |
|----|------|-------|-------------|
| **OQ-01** | 地图切换是否需要重新开始？ | 策划 | Pre-MVP |
| **OQ-02** | 是否支持云端备份地图配置？ | 技术 | Post-MVP |
| **OQ-03** | 装饰是否有互动功能（坐椅子）？ | 策划 | Pre-MVP |
