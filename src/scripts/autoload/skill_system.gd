extends Node

## SkillSystem - 技能系统
## 管理玩家的技能等级和经验
## 参考: design/gdd/core/skill-system.md

# ============ 技能类型 ============

## 技能枚举
enum SkillType {
	FARMING = 0,    # 农耕
	FORAGING = 1,   # 采集
	FISHING = 2,    # 钓鱼
	MINING = 3,     # 采矿
	COMBAT = 4,     # 战斗
	HUNTING = 5     # 狩猎 (Sprint 8 补全)
}

## 技能名称
const SKILL_NAMES: Dictionary = {
	SkillType.FARMING: "农耕",
	SkillType.FORAGING: "采集",
	SkillType.FISHING: "钓鱼",
	SkillType.MINING: "采矿",
	SkillType.COMBAT: "战斗",
	SkillType.HUNTING: "狩猎"
}

## 技能 Emoji
const SKILL_EMOJIS: Dictionary = {
	SkillType.FARMING: "🌾",
	SkillType.FORAGING: "🍄",
	SkillType.FISHING: "🎣",
	SkillType.MINING: "⛏️",
	SkillType.COMBAT: "⚔️",
	SkillType.HUNTING: "🏹"
}

# ============ 经验表 ============

## 升级所需累计经验
## EXP_TABLE[i] = 升到 i 级所需的累计经验
const EXP_TABLE: Array[int] = [
	0,      # Lv 0
	100,    # Lv 1
	380,    # Lv 2
	770,    # Lv 3
	1300,   # Lv 4
	2150,   # Lv 5
	3300,   # Lv 6
	4800,   # Lv 7
	6900,   # Lv 8
	10000,  # Lv 9
	15000   # Lv 10 (MAX)
]

const MAX_LEVEL: int = 10

## 每级体力减免比例
const STAMINA_REDUCTION_PER_LEVEL: float = 0.01

# ============ 技能数据 ============

## 技能状态
class SkillState:
	var level: int = 0
	var exp: int = 0
	var perk_5: String = ""
	var perk_10: String = ""

## 所有技能数据
var _skills: Dictionary = {
	SkillType.FARMING: SkillState.new(),
	SkillType.FORAGING: SkillState.new(),
	SkillType.FISHING: SkillState.new(),
	SkillType.MINING: SkillState.new(),
	SkillType.COMBAT: SkillState.new(),
	SkillType.HUNTING: SkillState.new()
}

## 经验加成 (来自装备等)
var _exp_bonus: float = 0.0

## 是否已初始化
var _initialized: bool = false

# ============ 信号 ============

## 技能升级信号
signal skill_level_up(skill_type: int, old_level: int, new_level: int)
signal exp_changed(skill_type: int, current_exp: int, exp_gained: int)

## 天赋选择信号
signal perk_selected(skill_type: int, perk_id: String)

# ============ 初始化 ============

func _ready() -> void:
	_initialize()

func _initialize() -> void:
	if _initialized:
		return

	# 确保所有技能都初始化
	for skill_type in SkillType.values():
		if not _skills.has(skill_type):
			_skills[skill_type] = SkillState.new()

	_initialized = true
	print("[SkillSystem] Initialized")

# ============ 经验操作 ============

## 添加经验
func add_exp(skill_type: int, base_amount: int) -> Dictionary:
	if not _is_valid_skill_type(skill_type):
		print("[SkillSystem] Invalid skill type: %d" % skill_type)
		return {"leveled_up": false, "new_level": 0, "old_level": 0}

	var skill = _get_skill(skill_type)

	# 满级后不再获取经验
	if skill.level >= MAX_LEVEL:
		return {"leveled_up": false, "new_level": skill.level, "old_level": skill.level}

	# 计算实际获得经验
	var actual_exp = base_amount
	if _exp_bonus > 0:
		actual_exp = int(floor(base_amount * (1.0 + _exp_bonus)))

	skill.exp += actual_exp

	# 检查是否升级
	var result = _check_level_up(skill_type)

	# 发送经验变化信号
	exp_changed.emit(skill_type, skill.exp, actual_exp)

	print("[SkillSystem] %s +%d exp (total: %d/%d)" % [
		SKILL_NAMES[skill_type], actual_exp, skill.exp, EXP_TABLE[skill.level]])

	return result

