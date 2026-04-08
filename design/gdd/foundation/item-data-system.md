# 物品数据系统 (ItemData System)

> **状态**: In Design
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: F03
> **Implements Pillar**: 所有系统依赖的基础数据层

## Overview

物品数据系统是游戏的基础数据层，定义和管理所有物品的配置数据（ItemDef）。系统不持有物品实例（由 C02 InventorySystem 管理），而是提供只读的物品定义查询接口。物品数据被 12+ 个游戏系统依赖，包括库存、商店、钓鱼、采矿、烹饪、加工、装备等。所有物品数据以 Godot Resource 形式存储，支持热更新和编辑器编辑。

## Player Fantasy

物品数据系统是"隐形的基础设施"——玩家不会直接与它互动，但它的设计质量决定了整个游戏的深度和一致性。玩家应该感受到：

- **物品的多样性** — 超过 400+ 物品，每种都有独特的图标、描述和用途
- **品质的价值感** — normal/fine/excellent/supreme 品质让收集变得有意义
- **数据的一致性** — 物品价格、效果、数值在所有系统中保持一致
- **探索的惊喜** — 从钓鱼、采矿、种植中发现的每种新物品都经过精心设计

**Reference games**: Stardew Valley 的物品系统让玩家觉得每种东西都有用；Rune Factory 的物品数据层让所有系统协同工作。

**This is NOT a "system players love"** — it's infrastructure that makes other systems loveable.

## Detailed Design

### Core Rules

1. **物品分类体系（24 类）**
   | 分类 | 示例 | 是否可堆叠 | 是否可食用 |
   |------|------|-----------|-----------|
   | `seed` | 种子 | ✅ | ❌ |
   | `crop` | 作物收获 | ✅ | ✅ |
   | `fish` | 鱼 | ✅ | ✅ |
   | `ore` | 矿石 | ✅ | ❌ |
   | `gem` | 宝石 | ✅ | ❌ |
   | `food` | 烹饪成品 | ✅ | ✅ |
   | `material` | 木材、竹子 | ✅ | ❌ |
   | `weapon` | 武器 | ❌ | ❌ |
   | `ring` | 戒指 | ❌ | ❌ |
   | `hat` | 帽子 | ❌ | ❌ |
   | `shoe` | 鞋子 | ❌ | ❌ |
   | `machine` | 洒水器、加工机 | ❌ | ❌ |
   | `misc` | 杂物 | ✅ | 部分 |
   | ... | ... | ... | ... |

2. **物品品质系统（4 级）**
   - `normal`: 普通品质，白色文字
   - `fine`: 优秀品质，绿色文字
   - `excellent`: 精良品质，蓝色文字
   - `supreme`: 史诗品质，紫色文字

3. **物品定义数据结构 (ItemDef)**
   ```gdscript
   class_name ItemDef extends Resource
   @export var id: StringName           # 唯一标识符
   @export var name: String             # 显示名称
   @export_multiline var description: String  # 物品描述
   @export var category: ItemCategory   # 物品分类
   @export var sell_price: int          # 售出价格（基础价）
   @export var icon_path: String        # 图标资源路径

   # 可选字段（根据物品类型启用）
   @export var edible: bool = false
   @export var stamina_restore: int = 0  # 食用恢复体力
   @export var health_restore: int = 0   # 食用恢复生命

   # 品质修正（数值类物品）
   @export var quality_multipliers: Dictionary = {
       "normal": 1.0,
       "fine": 1.25,
       "excellent": 1.5,
       "supreme": 2.0
   }
   ```

4. **品质价格修正**
   ```
   actual_sell_price = base_price × quality_multiplier
   ```
   | 品质 | 修正系数 |
   |------|----------|
   | normal | 1.0 |
   | fine | 1.25 |
   | excellent | 1.5 |
   | supreme | 2.0 |

