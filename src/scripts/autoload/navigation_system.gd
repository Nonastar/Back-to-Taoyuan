extends Node

## NavigationSystem - 导航系统
## 管理玩家在游戏世界中的地点切换
## 参考: design/gdd/core/navigation-system.md

# ============ 单例 ============

static func get_instance() -> NavigationSystem:
	return Engine.get_singleton("NavigationSystem")

# ============ 地点组定义 ============

## 地点组
enum LocationGroup {
	FARM = 0,       # 农场区域
	VILLAGE = 1,    # 桃源村
	NATURE = 2,     # 野外区域
	MINE = 3,       # 矿洞
	HANHAI = 4      # 瀚海沙漠
}

## 地点组名称映射
const GROUP_NAMES: Dictionary = {
	LocationGroup.FARM: "农场",
	LocationGroup.VILLAGE: "桃源村",
	LocationGroup.NATURE: "野外",
	LocationGroup.MINE: "矿洞",
	LocationGroup.HANHAI: "瀚海"
}

## 地点组 Emoji
const GROUP_EMOJIS: Dictionary = {
	LocationGroup.FARM: "🏠",
	LocationGroup.VILLAGE: "🏘️",
	LocationGroup.NATURE: "🌲",
	LocationGroup.MINE: "⛏️",
	LocationGroup.HANHAI: "🏜️"
}

## 地点面板定义
const PANELS: Dictionary = {
	# 农场区域 (7个)
	"farm": {"name": "农场", "group": LocationGroup.FARM, "emoji": "🌾"},
	"animal": {"name": "畜棚", "group": LocationGroup.FARM, "emoji": "🐄"},
	"home": {"name": "家中", "group": LocationGroup.FARM, "emoji": "🏠"},
	"cottage": {"name": "小屋", "group": LocationGroup.FARM, "emoji": "🏡"},
	"workshop": {"name": "作坊", "group": LocationGroup.FARM, "emoji": "⚒️"},
	"breeding": {"name": "育种室", "group": LocationGroup.FARM, "emoji": "🌱"},
	"fishpond": {"name": "鱼塘", "group": LocationGroup.FARM, "emoji": "🐟", "scene": "res://src/scenes/interiors/fish_pond.tscn"},

	# 桃源村 (6个)
	"village": {"name": "村落", "group": LocationGroup.VILLAGE, "emoji": "🏘️"},
	"shop": {"name": "商店", "group": LocationGroup.VILLAGE, "emoji": "🛒", "scene": "res://src/scenes/interiors/shop.tscn"},
	"cooking": {"name": "烹饪", "group": LocationGroup.VILLAGE, "emoji": "🍳"},
	"upgrade": {"name": "工坊", "group": LocationGroup.VILLAGE, "emoji": "🔧"},
	"museum": {"name": "博物馆", "group": LocationGroup.VILLAGE, "emoji": "🏛️"},
	"guild": {"name": "公会", "group": LocationGroup.VILLAGE, "emoji": "⚔️"},

	# 野外 (2个)
	"forage": {"name": "采集", "group": LocationGroup.NATURE, "emoji": "🌿"},
	"fishing": {"name": "钓鱼", "group": LocationGroup.NATURE, "emoji": "🎣"},

	# 矿洞 (1个)
	"mining": {"name": "采矿", "group": LocationGroup.MINE, "emoji": "💎"},

	# 瀚海 (1个)
	"hanhai": {"name": "瀚海", "group": LocationGroup.HANHAI, "emoji": "🏜️"}
}

## 无地点面板（暂停游戏）
const NO_LOCATION_PANELS: Array = ["inventory", "skills", "achievement", "charinfo"]

# ============ 旅行时间表 (小时) ============

