# Sprint 9 -- 2026-05-06 to 2026-05-19

## Sprint Goal

**推进 M3 里程碑收尾：完成隐藏 NPC 系统 + 成就系统核心 + 博物馆系统开局。**

---

## Background

### Sprint 8 回顾

| 任务 | 状态 |
|------|------|
| 飘窗系统 (S8-T1~T5b) | ✅ 完成 |
| NPC好感度 UI (S8-T6) | ✅ 完成 |
| 狩猎技能定义 (S8-T7) | ✅ 完成 |
| 狩猎 UI (S8-T8) | ✅ 完成 |
| QuestSystem 核心逻辑 (S8-T9) | ✅ 完成 |
| QuestSystem UI (S8-T10) | ✅ 完成 |
| 地图UI完善 (S8-T11) | ✅ 完成 |
| DialogueSystem 核心 (S8-T12) | ✅ 完成 |

**Sprint 8 交付率**: 100%（所有 Must / Should / Nice-to-Have 全部完成）

### M3 里程碑进度

| 系统 | GDD | Sprint | 状态 |
|------|-----|--------|------|
| P06 商店系统 | ✅ | Sprint 6 | ✅ Autoload + UI |
| P04 烹饪系统 | ✅ | Sprint 6 | ✅ Autoload + UI |
| P05 加工系统 | ✅ | Sprint 6 | ✅ Autoload |
| P03 采矿系统 | ✅ | Sprint 7 | ✅ Autoload |
| P08 任务系统 | ✅ | Sprint 8 | ✅ Autoload + UI |
| P15 对话/事件系统 | ✅ | Sprint 8 | ✅ Autoload |
| **P07 隐藏NPC系统** | ✅ | Sprint 9 | 🔲 开工 |
| **P09 成就系统** | ✅ | Sprint 9 | 🔲 开工 |
| **P11 博物馆系统** | ✅ | Sprint 9 | 🔲 开工（轻量开局）|

---

## Capacity

| 项目 | 值 |
|------|-----|
| 总天数 | 14天 |
| 缓冲 (20%) | 3天 |
| 可用天数 | 11天 |
| 团队 | 1人 (独立开发者) |

---

## 工作量估算

| 类别 | 任务数 | 总天数 |
|------|--------|--------|
| Must Have | 3 | 5天 |
| Should Have | 3 | 4天 |
| Nice to Have | 2 | 2天 |
| **总计** | **8** | **11天** |

---

## Tasks

### Must Have (P0) — 隐藏NPC系统 + 成就系统核心

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| **S9-T1** | HiddenNPCSystem 核心逻辑 | Dev | 2天 | DialogueSystem ✅, NpcFriendshipSystem ✅ | `hidden_npc_system.gd` Autoload，4个隐藏NPC（归女、小龙女、老神仙、神秘商人），发现条件检查，解锁/触发 API，`_friend_npcs` 字典存储已发现NPC |
| **S9-T2** | HiddenNPCSystem UI 面板 | Dev | 1.5天 | S9-T1 | `hidden_npc_panel.tscn` + `hidden_npc_ui.gd`：已发现NPC列表，位置显示，未发现显示为"？" |
| **S9-T3** | AchievementSystem 核心逻辑 | Dev | 2天 | QuestSystem ✅, HiddenNPCSystem ✅ | `achievement_system.gd` Autoload，成就分类（采集/生产/社交/探索/特殊），解锁条件评估，成就奖励，`_unlocked_achievements` 存档 |

### Should Have (P1) — 成就系统UI + 博物馆开局

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| **S9-T4** | AchievementSystem UI 面板 | Dev | 1.5天 | S9-T3 | `achievement_panel.tscn` + `achievement_ui.gd`：成就列表，图标+名称+描述，已解锁/未解锁状态，总进度显示 |
| **S9-T5** | MuseumSystem 核心逻辑 | Dev | 2天 | ItemDataSystem ✅ | `museum_system.gd` Autoload，博物馆分类（鱼类/矿石/古物/艺术品），贡献系统，`_donated_items` 存档，`get_completeness()` 完成度 |
| **S9-T6** | MuseumSystem UI 面板 | Dev | 1天 | S9-T5 | `museum_panel.tscn` + `museum_ui.gd`：分类展示，贡献状态，完成度进度条 |

