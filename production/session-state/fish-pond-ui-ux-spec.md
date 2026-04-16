# Fish Pond UI - UX Specification

> **Status**: Draft
> **Author**: UI Team
> **Last Updated**: 2026-04-15
> **Sprint**: Sprint 5 - S5-T5
> **Phase**: Phase 1 Complete

## Overview

鱼塘管理界面是鱼塘系统的玩家交互界面，包含建造、放入/取出鱼类、收获产物等功能。

## User Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      鱼塘管理界面                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [未建造状态]                                          │   │
│  │                                                      │   │
│  │              🐟 鱼  塘                                │   │
│  │                                                      │   │
│  │         建造费用: 💰5000  🪵100  🎋50                │   │
│  │                                                      │   │
│  │              [ 🏗️ 建造鱼塘 ]                          │   │
│  │                                                      │   │
│  │         (点击返回野外 / ESC关闭)                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [已建造状态]                                          │   │
│  │                                                      │   │
│  │ 🐟 鱼塘管理        🐟 3/5                            │   │
│  │─────────────────────────────────────────────────────│   │
│  │                                                      │   │
│  │ 当前鱼类:                                             │   │
│  │ ┌─────────────────────────────────────────────────┐ │   │
│  │ │ 🐟 蓝鳃鱼  第3天 ✅成熟 ★40%  [选中]           │ │   │
│  │ ├─────────────────────────────────────────────────┤ │   │
│  │ │ 🐟 锦鲤    第5天 ⏳未成熟 ★25%                 │ │   │
│  │ ├─────────────────────────────────────────────────┤ │   │
│  │ │ 🐟 沼泽泥鳅 第2天 ✅成熟 ★50%  [选中]          │ │   │
│  │ └─────────────────────────────────────────────────┘ │   │
│  │                                                      │   │
│  │ 待收获产物: ⭐蓝鳃鱼x1  ✨锦鲤x1                    │   │
│  │                                                      │   │
│  │ [ 🗑️ 取出选中鱼 ] [ 📦 收获产物 ]                   │   │
│  │─────────────────────────────────────────────────────│   │
│  │                                                      │   │
│  │ [ + 放入鱼类 ▼展开选择列表 ]                         │   │
│  │ ┌─────────────────────────────────────────────────┐ │   │
│  │ │ 🐟 草鱼 (背包x3)  4天成熟 ★30%                  │ │   │
│  │ │ 🐟 鲈鱼 (背包x2)  5天成熟 ★30%                  │ │   │
│  │ │ 🐟 金鱼 (背包x1)  7天成熟 ★20%                  │ │   │
│  │ └─────────────────────────────────────────────────┘ │   │
│  │─────────────────────────────────────────────────────│   │
│  │                                    [ ✕ 关闭 ]         │   │
└─────────────────────────────────────────────────────────────┘
```

### Entry Points

1. **鱼塘场景 InfoPanel** → "鱼塘管理" 按钮
2. **快捷键 G** → 打开/关闭鱼塘管理

### Exit Points

1. **关闭按钮**: 点击关闭
2. **ESC 键**: 按下 Escape
3. **背景点击**: 点击遮罩关闭（未实现）

## Design Decisions

| 决策点 | 选择 | 原因 |
|--------|------|------|
| 放入鱼类对话框 | A. 物品选择列表 | 与 AnimalHusbandryUI 模式一致，减少界面层级 |
| 鱼类移除 | D. 选中+底部按钮 | 与 AnimalHusbandryUI 模式一致，最安全 |
| 标签页设计 | A. 单页设计 | 当前需求简单，保持界面简洁 |
| 建造界面 | B. 单独面板 | 完全不同的面板，只显示建造费用和按钮 |

## Wireframe Descriptions

### Unbuilt State Panel (500x400)

```
┌─────────────────────────────────────────────────────────────┐
│                        🐟 鱼  塘                             │
│                                                             │
│              鱼塘可以养殖鱼类，每天收获产物                    │
│                                                             │
│    ┌───────────────────────────────────────────────────┐   │
│    │  🪵 木材 x100                                      │   │
│    │  🎋 竹子 x50                                       │   │
│    │  💰 金币 x5000                                     │   │
│    └───────────────────────────────────────────────────┘   │
│                                                             │
│                   [ 🏗️ 建造鱼塘 ]                           │
│                                                             │
│                   (背包材料不足时按钮禁用)                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Main Panel (600x500)

```
┌─────────────────────────────────────────────────────────────┐
│ 🐟 鱼塘管理                           🐟 3/5              │
│─────────────────────────────────────────────────────────────│
│                                                             │
│ 当前鱼类:                                                    │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ [ ] 🐟 蓝鳃鱼      第3天  ✅成熟  产出率 40%           │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ [✓] 🐟 锦鲤        第5天  ⏳未成熟  产出率 25%         │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ [ ] 🐟 沼泽泥鳅    第2天  ✅成熟  产出率 50%           │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ 待收获产物: ⭐蓝鳃鱼x1  ✨锦鲤x1                           │
│                                                             │
│ [ 🗑️ 取出选中 ]  [ 📦 收获产物 ]                           │
│─────────────────────────────────────────────────────────────│
│ [ + 放入鱼类 ]                                              │
│ [ 展开的选择列表 - 当前隐藏 ]                                │
│┌─────────────────────────────────────────────────────────┐ │
││ 🐟 草鱼      背包 x3   4天成熟  产出率 30%                │ │
││ 🐟 鲈鱼      背包 x2   5天成熟  产出率 30%                │ │
││ 🐟 金鱼      背包 x1   7天成熟  产出率 20%                │ │
│└─────────────────────────────────────────────────────────┘ │
│─────────────────────────────────────────────────────────────│
│                                          [ ✕ 关闭 ]         │
└─────────────────────────────────────────────────────────────┘
```

