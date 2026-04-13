extends Node

## FishingSystem - 钓鱼系统
## 管理钓鱼小游戏和鱼塘
## 与 M01 FishingMiniGame 交互，提供鱼数据、驱动咬钩事件、接收结果

# ============ 信号 ============

signal fishing_started()
signal fishing_completed(caught: bool, fish_id: String)
signal fish_caught(fish_id: String, quantity: int, quality: int)
signal fishing_cancelled()

# ============ 状态 ============

var _is_fishing: bool = false
var _current_spot_id: String = ""
var _current_fish_id: String = ""
var _current_fish_data: Dictionary = {}
var _current_bait_type: BaitType = BaitType.NONE
var _assist_mode: bool = false

# ============ 钓鱼数据 ============

## 鱼饵类型定义
enum BaitType {
	NONE = 0,      # 无鱼饵
	COMMON = 1,    # 普通饵料
	DELUXE = 2,    # 美味饵料
	LEGENDARY = 3  # 传说饵料
}

## 鱼饵效果配置
const BAIT_EFFECTS: Dictionary = {
	BaitType.NONE: {"name": "无", "bite_bonus": 0.0, "legendary_bonus": 0.0, "item_id": ""},
	BaitType.COMMON: {"name": "普通饵料", "bite_bonus": 0.10, "legendary_bonus": 0.0, "item_id": "bait_common"},
	BaitType.DELUXE: {"name": "美味饵料", "bite_bonus": 0.20, "legendary_bonus": 0.0, "item_id": "bait_deluxe"},
	BaitType.LEGENDARY: {"name": "传说饵料", "bite_bonus": 0.50, "legendary_bonus": 0.10, "item_id": "bait_legendary"}
}

## 鱼类定义数据
## 每种鱼包含：名称、难度(1-10)、稀有度、经验值、价格
const FISH_DATA: Dictionary = {
	## 简单鱼 (难度1-3)
	"bluegill": {"name": "蓝鳃鱼", "rarity": 0.7, "exp": 5, "price": 10, "difficulty": 1},
	"carp": {"name": "鲤鱼", "rarity": 0.5, "exp": 10, "price": 25, "difficulty": 2},
	"frog": {"name": "青蛙", "rarity": 0.5, "exp": 8, "price": 15, "difficulty": 1},
	"koi": {"name": "锦鲤", "rarity": 0.2, "exp": 40, "price": 100, "difficulty": 3},

	## 中等鱼 (难度4-6)
	"catfish": {"name": "鲶鱼", "rarity": 0.3, "exp": 20, "price": 50, "difficulty": 4},
	"trout": {"name": "鳟鱼", "rarity": 0.4, "exp": 15, "price": 30, "difficulty": 4},
	"bass": {"name": "鲈鱼", "rarity": 0.35, "exp": 18, "price": 45, "difficulty": 5},
	"snow_fish": {"name": "雪鱼", "rarity": 0.25, "exp": 35, "price": 80, "difficulty": 5},
	"golden_fish": {"name": "金鱼", "rarity": 0.15, "exp": 50, "price": 150, "difficulty": 5},
	"eel": {"name": "鳗鱼", "rarity": 0.2, "exp": 50, "price": 150, "difficulty": 6},

	## 困难鱼 (难度7-9)
	"salmon": {"name": "三文鱼", "rarity": 0.3, "exp": 25, "price": 60, "difficulty": 7},
	"mountain_trout": {"name": "山鳟", "rarity": 0.2, "exp": 45, "price": 120, "difficulty": 7},
	"ice_fish": {"name": "冰鱼", "rarity": 0.1, "exp": 60, "price": 200, "difficulty": 8},
	"magic_fish": {"name": "魔法鱼", "rarity": 0.1, "exp": 70, "price": 250, "difficulty": 8},
	"swamp_creature": {"name": "沼泽生物", "rarity": 0.25, "exp": 40, "price": 100, "difficulty": 6},

	## 传说鱼 (难度10)
	"tuna": {"name": "金枪鱼", "rarity": 0.15, "exp": 55, "price": 180, "difficulty": 9},
	"swordfish": {"name": "剑鱼", "rarity": 0.08, "exp": 80, "price": 300, "difficulty": 9},
	"shark": {"name": "鲨鱼", "rarity": 0.05, "exp": 100, "price": 500, "difficulty": 10},
	"legendary_fish": {"name": "传说鱼", "rarity": 0.02, "exp": 200, "price": 1000, "difficulty": 10},
	"mythical_fish": {"name": "神话鱼", "rarity": 0.01, "exp": 500, "price": 5000, "difficulty": 10},
	"treasure_fish": {"name": "宝藏鱼", "rarity": 0.03, "exp": 150, "price": 800, "difficulty": 10}
}

