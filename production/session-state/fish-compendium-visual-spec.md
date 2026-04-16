# Fish Compendium UI - Visual Design Specification

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

### Rarity Colors

| Rarity | Name | Hex | Usage |
|--------|------|-----|-------|
| 0.7+ | 普通 Common | `#FFFFFF` | Normal fish |
| 0.3-0.7 | 优质 Fine | `#42A5F5` | Good fish |
| 0.1-0.3 | 精品 Rare | `#AB47BC` | Rare fish |
| <0.1 | 传说 Legendary | `#FFD700` | Legendary fish |

### Status Colors

| Status | Color | Hex |
|--------|-------|-----|
| Discovered | Green | `#4CAF50` |
| Not Discovered | Gray | `#808080` |
| Progress bar fill | Blue | `#2196F3` |
| Progress bar BG | Dark | `#1A2A3A` |

## Typography

| Element | Size | Weight | Notes |
|---------|------|--------|-------|
| Title | 24px | Bold | "🐟 鱼类图鉴" |
| Progress text | 14px | Normal | "已钓: 8/20" |
| Tab labels | 14px | Normal | "全部" 等 |
| Fish name | 16px | Bold | "锦鲤" |
| Fish details | 12px | Normal | "已钓 x2 ★★★☆☆" |
| Price | 12px | Normal | "💰 100g" |

## Spacing System

| Element | Value |
|---------|-------|
| Panel padding | 16px |
| Section separation | 8px |
| Card padding | 12px |
| Card spacing | 4px |
| Tab button spacing | 4px |

## Visual Effects

### Legend fish Glow

```gdscript
# Legendary fish have gold glow effect
if rarity < 0.1:  # Legendary
    var style = StyleBoxFlat.new()
    style.set_bg_color(Color(0.8, 0.6, 0.2, 0.2))
    style.set_border_color(Color(1, 0.84, 0, 0.8))
    style.set_border_width_all(2)
```

### Undiscovered Card

```gdscript
# Undiscovered fish at 50% opacity
if not is_discovered:
    card.modulate = Color(0.5, 0.5, 0.5, 1)
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

## Component Specifications

### Fish Card

```gdscript
# Specifications
custom_minimum_size: Vector2(0, 48)
# Layout: HBoxContainer
# - Left: Fish emoji (32x32)
# - Center: VBoxContainer (name, details)
# - Right: Price + difficulty stars
```

### Filter Tabs

```gdscript
# Specifications
size_flags_horizontal: 0  # Shrink to fit
custom_minimum_size: Vector2(60, 32)
toggle_mode: true
button_group: FishFilterGroup  # Mutual exclusion
```

### Progress Bar

```gdscript
# Specifications
custom_minimum_size: Vector2(0, 20)
max_value: 100.0
value: float  # 0-100 percentage
show_percentage: true
```

## Fish Emoji Mapping

```gdscript
const FISH_EMOJI: Dictionary = {
    "bluegill": "🐟",
    "carp": "🐟",
    "frog": "🐸",
    "koi": "🐠",
    "catfish": "🐟",
    "trout": "🐟",
    "bass": "🐟",
    "snow_fish": "🐟",
    "golden_fish": "🐠",
    "eel": "🐍",
    "salmon": "🐟",
    "mountain_trout": "🐟",
    "ice_fish": "🐟",
    "magic_fish": "✨🐟",
    "swamp_creature": "🦎",
    "tuna": "🐟",
    "swordfish": "⚔️🐟",
    "shark": "🦈",
    "legendary_fish": "🐉",
    "mythical_fish": "🐲",
    "treasure_fish": "💎🐟"
}

const DEFAULT_EMOJI: String = "🐟"
```

## Consistency with Existing UI

| Element | FishPondUI | AnimalHusbandryUI | FishCompendiumUI |
|---------|------------|-------------------|------------------|
| Panel size | 600x400 | 600x500 | 600x500 |
| Background | ColorRect 50% | ColorRect 50% | ✅ Match |
| Title style | "🐟 鱼塘" | "畜牧" | "🐟 鱼类图鉴" |
| Close button | Bottom right | Bottom right | ✅ Match |
| Card style | Fish list | Animal cards | ✅ Match |

## Animations

| Animation | Duration | Trigger |
|----------|----------|---------|
| Panel fade in | 250ms | show_ui() |
| Panel scale | 250ms | show_ui() |
| Card hover | 100ms | mouse_enter |
| Progress fill | 500ms | panel_open |
| Legendary glow | Loop | Always |

## Implementation Notes

1. Use same panel structure as AnimalHusbandryUI (600x500)
2. Use same button styling
3. Fish cards use consistent card height (48px)
4. Progress bar at top for visibility
5. Filter tabs as toggle buttons
