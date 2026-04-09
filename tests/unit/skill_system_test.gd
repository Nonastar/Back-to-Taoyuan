extends "res://tests/unit/test_base.gd"

## SkillSystem单元测试

var _skill: Node = null

func before_each():
	_skill = Node.new()
	_skill.set_script(load("res://src/scripts/autoload/skill_system.gd"))
	_skill._initialize()

func after_each():
	_skill.free()

## 测试初始状态
func test_initial_level():
	assert_eq(_skill.get_level(_skill.SkillType.FARMING), 0, "初始农耕等级应为0")
	assert_eq(_skill.get_level(_skill.SkillType.FISHING), 0, "初始钓鱼等级应为0")
	assert_eq(_skill.get_level(_skill.SkillType.MINING), 0, "初始采矿等级应为0")

func test_initial_exp():
	assert_eq(_skill.get_exp(_skill.SkillType.FARMING), 0, "初始经验应为0")
	assert_eq(_skill.get_exp(_skill.SkillType.FORAGING), 0, "初始采集经验应为0")

## 测试经验添加
func test_add_exp():
	_skill.add_exp(_skill.SkillType.FARMING, 50)
	assert_eq(_skill.get_exp(_skill.SkillType.FARMING), 50, "添加50经验后应有50")
	assert_eq(_skill.get_level(_skill.SkillType.FARMING), 0, "50经验不足以升级")

func test_add_exp_level_up():
	# 添加100经验应升到Lv1 (需要100经验)
	var result = _skill.add_exp(_skill.SkillType.FARMING, 100)
	assert_eq(_skill.get_level(_skill.SkillType.FARMING), 1, "100经验应升到Lv1")
	assert_true(result["leveled_up"], "应返回升级")
	assert_eq(result["new_level"], 1, "新等级应为1")
	assert_eq(result["old_level"], 0, "旧等级应为0")

## 测试经验百分比
func test_exp_percent():
	_skill.add_exp(_skill.SkillType.FARMING, 50)  # 50/100 = 50%
	var percent = _skill.get_exp_percent(_skill.SkillType.FARMING)
	assert_almost_eq(percent, 50.0, 0.1, "50/100经验应为50%")

func test_exp_percent_full_level():
	_skill.debug_set_level(_skill.SkillType.FISHING, 10)
	var percent = _skill.get_exp_percent(_skill.SkillType.FISHING)
	assert_eq(percent, 100.0, "满级经验百分比应为100%")

## 测试升级经验表
func test_exp_table():
	# Lv0 → Lv1: 100经验
	assert_eq(_skill.EXP_TABLE[1], 100, "升到Lv1需要100经验")
	# Lv1 → Lv2: 280经验 (累计380)
	assert_eq(_skill.EXP_TABLE[2], 380, "升到Lv2需要380经验")
	# Lv2 → Lv3: 390经验 (累计770)
	assert_eq(_skill.EXP_TABLE[3], 770, "升到Lv3需要770经验")
	# Lv9 → Lv10: 5000经验 (累计15000)
	assert_eq(_skill.EXP_TABLE[10], 15000, "升到Lv10需要15000经验")

## 测试连续升级
func test_multi_level_up():
	# 添加280经验 (50+230) 应该升到Lv2
	_skill.add_exp(_skill.SkillType.MINING, 50)
	_skill.add_exp(_skill.SkillType.MINING, 230)  # 累计280

	assert_eq(_skill.get_level(_skill.SkillType.MINING), 2, "280经验应升到Lv2")
	assert_eq(_skill.get_exp(_skill.SkillType.MINING), 280, "总经验应为280")

## 测试满级后不再获得经验
func test_max_level_no_exp():
	_skill.debug_set_level(_skill.SkillType.FARMING, 10)
	var exp_before = _skill.get_exp(_skill.SkillType.FARMING)

	_skill.add_exp(_skill.SkillType.FARMING, 1000)
	assert_eq(_skill.get_exp(_skill.SkillType.FARMING), exp_before, "满级后经验不应增加")
	assert_eq(_skill.get_level(_skill.SkillType.FARMING), 10, "满级后等级不变")

## 测试体力减免
func test_stamina_reduction():
	assert_almost_eq(_skill.get_stamina_reduction(_skill.SkillType.FARMING), 0.0, 0.001, "Lv0无减免")

	_skill.debug_set_level(_skill.SkillType.FARMING, 5)
	assert_almost_eq(_skill.get_stamina_reduction(_skill.SkillType.FARMING), 0.05, 0.001, "Lv5应有5%减免")

	_skill.debug_set_level(_skill.SkillType.FARMING, 10)
	assert_almost_eq(_skill.get_stamina_reduction(_skill.SkillType.FARMING), 0.10, 0.001, "Lv10应有10%减免")

## 测试农耕品质加成
func test_farming_quality_bonus():
	assert_almost_eq(_skill.get_farming_quality_bonus(), 0.0, 0.001, "Lv0无品质加成")

	_skill.debug_set_level(_skill.SkillType.FARMING, 3)
	assert_almost_eq(_skill.get_farming_quality_bonus(), 0.06, 0.001, "Lv3应有6%品质加成")

