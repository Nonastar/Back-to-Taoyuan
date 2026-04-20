# Sprint 6 -- 2026-04-20 to 2026-05-03

## Sprint Goal

**完成 M3 里程碑开局：商店系统（购买/出售/动物商店）和烹饪系统（食谱/烹饪锅）核心逻辑上线，同步推进本地化和风险关闭。**

## Background

### M2 里程碑收尾
| 系统 | 状态 | 备注 |
|------|------|------|
| C01 玩家属性 | ✅ 完成 | Sprint 3 |
| C02 库存系统 | ✅ 完成 | Sprint 3 |
| C04 农场地块 | ✅ 完成 | Sprint 3/4 |
| C03 技能系统 | ✅ 完成 | Sprint 4 |
| P01 畜牧系统 | ✅ 完成 | Sprint 5 |
| P02 钓鱼系统 | ✅ 完成 | Sprint 5 |

### Sprint 5 回顾
- ✅ 所有 Must Have (P0) 完成：好感度/产出/畜牧UI
- ✅ 所有 Should Have (P1) 完成：钓鱼图鉴/鱼塘管理
- ⚠️ P2 正确延期：疾病系统(代码存在未暴露)、喂食消耗(基础完成)

### Risk Register 需关注项目
| ID | 风险 | 优先级 |
|----|------|--------|
| R-001 | Release证据链不完整 | High |
| R-003 | 本地化未外部化，硬编码字符串 | High |
| R-004 | 鱼塘/图鉴缺少针对性测试 | Medium |
| R-005 | 技术债积累 | Medium |

## Capacity

| 项目 | 值 |
|------|-----|
| 总天数 | 14天 |
| 缓冲 (20%) | 3天 |
| 可用天数 | 11天 |
| 团队 | 1人 (独立开发者) |

## Sprint 6 详细任务

### Must Have (P0) — 商店系统核心

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| S6-T1 | 商店系统基础架构 | Dev | 2天 | ItemData ✅, PlayerStats ✅ | `ShopSystem.gd` Autoload、购买/出售核心逻辑、营业时间检查 |
| S6-T2 | 商店购买UI | Dev | 1天 | S6-T1 | 商品列表显示、购买按钮、余额扣款、背包添加 |
| S6-T3 | 商店出售UI | Dev | 1天 | S6-T1 | 背包物品选择、出售价格计算、金币增加 |
| S6-T4 | 动物商店 | Dev | 1天 | S6-T1, AnimalHusbandry ✅ | 从商店购买动物、放入畜牧系统 |

### Must Have (P0) — 烹饪系统核心

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| S6-T5 | 烹饪系统基础架构 | Dev | 2天 | ItemData ✅, Inventory ✅ | `CookingSystem.gd` Autoload、配方加载、食谱匹配、产出计算 |
| S6-T6 | 烹饪核心逻辑 | Dev | 1天 | S6-T5 | 投入食材、烹饪计时、产出物品、品质继承 |
| S6-T7 | 烹饪UI | Dev | 2天 | S6-T5, S6-T6 | 配方选择、食材显示、烹饪锅状态、产出提示 |

### Should Have (P1) — 本地化 + 测试

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| S6-T8 | 本地化工作流执行 | Dev | 1天 | — | 提取硬编码字符串、生成翻译表、替换tr()调用 |
| S6-T9 | FishPondSystem 单元测试 | Dev | 1天 | FishPondSystem ✅ | add/remove/collect/daily_update 路径覆盖 |
| S6-T10 | FishCompendiumSystem 单元测试 | Dev | 1天 | FishCompendiumSystem ✅ | record/progress 路径覆盖 |

### Nice to Have (P2) — 技术债

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| S6-T11 | game_manager TODO清理 | Dev | 1天 | — | 5个TODO全部关闭或转入Issue |
| S6-T12 | Bug严重性分级文档 | Dev | 0.5天 | — | S1/S2/S3计数器模板建立 |

## 工作量估算

| 类别 | 任务数 | 总天数 |
|------|--------|--------|
| Must Have | 7 | 10天 |
| Should Have | 3 | 3天 |
| Nice to Have | 2 | 1.5天 |
| **总计** | **12** | **14.5天** |

**注**: 预估14.5天超过可用11天。执行策略：
- P0 Must Have 优先，前7天完成
- Should Have 并行推进
- Nice to Have 在缓冲时间内完成或延期

