# 存档系统 (SaveLoad System)

> **状态**: Designed
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: F04
> **Implements Pillar**: 玩家进度保存与跨设备同步

## Overview

存档系统管理玩家进度的持久化存储，支持 3 个本地存档槽位和 WebDAV 云同步。系统使用 AES 加密保护存档数据，支持跨平台（PC/Android/iOS）同步。存档包含所有游戏系统的运行时状态，从游戏时间到物品库存、NPC好感度等。玩家可以手动存档、自动存档，以及导出/导入存档文件用于备份或分享。

## Player Fantasy

存档系统给玩家带来**安全感和连续性**。玩家应该感受到：

- **进度被珍视** — 每一次存档都像是一个承诺，"你的劳动成果被安全保存了"
- **云同步的便利** — 在手机上开始游戏，回家可以在 PC 上继续
- **数据的安全性** — AES 加密让玩家知道他们的存档不会被轻易篡改
- **版本迁移的安心** — 即使游戏更新，旧存档也能平滑迁移

**Reference games**: Stardew Valley 的存档系统简洁可靠；Animal Crossing 的云同步让玩家跨设备无缝游戏。

**This is a trust system** — when it works, players don't notice; when it fails, they never forget.

## Detailed Design

### Core Rules

1. **存档槽位**
   - 3 个本地存档槽位（Slot 0, 1, 2）
   - 每个槽位存储：游戏时间、玩家状态、物品库存、所有系统数据
   - 槽位元数据：存档时间、年份、季节、第几天、金币数、玩家名

2. **存档格式**
   ```json
   {
     "version": "1.0.0",
     "game": { ... },           // F01 TimeSeasonSystem
     "player": { ... },         // C01 PlayerStatsSystem
     "inventory": { ... },     // C02 InventorySystem
     "farm": { ... },          // C04 FarmPlotSystem
     "skill": { ... },         // C03 SkillsSystem
     "npc": { ... },           // C07 NPCFriendshipSystem
     "mining": { ... },        // P03 MiningSystem
     "cooking": { ... },       // P04 CookingSystem
     // ... 所有需要持久化的系统
     "savedAt": "2026-04-03T12:00:00Z"
   }
   ```

3. **加密方案**
   - 算法：AES-256-CBC（与 CryptoJS AES 兼容）
   - 密钥：硬编码常量 + 平台盐值混淆
   - 存储格式：Base64 编码的密文

4. **自动存档**
   - 触发时机：每日结算时（睡眠/强制昏厥）
   - 保存位置：当前活跃槽位
   - 覆盖策略：始终覆盖，不创建新文件

5. **手动存档**
   - 触发时机：玩家主动点击存档按钮
   - 保存位置：玩家选择的槽位
   - 覆盖确认：覆盖已有存档时提示确认

6. **WebDAV 云同步**
   - 支持：坚果云、Nextcloud、ownCloud 等标准 WebDAV 服务器
   - 同步内容：3 个存档槽位
   - 冲突处理：本地优先，不自动覆盖云端
   - 连接测试：支持 PROPFIND/PUT/GET 操作

7. **导出/导入**
   - 导出格式：`.tyx` 文件（加密的存档数据）
   - 导入验证：解密验证通过后才写入本地槽位

8. **存档数据验证**
   - Version 字段存在性检查
   - JSON 格式校验
   - 关键字段存在性（game, player）
   - 加密完整性（AES 解密验证）

### States and Transitions

| 状态 | 描述 | 数据内容 | 触发时机 |
|------|------|----------|----------|
| **Idle** | 无活跃存档 | 无 | 游戏启动/存档加载完成 |
| **SlotSelected** | 已选择存档槽位 | `selectedSlot: int` | 玩家选择槽位 |
| **Loading** | 正在加载存档 | 加载进度 | `loadFromSlot()` 执行中 |
| **Saving** | 正在保存存档 | 保存进度 | `saveToSlot()` 执行中 |
| **Syncing** | 正在云同步 | 同步进度 | `uploadSave()`/`downloadSave()` 执行中 |
| **Exporting** | 正在导出文件 | 导出进度 | `exportSave()` 执行中 |
| **Importing** | 正在导入文件 | 导入验证状态 | `importSave()` 执行中 |
| **Error** | 存档操作失败 | 错误类型 | 任何存档操作异常 |

