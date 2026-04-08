# ADR-0012: 天气特效系统架构

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏需要丰富的天气系统，包括晴天、阴天、雨天、暴风雨、雪天等，每种天气需要视觉和音效反馈。

### 天气类型分析

| 天气 | 粒子 | 音效 | 特殊效果 |
|------|------|------|----------|
| 晴 | 无 | 鸟鸣 | 阴影方向 |
| 阴 | 无 | 风声 | 调暗环境 |
| 雨 | 雨滴 | 雨声 | 湿润效果 |
| 暴风雨 | 暴雨+闪电 | 雷声 | 树摇摆 |
| 雪 | 雪花 | 风雪声 | 积雪 |
| 风 | 落叶 | 风声 | 物体移动 |
| 绿雨 | 绿滴 | 神秘声 | 颜色滤镜 |

## Decision

### 天气目录结构

```
res://
├── assets/
│   ├── particles/
│   │   ├── rain.tres       # GPUParticles2D 资源
│   │   ├── snow.tres
│   │   ├── storm.tres
│   │   ├── wind_leaves.tres
│   │   └── green_rain.tres
│   │
│   └── shaders/
│       ├── rain_overlay.gdshader
│       ├── wet_floor.gdshader
│       └── color_filter.gdshader
│
├── scenes/
│   └── effects/
│       ├── weather/
│       │   ├── weather_manager.tscn
│       │   ├── rain_effect.tscn
│       │   ├── snow_effect.tscn
│       │   └── storm_effect.tscn
│       └── lightnings/
│           └── lightning.tscn
```

### 天气管理器

```gdscript
# systems/weather/weather_manager.gd
class_name WeatherManager
extends Node

static var instance: WeatherManager

# 当前天气
var _current_weather: WeatherType = WeatherType.SUNNY
var _next_weather: WeatherType = WeatherType.SUNNY
var _weather_duration: float = 0.0
var _weather_elapsed: float = 0.0

# 特效节点
var _particle_container: Node2D
var _lightning_timer: Timer

# 天气类型
enum WeatherType {
    SUNNY,
    CLOUDY,
    RAINY,
    STORM,
    SNOWY,
    WINDY,
    GREEN_RAIN
}

func _ready():
    instance = self

    _particle_container = Node2D.new()
    _particle_container.name = "WeatherParticles"
    add_child(_particle_container)

    _lightning_timer = Timer.new()
    _lightning_timer.one_shot = true
    _lightning_timer.timeout.connect(_on_lightning_timer)
    add_child(_lightning_timer)

func _process(delta: float):
    _weather_elapsed += delta
    if _weather_elapsed >= _weather_duration:
        _transition_to_weather(_next_weather)
        _generate_next_weather()

# 切换天气
func set_weather(weather: WeatherType, duration: float = 0.0) -> void:
    _next_weather = weather
    if duration > 0:
        _weather_duration = duration
        _weather_elapsed = 0.0

func _transition_to_weather(new_weather: WeatherType) -> void:
    # 停止当前天气特效
    _clear_weather_effects()

    _current_weather = new_weather

    # 启动新天气特效
    match new_weather:
        WeatherType.SUNNY:
            _setup_sunny()
        WeatherType.CLOUDY:
            _setup_cloudy()
        WeatherType.RAINY:
            _setup_rainy()
        WeatherType.STORM:
            _setup_storm()
        WeatherType.SNOWY:
            _setup_snowy()
        WeatherType.WINDY:
            _setup_windy()
        WeatherType.GREEN_RAIN:
            _setup_green_rain()

    # 通知其他系统
    EventBus.weather_changed.emit(new_weather)

func _clear_weather_effects():
    # 移除所有粒子效果
    for child in _particle_container.get_children():
        child.queue_free()

    _lightning_timer.stop()

    # 重置环境
    if has_node("Environment"):
        get_node("Environment").queue_free()

    # 停止环境音
    AudioManager.stop_ambient()
```

### 天气特效设置

