# Sprint 3 -- 2026-05-06 to 2026-05-19

## Sprint Goal

**实现钓鱼系统和鱼类收集：玩家可以在钓鱼点进行钓鱼，捕获鱼类存入背包并获得经验。**

## 背景

### Sprint 2 回顾
- ✅ S2-T1 ~ T8 全部完成
- ✅ 农场核心玩法就绪（地块、工具、技能、HUD）
- ✅ 导航系统实现
- ✅ 单元测试扩展

### Sprint 3 目标
- 实现钓鱼系统基础功能
- 实现鱼类数据定义
- 钓鱼小游戏核心机制

## Capacity

| 项目 | 值 |
|------|-----|
| 总天数 | 14天 |
| 缓冲 (20%) | 3天 |
| 可用天数 | 11天 |
| 团队 | 1人 (独立开发者) |

## Sprint 3 详细任务

### Must Have (P0) - 核心路径

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| S3-T1 | 鱼类数据定义 | Dev | 2 | F03 | 60种鱼类定义，包含6个钓鱼点数据 |
| S3-T2 | FishingSystem Autoload | Dev | 3 | S3-T1, C02 | 抛竿/提竿/咬钩逻辑，鱼类选择 |
| S3-T3 | 钓鱼小游戏核心 | Dev | 4 | S3-T2 | 时机判定（浮标下沉），搏鱼机制 |
| S3-T4 | 钓鱼UI集成 | Dev | 2 | S3-T2, S3-T3 | 浮标动画，力量/压力条显示 |

### Should Have (P1) - 扩展功能

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| S3-T5 | 钓鱼技能集成 | Dev | 1 | C03, S3-T2 | 钓鱼技能加成，经验获取 |
| S3-T6 | 鱼饵系统 | Dev | 2 | S3-T2, F03 | 鱼饵消耗，效果加成 |

### Nice to Have (P2)

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| S3-T7 | 辅助模式 | Dev | 1 | S3-T3 | 放大安全区，简化时机 |
| S3-T8 | 鱼类图鉴 | Dev | 1 | S3-T1 | 收集进度显示 |

## 工作量估算

| 类别 | 任务数 | 总天数 |
|------|--------|--------|
| Must Have | 4 | 11天 |
| Should Have | 2 | 3天 |
| Nice to Have | 2 | 2天 |
| **总计** | **8** | **16天** |

**注**: 预估16天超出可用11天，优先完成 Must Have (S3-T1 ~ T4)

## 任务优先级

```
Sprint 3 优先级排序:
1. S3-T1 鱼类数据定义 (2天) - 阻塞钓鱼系统
2. S3-T2 FishingSystem (3天) - 核心逻辑
3. S3-T3 钓鱼小游戏 (4天) - 核心交互
4. S3-T4 钓鱼UI (2天) - UI集成
---
Must Have 总计: 11天 (刚好在缓冲范围内)
```

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| 无 | Sprint 2 全部完成 | - |

## 风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 钓鱼小游戏时序复杂 | 中 | 高 | 简化 MVP 版本，延迟搏鱼机制 |
| 鱼类数据量大 | 低 | 中 | 分批实现，先完成基础鱼类 |
| 动画资源缺失 | 高 | 低 | 使用程序生成/占位符 |

## Dependencies on External Factors

- **ItemDataSystem**: `design/gdd/foundation/item-data-system.md` (✅ 已完成)
- **InventorySystem**: `design/gdd/core/inventory-system.md` (✅ 已完成)
- **SkillSystem**: `design/gdd/core/skill-system.md` (✅ 已完成)
- **Fishing GDD**: `design/gdd/feature/fishing-system.md` (✅ Approved)
- **Fishing Mini-game GDD**: `design/gdd/minigames/fishing-mini-game.md` (✅ Designed)

## Definition of Done for this Sprint

- [ ] 所有 Must Have 任务完成
- [ ] 玩家可以在钓鱼点抛竿
- [ ] 浮标显示并等待鱼咬钩
- [ ] 时机小游戏正常工作
- [ ] 成功捕获鱼类存入背包
- [ ] 钓鱼技能经验正确增加
- [ ] 代码符合命名规范
- [ ] Git 提交包含任务 ID

## 参考文档

- **钓鱼系统设计**: `design/gdd/feature/fishing-system.md`
- **钓鱼小游戏设计**: `design/gdd/minigames/fishing-mini-game.md`
- **物品数据系统**: `design/gdd/foundation/item-data-system.md`
- **技能系统**: `design/gdd/core/skill-system.md`
- **库存系统**: `design/gdd/core/inventory-system.md`

## 每日检查点

| 日期 | 目标 | 状态 |
|------|------|------|
| Day 1-2 | S3-T1 完成 | [ ] |
| Day 3-5 | S3-T2 完成 | [ ] |
| Day 6-9 | S3-T3 完成 | [ ] |
| Day 10-11 | S3-T4 完成 | [ ] |
| Day 12-14 | S3-T5/T6 (视进度) | [ ] |

---

*最后更新: 2026-04-09*
