extends Node

## GameManager - 全局游戏状态管理器
## 负责游戏初始化、状态管理和场景切换

# 游戏状态枚举
enum GameState {
	BOOT,           # 启动中
	TITLE,          # 标题画面
	PLAYING,        # 游戏中
	PAUSED,         # 暂停
	INVENTORY_OPEN, # 背包打开
	MENU_OPEN,      # 菜单打开
	SAVING,         # 保存中
	LOADING,        # 加载中
}

# 当前游戏状态
var current_state: GameState = GameState.BOOT:
	set(value):
		_state_changed(current_state, value)
		current_state = value

# 游戏版本
const GAME_VERSION: String = "0.1.0"
const GAME_NAME: String = "归园田居"

# 是否是新游戏
var is_new_game: bool = true

# 当前存档槽位
var current_save_slot: int = -1

const DEFAULT_WORLD: String = "farm"

func _ready() -> void:
	# 初始化完成，进入标题画面
	current_state = GameState.TITLE
	print("[GameManager] %s v%s initialized" % [GAME_NAME, GAME_VERSION])

func _state_changed(from: GameState, to: GameState) -> void:
	EventBus.game_state_changed.emit(from, to)

## 获取当前是否为游戏中状态
func is_playing() -> bool:
	return current_state == GameState.PLAYING

## 获取当前是否可接受输入
func can_receive_input() -> bool:
	return current_state in [
		GameState.PLAYING,
		GameState.TITLE
	]

## 开始新游戏
func start_new_game() -> void:
	is_new_game = true
	current_save_slot = -1
	if not _initialize_new_game_data():
		push_error("[GameManager] Failed to initialize new game data")
		current_state = GameState.TITLE
		return

	_enter_gameplay_world()
	current_state = GameState.PLAYING

## 继续游戏
func continue_game(slot: int) -> void:
	if slot < 0:
		push_error("[GameManager] Invalid save slot: %d" % slot)
		current_state = GameState.TITLE
		return

	current_save_slot = slot
	is_new_game = false

	if not _load_save_slot(slot):
		push_warning("[GameManager] Failed to load slot %d, fallback to title" % slot)
		current_state = GameState.TITLE
		return

	_enter_gameplay_world()
	current_state = GameState.PLAYING

## 打开存档菜单
func open_save_menu() -> void:
	current_state = GameState.MENU_OPEN
	# 打开存档菜单 UI，详见 design/gdd/ui/save-menu-ui.md

## 暂停游戏
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true

## 继续游戏
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false

## 退出游戏
func quit_game() -> void:
	print("[GameManager] Quitting game...")
	get_tree().quit()

func _initialize_new_game_data() -> bool:
	if TimeManager:
		TimeManager.current_day = 1
		TimeManager.current_year = 1
	if SceneManager and SceneManager.has_method("switch_world"):
		SceneManager.current_interior = ""
	return true

func _load_save_slot(slot: int) -> bool:
	if not SaveManager or not SaveManager.has_method("load_game"):
		push_warning("[GameManager] SaveManager unavailable, skip loading")
		return true

	if not SaveManager.has_method("has_save"):
		return SaveManager.load_game(slot)

	if not SaveManager.has_save(slot):
		push_warning("[GameManager] Save slot %d does not exist" % slot)
		return false

	return SaveManager.load_game(slot)

func _enter_gameplay_world() -> void:
	if SceneManager and SceneManager.has_method("switch_world"):
		SceneManager.switch_world(DEFAULT_WORLD)
