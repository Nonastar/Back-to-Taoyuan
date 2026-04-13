extends CanvasLayer

## FishingMiniGame - 钓鱼小游戏
## 按照 design/gdd/minigames/fishing-mini-game.md 设计文档实现
##
## 包含两个核心机制：
## 1. 时机小游戏：观察浮标状态，在最佳时机提竿
## 2. 搏鱼小游戏：保持鱼在绿色区域，消耗鱼的力量条

# ============ 枚举 ============

## 小游戏状态
enum State {
	IDLE,       ## 钓鱼小游戏未激活
	WAITING,    ## 浮标浮动，等待鱼咬钩
	BITE,       ## 浮标下沉，进入时机判定
	REELING,    ## 提竿中
	FISHING,    ## 搏鱼进行中
	SUCCESS,    ## 捕获成功
	FAILED      ## 捕获失败
}

## 浮标状态
enum BobberState {
	FLOATING,   ## 抛竿后，轻微上下浮动
	BOBBING,    ## 鱼在试探，轻微下沉
	SINKING,    ## 鱼咬钩，快速下沉
	DIVING      ## 鱼咬钩后，浮标完全消失
}

## 时机判定结果
enum TimingResult {
	NONE,       ## 无判定
	PERFECT,    ## 完美时机
	NORMAL,     ## 正常时机
	TOO_EARLY,  ## 太早
	TOO_LATE    ## 太晚
}

## 区域类型
enum ZoneType {
	SAFE,       ## 安全区域 (30-70%)
	TRANSITION, ## 过渡区域 (20-30%, 70-80%)
	DANGER      ## 危险区域 (0-20%, 80-100%)
}

# ============ 常量：时机小游戏 ============

## 时机小游戏参数
const BASE_BITE_TIME_MIN: float = 2.0   ## 基础咬钩时间最小值(秒)
const BASE_BITE_TIME_MAX: float = 10.0 ## 基础咬钩时间最大值(秒)
const BASE_TIMING_WINDOW: float = 1.0  ## 基础最佳时机窗口(秒)
const TIMING_WINDOW_PER_DIFFICULTY: float = 0.1 ## 难度每级增加的窗口时间
const MAX_TIMING_WINDOW: float = 2.0   ## 最大时机窗口(秒)
const SINK_TRIGGER_THRESHOLD: float = 0.7 ## 浮标下沉触发窗口的阈值(70%)

# ============ 常量：搏鱼小游戏 ============

## 区域边界
const SAFE_ZONE_START: float = 0.30  ## 安全区起始(30%)
const SAFE_ZONE_END: float = 0.70    ## 安全区结束(70%)
const TRANSITION_ZONE_SIZE: float = 0.10 ## 过渡区大小(10%)

## 消耗和增长数值(每帧，60fps)
const STAMINA_DRAIN_SAFE: float = 0.05      ## 安全区力量消耗/帧
const STAMINA_DRAIN_TRANSITION: float = 0.03 ## 过渡区力量消耗/帧
const STAMINA_DRAIN_DANGER: float = 0.02    ## 危险区力量消耗/帧

const PRESSURE_RATE_SAFE: float = -0.002    ## 安全区压力变化/帧(负=减压)
const PRESSURE_RATE_TRANSITION: float = 0.005 ## 过渡区压力变化/帧
const PRESSURE_RATE_DANGER: float = 0.015    ## 危险区压力变化/帧

## 玩家速度
const PLAYER_BASE_SPEED: float = 0.5  ## 基础速度(50% 宽度/秒)
const FISH_NATURAL_DRIFT: float = 0.1  ## 鱼的自然拉力(无操作时趋向危险区)

## 搏鱼时间限制
const MAX_FIGHT_TIME: float = 60.0     ## 最大搏鱼时间(秒)

# ============ 常量：辅助模式 ============

## 辅助模式区域边界（比普通模式大50%）
const ASSIST_SAFE_ZONE_START: float = 0.25  ## 安全区起始(25%)
const ASSIST_SAFE_ZONE_END: float = 0.75    ## 安全区结束(75%)
const ASSIST_TRANSITION_ZONE_SIZE: float = 0.10 ## 过渡区大小(10%)

## 辅助模式消耗和增长（更温和）
const ASSIST_STAMINA_DRAIN_SAFE: float = 0.07      ## 安全区力量消耗/帧（更快消耗=更容易成功）
const ASSIST_STAMINA_DRAIN_TRANSITION: float = 0.05 ## 过渡区力量消耗/帧
const ASSIST_STAMINA_DRAIN_DANGER: float = 0.04    ## 危险区力量消耗/帧

