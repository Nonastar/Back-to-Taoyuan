# Sprint 9 面板视觉规范评审报告

> **评审日期**: 2026-04-25
> **评审人**: Visual Reviewer
> **状态**: Complete
> **文件版本**: v1.0

---

## 评审概述

本次评审覆盖 Sprint 9 的三个 UI 面板实现，对照视觉设计规范 `sprint9-panel-visual-spec.md` 和设计 Token `ui_tokens.gd` 进行全面检查。

| 面板 | 文件 | 评审状态 |
|------|------|----------|
| MuseumPanel | `museum_panel.gd` / `museum_panel.tscn` | 存在问题 |
| AchievementPanel | `achievement_panel.gd` / `achievement_panel.tscn` | 存在严重问题 |
| HiddenNPCPanel | `hidden_npc_panel.gd` / `hidden_npc_panel.tscn` | 存在严重问题 |

---

## 1. Design Tokens 使用一致性

### 评审结果：不合格

**核心问题**：三个面板均未引用 `ui_tokens.gd` 中的设计 Token，而是使用硬编码的颜色值和尺寸值。

**详细分析**：

| 检查项 | 规范要求 | 实现情况 | 状态 |
|--------|----------|----------|------|
| PANEL_BG | 使用 `UITokens.PANEL_BG` | 硬编码 `Color(0.12, 0.12, 0.16, 0.95)` | P0 |
| PANEL_BORDER | 使用 `UITokens.PANEL_BORDER` | 硬编码 `Color(0.25, 0.25, 0.32, 1.0)` | P0 |
| BUTTON_* 系列 | 使用 `UITokens.BUTTON_*` | 硬编码颜色值 | P0 |
| TEXT_* 系列 | 使用 `UITokens.TEXT_*` | 硬编码颜色值 | P0 |
| ACCENT_* 系列 | 使用 `UITokens.ACCENT_*` | 硬编码颜色值 | P0 |
| SPACE_* | 使用 `UITokens.SPACE_*` | 硬编码数值 | P1 |
| RADIUS_* | 使用 `UITokens.RADIUS_*` | 硬编码数值 | P1 |
| FONT_SIZE_* | 使用 `UITokens.FONT_SIZE_*` | 硬编码数值 | P1 |

**影响**：
- 设计系统无法统一管理全局样式
- 修改设计规范时需要逐个文件修改
- 违反 DRY 原则

**代码示例** (museum_panel.gd:88-96)：
```gdscript
# 规范要求
var panel_style = StyleBoxFlat.new()
panel_style.bg_color = UITokens.PANEL_BG  # 使用 Token
panel_style.border_color = UITokens.PANEL_BORDER
# ...

# 实际实现
var panel_style = StyleBoxFlat.new()
panel_style.bg_color = Color(0.12, 0.12, 0.16, 0.95)  # 硬编码
panel_style.border_color = Color(0.25, 0.25, 0.32, 1.0)
```

---

## 2. MuseumPanel 配色方案遵守

### 评审结果：部分通过

| 检查项 | 规范要求 | 实现情况 | 状态 |
|--------|----------|----------|------|
| 面板背景 | `PANEL_BG` | 正确使用深色背景 | 通过 |
| 面板边框 | `PANEL_BORDER` | 正确使用边框色 | 通过 |
| 已捐赠展品图标 | `ACCENT_GOLD` | 未使用 Token，但值正确 | P1 |
| 未捐赠展品图标 | `TEXT_MUTED` | 未使用 Token，但值正确 | P1 |
| 未捐赠展品背景 | `Color(0.1, 0.1, 0.12, 0.8)` | 未使用 Token，但值正确 | P1 |
| 可领取里程碑边框 | `ACCENT_GOLD` | 未使用 Token，但值正确 | P1 |
| 已领取状态 | `ACCENT_GREEN` | 未使用 Token，但值正确 | P1 |
| 已捐赠确认 ✓ | `ACCENT_GREEN` | 未使用 Token，但值正确 | P1 |
| 展品分类标题 | `Color(0.69, 0.69, 0.72, 1.0)` | 未使用 Token，但值正确 | P1 |