### Nice to Have (P2)

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| **S9-T7** | 隐藏NPC 交互动画/特效 | Dev | 1天 | S9-T2 | NPC出现时的光效/粒子特效，对话触发动画 |
| **S9-T8** | 博物馆贡献展示特效 | Dev | 1天 | S9-T6 | 贡献新物品时的视觉反馈，完成里程碑时的奖励展示 |

---

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| 无 | Sprint 8 全部完成 | — |

---

## Risks

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 隐藏NPC发现条件与现有系统耦合过多 | 中 | 中 | 发现逻辑独立评估，不修改被依赖系统 |
| 成就系统解锁条件评估影响性能 | 中 | 中 | 使用事件驱动评估，避免每帧轮询 |
| 博物馆物品分类数据量庞大 | 低 | 低 | 按类别 lazy-load，暂只实现框架 |

---

## Dependencies on External Factors

- **DialogueSystem (S8-T12)**: 隐藏NPC 对话内容依赖 P15
- **NpcFriendshipSystem (S7-T4)**: 隐藏NPC 发现条件依赖好感度
- **QuestSystem (S8-T9)**: 成就条件依赖任务完成
- **ItemDataSystem (F03)**: 博物馆物品定义依赖 F03

---

## Implementation Order

```
Week 1 (Day 1-5)
├── Day 1-2: HiddenNPCSystem 核心逻辑（T1）
│   ├── 4个隐藏NPC定义（归女/小龙女/老神仙/神秘商人）
│   ├── 发现条件评估（好感度/任务/物品/随机）
│   └── emit heart_event_triggered → DialogueSystem
│
├── Day 3: HiddenNPCSystem UI 面板（T2）
│   ├── 已发现/未发现列表展示
│   └── 发现位置标注
│
├── Day 4-5: AchievementSystem 核心逻辑（T3）
│   ├── 成就分类 + 100个成就定义
│   ├── 解锁条件评估（事件驱动）
│   └── 奖励发放 API
│
└── Day 5 下午: 验收 T1-T3

Week 2 (Day 6-11)
├── Day 6-7: AchievementSystem UI 面板（T4）
│   ├── 成就列表 + 完成度
│   └── 解锁动画
│
├── Day 8-9: MuseumSystem 核心逻辑（T5）
│   ├── 博物馆分类
│   ├── 贡献系统
│   └── 完成度计算
│
├── Day 10: MuseumSystem UI 面板（T6）
│   ├── 分类展示 + 完成度
│   └── 贡献表单
│
└── Day 11: Nice-to-have (T7-T8) + 总验收
```

---

## Definition of Done for this Sprint

- [ ] HiddenNPCSystem Autoload + 4个NPC定义 + 发现条件
- [ ] HiddenNPCSystem UI 面板可查看已发现/未发现状态
- [ ] AchievementSystem Autoload + 核心成就定义（≥50个）
- [ ] 成就解锁事件驱动评估，不影响帧率
- [ ] AchievementSystem UI 面板可查看成就列表
- [ ] MuseumSystem Autoload + 分类框架 + 贡献 API
- [ ] MuseumSystem UI 面板可查看完成度
- [ ] Nice-to-Have 至少完成 1 项

---

## 下一步 (Sprint 10 预览)

| 任务 | 描述 | 依赖 |
|------|------|------|
| P06 商店系统完善 | 商店UI细化+进货系统 | 已有 ✅ |
| P12 商会系统 | 公会商店/商会任务 | P09 成就 ✅ |
| P14 沙漠/赌场系统 | 汉海赌场NPC + 小游戏 | P07 隐藏NPC ✅ |
| P13 繁殖系统完善 | 动物繁殖UI+后代管理 | P01 畜牧 ✅ |

---

*最后更新: 2026-04-25*
