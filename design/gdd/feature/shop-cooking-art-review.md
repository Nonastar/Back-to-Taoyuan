# Shop & Cooking Panels Visual Review (Godot 4.6)

This document evaluates visual consistency and UITokens usage for the Shop and Cooking panels as implemented in:
- src/scripts/ui/shop_panel.gd
- src/scripts/ui/cooking_panel.gd

Reference design material:
- design/gdd/feature/shop-cooking-visual-design.md
- src/design/ui_tokens.gd

## Summary
- UITokens usage: Pass
- Visual consistency with HUD and inventory: Mostly Pass with notes
- Component styling (buttons, cards, text): Pass with minor gaps
- Resolution/key edge cases: Recommend tests and minor tweaks

Status: Pass with recommended refinements below.

## 1) UITokens Usage
- PANEL_BG used for panel backgrounds: Yes. shop_panel.gd applies UITokens.PANEL_BG to the panel StyleBoxFlat.
- PANEL_BORDER used for borders: Yes. Borders are applied in panel and button styles using UITokens.PANEL_BORDER.
- ACCENT_GOLD used for price text: Yes. Price text in shop items uses UITokens.ACCENT_GOLD.
- ACCENT_GREEN / ACCENT_RED usage: Defined in ui_tokens.gd, but not consistently used in code paths for status feedback. In cooking_panel.gd and inventory-related sections, color overrides are often hard-coded (e.g., red/green tones for material sufficiency). Recommendation: wire these into the design system by using UITokens.ACCENT_GREEN/ACCENT_RED where appropriate for readability and consistency.
- Spacing tokens (SPACE_8, SPACE_16, etc.): Used across panel and button styling (SPACE_16 and SPACE_8). Good consistency.
- Radius tokens (RADIUS_MD): Used for panel corners and button corners. Correct.

### Observations
- item cards and panels adopt a consistent visual language via UITokens, aligning with the intended design language.
- The price display uses the intended ACCENT_GOLD color, which reinforces price emphasis.
- Some status/validation text uses explicit Color values rather than UITokens (e.g., in _update_ingredients_display for “not enough” vs “enough”). This is a minor inconsistency with the token system.

## 2) Visual Consistency with HUD and Inventory
- HUD (src/scenes/ui/HUD.tscn): Visual language centers on a dark overlay with semi-transparent bars; the color system uses dark panels and accent tokens. The Shop/Cooking panels match this dark, high-contrast style through PANEL_BG and ACCENT_GOLD.
- Inventory panel (src/scenes/ui/inventory_panel.tscn): Uses a more neutral default styling in its scene definition. Shop/Cooking panels maintain the main design language, but cross-scene consistency relies on a shared UITokens usage. Recommendation: introduce UITokens-based styling for InventoryPanel as well for full consistency.
- Style language consistency: Overall, Shop/Cooking adheres to the design system’s color and spacing vocabulary; HUD and Shop/Cooking share the dark panel aesthetic but Inventory could be aligned further via tokens.

## 3) Component Styles
- Buttons: Normal/hover/pressed states implemented for the Shop's main action and the recipe item buttons in Cooking, using StyleBoxFlat overrides. This provides clear visual feedback.
- Cards/Items: Shop item cards use a PanelContainer with a defined minimum size; the icon, name, price, and stock sub-elements are laid out in a compact card, with price highlighted in gold and stock in secondary text color.
- Text readability and contrast: Primary text uses TEXT_PRIMARY; secondary/stock uses TEXT_SECONDARY. Price uses ACCENT_GOLD for emphasis. Overall readable against PANEL_BG.
- Minor gap: ActionButton (购买/出售) only has a normal state override in code; hover/pressed variants are not explicitly overridden. If consistent hover/pressed language is desired across all main actions, add hover/pressed style overrides similar to Buy/Sell styles.

## 4) Resolution Testing
- The panels are designed to be responsive through PanelContainer sizing and dynamic styling. The code uses fixed content margins (SPACE_16 / SPACE_8) and radius constants to maintain consistent density across sizes.
- Recommendation: test at multiple resolutions to ensure panel centering and content scaling remain harmonious. If needed, add explicit anchors or min/max sizes to ensure centering on extreme aspect ratios.

## 5) Issues Found and Fixes
- Issue: Inconsistent use of UITokens for some status/feedback text (hard-coded colors in Cooking panel for ingredient sufficiency).
  - Fix: Replace hard-coded color values with UITokens.ACCENT_GREEN/ACCENT_RED or UITokens.TEXT_PRIMARY/TEXT_SECONDARY where appropriate.
- Issue: Action button (购买/出售) uses a normal state override only; no explicit hover/pressed overrides.
  - Fix: Add hover/pressed style overrides to action_button similar to Buy and Sell, reusing the same color/radius/margins.
- Issue: Inventory panel styling is not UITokens-driven, potentially breaking cross-scene consistency.
  - Fix: Apply UITokens-based styling to InventoryPanel and its item/tool sub-views where appropriate for full system-wide cohesion.

## 6) Recommended Fixes (priority order)
1) Refactor status text coloring in CookingPanel to use UITokens.ACCENT_GREEN/ACCENT_RED for whether ingredient sufficiency is met.
2) Add hover/pressed style overrides to Action button in ShopPanel to ensure parity with Buy/Sell.
3) Extend UITokens styling to InventoryPanel (and possibly its item/tool sub-views) to ensure end-to-end consistency.
4) Conduct a quick multi-resolution test pass (e.g., 1280x720, 1920x1080, 1366x768) to confirm centering and sizing behavior; if needed, fix anchors/minimum sizes.

If you want, I can implement the above refinements directly and re-run a diagnostic pass.
