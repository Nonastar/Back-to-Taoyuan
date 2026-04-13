# 归园田居 - 修复日志

> 记录犯过的错误，避免重蹈覆辙

---

## 核心规则

### Autoload 脚本规则

1. **不要使用 `class_name`** — Autoload本身已注册为单例
2. **不要使用 `@onready` 引用子节点** — 运行时动态创建
3. **延迟初始化所有节点引用**

### Godot 4.x 类型规则

1. **枚举使用** — 使用 `int` + 常量，不用 `enum`
2. **方法命名** — 避免与 `Resource` 内置方法冲突 (`get_name`, `to_string` 等)
3. **配置系统** — 实现 `apply_config()` 接口方法

---

## 问题列表

### 问题1: Autoload不能使用class_name

**错误:**
```gdscript
# 错误写法
extends Node
class_name GameManager

# 编译错误
Parse Error: Class "GameManager" hides an autoload singleton.
```

**原因:** Godot的Autoload本身就是单例，不能再用`class_name`声明

**正确写法:**
```gdscript
# 正确写法
extends Node
# 不要写 class_name
```

**教训:** Autoload脚本直接`extends Node`，不写`class_name`

---

### 问题2: @onready引用不存在的节点

**错误:**
```gdscript
# 错误写法
@onready var _bgm_player: AudioStreamPlayer = $BGMPlayer

# 编译错误
Node not found: "BGMPlayer" (relative to "/root/AudioManager")
```

**原因:** Autoload是根节点，没有场景层级，子节点不存在

**正确写法:**
```gdscript
# 正确写法1: 延迟初始化
var _bgm_player: AudioStreamPlayer = null

func _setup() -> void:
    _bgm_player = AudioStreamPlayer.new()
    add_child(_bgm_player)

# 正确写法2: 在ready中创建
func _ready() -> void:
    _bgm_player = AudioStreamPlayer.new()
    add_child(_bgm_player)
```

**教训:** Autoload无场景层级，子节点必须运行时创建

---

### 问题3: Godot 4 API差异

**错误:**
```gdscript
# 错误
var db = linear2db(0.5)

# 编译错误
Function "linear2db()" not found. Did you mean to use "linear_to_db()"?
```

**原因:** Godot 4.x API与3.x有差异

**正确写法:**
```gdscript
var db = linear_to_db(0.5)
```

**教训:** Godot 4 API与3.x有差异，使用前查阅文档

---

### 问题4: FileAccess.open_encrypted用途

**错误:**
```gdscript
# 游戏存档使用加密
FileAccess.open_encrypted(path, FileAccess.WRITE, key)
# 编译错误
Condition "magic != 0x43454447" is true.
```

**原因:** `open_encrypted`是Godot资源格式专用API，不适合JSON存档

**正确写法:**
```gdscript
# 使用普通文件操作
FileAccess.open(path, FileAccess.WRITE)
```

**教训:** `open_encrypted`仅限Godot资源格式，游戏存档用JSON

---

### 问题5: 变量名拼写错误

**错误:**
```gdscript
# 声明了 bg_volume，使用了 master_volume
var master_volume: float = 1.0

func unmute() -> void:
    _set_master_volume(bg_volume)  # 错误: bg_volume 未声明

# 编译错误
Identifier "bg_volume" not declared in the current scope.
```

**教训:** 引用变量前确认已声明

---

### 问题6: 变量未声明/作用域错误

**错误:**
```gdscript
# 循环中引用循环外变量
for system_name in _configurable_systems:
    var system = _configurable_systems[system_name]
    system.on_config_changed(config_name)  # config_name 未在作用域

# 编译错误
Parse Error: Identifier "config_name" not declared in the current scope.
```

**正确写法:**
```gdscript
# 方法参数或预先声明
for system_name in _configurable_systems:
    var system = _configurable_systems[system_name]
    system.on_config_changed("all")  # 使用硬编码值
```

**教训:** 确保所有引用的变量在当前作用域内

---

### 问题7: 类型名称与方法名冲突

**错误:**
```gdscript
# 自定义类
class_name Quality
func get_name() -> String:  # 冲突!
    return "Normal"

# 编译错误
The function signature doesn't match the parent. Parent signature is "get_name() -> String".
```

**原因:** `Resource`类有`get_name()`方法，自定义类继承后方法名冲突