5. **数据加载策略**
   - **启动时加载**: 所有 ItemDef Resource 在游戏启动时加载到内存
   - **延迟加载**: 大型数据（如 400+ 作物变种）使用 resource loader
   - **热更新支持**: 数据文件支持 .tres/.res 格式，方便热更新

6. **数据验证规则**
   - `id` 必须唯一，格式为 `snake_case`（如 `copper_ore`）
   - `category` 必须是有效的 ItemCategory 枚举值
   - `sell_price` >= 0
   - 可食用物品必须有 `stamina_restore` 或 `health_restore`

### States and Transitions

物品数据系统是纯数据层，不持有运行时状态。以下是关键状态和生命周期：

| 状态 | 描述 | 数据内容 | 触发时机 |
|------|------|----------|----------|
| **Loaded** | 所有 ItemDef 已加载 | `items: Dictionary[id -> ItemDef]` | 游戏启动完成 |
| **HotReload** | 热更新重新加载 | `items` 替换为新数据 | 数据文件变更（开发模式） |
| **Disposed** | 释放内存 | 无 | 游戏退出 |

**状态转换**:
- `Game Start` → `Loaded`: 加载所有 .tres 数据文件
- `Loaded` → `HotReload`: 编辑器修改数据时自动重载（开发模式）
- `HotReload` → `Loaded`: 重载完成
- `Any` → `Disposed`: 游戏退出

**注意**: 生产环境下不支持热更新，避免数据不一致风险。

### Interactions with Other Systems

**上游依赖**: 无（Foundation 层，最底层）

**下游依赖 (依赖 F03 的系统)**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **C02 InventorySystem** | 硬依赖 | 查询 ItemDef 获取物品显示信息、价格 |
| **P06 ShopSystem** | 硬依赖 | 查询物品购买价格、展示商品信息 |
| **P04 CookingSystem** | 硬依赖 | 查询食材定义、产出食物定义 |
| **P05 ProcessingSystem** | 硬依赖 | 查询加工配方、输入输出物品 |
| **C08 EquipmentSystem** | 硬依赖 | 查询武器/装备/戒指定义 |
| **P02 FishingSystem** | 硬依赖 | 查询鱼类定义、售卖价格 |
| **P03 MiningSystem** | 硬依赖 | 查询矿石/宝石定义 |
| **P01 AnimalHusbandrySystem** | 硬依赖 | 查询动物产品定义 |
| **P11 MuseumSystem** | 硬依赖 | 查询捐赠物品定义 |
| **C07 NPCFriendshipSystem** | 硬依赖 | 查询礼物偏好数据 |
| **P09 AchievementSystem** | 硬依赖 | 查询物品收集成就条件 |
| **F04 SaveLoadSystem** | 硬依赖 | 物品 ID 序列化/反序列化 |

### 提供给下游的 API

```gdscript
class_name ItemDataSystem extends Node

## 单例访问
static func get_instance() -> ItemDataSystem:
    return Engine.get_singleton("ItemDataSystem")

## 数据查询
func get_item_def(item_id: StringName) -> ItemDef:
    """根据 ID 获取物品定义，不存在则返回 null"""

func get_all_items_by_category(category: ItemCategory) -> Array[ItemDef]:
    """获取指定分类的所有物品"""

func get_items_by_tags(tags: Array[String]) -> Array[ItemDef]:
    """获取具有指定标签的所有物品（用于复杂查询）"""

func item_exists(item_id: StringName) -> bool:
    """检查物品 ID 是否存在"""

## 品质相关
func get_quality_multiplier(quality: Quality) -> float:
    """获取品质价格修正系数"""

func calculate_sell_price(base_price: int, quality: Quality) -> int:
    """计算实际售出价格"""

## 数据验证
func validate_all_items() -> Array[String]:
    """验证所有物品数据，返回错误列表"""
```

### 特殊数据表（独立于 ItemDef）

