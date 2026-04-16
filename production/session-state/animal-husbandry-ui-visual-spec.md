# Animal Husbandry UI - Visual Design Specification

> **Status**: Approved
> **Author**: UI Team
> **Last Updated**: 2026-04-15
> **Phase**: Phase 2 Complete

## Design Philosophy

The Animal Husbandry UI follows the existing cozy farming game aesthetic with:
- **Warm, pastoral feel** — Earth tones, soft shadows, friendly appearance
- **Emoji-based iconography** — Consistent with game style (🐔, 🐄, 🐑)
- **Card-based layouts** — Matches FishPondUI structure
- **Minimal chrome** — Focus on content, not decoration

## Color Palette

### Panel Colors

| Element | Color | Hex | Notes |
|---------|-------|-----|-------|
| Background overlay | Black 50% | `#00000080` | Same as FishPondUI |
| Panel background | Default theme | — | Use Godot theme default |
| Card background | Slight tint | `#2D2D2D` | For animal cards |

### Friendship Level Colors

| Level | Color Name | Hex | Usage |
|-------|------------|-----|-------|
| Stranger | Gray | `#808080` | Default state |
| Pal | Green | `#4CAF50` | Reached first threshold |
| Friend | Blue | `#2196F3` | Mid-tier relationship |
| Best Friend | Gold | `#CC9933` | Max tier, special highlight |

### Status Colors

| Status | Color | Hex | Notes |
|--------|-------|-----|-------|
| Hungry | Orange | `#FF9800` | Needs attention |
| Fed | Green | `#4CAF50` | Already fed |
| Not Pet | Blue | `#2196F3` | Can pet today |
| Pet Done | Gray | `#9E9E9E` | Already pet |
| Immature | Purple | `#9C27B0` | Still growing |
| Product Ready | Yellow | `#FFEB3B` | Has collectible |

### Quality Colors

| Quality | Color | Hex | Source |
|---------|-------|-----|--------|
| Normal | White | `#FFFFFF` | Quality enum |
| Fine | Blue | `#42A5F5` | Quality enum |
| Excellent | Purple | `#AB47BC` | Quality enum |
| Supreme | Gold | `#FFD700` | Quality enum |

## Typography

### Font Sizes

| Element | Size | Weight | Notes |
|---------|------|--------|-------|
| Panel title | 24px | Bold | "畜牧" heading |
| Tab labels | 16px | Normal | Button text |
| Animal name | 18px | Bold | "🐔 白鸡" |
| Friendship level | 14px | Normal | "(Pal 234)" |
| Status text | 12px | Normal | "成年 \| 已喂养" |
| Button text | 14px | Normal | Action buttons |
| Section labels | 14px | Normal | "待收获:" |

### Font Style

- **Chinese text**: Use theme default (usually Noto Sans CJK or similar)
- **Emoji**: Native emoji rendering via Label nodes
- **Numbers**: Arabic numerals for counts and progress

## Spacing System

### Panel Layout

```
┌─────────────────────────────────────────┐
│ Title: margin_top = 16                  │
│ ─────────────────────────────────────── │
│ TabButtons: separation = 8              │
│ ─────────────────────────────────────── │
│ AnimalScroll:                           │
│   - fill container height               │
│   - separation = 8 (between cards)      │
│ ─────────────────────────────────────── │
│ ProductSection: separation = 8          │
│ ─────────────────────────────────────── │
│ ActionButtons: separation = 8            │
│ ─────────────────────────────────────── │
│ BottomButtons: alignment = RIGHT        │
└─────────────────────────────────────────┘
```

### Animal Card Padding

| Padding | Value |
|---------|-------|
| Card padding | 12px |
| Between icon and text | 8px |
| Between text rows | 4px |
| Button spacing | 8px |

## Visual Effects

### Animations (Already Implemented)

| Animation | Duration | Easing | Trigger |
|----------|----------|--------|---------|
| Panel fade in | 250ms | ease_out | show_ui() |
| Panel scale | 250ms | ease_out | show_ui() |
| Panel fade out | 250ms | ease_in | hide_ui() |
| Panel shrink | 250ms | ease_in | hide_ui() |