## 检查升级
func _check_level_up(skill_type: int) -> Dictionary:
	var skill = _get_skill(skill_type)
	var leveled_up = false
	var old_level = skill.level

	# 检查是否可以升级
	while skill.level < MAX_LEVEL and skill.exp >= EXP_TABLE[skill.level + 1]:
		skill.level += 1
		leveled_up = true
		skill_level_up.emit(skill_type, old_level, skill.level)
		# 通过 EventBus 发送，供其他系统接收
		if EventBus.has_signal("skill_level_up"):
			EventBus.skill_level_up.emit(skill_type, old_level, skill.level)
		print("[SkillSystem] %s leveled up to Lv.%d!" % [SKILL_NAMES[skill_type], skill.level])

	return {
		"leveled_up": leveled_up,
		"new_level": skill.level,
		"old_level": old_level
	}

# ============ 查询 API ============

## 获取技能等级
func get_level(skill_type: int) -> int:
	var skill = _get_skill(skill_type)
	return skill.level if skill else 0

## 获取技能经验
func get_exp(skill_type: int) -> int:
	var skill = _get_skill(skill_type)
	return skill.exp if skill else 0

## 获取当前等级经验
func get_current_level_exp(skill_type: int) -> int:
	var skill = _get_skill(skill_type)
	if not skill or skill.level >= MAX_LEVEL:
		return 0
	return skill.exp - EXP_TABLE[skill.level]

## 获取升级所需经验
func get_exp_to_next_level(skill_type: int) -> int:
	var skill = _get_skill(skill_type)
	if not skill or skill.level >= MAX_LEVEL:
		return 0
	return EXP_TABLE[skill.level + 1] - skill.exp

## 获取当前等级总经验需求
func get_level_exp_requirement(skill_type: int) -> int:
	var skill = _get_skill(skill_type)
	if not skill or skill.level >= MAX_LEVEL:
		return 0
	return EXP_TABLE[skill.level + 1] - EXP_TABLE[skill.level]

## 获取经验百分比
func get_exp_percent(skill_type: int) -> float:
	var skill = _get_skill(skill_type)
	if not skill or skill.level >= MAX_LEVEL:
		return 100.0

	var current = skill.exp - EXP_TABLE[skill.level]
	var required = EXP_TABLE[skill.level + 1] - EXP_TABLE[skill.level]

	if required <= 0:
		return 100.0

	return (float(current) / float(required)) * 100.0

## 获取体力减免比例
func get_stamina_reduction(skill_type: int) -> float:
	var level = get_level(skill_type)
	return level * STAMINA_REDUCTION_PER_LEVEL

## 获取农耕技能加成 (作物品质提升)
func get_farming_quality_bonus() -> float:
	var level = get_level(SkillType.FARMING)
	# 3级+有概率出Fine, 6级+有概率出Excellent, 9级+有概率出Supreme
	return level * 0.02  # 每级+2%高品质概率

# ============ 内部方法 ============

func _get_skill(skill_type: int) -> SkillState:
	return _skills.get(skill_type)

func _is_valid_skill_type(skill_type: int) -> bool:
	return skill_type >= 0 and skill_type < SkillType.size()

# ============ 天赋系统 (简化版) ============

## 获取5级天赋
func get_perk_5(skill_type: int) -> String:
	var skill = _get_skill(skill_type)
	return skill.perk_5 if skill else ""

## 获取10级天赋
func get_perk_10(skill_type: int) -> String:
	var skill = _get_skill(skill_type)
	return skill.perk_10 if skill else ""

## 设置5级天赋
func set_perk_5(skill_type: int, perk_id: String) -> bool:
	var skill = _get_skill(skill_type)
	if not skill:
		return false

	# 检查等级是否足够
	if skill.level < 5:
		print("[SkillSystem] Cannot set perk: level %d < 5" % skill.level)
		return false

	# 检查是否已选择
	if skill.perk_5 != "":
		print("[SkillSystem] Perk 5 already selected: %s" % skill.perk_5)
		return false

	skill.perk_5 = perk_id
	perk_selected.emit(skill_type, perk_id)
	print("[SkillSystem] %s Lv5 perk selected: %s" % [SKILL_NAMES[skill_type], perk_id])
	return true

