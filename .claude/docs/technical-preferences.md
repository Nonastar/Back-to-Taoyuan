# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript (primary), C# (performance-critical systems)
- **Rendering**: Forward+ (3D), 2D native (Canvas)
- **Physics**: Jolt Physics 3D (default), Godot Physics 2D

## Naming Conventions

### GDScript (Primary)
- **Classes**: PascalCase (e.g., `PlayerController`, `FarmPlot`)
- **Variables/functions**: snake_case (e.g., `move_speed`, `plant_crop`)
- **Signals**: snake_case past tense (e.g., `health_changed`, `crop_harvested`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`)
- **Scenes**: PascalCase matching root node (e.g., `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_STAMINA`, `DAY_START_HOUR`)
- **Enums**: PascalCase enum, UPPER_SNAKE_CASE values (e.g., `Season.Spring`)

### C# (Performance-Critical)
- **Classes**: PascalCase (e.g., `InventorySystem`)
- **Public fields/properties**: PascalCase (e.g., `MaxCapacity`)
- **Private fields**: _camelCase (e.g., `_itemCache`)
- **Methods**: PascalCase (e.g., `AddItem()`)
- **Constants**: PascalCase or UPPER_SNAKE_CASE

## Performance Budgets

- **Target Framerate**: 60fps (desktop), 30fps (mobile)
- **Frame Budget**: 16.6ms (desktop), 33.3ms (mobile)
- **Draw Calls**: <200 per frame (target)
- **Memory Ceiling**: 512MB (mobile), 1GB (desktop)

## Testing

- **Framework**: GUT (Godot Unit Tester) for GDScript, NUnit for C#
- **Minimum Coverage**: Core game systems (farming, inventory, skills)
- **Required Tests**: Balance formulas, save/load serialization, skill calculations

## Project Structure

```
res://
├── scenes/              # .tscn files
├── scripts/             # .gd / .cs files
│   ├── autoload/       # Singleton systems
│   ├── components/     # Reusable node components
│   ├── systems/        # Game systems
│   └── ui/             # UI logic
├── resources/          # .tres Resource files
│   └── data/           # Game data definitions
├── assets/             # Imported assets
│   ├── art/
│   ├── audio/
│   └── fonts/
└── addons/             # Editor plugins
```

## Logging Standards

- **一般信息** — 使用 `print()` 输出（如：初始化状态、调试信息、用户操作反馈）
- **重要/警告信息** — 使用 `push_warning()` 输出（如：配置缺失、功能降级、边界条件处理）
- **错误信息** — 使用 `push_error()` 输出（如：数据损坏、致命异常）

## Forbidden Patterns

- `randi()` / `randf()` — use `RandomNumberGenerator` for determinism
- Hardcoded numeric values — use constants or exported variables
- Cyclic scene references — use signals or `get_node()` with paths
- `@tool` scripts in production scenes — only for editor utilities

## Allowed Libraries / Addons

- [None approved yet — add as needed]

## Architecture Decisions Log

- ADR-0001: OOP架构模式 (OOP vs ECS)
- ADR-0002: Autoload系统设计
- ADR-0003: 场景管理与加载策略
- ADR-0004: 数据持久化与存档系统
- ADR-0005: UI/菜单系统架构
- ADR-0006: 物品与数据系统架构
- ADR-0007: 事件/消息系统架构
- ADR-0008: 交互系统架构
- ADR-0009: 音频系统架构
- ADR-0010: 动画系统架构
- ADR-0011: 寻路/导航系统架构
- ADR-0012: 天气特效系统架构
- ADR-0013: 战斗系统架构
- ADR-0014: 迷你游戏框架
- ADR-0015: 玩家交互模式 (点击交互 vs 靠近按键)