const TRAVEL_TIME: Dictionary = {
	# farm
	"farm->farm": 0.0, "farm->village": 0.17, "farm->nature": 0.17, "farm->mine": 0.33, "farm->hanhai": 0.5,
	# village
	"village->farm": 0.17, "village->village": 0.0, "village->nature": 0.17, "village->mine": 0.33, "village->hanhai": 0.5,
	# nature
	"nature->farm": 0.17, "nature->village": 0.17, "nature->nature": 0.0, "nature->mine": 0.33, "nature->hanhai": 0.5,
	# mine
	"mine->farm": 0.33, "mine->village": 0.33, "mine->nature": 0.33, "mine->mine": 0.0, "mine->hanhai": 0.5,
	# hanhai
	"hanhai->farm": 0.5, "hanhai->village": 0.5, "hanhai->nature": 0.5, "hanhai->mine": 0.5, "hanhai->hanhai": 0.0
}

## 旅行体力消耗表
const TRAVEL_STAMINA: Dictionary = {
	# farm
	"farm->farm": 0, "farm->village": 1, "farm->nature": 1, "farm->mine": 2, "farm->hanhai": 3,
	# village
	"village->farm": 1, "village->village": 0, "village->nature": 1, "village->mine": 2, "village->hanhai": 3,
	# nature
	"nature->farm": 1, "nature->village": 1, "nature->nature": 0, "nature->mine": 2, "nature->hanhai": 3,
	# mine
	"mine->farm": 2, "mine->village": 2, "mine->nature": 2, "mine->mine": 0, "mine->hanhai": 3,
	# hanhai
	"hanhai->farm": 3, "hanhai->village": 3, "hanhai->nature": 3, "hanhai->mine": 3, "hanhai->hanhai": 0
}

# ============ 当前状态 ============

## 当前所在地点
var current_panel: String = "farm":
	set(value):
		var old_group = current_group
		current_panel = value
		current_group = _get_panel_group(value)
		if current_group != old_group:
			location_changed.emit(current_group, old_group)

## 当前所在组
var current_group: int = LocationGroup.FARM

## 游戏是否暂停（无地点面板时）
var is_paused: bool = false

## 马匹拥有状态
var has_horse: bool = false

## 速度加成百分比 (0.0 - 1.0)
var speed_buff: float = 0.0

## 旅行速度加成 (0.0 - 1.0)
var travel_speed_bonus: float = 0.0

# ============ 信号 ============

## 地点变化信号
signal location_changed(new_group: int, old_group: int)

## 旅行开始信号
signal travel_started(time_cost: float, stamina_cost: int)

## 旅行完成信号
signal travel_completed(panel_key: String)

## 商店拒绝访问信号
signal shop_access_denied(panel_key: String, reason: String)

## 就寝时间信号
signal past_bedtime()

# ============ 初始化 ============

func _ready() -> void:
	current_panel = "farm"
	current_group = LocationGroup.FARM
	push_warning("[NavigationSystem] Initialized at farm")

## 获取面板所属组
func _get_panel_group(panel_key: String) -> int:
	var panel_info = PANELS.get(panel_key, null)
	if panel_info:
		return panel_info["group"]
	# 无地点面板默认归为 FARM
	return LocationGroup.FARM

# ============ 公共 API ============

## 获取当前地点组名称
func get_current_group_name() -> String:
	return GROUP_NAMES.get(current_group, "未知")

## 获取当前地点组 Emoji
func get_current_group_emoji() -> String:
	return GROUP_EMOJIS.get(current_group, "🏠")

## 获取当前面板名称
func get_current_panel_name() -> String:
	var panel_info = PANELS.get(current_panel, null)
	if panel_info:
		return panel_info["name"]
	return "未知"

## 获取当前面板 Emoji
func get_current_panel_emoji() -> String:
	var panel_info = PANELS.get(current_panel, null)
	if panel_info:
		return panel_info["emoji"]
	return "🏠"

## 获取当前地点组名称（公开 API）
func get_current_location_group() -> String:
	return get_current_group_name()

