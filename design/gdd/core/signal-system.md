# 信号管理系统 (Signal System)

> **状态**: Designed
> **Author**: Claude Code
> **Last Updated**: 2026-04-10
> **System ID**: ADR-0007 (Revised)
> **Implements Pillar**: 基础设施 - 系统间通信

## Overview

信号管理系统是游戏各系统间松耦合通信的统一机制。所有跨系统事件通过全局 EventBus 单例分发，确保系统间无直接引用依赖。

## 信号分类

| 分类 | 前缀 | 示例 |
|------|------|------|
| 时间/季节 | `time_` | time_hour_changed, time_day_changed |
| 玩家属性 | `player_` | player_stamina_changed, player_hp_changed |
| 农场交互 | `farm_` | farm_interaction_result, farm_crop_harvested |
| 库存物品 | `inventory_` | inventory_item_added, inventory_item_removed |
| 技能系统 | `skill_` | skill_exp_changed, skill_level_up |
| UI通知 | `ui_` | ui_notification, ui_achievement_unlocked |
| 游戏状态 | `game_` | game_save_completed, game_state_changed |

## 核心信号

### farm_interaction_result

农场交互结果信号，用于解耦农场操作和体力消耗：

```gdscript
# 参数
# plot_id: String - 地块名称
# tool: int - 工具类型 (0=HOE, 1=WATER, 2=SEEDS, 3=HAND)
# action: String - "till"|"water"|"plant"|"harvest"
# success: bool - 交互是否成功
# original_state: int - FarmPlot.PlotState 枚举值
signal farm_interaction_result(plot_id: String, tool: int, action: String, success: bool, original_state: int)
```

### 体力消耗逻辑

```gdscript
func _should_consume_stamina(action: String, original_state: int) -> bool:
	match action:
		"till": return original_state == 0  # WASTELAND
		"water": return original_state in [2, 3]  # PLANTED, GROWING
		"plant": return original_state == 1  # TILLED
		"harvest": return original_state == 4  # HARVESTABLE
	return false

func _get_stamina_cost_for_action(action: String) -> int:
	match action:
		"till": return 5
		"water": return 3
		"plant": return 2
		"harvest": return 1
	return 0
```

## 睡眠恢复逻辑

```gdscript
func daily_reset(bed_hour: int = 24, forced: bool = false) -> Dictionary:
	# forced = true: 体力耗尽昏厥，恢复50%
	# forced = false: 正常就寝/自动跨天 (6-26时恢复90%)
```

## 完整信号列表

见 EventBus.gd 的 SIGNAL_METADATA 常量。

## 依赖关系

| 系统 | 发出信号 | 监听信号 |
|------|----------|----------|
| Player | farm_interaction_result | - |
| PlayerStats | player_stamina_changed | farm_interaction_result, time_sleep_triggered |
| TimeManager | time_day_changed, time_sleep_triggered | - |
| FarmManager | farm_interaction_result, farm_crop_harvested | time_sleep_triggered |
| FarmPlot | farming_exp_changed | - |
| SkillSystem | skill_level_up | - |

## 注意事项

1. 所有信号使用强类型参数
2. 信号命名遵循 `[category]_[verb]_past_tense` 模式
3. 使用 `has_signal()` 检查信号存在
4. 回调函数参数必须与信号参数匹配
