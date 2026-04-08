# ADR-0009: 音频系统架构

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏需要统一的音频系统来管理背景音乐(BGM)、音效(SFX)和语音。要求支持音量控制、音效混叠、多通道管理和平台适配，同时处理Godot 4.6的音频API变化。

### 音频需求分析

| 类型 | 数量 | 特性 |
|------|------|------|
| BGM | 19首 | 循环播放、淡入淡出 |
| SFX | 80+ | 即时播放、可打断 |
| 语音 | 20+ | NPC对话语音 |
| 环境音 | 10+ | 场景环境音 |

## Decision

### 音频目录结构

```
res://
├── assets/
│   └── audio/
│       ├── bgm/
│       │   ├── farm_morning.ogg
│       │   ├── town_day.ogg
│       │   ├── mine_ambient.ogg
│       │   └── ...
│       ├── sfx/
│       │   ├── ui/
│       │   │   ├── button_click.ogg
│       │   │   ├── menu_open.ogg
│       │   │   └── ...
│       │   ├── farm/
│       │   │   ├── plant_seed.ogg
│       │   │   ├── harvest_crop.ogg
│       │   │   └── ...
│       │   ├── combat/
│       │   │   ├── sword_swipe.ogg
│       │   │   ├── hit_enemy.ogg
│       │   │   └── ...
│       │   └── misc/
│       │       ├── coin.ogg
│       │       ├── notification.ogg
│       │       └── ...
│       ├── voice/
│       │   ├── npc/
│       │   │   ├── merchant_greet.ogg
│       │   │   └── ...
│       │   └── player/
│       │       └── ...
│       └── ambient/
│           ├── rain.ogg
│           ├── birds.ogg
│           └── ...
```

### AudioManager 设计