## 任务优先级

```
Sprint 6 优先级排序:
1. S6-T1 商店系统基础 (2天) - P06阻塞所有商店功能
2. S6-T2 商店购买UI (1天) - 核心购买流程
3. S6-T3 商店出售UI (1天) - 核心出售流程
4. S6-T4 动物商店 (1天) - 畜牧系统变现
---
Must Have 商店: 5天
---
5. S6-T5 烹饪系统基础 (2天) - P04阻塞所有烹饪功能
6. S6-T6 烹饪核心逻辑 (1天) - 烹饪计时
7. S6-T7 烹饪UI (2天) - 玩家交互入口
---
Must Have 烹饪: 5天
---
Should Have: 3天 (本地化+测试)
Nice to Have: 1.5天 (技术债)
```

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| S5-T6 畜牧疾病UI | MVP延期，代码已存在 | 0.5天（暴露UI），视时间决定 |
| S5-T7 深度喂食逻辑 | 需商店系统支持多饲料购买 | Sprint 7 |

## 风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 商店/烹饪系统复杂度超预期 | 中 | 高 | MVP限定购买/出售/烹饪基础，后续迭代 |
| 本地化涉及大量文件修改 | 高 | 中 | 独立工作流，批量替换工具辅助 |
| 技术债清理阻塞功能开发 | 低 | 中 | 技术债任务放在冲刺后半段 |
| 鱼塘/图鉴回归风险 | 中 | 中 | 单元测试先行，避免破坏现有功能 |

## Dependencies on External Factors

- **ItemDataSystem**: `design/gdd/foundation/item-data-system.md` (✅ Completed)
- **InventorySystem**: `design/gdd/core/inventory-system.md` (✅ Completed)
- **PlayerStatsSystem**: `design/gdd/core/player-stats-system.md` (✅ Completed)
- **ShopSystem GDD**: `design/gdd/feature/shop-system.md` (✅ Approved)
- **CookingSystem GDD**: `design/gdd/feature/cooking-system.md` (✅ Approved)
- **AnimalHusbandrySystem**: 已完成 (Sprint 5)
- **Localization Workflow**: `/localize` skill

## 设计文档参考

### 商店系统 MVP 范围

**简化版功能**:
- 购买：选择商品 → 扣款 → 添加到背包
- 出售：选择背包物品 → 计算价格 → 获得金币
- 动物商店：从商店购买动物 → 自动放入畜牧系统
- 营业时间检查：显示打烊提示

**MVP排除的功能**:
- ❌ 动态库存（每日进货/限量）
- ❌ 好感度折扣（NPC未实现）
- ❌ 商品解锁条件（任务/季节）
- ❌ 武器店/矿石店（次要商店）

### 烹饪系统 MVP 范围

**简化版功能**:
- 烹饪锅放置：工坊中放置烹饪锅
- 配方选择：显示可用配方（按食材）
- 烹饪执行：投入食材 → 计时 → 产出
- 品质继承：产出品质 = 投入最低品质

**MVP排除的功能**:
- ❌ 烹饪技能升级
- ❌ 特殊厨具加成
- ❌ 食谱发现机制（固定配方）
- ❌ 虚空箱自动烹饪

## Definition of Done for this Sprint

- [ ] 商店可购买商品，余额正确扣减
- [ ] 商店可出售背包物品，金币正确增加
- [ ] 从动物商店购买动物，动物出现在畜牧系统
- [ ] 烹饪锅可放置在工坊
- [ ] 选择配方后，食材消耗正确
- [ ] 烹饪完成后，产出物品进入背包
- [ ] 本地化工作流执行完成（字符串提取）
- [ ] FishPondSystem 单元测试通过
- [ ] FishCompendiumSystem 单元测试通过
- [ ] game_manager TODO 减少3个以上
- [ ] 代码符合命名规范
- [ ] Git 提交包含任务 ID

## 下一步 (Sprint 7 预览)

| 任务 | 描述 | 状态 |
|------|------|------|
| P05 加工系统 | 工坊、21种机器、150+配方 | 待实现 |
| P03 采矿系统 | 矿洞、矿石采集、冶炼 | 待实现 |
| P07 隐藏NPC | 仙缘能力解锁 | In Design |

---

*最后更新: 2026-04-20*