| 数据表 | 文件 | 用途 |
|--------|------|------|
| `CropDef[]` | crops.tres | 作物种植数据（季节、成熟时间、产量） |
| `FishDef[]` | fish.tres | 鱼类数据（出现地点、季节、时间） |
| `RecipeDef[]` | recipes.tres | 烹饪食谱（材料、产出、buff） |
| `WeaponDef[]` | weapons.tres | 武器数据（攻击、暴击率） |
| `ShopDef[]` | shops.tres | 商店配置（商品列表、价格） |

## Formulas

### 1. 物品售价计算

```
actual_sell_price = base_sell_price × quality_multiplier × special_modifier
```

| 品质 (Quality) | 修正系数 |
|----------------|----------|
| normal | 1.0 |
| fine | 1.25 |
| excellent | 1.5 |
| supreme | 2.0 |

**变量说明**:
- `base_sell_price`: ItemDef.sellPrice（物品基础售价）
- `quality_multiplier`: 品质修正系数
- `special_modifier`: 特殊修正（如 NPC 好感度礼物加成，见 C07 NPCFriendship）

**示例**:
```
铜矿 (base=5) × fine(1.25) = 6.25 → 向下取整 = 6 金币
```

### 2. 食物恢复效果

```
actual_stamina = stamina_restore × quality_multiplier
actual_health = health_restore × quality_multiplier
```

### 3. 物品数量限制

```
# 单格堆叠上限（可堆叠物品）
max_stack_size = 9999  # 通用上限

# 特殊物品上限
if item.category == "seed": max_stack = 999
if item.category == "ore": max_stack = 999
if item.category == "gem": max_stack = 999
```

### 4. 装备属性计算

```
weapon.attack = base_attack × (1 + enchantment.attack_bonus / 100)
weapon.crit_rate = base_crit + enchantment.crit_bonus
```

### 5. 物品实例唯一 ID

