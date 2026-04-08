# 库存系统 (Inventory System)

> **状态**: In Design
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: C02
> **Implements Pillar**: 物品管理与资源循环

## Overview

库存系统管理玩家所有物品的存储、堆叠、检索和整理。系统包含主背包（24格，最大60格）、临时背包溢出缓冲区、工具升级队列、武器/戒指/帽子/鞋子装备系统、套装奖励系统、装备方案预设，以及戒指/帽子/鞋子的合成系统。库存系统是游戏经济的核心枢纽，所有物品的获取、出售、消耗都经过此处。

## Player Fantasy

库存系统给玩家带来**收集的满足感和整理的控制感**。玩家应该感受到：

- **背包满满的成就感** — 看着背包里堆满了各式各样的收获
- **整理的舒适感** — 一键整理后井井有条的背包
- **装备的成就感** — 换上更强力的武器，看着属性提升
- **背包升级的期待** — 容量快满时提醒扩容，解锁更多可能

**Reference games**: Stardew Valley 的背包简洁实用；Rune Factory 的装备系统丰富多样。

## Detailed Design

### Core Rules

#### 1. 主背包系统
- 初始容量：24 格
- 最大容量：60 格（可扩容）
- 单格最大堆叠：999
- 物品按分类→ID→品质排序
- 支持物品锁定（不会被自动清理）

#### 2. 临时背包（溢出缓冲区）
- 容量：10 格
- 当主背包满时，物品自动存入临时背包
- 临时背包物品需要手动移回主背包

#### 3. 物品操作
- **添加物品** (`addItem`): 自动堆叠到已有槽位，溢出时创建新槽位
- **移除物品** (`removeItem`): 支持指定品质，优先消耗低品质
- **查询物品** (`getItemCount`, `hasItem`): 统计总数量

#### 4. 工具系统
- 7 种基础工具：浇水壶、锄头、镐子、鱼竿、镰刀、斧头、平底锅
- 4 个等级：basic → iron → steel → iridium
- 工具升级：2 天等待期（`pendingUpgrade`）
- 工具等级影响体力消耗和蓄力批量操作数量

#### 5. 武器系统
- 武器列表（`ownedWeapons`）存储所有武器
- 当前装备索引（`equippedWeaponIndex`）
- 武器攻击力 = 基础攻击 + 附魔加成（附魔效果由 C08 管理）

#### 6. 戒指系统
- 2 个装备槽位（Slot 1, Slot 2）
- 禁止同 ID 戒指同时装备在两个槽位
- 戒指提供各种属性加成效果

#### 7. 帽子/鞋子系统
- 各 1 个装备槽位
- 帽子和鞋子也提供属性加成

#### 8. 套装系统
- 根据已装备的武器/戒指/帽子/鞋子的组合激活套装奖励
- 套装奖励叠加到 `getEquipmentBonus()`

#### 9. 装备方案系统
- 最多保存 5 个装备预设方案
- 一键切换完整装备配置
- 方案中缺少的装备会提示玩家

#### 10. 合成系统
- 支持戒指、帽子、鞋子的合成
- 合成需要材料（金币 + 物品）
- **注**：装备效果计算（套装奖励、附魔属性）由 **C08 EquipmentSystem** 提供

### States and Transitions

#### 背包状态
| 状态 | 描述 | 条件 |
|------|------|------|
| **Normal** | 主背包有空间 | `items.length < capacity` |
| **Full** | 主背包已满 | `items.length >= capacity` |
| **AllFull** | 主背包+临时背包均满 | `isFull && isTempFull` |

#### 工具升级状态
| 状态 | 描述 | 条件 |
|------|------|------|
| **Idle** | 无升级进行中 | `pendingUpgrade == null` |
| **Upgrading** | 升级等待中 | `pendingUpgrade != null` |

**升级状态转换**:
```
Idle → Upgrading: startUpgrade(type, targetTier)
Upgrading → Idle: dailyUpgradeUpdate() 完成
```

### Interactions with Other Systems

**上游依赖**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **F03 ItemDataSystem** | 硬依赖 | 查询物品定义、分类、价格 |
| **C01 PlayerStatsSystem** | 硬依赖 | 消耗金币购买物品，出售物品获得金币 |

**下游依赖 (依赖 C02 的系统)**:

| 系统 | 依赖类型 | 接口说明 |
|------|----------|----------|
| **C01 PlayerStatsSystem** | 软依赖 | 查询装备属性加成 |
| **P01 AnimalHusbandrySystem** | 硬依赖 | 存储动物产品 |
| **P02 FishingSystem** | 硬依赖 | 存储钓到的鱼 |
| **P03 MiningSystem** | 硬依赖 | 存储矿石和宝石 |
| **P04 CookingSystem** | 硬依赖 | 存储食材和成品 |
| **P05 ProcessingSystem** | 硬依赖 | 存储加工产出 |
| **P06 ShopSystem** | 硬依赖 | 购买/出售物品 |
| **F04 SaveLoadSystem** | 硬依赖 | 存档所有库存数据 |

### 提供给下游的 API

```gdscript
class_name InventorySystem extends Node

## 单例访问
static func get_instance() -> InventorySystem

## 背包操作
func add_item(item_id: String, quantity: int = 1, quality: Quality = NORMAL) -> bool
func remove_item(item_id: String, quantity: int = 1, quality: Quality = NORMAL) -> bool
func get_item_count(item_id: String, quality: Quality = NORMAL) -> int
func has_item(item_id: String, quantity: int = 1) -> bool
func is_full() -> bool
func is_all_full() -> bool

## 背包管理
func expand_capacity() -> bool  # +4 格
func sort_items() -> void
func toggle_item_lock(item_id: String, quality: Quality) -> void

## 临时背包
func move_from_temp(index: int) -> bool
func move_all_from_temp() -> int  # 返回移动数量
func discard_temp_item(index: int) -> bool

## 工具操作
func get_tool(type: ToolType) -> Tool
func get_tool_stamina_multiplier(type: ToolType) -> float
func get_tool_batch_count(type: ToolType) -> int
func start_tool_upgrade(type: ToolType, target_tier: ToolTier) -> bool
func daily_tool_update() -> Dictionary  # {completed: bool, ...}

## 武器操作
func get_equipped_weapon() -> OwnedWeapon
func get_weapon_attack() -> int
func get_weapon_crit_rate() -> float
func add_weapon(def_id: String) -> bool
func equip_weapon(index: int) -> bool
func sell_weapon(index: int) -> Dictionary

## 物品出售
func sell_item(item_id: String, quantity: int = 1) -> Dictionary:
    """出售物品，返回 {success, money_earned, quantity_sold}"""
    # 由 C08 查询装备效果，由 F03 计算售价

## 戒指操作
func equip_ring(ring_index: int, slot: int) -> bool  # slot: 0 或 1
func unequip_ring(slot: int) -> bool
func get_ring_effect_value(effect_type: String) -> float
func add_ring(def_id: String) -> bool
func sell_ring(index: int) -> Dictionary
func craft_ring(def_id: String) -> Dictionary

## 帽子/鞋子操作
func equip_hat(index: int) -> bool
func unequip_hat() -> bool
func add_hat(def_id: String) -> bool
func sell_hat(index: int) -> Dictionary
func craft_hat(def_id: String) -> Dictionary

func equip_shoe(index: int) -> bool
func unequip_shoe() -> bool
func add_shoe(def_id: String) -> bool
func sell_shoe(index: int) -> Dictionary
func craft_shoe(def_id: String) -> Dictionary

## 装备方案
func create_preset(name: String) -> bool
func delete_preset(id: String) -> void
func save_current_to_preset(id: String) -> void
func apply_preset(id: String) -> Dictionary

## 套装信息
func get_active_sets() -> Array[SetInfo]

## 存档接口
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

## Formulas

### 1. 背包容量

```
max_capacity = INITIAL_CAPACITY + expansion_count × 4  # 最大 60
# expansion_count = 累计扩容次数
```

### 2. 工具体力消耗倍率

```
stamina_multiplier = TOOL_TIER_MULTIPLIER[tier]
# basic: 1.0, iron: 0.8, steel: 0.6, iridium: 0.4
```

### 3. 工具批量操作数量

```
batch_count = TOOL_TIER_BATCH[tier]
# basic: 1, iron: 2, steel: 4, iridium: 8
```

### 4. 武器攻击力

```
base_attack = WEAPON_DEFS[def_id].attack
# 附魔加成由 C08 EquipmentEffectSystem 计算
# C02 调用 C08.get_weapon_enchantment_bonus(weapon_index) 获取附魔加成
# total_attack = base_attack + enchant_bonus
```

### 5. 戒指效果查询

```
# effect_type 可选值: "luck", "defense", "stamina", "speed", "attack"
# 由 C08 EquipmentEffectSystem 提供具体加成数值
ring_value = C08.get_ring_effect_value(equipped_ring_index, effect_type)
```

### 6. 物品品质消耗优先级

```
quality_order = [NORMAL, FINE, EXCELLENT, SUPREME]
# 品质枚举定义在 F03 ItemDataSystem
# 移除物品时，优先消耗低品质
```

### 7. 套装数据结构

```gdscript
## 套装奖励定义 (由 C08 EquipmentEffectSystem 提供)
class SetBonus:
    var set_id: String           # 套装唯一标识
    var name: String              # 套装名称
    var required_items: Array     # 需要的物品 def_id 列表
    var required_count: int       # 需要装备的数量
    var effects: Array            # 激活时提供的效果加成