const ASSIST_PRESSURE_RATE_SAFE: float = -0.004    ## 安全区压力变化/帧(负=快速减压)
const ASSIST_PRESSURE_RATE_TRANSITION: float = 0.003 ## 过渡区压力变化/帧
const ASSIST_PRESSURE_RATE_DANGER: float = 0.010    ## 危险区压力变化/帧

## 辅助模式玩家速度（更快）
const ASSIST_PLAYER_BASE_SPEED: float = 0.7  ## 基础速度(70% 宽度/秒)

## 辅助模式时机窗口（更大）
const ASSIST_TIMING_WINDOW: float = 1.5  ## 辅助模式时机窗口(秒)
const ASSIST_SINK_TRIGGER_THRESHOLD: float = 0.5 ## 浮标下沉触发窗口的阈值(50%，更早触发)

# ============ 节点引用 ============

## UI节点
var _background: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _instruction_label: Label
var _bobber_bar: ProgressBar
var _fight_progress_bg: ColorRect
var _fish_indicator: Label
var _stamina_label: Label
var _stamina_bar: ProgressBar
var _pressure_label: Label
var _pressure_bar: ProgressBar
var _result_label: Label
var _reel_button: Button
var _cancel_button: Button
var _left_button: Button
var _right_button: Button
var _hint_label: Label

## 区域绘制
var _zone_safe_left: ColorRect
var _zone_safe_right: ColorRect
var _zone_transition_left: ColorRect
var _zone_transition_right: ColorRect

# ============ 状态变量 ============

var _current_state: State = State.IDLE
var _bobber_state: BobberState = BobberState.FLOATING
var _timing_result: TimingResult = TimingResult.NONE

## 时机小游戏状态
var _bite_timer: float = 0.0        ## 咬钩倒计时
var _timing_window_timer: float = 0.0 ## 时机窗口倒计时
var _is_timing_window_active: bool = false
var _bobber_sink_amount: float = 0.0  ## 浮标下沉程度(0.0-1.0)

## 搏鱼小游戏状态
var _fish_position: float = 0.5    ## 鱼的位置(0.0-1.0)
var _fish_dash_timer: float = 0.0   ## 冲刺计时器
var _fish_dash_direction: int = 0   ## 冲刺方向(-1/0/1)

var _player_stamina: float = 1.0   ## 鱼的力量条(1.0=满)
var _player_pressure: float = 0.0  ## 玩家压力条(0.0=无)
var _fight_time: float = 0.0       ## 搏鱼已用时间
var _move_direction: int = 0       ## 玩家输入方向(-1/0/1)

## 鱼数据
var _fish_data: Dictionary = {}
var _fish_difficulty: int = 1      ## 鱼类难度(1-10)
var _is_fighting: bool = false      ## 是否在搏鱼阶段

## 战斗加成
var _skill_level: int = 0          ## 钓鱼技能等级
var _rod_bonus: float = 1.0        ## 鱼竿加成

## 辅助模式
var _assist_mode: bool = false      ## 是否启用辅助模式

## 时间管理
var _last_update_time: int = 0

# ============ 信号定义 ============

signal state_changed(new_state: State, old_state: State)
signal timing_result_changed(result: TimingResult)
signal fishing_complete(result: Dictionary)
signal fish_stamina_changed(value: float)
signal player_pressure_changed(value: float)
signal zone_entered(zone: ZoneType)

# ============ 初始化 ============

func _ready() -> void:
	_setup_node_references()
	_connect_signals()
	_hide_game()
	_last_update_time = Time.get_ticks_msec()