```
instance_id = "{item_id}_{uuid_v4}"
# 例: "copper_ore_a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

## Edge Cases

1. **物品 ID 不存在**
   - Problem: 查询不存在的物品 ID
   - Resolution: `get_item_def()` 返回 null，调用方应处理 null 情况

2. **重复物品 ID**
   - Problem: 两个 .tres 文件定义了相同 ID
   - Resolution: 启动时验证报错，阻止游戏启动

3. **负数价格**
   - Problem: ItemDef.sellPrice < 0
   - Resolution: 数据验证失败，拒绝加载该物品

4. **可食用物品无恢复值**
   - Problem: edible=true 但 stamina_restore=0 且 health_restore=0
   - Resolution: 视为"装饰性食物"，允许但添加警告日志

5. **品质修正表不完整**
   - Problem: quality_multipliers 字典缺少某些品质
   - Resolution: 使用默认值 1.0 填充缺失项

6. **热更新与运行数据不一致**
   - Problem: 热更新修改了某物品定义，但玩家背包中有该物品
   - Resolution: 库存系统缓存 ItemDef 引用，不重新查询

7. **跨语言文本缺失**
   - Problem: 某物品 name/description 在当前语言文件中缺失
   - Resolution: 回退到中文显示，并在日志中警告

8. **物品数据文件损坏**
   - Problem: .tres 文件格式错误或损坏
   - Resolution: 捕获加载异常，跳过该文件，记录错误

9. **物品分类变更**
   - Problem: 物品被移动到不同分类（如从 material 改为 crop）
   - Resolution: 分类变更需要版本迁移，库存系统需要刷新 UI

10. **最大堆叠溢出**
    - Problem: 玩家尝试堆叠超过 max_stack_size
    - Resolution: 拆分到多个格子，超出部分提示"背包已满"

## Dependencies

### 上游依赖 (F03 依赖其他系统)

无。F03 是 Foundation 层最底层系统，不依赖任何其他系统。

### 下游依赖 (其他系统依赖 F03)

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| C02 库存系统 | 硬依赖 | 查询物品定义、展示信息 |
| C08 武器装备系统 | 硬依赖 | 查询装备/武器/戒指定义 |
| P01 畜牧系统 | 硬依赖 | 查询动物产品定义 |
| P02 钓鱼系统 | 硬依赖 | 查询鱼定义和价格 |
| P03 采矿系统 | 硬依赖 | 查询矿石/宝石定义 |
| P04 烹饪系统 | 硬依赖 | 查询食谱和食材 |
| P05 加工系统 | 硬依赖 | 查询加工配方 |
| P06 商店系统 | 硬依赖 | 查询商品价格和信息 |
| P07 隐藏NPC系统 | 软依赖 | 查询特殊物品定义 |
| P09 成就系统 | 硬依赖 | 查询物品收集条件 |
| P11 博物馆系统 | 硬依赖 | 查询捐赠物品定义 |
| C07 NPC好感度系统 | 硬依赖 | 查询礼物偏好数据 |
| F04 存档系统 | 硬依赖 | 物品 ID 序列化 |
| F05 音效系统 | 软依赖 | 查询物品使用音效 |

### 双向一致性验证

| 系统 | F03 列出依赖 | 该系统列出依赖 F03 | 状态 |
|------|-------------|-------------------|------|
| C02 库存系统 | ✅ | 待验证 | 需确认 |
| P06 商店系统 | ✅ | 待验证 | 需确认 |
| P04 烹饪系统 | ✅ | 待验证 | 需确认 |

## Tuning Knobs

### 数据加载参数

| 参数 | 默认值 | 范围 | 影响 |
|------|-------|------|------|
| `MAX_STACK_SIZE` | 9999 | 100-99999 | 通用堆叠上限 |
| `SEED_STACK_SIZE` | 999 | 100-9999 | 种子堆叠上限 |
| `ORE_STACK_SIZE` | 999 | 100-9999 | 矿石堆叠上限 |
| `AUTO_VALIDATE_ON_LOAD` | true | true/false | 启动时验证数据 |
| `HOT_RELOAD_ENABLED` | false (生产) | true/false | 热更新开关 |

### 品质修正参数

| 参数 | 默认值 | 范围 | 影响 |
|------|-------|------|------|
| `QUALITY_NORMAL_MULT` | 1.0 | 固定 | 普通品质修正 |
| `QUALITY_FINE_MULT` | 1.25 | 1.0-1.5 | 优秀品质修正 |
| `QUALITY_EXCELLENT_MULT` | 1.5 | 1.25-2.0 | 精良品质修正 |
| `QUALITY_SUPREME_MULT` | 2.0 | 1.5-3.0 | 史诗品质修正 |

### 调试参数

| 参数 | 默认值 | 说明 |
|------|-------|------|
| `DEBUG_SHOW_ITEM_IDS` | false | 在 UI 显示物品 ID |
| `DEBUG_UNLOCK_ALL_ITEMS` | false | 解锁所有物品（测试用） |
| `DEBUG_LOG_MISSING_ITEMS` | true | 记录缺失物品查询 |

### 性能参数

| 参数 | 默认值 | 说明 |
|------|-------|------|
| `LAZY_LOAD_THRESHOLD` | 100 | 超过此数量的物品使用延迟加载 |
| `CACHE_SIZE` | 1000 | ItemDef 查询缓存大小 |

## Acceptance Criteria

### 功能测试

1. [ ] **数据加载**
   - [ ] 游戏启动时所有 ItemDef 正确加载
   - [ ] 延迟加载的物品在需要时正确加载
   - [ ] 重复 ID 检测并报错

2. [ ] **数据查询**
   - [ ] `get_item_def(id)` 正确返回 ItemDef
   - [ ] `get_item_def(unknown_id)` 返回 null
   - [ ] `get_all_items_by_category()` 正确过滤

3. [ ] **品质计算**
   - [ ] normal 品质 = base_price × 1.0
   - [ ] fine 品质 = base_price × 1.25
   - [ ] excellent 品质 = base_price × 1.5
   - [ ] supreme 品质 = base_price × 2.0
   - [ ] 向下取整处理正确

4. [ ] **数据验证**
   - [ ] 负数价格被拒绝
   - [ ] 空 ID 被拒绝
   - [ ] 无效 category 被拒绝

5. [ ] **堆叠限制**
   - [ ] 普通物品可堆叠到 9999
   - [ ] 种子/矿石限制为 999
   - [ ] 不可堆叠物品正确处理

### 跨系统集成测试

1. [ ] **C02 库存系统**
   - [ ] 库存正确显示物品名称和图标
   - [ ] 物品价格正确从 ItemDef 获取

2. [ ] **P06 商店系统**
   - [ ] 商品价格从 ItemDef 获取
   - [ ] 新物品自动出现在商店分类中

3. [ ] **P04 烹饪系统**
   - [ ] 食材消耗正确查询 ItemDef
   - [ ] 产出物品定义正确注册

### 性能测试

1. [ ] **启动时间**
   - [ ] 物品数据加载 < 500ms

2. [ ] **查询性能**
   - [ ] 单次 `get_item_def()` < 0.1ms
   - [ ] 1000 次查询 < 10ms

3. [ ] **内存占用**
   - [ ] 所有 ItemDef 内存 < 5MB

### 边界条件测试

1. [ ] **空数据库**
   - [ ] 0 个物品时游戏启动不崩溃

2. [ ] **大量物品**
   - [ ] 10000+ 物品时性能可接受

3. [ ] **并发访问**
   - [ ] 多线程访问不崩溃

## Visual/Audio Requirements

物品数据系统本身不直接产生视觉或音频输出，但规定以下要求：

### 图标资源

| 类型 | 格式 | 分辨率 | 说明 |
|------|------|--------|------|
| 物品图标 | .png | 64×64 | 主图标，白色背景透明 |
| 物品图标（装备） | .png | 128×128 | 装备物品需要更大尺寸 |
| 武器图标 | .png | 128×128 | 武器显示动画帧 |

### 音效资源（由 F05 音效系统提供）

物品相关的音效由各系统定义，F03 提供以下规范：
- 物品使用音效路径: `res://assets/sfx/items/{category}/{item_id}.ogg`
- 默认音效: `res://assets/sfx/items/default.ogg`

