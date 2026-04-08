extends Resource
class_name TimeConfig

## TimeConfig - 时间系统配置
## 参考: F01 时间/季节系统 GDD

# ============ 游戏时间设置 ============

@export_group("游戏时间")
## 每游戏小时 = 700ms 实时
@export var hour_duration_ms: float = 700.0
## 游戏日开始时间
@export var day_start_hour: int = 6
## 游戏日结束时间 (次日2:00 = 26)
@export var day_end_hour: int = 26
## 午夜警告时间
@export var midnight_warning_hour: int = 24

# ============ 季节设置 ============

@export_group("季节")
## 每季节天数
@export var days_per_season: int = 28
## 季节数量 (4季)
@export var seasons_per_year: int = 4

# ============ 睡眠恢复设置 ============

@export_group("睡眠恢复")
## 默认睡眠恢复率
@export var recovery_rate: float = 0.90
## 24时前就寝恢复率
@export var early_bed_recovery_rate: float = 0.90
## 25时就寝恢复率
@export var late_bed_recovery_rate: float = 0.60
## 强制睡眠恢复率
@export var forced_sleep_recovery_rate: float = 0.50

# ============ 时间速度 ============

@export_group("时间速度")
## 最低时间速度
@export var min_time_scale: float = 0.5
## 最高时间速度
@export var max_time_scale: float = 3.0
## 默认时间速度
@export var default_time_scale: float = 1.0

# ============ 时段定义 ============

@export_group("时段")
## 早晨开始 (小时)
@export var dawn_start: int = 6
## 下午开始
@export var afternoon_start: int = 12
## 傍晚开始
@export var dusk_start: int = 17
## 夜晚开始
@export var night_start: int = 20