```gdscript
# autoload/audio_manager.gd
class_name AudioManager
extends Node

static var instance: AudioManager

# 音频总线配置 (与 project.godot 中的 AudioBusLayout 对应)
enum Bus {
    MASTER = 0,
    BGM = 1,
    SFX = 2,
    VOICE = 3,
    AMBIENT = 4
}

# 音量设置 (0.0 - 1.0)
var _volumes: Dictionary = {
    Bus.MASTER: 1.0,
    Bus.BGM: 0.7,
    Bus.SFX: 0.8,
    Bus.VOICE: 1.0,
    Bus.AMBIENT: 0.5
}

# 当前播放
var _current_bgm: AudioStreamPlayer = null
var _bgm_fade_tween: Tween = null
var _ambient_player: AudioStreamPlayer = null

# 预加载的音效
var _sfx_cache: Dictionary = {}

func _ready():
    instance = self
    _preload_sfx()

func _preload_sfx():
    # 预加载常用音效
    var common_sfx = [
        "res://assets/audio/sfx/ui/button_click.ogg",
        "res://assets/audio/sfx/misc/coin.ogg",
        "res://assets/audio/sfx/misc/notification.ogg"
    ]
    for path in common_sfx:
        if ResourceLoader.exists(path):
            _sfx_cache[path] = load(path)

# ============ 公开 API ============

# 设置音量 (0.0 - 1.0)
func set_volume(bus: Bus, volume: float) -> void:
    _volumes[bus] = clamp(volume, 0.0, 1.0)
    AudioServer.set_bus_volume_db(bus, linear_to_db(_volumes[bus]))

func get_volume(bus: Bus) -> float:
    return _volumes.get(bus, 1.0)

# 静音控制
func set_muted(muted: bool) -> void:
    AudioServer.set_bus_mute(Bus.MASTER, muted)

func is_muted() -> bool:
    return AudioServer.is_bus_muted(Bus.MASTER)

# ============ BGM 控制 ============

func play_bgm(bgm_path: String, fade_duration: float = 1.0) -> void:
    if not ResourceLoader.exists(bgm_path):
        push_warning("AudioManager: BGM not found: " + bgm_path)
        return

    var stream = load(bgm_path)

    if _current_bgm == null:
        _current_bgm = AudioStreamPlayer.new()
        _current_bgm.bus = AudioServer.get_bus_name(Bus.BGM)
        add_child(_current_bgm)

    # 淡出当前BGM
    if _bgm_fade_tween:
        _bgm_fade_tween.kill()

    _bgm_fade_tween = create_tween()

    if _current_bgm.playing:
        _bgm_fade_tween.tween_property(_current_bgm, "volume_db", -80, fade_duration)
        await _bgm_fade_tween.finished
        _current_bgm.stop()

    # 播放新BGM
    _current_bgm.stream = stream
    _current_bgm.volume_db = -80
    _current_bgm.play()

    _bgm_fade_tween = create_tween()
    _bgm_fade_tween.tween_property(_current_bgm, "volume_db", 0, fade_duration)

func stop_bgm(fade_duration: float = 1.0) -> void:
    if _current_bgm == null or not _current_bgm.playing:
        return

    _bgm_fade_tween = create_tween()
    _bgm_fade_tween.tween_property(_current_bgm, "volume_db", -80, fade_duration)
    await _bgm_fade_tween.finished
    _current_bgm.stop()

func pause_bgm() -> void:
    if _current_bgm:
        _current_bgm.stream_paused = true

func resume_bgm() -> void:
    if _current_bgm:
        _current_bgm.stream_paused = false

# ============ SFX 控制 ============

func play_sfx(sfx_path: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
    if not ResourceLoader.exists(sfx_path):
        push_warning("AudioManager: SFX not found: " + sfx_path)
        return

    var player = AudioStreamPlayer.new()
    player.bus = AudioServer.get_bus_name(Bus.SFX)
    player.volume_db = volume_db
    player.pitch_scale = pitch_scale

    # 尝试使用缓存
    if _sfx_cache.has(sfx_path):
        player.stream = _sfx_cache[sfx_path]
    else:
        player.stream = load(sfx_path)

    add_child(player)
    player.play()
    player.finished.connect(func(): player.queue_free())

func play_sfx_oneshot(sfx_path: String, volume_scale: float = 1.0) -> void:
    # 使用Bus对应的Player播放，适用于频繁触发的音效
    var player = AudioStreamPlayer2D.new() if self is Node2D else AudioStreamPlayer.new()
    player.bus = AudioServer.get_bus_name(Bus.SFX)
    player.volume_db = linear_to_db(volume_scale)

    if ResourceLoader.exists(sfx_path):
        player.stream = load(sfx_path)
        add_child(player)
        player.play()
        player.finished.connect(func(): player.queue_free())

# UI 常用音效
func play_ui_click() -> void:
    play_sfx("res://assets/audio/sfx/ui/button_click.ogg")

func play_ui_open() -> void:
    play_sfx("res://assets/audio/sfx/ui/menu_open.ogg")

func play_ui_close() -> void:
    play_sfx("res://assets/audio/sfx/ui/menu_close.ogg")

# ============ 语音控制 ============

func play_voice(voice_path: String) -> void:
    if not ResourceLoader.exists(voice_path):
        return

    var player = AudioStreamPlayer.new()
    player.bus = AudioServer.get_bus_name(Bus.VOICE)
    player.stream = load(voice_path)
    add_child(player)
    player.play()
    player.finished.connect(func(): player.queue_free())

# ============ 环境音控制 ============

func play_ambient(ambient_path: String, fade_duration: float = 2.0) -> void:
    if not ResourceLoader.exists(ambient_path):
        return

    if _ambient_player == null:
        _ambient_player = AudioStreamPlayer.new()
        _ambient_player.bus = AudioServer.get_bus_name(Bus.AMBIENT)
        _ambient_player.volume = 0
        add_child(_ambient_player)

    var stream = load(ambient_path)
    _ambient_player.stream = stream
    _ambient_player.play()

    var tween = create_tween()
    tween.tween_property(_ambient_player, "volume", _volumes[Bus.AMBIENT], fade_duration)

func stop_ambient(fade_duration: float = 2.0) -> void:
    if _ambient_player == null or not _ambient_player.playing:
        return

    var tween = create_tween()
    tween.tween_property(_ambient_player, "volume", 0.0, fade_duration)
    await tween.finished
    _ambient_player.stop()

# ============ 场景适配 ============

func on_scene_changed(scene_name: String) -> void:
    # 根据场景切换BGM
    match scene_name:
        "farm":
            play_bgm("res://assets/audio/bgm/farm_morning.ogg")
        "town":
            play_bgm("res://assets/audio/bgm/town_day.ogg")
        "mine":
            play_bgm("res://assets/audio/bgm/mine_ambient.ogg")
        _:
            pass

    # 场景环境音
    match scene_name:
        "rain":
            play_ambient("res://assets/audio/ambient/rain.ogg")
        "forest":
            play_ambient("res://assets/audio/ambient/birds.ogg")
        _:
            stop_ambient()
```