**正确写法:**
```gdscript
class_name Quality  # 继承自RefCounted
extends RefCounted   # 不要继承Resource

func get_quality_name() -> String:  # 改名避免冲突
    return "Normal"
```

**教训:** 不要用`get_name()`, `to_string()` 等作为自定义方法名

---

### 问题8: enum类型声明问题

**错误:**
```gdscript
# 错误: enum用作类型
@export var quality: Quality = Quality.NORMAL

# 编译错误
Cannot assign a value of type Callable to parameter "quality" with specified type Quality.
```

**原因:** Godot 4中`enum`与类型声明有差异

**正确写法:**
```gdscript
# 使用int + 常量
@export var quality: int = Quality.NORMAL

# Quality类
class_name Quality
extends RefCounted

const NORMAL: int = 0
const FINE: int = 1

static func get_multiplier(q: int) -> float:
    match q:
        NORMAL: return 1.0
        FINE: return 1.25
    return 1.0
```

**教训:** 使用`int`类型配合常量定义，而非`enum`类型

---

### 问题9: 缺少方法实现

**错误:**
```gdscript
# ConfigManager调用
tm.apply_config(time_config)

# InventorySystem没有实现这个方法
# 编译错误
Invalid call. Nonexistent function 'apply_config' in base 'Node'.
```

**原因:** ConfigManager定义了接口，但被调用的类未实现

**正确写法:**
```gdscript
# InventorySystem中添加
func apply_config(config: PlayerConfig) -> void:
    if config == null:
        return
    backpack_size = config.default_backpack_size
```

**教训:**
1. 定义接口时，确保所有实现类都有对应方法
2. 或在调用前检查方法是否存在: `if node.has_method("apply_config")`

---

### 问题10: 变量未声明

**错误:**
```gdscript
# 使用了未声明的变量
max_stack_size = config.max_stack_size  # 变量未声明

# 编译错误
Invalid call. Nonexistent function 'max_stack_size' in base 'Node'.
```

**正确写法:**
```gdscript
# 先声明变量
var max_stack_size: int = 9999

# 再使用
func apply_config(config: PlayerConfig) -> void:
    max_stack_size = config.max_stack_size
```

**教训:** 使用变量前必须先声明

---

### 问题11: 变量作用域与if块

**错误:**
```gdscript
# 变量在if块内声明，但在块外使用
if TimeManager != null:
    var tomorrow_day = TimeManager.current_day + 1  # 作用域错误

if tomorrow_day > 28:  # tomorrow_day 未声明
    tomorrow_day = 1
```

**正确写法:**
```gdscript
# 在if块之前声明变量
var tomorrow_day = 1

if TimeManager != null:
    tomorrow_day = TimeManager.current_day + 1

if tomorrow_day > 28:
    tomorrow_day = 1
```

**教训:** 如果变量在if块外使用，必须在if块之前声明并给出默认值

---

### 问题12: 调用不存在的API方法

**错误:**
```gdscript
# 调用了不存在的方法
var config = ConfigManager.get_player_config()

# 编译错误
Invalid call. Nonexistent function 'get_player_config' in base 'Node'.
```

**原因:** API方法名拼写错误或不存在

**正确写法:**
```gdscript
# 查阅API文档确认正确的方法名
var config = ConfigManager.get_config("player")
```

**教训:** 调用API前确认方法存在，或使用 `has_method()` 检查

---

### 问题13: Autoload 类引用

**错误:**
```gdscript
# farm_plot.gd 中引用 Player 类
match tool_type:
    Player.ToolType.HOE:
        return _till()

# 编译错误
Parse Error: Identifier "Player" not declared in the current scope.
```

**原因:** 引用了不在当前作用域的类

**正确写法:**
1. 将类添加到 Autoload (推荐):
```gdscript
# project.godot
[autoload]
Player="*res://src/scripts/entities/player.gd"
```

2. 或使用常量/枚举而非类引用:
```gdscript
# 定义全局常量
const TOOL_HOE = 0
const TOOL_WATER = 1

# 直接使用数值
match tool_type:
    TOOL_HOE:
        return _till()
```

**教训:** 非 Autoload 类需要通过 `class_name` 或 `extends` 声明后才能被其他脚本引用

---

### 问题14: TSCN 文件中 ext_resource 位置

