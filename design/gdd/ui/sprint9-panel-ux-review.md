# Sprint 9 UI 面板 UX 评审报告

> **状态**: Final
> **Author**: UX Reviewer
> **Date**: 2026-04-25
> **Sprint**: S9
> **Panels Reviewed**: HiddenNPCPanel, AchievementPanel, MuseumPanel

---

## 1. 概述

本次评审对照 UX 规范 `design/gdd/ui/sprint9-panel-ux-spec.md` 对三个面板进行了全面检查。三个面板在核心交互流程、动画时长、颜色规范方面表现良好，但存在**键盘导航不完整**和**滚动容器缺失**两类关键问题需要修复。

---

## 2. 通过项

### 2.1 MuseumPanel

| 项 | 实现 | 位置 |
|----|------|------|
| 面板打开/关闭动画 | 200ms / 150ms，符合规范 | L184-197 |
| ESC 关闭支持 | `_input()` 监听 `ui_cancel` | L741-743 |
| Tab 切换逻辑 | `_switch_tab()` 正确切换 3 个 Tab | L222-246 |
| 面板尺寸 | 900x700px，水平+垂直居中 | museum_panel.tscn L11-14 |
| 颜色 Token | PANEL_BG / PANEL_BORDER 正确应用 | L90-96 |
| 按钮高度 | 28-32px，符合规范 | L554, 663 |
| 字体大小 | 12-20px，符合 14px 最小值 | 各组件 |
| 系统未就绪占位 | "博物馆系统开发中..." | L248-258 |
| 空状态提示 | "背包中无可捐赠物品" | L477-485 |
| 错误反馈 | NotificationManager 飘窗提示 | L710-735 |

### 2.2 AchievementPanel

| 项 | 实现 | 位置 |
|----|------|------|
| 面板打开/关闭动画 | 200ms / 150ms，符合规范 | L198-211 |
| ESC 关闭支持 | `_input()` 监听 `ui_cancel` | L535-537 |
| Tab 动态构建 | 18 个分类按钮，动态生成 | L118-138 |
| 成就详情弹窗 | 完整 overlay + 详情内容 | L368-504 |
| 详情弹窗动画 | 200ms 缩放弹出 | L502-504 |
| 详情 ESC/点击关闭 | 双重关闭方式 | L524-533 |
| 成就卡片键盘支持 | Enter/Space 确认 | L520-522 |
| 滚动容器 | ScrollContainer 包装内容区 | achievement_panel.tscn L83-93 |
| Tab 横向滚动 | ScrollContainer 包装 Tab 栏 | achievement_panel.tscn L71-81 |
| 字体大小 | 12-20px，符合 14px 最小值 | 各组件 |
| 系统未就绪占位 | "成就系统开发中..." | L242-251 |
| 空状态提示 | "该分类暂无成就" | L267-274 |

### 2.3 HiddenNPCPanel

| 项 | 实现 | 位置 |
|----|------|------|
| 面板打开/关闭动画 | 200ms / 150ms，符合规范 | L156-169 |
| ESC 分级关闭 | 详情视图返回列表，列表关闭面板 | L1025-1032 |
| Tab 筛选 | 全部/已发现/未发现 三态过滤 | L215-222, L938-957 |
| 面板尺寸 | 900x700px，水平+垂直居中 | hidden_npc_panel.tscn L11-14 |
| 颜色 Token | PANEL_BG / PANEL_BORDER 正确应用 | L86-92 |
| 多视图导航 | 列表 > 详情 > 供奉 三层流转 | L177-214, L386-582, L708-776 |
| 返回按钮 | 详情/供奉视图有返回按钮 | L411-420, L717-725 |
| 每日剩余计数 | 供奉/互动次数显示 | L543-549 |
| 供奉选择显示品质 | 灵犀/合意/一般三级 | L818-825 |
| 字体大小 | 11-18px，符合 14px 最小值 | 各组件 |
| 空状态提示 | "该分类暂无仙灵" | L207-213 |
| 错误反馈 | NotificationManager 飘窗提示 | L981-1004 |

---

## 3. 问题项

### 3.1 P0 - 必须修复

#### 问题 1: HiddenNPCPanel 内容区缺少滚动容器

**描述**: `hidden_npc_panel.tscn` 中 `ContentContainer` 直接使用 `VBoxContainer`，没有 ScrollContainer 包装。当仙灵数量较多或详情视图内容超出 600px 高度时，内容无法滚动浏览。

**规范要求**: 内容区必须可滚动 (第 25 行线框图标注 Content 区域)

**位置**: hidden_npc_panel.tscn L57-61

**当前代码**:
```
VBox/ContentContainer (VBoxContainer, 直接使用)
```

**建议修复**:
```
VBox/ContentScroll (ScrollContainer)
└── ContentContainer (VBoxContainer, 放入 ScrollContainer)
```

---

#### 问题 2: 三个面板均缺少 Tab/方向键导航逻辑