## 装备套装信息 (C02 使用)
class EquipmentSet:
    var set_id: String
    var equipped_count: int       # 当前已装备的数量
    var is_active: bool           # 是否已激活 (达到 required_count)

## 套装激活规则
# 遍历所有已装备物品，检查是否存在同一 set_id 的物品
# 当 equipped_count >= required_count 时，is_active = true
# 激活的套装效果由 C08.get_equipment_bonus() 计算
```

### 8. 套装查找表

```
# 已知套装列表 (示例)
SET_DEFS = {
    "warrior_set": SetBonus(...),    # 战士套装: 武器+戒指+帽子
    "miner_set": SetBonus(...),      # 矿工套装: 镐子+鞋子+戒指
    "fisher_set": SetBonus(...)      # 渔夫套装: 鱼竿+戒指+帽子
}

# 装备物品时:
# 1. 根据 item_id 查找所属套装 (from F03 ItemDataSystem)
# 2. 更新 EquipmentSet.equipped_count
# 3. 判断 is_active 是否变化
# 4. 如有变化，通知 C08 重新计算总属性
```

### 9. 武器实例数据结构

```gdscript
## 武器实例 (C02 存储)
class OwnedWeapon:
    var def_id: String        # 物品定义 ID (from F03)
    var instance_id: String   # 唯一实例 ID (uuid)
    # 注意: 附魔数据由 C08 EquipmentEffectSystem 管理，不存储在 C02

## 获取附魔加成 (调用 C08)
func get_weapon_enchantment_bonus(weapon_index: int) -> int:
    return C08.get_weapon_enchantment_bonus(weapon_index)
```

## Edge Cases

### 1. 主背包+临时背包均满
- **场景**: 物品过多
- **处理**: 提示"背包已满"，超出物品丢失

### 2. 移除不存在的物品
- **场景**: `removeItem("unknown", 1)`
- **处理**: 返回 false，不进行任何操作

### 3. 工具升级中再次申请升级
- **场景**: 已有 pendingUpgrade
- **处理**: 返回 false，拒绝新升级

### 4. 卖装备中的武器
- **场景**: 尝试卖出当前装备的武器
- **处理**: 返回失败，提示"不能卖出装备中的武器"

### 5. 同 ID 戒指双槽装备
- **场景**: 尝试将同一戒指装备到两个槽位
- **处理**: 返回 false，禁止

### 6. 装备方案中的物品已不在背包
- **场景**: 应用方案时，方案中的武器已被出售
- **处理**: 成功应用方案，但提示缺失物品

### 7. 旧存档缺少新字段
- **场景**: v1.0 存档加载到新增系统的版本
- **处理**: 使用默认值初始化新字段

### 8. 物品锁定保护
- **场景**: 整理背包时，有物品被锁定
- **处理**: 锁定物品位置不变，不参与合并

### 9. 背包容量已达最大
- **场景**: 60 格时调用 expandCapacity
- **处理**: 返回 false

### 10. 武器出售后索引修正
- **场景**: 卖出装备索引之前的武器
- **处理**: `equippedWeaponIndex` 递减以保持正确引用

## Dependencies

### 上游依赖（C02 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F03** | ItemDataSystem | 硬依赖 | 查询物品定义、价格、分类 |
| **C01** | PlayerStatsSystem | 硬依赖 | 消耗/获得金币 |

### 下游依赖（其他系统依赖 C02）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P01** | AnimalHusbandrySystem | 硬依赖 | 存储动物产品 |
| **P02** | FishingSystem | 硬依赖 | 存储鱼 |
| **P03** | MiningSystem | 硬依赖 | 存储矿石 |
| **P04** | CookingSystem | 硬依赖 | 存储食材 |
| **P05** | ProcessingSystem | 硬依赖 | 存储加工产出、合成材料 |
| **P06** | ShopSystem | 硬依赖 | 购买/出售 |
| **F04** | SaveLoadSystem | 硬依赖 | 存档 |
| **C08** | EquipmentSystem | 硬依赖 | 装备槽位变化时通知更新效果计算 |

> **注意**: 武器/装备详细属性（武器附魔、套装奖励）由 **C08 EquipmentSystem** 定义。
> C02 负责物品存储、装备槽位管理、合成操作；C08 负责装备效果计算（套装加成、附魔属性）。
>
> **职责边界**:
> - **F03 ItemDataSystem**: 定义物品基础数据（名称、价格、图标、分类、Quality 枚举、装备 set_id）
> - **C02 InventorySystem**: 存储物品实例、管理装备槽位、处理物品堆叠、合成操作
> - **C08 EquipmentEffectSystem**: 计算套装奖励、附魔效果、装备总属性加成

### 关键接口契约

```gdscript
## 订阅的信号