func _setup_node_references() -> void:
	_background = $Background if has_node("Background") else null
	_panel = $Panel if has_node("Panel") else null

	if _panel:
		_title_label = _panel.find_child("Title", true, false)
		var timing_section = _panel.find_child("TimingSection", true, false)
		if timing_section:
			_instruction_label = timing_section.find_child("InstructionLabel", true, false)
			var bobber_container = timing_section.find_child("BobberContainer", true, false)
			if bobber_container:
				_bobber_bar = bobber_container.find_child("BobberBar", true, false)

		var fishing_section = _panel.find_child("FishingSection", true, false)
		if fishing_section:
			var fight_progress_container = fishing_section.find_child("FightProgressContainer", true, false)
			if fight_progress_container:
				_fight_progress_bg = fight_progress_container.find_child("FightProgressBg", true, false)
				_fish_indicator = fight_progress_container.find_child("FishIndicator", true, false)

			var fight_stats = fishing_section.find_child("FightStats", true, false)
			if fight_stats:
				_stamina_label = fight_stats.find_child("StaminaLabel", true, false)
				_stamina_bar = fight_stats.find_child("StaminaBar", true, false)
				_pressure_label = fight_stats.find_child("PressureLabel", true, false)
				_pressure_bar = fight_stats.find_child("PressureBar", true, false)

	_result_label = _panel.find_child("ResultLabel", true, false) if _panel else null

	var button_section = _panel.find_child("ButtonSection", true, false) if _panel else null
	if button_section:
		_reel_button = button_section.find_child("ReelButton", true, false)
		_cancel_button = button_section.find_child("CancelButton", true, false)

	var touch_controls = _panel.find_child("TouchControls", true, false) if _panel else null
	if touch_controls:
		_left_button = touch_controls.find_child("LeftButton", true, false)
		_right_button = touch_controls.find_child("RightButton", true, false)

	_hint_label = _panel.find_child("HintLabel", true, false) if _panel else null

	_setup_zone_visuals()
	_update_ui_visibility()

func _setup_zone_visuals() -> void:
	## 安全区和过渡区会在搏鱼阶段动态显示
	pass

func _connect_signals() -> void:
	if _reel_button:
		_reel_button.pressed.connect(_on_reel_pressed)
	if _cancel_button:
		_cancel_button.pressed.connect(_on_cancel_pressed)
	if _left_button:
		_left_button.pressed.connect(_on_left_pressed)
		_left_button.button_down.connect(_on_left_down)
		_left_button.button_up.connect(_on_left_up)
	if _right_button:
		_right_button.pressed.connect(_on_right_pressed)
		_right_button.button_down.connect(_on_right_down)
		_right_button.button_up.connect(_on_right_up)

# ============ 公共 API ============

## 启动钓鱼小游戏
## fish_data: 鱼数据字典
## assist_mode: 是否启用辅助模式（可选，默认为false）
func start_minigame(fish_data: Dictionary, assist_mode: bool = false) -> void:
	if _current_state != State.IDLE:
		print("[FishingMiniGame] Already active, ignoring start_minigame")
		return

	_fish_data = fish_data
	_fish_difficulty = fish_data.get("difficulty", 1)

	## 设置辅助模式
	_assist_mode = assist_mode

	## 获取技能等级和装备加成
	_skill_level = 0
	_rod_bonus = 1.0
	if SkillSystem and SkillSystem.has_method("get_level"):
		_skill_level = SkillSystem.get_level(SkillSystem.SkillType.FISHING)
		print("[FishingMiniGame] Fishing skill level: " + str(_skill_level))

	## 重置状态
	_reset_game_state()

	## 显示界面
	_show_game()

	## 开始等待阶段
	_change_state(State.WAITING)

	var mode_str = "普通模式" if not _assist_mode else "辅助模式"
	print("[FishingMiniGame] Started minigame with fish: " + str(fish_data.get("name", "Unknown")) + " (" + mode_str + ")")

## 取消钓鱼小游戏
func cancel_minigame() -> void:
	if _current_state == State.IDLE:
		return

	print("[FishingMiniGame] Cancelled")
	_change_state(State.FAILED)
	_hide_game()

## 提竿按钮按下
func on_reel_pressed() -> void:
	_on_reel_pressed()

## 收线方向
## direction = -1 (向左) / 0 (无) / 1 (向右)
func on_move_direction(direction: int) -> void:
	_move_direction = direction

## 获取当前状态
func get_current_state() -> State:
	return _current_state

## 获取鱼的位置 (0.0-1.0)
func get_fish_position() -> float:
	return _fish_position

## 获取力量条 (0.0-1.0)
func get_stamina() -> float:
	return _player_stamina

## 获取压力条 (0.0-1.0)
func get_pressure() -> float:
	return _player_pressure

## 获取/设置辅助模式
func is_assist_mode() -> bool:
	return _assist_mode

func set_assist_mode(enabled: bool) -> void:
	_assist_mode = enabled
	print("[FishingMiniGame] Assist mode: " + str(_assist_mode))