**描述**: 所有 `_input()` 方法只监听 `ui_cancel` (ESC)，没有处理 Tab/方向键的焦点切换或列表导航。

**规范要求**:
- Tab 导航顺序: 面板打开 → 第一个可交互元素 → Tab 循环
- 方向键在网格/列表中移动焦点

**位置**:
- museum_panel.gd: L741-743 (仅 ESC)
- achievement_panel.gd: L535-537 (仅 ESC)
- hidden_npc_panel.gd: L1025-1032 (仅 ESC)

**当前代码** (所有面板通用模式):
```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel") and _visible:
        close_panel()
```

**建议修复**: 添加方向键网格导航逻辑，例如:
```gdscript
func _input(event: InputEvent) -> void:
    if not _visible:
        return
    if event.is_action_pressed("ui_cancel"):
        # ... 现有逻辑
    elif event.is_action_pressed("ui_left"):
        _navigate_grid(-1, 0)
    elif event.is_action_pressed("ui_right"):
        _navigate_grid(1, 0)
    elif event.is_action_pressed("ui_up"):
        _navigate_grid(0, -1)
    elif event.is_action_pressed("ui_down"):
        _navigate_grid(0, 1)
```

---

### 3.2 P1 - 建议修复

#### 问题 3: 三个面板 Tab 切换动画均未实现

**描述**: 三个面板的 `_switch_tab()` / `_on_category_tab_pressed()` 方法都是直接重建内容，没有任何动画过渡。

**规范要求**:
- MuseumPanel: Tab 切换动画 150ms，内容横向滑动
- AchievementPanel: Tab 切换动画 150ms，内容横向滑动
- HiddenNPCPanel: 切换视图动画 200ms，横向滑动过渡

**位置**:
- museum_panel.gd: L222-246
- achievement_panel.gd: L511-514
- hidden_npc_panel.gd: L938-943, L945-950, L952-957

**当前代码** (以 MuseumPanel 为例):
```gdscript
func _switch_tab(tab_index: int) -> void:
    _current_tab = tab_index
    _update_tab_button_style(...)  # 仅更新样式
    # 直接清空并重建内容，无动画
    for child in _content_container.get_children():
        child.queue_free()
    # ... 立即构建新内容
```

**建议**: 使用 Tween 实现横向滑动效果，或至少使用 `modulate:a` 淡入淡出。

---

#### 问题 4: 三个面板均缺少键盘焦点指示器样式

**描述**: 所有按钮和卡片没有 Focus 状态的视觉样式。用户使用 Tab 导航时无法确认当前焦点在哪里。

**规范要求**: 键盘焦点应有 2px 金色边框 + 微弱发光

**位置**: 所有 `_apply_styles()` 和 `_update_tab_button_style()` 方法

**建议**: 添加 Focus StyleBox，例如:
```gdscript
var focus_style = StyleBoxFlat.new()
focus_style.bg_color = Color(0.12, 0.12, 0.16, 0.95)
focus_style.border_color = Color(1.0, 0.84, 0.0, 1.0)
focus_style.border_width_left = 2
focus_style.border_width_right = 2
focus_style.border_width_top = 2
focus_style.border_width_bottom = 2
btn.add_theme_stylebox_override("focus", focus_style)
```

---

#### 问题 5: AchievementPanel 完美度详情 Tab 未实现

**描述**: 规范中定义了 `_showing_perfection_detail` 状态和完美度详情视图（3.2.3 节），但 `_build_achievement_list()` 只显示成就列表，没有切换到完美度详情的逻辑。

**规范要求**: Tab 中应包含 "完美度" 分类，切换后显示完美度详情视图

**位置**: achievement_panel.gd: L236-266, L55

**当前状态**: `_showing_perfection_detail` 始终为 false

---

#### 问题 6: 三个面板的手柄导航均未实现

**描述**: 规范定义了完整的手柄按钮映射，但没有任何手柄专属逻辑 (LB/RB Tab 切换、十字键导航等)。

**规范要求**: LB/RB 切换 Tab，摇杆选择网格项目

**建议**: 在 `_input()` 中添加手柄按钮检测:
```gdscript
if event is InputEventJoypadButton:
    if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
        _prev_tab()
    elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
        _next_tab()
```

---

### 3.3 P2 - 可选优化

#### 问题 7: AchievementPanel 详情弹窗键盘焦点管理

**描述**: 详情弹窗打开后，Tab 键会继续切换父面板（成就列表）的元素，而不是弹窗内的元素（关闭按钮、确定按钮）。

**位置**: achievement_panel.gd: L368-504

**建议**: 在弹窗打开时设置焦点范围，或使用 `Control.grab_focus()` 锁定焦点。

---

#### 问题 8: MuseumPanel 捐赠卡片点击区域过大

**描述**: 捐赠卡片的 `gui_input` 同时监听 `_on_donation_card_input`（触发捐赠）和按钮本身的 `pressed.connect`（触发 `_on_donate_item_pressed`），可能导致重复操作。