```gdscript
# 各天气特效设置

func _setup_sunny():
    # 明亮环境
    var env = WorldEnvironment.new()
    var light = Environment.new()
    light.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    light.ambient_light_color = Color(1.0, 0.98, 0.95)
    light.ambient_light_energy = 1.2
    env.environment = light
    add_child(env)

func _setup_cloudy():
    # 调暗环境
    var env = WorldEnvironment.new()
    var light = Environment.new()
    light.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    light.ambient_light_color = Color(0.8, 0.82, 0.85)
    light.ambient_light_energy = 0.8
    light.background_mode = Environment.BG_COLOR
    light.background_color = Color(0.5, 0.55, 0.6)
    env.environment = light
    add_child(env)

    AudioManager.play_ambient("res://assets/audio/ambient/wind_light.ogg")

func _setup_rainy():
    # 雨滴粒子
    var rain = GPUParticles2D.new()
    rain.emitting = true
    rain.amount = 500
    rain.lifetime = 1.0
    rain.explosiveness = 0.0
    rain.visibility_rect = Rect2(-1000, -1000, 2000, 2000)

    var material = ParticleProcessMaterial.new()
    material.direction = Vector3(0.1, 1, 0)  # 稍微倾斜
    material.spread = 5.0
    material.initial_velocity_min = 600.0
    material.initial_velocity_max = 800.0
    material.gravity = Vector3(0, -980, 0)
    material.color = Color(0.6, 0.7, 0.9, 0.5)
    rain.process_material = material

    _particle_container.add_child(rain)

    # 湿润地面效果 (shader)
    _apply_wet_overlay()

    AudioManager.play_ambient("res://assets/audio/ambient/rain.ogg")

func _setup_storm():
    # 暴雨
    var storm = GPUParticles2D.new()
    storm.emitting = true
    storm.amount = 1000
    storm.lifetime = 0.8
    storm.explosiveness = 0.1

    var material = ParticleProcessMaterial.new()
    material.direction = Vector3(0.3, 1, 0)
    material.spread = 10.0
    material.initial_velocity_min = 1000.0
    material.initial_velocity_max = 1500.0
    material.gravity = Vector3(0, -1500, 0)
    material.color = Color(0.5, 0.6, 0.8, 0.6)
    storm.process_material = material

    _particle_container.add_child(storm)

    # 闪电
    _start_lightning()

    # 场景调暗
    var env = WorldEnvironment.new()
    var light = Environment.new()
    light.ambient_light_energy = 0.5
    env.environment = light
    add_child(env)

    AudioManager.play_ambient("res://assets/audio/ambient/storm.ogg")

func _setup_snowy():
    var snow = GPUParticles2D.new()
    snow.emitting = true
    snow.amount = 300
    snow.lifetime = 4.0
    snow.explosiveness = 0.0
    snow.visibility_rect = Rect2(-1000, -1000, 2000, 2000)

    var material = ParticleProcessMaterial.new()
    material.direction = Vector3(0.2, 1, 0.1)  # 稍微倾斜飘落
    material.spread = 20.0
    material.initial_velocity_min = 30.0
    material.initial_velocity_max = 60.0
    material.gravity = Vector3(0, -30, 0)
    material.color = Color.WHITE
    snow.process_material = material

    # 使用雪花纹理 (如果有)
    if ResourceLoader.exists("res://assets/particles/snowflake.png"):
        var texture = load("res://assets/particles/snowflake.png")
        snow.texture = texture

    _particle_container.add_child(snow)

    AudioManager.play_ambient("res://assets/audio/ambient/snow.ogg")

func _setup_windy():
    # 飘落物 (树叶、花瓣)
    var leaves = GPUParticles2D.new()
    leaves.emitting = true
    leaves.amount = 50
    leaves.lifetime = 5.0

    var material = ParticleProcessMaterial.new()
    material.direction = Vector3(1, 0.2, 0)  # 横向吹动
    material.spread = 15.0
    material.initial_velocity_min = 100.0
    material.initial_velocity_max = 200.0
    material.gravity = Vector3(0, 20, 0)  # 轻微下落
    material.color = Color(0.6, 0.8, 0.3, 0.8)
    leaves.process_material = material

    _particle_container.add_child(leaves)

    AudioManager.play_ambient("res://assets/audio/ambient/wind_strong.ogg")

func _setup_green_rain():
    var green_rain = GPUParticles2D.new()
    green_rain.emitting = true
    green_rain.amount = 400
    green_rain.lifetime = 1.0

    var material = ParticleProcessMaterial.new()
    material.direction = Vector3(0.1, 1, 0)
    material.spread = 8.0
    material.initial_velocity_min = 500.0
    material.initial_velocity_max = 700.0
    material.gravity = Vector3(0, -980, 0)
    material.color = Color(0.3, 0.9, 0.3, 0.4)  # 绿色
    green_rain.process_material = material

    _particle_container.add_child(green_rain)

    # 绿色滤镜
    _apply_color_filter(Color(0.3, 1.0, 0.3, 0.2))

    AudioManager.play_ambient("res://assets/audio/ambient/green_rain.ogg")
```

