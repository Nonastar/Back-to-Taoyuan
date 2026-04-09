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
