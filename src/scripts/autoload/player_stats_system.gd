extends Node

## PlayerStatsSystem - 玩家属性系统
## 负责管理玩家HP、体力、金钱等基础属性
## 参考: C01 玩家属性系统 GDD

# ============ 常量 ============

## 体力上限档位 [0-4]
const STAMINA_CAPS: Array[int] = [120, 160, 200, 250, 300]

## 体力耗尽阈值
const EXHAUSTED_THRESHOLD: int = 5

## 基础最大HP
const BASE_MAX_HP: int = 100

## 每级战斗等级HP加成
const HP_PER_COMBAT_LEVEL: int = 5

## Fighter专精HP加成
const FIGHTER_HP_BONUS: int = 25

## Warrior专精HP加成
const WARRIOR_HP_BONUS: int = 40

## 低HP警告阈值
const LOW_HP_THRESHOLD: float = 0.25

## 开局金钱
const STARTING_MONEY: int = 500

## 晚睡就寝最大恢复率 (24时)
const LATE_NIGHT_RECOVERY_MAX: float = 0.9

## 晚睡就寝最小恢复率 (25时)
const LATE_NIGHT_RECOVERY_MIN: float = 0.6

## 昏厥后体力恢复率
const PASSOUT_STAMINA_RECOVERY: float = 0.5

## 昏厥扣钱比例
const PASSOUT_MONEY_PENALTY_RATE: float = 0.1

## 昏厥扣钱上限
const PASSOUT_MONEY_PENALTY_CAP: int = 1000

# ============ 玩家身份 ============

## 玩家名称
var player_name: String = "农夫"

## 性别 (male/female)
var gender: String = "male"

## 获取敬称
func get_honorific() -> String:
	if gender == "female":
		return "姑娘"
	return "小哥"

# ============ 体力属性 ============

## 当前体力值
var stamina: int = STAMINA_CAPS[0]

## 体力上限等级 (0-4)
var stamina_cap_level: int = 0

## 额外体力上限 (道具加成)
var bonus_max_stamina: int = 0

## 仙缘体力减免 (0.0-1.0)
var spirit_shield_stamina_save: float = 0.0

# ============ HP属性 ============

## 当前HP
var current_hp: int = BASE_MAX_HP

## 战斗等级
var combat_level: int = 1

## Fighter专精激活
var has_fighter_perk: bool = false

## Warrior专精激活
var has_warrior_perk: bool = false

## 戒指HP加成
var ring_hp_bonus: int = 0

## 仙缘HP加成
var spirit_shield_hp_bonus: int = 0

## 公会HP加成
var guild_hp_bonus: int = 0

## 房屋HP加成
var house_hp_bonus: int = 0

## 房屋体力恢复加成
var house_stamina_bonus: float = 0.0

# ============ 金钱属性 ============

## 当前金钱
var money: int = STARTING_MONEY

# ============ 状态 ============

## 是否已初始化
var _initialized: bool = false

# ============ 信号 ============

## 体力变化信号
signal stamina_changed(current: int, max: int)

## HP变化信号
signal hp_changed(current: int, max: int)

## 金钱变化信号
signal money_changed(amount: int)

## 体力耗尽信号
signal exhausted()

## 低HP警告信号
signal low_hp_warning()

## 玩家状态变化信号 (normal/exhausted/low_hp/pass_out)
signal state_changed(state: String)

## 每日结算完成信号
signal daily_reset_completed(result: Dictionary)

# ============ 生命周期 ============

func _ready() -> void:
	_initialize()
	_connect_signals()

## 初始化
func _initialize() -> void:
	if _initialized:
		return

	# 从配置读取初始值
	var config = ConfigManager.get_config("player")
	if config != null:
		_apply_config(config)

	_initialized = true

## 连接信号
func _connect_signals() -> void:
	# 监听睡眠触发信号
	if EventBus.has_signal("time_sleep_triggered"):
		EventBus.time_sleep_triggered.connect(_on_sleep_triggered)

	# 监听农场交互信号
	if EventBus.has_signal("farm_interaction_result"):
		EventBus.farm_interaction_result.connect(_on_farm_interaction)

# ============ 配置应用 ============

## 应用配置
func apply_config(config: PlayerConfig) -> void:
	if config == null:
		push_error("[PlayerStats] Cannot apply null config")
		return

	# 体力配置
	stamina = int(config.max_stamina)
	bonus_max_stamina = 0  # 道具加成不通过配置设置

	# HP配置
	current_hp = int(config.max_health)

	# 金钱配置
	money = config.initial_money

	push_warning("[PlayerStats] Config applied: max_stamina=%d, max_hp=%d" % [get_max_stamina(), get_max_hp()])

