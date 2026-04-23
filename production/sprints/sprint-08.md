# Sprint 8 -- 2026-04-22 to 2026-05-05

## Sprint Goal

**完成 M3 里程碑 UI 闭环：全局飘窗通知系统补全上线 + NPC 好感度/狩猎系统 UI + 任务系统开局。**

---

## Background

### 飘窗系统现状与决策

项目已有 `NotificationManager.gd` Autoload（队列管理 + 优先级），已有 `HUD.show_message()`（单条显示），但与 GDD 要求存在差距：

| GDD 要求 | 现有实现 | 状态 |
|---------|---------|------|
| 6种类型 (gain/cost/success/warning/error/system) | ✅ ERROR/COST/GAIN/SUCCESS/WARNING/SYSTEM | ✅ 已完成 |
| 同时显示最多3条 | ✅ NotificationArea + 堆叠逻辑 | ✅ 已完成 |
| 去重合并（2秒窗口，合并显示 `x3`） | ✅ _dedup_map + 合并逻辑 | ✅ 已完成 |
| 优先级打断（priority>=3 打断低优先级） | ✅ _try_interrupt_low_priority | ✅ 已完成 |
| 暂停/恢复（pause_requested/resume_requested） | ✅ _is_paused/_is_draining | ✅ 已完成 |
| 堆叠动画（淡入0.2s/飘动50px/s/淡出0.3s） | ✅ _spawn_toast + _process 计时 | ✅ 已完成 |
| EventBus `notification_requested` 信号 | ✅ event_bus.gd 已定义 | ✅ 已完成 |
| 迁移散落调用 | ✅ AnimalHusbandryUI 使用 NotificationManager | ✅ 已完成 |

**决策：不新建 ToastManager，扩展 NotificationManager + 改造 HUD 显示层。**
理由：迁移成本低，已有完整队列基础，只需扩展功能而非重建。

### Sprint 7 回顾

- **完成率**: ~100%（Must + P1 全部完成，Nice-to-Have 主动延期）
- **关键交付**: `NpcFriendshipSystem.gd`、`HuntingSystem.gd`、`save-menu-ui.md`
- **关键 Bug**: `animal_husbandry_ui.gd` HUD 引用错误
- **需改进**: 狩猎技能存在性未验证（`hunting_system.gd` 调用未注册的技能名）

### M3 里程碑进度

| 系统 | GDD | Sprint | 状态 |
|------|-----|--------|------|
| P06 商店系统 | ✅ | Sprint 6 | ✅ Autoload + UI |
| P04 烹饪系统 | ✅ | Sprint 6 | ✅ Autoload + UI |
| P05 加工系统 | ✅ | Sprint 6 | ✅ Autoload |
| P03 采矿系统 | ✅ | Sprint 7 | ✅ Autoload |
| **P08 任务系统** | ✅ | Sprint 8 | 🔲 开工 |
| **P15 对话/事件系统** | ✅ | Sprint 8 | 🔲 开工 |
| **NPC好感度 (C07) UI** | ✅ | Sprint 8 | 🔲 UI 上线 |
| **狩猎系统 (P10) UI + 技能** | ✅ GDD Approved | Sprint 8 | 🔲 UI + 技能补全 |

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
| Must Have | 5 | 5天 |
| Should Have | 4 | 4.5天 |
| Nice to Have | 3 | 2天 |
| **总计** | **12** | **11.5天** |

---

## Tasks

### Must Have (P0) — 飘窗系统补全

