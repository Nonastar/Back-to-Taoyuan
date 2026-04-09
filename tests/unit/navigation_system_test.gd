extends "res://tests/unit/test_base.gd"

## NavigationSystem单元测试

var _nav: Node = null

func before_each():
	_nav = Node.new()
	_nav.set_script(load("res://src/scripts/autoload/navigation_system.gd"))
	# 初始化
	_nav.current_panel = "farm"
	_nav.current_group = _nav.LocationGroup.FARM
	_nav.has_horse = false
	_nav.speed_buff = 0.0
	_nav.travel_speed_bonus = 0.0

func after_each():
	_nav.free()

## 测试初始状态
func test_initial_state():
	assert_eq(_nav.current_panel, "farm", "初始面板应为farm")
	assert_eq(_nav.current_group, _nav.LocationGroup.FARM, "初始组应为FARM")

## 测试组名获取
func test_group_names():
	assert_eq(_nav.get_current_group_name(), "农场", "farm组名称应为农场")
	assert_eq(_nav.get_current_group_emoji(), "🏠", "farm组emoji应为🏠")

## 测试面板名称获取
func test_panel_names():
	assert_eq(_nav.get_current_panel_name(), "农场", "farm面板名称应为农场")
	assert_eq(_nav.get_current_panel_emoji(), "🌾", "farm面板emoji应为🌾")

## 测试同组内切换无消耗
func test_same_group_no_cost():
	var cost = _nav.get_travel_cost("animal")
	assert_eq(cost["time_cost"], 0.0, "同组切换时间消耗为0")
	assert_eq(cost["stamina_cost"], 0, "同组切换体力消耗为0")
	assert_false(cost["is_travel"], "同组切换不是旅行")

## 测试跨组旅行消耗 - farm到village
func test_farm_to_village_cost():
	var cost = _nav.get_travel_cost("village")
	assert_almost_eq(cost["time_cost"], 0.17, 0.001, "farm→village时间0.17h")
	assert_eq(cost["stamina_cost"], 1, "farm→village体力1")
	assert_true(cost["is_travel"], "跨组切换是旅行")

## 测试跨组旅行消耗 - farm到mine
func test_farm_to_mine_cost():
	var cost = _nav.get_travel_cost("mining")
	assert_almost_eq(cost["time_cost"], 0.33, 0.001, "farm→mine时间0.33h")
	assert_eq(cost["stamina_cost"], 2, "farm→mine体力2")
	assert_true(cost["is_travel"], "farm→mine是旅行")

## 测试跨组旅行消耗 - farm到hanhai
func test_farm_to_hanhai_cost():
	var cost = _nav.get_travel_cost("hanhai")
	assert_almost_eq(cost["time_cost"], 0.5, 0.001, "farm→hanhai时间0.5h")
	assert_eq(cost["stamina_cost"], 3, "farm→hanhai体力3")
	assert_true(cost["is_travel"], "farm→hanhai是旅行")

## 测试马匹加成
func test_horse_bonus():
	_nav.has_horse = true

	# farm→mine: 0.33h × 0.7 = 0.231h
	var cost = _nav.get_travel_cost("mining")
	assert_almost_eq(cost["time_cost"], 0.231, 0.01, "马匹加成后farm→mine时间约0.231h")
	assert_eq(cost["stamina_cost"], 1, "马匹体力减半")

	_nav.has_horse = false

## 测试速度buff加成
func test_speed_buff():
	_nav.speed_buff = 0.1  # 10%速度加成

	# farm→mine: 0.33h × 0.9 = 0.297h
	var cost = _nav.get_travel_cost("mining")
	assert_almost_eq(cost["time_cost"], 0.297, 0.001, "速度buff后farm→mine时间约0.297h")

	_nav.speed_buff = 0.0

## 测试多个加成叠加
func test_multiple_bonuses():
	_nav.has_horse = true
	_nav.speed_buff = 0.1

	# farm→mine: 0.33 × 0.7 × 0.9 = 0.2079h
	var cost = _nav.get_travel_cost("mining")
	assert_almost_eq(cost["time_cost"], 0.2079, 0.001, "多加成后farm→mine时间约0.208h")

	_nav.has_horse = false
	_nav.speed_buff = 0.0

## 测试获取当前组面板
func test_get_panels_in_group():
	var farm_panels = _nav.get_panels_in_current_group()
	assert_true("farm" in farm_panels, "farm面板应在farm组")
	assert_true("animal" in farm_panels, "animal面板应在farm组")
	assert_true("home" in farm_panels, "home面板应在farm组")

## 测试可访问面板
func test_accessible_panels():
	var panels = _nav.get_accessible_panels()
	assert_true(panels.size() > 0, "应有可访问的面板")

## 测试无地点面板
func test_no_location_panels():
	var cost = _nav.get_travel_cost("inventory")
	assert_eq(cost["time_cost"], 0.0, "无地点面板时间消耗为0")
	assert_eq(cost["stamina_cost"], 0, "无地点面板体力消耗为0")
	assert_false(cost["is_travel"], "无地点面板不是旅行")

## 测试保存/加载数据
func test_save_load():
	var save_data = _nav.get_save_data()
	assert_eq(save_data["current_panel"], "farm")
	assert_eq(save_data["current_group"], _nav.LocationGroup.FARM)
	assert_false(save_data["has_horse"])

	# 模拟加载
	_nav.current_panel = "mining"
	_nav.current_group = _nav.LocationGroup.MINE
	_nav.has_horse = true

	_nav.load_save_data(save_data)
	assert_eq(_nav.current_panel, "farm", "加载后面板应为farm")
	assert_eq(_nav.current_group, _nav.LocationGroup.FARM, "加载后组应为FARM")
	assert_false(_nav.has_horse, "加载后马匹状态应为false")

## 测试返回农场
func test_return_to_farm():
	_nav.current_panel = "mining"
	_nav.current_group = _nav.LocationGroup.MINE

	_nav.return_to_farm()

	assert_eq(_nav.current_panel, "farm", "返回后面板应为farm")
	assert_eq(_nav.current_group, _nav.LocationGroup.FARM, "返回后组应为FARM")
	assert_false(_nav.is_paused, "返回后不应暂停")