## 应用配置 (内部)
func _apply_config(config: PlayerConfig) -> void:
	# 体力初始化为满
	stamina = get_max_stamina()
	if config.max_health > 0:
		current_hp = int(config.max_health)
	else:
		current_hp = BASE_MAX_HP
	money = config.initial_money

# ============ 属性查询 ============

## 获取当前体力上限
func get_max_stamina() -> int:
	return STAMINA_CAPS[stamina_cap_level] + bonus_max_stamina

## 获取当前体力值
func get_current_stamina() -> int:
	return stamina

## 获取体力百分比 (0-100)
func get_stamina_percent() -> float:
	var max_s = get_max_stamina()
	if max_s <= 0:
		return 0.0
	return round(stamina / float(max_s) * 100.0)

## 获取当前最大HP (含所有加成)
func get_max_hp() -> int:
	var max_hp = BASE_MAX_HP
	max_hp += (combat_level - 1) * HP_PER_COMBAT_LEVEL  # 战斗等级加成

	if has_fighter_perk:
		max_hp += FIGHTER_HP_BONUS
	if has_warrior_perk:
		max_hp += WARRIOR_HP_BONUS

	max_hp += ring_hp_bonus
	max_hp += spirit_shield_hp_bonus
	max_hp += guild_hp_bonus
	max_hp += house_hp_bonus

	return max_hp

## 获取当前HP
func get_current_hp() -> int:
	return current_hp

## 获取HP百分比
func get_hp_percent() -> float:
	var max_hp = get_max_hp()
	if max_hp <= 0:
		return 0.0
	return round(current_hp / float(max_hp) * 100.0)

## 获取当前金钱
func get_money() -> int:
	return money

## 获取玩家名称
func get_player_name() -> String:
	return player_name

## 获取体力上限等级
func get_stamina_cap_level() -> int:
	return stamina_cap_level

## 获取额外体力上限
func get_bonus_max_stamina() -> int:
	return bonus_max_stamina

# ============ 体力操作 ============

## 消耗体力
func consume_stamina(amount: int) -> bool:
	if amount <= 0:
		return true

	# 计算有效消耗 (仙缘减免)
	var effective_amount = amount
	if spirit_shield_stamina_save > 0:
		effective_amount = int(effective_amount * (1.0 - spirit_shield_stamina_save))

	# 最小消耗为1
	effective_amount = maxi(1, effective_amount)

	# 检查天气修正 (如果有WeatherSystem)
	var weather_modifier = _get_weather_stamina_modifier()
	effective_amount = int(ceil(effective_amount * weather_modifier))

	# 消耗体力
	stamina -= effective_amount
	stamina = maxi(0, stamina)

	_emit_stamina_changed()
	_check_stamina_state()

	return stamina > EXHAUSTED_THRESHOLD or stamina >= amount

## 恢复体力
func restore_stamina(amount: int) -> void:
	if amount <= 0:
		return

	stamina += amount
	var max_s = get_max_stamina()
	stamina = mini(stamina, max_s)

	_emit_stamina_changed()
	_check_stamina_state()

## 提升体力上限等级
func upgrade_max_stamina() -> bool:
	if stamina_cap_level >= STAMINA_CAPS.size() - 1:
		push_warning("[PlayerStats] Max stamina level already reached")
		return false

	stamina_cap_level += 1

	# 恢复因升级损失的体力
	var old_cap = STAMINA_CAPS[stamina_cap_level - 1]
	var new_cap = STAMINA_CAPS[stamina_cap_level]
	var recovered = new_cap - old_cap
	stamina = mini(stamina + recovered, new_cap + bonus_max_stamina)

	_emit_stamina_changed()
	return true

## 添加额外体力上限
func add_bonus_max_stamina(amount: int) -> void:
	bonus_max_stamina += amount
	_emit_stamina_changed()

## 设置仙缘体力减免
func set_spirit_shield_stamina_save(value: float) -> void:
	spirit_shield_stamina_save = clamp(value, 0.0, 1.0)

# ============ HP操作 ============

## 受到伤害
func take_damage(amount: int) -> int:
	if amount <= 0:
		return 0

	var actual_damage = mini(amount, current_hp)
	current_hp -= actual_damage
	current_hp = maxi(0, current_hp)

	_emit_hp_changed()
	_check_hp_state()

	return actual_damage

## 恢复HP
func restore_health(amount: int) -> void:
	if amount <= 0:
		return

	current_hp += amount
	var max_hp = get_max_hp()
	current_hp = mini(current_hp, max_hp)

	_emit_hp_changed()
	_check_hp_state()