**错误:**
```gdscript
[gd_scene format=3]

[node name="Main" type="Node2D"]
script = ExtResource("2_main")  # 错误：引用未声明的 ExtResource

[ext_resource type="Script" path="res://main.gd" id="2_main"]
```

**正确写法:**
```gdscript
[gd_scene format=3]

[ext_resource type="Script" path="res://main.gd" id="2_main"]

[node name="Main" type="Node2D"]
script = ExtResource("2_main")
```

**教训:** `[ext_resource]` 必须声明在引用它的节点之前

---

### 问题15: 返回类型不匹配 (null vs 具体类型)

**错误:**
```gdscript
func _get_selected_seed() -> Dictionary:
    if ItemDataSystem:
        var tomato = ItemDataSystem.get_item_def("tomato_seed")
        if tomato:
            return {...}
    return null  # 错误：返回 null 但类型声明是 Dictionary

# 编译错误
Cannot return value of type "null" because the function return type is "Dictionary".
```

**正确写法:**
```gdscript
func _get_selected_seed() -> Dictionary:
    if ItemDataSystem:
        var tomato = ItemDataSystem.get_item_def("tomato_seed")
        if tomato:
            return {...}
    # 返回默认值而非 null
    return {"id": "", "name": "", "count": 0, "growth_days": 4, "base_quality": 0}
```

**教训:** 函数返回类型声明后，必须返回对应类型；用空值/默认值代替 null

---

### 问题16: 空目录未触发默认物品创建

**错误:**
```gdscript
# items/ 目录存在但为空时，不会创建默认物品
var dir = DirAccess.open(ITEMS_DATA_PATH)
if dir == null:  # 目录存在，所以这里不执行
    _create_default_items()
# 结果：没有物品被加载
```

**正确写法:**
```gdscript
var dir = DirAccess.open(ITEMS_DATA_PATH)
var items_loaded_count = 0

# ... 遍历加载文件 ...

# 如果没有加载任何物品，创建默认物品
if items_loaded_count == 0:
    push_warning("[ItemDataSystem] No items found, creating defaults...")
    _create_default_items()
```

**教训:** 目录存在不等于有内容，需要计数检查

---

### 问题17: Resource 不支持 Array\[String\]

**错误:**
```gdscript
@export var tags: Array[String] = []  # Godot 4.x 错误

item.tags = ["spring", "summer"]  # 编译错误
```

**正确写法:**
```gdscript
@export var tags: PackedStringArray = []

item.tags = ["spring", "summer"]  # 正常工作
```

**教训:** Godot 4.x 使用 `PackedStringArray` 代替 `Array[String]`

---

### 问题18: 属性名不匹配

**错误:**
```gdscript
PlayerStats.current_stamina  # 不存在
PlayerStats.try_consume_stamina()  # 不存在
```

**正确写法:**
```gdscript
PlayerStats.stamina  # 正确
PlayerStats.consume_stamina(amount)  # 正确
```

**教训:** 调用 API 前确认属性/方法名存在

---

### 问题19: 信号参数类型不匹配

**错误:**
```gdscript
# TimeManager 发送
EventBus.day_changed.emit(current_day, current_season)
# current_season 是 Season 枚举 (int)

# WeatherSystem 接收
func _on_day_changed(day: int, season: String) -> void:
    # 类型不匹配：int vs String
```

**正确写法:**
```gdscript
# 发送时转换为字符串
EventBus.day_changed.emit(current_day, SEASON_NAMES[current_season])
```

**教训:** 信号参数类型必须完全匹配，包括枚举和字符串的转换

---

### 问题20: Sprite 没有纹理导致不显示

**问题:** 创建 Sprite2D 后没有设置 texture，导致精灵不显示

**错误:**
```gdscript
sprite = Sprite2D.new()
sprite.name = "Sprite"
sprite.centered = false
add_child(sprite)
# 没有设置 texture！
```

**正确写法:**
```gdscript
sprite = Sprite2D.new()
sprite.name = "Sprite"
sprite.centered = false
sprite.texture = _make_color_rect(Color(0.5, 0.35, 0.2, 1), Vector2i(48, 48))
add_child(sprite)
```

**教训:** Sprite2D 必须有 texture 才能显示

---

### 问题21: Godot 4.x match 表达式兼容性问题

**问题:** match 表达式的 `_` 默认分支在某些情况下可能有问题