## 获取当前模式的安全区参数
func _get_safe_zone_params() -> Dictionary:
	if _assist_mode:
		return {
			"safe_start": ASSIST_SAFE_ZONE_START,
			"safe_end": ASSIST_SAFE_ZONE_END,
			"transition_size": ASSIST_TRANSITION_ZONE_SIZE
		}
	else:
		return {
			"safe_start": SAFE_ZONE_START,
			"safe_end": SAFE_ZONE_END,
			"transition_size": TRANSITION_ZONE_SIZE
		}

# ============ 游戏控制 ============

func _show_game() -> void:
	visible = true
	if _background:
		_background.visible = true
	if _panel:
		_panel.visible = true

func _hide_game() -> void:
	visible = false

func _reset_game_state() -> void:
	_current_state = State.IDLE
	_bobber_state = BobberState.FLOATING
	_timing_result = TimingResult.NONE

	_bite_timer = 0.0
	_timing_window_timer = 0.0
	_is_timing_window_active = false
	_bobber_sink_amount = 0.0

	_fish_position = 0.5
	_fish_dash_timer = 0.0
	_fish_dash_direction = 0

	_player_stamina = 1.0
	_player_pressure = 0.0
	_fight_time = 0.0
	_move_direction = 0
	_is_fighting = false

func _change_state(new_state: State) -> void:
	var old_state = _current_state
	_current_state = new_state

	print("[FishingMiniGame] State changed: " + str(old_state) + " -> " + str(new_state))

	_on_state_enter(new_state)
	state_changed.emit(new_state, old_state)

func _on_state_enter(state: State) -> void:
	match state:
		State.IDLE:
			pass
		State.WAITING:
			_start_waiting_phase()
		State.BITE:
			_start_bite_phase()
		State.FISHING:
			_start_fighting_phase()
		State.SUCCESS:
			_handle_success()
		State.FAILED:
			_handle_failure()

# ============ 阶段处理 ============

func _start_waiting_phase() -> void:
	_update_title("钓鱼中...")
	_update_instruction("等待鱼儿上钩...")
	_update_result("鱼儿正在试探...")

	## 计算咬钩时间
	var bite_time = _calculate_bite_time()
	_bite_timer = bite_time

	## 重置浮标状态
	_bobber_state = BobberState.FLOATING
	_bobber_sink_amount = 0.0

	_enable_reel_button(false)

	## 显示时机小游戏区域，隐藏搏鱼区域
	_update_ui_visibility()

	print("[FishingMiniGame] Waiting phase started, bite in " + str(bite_time) + "s")

func _calculate_bite_time() -> float:
	var rng = RandomNumberGenerator.new()
	var base_time = rng.randf_range(BASE_BITE_TIME_MIN, BASE_BITE_TIME_MAX)

	## 技能缩短系数
	var skill_multiplier = 1.0 - (_skill_level * 0.02)

	## 鱼饵缩短系数（咬钩率越高，等待时间越短）
	## bite_bonus: 0.0=无, 0.10=普通, 0.20=美味, 0.50=传说
	## 转换为时间缩短系数
	var bite_bonus = _fish_data.get("bait_multiplier", 1.0)
	var bait_multiplier = bite_bonus  ## 0.9, 0.8, 0.5

	## 传说饵料额外缩短10%
	if _fish_data.get("bait_name", "") == "传说饵料":
		bait_multiplier *= 0.9

	var final_time = base_time * skill_multiplier * bait_multiplier

	print("[FishingMiniGame] Bite time: base=" + str(base_time) + " skill_mult=" + str(skill_multiplier) + " bait_mult=" + str(bait_multiplier) + " final=" + str(final_time))

	return final_time

func _start_bite_phase() -> void:
	_update_instruction("！！！鱼儿上钩了！！！")
	_update_result("现在提竿！")

	_bobber_state = BobberState.SINKING
	_is_timing_window_active = false  ## 时机窗口不立即激活
	_bobber_sink_amount = 0.0  ## 重置下沉量

	_enable_reel_button(true)

	## 根据辅助模式设置触发阈值
	var trigger_threshold = SINK_TRIGGER_THRESHOLD
	if _assist_mode:
		trigger_threshold = ASSIST_SINK_TRIGGER_THRESHOLD

	print("[FishingMiniGame] Bite phase started, trigger threshold: " + str(trigger_threshold))

