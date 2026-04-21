# Sprint 7 -- 2026-04-21 to 2026-05-04

## Sprint Goal

**完成 Sprint 6 延期项扫尾，推进 M3 里程碑基础设施（S5 畜牧完结 + NPC 好感度架构）+ 狩猎系统开局。**

## Background

### M3 里程碑进度

| 系统 | GDD | Sprint |
|------|-----|--------|
| P06 商店系统 | ✅ | Sprint 6 |
| P04 烹饪系统 | ✅ | Sprint 6 |
| P05 加工系统 | ✅ | Sprint 6 |
| P03 采矿系统 | ✅ | Sprint 7 |
| P08 任务系统 | ✅ | Sprint 8 |
| P15 对话/事件系统 | ✅ | Sprint 8 |
| P07 隐藏NPC系统 | ✅ | Sprint 9 |
| P09 成就系统 | ✅ | Sprint 9 |

### Sprint 6 回顾摘要

- **完成率**: ~90%（Nice-to-Have 延期）
- **关键 Bug 修复**: 7个（StatusBar/背包尺寸/出售标签/动物商店等）
- **做得好的**: 代码审查先行、测试驱动修复、配置外部化
- **需改进**: UI调试效率低、物品图标资产缺失

### Sprint 6 Carryover

| 任务 | 原因 | 状态 |
|------|------|------|
| S5-T6 畜牧疾病UI暴露 | Sprint 5代码已存在，UI延期 | 待实现 |
| S5-T7 深度喂食逻辑 | 需商店系统支持多饲料购买 | ✅ 已解锁 |
| S6-T11 game_manager TODO清理 | UI功能需单独设计存档菜单 | 待实现 |
| S6-T12 Bug严重性分级文档 | 优先级低于功能开发 | 待实现 |

## Capacity

| 项目 | 值 |
|------|-----|
| 总天数 | 14天 |
| 缓冲 (20%) | 3天 |
| 可用天数 | 11天 |
| 团队 | 1人 (独立开发者) |

## Sprint 7 详细任务

### Must Have (P0) — Sprint 6 延期项扫尾

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| S7-T1 | 畜牧疾病UI暴露 | Dev | 1天 | AnimalHusbandrySystem ✅(S5) | 患病动物在畜牧UI中显示症状图标，提示治疗按钮 |
| S7-T2 | 深度喂食逻辑 | Dev | 1天 | ShopSystem ✅(S6) | 购买饲料后背包消耗逻辑完善，动物饱食度/好感度联动 |
| S7-T3 | game_manager TODO清理 | Dev | 1天 | — | 5个TODO关闭或转入Issue，存档菜单UI设计文档 |

### Should Have (P1) — NPC好感度系统架构 + 狩猎系统开局

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| S7-T4 | NpcFriendshipSystem 架构设计 | Dev | 2天 | ItemDataSystem ✅, TimeManager ✅ | `NpcFriendshipSystem.gd` Autoload + NPC数据基础结构 + 好感度计算 |
| S7-T5 | Bug严重性分级文档 | Dev | 0.5天 | — | `production/bug-severity.md` 模板建立，S1/S2/S3计数器定义 |
| S7-T6 | HuntingSystem 核心逻辑 | Dev | 2天 | SkillSystem ✅, WeaponEquipment ❌(stub) | `HuntingSystem.gd` Autoload，狩猎技能计时，猎物刷新，掉落计算 |

### Nice to Have (P2) — UI完善 + 测试补全

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| S7-T7 | 地图UI完善 | Dev | 1天 | NavigationSystem ✅ | 区域标记、传送点解锁、当前位置显示 |
| S7-T8 | ShopSystem 单元测试补全 | Dev | 1天 | ShopSystem ✅(S6) | buy/sell/stock/inventory_full 路径覆盖 |
| S7-T9 | CookingSystem 单元测试补全 | Dev | 0.5天 | CookingSystem ✅(S6) | cook_item/eat_dish/mastery 路径覆盖 |