## 设置战斗等级
func set_combat_level(level: int) -> void:
	combat_level = maxi(1, level)
	_emit_hp_changed()

## 设置Fighter专精
func set_fighter_perk(active: bool) -> void:
	has_fighter_perk = active
	_emit_hp_changed()

## 设置Warrior专精
func set_warrior_perk(active: bool) -> void:
	has_warrior_perk = active
	_emit_hp_changed()

## 设置戒指HP加成
func set_ring_hp_bonus(amount: int) -> void:
	ring_hp_bonus = amount
	_emit_hp_changed()

## 设置仙缘HP加成
func set_spirit_shield_hp_bonus(amount: int) -> void:
	spirit_shield_hp_bonus = amount
	_emit_hp_changed()

## 设置公会HP加成
func set_guild_hp_bonus(amount: int) -> void:
	guild_hp_bonus = amount
	_emit_hp_changed()

## 设置房屋加成
func set_house_bonus(hp_bonus: int, stamina_bonus: float) -> void:
	house_hp_bonus = hp_bonus
	house_stamina_bonus = stamina_bonus

# ============ 金钱操作 ============

## 花费金钱
func spend_money(amount: int) -> bool:
	if amount <= 0:
		return true

	if money < amount:
		push_warning("[PlayerStats] Not enough money: have %d, need %d" % [money, amount])
		return false

	money -= amount
	_emit_money_changed()
	return true

## 获得金钱
func earn_money(amount: int) -> void:
	if amount <= 0:
		return

	money += amount
	_emit_money_changed()

	# 触发成就检查
	if EventBus.has_signal("money_earned"):
		EventBus.money_earned.emit(money)

## 设置金钱 (用于调试)
func set_money(amount: int) -> void:
	money = maxi(0, amount)
	_emit_money_changed()

# ============ 玩家身份 ============

## 设置玩家名称
func set_player_name(name: String) -> void:
	player_name = name

## 设置性别
func set_gender(g: String) -> void:
	gender = g

# ============ 每日结算 ============

## 每日重置
## forced 参数表示是否强制（体力耗尽昏厥）
func daily_reset(bed_hour: int = 24, forced: bool = false) -> Dictionary:
	var sleep_info = _calculate_sleep_recovery(bed_hour, forced)

	# 计算恢复量
	var max_s = get_max_stamina()
	var recovered = int(max_s * sleep_info.recovery_pct)

	# 加上房屋加成
	if house_stamina_bonus > 0:
		recovered = mini(recovered + int(max_s * house_stamina_bonus), max_s)

	# 恢复体力（累加而非替换，上限为最大体力）
	stamina = mini(stamina + recovered, max_s)

	# 恢复HP
	current_hp = get_max_hp()

	# 扣钱
	if sleep_info.money_lost > 0:
		_emit_money_changed()

	# 发送信号
	var result = {
		"mode": sleep_info.mode,
		"recovery_pct": sleep_info.recovery_pct,
		"money_lost": sleep_info.money_lost,
		"stamina_recovered": stamina,
		"hp_restored": current_hp
	}

	_emit_stamina_changed()
	_emit_hp_changed()
	daily_reset_completed.emit(result)

	return result

## 计算睡眠恢复信息
class SleepInfo:
	var mode: String
	var recovery_pct: float
	var money_lost: int

func _calculate_sleep_recovery(bed_hour: int, forced: bool) -> SleepInfo:
	var info = SleepInfo.new()

	# 确定就寝模式
	if forced:
		info.mode = "passout"
		info.recovery_pct = PASSOUT_STAMINA_RECOVERY
		info.money_lost = mini(int(floor(money * PASSOUT_MONEY_PENALTY_RATE)), PASSOUT_MONEY_PENALTY_CAP)
		money -= info.money_lost
	elif bed_hour >= 6 and bed_hour <= 26:
		info.mode = "normal"
		info.recovery_pct = 0.9
		info.money_lost = 0
	elif bed_hour > 26:
		info.mode = "late"
		info.recovery_pct = 0.5
		info.money_lost = 0
	else:
		info.mode = "passout"
		info.recovery_pct = PASSOUT_STAMINA_RECOVERY
		info.money_lost = 0

	return info

# ============ 状态查询 ============

## 是否体力耗尽
func is_exhausted() -> bool:
	return stamina <= EXHAUSTED_THRESHOLD

## 是否低HP
func is_low_hp() -> bool:
	var max_hp = get_max_hp()
	return current_hp <= int(max_hp * LOW_HP_THRESHOLD)

## 获取当前状态
func get_state() -> String:
	if stamina <= EXHAUSTED_THRESHOLD:
		return "exhausted"
	elif is_low_hp():
		return "low_hp"
	return "normal"