### Hover States (To Add)

For buttons, apply subtle highlight on hover:
```gdscript
# Example hover effect
button.mouse_entered.connect(func():
    button.modulate = Color(1.1, 1.1, 1.1)
)
button.mouse_exited.connect(func():
    button.modulate = Color(1, 1, 1)
)
```

### Focus Indicators

For gamepad/keyboard navigation, use Godot's built-in focus:
- Default focus border: 2px solid theme accent
- Custom focus: Subtle glow effect

### Friendship Level Visual Treatments

| Level | Visual Treatment |
|-------|------------------|
| Stranger | Default appearance |
| Pal | Green text color |
| Friend | Blue text color |
| Best Friend | Gold text + subtle glow/border |

### Empty State

```
[ 鸡舍 ]

空空如也

去购买小动物吧~
```

Style:
- Large centered icon: "🐔" or building emoji
- Title: Building name in brackets
- Message: "空空如也" centered
- Hint: "去购买小动物吧~" in muted gray
- Optional: "🛒 去商店" quick action button

## Asset Requirements

### Icons (Emoji-based)

All icons use native emoji, no custom assets needed:
- 🐔 Chicken
- 🦆 Duck
- 🐄 Cow
- 🐑 Sheep
- 🐐 Goat
- 🐷 Pig
- 🥚 Egg
- 🥛 Milk
- 🧶 Wool
- 🍄 Truffle
- 🐐 Goat Milk
- 🥚 Duck Egg

### Background Textures

No custom textures required. Using Godot's default panel styling.

## Consistency Guide

### Match FishPondUI

| Element | FishPondUI | AnimalHusbandryUI | Status |
|---------|------------|------------------|--------|
| Panel size | 600x500 | 600x500 | ✅ Match |
| Background | ColorRect 50% | ColorRect 50% | ✅ Match |
| Title format | "🐟 鱼塘" | "畜牧" | ✅ Match |
| Separator style | HSeparator | HSeparator | ✅ Match |
| Button style | Default | Default | ✅ Match |
| Close button | Bottom right | Bottom right | ✅ Match |

### Match HUD

| Element | HUD Style | AnimalHusbandryUI | Status |
|---------|-----------|------------------|--------|
| Font sizes | Varies | 18/16/14/12 | ✅ Match hierarchy |
| Progress bars | Blue fill | Blue fill | ✅ Match |
| Status colors | Icon-based | Text + color | ✅ Consistent |

## Component Specifications

### Tab Buttons

```gdscript
# Specifications
size_flags_horizontal: 3  # Expand to fill
size_flags_vertical: 2    # Center vertically
toggle_mode: true         # One selected at a time
button_group: TabButtonGroup  # Mutual exclusion
disabled: bool            # Gray out unavailable
```

### Animal Card

```gdscript
# Specifications
custom_minimum_size: Vector2(0, 72)
# Layout: HBoxContainer
# - Left: VBoxContainer (animal info)
# - Right: VBoxContainer (action buttons)
```

### Action Buttons

```gdscript
# Specifications
size_flags_horizontal: 3  # Equal width
custom_minimum_size: Vector2(0, 36)
disabled: bool            # Gray when unavailable
```

### Progress Bar (Friendship)

```gdscript
# Specifications
custom_minimum_size: Vector2(200, 12)
max_value: 1.0            # Normalized progress
value: float              # 0.0 - 1.0
show_percentage: true    # Show "XX%"
```

## Implementation Checklist

- [ ] Apply friendship level colors to level labels
- [ ] Apply status colors (Hungry = orange, etc.)
- [ ] Add hover effects to all buttons
- [ ] Add focus indicators for keyboard/gamepad
- [ ] Style empty state consistently
- [ ] Verify spacing matches spec
- [ ] Test at 1280x720 minimum resolution
- [ ] Test at 1920x1080 maximum resolution
- [ ] Verify text scales with system font size