## 工作量估算

| 类别 | 任务数 | 总天数 |
|------|--------|--------|
| Must Have | 3 | 3天 |
| Should Have | 3 | 4.5天 |
| Nice to Have | 3 | 2.5天 |
| **总计** | **9** | **10天** |

**注**: 预留 1 天缓冲处理突发问题。

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| S5-T6 畜牧疾病UI暴露 | Sprint 5 代码已存在，UI 延期 | 1天（暴露UI） |
| S5-T7 深度喂食逻辑 | 需商店系统支持多饲料购买（S6 完成） | 1天 |
| S6-T11 game_manager TODO清理 | UI需单独设计存档菜单 | 1天 |
| S6-T12 Bug严重性分级文档 | 优先级低于功能开发 | 0.5天 |

## 风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| C08 WeaponEquipment 未实现阻塞采矿/狩猎 | 中 | 高 | 狩猎系统MVP先做技能计时部分，武器战斗后期接入 |
| NPC好感度系统复杂度超预期 | 中 | 中 | 架构设计阶段先产出 Autoload 框架，完整对话/MVP延后 |
| 狩猎系统地图/交互需要大量UI设计 | 中 | 中 | 使用 EMMY 风格简化UI，后期迭代 |

## Dependencies on External Factors

- **WeaponEquipmentSystem (C08)**: "In Design" 状态，先用 stub 接口，待完整实现后狩猎系统接入战斗
- **NpcFriendshipSystem (C07)**: GDD 存在，商店折扣功能依赖此系统
- **HuntingSystem GDD**: `design/gdd/feature/hunting-system.md` (✅ Approved) — 狩猎系统在设计阶段遗漏，未在 milestones.md 中列出，需补充

## 设计文档参考

### 狩猎系统 MVP 范围（补充）

**简化版功能**:
- 狩猎区域划分：灌木丛/森林/湖泊（3个区域）
- 狩猎技能（复用 C03 SkillSystem）
- 猎物刷新计时（使用 TimeManager）
- 狩猎完成产出计算

**MVP排除的功能**:
- ❌ 狩猎武器装备（依赖 C08）
- ❌ 狩猎小游戏（迷你游戏延期）
- ❌ 特殊猎物遭遇
- ❌ 狩猎成就

### NPC好感度系统 MVP 范围

**简化版功能**:
- NPC数据基础结构（ID、名称、位置、初始好感度）
- 好感度查询 API（get_friendship, get_friendship_level）
- 好感度变化 API（对话+20，每日衰减）
- 与商店系统对接（好感度折扣）

**MVP排除的功能**:
- ❌ 心事件系统
- ❌ 恋爱/结婚系统
- ❌ 雇工系统
- ❌ 孕期/子女系统

## Definition of Done for this Sprint

- [ ] 畜牧疾病 UI 正常暴露（患病动物有症状提示）
- [ ] 深度喂食逻辑完善（饲料消耗 + 动物饱食度/好感度联动）
- [ ] game_manager TODO 减少3个以上
- [ ] NpcFriendshipSystem Autoload 框架完成，基础 API 可用
- [ ] HuntingSystem Autoload 完成，技能计时/猎物刷新逻辑可测试
- [ ] Bug 严重性分级文档建立
- [ ] ShopSystem / CookingSystem 单元测试补充完成
- [ ] 地图 UI 完善（区域标记/传送点）

## 下一步 (Sprint 8 预览)

| 任务 | 描述 | 依赖 |
|------|------|------|
| P08 任务系统 | 任务接取/追踪/完成系统 | S7-T4(NPC) |
| P15 对话/事件系统 | NPC对话框架 + 事件触发 | S7-T4(NPC) |
| HuntingSystem UI | 狩猎交互界面 | S7-T6 |
| MiningSystem 基础设施 | 矿洞场景/矿石数据 | C08 待实现 |

---

*最后更新: 2026-04-21*