**状态转换**:
```
Idle → SlotSelected: 玩家选择槽位
SlotSelected → Loading: 玩家点击"加载"
SlotSelected → Saving: 玩家点击"保存"
Loading → Idle: 加载完成或失败
Saving → Idle: 保存完成或失败
Idle → Syncing: 玩家触发云同步
Syncing → Idle: 同步完成或失败
Any → Error: 操作异常
Error → Idle: 错误已处理
```

**活跃槽位状态**:
```
activeSlot: int = -1  # -1 表示无活跃槽位
activeSlot >= 0       # 已加载的槽位编号
```

### Interactions with Other Systems

**上游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **F01 TimeSeasonSystem** | 硬依赖 | 订阅时间状态用于存档元数据 |
| **F02 WeatherSystem** | 硬依赖 | 订阅天气状态（可选保存） |
| **C01 PlayerStatsSystem** | 硬依赖 | 订阅玩家状态用于存档 |
| **C02 InventorySystem** | 硬依赖 | 订阅物品库存用于存档 |

**下游依赖 (依赖 F04 的系统)**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| 所有游戏系统 | 硬依赖 | 每个系统需要实现 `serialize()` 和 `deserialize()` |
| **U12 SaveLoadUI** | 硬依赖 | 订阅存档状态用于 UI 显示 |

### 提供给下游的 API

```gdscript
class_name SaveLoadSystem extends Node

## 单例访问
static func get_instance() -> SaveLoadSystem

## 槽位管理
func get_slots() -> Array[SaveSlotInfo]:
    """获取所有存档槽位信息"""

func get_active_slot() -> int:
    """获取当前活跃槽位（-1 表示无）"""

## 存档操作
func save_to_slot(slot: int) -> bool:
    """保存到指定槽位"""

func load_from_slot(slot: int) -> bool:
    """从指定槽位加载"""

func auto_save() -> bool:
    """自动存档到当前活跃槽位"""

func delete_slot(slot: int) -> bool:
    """删除指定槽位"""

## 云同步
func test_webdav_connection() -> bool:
    """测试 WebDAV 连接"""

func upload_save(slot: int) -> Dictionary:
    """上传存档到云端"""

func download_save(slot: int) -> Dictionary:
    """从云端下载存档"""

func list_remote_saves() -> Array:
    """列出云端存档"""

## 导出导入
func export_save(slot: int) -> bool:
    """导出存档为 .tyx 文件"""

func import_save(slot: int, file_content: String) -> bool:
    """从 .tyx 文件导入存档"""

## 数据验证
func validate_save_data(data: Dictionary) -> bool:
    """验证存档数据完整性"""

## 信号定义
signal save_started(slot: int)
signal save_completed(slot: int, success: bool)
signal load_started(slot: int)
signal load_completed(slot: int, success: bool)
signal cloud_sync_started()
signal cloud_sync_completed(results: Dictionary)
signal error_occurred(error_code: String, message: String)
```

### 各系统的序列化接口

```gdscript
## 每个需要存档的系统必须实现:

## 返回存档数据的字典
func serialize() -> Dictionary:
    pass

## 从存档数据恢复状态
func deserialize(data: Dictionary) -> void:
    pass

## 示例（TimeSeasonSystem）:
# serialize() 返回: {"year": 1, "season": "spring", "day": 5, "hour": 14}
# deserialize(data) 读取: self.year = data.year
```

## Formulas

### 1. 存档密钥生成

```
# Godot 实现（兼容 CryptoJS AES）
encryption_key = SHA256(ENCRYPTION_CONSTANT + platform_salt).substr(0, 32)
iv = MD5(timestamp).substr(0, 16)

# CryptoJS 等效（Vue 端）
key = CryptoJS.SHA256(ENCRYPTION_CONSTANT + platform_salt)
cipher = CryptoJS.AES.encrypt(json_string, key)
```

### 2. 存档数据校验和

```
# 计算存档数据校验和（用于检测损坏）
checksum = MD5(JSON.stringify(data.game) + JSON.stringify(data.player) + ...)

# 存档元数据
metadata = {
    "year": data.game.year,
    "season": data.game.season,
    "day": data.game.day,
    "money": data.player.money,
    "playerName": data.player.name,
    "savedAt": ISO8601_timestamp,
    "checksum": checksum
}
```