**错误:**
```gdscript
var color = match state:
    PlotState.WASTELAND: Color(0.5, 0.35, 0.2, 1)
    # 使用 _ 作为默认分支可能有兼容性问题
```

**正确写法:**
```gdscript
var color = Color(0.5, 0.35, 0.2, 1)
if state == PlotState.WASTELAND:
    color = Color(0.5, 0.35, 0.2, 1)
elif state == PlotState.TILLED:
    color = Color(0.4, 0.3, 0.15, 1)
# ...
```

**教训:** 使用 if-elif 代替 match 避免兼容性问题

---

### 问题22: 农场位置偏移计算错误

**问题:** 农场起始偏移和地块位置计算导致地块不在屏幕中心

**错误:**
```gdscript
# 视口 1280x720，屏幕中心是 (640, 360)
# 但 FARM_OFFSET 设置为 (320, 180)
const FARM_OFFSET: Vector2 = Vector2(320, 180)
```

**正确写法:**
```gdscript
# 使用实际屏幕中心作为偏移基准
const FARM_OFFSET: Vector2 = Vector2(640, 360)
```

**教训:** 偏移值需要与视口大小匹配，居中时使用视口中心坐标

---

### 问题23: modate 和 texture 的区别

**问题:** 修改 modulate 只改变颜色，不改变精灵大小

**正确用法:**
```gdscript
# modulate 只改变颜色/透明度
sprite.modulate = Color(0.5, 0.35, 0.2, 1)

# texture 控制精灵的实际显示
sprite.texture = _make_color_rect(Color(...), Vector2i(48, 48))
```

**教训:** modulate 是颜色叠加，texture 才是精灵的实际形状

---

### 问题24: HUD 场景加载顺序

**问题:** HUD 脚本在 _ready() 时访问 Autoload 系统，但此时可能尚未初始化

**错误写法:**
```gdscript
func _ready() -> void:
    _setup_ui()
    _connect_signals()
    _update_from_systems()  # Autoload 可能还未就绪！

func _update_from_systems() -> void:
    _current_stamina = PlayerStats.stamina  # 可能报错
```

**正确写法:**
```gdscript
func _ready() -> void:
    _setup_ui()
    _connect_signals()

    # 延迟初始化，等待 Autoload 系统就绪
    await get_tree().process_frame
    _update_from_systems()
```

**教训:** 使用 `await get_tree().process_frame` 确保 Autoload 系统完全初始化后再访问

---

### 问题25: CanvasLayer 没有 Control 锚点属性

**问题:** HUD 继承自 CanvasLayer，但尝试使用 `anchors_preset` 或 `set_anchors_preset()` 导致错误

**错误写法:**
```gdscript
extends CanvasLayer

func _setup_ui() -> void:
    anchors_preset = Control.PRESET_FULL_RECT  # 错误
    set_anchors_preset(Control.PRESET_FULL_RECT)  # 错误
```

**正确写法:**
```gdscript
extends CanvasLayer

func _setup_ui() -> void:
    # CanvasLayer 自动覆盖全屏，不需要设置锚点
    # 直接创建子节点即可
    _create_top_bar()
```

**教训:** CanvasLayer 是独立的画布层，不需要也不支持 Control 的锚点属性

---

### 问题26: TSCN 文件中不能使用 `#` 注释

**问题:** `.tscn` 场景文件中使用 `#` 注释导致解析错误

**错误:**
```gdscript
[gd_scene format=3 uid="uid://0phiucwn7q5u"]

[node name="Foo" type="Node"]
# 这是一个注释
```

**错误日志:**
```
Parse Error: Parse error. [Resource file res://src/scenes/ui/FishingMiniGame.tscn:8]
```

**正确写法:**
```gdscript
[gd_scene format=3 uid="uid://0phiucwn7q5u"]

[node name="Foo" type="Node"]
```

**教训:** `.tscn` 文件只支持 Godot 格式的节点定义，不支持 `#` 注释

---

### 问题27: `pass` 关键字不能加下划线

**问题:** 在 `match` 语句中使用 `_pass` 而非 `pass`

**错误:**
```gdscript
match state:
    State.IDLE:
        _pass  # 错误: _pass 不是有效关键字
```

**正确写法:**
```gdscript
match state:
    State.IDLE:
        pass  # 正确
```

**教训:** GDScript 中空语句块使用 `pass`，不是 `_pass`

---