## Data Display

### From FishPondSystem

| Data | Format | Display |
|------|--------|---------|
| fish_count | Int | "🐟 3/5" header |
| capacity | Int | "🐟 3/5" header |
| fish_list | Array | Scrollable card list |
| pending_products | Array | Product badges |

### Fish Card Data

| Data | Format | Display |
|------|--------|---------|
| fish_id | String | Internal ID |
| name | String | Fish name with emoji |
| days_in_pond | Int | "第X天" |
| is_mature | Bool | ✅成熟 / ⏳未成熟 |
| production_rate | Float | "产出率 X%" |

### Product Badge

| Data | Format | Display |
|------|--------|---------|
| product_id | String | Fish product name |
| quality | String | ⭐(excellent) / ✨(fine) / 🐟(normal) |
| quantity | Int | "x3" |

## Components

### Build Panel (Unbuilt State)

```
┌─────────────────────────────────────────────────────────────┐
│ Title: "🐟 鱼  塘"                                          │
│ Subtitle: "鱼塘可以养殖鱼类，每天收获产物"                        │
│                                                             │
│ Cost List:                                                  │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🪵 木材 x100                                            │ │
│ │ 🎋 竹子 x50                                             │ │
│ │ 💰 金币 x5000                                           │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ Build Button: "🏗️ 建造鱼塘"                                 │
│                                                             │
│ Hint: "(背包材料不足时按钮禁用)"                               │
└─────────────────────────────────────────────────────────────┘
```

### Fish Card

```
┌─────────────────────────────────────────────────────────────┐
│ [✓] 🐟 锦鲤        第5天  ⏳未成熟  产出率 25%              │
└─────────────────────────────────────────────────────────────┘
```

States:
- **Default**: No highlight
- **Selected**: Checkbox checked, subtle background color
- **Mature**: Show "✅" badge
- **Immature**: Show "⏳" badge, slightly dimmed

### Product Badge

```
┌─────────────┐
│ ⭐蓝鳃鱼x1  │
└─────────────┘
```

Quality icons:
- **excellent**: ⭐
- **fine**: ✨
- **normal**: 🐟

### Add Fish Section

```
┌─────────────────────────────────────────────────────────────┐
│ [ + 放入鱼类 ]                                              │
│ ▼ (expanded)                                                │
├─────────────────────────────────────────────────────────────┤
│ 🐟 草鱼      背包 x3   4天成熟  产出率 30%  [放入]         │
│ 🐟 鲈鱼      背包 x2   5天成熟  产出率 30%  [放入]         │
│ 🐟 金鱼      背包 x1   7天成熟  产出率 20%  [禁用-已满]    │
└─────────────────────────────────────────────────────────────┘
```

## Interaction Patterns

### Mouse/Keyboard

| Action | Mouse | Keyboard |
|--------|-------|----------|
| Toggle panel | Click button | G key |
| Select fish | Click card | Space/Enter |
| Remove selected | Click button | R key |
| Collect products | Click button | C key |
| Add fish | Click expand | E key |
| Add specific fish | Click row | Enter |
| Close panel | Click button | Escape |

### Gamepad

| Action | Button |
|--------|--------|
| Navigate | D-pad |
| Select | A / Cross |
| Remove | X button |
| Collect | Y button |
| Close | B / Circle |

## Accessibility

### Color Coding

| Element | Color | Hex |
|---------|-------|-----|
| Mature badge | Green | #4CAF50 |
| Immature badge | Gray | #9E9E9E |
| Selected row | Light blue | #E3F2FD |
| Button normal | Theme default | — |
| Button hover | Lightened | +10% brightness |

### Text Scaling

- All text must scale with UI settings
- Minimum touch target: 32x32 pixels
- Focus indicators for keyboard navigation

## System Integration

### FishPondSystem API Usage

```gdscript
## Query methods (read-only)
FishPondSystem.is_built()
FishPondSystem.get_fish_count()
FishPondSystem.get_capacity()
FishPondSystem.get_fish_list()
FishPondSystem.get_pending_products()
FishPondSystem.get_pondable_fish_list()

## Action methods (emit signals)
FishPondSystem.build_pond()
FishPondSystem.add_fish(fish_id)
FishPondSystem.remove_fish(index)
FishPondSystem.collect_products()

## Signal connections
FishPondSystem.pond_state_changed.connect(_on_pond_state_changed)
FishPondSystem.product_collected.connect(_on_product_collected)
```

### Player Inventory Integration

```gdscript
## Check if player has pondable fish in inventory
InventorySystem.get_item_count(fish_id) > 0

## Add/remove fish from inventory (handled by FishPondSystem)
```

## Open Questions

1. Should there be a confirmation dialog when removing fish?
2. Should mature fish have a visual indicator (glow, animation)?
3. Should the product collection show individual item badges or a total count?

## Next Steps

1. ✅ UX Design Complete
2. ⏳ Visual Design
3. ⏳ Implement FishPondUI enhancements
4. ⏳ Test and polish
