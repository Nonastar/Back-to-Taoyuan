# ADR-0014: 迷你游戏框架

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
游戏包含11个迷你游戏(M01-M11)，需要统一的框架来管理游戏的启动、暂停、结束、计分和奖励发放。

### 迷你游戏分析

| ID | 游戏 | 类型 | 核心机制 |
|----|------|------|----------|
| M01 | 钓鱼小游戏 | 时机 | 力度条+时机 |
| M02 | 德州扑克 | 运气 | 牌面组合 |
| M03 | 左轮赌盘 | 运气 | 概率 |
| M04 | 赛龙舟 | 节奏 | 节拍输入 |
| M05 | 钓鱼比赛 | 竞赛 | 积分排名 |
| M06 | 猜灯谜 | 问答 | 选择 |
| M07 | 投壶 | 物理 | 抛物线 |
| M08 | 包饺子 | 模拟 | 定时/轨迹 |
| M09 | 烟花秀 | 创意 | 角度/时机 |
| M10 | 品茶会 | 品鉴 | 匹配 |
| M11 | 放风筝 | 操控 | 风向/高度 |

## Decision

### 迷你游戏目录结构

```
res://
├── scenes/
│   └── minigames/
│       ├── minigame_manager.tscn    # 统一管理器
│       ├── base_minigame.gd         # 基类
│       │
│       ├── fishing/
│       │   ├── fishing_minigame.tscn
│       │   └── fishing_controller.gd
│       │
│       ├── poker/
│       │   ├── poker_minigame.tscn
│       │   └── poker_controller.gd
│       │
│       └── [其他游戏]/
│
├── resources/
│   └── minigames/
│       ├── minigame_registry.gd
│       ├── reward_templates.gd
│       └── leaderboard_data.gd
```

### 迷你游戏基类

```gdscript
# scenes/minigames/base_minigame.gd
class_name BaseMinigame
extends Node2D

# 状态
enum GameState { LOADING, READY, PLAYING, PAUSED, ENDED }
var _state: GameState = GameState.LOADING

# 游戏配置
@export var minigame_id: String = ""
@export var game_duration: float = 0.0  # 0 = 无限制
@export var allow_pause: bool = true

# 分数和奖励
var _score: int = 0
var _time_remaining: float = 0.0
var _rewards: Dictionary = {}

# 信号
signal state_changed(state: GameState)
signal score_updated(score: int)
signal game_ended(final_score: int, rewards: Dictionary)
signal time_warning(seconds: float)

func _ready():
    _state = GameState.LOADING
    state_changed.emit(_state)

# ============ 状态控制 ============

func start_game() -> void:
    if _state != GameState.READY:
        return

    _state = GameState.PLAYING
    state_changed.emit(_state)

    if game_duration > 0:
        _time_remaining = game_duration
        _start_timer()

    _on_game_started()

func pause_game() -> void:
    if not allow_pause or _state != GameState.PLAYING:
        return

    _state = GameState.PAUSED
    state_changed.emit(_state)
    get_tree().paused = true

func resume_game() -> void:
    if _state != GameState.PAUSED:
        return

    _state = GameState.PLAYING
    state_changed.emit(_state)
    get_tree().paused = false

func end_game() -> void:
    _state = GameState.ENDED
    state_changed.emit(_state)

    # 计算奖励
    _calculate_rewards()

    # 发送结束信号
    game_ended.emit(_score, _rewards)

    # 清理
    _on_game_ended()

func _start_timer() -> void:
    var timer = Timer.new()
    timer.wait_time = 1.0
    timer.timeout.connect(_on_timer_tick)
    add_child(timer)
    timer.start()

func _on_timer_tick() -> void:
    _time_remaining -= 1.0

    if _time_remaining <= 10.0 and _time_remaining > 0:
        time_warning.emit(_time_remaining)

    if _time_remaining <= 0:
        end_game()

# ============ 分数系统 ============

func add_score(points: int, reason: String = "") -> void:
    _score += points
    score_updated.emit(_score)
    EventBus.minigame_score_changed.emit(minigame_id, _score, reason)

func set_score(value: int) -> void:
    _score = value
    score_updated.emit(_score)

# ============ 子类重写 ============

func _on_game_started() -> void:
    # 子类实现：初始化游戏逻辑
    pass

func _on_game_ended() -> void:
    # 子类实现：清理游戏
    pass

func get_high_score() -> int:
    return SaveManager.get_minigame_high_score(minigame_id)

func save_high_score() -> void:
    if _score > get_high_score():
        SaveManager.set_minigame_high_score(minigame_id, _score)
```