### 问题28: TextureProgressBar 需要配置纹理

**问题:** 使用 `TextureProgressBar` 但没有配置纹理，导致不显示

**错误:**
```gdscript
var _bobber_bar: TextureProgressBar
# 编译错误
Trying to assign value of type 'ProgressBar' to a variable of type 'TextureProgressBar'.
```

**正确写法:**
```gdscript
# 方案1: 使用 ProgressBar（更简单）
var _bobber_bar: ProgressBar

# 方案2: 使用 TextureProgressBar 但配置纹理
var _bobber_bar: TextureProgressBar
_bobber_bar.texture_under = load("res://path/to/under.png")
_bobber_bar.texture_progress = load("res://path/to/progress.png")
```

**教训:** `TextureProgressBar` 需要配置纹理才可用；简单场景用 `ProgressBar` 更方便

---

### 问题29: 设计文档参数与实际可玩性不匹配

**问题:** 钓鱼小游戏的设计文档参数导致游戏不可玩

**错误设计:**
```
时机窗口 = 0.3s + (难度 × 0.05s)  # 难度1只有0.35秒
浮标下沉时间 = ~0.5s              # 太快消失
时机窗口触发 = BITE阶段开始立即触发
```

**错误现象:**
```
timing window: 0.35s
timing_result: "too_late"  # 玩家还没反应过来就过期了
```

**正确设计:**
```
时机窗口 = 1.0s + (难度 × 0.1s)，最长2.0s  # 玩家有反应时间
浮标下沉速度 = delta / 2.5  # 2.5秒完全消失
时机窗口触发 = 下沉超过70%时触发
判定容错 = 时机窗口结束后、浮标消失前提竿 → 进入搏鱼
```

**教训:**
1. 设计文档的参数需要考虑人类反应时间（通常 > 0.5秒）
2. 玩家体验优先于"精确"的数值模拟
3. 给予容错空间比严格判定更能提升游戏体验

---

### 问题30: Tween API 错误 (Godot 4.6)

**问题:** `Tween.TRANS_EASE_OUT` 和 `Tween.TRANSITION_EASE_OUT` 都不存在

**错误:**
```gdscript
# 错误: TRANS_EASE_OUT 不存在
tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_EASE_OUT)

# 错误: TRANSITION_EASE_OUT 不存在
tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANSITION_EASE_OUT)
```

**正确写法:**
```gdscript
# Godot 4.x 需要分开设置 TRANS 和 EASE
tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
```

**教训:** Godot 4.x 中 `set_trans()` 需要 `TransitionType`，`set_ease()` 需要 `EaseType`，必须分开调用

---

### 问题31: CanvasLayer 没有 modulate 属性

**问题:** `CanvasLayer` 继承自 `Node2D`，没有 `modulate` 属性

**错误:**
```gdscript
extends CanvasLayer

func show_panel() -> void:
    modulate.a = 0.0  # 错误: CanvasLayer 没有 modulate
    tween.tween_property(self, "modulate:a", 1.0, 0.2)
```

**正确写法:**
```gdscript
extends CanvasLayer

func show_panel() -> void:
    # 只使用 scale 动画
    scale = Vector2(0.95, 0.95)
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
```

**教训:** `CanvasLayer` 是独立的画布层，没有 `modulate`、`anchors_preset` 等 Control 属性

---

### 问题32: CanvasLayer 没有 grab_focus() 方法

**问题:** `CanvasLayer` 没有 `grab_focus()` 方法

**错误:**
```gdscript
extends CanvasLayer

func _grab_focus() -> void:
    grab_focus()  # 错误: CanvasLayer 没有此方法
```

**正确写法:**
```gdscript
extends CanvasLayer

func _grab_focus() -> void:
    # 启用面板的焦点模式
    if main_panel:
        main_panel.set_focus_mode(Control.FOCUS_ALL)

func _release_focus() -> void:
    if main_panel:
        main_panel.release_focus()
```

**教训:** `CanvasLayer` 不是 Control，需要通过子节点来管理焦点

---

### 问题33: TextureRect 没有 text 属性

**问题:** 尝试给 `TextureRect` 设置 `text` 属性

**错误:**
```gdscript
var icon = TextureRect.new()
icon.text = "📦"  # 错误: TextureRect 没有 text 属性
```

**正确写法:**
```gdscript
var icon = Label.new()
icon.text = "📦"
icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
```

