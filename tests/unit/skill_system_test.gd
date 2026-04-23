extends "res://tests/unit/test_base.gd"

## SkillSystem单元测试
## 注意：由于测试运行器为每个文件创建一个实例并运行所有测试方法，
## 每个测试必须自行重置状态，防止测试间污染

var _skill: Node = null

func _reset_all_state():
	"""重置所有状态到初始值"""
	_skill._exp_bonus = 0.0
	for skill_type in _skill.SkillType.values():
		var skill = _skill._get_skill(skill_type)
		if skill:
			skill.level = 0
			skill.exp = 0
			skill.perk_5 = ""
			skill.perk_10 = ""

func before_each():
	_skill = Node.new()
	_skill.set_script(load("res://src/scripts/autoload/skill_system.gd"))
	_skill._initialized = false
	_skill._initialize()

func after_each():
	_skill._initialized = false
	_skill.free()

## 测试初始状态
func test_initial_level():
	_reset_all_state()
	assert_eq(_skill.get_level(_skill.SkillType.FARMING), 0, "初始农耕等级应为0")
	assert_eq(_skill.get_level(_skill.SkillType.FISHING), 0, "初始钓鱼等级应为0")
	assert_eq(_skill.get_level(_skill.SkillType.MINING), 0, "初始采矿等级应为0")

func test_initial_exp():
	_reset_all_state()
	assert_eq(_skill.get_exp(_skill.SkillType.FARMING), 0, "初始经验应为0")
	assert_eq(_skill.get_exp(_skill.SkillType.FORAGING), 0, "初始采集经验应为0")

## 测试经验添加
func test_add_exp():
	_reset_all_state()
	_skill.add_exp(_skill.SkillType.FARMING, 50)
	assert_eq(_skill.get_exp(_skill.SkillType.FARMING), 50, "添加50经验后应有50")
	assert_eq(_skill.get_level(_skill.SkillType.FARMING), 0, "50经验不足以升级")

func test_add_exp_level_up():
	_reset_all_state()
	var result = _skill.add_exp(_skill.SkillType.FISHING, 100)
	assert_eq(_skill.get_level(_skill.SkillType.FISHING), 1, "100经验应升到Lv1")
	assert_true(result["leveled_up"], "应返回升级")
	assert_eq(result["new_level"], 1, "新等级应为1")
	assert_eq(result["old_level"], 0, "旧等级应为0")

## 测试经验百分比
func test_exp_percent():
	_reset_all_state()
	_skill.add_exp(_skill.SkillType.MINING, 50)
	var percent = _skill.get_exp_percent(_skill.SkillType.MINING)
	assert_almost_eq(percent, 50.0, 0.1, "50/100经验应为50%")

func test_exp_percent_full_level():
	_reset_all_state()
	_skill.debug_set_level(_skill.SkillType.FISHING, 10)
	var percent = _skill.get_exp_percent(_skill.SkillType.FISHING)
	assert_eq(percent, 100.0, "满级经验百分比应为100%")

## 测试升级经验表
func test_exp_table():
	_reset_all_state()
	assert_eq(_skill.EXP_TABLE[1], 100, "升到Lv1需要100经验")
	assert_eq(_skill.EXP_TABLE[2], 380, "升到Lv2需要380经验")
	assert_eq(_skill.EXP_TABLE[3], 770, "升到Lv3需要770经验")
	assert_eq(_skill.EXP_TABLE[10], 15000, "升到Lv10需要15000经验")

## 测试连续升级
func test_multi_level_up():
	_reset_all_state()
	_skill.add_exp(_skill.SkillType.FORAGING, 280)
	assert_eq(_skill.get_level(_skill.SkillType.FORAGING), 1, "280经验应升到Lv1")
	assert_eq(_skill.get_exp(_skill.SkillType.FORAGING), 280, "总经验应为280")

## 测试满级后不再获得经验
func test_max_level_no_exp():
	_reset_all_state()
	_skill.debug_set_level(_skill.SkillType.COMBAT, 10)
	var exp_before = _skill.get_exp(_skill.SkillType.COMBAT)
	_skill.add_exp(_skill.SkillType.COMBAT, 1000)
	assert_eq(_skill.get_exp(_skill.SkillType.COMBAT), exp_before, "满级后经验不应增加")
	assert_eq(_skill.get_level(_skill.SkillType.COMBAT), 10, "满级后等级不变")

## 测试体力减免
func test_stamina_reduction():
	_reset_all_state()
	var reduction = _skill.get_stamina_reduction(_skill.SkillType.FARMING)
	assert_almost_eq(reduction, 0.0, 0.001, "Lv0无减免")

	_skill.debug_set_level(_skill.SkillType.FISHING, 5)
	reduction = _skill.get_stamina_reduction(_skill.SkillType.FISHING)
	assert_almost_eq(reduction, 0.05, 0.001, "Lv5应有5%减免")

## 测试农耕品质加成
func test_farming_quality_bonus():
	_reset_all_state()
	var bonus = _skill.get_farming_quality_bonus()
	assert_almost_eq(bonus, 0.0, 0.001, "Lv0无品质加成")

	_skill.debug_set_level(_skill.SkillType.FARMING, 3)
	bonus = _skill.get_farming_quality_bonus()
	assert_almost_eq(bonus, 0.06, 0.001, "Lv3应有6%品质加成")

