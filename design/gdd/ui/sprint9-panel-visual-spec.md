# 归园田居 - Sprint 9 UI 面板视觉设计规范

> **状态**: Draft
> **Author**: Art Director
> **Last Updated**: 2026-04-25
> **Sprint**: S9
> **Panels**: MuseumPanel (S9-T6), AchievementPanel (S9-T4), HiddenNPCPanel (S9-T2)
> **Design Tokens**: `src/design/ui_tokens.gd`
> **UX Spec**: `design/gdd/ui/sprint9-panel-ux-spec.md`

---

## 目录

1. [设计原则与基础系统](#1-设计原则与基础系统)
2. [MuseumPanel 视觉规范](#2-museumpanel-视觉规范)
3. [AchievementPanel 视觉规范](#3-achievementpanel-视觉规范)
4. [HiddenNPCPanel 视觉规范](#4-hiddennpcpanel-视觉规范)
5. [一致性检查清单](#5-一致性检查清单)
6. [附录](#6-附录)

---

## 1. 设计原则与基础系统

### 1.1 三面板共用的 Design Tokens（强制遵守）

所有面板必须使用 `src/design/ui_tokens.gd` 中定义的以下基础 Token：

| Token | 值 | 用途 |
|-------|-----|------|
| `PANEL_BG` | `Color(0.12, 0.12, 0.16, 0.95)` | 面板背景 |
| `PANEL_BORDER` | `Color(0.25, 0.25, 0.32, 1.0)` | 面板边框（默认） |
| `BUTTON_NORMAL` | `Color(0.2, 0.2, 0.25, 1.0)` | 按钮常态 |
| `BUTTON_HOVER` | `Color(0.3, 0.3, 0.38, 1.0)` | 按钮悬停 |
| `BUTTON_PRESSED` | `Color(0.15, 0.15, 0.2, 1.0)` | 按钮按下 |
| `BUTTON_DISABLED` | `Color(0.1, 0.1, 0.12, 1.0)` | 按钮禁用 |
| `TEXT_PRIMARY` | `Color(0.95, 0.95, 0.95, 1.0)` | 主要文字 |
| `TEXT_SECONDARY` | `Color(0.7, 0.7, 0.75, 1.0)` | 次要文字 |
| `TEXT_MUTED` | `Color(0.5, 0.5, 0.55, 1.0)` | 禁用/辅助文字 |
| `ACCENT_GREEN` | `Color(0.18, 0.8, 0.44, 1.0)` | 确认/成功 |
| `ACCENT_RED` | `Color(0.91, 0.3, 0.24, 1.0)` | 警告/错误 |
| `ACCENT_GOLD` | `Color(1.0, 0.84, 0.0, 1.0)` | 高亮/成就/重要 |
| `SPACE_4/8/12/16/24/32` | `4/8/12/16/24/32` px | 间距 |
| `RADIUS_SM/MD/LG` | `4.0/8.0/12.0` | 圆角半径 |
| `FONT_SIZE_SM/MD/LG/XL` | `12/14/16/20` px | 字号 |
| `BUTTON_HEIGHT` | `44` px | 按钮高度 |
| `ICON_SIZE` | `24` px | 图标尺寸 |
| `PANEL_HEADER_HEIGHT` | `50` px | 面板标题栏高度 |

### 1.2 面板结构规范

三个面板均遵循四层结构，与 UX 规范一致：

```
[Header] - 标题 + 关闭按钮       高度: 50px (PANEL_HEADER_HEIGHT)
[TabNav] - Tab 切换按钮栏         高度: 44px (BUTTON_HEIGHT)
[Content] - 主内容区（可滚动）    flex-grow
[Footer] - 底部状态/操作栏（可选） 高度: 50px
```

**通用布局规则**:
- 面板最大宽度: 900px
- 面板最大高度: 700px
- 面板居中: 水平 + 垂直居中
- 背景遮罩: 半透明黑色 `Color(0,0,0,0.5)`
- 内边距: `SPACE_16 = 16px`（与现有面板一致）
- 边框宽度: `1px`
- 圆角: `RADIUS_MD = 8.0`（面板根容器）
- Tab 按钮内部间距: `SPACE_8`
- 卡片间距: `SPACE_12`
- 列表项间距: `SPACE_8`

### 1.3 图标方案

所有面板使用 Unicode emoji，与现有 HUD (`src/scripts/ui/hud.gd`) 保持一致。

**图标规格**:
- 显示字号: 与容器匹配的 emoji 渲染（通常 `FONT_SIZE_LG = 16px` 的 1.2-1.5 倍视觉大小）
- 无特殊描边或背景，纯色渲染
- 禁用状态: emoji 整体降低透明度至 `0.4`

**各面板图标分配**:

| 面板 | 图标 | 用途 |
|------|------|------|
| MuseumPanel | 🏛️ | 面板标题 |
| MuseumPanel | 💎 | 宝石分类 |
| MuseumPanel | ⛏️ | 矿石分类 |
| MuseumPanel | 🔩 | 金属锭分类 |
| MuseumPanel | 🦴 | 化石分类 |
| MuseumPanel | 🏺 | 古物分类 |
| MuseumPanel | ✨ | 仙灵物品分类 |
| MuseumPanel | ❓ | 未发现展品占位 |
| MuseumPanel | ✓ | 已捐赠确认 |
| AchievementPanel | ⭐ | 面板标题 / 已解锁成就 |
| AchievementPanel | 🏆 | 成就图标（部分成就） |
| AchievementPanel | 🔒 | 未解锁成就 |
| AchievementPanel | ★ | 完美度 Tab |
| HiddenNPCPanel | ◈ | 面板标题 |
| HiddenNPCPanel | ✨ | 龙灵 |
| HiddenNPCPanel | 🌸 | 桃夭 |
| HiddenNPCPanel | 🌊 | 月兔 |
| HiddenNPCPanel | 🐰 | 月兔（替代方案） |
| HiddenNPCPanel | 🦊 | 狐仙 |
| HiddenNPCPanel | ⛰️ | 山翁 |
| HiddenNPCPanel | 👧 | 归女 |
| HiddenNPCPanel | 🔒 | 未发现仙灵 |
| HiddenNPCPanel | 💕 | 求缘中 |
| HiddenNPCPanel | 💍 | 已结缘 |

### 1.4 字体系统

三面板统一使用以下字体规范层级：

| 层级 | 字号 | 颜色 | 用途 | 字重 |
|------|------|------|------|------|
| 面板标题 | `FONT_SIZE_XL = 20px` | `TEXT_PRIMARY` | 面板 Header 文字 | Bold |
| 分类标题 | `FONT_SIZE_LG = 16px` | `TEXT_PRIMARY` | Tab 标签、分类标题 | Bold |
| 物品/仙灵名称 | `FONT_SIZE_LG = 16px` | `TEXT_PRIMARY` | 卡片内名称 | Medium |
| 正文/描述 | `FONT_SIZE_MD = 14px` | `TEXT_SECONDARY` | 描述文字、进度说明 | Regular |
| 数据/数值 | `FONT_SIZE_MD = 14px` | `ACCENT_GOLD` | 计数、百分比、金币数 | Bold |
| 辅助说明 | `FONT_SIZE_SM = 12px` | `TEXT_MUTED` | 锁定状态、次要提示 | Regular |
| 徽章/标签 | `FONT_SIZE_SM = 12px` | `TEXT_PRIMARY` | 状态徽章、Tab 标签 | Medium |

---

## 2. MuseumPanel 视觉规范

> **主题**: 收藏、古物、庄重
> **UX 编号**: S9-T6
> **Icon**: 🏛️

### 2.1 配色方案

#### 基础配色（来自 Design Tokens）

| 用途 | Token | 值 | 说明 |
|------|-------|-----|------|
| 面板背景 | `PANEL_BG` | `Color(0.12, 0.12, 0.16, 0.95)` | 统一使用 |
| 面板边框 | `PANEL_BORDER` | `Color(0.25, 0.25, 0.32, 1.0)` | 统一使用 |
| 关闭按钮 | `BUTTON_NORMAL/HOVER/PRESSED` | 见 Token 表 | 统一使用 |
| 主要文字 | `TEXT_PRIMARY` | `Color(0.95, 0.95, 0.95, 1.0)` | 标题、名称 |
| 次要文字 | `TEXT_SECONDARY` | `Color(0.7, 0.7, 0.75, 1.0)` | 描述、计数 |

#### 扩展配色（博物馆专属）

| 状态 | 颜色 Hex | RGBA | 用途 |
|------|----------|------|------|
| 已捐赠展品图标 | #FFD700 | `Color(1.0, 0.84, 0.0, 1.0)` | 使用 `ACCENT_GOLD` |
| 已捐赠展品光晕 | #FFD700 | `Color(1.0, 0.84, 0.0, 0.15)` | 微弱金色背景光（无 Glow，改为轻背景色） |
| 未捐赠展品图标 | #808080 | `Color(0.5, 0.5, 0.5, 1.0)` | 使用 `TEXT_MUTED` |
| 未捐赠展品背景 | #1A1A1F | `Color(0.1, 0.1, 0.12, 0.8)` | 比 `PANEL_BG` 更暗的占位背景 |
| 可领取里程碑边框 | #FFD700 | `Color(1.0, 0.84, 0.0, 1.0)` | 使用 `ACCENT_GOLD` |
| 可领取脉冲动画 | #FFD700 | `Color(1.0, 0.84, 0.0, 0.3)` | 脉冲背景（简单 opacity 动画） |
| 已领取状态 | #4CAF50 | `Color(0.3, 0.69, 0.31, 1.0)` | 使用 `ACCENT_GREEN` |
| 已领取勾选图标 | #808080 | `Color(0.5, 0.5, 0.5, 1.0)` | 使用 `TEXT_MUTED` |
| 未解锁里程碑 | #404040 | `Color(0.25, 0.25, 0.25, 1.0)` | 比 `TEXT_MUTED` 更暗 |
| 捐赠成功确认 | #4CAF50 | `Color(0.3, 0.69, 0.31, 1.0)` | 使用 `ACCENT_GREEN` |
| 展品分类标题 | #B0B0B8 | `Color(0.69, 0.69, 0.72, 1.0)` | 比 `TEXT_SECONDARY` 亮一些，庄重感 |

#### 捐赠进度条配色

| 用途 | 颜色 Hex | RGBA |
|------|----------|------|
| 进度条背景 | #2A2A30 | `Color(0.16, 0.16, 0.19, 1.0)` |
| 进度条填充 | #FFD700 | `Color(1.0, 0.84, 0.0, 1.0)` — 使用 `ACCENT_GOLD` |
| 进度条已完成段 | #4CAF50 | `Color(0.3, 0.69, 0.31, 1.0)` — 使用 `ACCENT_GREEN`（可选渐变方案见下方） |

**渐变方案（可选）**:
- 从 `ACCENT_GOLD` (`#FFD700`) 到 `ACCENT_GREEN` (`#4CAF50`) 的水平渐变
- 仅在进度超过里程碑阈值时启用渐变效果

### 2.2 字体规范

| 内容 | 字号 | 颜色 | 字重 | 说明 |
|------|------|------|------|------|
| 面板标题 "博物馆" | `FONT_SIZE_XL = 20px` | `TEXT_PRIMARY` | Bold | Header 内带 🏛️ emoji |
| 捐赠进度数值 | `FONT_SIZE_XL = 20px` | `ACCENT_GOLD` | Bold | "12/40" 的大号数字 |
| 进度百分比 | `FONT_SIZE_MD = 14px` | `TEXT_SECONDARY` | Regular | "30.0%" |
| 分类标题（如"矿石"） | `FONT_SIZE_LG = 16px` | `TEXT_PRIMARY` | Bold | 分类区块标题 |
| 展品名称 | `FONT_SIZE_SM = 12px` | `TEXT_PRIMARY` | Medium | 展柜格子内物品名 |
| 已捐赠确认 | `FONT_SIZE_SM = 12px` | `ACCENT_GREEN` | Medium | "✓" 符号 |
| 里程碑名称 | `FONT_SIZE_MD = 14px` | `TEXT_PRIMARY` | Bold | 里程碑行标题 |
| 里程碑奖励 | `FONT_SIZE_SM = 12px` | `TEXT_SECONDARY` | Regular | 金钱和物品描述 |
| 里程碑状态标签 | `FONT_SIZE_SM = 12px` | `ACCENT_GOLD` / `ACCENT_GREEN` / `TEXT_MUTED` | Medium | "可领取"/"已领取"/"X件后解锁" |
| 底部统计 | `FONT_SIZE_SM = 12px` | `TEXT_SECONDARY` | Regular | "已捐赠: 12件" |

### 2.3 间距系统

| 位置 | 间距 | 说明 |
|------|------|------|
| 面板内边距 | `SPACE_16 = 16px` | 面板边缘到内容的间距 |
| Tab 按钮之间 | `SPACE_8 = 8px` | Tab 按钮横向排列的间隔 |
| 分类标题与内容 | `SPACE_16 = 16px` | 分类区块标题上方间距 |
| 展品卡片之间 | `SPACE_12 = 12px` | 展柜网格内卡片的行列间距 |
| 展品卡片内边距 | `SPACE_8 = 8px` | 卡片内容到卡边界的距离 |
| 里程碑条目之间 | `SPACE_12 = 12px` | 里程碑列表项的间距 |
| 里程碑内容区内边距 | `SPACE_12 = 12px` | 里程碑行内文字与边框的间距 |

### 2.4 组件样式

#### 2.4.1 展品卡片（展柜视图 / 捐赠视图）

**尺寸**: 宽度根据网格自适应，高度 64px（展柜）/ 80px（捐赠）

**状态样式**:

| 状态 | 背景 | 边框 | 图标颜色 | 文字 |
|------|------|------|----------|------|
| **已捐赠** | `PANEL_BG` | 1px `PANEL_BORDER` | `ACCENT_GOLD` | `TEXT_PRIMARY` |
| **未捐赠（未发现）** | `Color(0.1, 0.1, 0.12, 0.8)` | 1px `PANEL_BORDER` | `TEXT_MUTED` | `TEXT_MUTED` |
| **未捐赠（可捐赠）** | `PANEL_BG` | 1px `PANEL_BORDER` | `TEXT_PRIMARY` | `TEXT_PRIMARY` |
| **悬停（可交互）** | `BUTTON_HOVER` | 1px `ACCENT_GOLD` | - | - |
| **选中** | `BUTTON_PRESSED` | 2px `ACCENT_GOLD` | - | - |

**内部布局**:
```
┌──────────────────────────┐
│ [图标 emoji]  [名称]      │
│              [状态/计数]  │
└──────────────────────────┘
```

#### 2.4.2 里程碑条目

**尺寸**: 高度自适应，内容较多时约 70px

**状态样式**:

| 状态 | 背景 | 左边框 | 标题颜色 | 按钮 |
|------|------|--------|----------|------|
| **已解锁未领取** | `PANEL_BG` | 3px `ACCENT_GOLD` | `TEXT_PRIMARY` | "领取" 按钮（高亮，背景 `ACCENT_GOLD`，文字深色） |
| **可领取** | `PANEL_BG` | 3px `ACCENT_GOLD` | `TEXT_PRIMARY` | "领取" 按钮（脉冲动画边框） |
| **已领取** | `Color(0.1, 0.1, 0.12, 0.6)` | 3px `TEXT_MUTED` | `TEXT_MUTED` | "已领取"（禁用按钮，灰色文字） |
| **未解锁** | `Color(0.1, 0.1, 0.12, 0.6)` | 3px `TEXT_MUTED` | `TEXT_MUTED` | 无按钮，显示 "X件后解锁" |

**内部布局**:
```
┌────────────────────────────────────────────────────────┐
│ ⭐ [里程碑名称] (X件)         [状态标签 / 领取按钮]     │
│    💰 奖励描述                                         │
└────────────────────────────────────────────────────────┘
```

#### 2.4.3 Tab 按钮

与现有面板保持一致：
- 默认: `BUTTON_NORMAL` 背景, `TEXT_SECONDARY` 文字
- 选中: `ACCENT_GREEN` 背景, `TEXT_PRIMARY` 文字
- 悬停: `BUTTON_HOVER` 背景

#### 2.4.4 进度条

**高度**: 8px
**圆角**: `RADIUS_SM = 4.0`
**背景**: `Color(0.16, 0.16, 0.19, 1.0)`
**填充**: `ACCENT_GOLD`，进度超过里程碑阈值后使用 `ACCENT_GOLD → ACCENT_GREEN` 渐变

### 2.5 动画规范

| 动画 | 触发时机 | 时长 | 缓动函数 | 效果描述 |
|------|----------|------|----------|----------|
| 面板打开 | open() | 200ms | `Easing.ease_out_cubic` | 从左侧滑入 (x: -50px → x: 0) + 透明度渐显 |
| 面板关闭 | close() | 150ms | `Easing.ease_in_cubic` | 向左侧滑出 (x: 0 → x: -50px) + 透明度渐隐 |
| Tab 切换 | 点击 Tab | 150ms | `Easing.ease_in_out` | 内容区横向滑动（当前内容左滑出，新内容右滑入） |
| 捐赠成功 | 确认捐赠 | 500ms | `Easing.ease_out` | 物品图标从背包位置飞入最近的展柜格子，原位置淡出，终点格子脉冲发光 |
| 捐赠反馈 | 捐赠成功自动 | 400ms | `Easing.ease_out` | 进度条填充动画（宽度从旧值到新值），飘窗显示 "+1 已捐赠" |
| 里程碑解锁 | 达到里程碑计数 | 600ms | `Easing.ease_out` | 该里程碑条目金光闪烁（边框颜色闪烁 3 次 `ACCENT_GOLD`，每次 200ms） |
| 领取奖励 | 点击领取 | 400ms | `Easing.ease_out` | 按钮变为"已领取"，金币数字弹出从里程碑位置飞向 HUD 金钱显示区 |
| 展品填充 | 新捐赠展品 | 300ms | `Easing.ease_out` | 该展品卡片从 `未捐赠（未发现）` 样式过渡到 `已捐赠` 样式（背景色 + 图标颜色同时过渡） |

**脉冲动画（里程碑可领取）**:
- 边框颜色在 `ACCENT_GOLD` 和 `Color(1.0, 0.84, 0.0, 0.3)` 之间循环
- 周期: 1000ms
- 缓动: `Easing.ease_in_out_sine`

---

## 3. AchievementPanel 视觉规范

> **主题**: 成就、金色、荣耀感
> **UX 编号**: S9-T4
> **Icon**: ⭐

### 3.1 配色方案

#### 基础配色（来自 Design Tokens）

| 用途 | Token | 值 | 说明 |
|------|-------|-----|------|
| 面板背景 | `PANEL_BG` | `Color(0.12, 0.12, 0.16, 0.95)` | 统一使用 |
| 面板边框 | `PANEL_BORDER` | `Color(0.25, 0.25, 0.32, 1.0)` | 统一使用 |
| 关闭按钮 | `BUTTON_*` | 见 Token 表 | 统一使用 |
| 主要文字 | `TEXT_PRIMARY` | `Color(0.95, 0.95, 0.95, 1.0)` | 标题、名称 |
| 次要文字 | `TEXT_SECONDARY` | `Color(0.7, 0.7, 0.75, 1.0)` | 描述、完成时间 |
| 辅助文字 | `TEXT_MUTED` | `Color(0.5, 0.5, 0.55, 1.0)` | 未解锁描述（模糊） |

#### 扩展配色（成就专属）

| 状态 | 颜色 Hex | RGBA | 用途 |
|------|----------|------|------|
| 已解锁成就图标 | #FFD700 | `Color(1.0, 0.84, 0.0, 1.0)` | 使用 `ACCENT_GOLD` |
| 已解锁成就光晕 | #FFD700 | `Color(1.0, 0.84, 0.0, 0.1)` | 成就卡片微弱金色背景 |
| 未解锁成就图标 | #808080 | `Color(0.5, 0.5, 0.5, 1.0)` | 使用 `TEXT_MUTED` |
| 未解锁描述 | #808080 | `Color(0.5, 0.5, 0.5, 0.6)` | 文字降低对比度（视觉模糊） |
| 完美度进度条渐变起点 | #FFD700 | `ACCENT_GOLD` | 进度条左侧 |
| 完美度进度条渐变终点 | #4CAF50 | `ACCENT_GREEN` | 进度条右侧 |
| 完美度数字 | #FFD700 | `ACCENT_GOLD` | 大号百分比数字 |
| 分类 Tab 选中 | #2ECC71 | `ACCENT_GREEN` | 当前激活的分类 Tab |
| 成就完成时间 | #B0B0B8 | `Color(0.69, 0.69, 0.72, 1.0)` | 比 `TEXT_SECONDARY` 稍亮 |

#### 完美度进度条配色

| 用途 | 颜色 | 说明 |
|------|------|------|
| 背景 | `Color(0.16, 0.16, 0.19, 1.0)` | 统一 |
| 进度填充 | 线性渐变 `ACCENT_GOLD → ACCENT_GREEN` | 从 0% 到 100% 渐变 |
| 里程碑标记 | `ACCENT_GOLD` | 25%/50%/75% 处的细线标记 |

### 3.2 字体规范

| 内容 | 字号 | 颜色 | 字重 | 说明 |
|------|------|------|------|------|
| 面板标题 "成就" | `FONT_SIZE_XL = 20px` | `TEXT_PRIMARY` | Bold | Header 内带 ⭐ emoji |
| 完美度数字 | `FONT_SIZE_XL = 20px` | `ACCENT_GOLD` | Bold | "45.2%" |
| 完美度标签 | `FONT_SIZE_MD = 14px` | `TEXT_SECONDARY` | Regular | "完美度:" |
| 分类 Tab 标签 | `FONT_SIZE_MD = 14px` | 选中: `TEXT_PRIMARY` / 未选: `TEXT_SECONDARY` | Medium | Tab 文字 |
| 成就名称 | `FONT_SIZE_MD = 14px` | `TEXT_PRIMARY` | Medium | 成就列表项名称 |
| 成就描述 | `FONT_SIZE_SM = 12px` | 已完成: `TEXT_SECONDARY` / 未完成: `TEXT_MUTED`(60%透明度) | Regular | 成就描述文字 |
| 进度数字 | `FONT_SIZE_SM = 12px` | `ACCENT_GOLD` | Bold | "8/10 棵" |
| 完成时间 | `FONT_SIZE_SM = 12px` | `TEXT_SECONDARY` | Regular | "完成时间: 第28天" |
| 奖励信息 | `FONT_SIZE_SM = 12px` | `TEXT_PRIMARY` | Regular | "奖励: 💰 100g" |
| 底部说明文字 | `FONT_SIZE_SM = 12px` | `TEXT_MUTED` | Regular | 完美度计算公式说明 |

### 3.3 间距系统

| 位置 | 间距 | 说明 |
|------|------|------|
| 面板内边距 | `SPACE_16 = 16px` | 面板边缘到内容 |
| 完美度栏与 Tab 之间 | `SPACE_12 = 12px` | 视觉分组 |
| Tab 按钮之间 | `SPACE_8 = 8px` | Tab 横向排列间隔 |
| 成就卡片之间 | `SPACE_12 = 12px` | 列表项间距 |
| 成就卡片内边距 | `SPACE_12 = 12px` | 卡片内容与边框 |
| 详情弹窗内边距 | `SPACE_24 = 24px` | 弹窗内容区边距 |
| 详情弹窗元素间距 | `SPACE_16 = 16px` | 弹窗内各元素间距 |

### 3.4 组件样式

#### 3.4.1 完美度栏

**位置**: Tab 导航上方，紧贴 Tab

**布局**:
```
[完美度: 45.2%]
[████████████████████████░░░░░░░░░░░░░░░░░░░░░░] 45.2%
```

**样式**:
- 标题 "完美度:" — `FONT_SIZE_MD`, `TEXT_SECONDARY`
- 数字 "45.2%" — `FONT_SIZE_XL`, `ACCENT_GOLD`, Bold
- 进度条高度: 10px（比博物馆的 8px 多 2px，突出成就感）
- 进度条圆角: `RADIUS_SM = 4.0`
- 进度条背景: `Color(0.16, 0.16, 0.19, 1.0)`
- 进度条填充: 渐变 `ACCENT_GOLD → ACCENT_GREEN`
- 百分比数字: `FONT_SIZE_MD`, `TEXT_SECONDARY`，放在进度条右侧

#### 3.4.2 成就卡片

**尺寸**: 宽度 100%，高度自适应（约 64px）

**状态样式**:

| 状态 | 背景 | 左侧边框 | 图标 | 名称颜色 | 描述 |
|------|------|----------|------|----------|------|
| **已完成** | `PANEL_BG` | 3px `ACCENT_GOLD` | ⭐ `ACCENT_GOLD` | `TEXT_PRIMARY` | `TEXT_SECONDARY` |
| **未完成** | `PANEL_BG` | 3px `PANEL_BORDER` | 🔒 `TEXT_MUTED` | `TEXT_PRIMARY` | `TEXT_MUTED`(60%对比度) |
| **悬停** | `BUTTON_HOVER` | 3px `ACCENT_GOLD` | - | - | - |
| **键盘焦点** | `BUTTON_PRESSED` | 3px `ACCENT_GOLD` | - | - | - |

**内部布局**:
```
┌─────────────────────────────────────────────────────────┐
│ ⭐ [成就名称]                              [进度条/✓]    │
│    [描述文字]                                            │
│    [完成时间 / 进度: X/Y]                                │
└─────────────────────────────────────────────────────────┘
```

#### 3.4.3 成就详情弹窗

**尺寸**: 宽度 400px，高度自适应（最大 500px）
**圆角**: `RADIUS_LG = 12.0`
**遮罩**: `Color(0, 0, 0, 0.6)`

**布局**:
```
┌─────────────────────────────────────────┐
│                                          │
│              [成就图标] ⭐⭐⭐⭐⭐            │
│                                          │
│              [成就名称]                   │
│              [描述]                       │
│                                          │
│  [████████████████████████████░░░░░░]   │
│              8/10 棵                      │
│                                          │
│              ✓ 已完成                      │
│              完成时间: 第28天              │
│                                          │
│  奖励: 💰 100g   [种子礼盒 ×1]            │
│                                          │
│           [确定]                         │
└─────────────────────────────────────────┘
```

**样式**:
- 成就图标区: 80px × 80px 容器，带 `ACCENT_GOLD` 边框（2px）
- 星星评级: ⭐ 符号排列在图标下方
- 进度条: 高度 8px，圆角 `RADIUS_SM`
- 确定按钮: 高度 `BUTTON_HEIGHT = 44px`，宽度 200px，背景 `ACCENT_GREEN`

#### 3.4.4 Tab 按钮

| 状态 | 背景 | 文字颜色 | 边框 |
|------|------|----------|------|
| 默认 | `BUTTON_NORMAL` | `TEXT_SECONDARY` | 无 |
| 悬停 | `BUTTON_HOVER` | `TEXT_PRIMARY` | 无 |
| 选中 | `ACCENT_GREEN` | `TEXT_PRIMARY` | 无 |

#### 3.4.5 完美度详情视图

**替代默认成就列表的子视图**，通过点击完美度栏或按 `P` 键进入。

**布局**: 与成就列表视图共用面板结构，内容区显示完美度分解。

**样式**:
- 大号百分比居中显示: `FONT_SIZE_XL = 20px` × 2 行，行高 40px
- 分项进度条与成就列表一致
- 权重标签: `FONT_SIZE_SM = 12px`，`TEXT_MUTED`，右对齐

### 3.5 动画规范

| 动画 | 触发时机 | 时长 | 缓动函数 | 效果描述 |
|------|----------|------|----------|----------|
| 面板打开 | open() | 200ms | `Easing.ease_out_cubic` | 从底部滑入 (y: +30px → y: 0) + 透明度渐显 |
| 面板关闭 | close() | 150ms | `Easing.ease_in_cubic` | 向底部滑出 (y: 0 → y: +30px) + 透明度渐隐 |
| Tab 切换 | 点击 Tab | 150ms | `Easing.ease_in_out` | 内容区横向滑动（与博物馆一致） |
| 成就解锁 | 成就完成 | 600ms | `Easing.ease_out` | 卡片区域金光爆发：从中心扩散的金色圆形遮罩（opacity 0 → 0.4 → 0），同时成就图标从 🔒 变形为 ⭐（scale 0.8 → 1.0 + bounce） |
| 解锁通知 | 成就完成时 | - | - | 飘窗提示 "🎉 成就解锁: [名称]" + 音效（待音效规范确定后补充） |
| 滚动 | 浏览列表 | - | `Easing.ease_out` | 平滑滚动，滚动惯性 |
| 详情弹窗 | 点击成就 | 200ms | `Easing.ease_out_back` | 从中心缩放弹出 (scale: 0.9 → 1.0)，背景遮罩淡入 |
| 弹窗关闭 | ESC/点击外部/确定 | 150ms | `Easing.ease_in` | 缩放收起 (scale: 1.0 → 0.95)，遮罩淡出 |
| 完美度更新 | 数值变化 | 500ms | `Easing.ease_out` | 数字滚动动画（旧数值 → 新数值，每次跳动 1%，持续 500ms） |
| 完美度进度条 | 数值变化 | 500ms | `Easing.ease_out` | 进度条宽度从旧值动画到新值 |

---

## 4. HiddenNPCPanel 视觉规范

> **主题**: 神秘、古风、仙气
> **UX 编号**: S9-T2
> **Icon**: ◈

### 4.1 配色方案

#### 基础配色（来自 Design Tokens）

| 用途 | Token | 值 | 说明 |
|------|-------|-----|------|
| 面板背景 | `PANEL_BG` | `Color(0.12, 0.12, 0.16, 0.95)` | 统一使用 |
| 面板边框 | `PANEL_BORDER` | `Color(0.25, 0.25, 0.32, 1.0)` | 统一使用（结缘状态替换） |
| 关闭按钮 | `BUTTON_*` | 见 Token 表 | 统一使用 |
| 主要文字 | `TEXT_PRIMARY` | `Color(0.95, 0.95, 0.95, 1.0)` | 标题、名称 |
| 次要文字 | `TEXT_SECONDARY` | `Color(0.7, 0.7, 0.75, 1.0)` | 描述 |
| 辅助文字 | `TEXT_MUTED` | `Color(0.5, 0.5, 0.55, 1.0)` | 未发现状态 |

#### 扩展配色（仙灵专属）

| 状态 | 颜色 Hex | RGBA | 用途 |
|------|----------|------|------|
| 缘分菱形（已点亮） | #FFD700 | `ACCENT_GOLD` | 已激活的缘分菱形 |
| 缘分菱形（未点亮） | #808080 | `TEXT_MUTED` | 未激活的缘分菱形 |
| 求缘中光晕 | #E91E8C | `Color(0.91, 0.11, 0.55, 0.15)` | 求缘状态仙灵卡片背景光晕（无 Glow，改为背景色） |
| 已结缘边框 | #FFD700 | `ACCENT_GOLD` | 结缘仙灵的卡片边框（替换 `PANEL_BORDER`），实线 2px |
| 已结缘背景 | #FFD700 | `Color(1.0, 0.84, 0.0, 0.05)` | 结缘仙灵卡片的微弱金色背景 |
| 未发现仙灵遮罩 | #1A1A1F | `Color(0.1, 0.1, 0.12, 0.85)` | 比 `PANEL_BG` 更暗的背景 |
| 发现传闻光晕 | #4FC3F7 | `Color(0.31, 0.76, 0.97, 0.12)` | 传闻阶段仙灵的微弱蓝色背景 |
| 能力已解锁标签 | #FFD700 | `ACCENT_GOLD` | 能力名称前的 ✓ 标记 |
| 能力未解锁 | #808080 | `TEXT_MUTED` | 未解锁能力整体样式 |
| 能力解锁金光 | #FFD700 | `Color(1.0, 0.84, 0.0, 0.6)` | 解锁动画中的金色闪烁（无 Glow，opacity 闪烁） |
| 显灵日提示 | #E91E8C | `Color(0.91, 0.11, 0.55, 1.0)` | 显灵日提示文字，使用粉红色强调特殊日期 |
| 供奉预览标签 | #FFD700 | `ACCENT_GOLD` | "预计缘分: +100" 数字颜色 |
| 求缘/结缘按钮 | #E91E8C | `Color(0.91, 0.11, 0.55, 1.0)` | 求缘/结缘按钮背景（粉色，与求缘状态呼应） |
| 求缘/结缘按钮悬停 | #F06292 | `Color(0.94, 0.38, 0.57, 1.0)` | 更亮的粉色 |
| 求缘/结缘按钮禁用 | #808080 | `BUTTON_DISABLED` | 缘分不足时禁用 |

### 4.2 字体规范

| 内容 | 字号 | 颜色 | 字重 | 说明 |
|------|------|------|------|------|
| 面板标题 "仙灵" | `FONT_SIZE_XL = 20px` | `TEXT_PRIMARY` | Bold | Header 内带 ◈ emoji |
| 仙灵名称 | `FONT_SIZE_LG = 16px` | `TEXT_PRIMARY` | Bold | 卡片名称或详情视图名称 |
| 仙灵称号 | `FONT_SIZE_MD = 14px` | `TEXT_SECONDARY` | Regular | 如 "潜渊龙灵" |
| 缘分等级名称 | `FONT_SIZE_MD = 14px` | `ACCENT_GOLD` | Bold | "信任"、"倾心" 等 |
| 缘分数值 | `FONT_SIZE_MD = 14px` | `TEXT_SECONDARY` | Regular | "1200/3000" |
| 缘分菱形标签 | `FONT_SIZE_SM = 12px` | `TEXT_MUTED` | Regular | "戒备" → "好奇" → ... |
| 能力名称 | `FONT_SIZE_MD = 14px` | 已解锁: `TEXT_PRIMARY` / 未解锁: `TEXT_MUTED` | Medium | 能力列表项 |
| 能力描述 | `FONT_SIZE_SM = 12px` | 已解锁: `TEXT_SECONDARY` / 未解锁: `TEXT_MUTED` | Regular | 能力效果描述 |
| 能力解锁条件 | `FONT_SIZE_SM = 12px` | `TEXT_MUTED` | Regular | "还需300缘分" |
| 发现阶段名称 | `FONT_SIZE_MD = 14px` | 根据阶段变化 | Medium | "未发现"/"传闻"/"惊鸿"/"邂逅"/"往来" |
| 羁绊状态标签 | `FONT_SIZE_SM = 12px` | 求缘: `#E91E8C` / 结缘: `ACCENT_GOLD` / 正常: `TEXT_SECONDARY` | Medium | "正常"/"求缘中"/"已结缘" |
| 每日剩余次数 | `FONT_SIZE_MD = 14px` | `TEXT_SECONDARY` | Regular | "今日剩余: 供奉 1次 \| 互动 1次" |
| 操作按钮文字 | `FONT_SIZE_MD = 14px` | 根据按钮类型 | Medium | "参悟"/"供奉"/"求缘" |
| 按钮加文字 | `FONT_SIZE_SM = 12px` | `TEXT_SECONDARY` | Regular | "+30~∞"/"+10~100" |
| 未发现仙灵名称 | `FONT_SIZE_LG = 16px` | `TEXT_MUTED` | Medium | "???" |
| 供奉物品品质标签 | `FONT_SIZE_SM = 12px` | 普通: `TEXT_SECONDARY` / 珍贵: `ACCENT_GOLD` | Regular | "普通"/"珍贵"/"灵犀" |
| 供奉预览缘分 | `FONT_SIZE_MD = 14px` | `ACCENT_GOLD` | Bold | "+100 (灵犀供奉)" |

### 4.3 间距系统

| 位置 | 间距 | 说明 |
|------|------|------|
| 面板内边距 | `SPACE_16 = 16px` | 面板边缘到内容 |
| Tab 与内容之间 | `SPACE_12 = 12px` | 视觉分组 |
| 仙灵卡片网格间距 | `SPACE_12 = 12px` | 行列间距 |
| 仙灵卡片内边距 | `SPACE_12 = 12px` | 卡片内容与边框 |
| 详情视图头像与信息之间 | `SPACE_16 = 16px` | 横向排列时的间距 |
| 缘分进度条与标签 | `SPACE_8 = 8px` | 进度条上下间距 |
| 能力列表项之间 | `SPACE_8 = 8px` | 列表项间距 |
| 能力列表内边距 | `SPACE_12 = 12px` | 列表项内容与边框 |
| 操作按钮之间 | `SPACE_12 = 12px` | 按钮组横向间距 |
| 供奉选择分类之间 | `SPACE_16 = 16px` | 分类区块间距 |
| 供奉物品卡片之间 | `SPACE_8 = 8px` | 物品网格间距 |

### 4.4 组件样式

#### 4.4.1 仙灵卡片（列表视图）

**尺寸**: 宽度根据网格自适应（3列），高度 100px

**状态样式**:

| 状态 | 背景 | 边框 | 图标 | 名称 | 缘分显示 |
|------|------|------|------|------|----------|
| **已发现（正常）** | `PANEL_BG` | 1px `PANEL_BORDER` | `TEXT_PRIMARY` | `TEXT_PRIMARY` | 菱形（部分金色） |
| **已发现（求缘中）** | `PANEL_BG` + 底部 `Color(0.91, 0.11, 0.55, 0.15)` 渐变背景 | 1px `PANEL_BORDER` | `TEXT_PRIMARY` | `TEXT_PRIMARY` | 全部金色菱形 + 💕 标签 |
| **已发现（已结缘）** | `PANEL_BG` + 微弱金色背景 `Color(1.0, 0.84, 0.0, 0.05)` | **2px `ACCENT_GOLD`** | `ACCENT_GOLD` | `TEXT_PRIMARY` | 全部金色菱形 |
| **未发现（传闻）** | `PANEL_BG` + 微弱蓝色背景 `Color(0.31, 0.76, 0.97, 0.12)` | 1px `PANEL_BORDER` | `TEXT_MUTED` | `TEXT_MUTED` | "传闻" 文字 |
| **未发现（未发现）** | `Color(0.1, 0.1, 0.12, 0.85)` | 1px `PANEL_BORDER` | `TEXT_MUTED` | `TEXT_MUTED` | 🔒 图标 + "未发现" |
| **悬停** | `BUTTON_HOVER` | 1px `ACCENT_GOLD` | - | - | - |
| **键盘焦点** | `BUTTON_PRESSED` | 2px `ACCENT_GOLD` | - | - | - |

**内部布局（已发现仙灵）**:
```
┌──────────────────────────────┐
│  [emoji]   [名称]             │
│           [称号]             │
│           ◇◇◇◇◇◇◇◇◇◇◇       │
│           戒备  0/3000        │
└──────────────────────────────┘
```

**内部布局（未发现仙灵）**:
```
┌──────────────────────────────┐
│         🔒                   │
│         ???                  │
│         未发现                │
└──────────────────────────────┘
```

#### 4.4.2 缘分菱形进度指示器

**规格**: 每颗菱形尺寸 12px × 12px，菱形之间间距 2px

**显示规则**:
- 每颗菱形代表 250 缘分
- 最多 12 颗（3000 缘分）
- 已点亮: `ACCENT_GOLD` (#FFD700)
- 未点亮: `TEXT_MUTED` (#808080)

**布局**:
```
◇ ◇ ◇ ◇ ◇ ◇ ◇ ◇ ◇ ◇ ◇ ◇    （共12颗）
↑ 已点亮 (金色)
  未点亮 (灰色)
```

**进度条显示（详情视图）**:
- 菱形行下方显示进度条: `[████████░░░░░░░░░░░░░░░]`
- 进度条高度: 6px
- 进度条背景: `Color(0.16, 0.16, 0.19, 1.0)`
- 进度条填充: `ACCENT_GOLD`
- 进度条圆角: `RADIUS_SM = 4.0`
- 百分比数字: `FONT_SIZE_SM`, `TEXT_SECONDARY`，右侧

#### 4.4.3 仙灵详情视图

**布局**:
```
┌─────────────────────────────────────────────────────────────┐
│  [头像区域]  [仙灵信息区]                                    │
│  120×120px   名称 · 称号                                   │
│              缘分等级 + 进度条 + 进度百分比                   │
│              发现阶段 + 羁绊状态                             │
├─────────────────────────────────────────────────────────────┤
│  缘分能力                                                   │
│  [能力1 - 已解锁] [能力2 - 待解锁] [能力3 - 待解锁]         │
├─────────────────────────────────────────────────────────────┤
│  今日剩余: 供奉 1次 | 互动 1次                               │
│  [参悟]  [供奉]  [求缘/结缘]                                │
└─────────────────────────────────────────────────────────────┘
```

**能力列表样式**:

| 状态 | 背景 | 边框 | 编号 | 名称颜色 | 描述颜色 | 标签 |
|------|------|------|------|----------|----------|------|
| **已解锁** | `PANEL_BG` | 1px `PANEL_BORDER` | ① `ACCENT_GOLD` | `TEXT_PRIMARY` | `TEXT_SECONDARY` | ✓ 已解锁 |
| **未解锁（可预览）** | `PANEL_BG` | 1px `PANEL_BORDER` | ② `TEXT_MUTED` | `TEXT_MUTED` | `TEXT_MUTED` | 🔒 待解锁 (还需X缘分) |

#### 4.4.4 操作按钮样式

| 按钮 | 背景 | 文字颜色 | 边框 | 特殊说明 |
|------|------|----------|------|----------|
| 参悟 | `BUTTON_NORMAL` | `TEXT_PRIMARY` | 无 | 默认操作按钮 |
| 参悟悬停 | `BUTTON_HOVER` | `TEXT_PRIMARY` | 无 | - |
| 供奉 | `BUTTON_NORMAL` | `TEXT_PRIMARY` | 无 | 默认操作按钮 |
| 供奉悬停 | `BUTTON_HOVER` | `TEXT_PRIMARY` | 无 | - |
| 求缘/结缘（可用） | `Color(0.91, 0.11, 0.55, 1.0)` | `TEXT_PRIMARY` | 无 | 粉色背景，区分于其他按钮 |
| 求缘/结缘悬停 | `Color(0.94, 0.38, 0.57, 1.0)` | `TEXT_PRIMARY` | 无 | 更亮的粉色 |
| 求缘/结缘（禁用） | `BUTTON_DISABLED` | `TEXT_MUTED` | 无 | 缘分不足 |

#### 4.4.5 供奉选择界面

**物品卡片样式**:
- 尺寸: 64px × 80px
- 背景: `PANEL_BG`
- 边框: 1px `PANEL_BORDER`
- 悬停: 1px `ACCENT_GOLD`
- 选中: 2px `ACCENT_GOLD`
- 选中物品显示金色边框（与结缘边框一致，简洁风格）

**内部布局**:
```
┌─────────┐
│ [emoji] │
│ [名称]  │
│ ×数量   │
│ +缘分值 │
│  [1]   │
└─────────┘
```

**品质标签颜色**:
| 品质 | 文字颜色 | 字体 |
|------|----------|------|
| 灵犀 | `ACCENT_GOLD` | Bold |
| 合意 | `TEXT_SECONDARY` | Regular |
| 一般 | `TEXT_MUTED` | Regular |

#### 4.5 动画规范

| 动画 | 触发时机 | 时长 | 缓动函数 | 效果描述 |
|------|----------|------|----------|----------|
| 面板打开 | open() | 200ms | `Easing.ease_out_cubic` | 从中心缩放淡入 (scale: 0.9 → 1.0, opacity: 0 → 1) |
| 面板关闭 | close() | 150ms | `Easing.ease_in_cubic` | 缩放淡出 (scale: 1.0 → 0.95, opacity: 1 → 0) |
| 切换视图 | 列表 ↔ 详情 | 200ms | `Easing.ease_in_out` | 横向滑动过渡（与博物馆/成就一致） |
| 仙灵选中 | 选择卡片 | 100ms | `Easing.ease_out` | 边框高亮 + 卡片轻微放大 (scale: 1.0 → 1.02) |
| 供奉成功 | 确认供奉 | 400ms | `Easing.ease_out` | 物品图标从背包飞入仙灵头像位置，缘分数字弹出（+100 从按钮位置向上飘动消失） |
| 缘分增加 | 供奉/互动后 | 300ms | `Easing.ease_out` | 菱形逐个点亮：从当前进度之后的菱形开始，每颗间隔 25ms 依次变为金色 |
| 能力解锁 | 达到能力门槛 | 600ms | `Easing.ease_out` | 金色闪烁（border-color 在 `ACCENT_GOLD` 和透明之间闪烁 3 次，每次 200ms）+ 解锁提示飘窗 |
| 求缘状态切换 | 进入/退出求缘 | 300ms | `Easing.ease_out` | 粉色光晕背景淡入/淡出（opacity 0 → 0.15 或反向） |
| 结缘成功 | 完成结缘 | 600ms | `Easing.ease_out` | 金色边框出现动画（border-color 从 `PANEL_BORDER` → `ACCENT_GOLD`，200ms）+ 金色背景淡入（300ms） |
| 每日互动成功 | 点击互动 | 300ms | `Easing.ease_out` | 按钮区域脉冲一下 + 飘窗显示缘分增加 |

---

## 5. 一致性检查清单

### 5.1 与 Design Tokens 的一致性

| 检查项 | 标准 | Museum | Achievement | HiddenNPC |
|--------|------|--------|-------------|-----------|
| 面板背景色 | `PANEL_BG` | ✓ | ✓ | ✓ |
| 面板边框色 | `PANEL_BORDER` | ✓ | ✓ | 结缘状态替换为 `ACCENT_GOLD` |
| 面板圆角 | `RADIUS_MD = 8.0` | ✓ | ✓ | ✓ |
| 面板内边距 | `SPACE_16 = 16px` | ✓ | ✓ | ✓ |
| 按钮高度 | `BUTTON_HEIGHT = 44px` | ✓ | ✓ | ✓ |
| Tab 按钮样式 | 使用 `BUTTON_*` Token | ✓ | ✓ | ✓ |
| 主要文字颜色 | `TEXT_PRIMARY` | ✓ | ✓ | ✓ |
| 次要文字颜色 | `TEXT_SECONDARY` | ✓ | ✓ | ✓ |
| 辅助文字颜色 | `TEXT_MUTED` | ✓ | ✓ | ✓ |

### 5.2 面板间的一致性

| 检查项 | 标准 | 说明 |
|--------|------|------|
| 面板打开动画 | 200ms, `ease_out_cubic` | 三面板统一 |
| 面板关闭动画 | 150ms, `ease_in_cubic` | 三面板统一 |
| Tab 切换动画 | 150ms, `ease_in_out` | 内容横向滑动，三面板统一 |
| 悬停反馈 | `BUTTON_HOVER` 背景 + 金色边框 | 三面板统一 |
| 键盘焦点 | `BUTTON_PRESSED` 背景 + 2px 金色边框 | 三面板统一 |
| 进度条高度 | 博物馆/成就: 8-10px，仙灵: 6px | 根据功能有差异，但风格一致 |
| 卡片内边距 | `SPACE_12 = 12px` | 三面板卡片样式统一 |

### 5.3 与现有 UI 的一致性

| 检查项 | 现有实现 | 一致性 |
|--------|----------|--------|
| 图标风格 | Unicode emoji（WEATHER_EMOJIS, SEASON_EMOJIS 等） | ✓ 所有面板使用 emoji |
| 关闭按钮 | `BUTTON_*` 样式 | ✓ 三面板统一 |
| 面板结构 | 四层结构（Header/Tab/Content/Footer） | ✓ 与 HUD 和其他面板一致 |
| 飘窗系统 | 通知使用 `NotificationManager` | ✓ 动画反馈使用飘窗 |
| 字体层级 | XL/LG/MD/SM 四级 | ✓ 与 HUD 面板一致 |

### 5.4 无障碍检查

| 检查项 | 标准 | 实现 |
|--------|------|------|
| 最小字号 | 12px | 所有面板最小 `FONT_SIZE_SM = 12px` |
| 颜色对比度 | WCAG AA (4.5:1) | 所有文字颜色与背景符合标准 |
| 色盲安全 | 不使用纯红绿区分 | 三面板都使用 `ACCENT_GOLD` 作为重要状态标识，与红绿搭配 |
| 键盘导航 | Tab / 方向键完整支持 | 与 UX 规范交互规范一致 |
| 手柄支持 | 完整支持 | 与 UX 规范交互规范一致 |

### 5.5 视觉层级检查

| 检查项 | 实现方式 |
|--------|----------|
| 面板标题最醒目 | `FONT_SIZE_XL = 20px` + 面板内最大字号 |
| 重要数据突出 | 使用 `ACCENT_GOLD`，如完美度数字、捐赠计数、缘分数值 |
| 状态区分清晰 | 通过边框颜色、背景色、图标颜色组合区分状态 |
| 操作引导明确 | 求缘/结缘按钮使用粉色与其他按钮形成视觉差异 |
| 禁用状态可识别 | 所有禁用元素使用 `TEXT_MUTED` 和 `BUTTON_DISABLED` |

---

## 6. 附录

### 6.1 仙灵图标分配

| 仙灵 ID | 名称 | Emoji | 缘分阶段颜色 |
|---------|------|-------|-------------|
| `long_ling` | 龙灵 | ✨（或 🌊） | 金色 |
| `tao_yao` | 桃夭 | 🌸 | 金色 |
| `yue_tu` | 月兔 | 🐰（或 🌙） | 金色 |
| `hu_xian` | 狐仙 | 🦊 | 金色 |
| `shan_weng` | 山翁 | ⛰️ | 金色 |
| `gui_nv` | 归女 | 👧（或 🌙） | 金色 |

### 6.2 博物馆分类图标

| 分类 ID | 名称 | Emoji |
|---------|------|-------|
| `ore` | 矿石 | ⛏️ |
| `gem` | 宝石 | 💎 |
| `bar` | 金属锭 | 🔩 |
| `fossil` | 化石 | 🦴 |
| `artifact` | 古物 | 🏺 |
| `spirit` | 仙灵物品 | ✨ |

### 6.3 成就分类图标

| 分类 ID | 名称 | Emoji |
|---------|------|-------|
| `perfection` | 完美度 | ★ |
| 其他分类 | - | ⭐（统一使用星星，与面板标题一致） |

### 6.4 三面板视觉特征总结

| 特征 | MuseumPanel | AchievementPanel | HiddenNPCPanel |
|------|-------------|------------------|----------------|
| **主题关键词** | 收藏、古物、庄重 | 成就、金色、荣耀感 | 神秘、古风、仙气 |
| **强调色** | `ACCENT_GOLD`（金色） | `ACCENT_GOLD`（金色） | `ACCENT_GOLD`（金色）+ `#E91E8C`（粉色） |
| **面板打开动画** | 从左侧滑入 | 从底部滑入 | 从中心缩放淡入 |
| **边框特殊状态** | 可领取里程碑: 金色边框 | 已完成成就: 金色边框 | 结缘仙灵: 金色边框（2px） |
| **图标风格** | 🏛️ 主导，实物 emoji | ⭐ 主导，荣耀感 | ◈ 主导，神秘感 |
| **主要数字显示** | 捐赠计数 12/40 | 完美度 45.2% | 缘分数值 1200/3000 |
| **特殊背景** | 无 | 成就卡片微弱金色光晕 | 求缘粉光晕 / 结缘金光晕 / 传闻蓝光晕 |

### 6.5 设计决策记录

| 决策 | 选项 | 选择 | 理由 |
|------|------|------|------|
| 图标方案 | Unicode emoji vs 定制 SVG | Unicode emoji | 与现有 HUD 一致，便于快速实现 |
| 结缘边框方案 | 金色实线 vs 金色 Glow | 金色实线 | MVP 阶段保持简洁风格，与现有面板一致 |
| 进度条渐变 | 单一金色 vs 渐变 | 单一金色（博物馆）；渐变（成就完美度） | 渐变仅用于完美度进度条增强成就感，其他使用统一金色 |
| 仙灵面板打开动画 | 从中心缩放 vs 从边缘滑入 | 从中心缩放 | 仙灵主题神秘感更强，适合缩放动画 |