### 3. 存档槽位文件路径

```
# Godot 实现
slot_key = "user://saves/slot_{slot}.tres"
slot_meta_key = "user://saves/slot_{slot}_meta.tres"

# 导出文件
export_filename = "桃园乡_存档{slot+1}_第{year}年{season_chinese}第{day}天.tyx"
```

### 4. 存档大小估算

```
# 单个存档最大估计大小（KB）
estimated_size = {
    "game": 1,           # 时间/季节
    "player": 2,         # 玩家属性
    "inventory": 50,     # 物品库存（300+ 物品）
    "farm": 100,         # 农场数据（大量作物状态）
    "skill": 5,          # 技能
    "npc": 20,           # NPC好感度（34 NPC）
    "other": 50          # 其他系统
}
total = sum(estimated_size) ≈ 228 KB（实际会更小）
```

### 5. 版本兼容性检查

```
# 存档版本格式
version = "1.0.0"  # major.minor.patch

# 版本比较
if save_version.major > current_version.major:
    # 不兼容，需要迁移
elif save_version.major == current_version.major:
    if save_version.minor > current_version.minor:
        # 向前兼容，可以加载
    else:
        # 完全兼容
```

## Edge Cases

### 1. 无存档槽位数据
- **场景**: 首次启动游戏，所有槽位为空
- **处理**: 显示"空槽位"UI，允许玩家创建新游戏
- **验证**: `get_slots()` 返回空数组时不应崩溃

### 2. 存档损坏检测
- **场景**: 存档文件被意外修改、截断或损坏
- **检测**: AES 解密失败、JSON 解析失败、校验和不匹配
- **处理**: 
  - 解密失败 → 提示"存档格式无效"
  - 校验和失败 → 提示"存档可能已损坏"
  - 部分数据缺失 → 尝试加载可用数据，缺失部分使用默认值

### 3. 版本不兼容存档
- **场景**: 存档版本高于游戏版本（major 不同）
- **检测**: `version_compare()` 返回 -1
- **处理**: 
  - 显示"存档版本过高，需要更新游戏"
  - 阻止加载，显示升级提示
- **迁移策略**: minor/patch 版本差可以向前兼容加载

### 4. 存档数据不完整
- **场景**: 新版本添加了系统，旧版本存档缺少该系统数据
- **处理**: `deserialize()` 对缺失字段使用默认值
- **示例**: v1.0.0 存档加载到 v1.1.0（新增农场装饰系统）
- **原则**: 新增系统必须有合理的默认值，不应因缺失数据而崩溃

### 5. 磁盘空间不足
- **场景**: 存档时磁盘空间不足以写入文件
- **检测**: 写入前检查可用空间（估算存档大小 × 2）
- **处理**: 
  - 写入前检测 → 提示"磁盘空间不足"
  - 写入中失败 → 保留原存档，提示错误
- **原则**: 永远不在写入失败时删除原存档

### 6. 云同步冲突
- **场景**: 本地存档与云端存档均被修改
- **检测**: 上传时发现云端版本更新
- **处理**: 
  - 本地优先策略
  - 询问玩家："覆盖云端"还是"保留云端"
  - 提供"创建云端备份"选项
- **不自动合并**: 游戏存档结构复杂，不做自动合并

### 7. WebDAV 连接超时
- **场景**: 网络不稳定导致 WebDAV 请求超时
- **处理**: 
  - 设置 30 秒超时
  - 超时后提示"连接超时，请检查网络"
  - 自动重试 2 次，间隔 3 秒
- **断点续传**: 不支持（存档文件小，直接重传）

### 8. 导出文件名编码问题
- **场景**: 玩家存档名包含特殊字符
- **处理**: 
  - 中文存档名直接使用（Godot 支持 Unicode 文件名）
  - 特殊符号替换为下划线
  - 禁止字符（\ / : * ? " < > |）直接删除

### 9. 导入恶意文件
- **场景**: 玩家导入的 .tyx 文件是伪造的或包含恶意代码
- **检测**: 
  - 解密后验证 JSON 结构
  - 验证 version 字段存在
  - 验证关键系统数据存在
- **处理**: 
  - 验证失败 → 拒绝导入，提示"存档格式无效"
  - 验证通过 → 导入到选定的槽位