## 检查面板是否可访问
func is_panel_accessible(panel_key: String) -> Dictionary:
	# 检查商店营业时间
	var shop_check = _check_shop_hours(panel_key)
	if not shop_check["accessible"]:
		return {"accessible": false, "reason": shop_check["reason"]}

	# 检查就寝时间
	if TimeManager and TimeManager.current_hour >= 26:
		return {"accessible": false, "reason": "已经深夜，无法出行"}

	# 检查体力
	var cost = get_travel_cost(panel_key)
	if cost["stamina_cost"] > 0 and PlayerStats:
		if PlayerStats.stamina < cost["stamina_cost"]:
			return {"accessible": false, "reason": "体力不足"}

	return {"accessible": true}

## 获取旅行消耗
func get_travel_cost(target_panel: String) -> Dictionary:
	# 如果是无地点面板，不消耗
	if target_panel in NO_LOCATION_PANELS:
		return {"time_cost": 0.0, "stamina_cost": 0, "is_travel": false}

	# 获取目标组
	var target_group = _get_panel_group(target_panel)
	var target_group_name = _get_group_name(target_group)
	var current_group_name = _get_group_name(current_group)

	# 同组切换无消耗
	if target_group == current_group:
		return {"time_cost": 0.0, "stamina_cost": 0, "is_travel": false}

	# 获取基础消耗
	var time_key = "%s->%s" % [current_group_name.to_lower(), target_group_name.to_lower()]
	var stamina_key = time_key

	var base_time = TRAVEL_TIME.get(time_key, 0.0)
	var base_stamina = TRAVEL_STAMINA.get(stamina_key, 0)

	# 应用加成
	var final_time = _apply_time_multipliers(base_time)
	var final_stamina = _apply_stamina_multipliers(base_stamina)

	return {
		"time_cost": final_time,
		"stamina_cost": final_stamina,
		"is_travel": true
	}

## 获取组名称（内部）
func _get_group_name(group: int) -> String:
	match group:
		LocationGroup.FARM: return "farm"
		LocationGroup.VILLAGE: return "village"
		LocationGroup.NATURE: return "nature"
		LocationGroup.MINE: return "mine"
		LocationGroup.HANHAI: return "hanhai"
		_: return "farm"

## 应用时间加成
func _apply_time_multipliers(base_time: float) -> float:
	var result = base_time

	# 马匹加成
	if has_horse:
		result *= 0.7

	# 速度加成
	if speed_buff > 0:
		result *= (1.0 - speed_buff)

	# 旅行速度加成（戒指等）
	if travel_speed_bonus > 0:
		result *= (1.0 - travel_speed_bonus)

	return result

## 应用体力加成
func _apply_stamina_multipliers(base_stamina: int) -> int:
	var result = base_stamina

	# 马匹体力减半
	if has_horse and result > 0:
		result = maxi(1, result / 2)

	return result

## 导航到目标面板
func navigate_to_panel(panel_key: String) -> Dictionary:
	# 检查是否为无地点面板
	if panel_key in NO_LOCATION_PANELS:
		is_paused = true
		current_panel = panel_key
		EventBus.panel_changed.emit(panel_key)
		return {"success": true, "message": "打开%s" % panel_key}

	# 获取旅行消耗
	var cost = get_travel_cost(panel_key)

	# 检查商店营业时间
	var shop_check = _check_shop_hours(panel_key)
	if not shop_check["accessible"]:
		shop_access_denied.emit(panel_key, shop_check["reason"])
		return {
			"success": false,
			"reason": shop_check["reason"],
			"shop_closed": true
		}

	# 检查就寝时间
	if TimeManager and TimeManager.current_hour >= 26:
		past_bedtime.emit()
		return {"success": false, "reason": "已经深夜，无法出行", "passed_out": true}

	# 检查体力
	if cost["stamina_cost"] > 0 and PlayerStats:
		if PlayerStats.stamina < cost["stamina_cost"]:
			return {"success": false, "reason": "体力不足"}

	# 执行旅行
	if cost["is_travel"]:
		# 消耗体力
		if cost["stamina_cost"] > 0 and PlayerStats:
			PlayerStats.consume_stamina(cost["stamina_cost"])

		# 推进时间
		if cost["time_cost"] > 0 and TimeManager:
			var minutes = int(cost["time_cost"] * 60)
			TimeManager.advance_minutes(minutes)

		travel_started.emit(cost["time_cost"], cost["stamina_cost"])

	# 更新当前面板
	current_panel = panel_key
	is_paused = false

	travel_completed.emit(panel_key)
	EventBus.panel_changed.emit(panel_key)

	var panel_name = PANELS.get(panel_key, {}).get("name", panel_key)
	return {
		"success": true,
		"time_cost": cost["time_cost"],
		"stamina_cost": cost["stamina_cost"],
		"message": "前往%s" % panel_name
	}

