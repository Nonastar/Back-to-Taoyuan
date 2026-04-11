extends Node

## EventBus - 全局事件总线
## 统一管理所有跨系统信号

# ============ 信号定义 ============

## 时间/季节事件
signal time_hour_changed(hour: int)
signal time_changed(day: int, hour: int, minute: int)
signal time_day_changed(day: int, season: String, year: int)
signal time_season_changed(season: String, year: int)
signal time_sleep_triggered(bedtime: int, forced: bool)
signal time_sleep_completed(stamina_recovered: int, hp_restored: int, mode: String)
signal time_paused()
signal time_resumed()
signal year_changed(year: int)

## 玩家属性事件
signal player_stamina_changed(current: int, max: int, delta: int)
signal player_hp_changed(current: int, max: int, delta: int)
signal player_money_changed(current: int, delta: int)
signal player_exhausted()
signal player_low_hp()
signal player_state_changed(state: String)

## 农场交互事件
signal farm_interaction_result(plot_id: String, tool: int, action: String, success: bool, original_state: int)
signal farm_plot_state_changed(plot_id: String, old_state: int, new_state: int)
signal farm_crop_planted(plot_id: String, crop_id: String)
signal farm_crop_harvested(plot_id: String, crop_id: String, quantity: int, quality: int)
signal farm_plot_watered(plot_id: String)
signal farm_message(message: String)
signal farming_exp_changed(skill_type: int, exp: int, leveled_up: bool)

## 库存物品事件
signal inventory_item_added(item_id: String, amount: int, total: int)
signal inventory_item_removed(item_id: String, amount: int, remaining: int)
signal inventory_full(item_id: String)
signal inventory_item_used(item_id: String)
signal item_used(item_id: String)
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)

## 技能系统事件
signal skill_exp_changed(skill_type: int, exp: int, level: int)
signal skill_level_up(skill_type: int, old_level: int, new_level: int)
signal skill_unlocked(skill_type: int)

## UI通知事件
signal ui_notification(message: String, duration: float, priority: int)
signal ui_achievement_unlocked(achievement_id: String)
signal ui_tutorial_triggered(tutorial_id: String)
signal panel_changed(panel_key: String)
signal notification_show(message: String, duration: float)
signal quick_button_pressed(button_id: String)

## 游戏状态事件
signal game_state_changed(from: int, to: int)
signal game_save_started(slot: int)
signal game_save_completed(slot: int, success: bool)
signal game_load_started(slot: int)
signal game_load_completed(slot: int, success: bool)
signal save_started(slot: int)
signal save_completed(slot: int, success: bool)
signal load_started(slot: int)
signal load_completed(slot: int, success: bool)

## 天气事件
signal weather_changed(weather_type: String)

# ============ 调试功能 ============

var _debug_mode: bool = false

func _ready() -> void:
	if _debug_mode:
		push_warning("[EventBus] Initialized")

func enable_debug() -> void:
	_debug_mode = true

func disable_debug() -> void:
	_debug_mode = false