**教训:** 显示文本使用 `Label`，显示图片使用 `TextureRect`

---

### 问题34: StyleBoxFlat.set_border_color_all 方法不存在

**问题:** `StyleBoxFlat` 没有 `set_border_color_all()` 方法

**错误:**
```gdscript
var style = StyleBoxFlat.new()
style.set_border_color_all(COLORS["border_light"])  # 错误
style.set_border_width_all(1)  # 错误
```

**正确写法:**
```gdscript
var style = StyleBoxFlat.new()
style.border_color = COLORS["border_light"]
style.border_width_left = 1
style.border_width_top = 1
style.border_width_right = 1
style.border_width_bottom = 1
```

**教训:** `StyleBoxFlat` 需要单独设置每条边框的颜色和宽度

---

### 问题35: TSCN 文件 instance 引用错误

**问题:** HUD.tscn 中 InventoryPanel 的实例化引用配置错误

**错误:**
```gdscript
[gd_scene format=3]

# 没有声明 ext_resource
[node name="InventoryPanel" type="Node2D" parent="." instance=ExtResource("2_inventory")]
```

**正确写法:**
```gdscript
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://src/scenes/ui/inventory_panel.tscn" id="2_inventory"]

[node name="HUD" type="CanvasLayer"]
[node name="InventoryPanel" parent="." instance=ExtResource("2_inventory")]
```

**教训:** 使用 `instance=` 前必须先声明 `[ext_resource type="PackedScene"]`

---

### 问题36: 重复的函数定义

**问题:** 同一个脚本中存在重复的函数定义

**错误:**
```gdscript
# 文件中有两个 _switch_tab 函数
func _switch_tab(tab_id: int) -> void:  # 第1个
    ...

func _switch_tab(tab_index: int) -> void:  # 第2个 - 冲突!
    ...
```

**错误日志:**
```
Parse Error: Function "_switch_tab" has the same name as a previously declared function.
```

**正确写法:**
```gdscript
# 只保留一个函数定义
func _switch_tab(tab_id: int) -> void:
    ...
```

**教训:** 检查脚本中是否有重复的函数定义，删除多余的

---

### 问题37: TSCN 文件中的重复节点

**问题:** HUD.tscn 中存在重复的 Notification 节点定义

**错误:**
```gdscript
[node name="Notification" type="Label" parent="." unique_id=23264448"]
...

[node name="Notification" type="Label" parent="." unique_id=23264448"]  # 重复!
...
```

**错误日志:**
```
Parse Error: Parse error. [Resource file res://src/scenes/ui/HUD.tscn:600]
```

**正确写法:**
```gdscript
[node name="Notification" type="Label" parent="." unique_id=23264448"]
...
[node name="InventoryPanel" parent="." instance=ExtResource("2_inventory")]
```

**教训:** 检查 TSCN 文件中是否有重复的节点定义

---

### 问题38: push_warning 用于非重要日志

**问题:** 项目规范要求非重要日志使用 `print`，而非 `push_warning`

**错误:**
```gdscript
push_warning("[GameManager] %s v%s initialized" % [GAME_NAME, GAME_VERSION])
push_warning("[HUD] InventoryPanel not found in scene")
push_warning("[SkillSystem] %s leveled up to Lv.%d!")
```

**正确写法:**
```gdscript
print("[GameManager] %s v%s initialized" % [GAME_NAME, GAME_VERSION])
print("[HUD] InventoryPanel not found in scene")
print("[SkillSystem] %s leveled up to Lv.%d!")
```

**教训:** 项目规范：重要警告用 `push_warning`，普通调试信息用 `print`

---

### 问题39: UTF-8 编码损坏的 TSCN 文件

**问题:** 场景文件被损坏，包含无效的 UTF-8 字节序列

**错误:**
```
Parse Error: Expected identifier (tag name)
```

**受影响的文件:**
- `src/scenes/ui/components/item_slot.tscn`
- `src/scenes/ui/components/equipment_slot.tscn`
- `src/scenes/ui/components/item_tooltip.tscn`
- `src/scenes/ui/components/preset_card.tscn`

**正确写法:**
```gdscript
[gd_scene load_steps=5 format=3 uid="uid://item_slot_001"]

[ext_resource type="Script" path="res://src/scripts/ui/components/item_slot.gd" id="1_slot"]

[node name="ItemSlot" type="PanelContainer"]
custom_minimum_size = Vector2(56, 56)
...
```

