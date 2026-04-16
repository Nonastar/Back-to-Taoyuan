# Animal Husbandry UI - UX Specification

> **Status**: Draft
> **Author**: UI Team
> **Last Updated**: 2026-04-15
> **Phase**: Phase 1 Complete

## Overview

This document defines the UX requirements for the Animal Husbandry UI in 归园田居. The UI provides players with a complete interface for managing their farm animals, including viewing animal status, feeding, petting, and collecting products.

## Current Implementation Analysis

### What's Implemented ✅

| Component | Status | Notes |
|-----------|--------|-------|
| CanvasLayer structure | ✅ | 600x500 panel, centered |
| Coop/Barn tabs | ✅ | ButtonGroup-based tab switching |
| Animal cards | ✅ | Scrollable list with dynamic creation |
| Friendship display | ✅ | Progress bar with level-based colors |
| Per-animal actions | ✅ | Feed/Pet buttons per animal |
| Bulk actions | ✅ | Feed All, Pet All, Collect buttons |
| Product list | ✅ | Shows pending products with quality colors |
| Gamepad navigation | ✅ | D-pad/arrow key focus management |
| Show/hide animation | ✅ | Scale + alpha tween |
| ESC to close | ✅ | `ui_cancel` action |
| Notification integration | ✅ | NotificationManager integration |

### What's Missing ❌

| Component | Priority | Notes |
|-----------|----------|-------|
| Building purchase UI | P0 | No way to buy/build without shop |
| Animal purchase from UI | P0 | Cannot buy animals directly |
| Feed cost display | P1 | Hay cost not shown before action |
| Capacity indicator | P1 | No "X/Y animals" display |
| Maturity status highlight | P1 | Immature animals not visually distinct |
| Building upgrade UI | P2 | Upgrade flow not implemented |
| Sick/unhealthy indicators | P2 | Health system in design, not MVP |
| Shearing cooldown display | P2 | Wool cooldown not shown |

## User Flow Map

```
[World Interaction] ──click building──> [Animal Husbandry UI]
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    │                         │                         │
              [Coop Tab]                 [Barn Tab]                [Close/Esc]
                    │                         │
                    ▼                         ▼
            [Animal List]              [Animal List]
                    │
    ┌───────────────┼───────────────┐
    │               │               │
[Feed All]    [Pet All]     [Collect]
    │               │               │
    ▼               ▼               ▼
[Per-animal feedback via notifications]
```

### Entry Points

1. **Direct click**: Player clicks on coop/barn sprite in world
2. **Keyboard shortcut**: [B] key opens Animal Husbandry UI (if implemented)

### Exit Points

1. **Close button**: Click "关闭" button
2. **ESC key**: Press Escape
3. **Background click**: Click outside panel (optional, not implemented)
4. **World interaction**: Clicking elsewhere returns to game

## Wireframe Descriptions

### Main Panel Layout (600x500)

```
┌─────────────────────────────────────────────────────────────┐
│                          畜牧                                │
│  ─────────────────────────────────────────────────────────  │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │    🐔 鸡舍       │  │    🐄 谷仓       │                   │
│  └─────────────────┘  └─────────────────┘                   │
│  ─────────────────────────────────────────────────────────  │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Animal Scroll Area (expandable)                        │ │
│  │                                                         │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ 🐔 白鸡  Pal (234)                    [喂养] [抚摸]   │ │ │
│  │ │ ████████████░░░░░░░░░░░  50%                       │ │ │
│  │ │ 成年 | 已喂养 | 已抚摸                              │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  │                                                         │ │
│  │ ┌─────────────────────────────────────────────────────┐ │ │
│  │ │ 🐔 棕鸡  Friend (456)                [已喂养] [抚摸] │ │ │
│  │ │ ████████████████████████░░░░  80%                  │ │ │
│  │ │ 成年 | 饥饿 | 已抚摸                                │ │ │
│  │ └─────────────────────────────────────────────────────┘ │ │
│  │                                                         │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ─────────────────────────────────────────────────────────  │
│  待收获:  🥚 x2 (Fine)  🥛 x1 (Normal)                      │
│  ─────────────────────────────────────────────────────────  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │  喂养全部    │  │  抚摸全部   │  │   收获     │           │
│  └────────────┘  └────────────┘  └────────────┘           │
│  ─────────────────────────────────────────────────────────  │
│                                             [关闭]          │
└─────────────────────────────────────────────────────────────┘
```

### Empty State (No Animals)

