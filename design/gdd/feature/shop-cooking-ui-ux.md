# Shop and Cooking UI UX Design Spec

Phase 1 UX design for the Shop and Cooking panels in the Godot 4.6 farming game "归园田居" (Taoyuan).

This document provides concrete, implementation-ready UX guidance for the team. It covers user flows, ASCII wireframes, interaction patterns, accessibility, data display, and component states.

## 1. User Flow Diagram (text-based)
- Entry
  - User presses S to open Shop panel or C to open Cooking panel.
  - Panel slides/appears with a focusable initial element.
- Shop flow
  - Tab selection: Choose between 杂货铺 (General) or 动物商店 (Animal).
  - Mode selection: Buy or Sell toggle.
  - Item interaction: Move focus to an item card, press Enter or click to select.
  - Quantity: Adjust quantity with +/− or via number input if supported, total price updates live.
  - Action: Press Buy or Sell to initiate transaction.
  - Confirmation: Confirm dialog or inline confirmation; on success, update player money and stock.
  - Exit: Close with X, press ESC, or press S again to toggle off.
- Cooking flow
  - Recipe list: Browse recipes in the left pane; navigate with arrow keys.
  - Recipe detail: Select a recipe to view ingredients, required amounts, and buffs.
  - Cook readiness: If have enough ingredients, Cook button is enabled; otherwise disabled with a hint.
  - Action: Click Cook or press Enter to execute; ingredients are consumed and buffs are applied.
  - Exit: Close with X, press ESC, or press C again to toggle off.
- Exit
  - Use X button, ESC, or re-press S/C to close the active panel.

## 2. Wireframes (ASCII) – Shop Panel
```
+------------------------------------------------------------+
|                    归园田居 Shop Panel                   |
| [X] Close  [ESC]                                         |
+------------------------------------------------------------+
| Tabs: 杂货铺  动物商店                                      |
| Modes: [ Buy ] [ Sell ]                                    |
+------------------------------------------------------------+
| Item Grid (3 columns)                                      |
| ---------------------------------------------------------- |
| |Icon| Item A        |Icon| Item B        |Icon| Item C       |
| Price: 100  Stock:12 | Price: 250 Stock:5  | Price: 60  Stock:30 |
| [选择]              [选择]             [选择]               |
|------------------------------------------------------------|
| [ - ] 1 [ + ]      |  2 items selected                    |
| Total: 100                                                |
+------------------------------------------------------------+
| Info Bar: Selected item(s) summary • Totals • Action hints  |
+------------------------------------------------------------+
| Status Bar: Money: 1000  Panel: Shop                      |
+------------------------------------------------------------+
```

## 3. Wireframes (ASCII) – Cooking Panel
```
+------------------------------------------------------------+
|                    归园田居 Cooking Panel                |
| [X] Close  [ESC]                                         |
+------------------------------------------------------------+
| Header: Cooking Panel                                       |
+------------------------------------------------------------+
| Content Area                                               |
| Left: Recipe List (scrollable)                              |
|   • Recipe 1                                                |
|   • Recipe 2                                                |
|   • Recipe 3                                                |
| Right: Recipe Details                                         |
|   Recipe Name: Golden Stew                                   |
|   Buffs: +XP, +Hunger Resistance                               |
|   Ingredients:                                             |
|     - Carrot 1/2 Have/Need                                       |
|     - Meat 2/3 Have/Need                                         |
|   [Cook Button]                                             |
+------------------------------------------------------------+
| Active Buffs Display                                         |
+------------------------------------------------------------+
```

## 4. Interaction Patterns
- Mouse
  - Hover items to highlight; click to select.
  - Click +/− or input a numeric value to set quantity (where supported).
  - Click Buy, Sell, or Cook to perform the action.
- Keyboard accessibility
  - Navigation: Arrow keys move focus between items; Tab cycles through focusable controls.
  - Actions: Enter selects/fires the primary action; Space toggles controls where appropriate.
  - Shortcuts: S opens/closes Shop; C opens/closes Cooking; Esc closes panels.
- Gamepad (optional)
  - D-Pad/Left Stick navigate; A to select; X to toggle panels; B for back.
- Tab order
  - Tab focuses: Shop Tabs -> Mode Toggles -> Item Grid -> Quantity -> Action Button -> Info/Status Panels -> Close Button.
  - Cooking: Recipe List (focusable) -> Recipe Details (focusable fields) -> Cook Button -> Close.

## 5. Accessibility Requirements
- Color contrast: Ensure text-to-background contrast ratio is at least 4.5:1 (AA).
- Focus indicators: All interactive elements have visible focus rings using distinct color and thickness.
- Keyboard navigation: All interactive controls are reachable; non-visual focus cues accompany mouse hover.
- Colorblind considerations: Use icons, patterns, or labels in addition to color for state signaling (e.g., stock, have/need).
- Font sizing: Base font 16px (1em); adjustable via OS/browser settings; headings scaled appropriately (24px+).
- ARIA: Use roles like region, button, tablist, tab, and aria-labels to convey structure to AT.

## 6. Data Display
- Shop
  - Item name, icon, price, stock, quantity selector, and total price per item.
  - Selected items summary and overall total in the Info Bar.
- Cooking
  - Recipe name, ingredient list with have/need counts, buffs applied, and a Cook button.
  - Active buffs shown in an always-visible strip beneath content.

## 7. Component States
- ItemCard
  - Normal: default card appearance.
  - Hover: subtle elevation, border highlight, tooltip hints.
  - Selected: card highlighted, focused outline, may show quick actions.
  - Disabled: dimmed, non-interactive (e.g., unavailable item in current mode).
  - Error: red border and brief tooltip if stock/availability issues occur.
- Tab
  - Normal, Focused, Active (selected).
- QuantityControls
  - Normal, Hover, Disabled (unable to change due to cap/stock).
- ActionButtons (Buy/Sell/Cook)
  - Normal: enabled; Hover to show ripple.
  - Selected: visual emphasis on current mode.
  - Disabled: grayed out when action cannot proceed.
- Info/Status Bars
  - Normal: standard display.
  - Error: red alert banner if a transaction fails.

## 8. Assumptions and Constraints
- The panels are access-controlled via keyboard shortcuts S and C.
- Panels should be accessible with a single Escape to exit, without requiring mouse interaction.
- All data is mockable/hookable to the Godot UI layer for production wiring.

---
This document provides a concrete, implementation-ready UX spec for Phase 1. It intentionally focuses on practical wireframes and interactions to accelerate integration with Godot 4.6 UI code.