### AudioBusLayout 配置

在 `project.godot` 中配置音频总线：

```ini
[audio]

driver="ALSA"  # Linux
; driver="WASAPI"  # Windows
; driver="AudioUnit"  # macOS

[audio_buses]

layout=[Object("AudioBusLayout")]

bus/0/name="Master"
bus/0/volume_db=0.0
bus/0/send=""

bus/1/name="BGM"
bus/1/volume_db=0.0
bus/1/send="Master"

bus/2/name="SFX"
bus/2/volume_db=0.0
bus/2/send="Master"

bus/3/name="Voice"
bus/3/volume_db=0.0
bus/3/send="Master"

bus/4/name="Ambient"
bus/4/volume_db=0.0
bus/4/send="Master"
```

### 音效分类常量

```gdscript
# systems/audio/sfx_paths.gd
class_name SFXPaths
extends Node

# UI 音效
const UI_CLICK = "res://assets/audio/sfx/ui/button_click.ogg"
const UI_OPEN = "res://assets/audio/sfx/ui/menu_open.ogg"
const UI_CLOSE = "res://assets/audio/sfx/ui/menu_close.ogg"

# 农场音效
const FARM_TILL = "res://assets/audio/sfx/farm/till_soil.ogg"
const FARM_PLANT = "res://assets/audio/sfx/farm/plant_seed.ogg"
const FARM_WATER = "res://assets/audio/sfx/farm/water.ogg"
const FARM_HARVEST = "res://assets/audio/sfx/farm/harvest_crop.ogg"

# 物品音效
const ITEM_PICKUP = "res://assets/audio/sfx/misc/item_pickup.ogg"
const ITEM_DROP = "res://assets/audio/sfx/misc/item_drop.ogg"
const ITEM_COIN = "res://assets/audio/sfx/misc/coin.ogg"

# 通知音效
const NOTIFICATION = "res://assets/audio/sfx/misc/notification.ogg"
const ACHIEVEMENT = "res://assets/audio/sfx/misc/achievement.ogg"
```

## Alternatives Considered

### Alternative 1: Godot AudioStreamPlayer 单例

- **描述**: 每个音频类型一个 Player
- **优点**: 实现简单
- **缺点**: 无法同时播放多个同类型音效
- **拒绝理由**: SFX需要同时播放多个

### Alternative 2: 使用第三方音频库 (FMOD/Wwise)

- **描述**: 集成专业音频中间件
- **优点**: 功能强大，性能优化
- **缺点**: 增加依赖，复杂度高
- **拒绝理由**: 对于本项目过于复杂

## Consequences

### Positive
- **统一管理**: 所有音频通过 AudioManager
- **性能优化**: SFX 缓存减少加载
- **平台适配**: 总线配置适配各平台

### Negative
- **单点故障**: AudioManager 故障影响所有音频
- **内存占用**: 预加载缓存占用内存

## Validation Criteria

1. BGM 淡入淡出平滑
2. 多个 SFX 可同时播放
3. 场景切换正确切换 BGM
4. 音量设置立即生效
5. 音频总线在所有平台正确工作