> **策略**: 扩展 NotificationManager（队列层）+ 改造 HUD（显示层），不新建 Autoload。

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| **S8-T1** | **NotificationManager 功能补全** | Dev | 1天 | NotificationManager ✅ | 添加 `NotificationColor.ERROR` 深红色，`COST` 别名；MAX_QUEUE_SIZE 改为 20；实现 `_dedup_map: Dictionary`（id→时间戳） + 2秒去重合并逻辑；`show_error()` 方法 |
| **S8-T2** | **HUD 多飘窗显示改造** | Dev | 1.5天 | S8-T1 | 移除 HUD 单条 `notification_label`；实现最多同时显示 3 条飘窗的堆叠布局（上层新建，下层堆叠）；实现淡入0.2s/向上飘动50px/s/淡出0.3s 动画；符合 GDD 颜色定义 |
| **S8-T3** | **优先级打断 + 暂停恢复** | Dev | 0.5天 | S8-T2 | priority>=3 打断正在显示的低优先级（移除最低优先级，立即淡出）；监听 `EventBus.pause_requested` → 暂停队列；监听 `EventBus.resume_requested` → draining 模式快速清空 |
| **S8-T4** | **信号对齐 GDD** | Dev | 0.5天 | S8-T1 | `EventBus` 添加 `notification_requested` 信号（按 GDD 定义：text/type/priority/duration/id/icon_path）；保留 `ui_notification` 向后兼容；NotificationManager 同时监听两个信号 |
| **S8-T5** | **迁移散落调用 + 验收测试** | Dev | 0.5天 | S8-T2 | `animal_husbandry_ui._show_toast()` → `NotificationManager.show_warning()`；移除 `AnimalHusbandryUI` 中局部 `_toast_label` + Tween；运行 `debug_show_all_types()` 验证 6 种颜色 |
| **S8-T5b** | **NotificationManager 单元测试** | Dev | 0.5天 | S8-T1 | show_gain/cost/success/warning/error/system 路径覆盖；去重合并测试（相同 id 2秒内合并）；队列满丢弃测试（MAX=20） |

### Should Have (P1) — NPC好感度 UI + 狩猎系统 UI

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| S8-T6 | NpcFriendshipSystem UI 面板 | Dev | 2天 | S7-T4 ✅ | NPC列表显示，好感度心形图标，每日好感度刷新提示，NPC对话触发 |
| S8-T7 | 狩猎技能定义补全 | Dev | 0.5天 | S7-T6 ✅ | `SkillSystem.gd` 中注册 "hunting" 技能，L1-L10 定义，狩猎系统调用有效 |
| S8-T8 | HuntingSystem UI 面板 | Dev | 1.5天 | S7-T6 ✅, S8-T7 | 狩猎区域选择（3区域），当前猎物显示，狩猎结果展示 |
| S8-T9 | QuestSystem 核心逻辑 | Dev | 2天 | NpcFriendshipSystem ✅ | `QuestSystem.gd` Autoload，主线/支线任务结构，任务接受/追踪/完成 API |

### Nice to Have (P2)

| ID | 任务 | 负责人 | 预估 | 依赖 | 验收标准 |
|----|------|--------|------|------|----------|
| S8-T10 | QuestSystem UI 面板 | Dev | 1.5天 | S8-T9 | 任务面板 UI，任务列表，已接任务详情，当前目标高亮 |
| S8-T11 | 地图UI完善 | Dev | 1天 | NavigationSystem ✅ | `HUD._open_map()` 全屏地图浮层，5个区域列表，体力/旅行消耗显示 | ✅ |
| S8-T12 | DialogueSystem 核心逻辑 | Dev | 0.5天 | NpcFriendshipSystem ✅ | `dialogue_system.gd` Autoload，状态机/对话获取/变量替换/选择效果，示例 NPC 对话数据 | ✅ |

---

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| 飘窗通知系统补全 | 现有 NotificationManager 不满足 GDD（缺去重/多飘窗/暂停恢复） | 4天（S8-T1~T4） |
| NpcFriendshipSystem UI | S7-T4 Autoload 已完成，需 UI | 2天 |
| HuntingSystem UI + 技能补全 | S7-T6 Autoload 已完成，需 UI + 技能定义 | 2天 |
| QuestSystem 核心逻辑 | Sprint 8 目标之一 | 2天 |

---