```
┌─────────────────────────────────────────────────────────────┐
│                          畜牧                                │
│  ─────────────────────────────────────────────────────────  │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │    🐔 鸡舍       │  │    🐄 谷仓       │                   │
│  └─────────────────┘  └─────────────────┘                   │
│  ─────────────────────────────────────────────────────────  │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │                    [ 鸡舍 ]                              │ │
│  │                                                         │ │
│  │                   空空如也                               │ │
│  │                                                         │ │
│  │              去购买小动物吧~                             │ │
│  │                                                         │ │
│  │           ┌────────────────────┐                        │ │
│  │           │   🛒 去商店购买    │  ← NEW: Quick action    │ │
│  │           └────────────────────┘                        │ │
│  │                                                         │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ─────────────────────────────────────────────────────────  │
│  待收获: (无)                                               │
│  ─────────────────────────────────────────────────────────  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │  喂养全部    │  │  抚摸全部   │  │   收获     │           │
│  └────────────┘  └────────────┘  └────────────┘           │
│  ─────────────────────────────────────────────────────────  │
│                                             [关闭]          │
└─────────────────────────────────────────────────────────────┘
```

### Animal Card States

| State | Visual Treatment |
|-------|------------------|
| **Immature** | Dimmed opacity (0.7), "幼年" badge, production disabled |
| **Hungry** | Status shows "饥饿" in orange text, Feed button highlighted |
| **Not Pet Today** | Status shows "未抚摸" in blue text, Pet button highlighted |
| **Best Friend** | Golden glow/border, special "⭐" indicator |
| **Product Ready** | Animal card has subtle "!" indicator |

## Interaction Patterns

### Mouse/Keyboard Navigation

| Action | Mouse | Keyboard |
|--------|-------|----------|
| Select tab | Click | Tab to tab buttons, Enter to select |
| Select animal card | Click any button | Arrow keys to navigate, Enter to activate |
| Feed single | Click "喂养" | Navigate to button, Enter |
| Pet single | Click "抚摸" | Navigate to button, Enter |
| Feed all | Click "喂养全部" | Navigate, Enter |
| Pet all | Click "抚摸全部" | Navigate, Enter |
| Collect | Click "收获" | Navigate, Enter |
| Close | Click "关闭" | Escape |

### Gamepad Navigation

| Action | Button |
|--------|--------|
| Navigate | D-pad / Left stick |
| Select/Activate | A / Cross |
| Back/Close | B / Circle |
| Tab switching | Left/Right on D-pad when on tabs |

### Focus Order

1. Tab buttons (Coop → Barn)
2. Animal card buttons (left to right: Feed → Pet)
3. Action buttons (Feed All → Pet All → Collect)
4. Close button

## Accessibility Requirements

### Text Scaling
- All labels use theme defaults that scale with system settings
- Minimum touch target: 32x32 pixels
- Progress bars show percentage text

### Color Contrast
| Element | Current Color | Contrast Ratio | Required |
|---------|--------------|----------------|----------|
| Background | #000000 (50% alpha) | N/A | OK (overlay) |
| Panel | Default theme | >4.5:1 | Verify |
| Friendship levels | See below | >4.5:1 | Verify |

**Friendship Level Colors:**
- Stranger: Gray (#808080)
- Pal: Green (#4CAF50)
- Friend: Blue (#2196F3)
- Best Friend: Gold (#CC9933)

### Screen Reader Considerations
- All buttons have text labels
- Animal cards should have semantic structure (name, level, progress)
- Consider adding `accessibility_description` for complex cards

## Data Display Requirements

### From AnimalHusbandrySystem

| Data | Format | Display |
|------|--------|---------|
| Animal name | String | Label: "🐔 白鸡" |
| Friendship level | Enum | Label with color: "Pal (234)" |
| Friendship progress | Float 0-1 | Progress bar + percentage |
| Fed status | Bool | "已喂养" / "饥饿" |
| Pet status | Bool | "已抚摸" / "未抚摸" |
| Maturity | Bool | "成年" / "幼年" |
| Product ready | Bool | Visual indicator |
| Capacity | Int | "X/Y" badge on tab (future) |

### From Pending Products

| Data | Format | Display |
|------|--------|---------|
| Product ID | String | Emoji/icon |
| Quantity | Int | "x3" |
| Quality | Enum | Color + label |

## Keyboard Shortcuts (Recommended)

| Key | Action |
|-----|--------|
| E | Open/close animal husbandry UI |
| F | Feed selected animal (when focused) |
| P | Pet selected animal (when focused) |
| C | Collect all products |
| 1 | Switch to Coop tab |
| 2 | Switch to Barn tab |
| Esc | Close UI |

## Recommendations for Phase 2

1. **Add capacity indicator** to tab buttons: "鸡舍 (3/4)"
2. **Add quick shop link** in empty state
3. **Improve maturity visibility**: Dim immature animals, show growth progress
4. **Add product preview**: Show estimated quality before collecting
5. **Consider animal detail popup**: Click animal name for full details
6. **Add feed cost warning**: "需要: 干草 x1" before feed action

## Open Questions for UX Team

1. Should we add a confirmation dialog for bulk actions?
2. Should "Feed All" auto-collect products first?
3. Do we need animal purchase UI in the panel, or keep shop separate?
4. What animations should trigger on successful actions?
5. Should we support multi-select for feeding/peting specific animals?
