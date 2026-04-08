# 音效系统 (Audio System)

> **状态**: In Design
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: F05
> **Implements Pillar**: 沉浸式音频体验

## Overview

音效系统管理游戏的所有音频输出，包括 80+ 程序化合成音效（SFX）和多首背景音乐（BGM）。系统基于中国五声音阶设计，支持季节、天气、时段动态 BGM 切换。Vue.js 原版使用 Tone.js 进行程序化合成，Godot 4.6 移植版将改用 AudioStreamPlayer + 程序化音频生成器（SFX）和预录制音频文件（BGM）。

## Player Fantasy

音效系统给玩家带来**身临其境的听觉享受**。玩家应该感受到：

- **田园的韵律** — 春季明快、夏季活泼、秋季忧伤、冬季空灵，每个季节都有独特的心境
- **操作的满足感** — 每一次点击、收获、升级都有清脆的音效反馈
- **节日的欢庆** — 节日 BGM 让特殊日子变得更有仪式感
- **天气的氛围** — 雨天有淅沥声，暴风有轰鸣，雪天有寂静

**Reference games**: Stardew Valley 的音效让农耕生活充满活力；原神的 BGM 切换与场景完美融合。

**This is a sensory system** — when it works, players don't notice it; when it's wrong, everything feels off.

## Detailed Design

### Core Rules

1. **音效分类**
   - **SFX (Sound Effects)**: 80+ 程序化合成音效
   - **BGM (Background Music)**: 19+ 首背景音乐
   - **Ambient**: 天气环境音（雨声、风声、雪声）

2. **SFX 实现方案（Godot 4.6）**
   - 使用自定义 `AudioStream` + GDScript 生成 PCM 数据
   - 保留现有合成参数表（频率、波形、时长）
   - 支持节流（throttle）防止音效过度触发
   - 支持音量衰减和多音叠加

   > ⚠️ **Godot API 说明**: Godot 4.x 没有 `AudioStreamGenerator` 类。
   > 实现方式：创建 `AudioStream` 子类，在 `_generate_buffer()` 中填充 PCM 数据。
   > 参考：`docs/engine-reference/godot/` 中的 "Procedural Audio" 实现模式。

3. **BGM 实现方案（Godot 4.6）**
   - MVP：使用自定义 `AudioStream` + GDScript 程序化合成 BGM
   - 保留现有旋律/低音参数表
   - 支持无缝循环
   - 支持多轨混音（旋律 + 低音 + 环境音）

   > **未来扩展**: 可添加预录制音频文件选项（见 OQ-01）。

4. **季节 BGM**
   - **春季**: 明快上行旋律，晨光田园感
   - **夏季**: 活泼高音域，蝉鸣荷塘感
   - **秋季**: 缓慢下行，落叶忧伤感
   - **冬季**: 稀疏空灵，初雪炉火感

5. **天气 BGM 修饰**
   - **晴天**: 正常播放
   - **雨天**: 节奏加快 15%，音量降低，加入雨声环境音
   - **暴风雨**: 节奏减慢 10%，音量降低，使用锯齿波形
   - **雪天**: 节奏加快 25%，音量降低，使用正弦波形
   - **绿雨**: 节奏加快 10%，音量降低，特殊音效

6. **时段 BGM 修饰**
   - **早晨**: 正常音量
   - **下午**: 音量略降，节奏加快
   - **傍晚**: 音量降低，节奏加快，失谐增加
   - **夜晚**: 音量大幅降低，节奏最快，失谐最大
   - **深夜**: 音量最低，节奏最快，低音最重

7. **节日 BGM 覆盖**
   - 节日期间自动切换到对应节日 BGM
   - 节日 BGM 优先级高于季节 BGM
   - 节日结束后自动恢复季节 BGM

8. **小游戏 BGM**
   - 每个小游戏有专属 BGM（11 种）
   - 小游戏 BGM 优先级高于节日 BGM
   - 小游戏结束后自动恢复之前 BGM

### States and Transitions

| 状态 | 描述 | 触发时机 |
|------|------|----------|
| **Idle** | 无音频播放 | 游戏启动/静音模式 |
| **SfxPlaying** | 播放单个 SFX | 玩家操作 |
| **BgmPlaying** | 播放 BGM | 游戏开始 |
| **FestivalMode** | 节日 BGM | 进入节日 |
| **MinigameMode** | 小游戏 BGM | 进入小游戏 |
| **HanhaiMode** | 瀚海区域 BGM | 进入沙漠 |
| **BattleMode** | 战斗 BGM | 进入战斗 |
| **Muted** | 静音模式 | 玩家关闭音频 |