### 迷你游戏管理器

```gdscript
# scenes/minigames/minigame_manager.gd
class_name MinigameManager
extends CanvasLayer

static var instance: MinigameManager

# 预加载场景
var _minigame_scenes: Dictionary = {}
var _current_game: BaseMinigame = null

# UI
@onready var loading_screen: Control = $LoadingScreen
@onready var hud: Control = $HUD
@onready var pause_menu: Control = $PauseMenu
@onready var result_screen: Control = $ResultScreen

func _ready():
    instance = self
    _preload_minigames()
    _hide_all_ui()

func _preload_minigames():
    var minigames = [
        "fishing",
        "poker",
        "buckshot_roulette",
        "dragon_boat",
        "fishing_contest",
        "lantern_riddle",
        "pot_throwing",
        "dumpling_making",
        "firework_show",
        "tea_contest",
        "kite_flying"
    ]

    for game_id in minigames:
        var path = "res://scenes/minigames/%s/%s_minigame.tscn" % [game_id, game_id]
        if ResourceLoader.exists(path):
            _minigame_scenes[game_id] = load(path)

# ============ 游戏启动 ============

func start_minigame(game_id: String) -> void:
    if not _minigame_scenes.has(game_id):
        push_error("MinigameManager: Unknown minigame: " + game_id)
        return

    _show_loading()

    # 实例化游戏
    var scene = _minigame_scenes[game_id]
    _current_game = scene.instantiate()
    add_child(_current_game)

    # 连接信号
    _current_game.state_changed.connect(_on_game_state_changed)
    _current_game.game_ended.connect(_on_game_ended)
    _current_game.score_updated.connect(_on_score_updated)

    # 延迟启动
    await get_tree().create_timer(0.5).timeout
    _current_game.start_game()

func exit_minigame() -> void:
    if _current_game:
        _current_game.queue_free()
        _current_game = null

    _hide_all_ui()

    # 返回游戏世界
    SceneManager.reload_current_world()

# ============ UI控制 ============

func _show_loading():
    loading_screen.visible = true

func _hide_loading():
    loading_screen.visible = false

func _show_hud():
    hud.visible = true

func _hide_hud():
    hud.visible = false

func _show_pause_menu():
    pause_menu.visible = true

func _hide_pause_menu():
    pause_menu.visible = false

func _show_result_screen(score: int, rewards: Dictionary):
    result_screen.visible = true
    result_screen.show_results(score, rewards)

func _hide_result_screen():
    result_screen.visible = false

func _hide_all_ui():
    loading_screen.visible = false
    hud.visible = false
    pause_menu.visible = false
    result_screen.visible = false

# ============ 信号处理 ============

func _on_game_state_changed(state: BaseMinigame.GameState):
    match state:
        BaseMinigame.GameState.READY:
            _hide_loading()
            _show_hud()
        BaseMinigame.GameState.PLAYING:
            pass
        BaseMinigame.GameState.PAUSED:
            _show_pause_menu()
        BaseMinigame.GameState.ENDED:
            pass

func _on_game_ended(final_score: int, rewards: Dictionary):
    _hide_hud()
    _show_result_screen(final_score, rewards)

func _on_score_updated(score: int):
    hud.update_score(score)

# ============ 输入处理 ============

func _input(event: InputEvent):
    if _current_game == null:
        return

    if event.is_action_pressed("ui_cancel"):
        match _current_game._state:
            BaseMinigame.GameState.PLAYING:
                _current_game.pause_game()
            BaseMinigame.GameState.PAUSED:
                _current_game.resume_game()
```

### 结果界面

```gdscript
# scenes/minigames/ui/result_screen.gd
class_name ResultScreen
extends Control

@onready var score_label: Label = $VBox/ScoreLabel
@onready var reward_list: VBoxContainer = $VBox/RewardList
@onready var high_score_label: Label = $VBox/HighScoreLabel
@onready var continue_button: Button = $VBox/ContinueButton
@onready var retry_button: Button = $VBox/RetryButton

var _current_game_id: String = ""

func _ready():
    continue_button.pressed.connect(_on_continue)
    retry_button.pressed.connect(_on_retry)

func show_results(score: int, rewards: Dictionary) -> void:
    score_label.text = "得分: %d" % score

    # 显示奖励
    reward_list.clear()
    for reward_id in rewards:
        var amount = rewards[reward_id]
        var item_name = ItemDatabase.get_item(reward_id).display_name
        var label = Label.new()
        label.text = "%s x%d" % [item_name, amount]
        reward_list.add_child(label)

    # 高分提示
    var high_score = SaveManager.get_minigame_high_score(_current_game_id)
    if score >= high_score:
        high_score_label.text = "新纪录!"
        high_score_label.modulate = Color.YELLOW
    else:
        high_score_label.text = "最高分: %d" % high_score
        high_score_label.modulate = Color.WHITE

func _on_continue():
    MinigameManager.exit_minigame()

func _on_retry():
    get_parent().start_minigame(_current_game_id)
```