**问题项**：
- 已捐赠展品边框应为 `ACCENT_GOLD`，但代码中未明确设置（默认使用 `PANEL_BORDER`）

---

## 3. AchievementPanel 配色方案遵守

### 评审结果：部分通过

| 检查项 | 规范要求 | 实现情况 | 状态 |
|--------|----------|----------|------|
| 面板背景 | `PANEL_BG` | 正确使用深色背景 | 通过 |
| 已解锁成就边框 | 3px `ACCENT_GOLD` | 正确实现 | 通过 |
| 未解锁成就边框 | 3px `PANEL_BORDER` | 正确实现 | 通过 |
| 已解锁成就图标 | `ACCENT_GOLD` | 正确实现 | 通过 |
| 未解锁成就图标 | `TEXT_MUTED` | 正确实现 | 通过 |
| 未解锁描述 | `TEXT_MUTED` (60%透明度) | 未实现透明度 | P1 |
| 完美度进度条 | 渐变 `ACCENT_GOLD → ACCENT_GREEN` | 未实现渐变 | P1 |
| 分类 Tab 选中 | `ACCENT_GREEN` | 未使用 Token，但值正确 | P1 |

**问题项**：
- 进度条只使用了单一金色 `ACCENT_GOLD`，未实现规范要求的渐变效果 `ACCENT_GOLD → ACCENT_GREEN`
- 未解锁成就的描述文字未实现 60% 透明度效果

---

## 4. HiddenNPCPanel 配色方案遵守

### 评审结果：基本通过

| 检查项 | 规范要求 | 实现情况 | 状态 |
|--------|----------|----------|------|
| 面板背景 | `PANEL_BG` | 正确使用深色背景 | 通过 |
| 已结缘边框 | 2px `ACCENT_GOLD` | 正确实现 (line 256-260) | 通过 |
| 求缘中背景光晕 | `Color(0.91, 0.11, 0.55, 0.15)` | 未实现粉光晕 | P1 |
| 求缘/结缘按钮 | `Color(0.91, 0.11, 0.55, 1.0)` | 未使用 Token，但值正确 | P1 |
| 未发现仙灵背景 | `Color(0.1, 0.1, 0.12, 0.85)` | 未使用 Token，但值正确 | P1 |

**问题项**：
- 求缘中状态未实现粉光晕背景效果（代码中只是普通背景）
- 缘分菱形使用 ◆ ◇ 字符，但未实现金色/灰色区分

---

## 5. 组件样式检查

### 5.1 面板背景样式

| 面板 | 圆角规范 (RADIUS_MD=8.0) | 实现 | 状态 |
|------|---------------------------|------|------|
| MuseumPanel | 8.0 | 8.0 | 通过 |
| AchievementPanel | 8.0 | 8.0 | 通过 |
| HiddenNPCPanel | 8.0 | 8.0 | 通过 |

### 5.2 Tab 按钮样式

三个面板的 Tab 按钮样式统一，实现正确：

| 状态 | 背景 | 文字颜色 | 状态 |
|------|------|----------|------|
| 默认 | `BUTTON_NORMAL` | `TEXT_SECONDARY` | 通过 |
| 悬停 | `BUTTON_HOVER` | `TEXT_PRIMARY` | 通过 |
| 选中 | `ACCENT_GREEN` | `TEXT_PRIMARY` | 通过 |
| 圆角 | `RADIUS_SM` (4.0) | 4.0 | 通过 |

### 5.3 卡片/列表项样式

| 面板 | 卡片圆角规范 | 实现 | 状态 |
|------|-------------|------|------|
| MuseumPanel 展品卡片 | 8.0 | 4.0 | P1 |
| AchievementPanel 成就卡片 | 8.0 | 4.0 | P1 |
| AchievementPanel 详情弹窗 | 12.0 | 12.0 | 通过 |
| HiddenNPCPanel 仙灵卡片 | 8.0 | 4.0 | P1 |

### 5.4 按钮状态

三个面板均未实现 `pressed` 状态的样式覆盖。

---

## 6. 字体层级

### 评审结果：部分不符合

