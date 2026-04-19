# Localization Scan Report - 2026-04-16

**Mode**: `/localize scan`  
**Scope**: `src/`  
**Goal**: Close release blocker `B-003` (hardcoded player-facing text)

---

## Summary

- Localization infrastructure is not initialized yet:
  - No `.po` or `.translation` resources found.
  - No locale/translation config found in `project.godot`.
  - No existing string table found in `assets/data/`.
- UI code currently contains substantial hardcoded player-facing text.
- Existing `tr()` usage is minimal (only a few component files), so most screens bypass localization.

Current recommendation: **Not localization-ready for release**.

---

## Key Findings

### 1) Hardcoded player-facing strings (high priority)

Representative hotspots:

- `src/scripts/ui/animal_husbandry_ui.gd`
  - UI labels and buttons: `"治疗"`, `"喂养"`, `"抚摸"`, `"空空如也"`, `"去购买小动物吧~"`
  - notifications: `"喂养失败: 饲料不足或已喂养"`, `"商店功能暂未开放，请前往村落购买动物"` etc.
- `src/scripts/ui/fish_pond_ui.gd`
  - status text: `"✅成熟"`, `"⏳未成熟"`, `"建造失败: 材料不足"`, `"没有可收获的产物"` etc.
- `src/scripts/entities/farm_plot.gd`
  - gameplay messages: `"耕地完成！"`, `"没有种子了！"`, `"收获成功！"` etc.

These are direct release blockers for multilingual readiness.

### 2) Limited localization API usage

- `tr()` appears in only a very small subset of files.
- Most user-facing strings are assigned directly to `.text` or passed to notification methods.

### 3) Placeholder formatting anti-patterns

- Several strings use `%s/%d` formatting directly.
- For localization safety, these should migrate to keyed templates with named placeholders.

### 4) Mixed content risk (UI text + debug strings)

- Many matched literals are debug logs and node paths (not player-facing).
- Needs triage pass to separate:
  - **Must localize**: visible UI text, notifications, prompts.
  - **Do not localize**: debug logs, internal IDs, node paths, asset keys.

---

## Release Impact

For `Polish -> Release` gate:

- `B-003` remains **Open** until at least:
  - critical UI paths are externalized (farm/fishing/fishpond/animal),
  - string source table exists and is used,
  - no new hardcoded player-facing text is introduced in touched files.

---

## Execution Plan (Practical, 2 Waves)

### Wave 1 (must-have for gate)

Target files:

- `src/scripts/ui/animal_husbandry_ui.gd`
- `src/scripts/ui/fish_pond_ui.gd`
- `src/scripts/entities/farm_plot.gd`
- `src/scripts/ui/fish_compendium_ui.gd`

Actions:

1. Replace player-facing literals with `tr("key")`.
2. Keep debug logs as-is (non-player-facing).
3. Use consistent key naming (`ui.*`, `notification.*`, `entity.*`).
4. Validate no behavior regressions in UI flows.

### Wave 2 (cleanup / expansion)

- Expand to remaining UI and gameplay messages.
- Normalize `%s/%d` templates to localization-friendly key patterns.
- Prepare additional locales after source key set stabilizes.

---

## Proposed Source String Table

See draft proposal:

- `production/localization/string-table-proposal-en.csv`

This is a review artifact (not wired into runtime yet).
