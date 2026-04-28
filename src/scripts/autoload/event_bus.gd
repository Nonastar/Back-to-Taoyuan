extends Node

## EventBus - 全局事件总线
## 统一管理所有跨系统信号

# ============ 信号定义 ============
# 信号由其他类 emit/connect，非本类内使用 — 禁用 UNUSED_SIGNAL 警告

## 时间/季节事件
@warning_ignore("unused_signal")
signal time_hour_changed(hour: int)
@warning_ignore("unused_signal")
signal time_changed(day: int, hour: int, minute: int)
@warning_ignore("unused_signal")
signal time_day_changed(day: int, season: String, year: int)
@warning_ignore("unused_signal")
signal time_season_changed(season: String, year: int)
@warning_ignore("unused_signal")
signal time_sleep_triggered(bedtime: int, forced: bool)
@warning_ignore("unused_signal")
signal time_paused()
@warning_ignore("unused_signal")
signal time_resumed()
@warning_ignore("unused_signal")
signal year_changed(year: int)

## 玩家属性事件
@warning_ignore("unused_signal")
signal player_money_changed(current: int, delta: int)

## 农场交互事件
@warning_ignore("unused_signal")
signal farm_interaction_result(plot_id: String, tool: int, action: String, success: bool, original_state: int)
@warning_ignore("unused_signal")
signal farm_crop_harvested(plot_id: String, crop_id: String, quantity: int, quality: int)
@warning_ignore("unused_signal")
signal farm_message(message: String)
@warning_ignore("unused_signal")
signal farming_exp_changed(skill_type: int, exp: int, leveled_up: bool)

## 库存物品事件
@warning_ignore("unused_signal")
signal inventory_full(item_id: String)
@warning_ignore("unused_signal")
signal item_used(item_id: String)
@warning_ignore("unused_signal")
signal item_added(item_id: String, amount: int)
@warning_ignore("unused_signal")
signal item_removed(item_id: String, amount: int)

## 技能系统事件
@warning_ignore("unused_signal")
signal skill_level_up(skill_type: int, old_level: int, new_level: int)

## UI通知事件
## type: 0=GAIN, 1=COST, 2=SUCCESS, 3=WARNING, 4=ERROR, 5=SYSTEM
@warning_ignore("unused_signal")
signal ui_achievement_unlocked(achievement_id: String)
@warning_ignore("unused_signal")
signal panel_changed(panel_key: String)
@warning_ignore("unused_signal")
signal quick_button_pressed(button_id: String)

## 飘窗通知事件（GDD标准信号）
## notification_requested(text, type, priority, duration, id, icon_path)
@warning_ignore("unused_signal")
signal notification_requested(text: String, type: int, priority: int, duration: float, id: String, icon_path: String)

## 场景/UI 暂停恢复事件
@warning_ignore("unused_signal")
signal pause_requested()
@warning_ignore("unused_signal")
signal resume_requested()

## 游戏状态事件
@warning_ignore("unused_signal")
signal game_state_changed(from: int, to: int)
@warning_ignore("unused_signal")
signal save_started(slot: int)
@warning_ignore("unused_signal")
signal save_completed(slot: int, success: bool)
@warning_ignore("unused_signal")
signal load_started(slot: int)
@warning_ignore("unused_signal")
signal load_completed(slot: int, success: bool)

## 天气事件
@warning_ignore("unused_signal")
signal weather_changed(weather_type: String)

## NPC好感度事件
@warning_ignore("unused_signal")
signal npc_talked(npc_id: String, gain: int)
@warning_ignore("unused_signal")
signal friendship_changed(npc_id: String, old_value: int, new_value: int)

## 烹饪/加工事件
@warning_ignore("unused_signal")
signal cooking_completed(recipe_id: String)

## 钓鱼事件
@warning_ignore("unused_signal")
signal fishing_started()
@warning_ignore("unused_signal")
signal fishing_completed(caught: bool, fish_id: String)
@warning_ignore("unused_signal")
signal fish_caught(fish_id: String, quantity: int, quality: int)
@warning_ignore("unused_signal")
signal fishing_cancelled()
@warning_ignore("unused_signal")
signal fishing_minigame_requested(fish_data: Dictionary, assist_mode: bool)
@warning_ignore("unused_signal")
signal fishing_minigame_cancelled()

# ============ 调试功能 ============

var _debug_mode: bool = false

func _ready() -> void:
	if _debug_mode:
		print("[EventBus] Initialized")

func enable_debug() -> void:
	_debug_mode = true

func disable_debug() -> void:
	_debug_mode = false