func _start_fighting_phase() -> void:
	_is_fighting = true
	_fight_time = 0.0
	_player_stamina = 1.0
	_player_pressure = 0.0

	## 重置鱼的位置到中心
	_fish_position = 0.5

	_update_title("搏鱼中...")
	_update_instruction("保持鱼在绿色区域！")
	_update_result("")

	_enable_reel_button(false)
	_show_fight_ui(true)

	## 触发鱼的第一冲刺
	_trigger_fish_dash()

	print("[FishingMiniGame] Fighting phase started")

func _handle_success() -> void:
	_update_result("🎉 钓到鱼了！")
	_update_instruction("太棒了！")

	var result = _build_result(true)
	fishing_complete.emit(result)

	_show_fight_ui(false)

	await get_tree().create_timer(2.0).timeout
	_hide_game()
	_reset_game_state()

func _handle_failure() -> void:
	var reason = ""
	match _timing_result:
		TimingResult.TOO_EARLY:
			reason = "提竿太早了，鱼被吓跑了..."
		TimingResult.TOO_LATE:
			reason = "提竿太晚了，鱼跑了..."
		_:
			if _player_pressure >= 1.0:
				reason = "压力过大，鱼挣脱了..."
			elif _fight_time >= MAX_FIGHT_TIME:
				reason = "时间太长了，鱼逃跑了..."
			else:
				reason = "鱼逃跑了..."

	_update_result("💨 " + reason)
	_update_instruction("没钓到... 再接再厉")

	var result = _build_result(false)
	fishing_complete.emit(result)

	_show_fight_ui(false)

	await get_tree().create_timer(2.0).timeout
	_hide_game()
	_reset_game_state()

func _build_result(success: bool) -> Dictionary:
	return {
		"success": success,
		"fish_id": _fish_data.get("fish_id", ""),
		"quality": _calculate_quality(),
		"timing_result": _get_timing_result_string(),
		"fight_time": _fight_time
	}

func _calculate_quality() -> String:
	var rng = RandomNumberGenerator.new()
	var roll = rng.randf()

	## 基础高品质概率 10%
	var base_prob = 0.10
	## 技能加成
	var skill_bonus = _skill_level * 0.02
	## 时机加成
	var timing_bonus = 0.0
	if _timing_result == TimingResult.PERFECT:
		timing_bonus = 0.05

	var final_prob = clamp(base_prob + skill_bonus + timing_bonus, 0.0, 0.30)

	if roll < final_prob * 0.33:  ## 高品质(excellent)概率
		return "excellent"
	elif roll < final_prob:        ## 普通高品质(fine)概率
		return "fine"
	else:
		return "normal"

func _get_timing_result_string() -> String:
	match _timing_result:
		TimingResult.PERFECT:
			return "perfect"
		TimingResult.NORMAL:
			return "normal"
		TimingResult.TOO_EARLY:
			return "too_early"
		TimingResult.TOO_LATE:
			return "too_late"
		_:
			return "none"

# ============ 帧更新 ============

func _process(delta: float) -> void:
	if _current_state == State.IDLE:
		return

	var current_time = Time.get_ticks_msec()
	var frame_delta = (current_time - _last_update_time) / 1000.0
	_last_update_time = current_time

	match _current_state:
		State.WAITING:
			_update_waiting(delta)
		State.BITE:
			_update_bite(delta)
		State.FISHING:
			_update_fighting(delta)

	_update_visual_elements()

func _update_waiting(delta: float) -> void:
	## 浮标轻微浮动动画
	_bobber_state = BobberState.FLOATING
	_bobber_sink_amount = 0.05 + sin(Time.get_ticks_msec() / 500.0) * 0.03

	## 倒计时
	_bite_timer -= delta
	if _bite_timer <= 0:
		_change_state(State.BITE)