## 设置10级天赋
func set_perk_10(skill_type: int, perk_id: String) -> bool:
	var skill = _get_skill(skill_type)
	if not skill:
		return false

	# 检查等级是否足够
	if skill.level < 10:
		print("[SkillSystem] Cannot set perk: level %d < 10" % skill.level)
		return false

	# 检查是否已选择
	if skill.perk_10 != "":
		print("[SkillSystem] Perk 10 already selected: %s" % skill.perk_10)
		return false

	skill.perk_10 = perk_id
	perk_selected.emit(skill_type, perk_id)
	print("[SkillSystem] %s Lv10 perk selected: %s" % [SKILL_NAMES[skill_type], perk_id])
	return true

# ============ 经验加成 (来自装备) ============

## 设置经验加成
func set_exp_bonus(bonus: float) -> void:
	_exp_bonus = max(0.0, bonus)
	print("[SkillSystem] Exp bonus: %.0f%%" % (_exp_bonus * 100))

## 获取经验加成
func get_exp_bonus() -> float:
	return _exp_bonus

# ============ 存档支持 ============

## 序列化存档数据
func serialize() -> Dictionary:
	var skills_data = {}
	for skill_type in SkillType.values():
		var skill = _get_skill(skill_type)
		if skill:
			skills_data[str(skill_type)] = {
				"level": skill.level,
				"exp": skill.exp,
				"perk_5": skill.perk_5,
				"perk_10": skill.perk_10
			}

	return {
		"skills": skills_data,
		"exp_bonus": _exp_bonus
	}

## 反序列化加载数据
func deserialize(data: Dictionary) -> void:
	if data.is_empty():
		print("[SkillSystem] Empty save data, using defaults")
		return

	# 加载技能数据
	var skills_data = data.get("skills", {})
	for skill_type in SkillType.values():
		var skill_data = skills_data.get(str(skill_type), {})
		var skill = _get_skill(skill_type)
		if skill and not skill_data.is_empty():
			skill.level = clampi(skill_data.get("level", 0), 0, MAX_LEVEL)
			skill.exp = maxi(skill_data.get("exp", 0), 0)
			skill.perk_5 = skill_data.get("perk_5", "")
			skill.perk_10 = skill_data.get("perk_10", "")

	# 加载经验加成
	_exp_bonus = data.get("exp_bonus", 0.0)

	_initialized = true
	print("[SkillSystem] Loaded skills data")

# ============ 调试方法 ============

## 调试：添加大量经验
func debug_add_exp(skill_type: int, amount: int) -> void:
	add_exp(skill_type, amount)

## 调试：设置等级
func debug_set_level(skill_type: int, level: int) -> void:
	var skill = _get_skill(skill_type)
	if skill:
		skill.level = clampi(level, 0, MAX_LEVEL)
		skill.exp = EXP_TABLE[skill.level]
		print("[SkillSystem] Debug: %s set to Lv.%d" % [SKILL_NAMES[skill_type], skill.level])

## 调试：获取所有技能信息
func debug_get_all_skills() -> Dictionary:
	var result = {}
	for skill_type in SkillType.values():
		var skill = _get_skill(skill_type)
		if skill:
			result[SKILL_NAMES[skill_type]] = {
				"level": skill.level,
				"exp": skill.exp,
				"exp_percent": get_exp_percent(skill_type),
				"stamina_reduction": "%.0f%%" % (get_stamina_reduction(skill_type) * 100)
			}
	return result

# ============ 便捷方法 ============

## 获取所有技能信息 (用于UI显示)
func get_all_skills_info() -> Array:
	var result = []
	for skill_type in SkillType.values():
		result.append({
			"type": skill_type,
			"name": SKILL_NAMES[skill_type],
			"emoji": SKILL_EMOJIS[skill_type],
			"level": get_level(skill_type),
			"exp": get_exp(skill_type),
			"exp_percent": get_exp_percent(skill_type),
			"exp_to_next": get_exp_to_next_level(skill_type),
			"perk_5": get_perk_5(skill_type),
			"perk_10": get_perk_10(skill_type),
			"stamina_reduction": get_stamina_reduction(skill_type)
		})
	return result