## 地点可钓鱼类
const FISH_BY_LOCATION: Dictionary = {
	"fishpond": ["bluegill", "carp", "catfish"],
	"river": ["trout", "salmon", "bass"],
	"forest_pond": ["koi", "golden_fish", "frog"],
	"mountain_lake": ["snow_fish", "ice_fish", "mountain_trout"],
	"ocean": ["tuna", "swordfish", "shark"],
	"witch_swamp": ["eel", "magic_fish", "swamp_creature"],
	"secret_pond": ["legendary_fish", "mythical_fish", "treasure_fish"]
}

# ============ 初始化 ============

func _ready() -> void:
	_connect_signals()
	print("[FishingSystem] Initialized")

func _connect_signals() -> void:
	fishing_started.connect(_on_fishing_started)

## 获取小游戏引用
func _get_mini_game() -> Node:
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		return main.get_node_or_null("UILayer/FishingMiniGame")
	return null

# ============ 公共 API ============

func is_fishing() -> bool:
	return _is_fishing

func get_current_spot_id() -> String:
	return _current_spot_id

func get_current_fish_id() -> String:
	return _current_fish_id

## 开始钓鱼
func start_fishing(spot_id: String) -> void:
	if _is_fishing:
		print("[FishingSystem] Already fishing, ignoring start request")
		return

	## 检查是否有鱼可钓
	var available = get_available_fish(spot_id)
	if available.is_empty():
		push_warning("[FishingSystem] No fish available at spot: " + str(spot_id))
		return

	## 检查并消耗鱼饵
	_current_bait_type = _select_best_bait()
	if _current_bait_type != BaitType.NONE:
		var bait_item_id = BAIT_EFFECTS[_current_bait_type]["item_id"]
		if PlayerStats and PlayerStats.has_method("remove_item"):
			PlayerStats.remove_item(bait_item_id, 1)
			print("[FishingSystem] Used bait: " + str(BAIT_EFFECTS[_current_bait_type]["name"]))

	_is_fishing = true
	_current_spot_id = spot_id

	## 随机选择要钓的鱼
	_current_fish_id = roll_fish(spot_id)
	if _current_fish_id.is_empty():
		push_warning("[FishingSystem] Failed to roll fish")
		_is_fishing = false
		return

	## 构建鱼数据
	_current_fish_data = _build_fish_data(_current_fish_id)
	_current_fish_data["spot_id"] = spot_id

	## 添加鱼饵加成到鱼数据（传递给小游戏）
	var bait_data = get_bait_bonus()
	_current_fish_data["bait_type"] = bait_data["type"]
	_current_fish_data["bait_multiplier"] = 1.0 - bait_data["bite_bonus"]  ## 咬钩率加成转缩短时间
	_current_fish_data["bait_name"] = bait_data["name"]

	## 暂停游戏时间
	if TimeManager and TimeManager.has_method("enter_minigame"):
		TimeManager.enter_minigame()

	## 显示钓鱼小游戏
	_show_fishing_minigame()

	fishing_started.emit()
	print("[FishingSystem] Started fishing at: " + str(spot_id) + ", fish: " + str(_current_fish_id))

## 结束钓鱼
func end_fishing(caught: bool, fish_id: String = "") -> void:
	if not _is_fishing:
		print("[FishingSystem] Not fishing, ignoring end request")
		return

	_is_fishing = false

	## 处理捕获结果
	if caught and not fish_id.is_empty():
		## 计算经验值
		var fish_data = get_fish_data(fish_id)
		var exp = fish_data.get("exp", 10)

		## 添加钓鱼经验
		if SkillSystem and SkillSystem.has_method("add_exp"):
			SkillSystem.add_exp(SkillSystem.SkillType.FISHING, exp)
			print("[FishingSystem] Added " + str(exp) + " fishing exp")

		## 添加鱼到背包
		if PlayerStats and PlayerStats.has_method("add_item"):
			PlayerStats.add_item(fish_id, 1)

		fish_caught.emit(fish_id, 1, 0)
		print("[FishingSystem] Fish caught: " + str(fish_id) + ", exp: " + str(exp))

	## 隐藏钓鱼小游戏
	_hide_fishing_minigame()

	## 恢复游戏时间
	if TimeManager and TimeManager.has_method("exit_minigame"):
		TimeManager.exit_minigame()

	fishing_completed.emit(caught, fish_id)
	print("[FishingSystem] Fishing ended: caught=" + str(caught) + ", fish=" + str(fish_id))

	_current_spot_id = ""
	_current_fish_id = ""
	_current_fish_data = {}
	_current_bait_type = BaitType.NONE
	_assist_mode = false

## 取消钓鱼
func cancel_fishing() -> void:
	if not _is_fishing:
		return

	_is_fishing = false

	## 隐藏钓鱼小游戏
	_hide_fishing_minigame()

	## 恢复游戏时间
	if TimeManager and TimeManager.has_method("exit_minigame"):
		TimeManager.exit_minigame()

	fishing_cancelled.emit()
	print("[FishingSystem] Fishing cancelled")

	_current_spot_id = ""
	_current_fish_id = ""
	_current_fish_data = {}
	_current_bait_type = BaitType.NONE
	_assist_mode = false

