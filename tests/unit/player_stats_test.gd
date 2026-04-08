extends "res://tests/unit/test_base.gd"

## PlayerStats单元测试

var _stats: Node = null

func before_each():
	_stats = Node.new()
	_stats.set_script(load("res://src/scripts/autoload/player_stats_system.gd"))
	# 初始化
	_stats._initialized = false
	_stats._initialize()

func after_each():
	_stats.free()

func test_initial_values():
	# 测试初始值
	assert_eq(_stats.get_current_stamina(), 120, "初始体力应为120")
	assert_eq(_stats.get_max_stamina(), 120, "初始体力上限应为120")
	assert_eq(_stats.get_current_hp(), 100, "初始HP应为100")
	assert_eq(_stats.get_max_hp(), 100, "基础最大HP应为100")
	assert_eq(_stats.get_money(), 500, "初始金钱应为500")

func test_stamina_consume():
	# 测试体力消耗
	var initial = _stats.get_current_stamina()
	var consumed = _stats.consume_stamina(10)
	assert_true(consumed, "消耗成功应返回true")
	assert_eq(_stats.get_current_stamina(), initial - 10, "体力应减少10")

	# 测试体力不足
	var remaining = _stats.get_current_stamina()
	consumed = _stats.consume_stamina(remaining + 100)
	assert_false(consumed, "体力不足应返回false")
	assert_eq(_stats.get_current_stamina(), 0, "体力应降至0")

func test_stamina_restore():
	# 测试体力恢复
	_stats.stamina = 50
	_stats.restore_stamina(30)
	assert_eq(_stats.get_current_stamina(), 80, "体力应恢复到80")

	# 测试超过上限
	_stats.stamina = 100
	_stats.restore_stamina(50)
	assert_eq(_stats.get_current_stamina(), 120, "体力不应超过上限120")

func test_stamina_upgrade():
	# 测试体力上限升级
	assert_eq(_stats.get_stamina_cap_level(), 0, "初始等级应为0")
	assert_eq(_stats.get_max_stamina(), 120, "第0档上限应为120")

	var upgraded = _stats.upgrade_max_stamina()
	assert_true(upgraded, "升级成功应返回true")
	assert_eq(_stats.get_stamina_cap_level(), 1, "等级应变为1")
	assert_eq(_stats.get_max_stamina(), 160, "第1档上限应为160")

	# 测试最高级不能再升级
	for i in range(10):
		_stats.upgrade_max_stamina()
	assert_eq(_stats.get_stamina_cap_level(), 4, "最高等级应为4")
	var cannot_upgrade = _stats.upgrade_max_stamina()
	assert_false(cannot_upgrade, "最高级不应再升级")

func test_stamina_percent():
	# 测试体力百分比
	_stats.stamina = 60
	assert_almost_eq(_stats.get_stamina_percent(), 50.0, 0.1, "50%体力")

	_stats.stamina = 120
	assert_almost_eq(_stats.get_stamina_percent(), 100.0, 0.1, "100%体力")

func test_hp_damage():
	# 测试伤害
	var initial_hp = _stats.get_current_hp()
	var damage = _stats.take_damage(20)
	assert_eq(damage, 20, "应造成20点伤害")
	assert_eq(_stats.get_current_hp(), initial_hp - 20, "HP应减少20")

	# 测试过量伤害
	_stats.current_hp = 10
	damage = _stats.take_damage(100)
	assert_eq(damage, 10, "实际伤害不应超过当前HP")
	assert_eq(_stats.get_current_hp(), 0, "HP不应为负")

func test_hp_restore():
	# 测试HP恢复
	_stats.current_hp = 50
	_stats.restore_health(30)
	assert_eq(_stats.get_current_hp(), 80, "HP应恢复到80")

	# 测试超过上限
	_stats.restore_health(100)
	assert_eq(_stats.get_current_hp(), 100, "HP不应超过最大HP")

func test_combat_level_hp():
	# 测试战斗等级影响HP
	_stats.combat_level = 1
	assert_eq(_stats.get_max_hp(), 100, "1级HP应为100")

	_stats.combat_level = 5
	assert_eq(_stats.get_max_hp(), 120, "5级HP应为100+(5-1)*5=120")

func test_money_operations():
	# 测试金钱操作
	_stats.money = 1000
	var spent = _stats.spend_money(300)
	assert_true(spent, "花费成功应返回true")
	assert_eq(_stats.get_money(), 700, "金钱应减少300")

	var failed = _stats.spend_money(1000)
	assert_false(failed, "余额不足应返回false")
	assert_eq(_stats.get_money(), 700, "金钱不应变化")

	_stats.earn_money(500)
	assert_eq(_stats.get_money(), 1200, "获得金钱后应为1200")

func test_exhausted_state():
	# 测试体力耗尽状态
	_stats.stamina = 100
	assert_false(_stats.is_exhausted(), "体力100不应是耗尽")

	_stats.stamina = 5
	assert_true(_stats.is_exhausted(), "体力<=5应是耗尽状态")

func test_low_hp_state():
	# 测试低HP状态
	_stats.current_hp = 100
	_stats._update_max_hp_for_test()
	assert_false(_stats.is_low_hp(), "HP>25%不应是低HP")

	_stats.current_hp = 24
	assert_true(_stats.is_low_hp(), "HP<=25%应是低HP")

func test_get_state():
	# 测试状态获取
	_stats.stamina = 100
	_stats.current_hp = 100
	assert_eq(_stats.get_state(), "normal", "正常状态")

	_stats.stamina = 5
	assert_eq(_stats.get_state(), "exhausted", "耗尽状态")

	_stats.stamina = 100
	_stats.current_hp = 10
	assert_eq(_stats.get_state(), "low_hp", "低HP状态")

# 辅助方法用于测试
func _update_max_hp_for_test():
	pass  # 简化版，实际测试中HP上限固定为100