## Risks

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 飘窗 HUD 改造破坏现有 HUD 布局 | 中 | 高 | T2 优先处理，先复制现有 notification_label 行为，再扩展多飘窗 |
| 去重合并逻辑与队列优先级冲突 | 中 | 中 | 去重在入队时处理（同一 id 刷新计时器而非新建），高优先级打断在显示层处理 |
| 暂停/恢复引入状态机复杂度 | 中 | 中 | 状态机只有 idle/running/paused/draining 4个状态，迁移路径清晰 |
| NPC/狩猎 UI 并行开发赶不上 Sprint | 低 | 中 | P1 任务拆分为独立任务，可灵活调整优先级 |

---

## Dependencies on External Factors

- **NotificationManager (Autoload)**: 已存在，需扩展；依赖 EventBus 信号
- **HUD**: 已存在 notification_label，需改造为多飘窗显示
- **NpcFriendshipSystem (S7-T4)**: Autoload 已完成，UI 依赖此系统
- **HuntingSystem (S7-T6)**: Autoload 已完成，UI + 技能补全依赖此系统
- **SkillSystem (C03)**: 需添加 "hunting" 技能定义

---

## Implementation Order for Toast System

```
Week 1 (Day 1-5)
├── Day 1: NotificationManager 扩展（T1）
│   ├── 添加 ERROR 类型颜色 + COST 别名
│   ├── MAX_QUEUE_SIZE: 10 → 20
│   ├── 实现 _dedup_map（id→时间戳）+ 去重合并逻辑
│   └── 添加 show_error() / show_cost() 别名
│
├── Day 2-3: HUD 多飘窗显示改造（T2 + T3）
│   ├── 移除 HUD 单条 notification_label（备选：保留兼容）
│   ├── 实现 NotificationArea（CanvasLayer，z_index=100）
│   ├── NotificationQueue 状态机（idle/running/paused/draining）
│   ├── 最多同时显示3条飘窗
│   ├── 淡入 0.2s + 向上飘动 50px/s + 淡出 0.3s
│   ├── 优先级打断：priority>=3 打断低优先级
│   └── pause_requested/resume_requested 监听
│
├── Day 4: 信号对齐 GDD（T4）
│   ├── EventBus.notification_requested 信号定义
│   ├── 保留 ui_notification 向后兼容
│   └── NotificationManager 双信号监听
│
├── Day 5: 迁移 + 验收（T5 + T5b）
│   ├── AnimalHusbandryUI._show_toast() → NotificationManager
│   ├── 移除局部 _toast_label/Tween
│   ├── debug_show_all_types() 验证 6 种颜色
│   └── 单元测试：去重合并/队列满/优先级打断
│
└── Day 5 下午: Acceptance Criteria 验收
    ├── 6种类型颜色正确
    ├── 同时不超过 3 条
    ├── 2秒去重合并显示 x3
    ├── priority>=3 打断低优先级
    └── 打开/关闭 UI 时暂停恢复正确

Week 2 (Day 6-11): NPC UI + 狩猎 UI + Quest System
```

## Implementation Status

### 飘窗系统 (S8-T1 ~ S8-T5b) — ✅ 已完成

| 子任务 | 文件改动 | 状态 |
|--------|---------|------|
| S8-T1 NotificationManager 补全 | `notification_manager.gd`: ERROR颜色/COST别名/MAX=20/去重合并 | ✅ |
| S8-T2 HUD 多飘窗显示改造 | `hud.gd` + `HUD.tscn`: NotificationArea/3条堆叠/动画 | ✅ |
| S8-T3 优先级打断 + 暂停恢复 | `hud.gd` + `notification_manager.gd`: priority>=3打断/pause_requested | ✅ |
| S8-T4 信号对齐 GDD | `event_bus.gd`: notification_requested + pause_requested/resume_requested | ✅ |
| S8-T5 迁移散落调用 | `animal_husbandry_ui.gd`: 移除_toast_label/→NotificationManager | ✅ |
| S8-T5b 单元测试 | `notification_manager_test.gd`: 6种类型/去重/队列满/优先级测试 | ✅ |

### NPC好感度 UI (S8-T6) — ✅ 已完成

