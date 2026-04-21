# Bug Severity Grading Framework

> **状态**: Active
> **Last Updated**: 2026-04-21
> **Owner**: Dev

## Purpose

This document defines the severity classification for bugs found in 归园田居 (Taoyuan). Every bug report must include a severity level. Severity determines response time, fix priority, and escalation path.

---

## Severity Levels

### S1 — Critical

**Definition**: Game is completely unplayable, data corruption, or security vulnerability.

**Response**: Fix within 24 hours. All other work pauses.

**Examples**:
- Game crashes on startup for all players
- Save data corrupts on every save
- Player progress permanently lost
- Security: player can read/modify other players' save files
- Critical path feature completely broken (e.g., cannot plant, cannot sleep, cannot eat)

**Counter**: 0 tolerance.

---

### S2 — High

**Definition**: A major feature is blocked, or progress is significantly hindered.

**Response**: Fix within 3 days. High priority in sprint.

**Examples**:
- Cannot complete the core gameplay loop (e.g., cannot buy from shop)
- Inventory system fails silently (items disappear)
- Time system stops advancing
- Shop purchase/sell always fails
- Animal husbandry system crashes when buying animals
- Save/load produces incorrect data
- Audio causes crash
- Multi-file loss: 3+ features affected

**Counter**: 0 tolerance.

---

### S3 — Medium

**Definition**: A feature is degraded but a workaround exists, or the issue is cosmetic.

**Response**: Fix within 1 sprint (14 days).

**Examples**:
- UI element is misaligned but function still works
- Button text is wrong (wrong language/no translation)
- SFX doesn't play for one specific action
- Animal produces wrong item occasionally
- Backpack shows wrong item count (off by one)
- Weather display is incorrect
- One NPC dialogue is wrong

**Counter**: Soft cap. Track but don't block releases.

---

### S4 — Low

**Definition**: Minor cosmetic issue or very rare edge case.

**Response**: Fix within 2 sprints, or backlog for v1.1.

**Examples**:
- Tooltip slightly mispositioned
- Rare crash that requires specific sequence of 5 actions
- Spelling error in non-critical text
- Animation frame drop in non-essential VFX
- Minor color inconsistency in UI

**Counter**: No counter. Backlog items.

---

### S5 — Enhancement

**Definition**: Not a bug. Feature request, UX improvement, or polish item.

**Response**: Never enters bug counter. Move to feature backlog.

**Examples**:
- "Could we add a confirmation dialog before selling?"
- "The button hover effect could be more visible"
- "Add auto-save every 5 minutes"

---

## Bug Counters

| Sprint | S1 Count | S2 Count | S3 Count | S4 Count | Notes |
|--------|----------|----------|----------|----------|-------|
| S1 | 0 | 1 | 2 | 1 | |
| S2 | 0 | 0 | 3 | 2 | |
| S3 | 0 | 1 | 2 | 0 | |
| S4 | 0 | 0 | 1 | 2 | |
| S5 | 0 | 0 | 1 | 0 | |
| S6 | 0 | 0 | 0 | 0 | All bugs resolved before sprint close |
| S7 | 0 | 0 | 0 | 0 | Running... |

**Release gate**: Zero S1 and S2 bugs open before shipping. S3 count ≤ 3.

---

## Bug Triage Checklist

For every bug report, answer these:

1. **Can the player finish a typical play session?** (If no → S1/S2)
2. **Is a workaround available?** (If yes → S3)
3. **Does it affect more than one feature?** (If yes → S2 minimum)
4. **Is it a visual/text issue only?** (If yes → S3/S4)
5. **Is this actually a bug or a feature request?** (If feature → S5)

---

## Severity Override Rules

- **S1 escape**: A bug discovered as S3 but later found to be S1 must be escalated immediately.
- **S2 downgrade**: Only if verified workaround is sufficient for majority of players.
- **Auto-escalation**: 3 × S3 in same system → one S2.

---

## File Format for Bug Reports

```markdown
| ID | Severity | Title | System | Found By | Date | Status |
|----|----------|-------|--------|----------|------|--------|
| B001 | S2 | Shop purchase silently fails | ShopSystem | Dev | 2026-04-20 | Fixed |
```

---

*Last updated: 2026-04-21*