## UI Requirements

物品数据系统为 UI 系统提供以下数据接口：

### 物品显示信息

```gdscript
func get_display_info(item_id: StringName) -> Dictionary:
    return {
        "name": item_def.name,
        "description": item_def.description,
        "icon_path": item_def.icon_path,
        "category": item_def.category,
        "sell_price": calculate_sell_price(item_def.sell_price, quality),
        "quality_color": get_quality_color(quality),
        "edible": item_def.edible,
        "stamina_restore": item_def.stamina_restore,
        "health_restore": item_def.health_restore
    }

func get_quality_color(quality: Quality) -> Color:
    match quality:
        "normal": return Color.WHITE
        "fine": return Color.GREEN
        "excellent": return Color.BLUE
        "supreme": return Color.PURPLE
```

### 物品列表显示

- 物品按 `category` 分组显示
- 每组内按 `name` 排序
- 品质用文字颜色区分（白/绿/蓝/紫）

## Open Questions

1. **物品图标工作流**
   - 图标由谁制作？设计师还是程序生成？
   - 是否需要支持 Mod 导入自定义图标？
   - Owner: 需要与 Art Team 讨论

2. **物品数据版本迁移**
   - 当物品 ID 变更时，如何处理旧存档？
   - 建议：保留 ID 别名映射
   - Owner: 需要与 F04 SaveLoadSystem 协调

3. **Mod 支持**
   - 是否支持 Mod 添加新物品？
   - Mod 物品如何注册到 ItemDataSystem？
   - Owner: 需要与 Game Designer 讨论

4. **物品分类扩展性**
   - 未来是否可能新增物品分类？
   - 建议：预留 `custom_category` 字段
   - Owner: 低优先级

5. **物品数据导出/导入**
   - 是否需要 Excel/CSV 导入功能？
   - 用于策划快速调整数值
   - Owner: 工具 Team