func _update_bite(delta: float) -> void:
	## 浮标下沉动画
	if _bobber_state == BobberState.SINKING:
		## 下沉速度：2.5秒从0到1.0（完全消失）
		## 这样浮标下沉到70%约1.75s，时机窗口约1.1s，给玩家充足时间
		_bobber_sink_amount += delta / 2.5
		_bobber_sink_amount = clampf(_bobber_sink_amount, 0.0, 1.0)

		## 根据辅助模式选择触发阈值和时机窗口
		var trigger_threshold = SINK_TRIGGER_THRESHOLD
		var timing_window_base = BASE_TIMING_WINDOW
		if _assist_mode:
			trigger_threshold = ASSIST_SINK_TRIGGER_THRESHOLD
			timing_window_base = ASSIST_TIMING_WINDOW

		## 检查是否超过阈值，触发时机窗口
		if not _is_timing_window_active and _bobber_sink_amount >= trigger_threshold:
			## 触发时机窗口
			_is_timing_window_active = true
			var timing_window = timing_window_base + (_fish_difficulty * TIMING_WINDOW_PER_DIFFICULTY)
			timing_window = minf(timing_window, MAX_TIMING_WINDOW)
			_timing_window_timer = timing_window
			print("[FishingMiniGame] Timing window started! duration=" + str(timing_window) + "s (assist=" + str(_assist_mode) + ")")

		## 如果浮标完全消失，状态变为DIVING
		if _bobber_sink_amount >= 1.0:
			_bobber_state = BobberState.DIVING

	## 时机窗口倒计时
	if _is_timing_window_active:
		_timing_window_timer -= delta
		if _timing_window_timer <= 0:
			## 时机窗口结束，但浮标可能还没完全消失
			_is_timing_window_active = false
			print("[FishingMiniGame] Timing window ended, bobber still sinking")

func _update_fighting(delta: float) -> void:
	_fight_time += delta

	## 检查超时
	if _fight_time >= MAX_FIGHT_TIME:
		_change_state(State.FAILED)
		return

	## 更新鱼的位置
	_update_fish_position(delta)

	## 更新区域判定和消耗
	_update_zone_effects(delta)

	## 检查成功/失败条件
	_check_fight_end_conditions()

	## 更新UI
	_update_fight_ui()

func _update_fish_position(delta: float) -> void:
	## 基础速度计算（根据辅助模式选择）
	var base_speed = PLAYER_BASE_SPEED
	if _assist_mode:
		base_speed = ASSIST_PLAYER_BASE_SPEED

	var player_speed = base_speed * (1.0 + _skill_level * 0.05) * _rod_bonus

	## 无输入时，鱼趋向危险区（自然拉力）
	## 有输入时，玩家收线可以抵消鱼的拉力
	var net_movement: float = 0.0

	if _move_direction != 0:
		## 玩家收线 = 向按压方向移动
		net_movement = _move_direction * player_speed * delta
	else:
		## 无输入时，鱼趋向危险区
		## 鱼在左侧趋向左，鱼在右侧趋向右
		if _fish_position < 0.5:
			net_movement = -FISH_NATURAL_DRIFT * delta
		else:
			net_movement = FISH_NATURAL_DRIFT * delta

	## 鱼冲刺：在自然拉力基础上叠加冲刺
	net_movement += _calculate_fish_dash_movement(delta)

	## 应用最终移动
	_fish_position += net_movement

	## 边界限制
	_fish_position = clampf(_fish_position, 0.0, 1.0)

## 计算鱼的冲刺产生的额外移动
func _calculate_fish_dash_movement(delta: float) -> float:
	if _fish_dash_direction == 0:
		## 检查是否需要开始新冲刺
		_fish_dash_timer -= delta
		if _fish_dash_timer <= 0:
			_trigger_fish_dash()
		return 0.0
	else:
		## 冲刺中，使用基于难度的冲刺速度
		var dash_speed = _calculate_dash_range() / _calculate_dash_duration()
		return _fish_dash_direction * dash_speed * delta

func _trigger_fish_dash() -> void:
	## 冲刺方向：鱼会向更能逃离的方向冲刺
	## 70%概率向逃离方向，30%概率随机
	var rng = RandomNumberGenerator.new()

	## 判断逃离方向
	## 如果鱼在中心(0.5)，逃离方向随机
	## 如果鱼在左侧(<0.5)，逃离方向是左(-1)
	## 如果鱼在右侧(>0.5)，逃离方向是右(1)
	var escape_direction: int = -1 if _fish_position < 0.5 else 1

	if rng.randf() < 0.7:
		## 70%概率向逃离方向冲刺
		_fish_dash_direction = escape_direction
	else:
		## 30%概率随机方向
		_fish_dash_direction = rng.randi_range(-1, 1)

	## 冲刺间隔（基于难度）
	var dash_interval = _calculate_dash_interval()
	_fish_dash_timer = dash_interval * rng.randf_range(0.5, 1.5)

