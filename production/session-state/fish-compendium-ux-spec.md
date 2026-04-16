# Fish Compendium UI - UX Specification

> **Status**: Draft
> **Author**: UI Team
> **Last Updated**: 2026-04-15
> **Sprint**: Sprint 5 - S5-T4
> **Phase**: Phase 1 Complete

## Overview

鱼类图鉴是钓鱼系统的收集界面，记录玩家钓过的所有鱼类。图鉴包含发现状态、捕获数量、难度和稀有度信息。

## Data Sources

### From FishingSystem

```gdscript
const FISH_DATA: Dictionary = {
    "bluegill": {"name": "蓝鳃鱼", "rarity": 0.7, "exp": 5, "price": 10, "difficulty": 1},
    "carp": {"name": "鲤鱼", "rarity": 0.5, "exp": 10, "price": 25, "difficulty": 2},
    # ... 20+ 种鱼
}

const FISH_BY_LOCATION: Dictionary = {
    "fishpond": ["bluegill", "carp", "catfish"],
    "river": ["trout", "salmon", "bass"],
    "forest_pond": ["koi", "golden_fish", "frog"],
    "mountain_lake": ["snow_fish", "ice_fish", "mountain_trout"],
    "ocean": ["tuna", "swordfish", "shark"],
    "witch_swamp": ["eel", "magic_fish", "swamp_creature"],
    "secret_pond": ["legendary_fish", "mythical_fish", "treasure_fish"]
}
```

### From EventBus

```gdscript
EventBus.fish_caught.emit(fish_id, quantity, quality)
```