**教训:** 定期备份重要文件，避免文件损坏；损坏后需要重新创建文件

---

## 检查清单

编写代码前确认：
- [ ] Autoload没有`class_name`
- [ ] Autoload没有`@onready`
- [ ] 所有节点引用延迟初始化
- [ ] 方法名不与Resource冲突
- [ ] 类型使用`int`而非`enum`
- [ ] 变量先声明后使用
- [ ] 接口方法已实现
- [ ] Autoload依赖顺序正确
- [ ] 变量在if块外使用时，在块前声明
- [ ] API方法调用前确认方法存在
- [ ] 没有嵌套类定义（使用常量代替）
- [ ] 类引用通过Autoload或class_name声明
- [ ] TSCN中ext_resource在节点引用之前
- [ ] 返回类型与实际返回值匹配（用默认值代替null）
- [ ] 空目录需要计数检查而非 null 检查
- [ ] Godot 4.x 使用 PackedStringArray 而非 Array[String]
- [ ] 属性/方法名与实际API一致
- [ ] 信号参数类型完全匹配
- [ ] Sprite2D 必须设置 texture 才能显示
- [ ] 位置偏移值与视口大小匹配
- [ ] 区分 modulate（颜色）和 texture（形状）
- [ ] 场景初始化时使用 await get_tree().process_frame 等待 Autoload 就绪
- [ ] CanvasLayer 不需要也不支持 Control 锚点属性
- [ ] TSCN 文件中不能使用 `#` 注释
- [ ] `pass` 关键字没有下划线
- [ ] TextureProgressBar 配置了纹理或使用 ProgressBar
- [ ] 游戏参数考虑人类反应时间和可玩性
- [ ] Tween 动画分开调用 set_trans() 和 set_ease()
- [ ] CanvasLayer 没有 modulate 属性，使用 scale 代替
- [ ] CanvasLayer 没有 grab_focus()，通过子节点管理焦点
- [ ] 显示文本用 Label，显示图片用 TextureRect
- [ ] StyleBoxFlat 单独设置每条边框颜色和宽度
- [ ] TSCN 中 instance 前必须声明 ext_resource
- [ ] 检查脚本中是否有重复的函数定义
- [ ] 检查 TSCN 中是否有重复的节点定义
- [ ] 非重要日志用 print，重要警告用 push_warning

---

## Autoload加载顺序

Autoload按project.godot中的顺序加载，后加载的可以引用先加载的。

**依赖关系:**
```
ConfigManager → GameManager → TimeManager → EventBus → SaveManager
                                              ↓
AudioManager → PlayerStats → ItemDataSystem → InventorySystem → WeatherSystem
```

**注意:** InventorySystem依赖PlayerStats，必须在PlayerStats之后加载！

---

## 嵌套类问题 (参考: 问题11详细说明)

> ⚠️ 此为快速参考，详细说明见上方"问题11"

Godot 4.6不支持在脚本中嵌套定义新类（使用class_name + extends）。

**错误写法:**
```gdscript
extends Node

class_name WeatherType  # 嵌套类 - 不支持
extends RefCounted

const SUNNY: String = "sunny"
```

**正确写法:** 使用命名常量
```gdscript
extends Node

const WEATHER_SUNNY: String = "sunny"
const WEATHER_RAINY: String = "rainy"
```

---

## 函数名与变量名冲突 (参考: 问题13详细说明)

> ⚠️ 此为快速参考，详细说明见上方"问题13"

Godot不允许函数名与变量名相同。

**错误写法:**
```gdscript
var has_player_override: bool = false

func has_player_override() -> bool:  # 冲突!
    return has_player_override
```

**正确写法:** 重命名函数或变量
```gdscript
var has_player_override: bool = false

func has_player_weather_override() -> bool:  # 不同名
    return has_player_override
```

---

## Godot 4.x 常见API差异

| Godot 3.x | Godot 4.x |
|-----------|------------|
| `linear2db()` | `linear_to_db()` |
| `randi()` | `RandomNumberGenerator` |
| `Tankard.new()` | `Tankard.new()` |
| `FileAccess.open_encrypted()` | 仅限`.tres`格式 |

---

## 参考文档

- Godot 4 迁移指南: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.html
- GDScript API差异: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
