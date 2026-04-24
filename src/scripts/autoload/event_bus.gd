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
## type: 0=GAIN, 1=COST, 2=SUCCESS, 3=WARNING, 4=ERROR, 5=SYSTEM
signal ui_notification(message: String, duration: float, priority: int, type: int, id: String)
signal ui_achievement_unlocked(achievement_id: String)
signal ui_tutorial_triggered(tutorial_id: String)
signal panel_changed(panel_key: String)
signal quick_button_pressed(button_id: String)

## 飘窗通知事件（GDD标准信号）
## notification_requested(text, type, priority, duration, id, icon_path)
## type: 0=GAIN, 1=COST, 2=SUCCESS, 3=WARNING, 4=ERROR, 5=SYSTEM
signal notification_requested(text: String, type: int, priority: int, duration: float, id: String, icon_path: String)

## 场景/UI 暂停恢复事件
signal pause_requested()    # 进入全屏UI/菜单时发送，飘窗队列暂停
signal resume_requested()   # 退出全屏UI/菜单时发送，飘窗队列恢复

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

## NPC好感度事件
signal npc_talked(npc_id: String, gain: int)
signal npc_gifted(npc_id: String, item_id: String, gain: int, reaction: String)
signal friendship_changed(npc_id: String, old_value: int, new_value: int)
signal heart_event_triggered(npc_id: String, event_id: String)

## 烹饪/加工事件
signal cooking_completed(recipe_id: String)
signal processing_completed(output_item_id: String)

## 采矿/探索事件
signal mine_floor_reached(floor: int)

## 钓鱼事件
signal fishing_started()
signal fishing_completed(caught: bool, fish_id: String)
signal fish_caught(fish_id: String, quantity: int, quality: int)
signal fishing_cancelled()
signal fishing_minigame_requested(fish_data: Dictionary, assist_mode: bool)
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