## User Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     鱼类图鉴                                 │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 进度: 已钓 8/20 种鱼                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  [全部] [池塘] [河流] [湖泊] [海洋] [沼泽] [秘密]          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 🐟 蓝鳃鱼        ✅ 已钓 x12        ★☆☆☆☆           │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ 🐟 鲤鱼          ✅ 已钓 x5         ★★☆☆☆           │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ ❓ ???            ❌ 未发现                          │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ 🐟 锦鲤          ✅ 已钓 x2         ★★★☆☆           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│                              [关闭]                          │
└─────────────────────────────────────────────────────────────┘
```

### Entry Points

1. **Fishing Mini Game** → 图鉴按钮
2. **Bottom Navigation** → 钓鱼分类 → 图鉴按钮
3. **Menu** → 图鉴 → 鱼类

### Exit Points

1. **关闭按钮**: 点击关闭
2. **ESC 键**: 按下 Escape
3. **背景点击**: 点击遮罩关闭

## Wireframe Descriptions

### Main Panel (600x500)

```
┌─────────────────────────────────────────────────────────────┐
│                        🐟 鱼类图鉴                            │
│  ─────────────────────────────────────────────────────────  │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📊 已钓: 8/20 种鱼 (40%)                             │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐              │
│  │全部 │池塘 │河流 │湖泊 │海洋 │沼泽 │秘密 │              │
│  └─────┴─────┴─────┴─────┴─────┴─────┴─────┘              │
│  ─────────────────────────────────────────────────────────  │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Fish List (ScrollContainer, flex height)               │ │
│  │                                                         │ │
│  │ ┌─────────────────────────────────────────────────┐   │ │
│  │ │ 🐟 蓝鳃鱼  已钓x12  ★☆☆☆☆  10g  简单     │   │ │
│  │ └─────────────────────────────────────────────────┘   │ │
│  │                                                         │ │
│  │ ┌─────────────────────────────────────────────────┐   │ │
│  │ │ 🐟 鲤鱼    已钓x5   ★★☆☆☆  25g  简单     │   │ │
│  │ └─────────────────────────────────────────────────┘   │ │
│  │                                                         │ │
│  │ ┌─────────────────────────────────────────────────┐   │ │
│  │ │ ❓ ???      未发现    -      -        -        │   │ │
│  │ └─────────────────────────────────────────────────┘   │ │
│  │                                                         │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ─────────────────────────────────────────────────────────  │
│                                              [关闭]          │
└─────────────────────────────────────────────────────────────┘
```

### Fish Card States

| State | Visual Treatment | Card Content |
|-------|-----------------|--------------|
| **Caught** | Full opacity, ✅ icon | 名称, 捕获次数, 难度星级, 价格 |
| **Not Caught** | 50% opacity, ❓ icon | "???" 名称, "未发现" |
| **Selected** | Highlighted border | 显示详细信息面板 |
| **Legendary** | Gold glow | 特殊边框和图标 |

## Interaction Patterns

### Mouse/Keyboard

| Action | Mouse | Keyboard |
|--------|-------|----------|
| Open | Click button | C or Tab to focus |
| Select tab | Click tab | Left/Right arrows |
| Select fish | Click card | Up/Down arrows |
| View details | Click card | Enter |
| Close | Click close | Escape |

### Gamepad

| Action | Button |
|--------|--------|
| Navigate | D-pad |
| Select | A / Cross |
| Back | B / Circle |
| Filter | LB/RB |
| Close | Start |

## Accessibility Requirements

### Color Coding

| Rarity | Color | Hex |
|--------|-------|-----|
| 普通 (Common) | White | #FFFFFF |
| 优质 (Fine) | Blue | #42A5F5 |
| 精品 (Rare) | Purple | #AB47BC |
| 传说 (Legendary) | Gold | #FFD700 |

### Difficulty Stars

| Difficulty | Stars |
|------------|-------|
| 1-2 | ★☆☆☆☆ |
| 3-4 | ★★☆☆☆ |
| 5-6 | ★★★☆☆ |
| 7-8 | ★★★★☆ |
| 9-10 | ★★★★★ |

## Data Display

### From FishCompendiumSystem (NEW)

| Data | Format | Display |
|------|--------|--------|
| is_discovered | Bool | ✅/❓ icon |
| catch_count | Int | "已钓 x12" |
| best_quality | Enum | Badge/icon |

### From FISH_DATA

| Data | Format | Display |
|------|--------|--------|
| name | String | Fish name label |
| emoji | String | Map to emoji |
| difficulty | Int 1-10 | ★ stars |
| rarity | Float | Color coding |
| price | Int | Gold icon + number |

## Fish Emoji Mapping

| Fish ID | Emoji |
|---------|-------|
| bluegill | 🐟 |
| carp | 🐟 |
| koi | 🐠 |
| catfish | 🐟 |
| trout | 🐟 |
| golden_fish | 🐠 |
| legendary_fish | 🐉 |
| mythical_fish | 🐲 |
| Default | 🐟 |

## Components

### Filter Tabs

- **全部** (All): 显示所有鱼类
- **池塘** (Fishpond): fishpond 地点鱼类
- **河流** (River): river 地点鱼类
- **湖泊** (Mountain Lake): mountain_lake 地点鱼类
- **海洋** (Ocean): ocean 地点鱼类
- **沼泽** (Witch Swamp): witch_swamp 地点鱼类
- **秘密** (Secret): secret_pond 地点鱼类

### Fish Card

```
┌─────────────────────────────────────────────────┐
│ 🐠 锦鲤     已钓 x2   ★★★☆☆   💰 100g         │
└─────────────────────────────────────────────────┘
```

### Undiscovered Card

```
┌─────────────────────────────────────────────────┐
│ ❓ ???       未发现                             │
└─────────────────────────────────────────────────┘
```

### Progress Bar

```
📊 已钓: 8/20 种鱼 (40%)
```

## System Integration

### FishCompendiumSystem API (To Implement)

```gdscript
class_name FishCompendiumSystem extends Node

## 追踪捕获
func record_catch(fish_id: String, quantity: int, quality: int) -> void

## 查询
func is_discovered(fish_id: String) -> bool
func get_catch_count(fish_id: String) -> int
func get_total_discovered() -> int
func get_total_fish_count() -> int
func get_discovered_list() -> Array
func get_undiscovered_list() -> Array
func get_fish_by_location(location: String) -> Array

## 进度
func get_progress() -> float  # 0.0 - 1.0
func get_progress_text() -> String  # "8/20 (40%)"

## 存档
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

## Open Questions

1. Should undiscovered fish show hints (location/season)?
2. Should catch count show in detail view?
3. Should legendary fish have special animation?
4. How to handle fish caught before compendium was added?

## Next Steps

1. ✅ UX Design Complete
2. ⏳ Visual Design
3. ⏳ Implement FishCompendiumSystem
4. ⏳ Implement FishCompendiumUI
5. ⏳ Register to navigation
6. ⏳ Test and polish