## 测试经验加成
func test_exp_bonus():
	_reset_all_state()
	_skill.set_exp_bonus(0.5)
	assert_almost_eq(_skill.get_exp_bonus(), 0.5, 0.001, "经验加成应为50%")

	_skill.add_exp(_skill.SkillType.FORAGING, 100)
	assert_eq(_skill.get_exp(_skill.SkillType.FORAGING), 150, "100基础+50%加成=150")

## 测试获取等级经验需求
func test_level_exp_requirement():
	_reset_all_state()
	var req = _skill.get_level_exp_requirement(_skill.SkillType.MINING)
	assert_eq(req, 100, "Lv0到Lv1需100经验")

## 测试升级所需经验
func test_exp_to_next_level():
	_reset_all_state()
	_skill.add_exp(_skill.SkillType.COMBAT, 50)
	var to_next = _skill.get_exp_to_next_level(_skill.SkillType.COMBAT)
	assert_eq(to_next, 50, "到下一级需50经验")

## 测试天赋系统
func test_perk_5():
	_reset_all_state()
	_skill.debug_set_level(_skill.SkillType.FARMING, 4)
	assert_false(_skill.set_perk_5(_skill.SkillType.FARMING, "fertile_soil"), "Lv4不能选择天赋")

	_skill.debug_set_level(_skill.SkillType.FARMING, 5)
	assert_true(_skill.set_perk_5(_skill.SkillType.FARMING, "fertile_soil"), "Lv5可以选择天赋")
	assert_eq(_skill.get_perk_5(_skill.SkillType.FARMING), "fertile_soil", "天赋应已设置")

	assert_false(_skill.set_perk_5(_skill.SkillType.FARMING, "other"), "已选择天赋不能重复选择")

func test_perk_10():
	_reset_all_state()
	_skill.debug_set_level(_skill.SkillType.FISHING, 9)
	assert_false(_skill.set_perk_10(_skill.SkillType.FISHING, "master_fisher"), "Lv9不能选择天赋")

	_skill.debug_set_level(_skill.SkillType.FISHING, 10)
	assert_true(_skill.set_perk_10(_skill.SkillType.FISHING, "master_fisher"), "Lv10可以选择天赋")
	assert_eq(_skill.get_perk_10(_skill.SkillType.FISHING), "master_fisher", "天赋应已设置")

## 测试获取所有技能信息
func test_get_all_skills_info():
	_reset_all_state()
	var info = _skill.get_all_skills_info()
	assert_eq(info.size(), 6, "应有6个技能（Sprint 8 狩猎技能）")

## 测试存档/加载
func test_serialize_deserialize():
	_reset_all_state()
	var fresh_skill = Node.new()
	fresh_skill.set_script(load("res://src/scripts/autoload/skill_system.gd"))
	fresh_skill._initialized = false
	fresh_skill._initialize()

	fresh_skill.add_exp(fresh_skill.SkillType.FARMING, 150)
	fresh_skill.add_exp(fresh_skill.SkillType.FISHING, 50)
	fresh_skill.set_exp_bonus(0.2)

	var data = fresh_skill.serialize()
	assert_true(data.has("skills"), "存档应包含skills")
	assert_true(data.has("exp_bonus"), "存档应包含exp_bonus")
	assert_almost_eq(data["exp_bonus"], 0.2, 0.001, "经验加成应为0.2")

	var new_skill = Node.new()
	new_skill.set_script(load("res://src/scripts/autoload/skill_system.gd"))
	new_skill._initialized = false
	new_skill._initialize()
	new_skill.deserialize(data)

	assert_eq(new_skill.get_level(fresh_skill.SkillType.FARMING), 1, "加载后农耕应为Lv1")
	assert_eq(new_skill.get_level(fresh_skill.SkillType.FISHING), 0, "加载后钓鱼应为Lv0")
	assert_almost_eq(new_skill.get_exp_bonus(), 0.2, 0.001, "加载后经验加成应为0.2")

	fresh_skill.free()
	new_skill.free()

## 测试无效技能类型
func test_invalid_skill_type():
	_reset_all_state()
	var result = _skill.add_exp(999, 100)
	assert_false(result["leveled_up"], "无效技能类型应返回未升级")
	assert_eq(result["new_level"], 0, "无效技能类型新等级应为0")

## 测试技能名称映射
func test_skill_names():
	_reset_all_state()
	assert_eq(_skill.SKILL_NAMES[_skill.SkillType.FARMING], "农耕")
	assert_eq(_skill.SKILL_NAMES[_skill.SkillType.FORAGING], "采集")
	assert_eq(_skill.SKILL_NAMES[_skill.SkillType.FISHING], "钓鱼")
	assert_eq(_skill.SKILL_NAMES[_skill.SkillType.MINING], "采矿")
	assert_eq(_skill.SKILL_NAMES[_skill.SkillType.COMBAT], "战斗")

## 测试技能Emoji
func test_skill_emojis():
	_reset_all_state()
	assert_eq(_skill.SKILL_EMOJIS[_skill.SkillType.FARMING], "🌾")
	assert_eq(_skill.SKILL_EMOJIS[_skill.SkillType.FISHING], "🎣")
	assert_eq(_skill.SKILL_EMOJIS[_skill.SkillType.MINING], "⛏️")
