extends "res://tests/unit/test_base.gd"

## WeatherSystem单元测试

var _weather: Node = null

func before_each():
	_weather = Node.new()
	_weather.set_script(load("res://src/scripts/autoload/weather_system.gd"))
	# 禁用debug模式减少输出
	_weather._debug_mode = false

func after_each():
	_weather.free()

func test_initial_weather():
	# 测试初始天气为晴天
	assert_eq(_weather.get_today_weather(), "sunny", "初始天气应为晴天")
	assert_eq(_weather.get_tomorrow_weather(), "sunny", "初始预报应为晴天")

func test_is_rainy():
	# 测试雨天判断
	_weather.tomorrow_weather = "sunny"
	assert_false(_weather.is_rainy(), "晴天不应是雨天")

	_weather.tomorrow_weather = "rainy"
	assert_true(_weather.is_rainy(), "雨天应返回true")

	_weather.tomorrow_weather = "stormy"
	assert_true(_weather.is_stormy(), "雷雨应返回true")

	_weather.tomorrow_weather = "green_rain"
	assert_true(_weather.is_rainy(), "绿雨应被视为雨天")

	_weather.tomorrow_weather = "snowy"
	assert_true(_weather.is_rainy(), "雪天应被视为雨天")

func test_is_snowy():
	_weather.tomorrow_weather = "snowy"
	assert_true(_weather.is_snowy(), "雪天应返回true")
	assert_false(_weather.is_snowy(), "非雪天应返回false")

func test_is_sunny():
	_weather.tomorrow_weather = "sunny"
	assert_true(_weather.is_sunny(), "晴天应返回true")
	assert_false(_weather.is_sunny(), "非晴天应返回false")

func test_stamina_modifier():
	# 测试体力消耗修正
	assert_almost_eq(_weather.get_stamina_modifier(), 1.0, 0.001, "晴天体力无修正")

	_weather.today_weather = "rainy"
	assert_almost_eq(_weather.get_stamina_modifier(), 0.9, 0.001, "雨天体力-10%")

	_weather.today_weather = "stormy"
	assert_almost_eq(_weather.get_stamina_modifier(), 0.8, 0.001, "雷雨体力-20%")

	_weather.today_weather = "snowy"
	assert_almost_eq(_weather.get_stamina_modifier(), 0.7, 0.001, "雪天体力-30%")

	_weather.today_weather = "green_rain"
	assert_almost_eq(_weather.get_stamina_modifier(), 0.9, 0.001, "绿雨体力-10%")

func test_mining_yield_modifier():
	# 测试采矿收益修正
	assert_almost_eq(_weather.get_mining_yield_modifier(), 1.0, 0.001, "晴天采矿无修正")

	_weather.today_weather = "rainy"
	assert_almost_eq(_weather.get_mining_yield_modifier(), 0.9, 0.001, "雨天采矿-10%")

	_weather.today_weather = "stormy"
	assert_almost_eq(_weather.get_mining_yield_modifier(), 0.8, 0.001, "雷雨采矿-20%")

func test_fishing_yield_modifier():
	# 测试钓鱼收益修正
	assert_almost_eq(_weather.get_fishing_yield_modifier(), 1.0, 0.001, "晴天钓鱼无修正")

	_weather.today_weather = "rainy"
	assert_almost_eq(_weather.get_fishing_yield_modifier(), 0.9, 0.001, "雨天钓鱼-10%")

	_weather.today_weather = "stormy"
	assert_almost_eq(_weather.get_fishing_yield_modifier(), 0.8, 0.001, "雷雨钓鱼-20%")

	_weather.today_weather = "green_rain"
	assert_almost_eq(_weather.get_fishing_yield_modifier(), 1.1, 0.001, "绿雨钓鱼+10%")

func test_crop_yield_modifier():
	# 测试农作物增产
	assert_almost_eq(_weather.get_crop_yield_modifier(), 1.0, 0.001, "非绿雨无增产")

	_weather.today_weather = "green_rain"
	assert_almost_eq(_weather.get_crop_yield_modifier(), 1.1, 0.001, "绿雨农作物+10%")

func test_auto_watering():
	# 测试自动浇水日
	_weather.today_weather = "sunny"
	assert_false(_weather.is_auto_watering_day(), "晴天不自动浇水")

	_weather.today_weather = "rainy"
	assert_true(_weather.is_auto_watering_day(), "雨天自动浇水")

	_weather.today_weather = "stormy"
	assert_true(_weather.is_auto_watering_day(), "雷雨自动浇水")

	_weather.today_weather = "snowy"
	assert_true(_weather.is_auto_watering_day(), "雪天自动浇水")

	_weather.today_weather = "green_rain"
	assert_true(_weather.is_auto_watering_day(), "绿雨自动浇水")

func test_player_override():
	# 测试玩家天气覆盖
	assert_false(_weather.has_player_override(), "初始无玩家覆盖")

	_weather.set_tomorrow_weather("rainy")
	assert_true(_weather.has_player_override(), "设置后应有玩家覆盖")
	assert_eq(_weather.get_tomorrow_weather(), "rainy", "应设置为指定天气")

	_weather.clear_tomorrow_weather_override()
	assert_false(_weather.has_player_override(), "清除后应无玩家覆盖")

func test_weather_name():
	# 测试天气名称
	assert_eq(_weather.get_weather_name("sunny"), "晴天")
	assert_eq(_weather.get_weather_name("rainy"), "雨天")
	assert_eq(_weather.get_weather_name("stormy"), "暴风雨")
	assert_eq(_weather.get_weather_name("snowy"), "雪天")
	assert_eq(_weather.get_weather_name("windy"), "大风")
	assert_eq(_weather.get_weather_name("green_rain"), "绿雨")
	assert_eq(_weather.get_weather_name("unknown"), "未知")