**位置**: museum_panel.gd: L558, L555

---

#### 问题 9: HiddenNPCPanel 数字键快捷键未实现

**描述**: 规范定义了 `1-7` 数字键快速选择供奉物品，但未实现。

**位置**: hidden_npc_panel.gd

---

#### 问题 10: MuseumPanel 里程碑领取按钮键盘支持

**描述**: 里程碑领取按钮 (`_on_claim_milestone_pressed`) 只有 `pressed.connect`，Tab 导航可以到达，但 Enter/Space 确认的卡片级键盘支持未实现。

**位置**: museum_panel.gd: L723-735

---

## 4. 无障碍检查

### 4.1 通过项

| 检查项 | MuseumPanel | AchievementPanel | HiddenNPCPanel |
|-------|-------------|------------------|----------------|
| 文字最小 14px | 12px (物品名称) | 12px (描述/状态) | 11px (供奉卡片) |
| 颜色对比度 WCAG AA | PASS | PASS | PASS |
| 可键盘关闭 | PASS | PASS | PASS |

### 4.2 未通过项

| 检查项 | MuseumPanel | AchievementPanel | HiddenNPCPanel |
|-------|-------------|------------------|----------------|
| Tab 导航 | FAIL | FAIL | FAIL |
| 方向键导航 | FAIL | FAIL | FAIL |
| 焦点指示器 | FAIL | FAIL | FAIL |
| 最小字号 | FAIL (12px) | PASS | FAIL (11px) |

---

## 5. 错误处理检查

| 场景 | MuseumPanel | AchievementPanel | HiddenNPCPanel |
|------|-------------|------------------|----------------|
| 系统未就绪 | "博物馆系统开发中..." (PASS) | "成就系统开发中..." (PASS) | 使用 `_system_ready` 标志 (PASS) |
| 空状态 | "背包中无可捐赠物品" (PASS) | "该分类暂无成就" (PASS) | "该分类暂无仙灵" (PASS) |
| 操作失败 | NotificationManager.show_error (PASS) | N/A | NotificationManager.show_error (PASS) |

---

## 6. 优先级汇总

| 优先级 | 问题 | 面板 |
|--------|------|------|
| P0 | 内容区缺少 ScrollContainer | HiddenNPCPanel |
| P0 | Tab/方向键导航未实现 | 全部三个 |
| P1 | Tab 切换动画未实现 | 全部三个 |
| P1 | 键盘焦点指示器缺失 | 全部三个 |
| P1 | 完美度详情 Tab 未实现 | AchievementPanel |
| P1 | 手柄导航未实现 | 全部三个 |
| P2 | 详情弹窗键盘焦点管理 | AchievementPanel |
| P2 | 数字键快捷键未实现 | HiddenNPCPanel |
| P2 | 字号低于 14px 最小值 | MuseumPanel, HiddenNPCPanel |

---

## 7. 参考实现分析

### 7.1 NpcFriendshipUI (参考面板)

`npc_friendship_ui.gd` 作为已实现的参考面板，结构简洁但缺少完整 UX 支持:
- 没有动画
- 没有键盘导航
- 没有焦点管理

这说明当前项目存在系统性的 UX 实现缺失，需要在所有面板中统一补充。

### 7.2 QuestUI (参考面板)

`quest_ui.gd` 同样缺少:
- 打开/关闭动画
- 键盘焦点管理
- 方向键导航

建议: 以 QuestUI 为基准建立面板基类，统一实现通用 UX 功能。

---

## 8. 建议行动项

### 8.1 立即修复 (Sprint 10)

1. 为 HiddenNPCPanel 添加 ScrollContainer 包装
2. 实现三个面板的基础键盘导航（Tab + 方向键）
3. 添加焦点指示器样式

### 8.2 后续迭代

4. 实现 Tab 切换动画
5. 实现手柄完整支持
6. 实现 AchievementPanel 完美度详情 Tab
7. 创建面板基类，统一通用 UX 功能

---

## 9. 附录

### 评审文件清单

| 文件 | 路径 | 用途 |
|------|------|------|
| 规范文档 | design/gdd/ui/sprint9-panel-ux-spec.md | 评审基准 |
| MuseumPanel 脚本 | src/scripts/ui/museum_panel.gd | 被评审 |
| AchievementPanel 脚本 | src/scripts/ui/achievement_panel.gd | 被评审 |
| HiddenNPCPanel 脚本 | src/scripts/ui/hidden_npc_panel.gd | 被评审 |
| MuseumPanel 场景 | src/scenes/ui/museum_panel.tscn | 被评审 |
| AchievementPanel 场景 | src/scenes/ui/achievement_panel.tscn | 被评审 |
| HiddenNPCPanel 场景 | src/scenes/ui/hidden_npc_panel.tscn | 被评审 |
| NpcFriendshipUI | src/scripts/ui/npc_friendship_ui.gd | 参考 |
| QuestUI | src/scripts/ui/quest_ui.gd | 参考 |

---

*报告结束*