### Interactions with Other Systems

**上游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **F01 TimeSeasonSystem** | 硬依赖 | 订阅季节/时段变化，切换 BGM |
| **F02 WeatherSystem** | 硬依赖 | 订阅天气变化，应用天气修饰器 |
| **C01 PlayerStatsSystem** | 软依赖 | 受伤时播放受伤音效 |

**下游依赖 (依赖 F05 的系统)**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| 所有游戏系统 | 硬依赖 | 触发各自的操作音效 |
| U11 SettingsUI | 硬依赖 | 音量控制 UI |

### 提供给下游的 API

```gdscript
class_name AudioSystem extends Node

## 单例访问
static func get_instance() -> AudioSystem

## 音量控制
func set_sfx_enabled(enabled: bool) -> void
func set_bgm_enabled(enabled: bool) -> void
func set_sfx_volume(volume: float) -> void  # 0.0 - 1.0
func set_bgm_volume(volume: float) -> void  # 0.0 - 1.0

## BGM 控制
func start_bgm() -> void
func stop_bgm() -> void
func switch_to_seasonal_bgm() -> void  # 切换到当前季节 BGM
func start_festival_bgm(season: Season) -> void
func start_minigame_bgm(minigame_type: String) -> void
func start_battle_bgm() -> void
func start_hanhai_bgm() -> void
func end_festival_bgm() -> void
func end_hanhai_bgm() -> void

## SFX 播放接口
func play_sfx_click() -> void
func play_sfx_water() -> void
func play_sfx_plant() -> void
func play_sfx_harvest() -> void
func play_sfx_dig() -> void
func play_sfx_buy() -> void
func play_sfx_coin() -> void
func play_sfx_level_up() -> void
func play_sfx_attack() -> void
func play_sfx_hurt() -> void
func play_sfx_victory() -> void
func play_sfx_fish_reel() -> void
func play_sfx_fish_catch() -> void
func play_sfx_mine() -> void
func play_sfx_sleep() -> void
# ... 其他 60+ SFX

## 信号定义
signal bgm_changed(bgm_type: String)
signal sfx_triggered(sfx_type: String)
```

## Formulas

### 1. 音量转分贝

```
db = 20 * log10(volume)  # volume > 0
db = -infinity            # volume = 0
```

### 2. 天气修饰器

| 天气 | 节奏系数 | 音量系数 | 波形 | 环境音量 | 失谐量 |
|------|----------|----------|------|----------|--------|
| sunny | 1.0 | 1.0 | triangle | 0 | 0 |
| rainy | 1.15 | 0.85 | triangle | 0.04 | 5 |
| stormy | 0.9 | 0.75 | sawtooth | 0.06 | 10 |
| snowy | 1.25 | 0.7 | sine | 0.02 | 8 |
| windy | 0.95 | 0.9 | triangle | 0.05 | 3 |
| green_rain | 1.1 | 0.8 | triangle | 0.05 | 6 |

### 3. 时段修饰器

| 时段 | 音量系数 | 节奏系数 | 失谐偏移 | 低音量系数 |
|------|----------|----------|----------|------------|
| morning | 1.0 | 1.0 | 0 | 0.8 |
| afternoon | 0.95 | 1.05 | 0 | 1.0 |
| evening | 0.85 | 1.1 | 3 | 1.1 |
| night | 0.7 | 1.2 | 6 | 1.3 |
| late_night | 0.55 | 1.3 | 10 | 1.5 |

### 4. 五声音阶频率

```
宫 = C, 商 = D, 角 = E, 徵 = G, 羽 = A

C3 = 131 Hz
D3 = 147 Hz
E3 = 165 Hz
G3 = 196 Hz
A3 = 220 Hz
C4 = 262 Hz
D4 = 294 Hz
E4 = 330 Hz
G4 = 392 Hz
A4 = 440 Hz
C5 = 523 Hz
D5 = 587 Hz
E5 = 659 Hz
G5 = 784 Hz
A5 = 880 Hz
```

### 5. SFX 合成参数

