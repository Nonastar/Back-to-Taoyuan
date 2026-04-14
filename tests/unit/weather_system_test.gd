extends "res://tests/unit/test_base.gd"

## WeatherSystem单元测试
## 注意：由于测试运行器为每个文件创建一个实例并运行所有测试方法，
## 每个测试必须自行重置状态，防止测试间污染

var _weather: Node = null

func _reset_all_state():
	"""重置所有状态到初始值"""
	_weather.today_weather = "sunny"
	_weather.tomorrow_weather = "sunny"
	_weather.has_player_override = false
	_weather.player_override_weather = ""
	_weather.is_green_rain_active = false

func before_each():
	_weather = Node.new()
	_weather.set_script(load("res://src/scripts/autoload/weather_system.gd"))
	_weather._initialized = false
	_weather._initialize()

func after_each():
	_weather._initialized = false
	_weather.free()

func test_initial_weather():
	_reset_all_state()
	assert_eq(_weather.get_today_weather(), "sunny", "初始天气应为晴天")
	assert_eq(_weather.get_tomorrow_weather(), "sunny", "初始预报应为晴天")

func test_is_rainy():
	_reset_all_state()
	_weather.today_weather = "sunny"
	assert_false(_weather.is_rainy(), "晴天不应是雨天")

	_weather.today_weather = "rainy"
	assert_true(_weather.is_rainy(), "雨天应返回true")

	_weather.today_weather = "stormy"
	assert_true(_weather.is_stormy(), "雷雨应返回true")

	_weather.today_weather = "green_rain"
	assert_true(_weather.is_rainy(), "绿雨应被视为雨天")

	_weather.today_weather = "snowy"
	assert_true(_weather.is_rainy(), "雪天应被视为雨天")

func test_is_snowy():
	_reset_all_state()
	_weather.today_weather = "snowy"
	assert_true(_weather.is_snowy(), "雪天应返回true")

	_weather.today_weather = "sunny"
	assert_false(_weather.is_snowy(), "非雪天应返回false")

func test_is_sunny():
	_reset_all_state()
	_weather.today_weather = "sunny"
	assert_true(_weather.is_sunny(), "晴天应返回true")

	_weather.today_weather = "rainy"
	assert_false(_weather.is_sunny(), "非晴天应返回false")

func test_stamina_modifier():
	_reset_all_state()
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
	_reset_all_state()
	assert_almost_eq(_weather.get_mining_yield_modifier(), 1.0, 0.001, "晴天采矿无修正")

	_weather.today_weather = "rainy"
	assert_almost_eq(_weather.get_mining_yield_modifier(), 0.9, 0.001, "雨天采矿-10%")

	_weather.today_weather = "stormy"
	assert_almost_eq(_weather.get_mining_yield_modifier(), 0.8, 0.001, "雷雨采矿-20%")

func test_fishing_yield_modifier():
	_reset_all_state()
	assert_almost_eq(_weather.get_fishing_yield_modifier(), 1.0, 0.001, "晴天钓鱼无修正")

	_weather.today_weather = "rainy"
	assert_almost_eq(_weather.get_fishing_yield_modifier(), 0.9, 0.001, "雨天钓鱼-10%")

	_weather.today_weather = "stormy"
	assert_almost_eq(_weather.get_fishing_yield_modifier(), 0.8, 0.001, "雷雨钓鱼-20%")

	_weather.today_weather = "green_rain"
	assert_almost_eq(_weather.get_fishing_yield_modifier(), 1.1, 0.001, "绿雨钓鱼+10%")

func test_crop_yield_modifier():
	_reset_all_state()
	assert_almost_eq(_weather.get_crop_yield_modifier(), 1.0, 0.001, "晴天无增产")

	_weather.today_weather = "green_rain"
	assert_almost_eq(_weather.get_crop_yield_modifier(), 1.1, 0.001, "绿雨增产+10%")

func test_auto_watering():
	_reset_all_state()
	_weather.today_weather = "sunny"
	assert_false(_weather.is_auto_watering_day(), "晴天不自动浇水")

	_weather.today_weather = "rainy"
	assert_true(_weather.is_auto_watering_day(), "雨天自动浇水")

	_weather.today_weather = "snowy"
	assert_true(_weather.is_auto_watering_day(), "雪天自动浇水")

	_weather.today_weather = "green_rain"
	assert_true(_weather.is_auto_watering_day(), "绿雨自动浇水")

func test_player_override():
	_reset_all_state()
	assert_false(_weather.has_player_weather_override(), "初始无玩家覆盖")

	_weather.set_tomorrow_weather("rainy")
	assert_true(_weather.has_player_weather_override(), "设置后应有玩家覆盖")
	assert_eq(_weather.get_tomorrow_weather(), "rainy", "应设置为指定天气")

	_weather.clear_tomorrow_weather_override()
	assert_false(_weather.has_player_weather_override(), "清除后应无玩家覆盖")

func test_weather_name():
	_reset_all_state()
	assert_eq(_weather.get_weather_name("sunny"), "晴天")
	assert_eq(_weather.get_weather_name("rainy"), "雨天")
	assert_eq(_weather.get_weather_name("stormy"), "暴风雨")
	assert_eq(_weather.get_weather_name("snowy"), "雪天")
	assert_eq(_weather.get_weather_name("windy"), "大风")
	assert_eq(_weather.get_weather_name("green_rain"), "绿雨")
	assert_eq(_weather.get_weather_name("unknown"), "未知")
