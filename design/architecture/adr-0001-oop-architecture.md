# ADR-0001: 游戏架构模式选择 - OOP普通模式

## Status
Accepted

## Date
2026-04-08

## Context

### Problem Statement
需要确定桃源乡项目的整体代码架构模式。选项包括传统的面向对象编程(OOP)、实体组件系统(ECS)，或两者的混合模式。架构决策将影响项目的代码组织、开发速度、性能表现和长期可维护性。

### Constraints
- **技术约束**: 必须基于 Godot 4.6 引擎
- **团队约束**: 小型团队（独立开发者），开发资源有限
- **时间约束**: 需要快速迭代，避免过度工程化
- **兼容性**: 需支持后续功能扩展和Bug修复

### Requirements
- 必须支持 46 个游戏系统的实现
- 实体数量估计 500-1000 个同时在线
- 需要清晰的模块划分和系统边界
- 性能需达到 60fps (桌面端)

## Decision

**采用 OOP 普通模式作为项目主架构**，参考 Stardew Valley 的成功实现经验。

### 架构原则

1. **继承为主，组合为辅**
   - 游戏实体通过 Node 继承实现（`Node2D` → `CharacterBody2D` → `Player`）
   - 共享行为通过子类继承复用
   - 复杂实体使用 `Composition` 模式注入组件

2. **Godot 原生特性优先**
   - 利用 `Autoload` 实现全局管理器
   - 使用 `Signal` 实现松耦合通信
   - 使用 `Resource` 实现数据定义

3. **系统边界清晰**
   - 每个游戏系统对应一个 Autoload 管理器
   - 系统间通过明确定义的 API 接口交互
   - 避免跨系统的直接 Node 引用

### 架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                         项目结构                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐     ┌─────────────────┐                    │
│  │   Autoload层    │     │   Scene实例层    │                    │
│  │   (单例系统)     │     │   (游戏实体)     │                    │
│  ├─────────────────┤     ├─────────────────┤                    │
│  │ GameManager     │     │ Player          │                    │
│  │ TimeManager     │     │ NPC             │                    │
│  │ InventorySystem │     │ FarmPlot        │                    │
│  │ AudioManager    │◄────│ Animal          │                    │
│  │ SaveManager     │     │ DroppedItem     │                    │
│  │ ...             │     │ ...             │                    │
│  └─────────────────┘     └─────────────────┘                    │
│            │                         │                            │
│            └───────── Signal ───────┘                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 核心目录结构

```
res://
├── scripts/
│   ├── autoload/           # 全局单例系统
│   │   ├── game_manager.gd
│   │   ├── time_manager.gd
│   │   ├── inventory_system.gd
│   │   ├── audio_manager.gd
│   │   ├── save_manager.gd
│   │   └── ...
│   │
│   ├── entities/           # 游戏实体基类
│   │   ├── base_entity.gd
│   │   ├── character.gd
│   │   └── interactable.gd
│   │
│   ├── components/         # 可复用组件
│   │   ├── health_component.gd
│   │   ├── stamina_component.gd
│   │   └── ...
│   │
│   ├── systems/            # 游戏系统实现
│   │   ├── farming/
│   │   ├── skills/
│   │   ├── combat/
│   │   └── ...
│   │
│   └── ui/                 # UI逻辑
│       ├── hud/
│       ├── menus/
│       └── dialogs/
│
├── scenes/
│   ├── entities/           # 实体场景
│   ├── ui/                 # UI场景
│   └── levels/             # 关卡场景
│
└── resources/
    ├── data/               # 数据定义
    │   ├── items/
    │   ├── crops/
    │   ├── recipes/
    │   └── ...
    └── configs/            # 配置文件
```

### 实体类层次

```
Node
└── CharacterBody2D / Node2D
    ├── Player (玩家角色)
    ├── NPC (非玩家角色)
    │   ├── TownNPC
    │   ├── ShopNPC
    │   └── Monster
    └── InteractableObject
        ├── FarmPlot (农场地块)
        ├── ResourceNode (资源节点)
        ├── Machine (加工机器)
        └── Container (储物容器)

    # 动物实体
    └── Animal
        ├── CoopAnimal (鸡舍动物)
        │   ├── Chicken
        │   ├── Duck
        │   └── ...
        └── BarnAnimal (谷仓动物)
            ├── Cow
            ├── Sheep
            └── ...
```