```gdscript
# 通用参数
type WaveType = "sine" | "square" | "triangle" | "sawtooth"
default_volume = 0.3
sfx_throttle_interval = 80  # ms

# 示例：收获音效
harvest_notes = [523, 659, 784, 784]  # Hz
harvest_durations = [0.07, 0.07, 0.07, 0.12]  # s
harvest_delays = [0, 55, 110, 220]  # ms
harvest_wave = "square"
harvest_volume = 0.22
```

## Edge Cases

### 1. 应用暂停时音频
- **场景**: 玩家切换应用/锁屏
- **处理**: 暂停时停止 BGM，恢复时继续播放
- **实现**:
```gdscript
# Godot 4.6 实现
var bgm_was_playing := false

func _notification(what: int) -> void:
    match what:
        Node.NOTIFICATION_APPLICATION_PAUSED:
            bgm_was_playing = is_bgm_playing()
            if bgm_was_playing:
                stop_bgm()
        Node.NOTIFICATION_APPLICATION_RESUMED:
            if bgm_was_playing and bgm_enabled:
                resume_bgm()
```

### 2. 静音模式切换
- **场景**: 玩家快速切换静音
- **处理**: 静音时停止所有音频，恢复时从断点继续

### 3. BGM 切换时音频断裂
- **场景**: 节日开始/结束时的 BGM 切换
- **处理**: 使用交叉淡入淡出（crossfade）过渡

### 4. 音效过度触发
- **场景**: 快速连续操作（如龙舟划桨）
- **处理**: 节流机制，80ms 间隔内不重复播放
- **实现**: `lastPlayTime` 时间戳检查

### 5. 音频上下文未初始化
- **场景**: 首次点击时 AudioContext 未启动
- **处理**: 懒加载，首次用户手势时初始化
- **Godot 实现**: `_ready()` 时初始化 AudioServer

### 6. 多个 SFX 同时播放
- **场景**: 快速连击操作
- **处理**: 允许最多 8 个同类型 SFX 叠加
- **实现**: 音效池（AudioPool）管理

### 7. 耳机/扬声器切换
- **场景**: 播放过程中切换音频设备
- **处理**: Godot 自动处理，无需额外代码

### 8. 背景音乐循环点
- **场景**: BGM 循环时出现明显断裂
- **处理**: 精心设计循环点，确保波形连续
- **实现**: 循环段首尾电平为零

## Dependencies

### 上游依赖（音效系统依赖的系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F01** | TimeSeasonSystem | 硬依赖 | 订阅季节/时段变化信号 |
| **F02** | WeatherSystem | 硬依赖 | 订阅天气变化信号 |
| **X02** | SettingsSystem | 软依赖 | 读取音量设置 |

### 下游依赖（依赖音效系统的系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **All Systems** | 所有游戏系统 | 硬依赖 | 触发各自的操作音效 |
| **U11** | SettingsUI | 硬依赖 | 音量控制界面 |
| **M01-M11** | Mini-game 系统 | 硬依赖 | 小游戏专属 BGM |

### 关键接口契约

```gdscript
## 订阅的信号

# F01 TimeSeasonSystem
signal season_changed(season: Season, year: int)  # 注意：带 year 参数
signal hour_changed(hour: int)

# F02 WeatherSystem
signal weather_changed(new_weather: WeatherType, old_weather: WeatherType)  # 注意：带两个参数

## 信号发射

signal bgm_changed(bgm_type: String)
signal sfx_triggered(sfx_type: String)
```

## Tuning Knobs

### 音量配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `SFX_ENABLED` | true | bool | SFX 总开关 |
| `BGM_ENABLED` | true | bool | BGM 总开关 |
| `SFX_VOLUME` | 0.3 | 0.0-1.0 | SFX 默认音量 |
| `BGM_VOLUME` | 0.15 | 0.0-1.0 | BGM 默认音量 |
| `MASTER_VOLUME` | 1.0 | 0.0-1.0 | 主音量 |

### SFX 配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `SFX_THROTTLE_MS` | 80 | 20-200 | 音效节流间隔 |
| `SFX_MAX_POLYPHONY` | 8 | 1-16 | 同类型 SFX 最大叠加数 |
| `SFX_POOL_SIZE` | 32 | 8-64 | SFX 对象池大小 |

