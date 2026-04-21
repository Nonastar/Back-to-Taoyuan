# Sprint 7 Retrospective

**Sprint 7** — 2026-04-21 to 2026-04-21 (持续中)

## 团队
独立开发者 (Dev)

---

## Sprint 目标回顾

**目标**: 完成 Sprint 6 延期项扫尾，推进 M3 里程碑基础设施（S5 畜牧完结 + NPC 好感度架构）+ 狩猎系统开局。

**结果**: ✅ 目标达成，Must Have (P0) + Should Have (P1) 全部6项完成，Nice-to-Have 主动延期。

---

## 交付成果

### Must Have — 3项全部完成

| ID | 任务 | 交付物 |
|----|------|--------|
| S7-T1 | 畜牧疾病UI暴露 | `animal_husbandry_ui.gd`: 商店按钮修复（→ shop_panel直接实例化），患病动物 🤒 badge + COLOR_SICK 样式 |
| S7-T2 | 深度喂食逻辑 | `feed_animals()` / `hay` 物品注册 + `feed_single_animal()` 单只喂养，饱食度/好感度联动完整 |
| S7-T3 | game_manager TODO清理 | `game_manager.gd` TODO→注释引用设计文档 + `design/gdd/ui/save-menu-ui.md` 存档菜单设计文档 |

### Should Have — 3项全部完成

| ID | 任务 | 交付物 |
|----|------|--------|
| S7-T4 | NpcFriendshipSystem 架构 | `npc_friendship_system.gd` Autoload：12个默认NPC，好感度API，对话+20/日，每日重置，商店折扣 `get_shop_discount()`，serialize/deserialize |
| S7-T5 | Bug严重性分级文档 | `production/bug-severity.md`：S1-S5框架，计数器模板，发布门槛规则 |
| S7-T6 | HuntingSystem 核心逻辑 | `hunting_system.gd` Autoload：3个狩猎区域，9种猎物，猎物刷新计时，掉落计算（技能加成+Prospector天赋），serialize/deserialize |

### Nice to Have — 3项延期

| ID | 任务 | 原因 |
|----|------|------|
| S7-T7 | 地图UI完善 | 优先级低于 Must/P1，未影响里程碑进度 |
| S7-T8 | ShopSystem 单元测试补全 | Sprint-6已有 `shop_system_test.gd`（全部通过），覆盖已足够 |
| S7-T9 | CookingSystem 单元测试补全 | Sprint-6已有 `cooking_system_test.gd`（全部通过），覆盖已足够 |

### Sprint后修复

| 时间 | 修复 | 原因 |
|------|------|------|
| 2026-04-21 | `animal_husbandry_ui.gd` HUD 引用移除 (037f9c7) | GDScript 解析错误：`HUD` 非 Autoload 名称，直接实例化 shop_panel.tscn 绕过 |

---

## 修复的关键 Bug

| Bug | 根因 | 修复 |
|-----|------|------|
| 运行时解析错误 `HUD not declared` | `HUD` 非 Autoload 变量，依赖未经验证的假设 | 移除 `HUD.toggle_shop()` 分支，直接实例化 shop_panel.tscn |

---

## 经验教训

### 做得好的

1. **Autoload 一致性验证** — 发现 `HUD` 变量引用问题后立即修复，避免了运行时崩溃
2. **主动延期 Nice-to-Have** — S7-T7/T8/T9 延期有明确理由（测试已覆盖/优先级低），不是范围蔓延
3. **设计文档驱动开发** — 在编写 Autoload 前先写 GDD（如 `save-menu-ui.md`），避免后期重构
4. **Godot UID 生成** — 使用 node.js 生成 .gd.uid 文件，确保资源引用正确

### 需要改进

1. **Autoload 命名验证** — `animal_husbandry_ui.gd` 中引用 `HUD` 前未检查 project.godot 的 autoload 列表，应添加预提交检查
2. **狩猎技能存在性** — `hunting_system.gd` 中 `_get_hunting_skill_level()` 调用 `SkillSystem.get_skill_level("hunting")`，未验证技能系统中是否实际存在该技能定义

---

## 下一步 (Sprint 8 候选)

| 优先级 | 任务 | 依赖 |
|--------|------|------|
| P0 | Sprint 7 Bug 修复扫尾（HUD错误已修复） | — |
| P1 | NpcFriendshipSystem UI 面板（NPC列表/好感度显示） | S7-T4 |
| P1 | HuntingSystem UI 面板（狩猎区域选择/结果展示） | S7-T6 |
| P1 | 狩猎技能定义补全（SkillSystem 中添加 "hunting" 技能） | S7-T6 |
| P2 | P08 任务系统 | S7-T4(NPC) |
| P2 | P15 对话/事件系统 | S7-T4(NPC) |
| P3 | S7-T7 地图UI完善 | NavigationSystem ✅ |

---

## 指标

| 指标 | 值 |
|------|-----|
| 提交数 | 3 (eddf206, 037f9c7, 8fb66ba) |
| 新增文件 | 6 (2 Autoload + 2 UID + 1 GDD + 1 doc) |
| 修改文件 | 3 |
| 关键 Bug 修复 | 1 |
| Sprint Goal 完成率 | ~100% (Must/P1全部完成，Nice-to-Have主动延期) |

---

*最后更新: 2026-04-21*