## 获取地点可钓鱼类列表
func get_available_fish(spot_id: String) -> Array:
	return FISH_BY_LOCATION.get(spot_id, [])

## 获取钓鱼点信息
func get_fishing_spot_info(spot_id: String) -> Dictionary:
	var fish_list = get_available_fish(spot_id)
	var fish_info = []
	for fish_id in fish_list:
		if FISH_DATA.has(fish_id):
			fish_info.append(get_fish_data(fish_id))

	return {
		"spot_id": spot_id,
		"available_fish": fish_list,
		"fish_data": fish_info
	}

## 获取鱼类数据
func get_fish_data(fish_id: String) -> Dictionary:
	return FISH_DATA.get(fish_id, {})

## 根据稀有度随机抽取鱼
func roll_fish(spot_id: String) -> String:
	var available = get_available_fish(spot_id)
	if available.is_empty():
		return ""

	## 获取鱼饵加成
	var legendary_bonus = 0.0
	if BAIT_EFFECTS.has(_current_bait_type):
		legendary_bonus = BAIT_EFFECTS[_current_bait_type].get("legendary_bonus", 0.0)

	## 按稀有度加权随机
	var rng = RandomNumberGenerator.new()
	var roll = rng.randf()
	var cumulative = 0.0

	for fish_id in available:
		var data = FISH_DATA.get(fish_id, {})
		var rarity = data.get("rarity", 0.5)

		## 传说饵料增加传说鱼概率
		if legendary_bonus > 0 and data.get("difficulty", 0) >= 9:
			rarity += legendary_bonus
			print("[FishingSystem] Legendary bait bonus applied to " + str(fish_id))

		cumulative += rarity
		if roll <= cumulative:
			return fish_id

	## 保底返回第一个
	return available[0] if not available.is_empty() else ""

## 选择最佳鱼饵
func _select_best_bait() -> BaitType:
	## 优先选择传说饵料
	if _has_bait_item(BaitType.LEGENDARY):
		return BaitType.LEGENDARY
	## 其次美味饵料
	if _has_bait_item(BaitType.DELUXE):
		return BaitType.DELUXE
	## 普通饵料
	if _has_bait_item(BaitType.COMMON):
		return BaitType.COMMON
	## 无鱼饵
	return BaitType.NONE

## 检查背包是否有指定鱼饵
func _has_bait_item(bait_type: BaitType) -> bool:
	var item_id = BAIT_EFFECTS.get(bait_type, {}).get("item_id", "")
	if item_id.is_empty():
		return false

	if PlayerStats and PlayerStats.has_method("get_item_count"):
		return PlayerStats.get_item_count(item_id) > 0
	return false

## 获取当前鱼饵类型名称
func get_current_bait_name() -> String:
	return BAIT_EFFECTS.get(_current_bait_type, {}).get("name", "无")

## 获取当前鱼饵加成信息
func get_bait_bonus() -> Dictionary:
	var bait_data = BAIT_EFFECTS.get(_current_bait_type, {})
	return {
		"type": _current_bait_type,
		"name": bait_data.get("name", "无"),
		"bite_bonus": bait_data.get("bite_bonus", 0.0),
		"legendary_bonus": bait_data.get("legendary_bonus", 0.0)
	}

## 获取/设置辅助模式
func is_assist_mode() -> bool:
	return _assist_mode

func set_assist_mode(enabled: bool) -> void:
	_assist_mode = enabled
	print("[FishingSystem] Assist mode: " + str(_assist_mode))

# ============ 内部方法 ============

func _build_fish_data(fish_id: String) -> Dictionary:
	var data = FISH_DATA.get(fish_id, {}).duplicate()
	data["fish_id"] = fish_id
	return data

func _on_fishing_started() -> void:
	_show_fishing_minigame()

func _show_fishing_minigame() -> void:
	var mini_game = _get_mini_game()
	if mini_game and mini_game.has_method("start_minigame"):
		## 连接结果信号
		if not mini_game.fishing_complete.is_connected(_on_fishing_complete):
			mini_game.fishing_complete.connect(_on_fishing_complete)

		mini_game.start_minigame(_current_fish_data, _assist_mode)
		print("[FishingSystem] FishingMiniGame started (assist=" + str(_assist_mode) + ")")
	else:
		push_warning("[FishingSystem] FishingMiniGame not found or invalid")

func _hide_fishing_minigame() -> void:
	var mini_game = _get_mini_game()
	if mini_game and mini_game.has_method("cancel_minigame"):
		mini_game.cancel_minigame()
		print("[FishingSystem] FishingMiniGame hidden")

## 处理小游戏完成结果
func _on_fishing_complete(result: Dictionary) -> void:
	var success = result.get("success", false)
	var fish_id = result.get("fish_id", _current_fish_id)
	var timing_result = result.get("timing_result", "none")

	print("[FishingSystem] Fishing complete: " + str(result))

	end_fishing(success, fish_id)