### BGM 配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `BGM_CROSSFADE_MS` | 500 | 200-2000 | BGM 切换淡入淡出时长 |
| `BGM_WEATHER_TRANSITION` | true | bool | 天气修饰是否过渡 |

### 环境音配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `AMBIENT_ENABLED` | true | bool | 环境音开关 |
| `AMBIENT_VOLUME_RAIN` | 0.04 | 0.0-0.2 | 雨声音量 |
| `AMBIENT_VOLUME_STORM` | 0.06 | 0.0-0.2 | 暴风雨声音量 |
| `AMBIENT_VOLUME_SNOW` | 0.02 | 0.0-0.2 | 雪声音量 |
| `AMBIENT_VOLUME_WIND` | 0.05 | 0.0-0.2 | 风声音量 |

### 调试配置

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `DEBUG_LOG_SFX` | false | 输出 SFX 触发日志 |
| `DEBUG_LOG_BGM` | false | 输出 BGM 切换日志 |
| `DEBUG_MUTE_ALL` | false | 静音所有音频 |

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 所有 80+ SFX 正确触发播放 | 逐个调用 SFX 函数，验证音频输出 |
| **AC-02** | 四季 BGM 正确切换 | 修改季节设置，验证 BGM 变化 |
| **AC-03** | 天气修饰器正确应用 | 切换天气，验证节奏/音量变化 |
| **AC-04** | 时段修饰器正确应用 | 修改游戏时间，验证 BGM 变化 |
| **AC-05** | 节日 BGM 正确覆盖季节 BGM | 进入节日，验证 BGM 切换 |
| **AC-06** | 小游戏 BGM 正确覆盖节日 BGM | 进入小游戏，验证 BGM 切换 |
| **AC-07** | 音量控制正确 | 调整音量，验证音频输出变化 |
| **AC-08** | 静音模式正确工作 | 关闭音频，验证无声音输出 |

### 性能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **PC-01** | SFX 延迟 < 50ms | 从触发到声音输出的时间 |
| **PC-02** | BGM 内存占用 < 20MB | 使用 Profiler 测量 |
| **PC-03** | 同屏 50+ SFX 不卡顿 | 快速触发多个 SFX |
| **PC-04** | BGM 循环无明显断裂 | 长时间播放 BGM |

### 兼容性验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CC-01** | PC/Android/iOS 音频同步 | 各平台测试音频同步 |
| **CC-02** | 耳机/扬声器自动切换 | 播放时切换音频设备 |
| **CC-03** | 锁屏后音频继续/停止 | 移动端测试锁屏行为 |

### 音频质量验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AQ-01** | BGM 无削波失真 | 使用音频分析工具检查 |
| **AQ-02** | SFX 无爆音 | 快速连续触发 SFX |
| **AQ-03** | BGM 循环点无缝 | 长时间收听循环 BGM |

## Open Questions

| # | 问题 | 状态 | 负责人 | 目标日期 |
|---|------|------|--------|----------|
| **OQ-01** | BGM 使用程序化合成还是预录制音频文件？ | 待决定 | 技术 | v1.0 |
| **OQ-02** | 是否需要支持自定义 BGM（玩家上传）？ | 评估中 | 策划 | v1.0 后 |
| **OQ-03** | SFX 是否需要区分不同工具/武器的声音？ | 评估中 | 策划 | v1.0 |
| **OQ-04** | 是否需要空间音频（3D 音效）？ | 拒绝 | - | - |
| **OQ-05** | 环境音是否需要定位（如只在下雨区域听到雨声）？ | 待决定 | 技术 | v1.0 |

### 问题详情

**OQ-01 BGM 实现方案**
> **选项 A**: 程序化合成（Tone.js 迁移方案）
> - 优点：无需音频文件，节省空间，支持动态修改
> - 缺点：合成质量可能不如专业音频，需要更多 CPU
>
> **选项 B**: 预录制音频文件（传统方案）
> - 优点：音频质量高，可以使用外部作曲
> - 缺点：占用存储空间，需要音频制作流程
>
> **建议**: MVP 阶段使用程序化合成，后续可添加预录制 BGM 选项

**OQ-03 工具/武器音效区分**
> 当前设计：所有攻击使用 `sfxAttack()`
> 可选改进：不同武器有不同的攻击音效
> - 剑：金属撞击
> - 锤子：沉重钝击
> - 弓：弦声
> 需要更多 SFX 函数和数据配置
