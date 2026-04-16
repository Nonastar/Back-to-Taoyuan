# ADR-0015: 玩家交互模式变更 — 点击交互 vs 靠近按键

## Status
Accepted

## Date
2026-04-14

## Context

### 问题背景
Sprint 2 计划实现玩家移动系统 (S2-T1)，原计划使用 **WASD 移动 + 碰撞检测** 的传统 RPG 交互模式。

### 原始设计 (Sprint 2 计划)
```
- WASD / 方向键移动
- 物理碰撞检测
- 4方向移动动画
- E键 / 空格键 交互
```

### 实际实现 (Sprint 2 完成)
```
- 鼠标点击交互模式
- 地块距离检测 (30像素范围)
- 数字键 1-4 切换工具
- 滚轮切换工具
- 无移动动画
```

### 决策驱动因素

| 因素 | 分析 |
|------|------|
| **游戏类型** | 农场模拟经营，类似 Stardew Valley |
| **交互密度** | 高频点击交互 (耕地/播种/浇水/收获) |
| **移动距离** | 有限的游戏区域，不需要快速移动 |
| **开发效率** | 点击模式实现更简单，快速验证核心玩法 |
| **目标用户** |休闲玩家，更习惯点击操作 |

## Decision

### 采用方案：点击交互模式

```gdscript
# src/scripts/entities/player.gd

enum ToolType { HOE, WATERING_CAN, SEEDS, HAND }

var current_tool: ToolType = ToolType.HOE
var is_using_tool: bool = false

func _input(event: InputEvent) -> void:
    # 工具切换 (数字键 1-4)
    if event is InputEventKey and event.pressed:
        var key_index = _get_key_tool_index(event.keycode)
        if key_index >= 0:
            _switch_tool(key_index as ToolType)
            return

    # 鼠标点击交互
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            _handle_click(event.position)

    # 滚轮切换工具
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            _cycle_tool(-1)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            _cycle_tool(1)

func _handle_click(screen_pos: Vector2) -> void:
    if is_using_tool:
        return

    is_using_tool = true
    interaction_attempted.emit(screen_pos)

    # 获取世界坐标
    var world_pos = _screen_to_world(screen_pos)

    # 尝试交互
    var interacted = _try_interact_at(world_pos)

    if interacted:
        # 消耗体力
        var stamina_cost = TOOL_STAMINA_COST.get(current_tool, 0.0)
        # ...

    await get_tree().create_timer(0.15).timeout
    is_using_tool = false
```

### 工具系统

```gdscript
const TOOL_NAMES: Dictionary = {
    ToolType.HOE: "锄头",
    ToolType.WATERING_CAN: "浇水壶",
    ToolType.SEEDS: "种子",
    ToolType.HAND: "手"
}

const TOOL_STAMINA_COST: Dictionary = {
    ToolType.HOE: 5.0,
    ToolType.WATERING_CAN: 3.0,
    ToolType.SEEDS: 2.0,
    ToolType.HAND: 1.0
}
```

### 交互检测

```gdscript
func _try_interact_at(world_pos: Vector2) -> bool:
    var plots: Array = []
    var farm = _find_farm_manager()
    if farm and farm.has_method("get_plots"):
        var all_plots = farm.get_plots()
        for plot in all_plots:
            if plot.has_method("get_center"):
                var plot_center = plot.get_center()
                var dist = world_pos.distance_to(plot_center)
                if dist < 30:  # 30像素交互范围
                    if plot.interact(current_tool, Vector2.ZERO):
                        return true
    return false
```

## Alternatives Considered

### Alternative 1: 传统 WASD + 碰撞检测 (原计划)

| 优点 | 缺点 |
|------|------|
| 经典 RPG 体验 | 实现复杂，需要碰撞层配置 |
| 支持大地图探索 | 频繁交互需要靠近 → 移动 → 交互 |
| 适合战斗系统 | 动画资源需求高 |

**拒绝理由**: 对于高交互频率的农场游戏，每次交互都需要靠近显得繁琐。

### Alternative 2: WASD 移动 + 点击交互 (混合模式)

| 优点 | 缺点 |
|------|------|
| 移动灵活 | 实现复杂度增加 |
| 点击精准 | 需要处理移动与点击的优先级 |

**拒绝理由**: 当前阶段不需要大地图移动，混合模式增加复杂度。

### Alternative 3: 全自动/放置模式

| 优点 | 缺点 |
|------|------|
| 最简单 | 缺乏玩家参与感 |
| | 失去农业游戏的"耕耘"体验 |

**拒绝理由**: 游戏需要有意义的玩家操作。

## Consequences

### Positive
- **快速实现**: 2天内完成核心交互，vs 传统模式预计 3-5 天
- **精准交互**: 点击哪里交互哪里，减少误操作
- **符合类型**: Stardew Valley、牧场物语等同类游戏也使用点击/点击+移动混合
- **降低门槛**: 休闲玩家容易上手

### Negative
- **大地图受限**: 不适合需要频繁大范围移动的场景
- **战斗系统冲突**: 如果未来加入战斗，格斗类操作需要额外设计
- **偏离 ADR-0008**: 原交互系统设计基于碰撞检测，需要更新文档

### Neutral
- **动画需求降低**: 暂时不需要4方向移动动画
- **但保留扩展性**: 如需，可以后续添加 WASD 移动作为可选模式

## Validation Criteria

| # | 标准 | 状态 |
|---|------|------|
| 1 | 玩家可以点击地块进行交互 | ✅ 已实现 |
| 2 | 工具切换响应正确 | ✅ 已实现 |
| 3 | 体力消耗正确 | ✅ 已实现 |
| 4 | 天气修正正确应用 | ✅ 已实现 (2026-04-14 修复) |
| 5 | 错误操作有正确提示 | ✅ 已实现 |

### 天气体力修正 (2026-04-14 修复)

**问题**: 原实现中坏天气反而减少体力消耗，与 GDD 预期相反

**修复内容**:
| 天气 | 修复前 | 修复后 |
|------|--------|--------|
| 雨天 | 90% 消耗 | 115% 消耗 |
| 暴风雨 | 80% 消耗 | 130% 消耗 |
| 雪天 | 70% 消耗 | 150% 消耗 |
| 绿雨 | 90% 消耗 | 110% 消耗 |

**消息提示**: 根据天气类型显示不同的提示消息（🌧️/⛈️/❄️/🌱/💨）

## Future Considerations

### 1. WASD 移动模式
如果未来需要支持更大的游戏区域，可以添加可选的 WASD 移动模式：

```gdscript
# 未来扩展示例
@export var enable_wasd_movement: bool = false

func _physics_process(delta: float) -> void:
    if enable_wasd_movement:
        # 处理 WASD 移动
        pass
```

### 2. 摇杆/手柄支持
移动端或手柄玩家可能需要虚拟摇杆：

```gdscript
# 未来扩展示例
@export var enable_joystick: bool = false
```

### 3. 战斗系统兼容性
如果未来加入战斗系统，需要评估点击模式是否满足需求。

## Related Documents

- ADR-0008: 交互系统架构 (需更新)
- FarmPlot GDD: 农场地块系统 (需更新交互部分)
- Sprint 2 Plan: `production/sprints/sprint-02-core-gameplay.md`

## Record of Changes

| 日期 | 修改人 | 修改内容 |
|------|--------|----------|
| 2026-04-14 | Claude Code | 初始记录设计变更 |
| 2026-04-14 | Claude Code | 修复天气体力修正逻辑（坏天气增加消耗） |
