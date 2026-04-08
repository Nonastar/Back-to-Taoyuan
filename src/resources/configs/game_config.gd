extends Resource
class_name GameConfig

## GameConfig - 主游戏配置
## 所有可调整的游戏参数集中管理

# ============ 版本信息 ============

@export_group("版本信息")
@export var config_version: int = 1
@export var game_version: String = "0.1.0"

# ============ 窗口设置 ============

@export_group("窗口设置")
@export var default_window_width: int = 1280
@export var default_window_height: int = 720
@export var vsync_enabled: bool = true
@export var fullscreen: bool = false

# ============ 性能设置 ============

@export_group("性能设置")
@export var target_fps: int = 60
@export var max_draw_calls: int = 200

# ============ 存档设置 ============

@export_group("存档设置")
@export var max_save_slots: int = 3
@export var auto_save_enabled: bool = true
@export var auto_save_interval_minutes: int = 5