### 奖励系统

```gdscript
# resources/minigames/reward_templates.gd
class_name RewardTemplates
extends Resource

# 根据分数段位发放奖励
static func calculate_rewards(game_id: String, score: int) -> Dictionary:
    var rewards = {}

    match game_id:
        "fishing":
            rewards = _fishing_rewards(score)
        "lantern_riddle":
            rewards = _riddle_rewards(score)
        "dragon_boat":
            rewards = _dragon_boat_rewards(score)
        _:
            rewards = _default_rewards(score)

    return rewards

static func _fishing_rewards(score: int) -> Dictionary:
    if score >= 500:
        return {"item_gold_fish": 3, "money": 500}
    elif score >= 300:
        return {"item_silver_fish": 2, "money": 300}
    elif score >= 100:
        return {"item_bronze_fish": 1, "money": 100}
    else:
        return {"money": 50}

static func _riddle_rewards(score: int) -> Dictionary:
    if score >= 10:  # 全对
        return {"item_lantern_wisdom": 1, "money": 200}
    elif score >= 7:
        return {"item_lantern_wisdom": 1, "money": 100}
    else:
        return {"money": 50}

static func _default_rewards(score: int) -> Dictionary:
    return {"money": score}
```

### 排行榜数据

```gdscript
# resources/minigames/leaderboard_data.gd
class_name LeaderboardData
extends Resource

@export var entries: Array[LeaderboardEntry] = []

[System.Serializable]
class LeaderboardEntry:
    @export var rank: int = 0
    @export var player_name: String = ""
    @export var score: int = 0
    @export var date: String = ""

static func get_top_scores(game_id: String, limit: int = 10) -> Array[LeaderboardEntry]:
    # 从存档读取排行榜
    var data = SaveManager.get_leaderboard(game_id)
    var entries = []
    for i in range(min(limit, data.size())):
        entries.append(data[i])
    return entries

static func is_high_score(game_id: String, score: int) -> bool:
    var current = SaveManager.get_minigame_high_score(game_id)
    return score > current
```

## 各游戏实现指南

### M01 钓鱼小游戏

```gdscript
# scenes/minigames/fishing/fishing_controller.gd
class_name FishingMinigame
extends BaseMinigame

@onready var fish_bar: TextureRect = $UI/FishBar
@onready var power_bar: TextureRect = $UI/PowerBar

var _fish_position: float = 0.5
var _fish_direction: float = 1.0
var _fish_speed: float = 0.01

func _process(delta: float):
    if _state != GameState.PLAYING:
        return

    # 移动鱼的位置
    _fish_position += _fish_direction * _fish_speed * delta * 60
    if _fish_position > 1.0 or _fish_position < 0.0:
        _fish_direction *= -1

    fish_bar.value = _fish_position * 100

func _on_input_pressed():
    # 检查是否在目标区域内
    var target_center = 50.0  # 目标中心
    var tolerance = 10.0

    if abs(_fish_position * 100 - target_center) < tolerance:
        add_score(100, "Perfect catch")
    else:
        add_score(50, "Good catch")
```

### M02 德州扑克

参考GDD中M02的设计，实现完整的扑克逻辑。

## Alternatives Considered

### Alternative 1: 每个游戏完全独立

- **描述**: 每个游戏独立场景，无基类
- **优点**: 完全自由
- **缺点**: 代码重复，难以维护
- **拒绝理由**: 11个游戏需要统一框架

### Alternative 2: 使用插件系统

- **描述**: 游戏作为插件动态加载
- **优点**: 可热插拔
- **缺点**: 过度工程化
- **拒绝理由**: 不需要运行时加载

## Consequences

### Positive
- **统一框架**: 11个游戏共享基类
- **奖励一致**: 统一的奖励计算
- **易于扩展**: 新游戏只需实现基类

### Negative
- **约束**: 子类需要遵循框架
- **学习成本**: 需要理解基类结构

## Validation Criteria

1. 所有游戏通过 MinigameManager 启动
2. 分数系统统一计算
3. 奖励正确发放
4. 排行榜数据正确保存
5. 暂停/恢复功能正常