### 关键接口示例

```gdscript
# 系统接口示例
class_name InventorySystem
extends Node

# 公开API
func add_item(item_id: String, amount: int) -> bool:
    pass

func remove_item(item_id: String, amount: int) -> bool:
    pass

func has_item(item_id: String, amount: int = 1) -> bool:
    pass

func get_item_count(item_id: String) -> int:
    pass

# Signal 定义
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)
signal inventory_full
```

## Alternatives Considered

### Alternative 1: ECS 模式

- **描述**: 采用实体-组件-系统架构，所有行为由组件拼装
- **优点**:
  - 组件复用性极高
  - 数据布局连续，缓存友好
  - 适合大量相似实体（>5000）
  - 性能优秀
- **缺点**:
  - 学习曲线陡峭
  - 实现复杂度高
  - Godot 原生支持有限，需第三方库
  - 开发速度慢，需要更多代码
  - 对于本项目实体数量(1000)性能优势不明显
- **拒绝理由**: 开发成本过高，实体数量未达到需要ECS的性能门槛

### Alternative 2: 混合模式 (OOP + ECS)

- **描述**: ECS 用于粒子/寻路等性能关键系统，OOP 用于游戏逻辑
- **优点**:
  - 兼顾性能和开发效率
  - 特定场景有ECS优势
- **缺点**:
  - 两种架构模式增加认知负担
  - 需要维护两套系统
  - 增加集成复杂度
- **拒绝理由**: 增加不必要的架构复杂度，可在后续按需引入

## Consequences

### Positive

- **开发效率高**: OOP模式直观易懂，开发速度快
- **代码可读性强**: 继承层次清晰，代码结构容易理解
- **Godot原生支持**: 充分利用Godot的Node/Signal/Resource系统
- **参考案例丰富**: Stardew Valley成功证明此架构适合农场模拟
- **维护成本低**: 小团队可快速定位和修复问题
- **学习曲线平缓**: 新成员可快速上手

### Negative

- **大量相似实体时性能受限**: 如需渲染5000+粒子需考虑优化
- **继承层次可能过深**: 需要遵循组合优先原则避免
- **跨实体行为复用不如ECS**: 需通过接口和组合模式弥补

### Risks

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 实体数量超出预期 | 性能下降 | 监控性能，必要时局部优化 |
| 继承层次过深 | 代码复杂 | 使用组合模式，避免深度继承 |
| 系统间耦合过高 | 修改困难 | 强制通过Signal交互，禁止直接引用 |

## Performance Implications

- **CPU**: 预期 60fps 可达，1000实体下帧时间 < 16ms
- **Memory**: 预估 < 200MB（实体数据），符合512MB移动端预算
- **Load Time**: 场景异步加载，预估 < 3秒
- **Network**: N/A (单机游戏)

## Migration Plan

本决策为初始架构，无需迁移。

**未来可能引入ECS的场景**:
1. 粒子系统（草地、落叶、雪花）
2. 寻路系统（NavMesh批量更新）
3. 物理模拟（如果加入复杂物理）

**引入方式**:
- 作为独立系统，不影响整体OOP架构
- 通过 C# 或 Godot GDExtension 实现性能关键部分

## Validation Criteria

1. **开发效率**: 单个系统开发时间 < 预计（需建立基线）
2. **代码质量**: 无循环依赖，依赖层次 < 3层
3. **性能测试**: 1000实体场景下保持 60fps
4. **可维护性**: 新增功能不需修改 > 3个现有系统

## Related Decisions

- **ADR-0002**: Autoload系统设计（规划中）
- **ADR-0003**: 场景管理与加载策略（规划中）
- **ADR-0004**: 数据持久化架构（规划中）

## References

- Stardew Valley 源码分析 (未公开，但社区逆向工程)
- Godot 4.x 官方文档: https://docs.godotengine.org/
- 《Game Programming Patterns》- Robert Nystrom
