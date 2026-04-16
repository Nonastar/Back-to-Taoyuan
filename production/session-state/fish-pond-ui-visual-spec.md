# Fish Pond UI - Visual Design Specification

> **Status**: Draft
> **Author**: UI Team
> **Last Updated**: 2026-04-15
> **Phase**: Phase 2 Complete

## Design Philosophy

遵循游戏整体风格 - 温馨牧场风格，与现有 UI 保持一致。

## Color Palette

### Panel Colors

| Element | Color | Hex |
|---------|-------|-----|
| Background overlay | Black 50% | `#00000080` |
| Panel background | Default theme | — |
| Card background | Slight tint | `#1A3A4A` |
| Undiscovered card | Gray tint | `#2A2A2A` |

### Status Colors

| Status | Color | Hex | Usage |
|--------|-------|-----|-------|
| Mature | Green | `#4CAF50` | ✅ 成熟标记 |
| Immature | Gray | `#9E9E9E` | ⏳ 未成熟标记 |
| Selected | Light blue | `#E3F2FD` | 选中卡片背景 |
| Discovered | Green | `#4CAF50` | ✅ 发现状态 |

### Quality Colors

| Quality | Emoji | Hex |
|---------|-------|-----|
| Excellent | ⭐ | Gold |
| Fine | ✨ | Light blue |
| Normal | 🐟 | White |

## Typography

| Element | Size | Weight | Notes |
|---------|------|--------|-------|
| Title | 24px | Bold | "🐟 鱼塘管理" |
| Subtitle | 14px | Normal | "鱼塘可以养殖鱼类..." |
| Fish name | 16px | Bold | "锦鲤" |
| Fish details | 12px | Normal | "第5天 ⏳未成熟" |
| Button text | 14px | Normal | "建造鱼塘" |

## Spacing System

| Element | Value |
|---------|-------|
| Panel padding | 16px |
| Section separation | 12px |
| Card padding | 12px |
| Card spacing | 4px |
| Button spacing | 8px |

## Visual Effects

### Fish Card States

```gdscript
# Default state
modulate = Color(1, 1, 1, 1)

# Selected state
panel.add_theme_stylebox_override("normal", selected_style)
selected_style.bg_color = Color(0.89, 0.95, 0.99)  # #E3F2FD

# Immature fish (dimmed)
modulate = Color(0.7, 0.7, 0.7, 1)

# Mature fish (normal opacity, green badge)
modulate = Color(1, 1, 1, 1)
```

### Add Fish Section Expand

```gdscript
# Expand animation
var tween = create_tween()
tween.tween_property(_add_fish_container, "visible", true, 0.1)
tween.tween_property(_add_fish_container, "modulate:a", 1.0, 0.2)
```

### Hover Effects

```gdscript
func _setup_hover_effect(button: Button) -> void:
    button.mouse_entered.connect(func():
        if not button.disabled:
            button.modulate = Color(1.15, 1.15, 1.15)
    button.mouse_exited.connect(func():
        button.modulate = Color(1, 1, 1)
```

## Consistency with Existing UI

| Element | FishPondUI | AnimalHusbandryUI | FishCompendiumUI |
|---------|------------|-------------------|------------------|
| Panel size | 600x500 | 600x500 | 600x500 |
| Background | ColorRect 50% | ✅ Match | ✅ Match |
| Title style | "🐟 鱼塘管理" | "畜牧" | "🐟 鱼类图鉴" |
| Close button | Bottom right | ✅ Match | ✅ Match |
| Card style | Fish list | Animal cards | ✅ Match |

## Component Specifications

### Build Panel (Unbuilt State)

```gdscript
# Specifications
custom_minimum_size: Vector2(500, 400)
offset: Centered on screen

# Title
text = "🐟 鱼  塘"
horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# Cost items in VBox
spacing = 8

# Build button
custom_minimum_size: Vector2(200, 48)
button_group = null
toggle_mode = false
```

### Fish Card

```gdscript
# Specifications
custom_minimum_size: Vector2(0, 48)
layout_mode = HBoxContainer

# Layout:
# - Checkbox (24x24)
# - Fish emoji (32x32)
# - Name label (flex)
# - Days label (fixed width)
# - Status badge (fixed width)
# - Rate label (fixed width)
```

### Product Badge

```gdscript
# Specifications
layout_mode = HBoxContainer
spacing = 4

# Quality emoji + name + count
```

### Add Fish Button

```gdscript
# Specifications
custom_minimum_size: Vector2(0, 36)
expand_icon = true  # Show ▼ when expanded
```

### Add Fish Item Row

```gdscript
# Specifications
custom_minimum_size: Vector2(0, 40)
layout_mode = HBoxContainer

# Layout:
# - Fish emoji (32x32)
# - Name (flex)
# - Inventory count
# - Maturity days
# - Production rate
# - Add button (fixed width)
```

## Animations

| Animation | Duration | Trigger |
|----------|----------|----------|
| Panel fade in | 250ms | show_ui() |
| Panel scale | 250ms | show_ui() |
| Card hover | 100ms | mouse_enter |
| Expand section | 200ms | button click |
| Collapse section | 150ms | button click |

## Implementation Notes

1. Use same panel structure as AnimalHusbandryUI (600x500)
2. Use same button styling
3. Fish cards use consistent card height (48px)
4. Build panel is centered modal
5. Add fish section expands below main content

## Accessibility

- All text must be readable at default scale
- Minimum touch target: 32x32 pixels
- Focus indicators for keyboard navigation
- Color is not the only indicator (icons accompany status)