## 检查商店营业时间
func _check_shop_hours(panel_key: String) -> Dictionary:
	var panel_info = PANELS.get(panel_key, null)
	if not panel_info:
		return {"accessible": true}

	# 商店开门时间
	var open_hour = 6
	var close_hour = 24

	# 工坊特殊时间
	if panel_key == "upgrade":
		open_hour = 8
		close_hour = 20

	# 检查当前时间
	if TimeManager:
		var hour = TimeManager.current_hour
		if hour < open_hour:
			return {"accessible": false, "reason": "尚未开门 (%d:00营业)" % open_hour}
		if hour >= close_hour:
			return {"accessible": false, "reason": "已经打烊 (%d:00关门)" % close_hour}

	return {"accessible": true}

## 是否可以前往目标面板
func can_navigate_to(panel_key: String) -> bool:
	# 检查商店营业时间
	var shop_check = _check_shop_hours(panel_key)
	if not shop_check["accessible"]:
		return false

	# 检查就寝时间
	if TimeManager and TimeManager.current_hour >= 26:
		return false

	# 检查体力
	var cost = get_travel_cost(panel_key)
	if cost["stamina_cost"] > 0 and PlayerStats:
		if PlayerStats.stamina < cost["stamina_cost"]:
			return false

	return true

## 获取可访问的面板列表
func get_accessible_panels() -> Array:
	var result = []
	for panel_key in PANELS:
		if can_navigate_to(panel_key):
			result.append(panel_key)
	return result

## 获取面板场景路径
func get_panel_scene(panel_key: String) -> String:
	var panel_info = PANELS.get(panel_key, null)
	if panel_info and panel_info.has("scene"):
		return panel_info["scene"]
	return ""

## 获取面板完整信息
func get_panel_info(panel_key: String) -> Dictionary:
	return PANELS.get(panel_key, {})

## 获取当前组的所有面板
func get_panels_in_current_group() -> Array:
	var result = []
	var group = current_group
	for panel_key in PANELS:
		var panel_info = PANELS[panel_key]
		if panel_info["group"] == group:
			result.append(panel_key)
	return result

## 设置马匹拥有状态
func set_has_horse(value: bool) -> void:
	has_horse = value

## 设置速度加成
func set_speed_buff(value: float) -> void:
	speed_buff = clamp(value, 0.0, 1.0)

## 设置旅行速度加成
func set_travel_speed_bonus(value: float) -> void:
	travel_speed_bonus = clamp(value, 0.0, 1.0)

## 返回农场（用于昏厥等强制传送）
func return_to_farm() -> void:
	current_panel = "farm"
	current_group = LocationGroup.FARM
	is_paused = false
	location_changed.emit(current_group, LocationGroup.FARM)
	EventBus.panel_changed.emit("farm")
	push_warning("[NavigationSystem] Returned to farm")

# ============ 存档支持 ============

func get_save_data() -> Dictionary:
	return {
		"current_panel": current_panel,
		"current_group": current_group,
		"has_horse": has_horse
	}

func load_save_data(data: Dictionary) -> void:
	current_panel = data.get("current_panel", "farm")
	current_group = data.get("current_group", LocationGroup.FARM)
	has_horse = data.get("has_horse", false)
	is_paused = false
	push_warning("[NavigationSystem] Loaded: panel=%s, group=%s" % [current_panel, GROUP_NAMES[current_group]])