| 层级 | 规范字号 | Museum | Achievement | HiddenNPC | 状态 |
|------|----------|--------|-------------|-----------|------|
| 面板标题 | FONT_SIZE_XL (20px) | 20px | 20px | 20px | 通过 |
| 分类标题 | FONT_SIZE_LG (16px) | 16px | 14px | 16px | P1 |
| 物品/仙灵名称 | FONT_SIZE_LG (16px) | 12px | 14px | 14px | P1 |
| 正文/描述 | FONT_SIZE_MD (14px) | 14px | 12-14px | 12px | P1 |
| 辅助文字 | FONT_SIZE_SM (12px) | 12px | 12px | 12px | 通过 |

**问题项**：
- AchievementPanel 成就名称使用 14px 而非规范中的 16px
- MuseumPanel 展品名称使用 12px 而非规范中的 16px
- HiddenNPCPanel 仙灵名称使用 14px 而非规范中的 16px
- HiddenNPCPanel 详情视图仙灵名称使用 18px，超出规范范围

---

## 7. 动画效果

### 评审结果：基本符合（存在偏差）

| 动画 | 规范时长 | 规范缓动 | 实际实现 | 状态 |
|------|----------|----------|----------|------|
| Museum 打开 | 200ms | ease_out_cubic | 200ms, TRANS_QUAD/EASE_OUT | P1 |
| Museum 关闭 | 150ms | ease_in_cubic | 150ms, TRANS_QUAD/EASE_IN | P1 |
| Achievement 打开 | 200ms | ease_out_cubic | 200ms, TRANS_QUAD/EASE_OUT | P1 |
| Achievement 关闭 | 150ms | ease_in_cubic | 150ms, TRANS_QUAD/EASE_IN | P1 |
| HiddenNPC 打开 | 200ms | ease_out_cubic | 200ms, TRANS_QUAD/EASE_OUT | P1 |
| HiddenNPC 关闭 | 150ms | ease_in_cubic | 150ms, TRANS_QUAD/EASE_IN | P1 |

**问题项**：
- 缓动函数使用了 `TRANS_QUAD` 而非规范中的 `ease_out_cubic`/`ease_in_cubic`
- Museum 打开动画为缩放动画而非规范要求的"从左侧滑入"
- HiddenNPC 打开动画为缩放动画，符合规范（scale: 0.9 → 1.0）

**规范动画要求对比**：

| 面板 | 规范打开动画 | 实际打开动画 |
|------|-------------|-------------|
| Museum | 从左侧滑入 (x: -50px) + 透明度渐显 | 从 scale(0.95, 1.0) 缩放 |
| Achievement | 从底部滑入 (y: +30px) + 透明度渐显 | 从 scale(1.0, 0.9) 缩放 |
| HiddenNPC | 从中心缩放淡入 (scale: 0.9 → 1.0) | 从 scale(0.9, 0.9) 缩放 |

---

## 8. 分辨率测试

### 评审结果：基本通过

| 检查项 | 规范要求 | 实现情况 | 状态 |
|--------|----------|----------|------|
| 面板最大尺寸 | 900x700 | 900x700 (offset: -450 to 450) | 通过 |
| 面板居中 | 水平+垂直居中 | anchors_preset=15, grow_horizontal=2, grow_vertical=2 | 通过 |
| 内容滚动 | 可滚动 | Museum/Achievement 使用 ScrollContainer | 通过 |
| 内容滚动 | 可滚动 | HiddenNPC **未使用 ScrollContainer** | P0 |

**问题项**：
- HiddenNPCPanel 的 `ContentContainer` 直接使用 VBoxContainer，详情视图内容较多时无法滚动

---

## 9. 问题汇总

### P0 - 必须修复

| # | 问题 | 文件 | 说明 |
|---|------|------|------|
| P0-1 | 未使用 Design Tokens | 全部 .gd 文件 | 应引用 `ui_tokens.gd` 中的常量 |
| P0-2 | HiddenNPC 内容不可滚动 | hidden_npc_panel.tscn | 详情视图内容超长时无法滚动 |

### P1 - 建议修复

