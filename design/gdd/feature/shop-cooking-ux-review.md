Shop & Cooking UX Verification - Phase 4 Review

Overview
- This review validates the Shop and Cooking UI panels against the UX spec located at design/gdd/feature/shop-cooking-ui-ux.md. It focuses on user flows, interaction patterns, component states, accessibility, and a manual Godot test plan. The code examined includes:
  - src/scripts/ui/shop_panel.gd
  - src/scripts/ui/cooking_panel.gd

Executive verdict
- Overall, the implemented panels provide solid keyboard navigation, clear close actions, and functional item/recipe selection flows. There are a few gaps around reopening focus behavior and a minor inconsistency with re-press close semantics that should be wired to the HUD input context. Details below.

- Pass / Fail by UX dimension:
- User Flows: Partial pass. The Shop and Cooking panels expose APIs to open with proper mode/state, and close via X button and ESC. The specific wiring that opens them in response to S/C keys depends on an external HUD handler (not visible in the examined files).
- Interaction Patterns: Pass. Arrow navigation, Enter to confirm/select, and auto-focus of the first focusable item on initial open are implemented. The exact mapping uses ui_up/ui_down for lists and ui_accept for selection.
- Component States: Pass with caveats. Normal/Disabled states are implemented for action tabs and the buy/sell bits. Per-item hover/selected visuals exist through the button styling, but explicit per-item state visuals could be strengthened to match the UX spec’s detailed hover/selected affordances.
- Accessibility: Pass with improvements suggested. Keyboard reachability is present and focus is moved between actionable items. Explicit focus indicators and ARIA-like cues could be enhanced by adding focused state styling on list items.
- Testability: Pass. A manual test plan is provided at the end of this document for both flows; consider adding automated Godot tests in a future iteration.

Key observations and gaps
- G1. Reopening focus after panel reopen: _focus_first_item_if_any is only invoked in _ready. When panels are closed and reopened, the first item may not auto-focus again.
- G2. Keyboard-toggling close: The spec mentions re-pressing S/C should close. The code supports ESC/X to close but has no explicit close-on re-press of S/C.
- G3. Item state visuals: There is basic visual feedback via button styles, but per-item hover/selected states could be more explicit to align with the UX spec.
- G4. Focus refresh on panel open: The shop_pane’s _populate_items() clears and rebuilds the grid but does not reset the item_select_buttons list before populating, which can lead to duplicate references and navigation drift across reopenings.
- G5. Accessibility: No explicit instructions for screen readers; rely on Godot's default focus cues. Consider improving contrast and adding descriptive label hints where needed.

Recommended fixes (concrete steps)
- F1. Reset and re-focus on open: In ShopPanel.open_panel, after _populate_items() and _update_ui(), call _focus_first_item_if_any() to ensure the first item is focused on every open.
- F2. Reset keyboard navigation state on open: In ShopPanel.open_panel, clear item_select_buttons before populating items to avoid duplicates, or call a dedicated _reset_navigation() wrapper.
- F3. Close-on-repress of S/C: Extend HUD wiring to close the panel when the corresponding S or C key is pressed again while a panel is open (or implement a toggle behavior in _unhandled_input handling for those keys).
- F4. Improve per-item visuals: Add an explicit hover/selected style for item cards and ensure a visually distinct “selected” border or background when an item is chosen.
- F5. Accessibility tweaks: Ensure all interactive elements have readable focus rings and consider adding accessible labels for recipe items and shop items.

Manual test plan (Godot)
Shop flow (BUY general store)
- Precondition: HUD opens the Shop panel in BUY GENERAL mode by pressing the S key.
- T1. Panel visibility: Verify the Shop panel becomes visible and shows a list of general store items with icons, names, prices, and stock where applicable. Expected: Panel visible with items populated.
- T2. Focus behavior: The first item’s "选择" button should have keyboard focus. Use Tab/Shift+Tab or Up/Down arrows to cycle focus as implemented. Expected: Focus moves to the first item button.
- T3. Navigate items: Press Up/Down (and Left/Right) to move focus between item cards. Expected: Focus visible on each navigable item, wrapping at ends.
- T4. Select item: Press Enter to activate the highlighted item’s 选择 button. Expected: selected_item_id/name/price update, quantity resets to 1, total price updates.
- T5. Adjust quantity: Press + / - or click the minus/plus buttons to change quantity. Expected: Quantity updates and total price reflects new quantity.
- T6. Buy action: Press the Action button (购买) or the item’s 选择->Action path to buy. Expected: In BUY mode, action executes, status label displays success or failure, and the item grid updates if stock/availability changes.
- T7. Close: Press the X button or press ESC to close. Re-open with S to verify closure works; expected: Panel hides when closed, re-opening shows items again.

Cooking flow (cook recipes)
- Precondition: HUD opens the Cooking panel by pressing the C key.
- T1. Recipe list visible: Verify Cooking panel shows recipe rows with a 选择 button for each recipe. Expected: All recipes populated and selectable.
- T2. Navigate recipes: Use Up/Down to focus recipe rows. Expected: Focus moves between recipe rows.
- T3. Select recipe: Press Enter to select the highlighted recipe. Expected: Selected recipe id shown, ingredients list updated, Cook button enabled.
- T4. Show ingredients: Verify ingredient rows show required vs owned amounts and color-coding for sufficiency. Expected: Adequate feedback colors (green for enough, red for not enough).
- T5. Cook readiness: With enough ingredients, press Cook. Expected: CookingSystem.cook_item executes, status updates, and panels refresh as appropriate.
- T6. Buffs display: Verify BuffList updates to reflect new active buffs after cooking. Expected: Buff rows appear with type, value, and remaining days.
- T7. Close: Press the X button or ESC to close. Re-open with C to verify closure works; expected: Panel hides when closed, re-opening shows updated recipe list.

Notes
- If any of the external systems (CookingSystem, InventorySystem, Shop) are not initialized (null), some flows will show empty states (暂无菜谱, 暂无商品). This is expected in a clean slate test.

Appendix: Code references (high level)
- ShopPanel (_ready, open_panel, _populate_items, _on_select_item, _update_ui, _unhandled_input)
- CookingPanel (_ready, open_panel, _populate_recipes, _on_select_recipe, _unhandled_input, _cook_pressed)
