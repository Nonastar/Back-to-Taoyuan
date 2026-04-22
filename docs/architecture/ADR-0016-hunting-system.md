# ADR-0016: 狩猎系统架构

**状态**: Accepted
**日期**: 2026-04-21
**决策者**: Claude Code (Lead Programmer)
**系统 ID**: P14
**参考**: Sprint 7 (S7-T6)

## 问题陈述

Sprint 7 需要实现狩猎系统（MVP）。需要确定：
1. 狩猎系统如何与现有技能系统（SkillSystem）集成
2. 猎物刷新与每日时间系统的交互方式
3. 狩猎数据的配置方式（硬编码 vs 外部化）

## 决策

### 1. 采用技能类型枚举（而非字符串 Key）集成 SkillSystem

**备选方案 A: 字符串 Key**（HuntingSystem 原有方案）
```gdscript
func get_skill_level("hunting"): int  # 字符串Key
```
**问题**: `SkillSystem` 的 `SkillType` 枚举只有 `FARMING/FORAGING/FISHING/MINING/COMBAT`，不包含 `HUNTING`。调用 `get_skill_level("hunting")` 将返回 0 或错误。

**备选方案 B: SkillType 枚举**（被否决）
在 `SkillSystem` 中添加 `HUNTING = 5` 枚举值。
**问题**: 需要修改已稳定的 SkillSystem，增加发布风险。

**采用的方案 C: 独立字符串 Key 接口**
HuntingSystem 通过 `SkillSystem.get_skill_level("hunting")` 独立查询，不依赖 SkillType 枚举。但需要 HuntingSystem 内部维护 "hunting" 技能的数据（经验表、升级逻辑），或等待 SkillSystem 扩展。

> **重要**: 当前实现中 `SkillSystem.get_skill_level()` 只能接受 SkillType 枚举值（int），**不**接受字符串。HuntingSystem 调用的 `SkillSystem.get_skill_level("hunting")` 在运行时不会按预期工作。这需要在后续 Sprint 中解决：
> - **方案 1**: SkillSystem 添加 `get_skill_level_by_name(name: String)` 方法
> - **方案 2**: SkillSystem 添加 `HUNTING = 5` 枚举值
> - **方案 3**: HuntingSystem 使用 SkillSystem 作为数据存储，自己管理狩猎技能状态

**短期缓解**: 在 `hunt_in_area()` 中添加技能等级前置检查，当技能等级 < 1 时拒绝狩猎，防止空引用。

**长期决策**: 延期至 Sprint 9，在 SkillSystem 扩展时一并解决。

### 2. 猎物刷新采用每日重置 + 计时器模式

**备选方案 A: 每日重置**（已采用）
每天睡眠后所有狩猎区域自动刷新猎物。
**优点**: 简单，符合游戏每日循环节奏，玩家无需关注刷新时间。
**缺点**: 不够动态，频繁游玩的玩家可能觉得刷新太慢。

**备选方案 B: 独立计时器刷新**（延期）
每个区域独立计时，刷新时可感知。
**问题**: 需要后台进程管理，复杂度高，MVP 不需要。

### 3. 狩猎数据硬编码常量

**当前**: `AREA_DATA` 和 `PREY_DATA` 以 GDScript 常量定义在 `hunting_system.gd` 中。
**后续**: 在 `assets/data/hunting_data.json` 中外部化，允许在不修改代码的情况下调整平衡。

## 决策原因

1. **MVP 优先**: 在 Sprint 7 时间box内完成核心狩猎逻辑，避免过度工程化
2. **SkillSystem 接口耦合**: SkillSystem 是核心系统，频繁修改有风险；狩猎系统作为独立 Autoload 可以先行实现，待 SkillSystem 扩展后对接
3. **每日重置**: 与游戏时间系统（TimeManager + EventBus）自然集成，无需额外架构

## 后果

| 后果类型 | 描述 |
|---------|------|
| **需要 SkillSystem 扩展** | Sprint 9 前需为 "hunting" 技能添加支持接口 |
| **需要 ADR 更新** | SkillSystem ADR-000X 需记录狩猎技能接口规范 |
| **数据外部化待办** | 平衡调整需要修改代码（Nice-to-Have，延期） |
| **测试依赖** | 狩猎掉落率测试需要 SkillSystem mock |

## 相关文件

- `src/scripts/autoload/hunting_system.gd` — 狩猎系统实现
- `src/scripts/autoload/skill_system.gd` — 技能系统（待扩展）
- `src/scripts/autoload/event_bus.gd` — 事件总线
- `src/scripts/autoload/time_manager.gd` — 时间管理

## 参考

- SkillSystem GDD: `design/gdd/core/skill-system.md`
- Sprint 7 Retrospective: `production/sprints/sprint-07-retrospective.md`
- Sprint 7 Plan: `production/sprints/sprint-07.md`