## 根据难度计算冲刺间隔
## 设计文档：简单(1-3)长3s/中等(4-6)中2s/困难(7-10)短1s
func _calculate_dash_interval() -> float:
	match _fish_difficulty:
		1, 2, 3:
			return 3.0  ## 简单：3秒间隔
		4, 5, 6:
			return 2.0  ## 中等：2秒间隔
		7, 8, 9, 10:
			return 1.0  ## 困难：1秒间隔
		_:
			return 2.0

## 根据难度计算冲刺时长
## 设计文档：简单(1-3)慢1.5s/中等(4-6)中1.0s/困难(7-10)快0.5s
func _calculate_dash_duration() -> float:
	match _fish_difficulty:
		1, 2, 3:
			return 1.5  ## 简单：1.5秒完成
		4, 5, 6:
			return 1.0  ## 中等：1.0秒完成
		7, 8, 9, 10:
			return 0.5  ## 困难：0.5秒完成
		_:
			return 1.0

func _calculate_dash_range() -> float:
	## 根据难度计算冲刺幅度
	## 设计文档：简单(1-3)小30%/中等(4-6)中50%/困难(7-10)大80%
	match _fish_difficulty:
		1, 2, 3:
			return 0.30  ## 简单：30%
		4, 5, 6:
			return 0.50  ## 中等：50%
		7, 8, 9, 10:
			return 0.80  ## 困难：80%
		_:
			return 0.50

func _update_zone_effects(delta: float) -> void:
	var zone = _get_zone_type(_fish_position)

	## 根据辅助模式选择消耗参数
	var stamina_drain_safe: float
	var stamina_drain_transition: float
	var stamina_drain_danger: float
	var pressure_rate_safe: float
	var pressure_rate_transition: float
	var pressure_rate_danger: float

	if _assist_mode:
		stamina_drain_safe = ASSIST_STAMINA_DRAIN_SAFE
		stamina_drain_transition = ASSIST_STAMINA_DRAIN_TRANSITION
		stamina_drain_danger = ASSIST_STAMINA_DRAIN_DANGER
		pressure_rate_safe = ASSIST_PRESSURE_RATE_SAFE
		pressure_rate_transition = ASSIST_PRESSURE_RATE_TRANSITION
		pressure_rate_danger = ASSIST_PRESSURE_RATE_DANGER
	else:
		stamina_drain_safe = STAMINA_DRAIN_SAFE
		stamina_drain_transition = STAMINA_DRAIN_TRANSITION
		stamina_drain_danger = STAMINA_DRAIN_DANGER
		pressure_rate_safe = PRESSURE_RATE_SAFE
		pressure_rate_transition = PRESSURE_RATE_TRANSITION
		pressure_rate_danger = PRESSURE_RATE_DANGER

	if zone == ZoneType.SAFE:
		_player_stamina -= stamina_drain_safe * 60 * delta
		_player_pressure += pressure_rate_safe * 60 * delta
	elif zone == ZoneType.TRANSITION:
		_player_stamina -= stamina_drain_transition * 60 * delta
		_player_pressure += pressure_rate_transition * 60 * delta
	else:  ## DANGER
		_player_stamina -= stamina_drain_danger * 60 * delta
		_player_pressure += pressure_rate_danger * 60 * delta

	## 压力值限制
	_player_pressure = clampf(_player_pressure, 0.0, 1.0)

	## 力量值限制
	_player_stamina = clampf(_player_stamina, 0.0, 1.0)

func _get_zone_type(position: float) -> ZoneType:
	var params = _get_safe_zone_params()
	var safe_start = params["safe_start"]
	var safe_end = params["safe_end"]
	var transition_size = params["transition_size"]

	if position >= safe_start and position <= safe_end:
		return ZoneType.SAFE
	elif position >= safe_start - transition_size and position < safe_start:
		return ZoneType.TRANSITION
	elif position > safe_end and position <= safe_end + transition_size:
		return ZoneType.TRANSITION
	else:
		return ZoneType.DANGER

func _check_fight_end_conditions() -> void:
	## 成功条件
	if _player_stamina <= 0:
		_player_stamina = 0
		_change_state(State.SUCCESS)
		return

	## 失败条件
	if _player_pressure >= 1.0:
		_player_pressure = 1.0
		_timing_result = TimingResult.TOO_LATE
		_change_state(State.FAILED)
		return

# ============ 提竿判定 ============