# C01 PlayerStatsSystem
signal money_changed(amount: int)

## 发出的信号

signal inventory_changed()
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal equipment_changed(slot: String)  # "weapon", "ring1", "ring2", "hat", "shoe"
signal tool_upgraded(type: ToolType, tier: ToolTier)
```

## Tuning Knobs

### 背包配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `INITIAL_CAPACITY` | 24 | 12-48 | 初始背包格数 |
| `MAX_CAPACITY` | 60 | 24-99 | 最大背包格数 |
| `EXPANSION_AMOUNT` | 4 | 1-8 | 每次扩容格数 |
| `MAX_STACK` | 999 | 100-9999 | 单格最大堆叠数 |
| `TEMP_CAPACITY` | 10 | 5-20 | 临时背包容量 |
| `FULL_WARNING_THRESHOLD` | 3 | 1-10 | 背包快满提醒阈值（剩余格数） |

### 工具配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `TOOL_UPGRADE_DAYS` | 2 | 1-5 | 工具升级等待天数 |
| `BASIC_STAMINA_MULT` | 1.0 | 固定 | 基础工具体力倍率 |
| `IRON_STAMINA_MULT` | 0.8 | 0.5-1.0 | 铁工具体力倍率 |
| `STEEL_STAMINA_MULT` | 0.6 | 0.3-0.8 | 钢工具体力倍率 |
| `IRIDIUM_STAMINA_MULT` | 0.4 | 0.2-0.6 | 铱工具体力倍率 |

### 装备方案配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `MAX_PRESETS` | 5 | 1-10 | 最大装备方案数 |

### 调试配置

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `DEBUG_UNLOCK_CAPACITY` | false | 解锁无限容量 |
| `DEBUG_MAX_STACK` | false | 忽略堆叠限制 |

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 物品添加/堆叠正确 | addItem 相同物品，验证堆叠 |
| **AC-02** | 物品移除正确 | removeItem 验证数量减少 |
| **AC-03** | 背包满时溢出到临时背包 | 填满主背包后再添加 |
| **AC-04** | 工具升级流程正确 | 升级工具，等待 2 天后验证 |
| **AC-05** | 武器装备/切换正确 | equipWeapon 切换武器 |
| **AC-06** | 戒指双槽位禁止同 ID | 尝试将同戒指装备到两槽 |
| **AC-07** | 装备方案保存/应用正确 | 保存方案，切换后应用 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | 商店购买物品 | 从商店购买后 addItem |
| **CS-02** | 商店出售物品 | sellItem 获得金币 |
| **CS-03** | 存档/读档 | serialize/deserialize 验证 |

### 性能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **PC-01** | addItem < 1ms | 1000 个物品测试 |
| **PC-02** | sortItems < 10ms | 60 格物品排序 |

### 边界情况测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **BC-01** | 背包满时添加物品 | 60 格满后再添加 |
| **BC-02** | 工具已满级升级 | iridium 工具调用 upgradeTool |
| **BC-03** | 删除唯一武器 | 尝试卖出最后一武器 |

## Open Questions

| # | 问题 | 状态 | 负责人 | 目标日期 |
|---|------|------|--------|----------|
| **OQ-01** | 是否需要物品丢弃功能（直接删除）？ | 待决定 | 策划 | v1.0 |
| **OQ-02** | 背包 UI 是否需要分类标签页？ | 待决定 | UX | v1.0 |
| **OQ-03** | 临时背包是否需要容量升级？ | 待决定 | 策划 | v1.0 |
| **OQ-04** | 是否需要快捷键快速切换装备方案？ | 待决定 | UX | v1.0 |
