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

## 检查清单

编写代码前确认：
- [ ] Autoload没有`class_name`
- [ ] Autoload没有`@onready`
- [ ] 所有节点引用延迟初始化
- [ ] 方法名不与Resource冲突
- [ ] 类型使用`int`而非`enum`
- [ ] 变量先声明后使用
- [ ] 接口方法已实现

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