| 子任务 | 文件改动 | 状态 |
|--------|---------|------|
| NpcFriendshipSystem UI 面板 | `npc_friendship_panel.tscn` + `npc_friendship_ui.gd`: NPC列表/心形好感度/每日刷新 | ✅ |

### 狩猎系统完善 (S8-T7 ~ S8-T8) — ✅ 已完成

| 子任务 | 文件改动 | 状态 |
|--------|---------|------|
| S8-T7 狩猎技能定义 | `skill_system.gd`: SkillType.HUNTING 注册，L1-L10 | ✅ |
| S8-T8 狩猎 UI 面板 | `hunting_panel.tscn` + `hunting_ui.gd`: 3区域/状态标签/结果展示 | ✅ |

### 任务系统 (S8-T9 ~ S8-T10)

| 子任务 | 文件改动 | 状态 |
|--------|---------|------|
| S8-T9 QuestSystem 核心逻辑 | `quest_system.gd`: 任务数据/接受/追踪/完成/奖励/存档 | ✅ |
| S8-T10 QuestSystem UI 面板 | `quest_panel.tscn` + `quest_ui.gd`: 任务列表/进度显示/接受/完成操作 | ✅ |
| S8-T11 地图UI完善 | `HUD._open_map()`: 全屏地图浮层/区域列表/体力消耗/ESC关闭 | ✅ |
| S8-T12 DialogueSystem 核心 | `dialogue_system.gd`: 状态机/对话获取/变量替换/EventBus信号/存档 | ✅ |

### Integration Fixes（验证阶段发现并修复）

| 问题 | 修复 | 文件 |
|------|------|------|
| `EventBus` 缺少 `npc_talked`/`cooking_completed`/`mine_floor_reached` 信号 | 添加到 `event_bus.gd` + 各系统转发 | ✅ |
| `QuestSystem` 使用字符串连接 `EventBus.connect("npc_talked",...)` | 改为类型安全 `EventBus.npc_talked.connect(...)` | ✅ |
| `QuestSystem._award_rewards` 调用 `talk_to()` 受每日限制 | 新增 `NpcFriendshipSystem.add_friendship()` 公共方法 | ✅ |
| `FarmPlot` 收割未 emit EventBus | `harvest()` 中添加 `EventBus.farm_crop_harvested.emit` | ✅ |
| `CookingSystem` 烹饪完成未转发 EventBus | 添加 `_on_cooking_finished` 转发 `EventBus.cooking_completed` | ✅ |

---

## Definition of Done for this Sprint

- [x] NotificationManager 满足 GDD：6种类型、MAX=20、去重合并、error 类型
- [x] HUD 同时显示最多 3 条飘窗，颜色符合 GDD
- [x] 淡入0.2s / 向上飘动50px/s / 淡出0.3s 动画正确
- [x] priority>=3 打断低优先级正在显示的消息
- [x] pause_requested/resume_requested 暂停恢复正确
- [x] EventBus.notification_requested 信号存在且功能正确
- [x] AnimalHusbandryUI 局部飘窗逻辑已移除，使用 NotificationManager
- [x] 飘窗系统单元测试覆盖核心路径
- [x] NPC 好感度面板可查看所有 NPC 好感度
- [x] 狩猎技能在 SkillSystem 中注册，L1-L10 可用
- [x] 狩猎区域选择 + 结果展示 UI 可用
- [x] QuestSystem Autoload + 基础 API 可测试
- [x] QuestSystem UI 面板可查看任务列表
- [x] Nice-to-Have 任务中至少完成 2 项（已完成 4 项：QuestSystem Autoload + UI + 地图UI + DialogueSystem）

---

## 下一步 (Sprint 9 预览)

| 任务 | 描述 | 依赖 |
|------|------|------|
| P07 隐藏NPC系统 | NPC完整交互 + 事件触发 | P15 对话系统 ✅ |
| P09 成就系统 | 成就条件/解锁/展示 | QuestSystem ✅ |
| P10 狩猎系统完善 | 狩猎小游戏/特殊猎物 | HuntingSystem UI ✅ |

---

*最后更新: 2026-04-23 (第二次会话)*