- **沙箱原则**: 导入数据不直接执行任何代码

### 10. 自动存档覆盖当前游玩进度
- **场景**: 玩家在 Slot A 游玩，但 Slot B 才是自动存档位置
- **处理**: 
  - 自动存档始终写入 `activeSlot`
  - 如果 `activeSlot = -1`，创建新存档到 Slot 0
  - 玩家主动切换槽位时重置 `activeSlot`

### 11. 存档时游戏状态不一致
- **场景**: 存档过程中玩家退出游戏
- **处理**: 
  - 使用原子写入：先写临时文件，写入成功后 rename
  - Godot: `DirAccess.copy_file()` + `DirAccess.rename()` 模式
- **检查点**: 任何存档操作开始前保存检查点状态

### 原子写入实现规范

```gdscript
## 原子写入流程（Godot 4.6）
func atomic_save(filepath: String, content: String) -> bool:
    var temp_path = filepath + ".tmp"
    var dir = DirAccess.open(filepath.get_base_dir())

    # 1. 写入临时文件
    var file = FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(content)
    file.close()

    # 2. 验证临时文件写入成功
    if not FileAccess.file_exists(temp_path):
        return false

    # 3. 用临时文件替换原文件（原子操作）
    if dir.file_exists(filepath):
        dir.remove(filepath)  # 先删除原文件
    var error = dir.rename(temp_path, filepath)
    if error != OK:
        dir.remove(temp_path)  # 清理失败的临时文件
        return false

    return true
```

> **注意**: Godot 4.6 中 `DirAccess.rename()` 在不同文件系统间可能不是原子的，
> 但在同一分区/卷内是原子操作。确保 WebDAV 和本地存储使用相同分区。

### 12. 多平台存档格式差异
- **场景**: PC 存档可能在 Android 上无法读取（路径分隔符、换行符等）
- **处理**: 
  - 所有路径使用正斜杠 `/`
  - 不依赖平台特定路径格式
  - Base64 编码确保二进制安全
- **验证**: 每个平台测试读写

## Dependencies

### 上游依赖（存档系统依赖的系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F01** | TimeSeasonSystem | 硬依赖 | 订阅时间状态，用于存档元数据和时间恢复 |
| **F02** | WeatherSystem | 软依赖 | 订阅天气状态，可选保存 |
| **C01** | PlayerStatsSystem | 硬依赖 | 订阅玩家状态（生命、金钱、属性）用于存档 |
| **C02** | InventorySystem | 硬依赖 | 订阅物品库存用于存档，需要 `serialize()`/`deserialize()` |

> ⚠️ **F02 WeatherSystem 依赖冲突说明**:
> F02 WeatherSystem 的 GDD 中存在内部矛盾：
> - Edge Case #6 说"存档**不保存**天气，每日结算时重新 roll"
> - Dependencies 列表说"F04 SaveLoad 是硬依赖...保存 today_weather"
>
> F04 选择**软依赖** F02（可选保存），符合 F02 Edge Case #6 的意图。
> 如果未来需要保存天气，F02 需先修正其内部文档矛盾。

### 下游依赖（依赖存档系统的系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **All Systems** | 所有游戏系统 | 硬依赖 | 每个系统必须实现 `serialize()`/`deserialize()` 方法 |
| **U12** | SaveLoadUI | 硬依赖 | 订阅存档状态信号用于 UI 显示 |

### 关键接口契约