## 测试经验加成
func test_exp_bonus():
	_skill.set_exp_bonus(0.5)  # 50%加成
	assert_almost_eq(_skill.get_exp_bonus(), 0.5, 0.001, "经验加成应为50%")

	# 添加100基础经验, 50%加成 = 150
	_skill.add_exp(_skill.SkillType.FORAGING, 100)
	assert_eq(_skill.get_exp(_skill.SkillType.FORAGING), 150, "100基础+50%加成=150")

	_skill.set_exp_bonus(0.0)  # 重置

## 测试获取等级经验需求
func test_level_exp_requirement():
	# Lv0 → Lv1 需要 100 - 0 = 100
	assert_eq(_skill.get_level_exp_requirement(_skill.SkillType.FARMING), 100, "Lv0到Lv1需100经验")
	# Lv1 → Lv2 需要 380 - 100 = 280
	_skill.debug_set_level(_skill.SkillType.FARMING, 1)
	assert_eq(_skill.get_level_exp_requirement(_skill.SkillType.FARMING), 280, "Lv1到Lv2需280经验")

## 测试升级所需经验
func test_exp_to_next_level():
	_skill.add_exp(_skill.SkillType.COMBAT, 50)
	# 100 - 50 = 50
	assert_eq(_skill.get_exp_to_next_level(_skill.SkillType.COMBAT), 50, "到下一级需50经验")

## 测试天赋系统
func test_perk_5():
	_skill.debug_set_level(_skill.SkillType.FARMING, 4)
	assert_false(_skill.set_perk_5(_skill.SkillType.FARMING, "fertile_soil"), "Lv4不能选择天赋")

	_skill.debug_set_level(_skill.SkillType.FARMING, 5)
	assert_true(_skill.set_perk_5(_skill.SkillType.FARMING, "fertile_soil"), "Lv5可以选择天赋")
	assert_eq(_skill.get_perk_5(_skill.SkillType.FARMING), "fertile_soil", "天赋应已设置")

	# 再次设置应失败
	assert_false(_skill.set_perk_5(_skill.SkillType.FARMING, "other"), "已选择天赋不能重复选择")

func test_perk_10():
	_skill.debug_set_level(_skill.SkillType.FISHING, 9)
	assert_false(_skill.set_perk_10(_skill.SkillType.FISHING, "master_fisher"), "Lv9不能选择天赋")

	_skill.debug_set_level(_skill.SkillType.FISHING, 10)
	assert_true(_skill.set_perk_10(_skill.SkillType.FISHING, "master_fisher"), "Lv10可以选择天赋")
	assert_eq(_skill.get_perk_10(_skill.SkillType.FISHING), "master_fisher", "天赋应已设置")

## 测试获取所有技能信息
func test_get_all_skills_info():
	var info = _skill.get_all_skills_info()
	assert_eq(info.size(), 5, "应有5个技能")

	# 检查结构
	for skill_info in info:
		assert_true(skill_info.has("type"), "应包含type")
		assert_true(skill_info.has("name"), "应包含name")
		assert_true(skill_info.has("level"), "应包含level")
		assert_true(skill_info.has("exp"), "应包含exp")

## 测试存档/加载
func test_serialize_deserialize():
	_skill.add_exp(_skill.SkillType.FARMING, 150)
	_skill.add_exp(_skill.SkillType.FISHING, 50)
	_skill.set_exp_bonus(0.2)

	var data = _skill.serialize()
	assert_true(data.has("skills"), "存档应包含skills")
	assert_true(data.has("exp_bonus"), "存档应包含exp_bonus")
	assert_almost_eq(data["exp_bonus"], 0.2, 0.001, "经验加成应为0.2")

	# 创建新实例并加载
	var new_skill = Node.new()
	new_skill.set_script(load("res://src/scripts/autoload/skill_system.gd"))
	new_skill.deserialize(data)

	assert_eq(new_skill.get_level(_skill.SkillType.FARMING), 1, "加载后农耕应为Lv1")
	assert_eq(new_skill.get_level(_skill.SkillType.FISHING), 0, "加载后钓鱼应为Lv0")
	assert_almost_eq(new_skill.get_exp_bonus(), 0.2, 0.001, "加载后经验加成应为0.2")

	new_skill.free()

## 测试无效技能类型
func test_invalid_skill_type():
	var result = _skill.add_exp(999, 100)
	assert_false(result["leveled_up"], "无效技能类型应返回未升级")
	assert_eq(result["new_level"], 0, "无效技能类型新等级应为0")

## 测试技能名称映射
func test_skill_names():
	assert_eq(_skill.SKILL_NAMES[_skill.SkillType.FARMING], "农耕")
	assert_eq(_skill.SKILL_NAMES[_skill.SkillType.FORAGING], "采集")
	assert_eq(_skill.SKILL_NAMES[_skill.SkillType.FISHING], "钓鱼")
	assert_eq(_skill.SKILL_NAMES[_skill.SkillType.MINING], "采矿")
	assert_eq(_skill.SKILL_NAMES[_skill.SkillType.COMBAT], "战斗")

## 测试技能Emoji
func test_skill_emojis():
	assert_eq(_skill.SKILL_EMOJIS[_skill.SkillType.FARMING], "🌾")
	assert_eq(_skill.SKILL_EMOJIS[_skill.SkillType.FISHING], "🎣")
	assert_eq(_skill.SKILL_EMOJIS[_skill.SkillType.MINING], "⛏️")