func _on_reel_pressed() -> void:
	if _current_state != State.BITE:
		print("[FishingMiniGame] Reel pressed but not in BITE state")
		return

	print("[FishingMiniGame] Reel pressed! bobber_state=" + str(_bobber_state) + " timing_window_active=" + str(_is_timing_window_active) + " sink=" + str(_bobber_sink_amount))

	## 时机判定
	if _bobber_state == BobberState.BOBBING:
		## 太早 - 鱼在试探阶段就提竿
		_timing_result = TimingResult.TOO_EARLY
		_change_state(State.FAILED)
	elif _bobber_state == BobberState.SINKING:
		if _is_timing_window_active:
			## 最佳时机！
			_timing_result = TimingResult.PERFECT
			timing_result_changed.emit(_timing_result)
			_change_state(State.FISHING)
		else:
			## 时机窗口已过，但浮标还没完全消失
			## 给予正常时机判定，进入搏鱼阶段（有惩罚）
			_timing_result = TimingResult.NORMAL
			timing_result_changed.emit(_timing_result)
			_change_state(State.FISHING)
	elif _bobber_state == BobberState.DIVING:
		## 太晚 - 浮标完全消失
		_timing_result = TimingResult.TOO_LATE
		_change_state(State.FAILED)
	else:
		## FLOATING - 还没咬钩就提竿
		_timing_result = TimingResult.TOO_EARLY
		_change_state(State.FAILED)

# ============ UI 更新 ============

func _update_title(text: String) -> void:
	if _title_label:
		_title_label.text = text

func _update_instruction(text: String) -> void:
	if _instruction_label:
		_instruction_label.text = text

func _update_result(text: String) -> void:
	if _result_label:
		_result_label.text = text

func _enable_reel_button(enabled: bool) -> void:
	if _reel_button:
		_reel_button.disabled = not enabled

func _update_ui_visibility() -> void:
	## 时机小游戏区域始终显示
	## 搏鱼小游戏区域根据状态显示
	var show_fight = _current_state == State.FISHING or _current_state == State.SUCCESS or _current_state == State.FAILED
	_show_fight_ui(show_fight)

func _show_fight_ui(show: bool) -> void:
	print("[FishingMiniGame] _show_fight_ui(" + str(show) + ")")
	if _fight_progress_bg:
		_fight_progress_bg.visible = show
	if _fish_indicator:
		_fish_indicator.visible = show
	if _stamina_bar:
		_stamina_bar.visible = show
		print("[FishingMiniGame] stamina_bar visible=" + str(show))
	if _stamina_label:
		_stamina_label.visible = show
	if _pressure_bar:
		_pressure_bar.visible = show
	if _pressure_label:
		_pressure_label.visible = show
	if _hint_label:
		_hint_label.visible = show

func _update_fight_ui() -> void:
	if _stamina_bar:
		_stamina_bar.value = _player_stamina * 100.0
	if _pressure_bar:
		_pressure_bar.value = _player_pressure * 100.0

	## 更新鱼的指示器位置
	if _fish_indicator:
		var container_width = 540.0  ## 大约的容器宽度
		_fish_indicator.position.x = _fish_position * container_width - container_width / 2

func _update_visual_elements() -> void:
	## 更新浮标下沉程度
	if _bobber_bar:
		_bobber_bar.value = _bobber_sink_amount * 100.0

# ============ 输入处理 ============

func _on_cancel_pressed() -> void:
	cancel_minigame()

func _on_left_pressed() -> void:
	_move_direction = -1

func _on_right_pressed() -> void:
	_move_direction = 1

func _on_left_down() -> void:
	_move_direction = -1

func _on_left_up() -> void:
	if _move_direction == -1:
		_move_direction = 0

func _on_right_down() -> void:
	_move_direction = 1

func _on_right_up() -> void:
	if _move_direction == 1:
		_move_direction = 0

func _input(event: InputEvent) -> void:
	if _current_state == State.IDLE:
		return

	## 提竿操作
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_on_reel_pressed()

	## 取消操作
	if event.is_action_pressed("ui_cancel"):
		cancel_minigame()

	## 收线操作（搏鱼阶段）
	if _current_state == State.FISHING:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
			_move_direction = -1
		elif event.is_action_released("ui_left") or event.is_action_released("move_left"):
			if _move_direction == -1:
				_move_direction = 0
		if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
			_move_direction = 1
		elif event.is_action_released("ui_right") or event.is_action_released("move_right"):
			if _move_direction == 1:
				_move_direction = 0
