# 桃源乡 - 修复日志

## 2026-04-08

### Sprint 1 - 基础框架修复

#### 问题1: Autoload脚本不能使用 `class_name`
**错误:**
```
Parse Error: Class "XxxManager" hides an autoload singleton.
```

**原因:** Autoload单例节点不能定义`class_name`，因为它们已经通过单例名称注册。

**修复:** 从所有Autoload脚本中移除`class_name`声明:
- `game_manager.gd`
- `time_manager.gd`
- `event_bus.gd`
- `save_manager.gd`
- `audio_manager.gd`
- `inventory_system.gd`

**文件:** `src/scripts/autoload/*.gd`

---

#### 问题2: Godot API函数名错误
**错误:**
```
Function "linear2db()" not found. Did you mean to use "linear_to_db()"?
```

**原因:** Godot 4.x中线性转分贝的函数名是`linear_to_db`而非`linear2db`。

**修复:** 修改`audio_manager.gd`:
```gdscript
# 修复前
var db = linear2db(linear_volume) if linear_volume > 0 else -80

# 修复后
var db = linear_to_db(linear_volume) if linear_volume > 0 else -80
```

**文件:** `src/scripts/autoload/audio_manager.gd:94`

---

#### 问题3: 变量名拼写错误
**错误:**
```
Identifier "bg_volume" not declared in the current scope.
```

**原因:** `unmute()`函数中引用了不存在的变量`bg_volume`，应为`master_volume`。

**修复:**
```gdscript
# 修复前
func unmute() -> void:
    _set_master_volume(bg_volume)

# 修复后
func unmute() -> void:
    _set_master_volume(master_volume)
```

**文件:** `src/scripts/autoload/audio_manager.gd:103`

---

#### 问题4: 加密存档API使用错误
**错误:**
```
Condition "p_key.size() != 32" is true. Returning: ERR_INVALID_PARAMETER
Condition "magic != 0x43454447" is true. Returning: ERR_FILE_UNRECOGNIZED
```

**原因:** `FileAccess.open_encrypted()`是Godot资源格式专用API，不适合游戏存档JSON文件。

**修复:** 简化存档系统，改用纯JSON格式:
- 移除AES加密逻辑
- 改用`FileAccess.open()`直接读写JSON
- 保留存档槽位管理结构

**文件:** `src/scripts/autoload/save_manager.gd` (完全重写)

---

#### 问题5: @onready引用不存在的子节点
**错误:**
```
Node not found: "BGMPlayer" (relative to "/root/AudioManager").
Node not found: "AmbientPlayer" (relative to "/root/AudioManager").
Node not found: "VoicePlayer" (relative to "/root/AudioManager").
```

**原因:** Autoload脚本运行时没有场景层级，子节点不存在。

**修复:**
1. 将`@onready`声明改为运行时初始化:
```gdscript
# 修复前
@onready var _bgm_player: AudioStreamPlayer = $BGMPlayer

# 修复后
var _bgm_player: AudioStreamPlayer = null
```

2. 在`_setup_sfx_pool()`中动态创建播放器:
```gdscript
func _setup_sfx_pool() -> void:
    # SFX池
    for i in SFX_POOL_SIZE:
        var player = AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        _sfx_players.append(player)

    # BGM播放器
    _bgm_player = AudioStreamPlayer.new()
    _bgm_player.bus = "BGM"
    add_child(_bgm_player)

    # 氛围音播放器
    _ambient_player = AudioStreamPlayer.new()
    _ambient_player.bus = "Ambient"
    add_child(_ambient_player)

    # 语音播放器
    _voice_player = AudioStreamPlayer.new()
    _voice_player.bus = "Voice"
    add_child(_voice_player)
```

3. 添加空值检查:
```gdscript
func _fade_out(player: AudioStreamPlayer, duration: float) -> void:
    if player == null or not is_instance_valid(player):
        return
    # ...
```

**文件:** `src/scripts/autoload/audio_manager.gd`

---

#### 问题6: 项目结构重组
**描述:** 设计文档目录结构重组

**变更:**
```
design/
├── gdd/
│   ├── foundation/   # F01-F05 (5个)
│   ├── core/        # C01-C08 (8个)
│   ├── feature/     # P01-P19 (19个)
│   ├── ui/          # U01 (1个)
│   ├── minigames/   # M01-M11 (11个)
│   └── meta/        # X01-X02 (2个)
└── architecture/    # ADR + systems-index
```

**更新的文件:**
- `design/architecture/systems-index.md` - GDD路径更新
- `production/sprints/sprint-01-foundation.md` - ADR路径更新
- `.claude/docs/templates/systems-index.md` - 模板路径

---

#### 问题7: project.godot路径问题
**描述:** Autoload路径使用`scripts/`而非`src/scripts/`

**修复:** 更新`project.godot`:
```ini
[autoload]
GameManager="*res://src/scripts/autoload/game_manager.gd"
TimeManager="*res://src/scripts/autoload/time_manager.gd"
EventBus="*res://src/scripts/autoload/event_bus.gd"
SaveManager="*res://src/scripts/autoload/save_manager.gd"
AudioManager="*res://src/scripts/autoload/audio_manager.gd"
InventorySystem="*res://src/scripts/autoload/inventory_system.gd"
```

---

## 经验总结

1. **Autoload脚本规则:**
   - 不能使用`class_name`
   - 不能使用`@onready`引用子节点
   - 子节点必须运行时动态创建

2. **Godot 4 API差异:**
   - `linear2db()` → `linear_to_db()`
   - 加密文件API仅限Godot资源格式

3. **项目初始化检查清单:**
   - [ ] 移除所有Autoload的`class_name`
   - [ ] 延迟初始化所有@onready节点
   - [ ] 验证project.godot路径正确
