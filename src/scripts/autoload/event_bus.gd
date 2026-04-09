extends Node

## EventBus - 全局事件总线
## 提供系统间松耦合通信机制
## 参考: ADR-0007 事件/消息系统架构

# ============ 游戏状态事件 ============

## 游戏状态变化 (from: GameState, to: GameState)
signal game_state_changed(from: int, to: int)

# ============ 时间/季节事件 ============

## 游戏小时变化 (hour: int)
signal hour_changed(hour: int)

## 游戏时间变化 (day: int, hour: int, minute: int)
signal time_changed(day: int, hour: int, minute: int)

## 新的一天开始 (day: int, season: String)
signal day_changed(day: int, season: String)

## 季节变化 (season: String, year: int)
signal season_changed(season: String, year: int)

## 年份变化 (year: int)
signal year_changed(year: int)

## 睡眠触发 (bedtime: int, forced: bool)
signal sleep_triggered(bedtime: int, forced: bool)

## 睡眠完成 (recovery_rate: float)
signal sleep_completed(recovery_rate: float)

## 时间暂停
signal time_paused()

## 时间恢复
signal time_resumed()

# ============ 天气事件 ============

## 天气变化 (weather_type: String)
signal weather_changed(weather_type: String)

# ============ 玩家属性事件 ============

## 体力变化 (current: float, max: float)
signal stamina_changed(current: float, max: float)

## 生命值变化 (current: float, max: float)
signal health_changed(current: float, max: float)

## 金钱变化 (amount: int)
signal money_changed(amount: int)

## 经验值变化 (skill: String, exp: int, level: int)
signal experience_gained(skill: String, exp: int, level: int)

## 等级提升 (skill: String, new_level: int)
signal level_up(skill: String, new_level: int)

# ============ 库存事件 ============

## 物品添加 (item_id: String, amount: int)
signal item_added(item_id: String, amount: int)

## 物品移除 (item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)

## 背包已满 (item_id: String)
signal inventory_full(item_id: String)

## 物品使用 (item_id: String)
signal item_used(item_id: String)

# ============ 农场事件 ============

## 地块状态变化 (plot_id: String, state: String)
signal plot_state_changed(plot_id: String, state: String)

## 作物种植 (plot_id: String, crop_id: String)
signal crop_planted(plot_id: String, crop_id: String)

## 作物收获 (plot_id: String, crop_id: String, amount: int)
signal crop_harvested(plot_id: String, crop_id: String, amount: int)

## 浇水完成 (plot_id: String)
signal plot_watered(plot_id: String)

# ============ NPC/社交事件 ============

## NPC好感度变化 (npc_id: String, points: int, total: int)
signal npc_friendship_changed(npc_id: String, points: int, total: int)

## NPC对话开始 (npc_id: String)
signal dialogue_started(npc_id: String)

## NPC对话结束 (npc_id: String, choice_id: String)
signal dialogue_ended(npc_id: String, choice_id: String)

## 礼物送出 (npc_id: String, item_id: String, liked: bool)
signal gift_sent(npc_id: String, item_id: String, liked: bool)

# ============ 技能事件 ============

## 技能解锁 (skill: String)
signal skill_unlocked(skill: String)

## 工具升级 (tool: String, new_level: int)
signal tool_upgraded(tool: String, new_level: int)

## 农耕经验变化 (skill_type: int, exp: int, leveled_up: bool)
signal farming_exp_changed(skill_type: int, exp: int, leveled_up: bool)

## 技能升级 (skill_type: int, old_level: int, new_level: int)
signal skill_level_up(skill_type: int, old_level: int, new_level: int)

# ============ 存档事件 ============

## 保存开始 (slot: int)
signal save_started(slot: int)

## 保存完成 (slot: int, success: bool)
signal save_completed(slot: int, success: bool)

## 加载开始 (slot: int)
signal load_started(slot: int)

## 加载完成 (slot: int, success: bool)
signal load_completed(slot: int, success: bool)

# ============ UI事件 ============

## 提示信息显示 (message: String, duration: float)
signal notification_show(message: String, duration: float)

## 地块消息显示 (message: String)
signal plot_message_received(message: String)

## 成就解锁 (achievement_id: String)
signal achievement_unlocked(achievement_id: String)

## 教程触发 (tutorial_id: String)
signal tutorial_triggered(tutorial_id: String)

# ============ 迷你游戏事件 ============

## 迷你游戏开始 (game_id: String)
signal minigame_started(game_id: String)

## 迷你游戏结束 (game_id: String, score: int, won: bool)
signal minigame_ended(game_id: String, score: int, won: bool)

# ============ 音频事件 ============

## 背景音乐切换 (track: String)
signal bgm_changed(track: String)

## 音效播放请求 (sfx_id: String)
signal sfx_play_requested(sfx_id: String)