### 闪电效果

```gdscript
func _start_lightning():
    # 随机闪电间隔 5-15 秒
    var interval = randf_range(5.0, 15.0)
    _lightning_timer.start(interval)

func _on_lightning_timer():
    _spawn_lightning()

    # 继续闪电
    if _current_weather == WeatherType.STORM:
        _start_lightning()

func _spawn_lightning():
    # 创建闪电精灵
    var lightning = Sprite2D.new()
    lightning.texture = preload("res://assets/effects/lightning.png")
    lightning.global_position = Vector2(randf() * 1000, 0)
    lightning.modulate = Color(1, 1, 1, 0.8)

    add_child(lightning)

    # 闪电闪烁
    var tween = create_tween()
    tween.tween_property(lightning, "modulate:a", 0.0, 0.3)
    await tween.finished
    lightning.queue_free()

    # 屏幕闪白
    _flash_screen()

    # 雷声
    AudioManager.play_sfx("res://assets/audio/sfx/thunder.ogg")

func _flash_screen():
    var flash = ColorRect.new()
    flash.color = Color.WHITE
    flash.anchors_preset = Control.PRESET_FULLRECT
    add_child(flash)

    var tween = create_tween()
    tween.tween_property(flash, "color:a", 0.0, 0.5)
    await tween.finished
    flash.queue_free()
```

### 天气对游戏的影响

```gdscript
# 天气对农场的影响

func _on_weather_changed(weather: WeatherType) -> void:
    match weather:
        WeatherType.RAINY, WeatherType.STORM, WeatherType.GREEN_RAIN:
            # 自动浇水
            EventBus.auto_water_all_plots.emit()
        WeatherType.SNOWY:
            # 作物停止生长
            EventBus.crops_stop_growing.emit()
        WeatherType.STORM:
            # 可能有作物被毁
            EventBus.storm_chance.emit()
```

## Alternatives Considered

### Alternative 1: 每种天气独立场景

- **描述**: 创建多个天气场景，按需切换
- **优点**: 场景独立
- **缺点**: 切换慢，资源重复
- **拒绝理由**: 粒子系统更高效

### Alternative 2: Shader 全屏特效

- **描述**: 使用全屏 shader 实现雨/雪效果
- **优点**: 性能好
- **缺点**: 无法与3D场景交互
- **接受**: 部分效果使用 shader

## Consequences

### Positive
- **视觉效果丰富**: 多种天气各有特色
- **粒子优化**: GPUParticles2D 性能好
- **可扩展**: 易于添加新天气

### Negative
- **资源需求**: 需要多种粒子纹理
- **性能**: 多粒子可能影响低端设备

## Validation Criteria

1. 每种天气视觉特效正确显示
2. 天气切换有过渡动画
3. 闪电和雷声同步
4. 雨天自动浇水正确触发
5. 帧率在可接受范围 (>40fps)