```gdscript
## 存档系统提供给其他系统的接口

# 1. 状态信号（订阅）
signal save_started(slot: int)
signal save_completed(slot: int, success: bool)
signal load_started(slot: int)
signal load_completed(slot: int, success: bool)
signal cloud_sync_started()
signal cloud_sync_completed(results: Dictionary)
signal error_occurred(error_code: String, message: String)

# 2. 查询接口
func get_active_slot() -> int:
    """返回当前活跃槽位，-1 表示无活跃存档"""

func is_save_valid(slot: int) -> bool:
    """检查指定槽位存档是否有效"""

# 3. 各系统需要实现的序列化接口
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

### 双向依赖一致性

> ⚠️ **重要**: 以下系统必须在其 GDD 的 Dependencies 部分列出 F04 SaveLoadSystem

- [ ] C01 PlayerStatsSystem
- [ ] C02 InventorySystem
- [ ] C03 SkillsSystem
- [ ] C04 FarmPlotSystem
- [ ] C05 AnimalHusbandrySystem
- [ ] C06 FishingSystem
- [ ] C07 NPCFriendshipSystem
- [ ] P01 QuestSystem
- [ ] P02 AchievementSystem
- [ ] P03 MiningSystem
- [ ] P04 CookingSystem
- [ ] P05 CraftingSystem
- [ ] P06 RelationshipsSystem
- [ ] U01-U12 UI Systems

## Tuning Knobs

### 存档槽位配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `MAX_SAVE_SLOTS` | 3 | 1-10 | 最大存档槽位数 |
| `DEFAULT_ACTIVE_SLOT` | 0 | 0 to MAX_SAVE_SLOTS-1 | 默认活跃槽位（无存档时） |

### 自动存档配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `AUTO_SAVE_ENABLED` | true | bool | 是否启用自动存档 |
| `AUTO_SAVE_ON_DEATH` | true | bool | 死亡时是否自动存档 |
| `AUTO_SAVE_COOLDOWN` | 60 | 10-300 秒 | 自动存档最小间隔 |

### 加密配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `ENCRYPTION_ALGORITHM` | AES-256-CBC | AES-256-CBC only | 加密算法（不可修改） |
| `KEY_DERIVATION` | SHA256 | SHA256/SHA512 | 密钥派生算法 |
| `IV_GENERATION` | MD5(timestamp) | 16 bytes | IV 生成方式 |

### WebDAV 配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `WEBDAV_TIMEOUT` | 30 | 10-120 秒 | WebDAV 请求超时 |
| `WEBDAV_RETRY_COUNT` | 2 | 0-5 | 失败重试次数 |
| `WEBDAV_RETRY_DELAY` | 3 | 1-10 秒 | 重试间隔 |

### 导出导入配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `EXPORT_FILE_EXT` | .tyx | any valid ext | 导出文件扩展名 |
| `EXPORT_PATH` | user://exports/ | valid path | 默认导出目录 |

### 版本兼容性配置

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `CURRENT_VERSION` | "1.0.0" | 当前存档版本 |
| `COMPATIBLE_MINOR_VERSION` | 0 | 向前兼容的最小 minor 版本 |
| `VERSION_MIGRATION_ENABLED` | true | 是否启用自动版本迁移 |

### 性能配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `SAVE_CHUNK_SIZE` | 4096 | 1024-65536 bytes | 写入缓冲区大小 |
| `PARALLEL_SERIALIZE` | false | bool | 是否异步并行序列化各系统（使用 await 分帧执行） |
| `COMPRESSION_ENABLED` | false | bool | 是否启用 gzip 压缩（需要测试兼容性） |

> **关于 `PARALLEL_SERIALIZE`**:
> GDScript 是单线程语言，"并行"指的是**异步分帧执行**而非真正的多线程。
> 启用后，每个系统的 `serialize()` 调用会被分散到多帧执行，避免单帧卡顿：
> - 帧 1: 序列化 game, player
> - 帧 2: 序列化 inventory, farm
> - 帧 3: 序列化 skill, npc
> - ...
> - 最后一帧: 写入文件
>
> 禁用后，所有系统在同一帧内顺序序列化（更快但可能卡顿）。

### 调试配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `DEBUG_LOGGING` | false | bool | 是否输出详细日志 |
| `SKIP_ENCRYPTION` | false | bool | 开发模式跳过加密 |
| `MOCK_WEBDAV` | false | bool | 使用模拟 WebDAV 服务器 |

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

### 功能性验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 玩家可以创建新游戏并存档到任意槽位 | 选择空槽位 → 创建新游戏 → 存档 → 验证文件存在 |
| **AC-02** | 玩家可以加载任意有效存档 | 选择有存档的槽位 → 点击加载 → 验证游戏状态恢复 |
| **AC-03** | 自动存档在睡眠时触发 | 进行游戏 → 睡眠 → 验证当前槽位存档更新 |
| **AC-04** | 存档数据正确包含所有系统 | 存档 → 解密查看 JSON → 验证所有系统数据存在 |
| **AC-05** | 损坏的存档被正确检测 | 手动修改存档文件 → 尝试加载 → 验证错误提示 |
| **AC-06** | 版本不兼容时显示提示 | 加载高版本存档 → 验证显示版本不兼容提示 |
| **AC-07** | 导出/导入 .tyx 文件正常工作 | 导出存档 → 移动文件 → 导入 → 验证数据一致 |
| **AC-08** | WebDAV 上传下载功能正常 | 配置 WebDAV → 上传存档 → 删除本地 → 下载 → 验证 |
| **AC-09** | 云同步冲突时提示玩家 | 云端有更新时上传 → 验证冲突处理 UI |
| **AC-10** | 存档覆盖时需要确认 | 选择有存档的槽位 → 存档 → 验证确认对话框 |

### 性能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **PC-01** | 单个存档保存时间 < 500ms | 使用 Timer 测量 `save_to_slot()` 执行时间 |
| **PC-02** | 单个存档加载时间 < 500ms | 使用 Timer 测量 `load_from_slot()` 执行时间 |
| **PC-03** | 存档文件大小 < 500KB | 完整存档后检查文件大小 |
| **PC-04** | 内存占用峰值 < 10MB | Profiler 测量存档期间最大内存 |

### 兼容性验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CC-01** | PC 存档可在 Android 读取 | PC 存档导出 → 传输 → Android 导入 → 验证 |
| **CC-02** | v1.0.0 存档可加载到 v1.1.0 | 创建 v1.0.0 存档 → 修改版本号 → 加载 → 验证 |
| **CC-03** | 特殊字符存档名正确处理 | 使用中文/emoji存档名 → 存档/加载 → 验证 |
| **CC-04** | 加密存档无法被普通文本编辑器读取 | 存档 → 用编辑器打开 → 验证显示乱码 |

### 安全验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **SC-01** | 篡改存档导致校验失败 | 修改存档内容 → 加载 → 验证校验和检测 |
| **SC-02** | 恶意构造的 JSON 被拒绝 | 导入非游戏格式 JSON → 验证拒绝 |
| **SC-03** | 存档密钥不硬编码在可执行文件中 | 搜索二进制文件 → 验证无明文密钥 |

### 边界情况验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **BC-01** | 磁盘空间不足时保留原存档 | 模拟磁盘满 → 存档 → 验证原存档未损坏 |
| **BC-02** | 网络超时后正确处理 | 断开网络 → WebDAV 操作 → 验证超时提示 |
| **BC-03** | 存档过程中强制退出后恢复 | 存档中强制退出 → 重启 → 验证原存档完整 |
| **BC-04** | 所有槽位为空时 UI 正常显示 | 删除所有存档 → 打开存档菜单 → 验证无崩溃 |

## Open Questions

| # | 问题 | 状态 | 负责人 | 目标日期 |
|---|------|------|--------|----------|
| **OQ-01** | 是否支持存档继承系统（多个存档共享部分数据）？ | 开放 | 策划 | v1.0 后 |
| **OQ-02** | 云同步是否需要增量更新（只同步变化部分）？ | 开放 | 技术 | v1.0 |
| **OQ-03** | 是否需要支持存档截图/缩略图预览？ | 开放 | 美术 | v1.0 |
| **OQ-04** | 多人模式存档如何处理（各玩家独立存档 vs 共享世界）？ | 开放 | 策划 | 待定 |
| **OQ-05** | 是否需要存档迁移向导（引导用户处理旧格式）？ | 待决定 | 策划 | v1.1 |
| **OQ-06** | 存档加密密钥是否由玩家设置（牺牲便利性换取安全性）？ | 拒绝 | - | - |
| **OQ-07** | 是否需要 Steam Cloud / Google Play Games 集成而非纯 WebDAV？ | 评估中 | 技术 | v1.0 后 |
| **OQ-08** | 自动存档频率是否可配置（每天/每次区域切换/每10分钟）？ | 待决定 | 策划 | v1.0 |

### 问题详情

**OQ-01 存档继承系统**
> 参考：RimWorld 的 "从该存档开始" 选项，允许新存档继承部分设置
> 需要评估实现复杂度与玩家价值比

**OQ-02 增量云同步**
> 当前方案每次上传完整存档（~200KB）
> 增量同步可减少带宽，但实现复杂度高
> 建议：先做完整同步 MVP，后续优化