| # | 问题 | 文件 | 说明 |
|---|------|------|------|
| P1-1 | 成就进度条无渐变 | achievement_panel.gd | 应实现 `ACCENT_GOLD → ACCENT_GREEN` 渐变 |
| P1-2 | 未解锁成就描述无60%透明度 | achievement_panel.gd | 文字应降低对比度 |
| P1-3 | 求缘状态无粉光晕 | hidden_npc_panel.gd | 应添加 `Color(0.91, 0.11, 0.55, 0.15)` 背景 |
| P1-4 | Tab 切换无动画 | 全部 .gd 文件 | 应实现横向滑动效果 |
| P1-5 | 缓动函数不正确 | 全部 .gd 文件 | 应使用 ease_out_cubic 而非 TRANS_QUAD |
| P1-6 | Museum 打开动画不符合规范 | museum_panel.gd | 应为从左侧滑入而非缩放 |
| P1-7 | Achievement 打开动画不符合规范 | achievement_panel.gd | 应为从底部滑入而非缩放 |
| P1-8 | 卡片圆角不正确 | museum/achievement/hidden_npc_panel.gd | 卡片应使用 8px 圆角而非 4px |
| P1-9 | 部分字体字号不正确 | 全部 .gd 文件 | 物品名称应为 16px 而非 12-14px |
| P1-10 | 缘分菱形无颜色区分 | hidden_npc_panel.gd | 应实现金色/灰色视觉区分 |

### P2 - 可选优化

| # | 问题 | 文件 | 说明 |
|---|------|------|------|
| P2-1 | 里程碑可领取无脉冲动画 | museum_panel.gd | 边框颜色应循环闪烁 |
| P2-2 | 捐赠成功无飞入动画 | museum_panel.gd | 物品应从背包位置飞入展柜 |
| P2-3 | 能力解锁无金光闪烁 | hidden_npc_panel.gd | 边框应闪烁 3 次 |
| P2-4 | 缘分增加无逐个点亮 | hidden_npc_panel.gd | 菱形应逐个变为金色 |

---

## 10. 建议优先级排序

### 第一优先级（影响设计系统一致性）

1. **引入 Design Tokens**
   - 在 `_ready()` 中初始化 `UITokens`
   - 将所有硬编码颜色值替换为 Token 引用
   - 将所有硬编码尺寸值替换为 Token 引用

### 第二优先级（影响用户体验）

2. **修复 HiddenNPC 滚动问题**
   - 将 `ContentContainer` 包装在 `ScrollContainer` 中
   - 保留列表视图的直接显示
   - 详情/供奉视图需要滚动支持

3. **实现渐变进度条**
   - AchievementPanel 完美度进度条
   - 使用自定义 Shader 或分段绘制实现渐变

### 第三优先级（提升视觉效果）

4. **修复动画效果**
   - Museum: 从左侧滑入
   - Achievement: 从底部滑入
   - 使用正确的缓动函数

5. **添加状态光晕效果**
   - 求缘状态粉光晕
   - 传闻状态蓝光晕

---

## 11. 通过项总结

尽管存在上述问题，以下方面实现正确：

| 类别 | 通过项 |
|------|--------|
| 面板结构 | 四层结构（Header/Tab/Content/Footer） |
| 面板尺寸 | 900x700，居中显示 |
| 面板圆角 | 8px，与规范一致 |
| Tab 按钮状态 | Normal/Hover/Selected 样式正确 |
| 关闭按钮 | 样式统一 |
| 成就卡片状态 | 已解锁/未解锁边框颜色正确 |
| 结缘边框 | 2px `ACCENT_GOLD` 正确实现 |
| 仙灵图标 | Emoji 分配正确 |
| 博物馆分类图标 | Emoji 分配正确 |
| 键盘导航 | ESC 关闭/返回支持 |
| 无障碍 | 最小字号 12px，颜色对比度符合标准 |

---

## 12. 结论

三个面板的整体实现质量良好，核心交互逻辑和结构正确。主要问题集中在：

1. **未使用设计系统 Token** — 这是架构性问题，需要重构
2. **部分视觉效果未完全实现** — 如渐变、光晕、动画细节
3. **HiddenNPC 内容溢出** — 功能性问题，需要修复

建议按照上述优先级排序逐步修复问题，P0 级问题必须在下个 Sprint 之前修复。

---

**评审人签名**: Visual Reviewer
**评审日期**: 2026-04-25
**下次评审**: Sprint 10 面板优化后