# ============ 信号处理 ============

## 睡眠触发回调
func _on_sleep_triggered(bedtime: int, forced: bool) -> void:
	var hour = bedtime if bedtime > 0 else 24
	daily_reset(hour, forced)

## 农场交互回调 - 消耗体力
func _on_farm_interaction(plot_id: String, tool: int, action: String, success: bool, original_state: int) -> void:
	if not success:
		return

	# 根据动作和原始状态判断是否消耗体力
	var should_consume = _should_consume_stamina(action, original_state)
	if should_consume:
		var cost = _get_stamina_cost_for_action(action)
		if cost > 0:
			consume_stamina(cost)

## 判断是否应该消耗体力
func _should_consume_stamina(action: String, original_state: int) -> bool:
	match action:
		"till":
			return original_state == 0  # WASTELAND
		"water":
			return original_state in [2, 3]  # PLANTED, GROWING
		"plant":
			return original_state == 1  # TILLED
		"harvest":
			return original_state == 4  # HARVESTABLE
	return false

## 获取动作的体力消耗
func _get_stamina_cost_for_action(action: String) -> int:
	match action:
		"till": return 5
		"water": return 3
		"plant": return 2
		"harvest": return 1
	return 0

# ============ 内部方法 ============

## 获取天气体力修正
func _get_weather_stamina_modifier() -> float:
	# 如果WeatherSystem存在，返回其修正值
	if EventBus.has_signal("weather_changed"):
		# 预留接口，实际天气系统实现后完善
		return 1.0
	return 1.0

## 发送体力变化信号
func _emit_stamina_changed() -> void:
	stamina_changed.emit(stamina, get_max_stamina())

## 发送HP变化信号
func _emit_hp_changed() -> void:
	hp_changed.emit(current_hp, get_max_hp())

## 发送金钱变化信号
func _emit_money_changed() -> void:
	money_changed.emit(money)

## 检查体力状态
func _check_stamina_state() -> void:
	if is_exhausted() and stamina <= 0:
		exhausted.emit()
		state_changed.emit("exhausted")

## 检查HP状态
func _check_hp_state() -> void:
	if is_low_hp():
		low_hp_warning.emit()
		state_changed.emit("low_hp")

# ============ 存档接口 ============

## 序列化存档数据
func serialize() -> Dictionary:
	return {
		"player_name": player_name,
		"gender": gender,
		"stamina": stamina,
		"stamina_cap_level": stamina_cap_level,
		"bonus_max_stamina": bonus_max_stamina,
		"current_hp": current_hp,
		"combat_level": combat_level,
		"has_fighter_perk": has_fighter_perk,
		"has_warrior_perk": has_warrior_perk,
		"ring_hp_bonus": ring_hp_bonus,
		"spirit_shield_hp_bonus": spirit_shield_hp_bonus,
		"guild_hp_bonus": guild_hp_bonus,
		"house_hp_bonus": house_hp_bonus,
		"house_stamina_bonus": house_stamina_bonus,
		"spirit_shield_stamina_save": spirit_shield_stamina_save,
		"money": money
	}

## 反序列化加载数据
func deserialize(data: Dictionary) -> void:
	if data.is_empty():
		push_warning("[PlayerStats] Empty save data, using defaults")
		_initialize()
		return

	player_name = data.get("player_name", "农夫")
	gender = data.get("gender", "male")
	stamina = data.get("stamina", STAMINA_CAPS[0])
	stamina_cap_level = data.get("stamina_cap_level", 0)
	bonus_max_stamina = data.get("bonus_max_stamina", 0)
	current_hp = data.get("current_hp", BASE_MAX_HP)
	combat_level = data.get("combat_level", 1)
	has_fighter_perk = data.get("has_fighter_perk", false)
	has_warrior_perk = data.get("has_warrior_perk", false)
	ring_hp_bonus = data.get("ring_hp_bonus", 0)
	spirit_shield_hp_bonus = data.get("spirit_shield_hp_bonus", 0)
	guild_hp_bonus = data.get("guild_hp_bonus", 0)
	house_hp_bonus = data.get("house_hp_bonus", 0)
	house_stamina_bonus = data.get("house_stamina_bonus", 0.0)
	spirit_shield_stamina_save = data.get("spirit_shield_stamina_save", 0.0)
	money = data.get("money", STARTING_MONEY)

	_initialized = true

	_emit_stamina_changed()
	_emit_hp_changed()
	_emit_money_changed()

	push_warning("[PlayerStats] Loaded: stamina=%d/%d, hp=%d/%d, money=%d" % [
		stamina, get_max_stamina(), current_hp, get_max_hp(), money])
