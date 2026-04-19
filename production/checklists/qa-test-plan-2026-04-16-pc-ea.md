# QA Test Plan: EA v0.1.0 -- PC

**Plan Date**: 2026-04-16  
**Owner**: QA Lead / Dev  
**Scope**: Release gate support for `Polish -> Release`  
**Target Build**: `v0.1.0` (TBD commit)

---

## 1) Test Objectives

- Validate core gameplay loop is playable end-to-end without blocker defects.
- Provide objective evidence for release checklist quality gates.
- Detect regressions in high-change systems (GameManager, FishPond, FishCompendium, UI flow).
- Verify performance and stability baselines for PC EA launch.

---

## 2) In-Scope Features

- New game / continue game flow (`game_manager.gd`)
- Time/day progression and save/load basics
- Inventory, skill, farm plot core loop
- Fishing core + fish pond + compendium UI path
- Animal husbandry MVP (friendship, production, interaction UI)
- Basic HUD/navigation and scene transitions

Out of scope (for this plan cycle):
- Full localization quality for all target languages (pre-localization readiness only)
- Non-PC platform certification testing

---

## 3) Test Entry / Exit Criteria

### Entry Criteria
- [ ] Test build available and installable
- [ ] Test data/profile setup instructions documented
- [ ] Known issues baseline documented
- [ ] Smoke sanity check passed

### Exit Criteria
- [ ] All P0/P1 test cases executed
- [ ] No open S1 defects
- [ ] No open S2 defects without explicit waiver
- [ ] Regression pass rate >= 95%
- [ ] Soak + performance evidence attached
- [ ] QA sign-off decision recorded

---

## 4) Test Types and Coverage

### A. Smoke Test (每个候选包必跑)
- Launch game, create profile, enter farm scene
- Basic input works (keyboard/mouse)
- Open/close key UI panels (HUD/inventory/navigation)
- Save once and load once

### B. Core Functional Test
- New game initializes expected default state
- Continue game loads selected slot correctly
- Core loop: farm plot interact -> crop growth -> harvest -> inventory/skill update
- Fishing loop: catch fish -> compendium update -> fish pond add/remove/collect
- Animal loop: feed/pet/collect with expected friendship/production changes

### C. Regression Test
- Run all existing unit tests
- Manual regression pass on top 10 critical user journeys
- Verify previous high-risk fixes did not regress

### D. Performance / Stability
- 30-minute normal-play profiling session
- 4-hour soak session (idle + active mix)
- Record FPS/memory/load-time evidence

### E. Release Readiness Checks
- No hardcoded player-facing text newly introduced in `src/`
- Crash reporting/analytics hook sanity (if configured)
- Packaging/install/uninstall sanity (PC)

---

## 5) Test Environment Matrix

| Env ID | OS | Build Type | Notes |
|-------|----|------------|------|
| PC-01 | Windows 10/11 | Release candidate | Primary gate env |
| PC-02 | Windows 10/11 | Debug/reference | Repro and diagnostics |

---

## 6) Priority Test Cases

| ID | Priority | Area | Test Case | Expected Result |
|----|----------|------|-----------|-----------------|
| TC-001 | P0 | Startup | Start new game from title | Enter playable farm state with initialized data |
| TC-002 | P0 | Save/Load | Save to slot and continue from same slot | State restored without data corruption |
| TC-003 | P0 | Core Loop | Plant -> grow -> harvest cycle | Inventory and skill gain update correctly |
| TC-004 | P0 | Fishing | Catch fish from spot | Fish added, feedback shown, no soft lock |
| TC-005 | P0 | Compendium | Catch new fish and open compendium | Discovery/catch count/progress updated |
| TC-006 | P0 | Fish Pond | Add fish -> daily tick -> collect | Capacity/production/collection behave correctly |
| TC-007 | P1 | Animal | Feed/pet/collect production | Friendship and production rules apply |
| TC-008 | P1 | UI/Flow | Open/close inventory/HUD/navigation repeatedly | No broken state transitions |
| TC-009 | P1 | Performance | 30-min active play sample | No severe frame stutter or memory spikes |
| TC-010 | P1 | Stability | 4-hour soak | No crash, no progressive degradation |

---

## 7) Defect Triage Rules

- **S1 (Critical)**: crash, save corruption, unrecoverable blocker, startup failure.
- **S2 (Major)**: feature unusable, major progression break, severe UX dead-end.
- **S3 (Minor)**: non-blocking bugs, visual/UI issues, low-impact logic mismatch.

Triage SLA:
- S1: immediate (same day)
- S2: next working day
- S3: batch in sprint planning

---

## 8) Evidence Artifacts (必留痕)

- Test execution log (date/build/tester/result)
- Defect list with severity and status
- Unit/regression summary snapshot
- Performance evidence (FPS/memory/load)
- Soak test summary
- Final QA sign-off record

Recommended location:
- `production/qa-reports/2026-04-xx/`

---

## 9) Execution Plan (Suggested)

| Day | Focus | Owner | Deliverable |
|-----|-------|-------|-------------|
| D1 | Smoke + P0 core path | QA/Dev | Initial defect list |
| D2 | Regression + fish/animal deep checks | QA/Dev | Regression report |
| D3 | Performance + soak start | QA/Dev | Perf baseline |
| D4 | Soak finish + retest fixes | QA/Dev | Final QA verdict draft |

---

## 10) QA Sign-off

| Role | Name | Decision | Date | Notes |
|------|------|----------|------|------|
| QA Lead |  | [ ] PASS [ ] CONDITIONAL [ ] FAIL |  |  |
| Dev Lead |  | [ ] PASS [ ] CONDITIONAL [ ] FAIL |  |  |

Final QA Recommendation: **TBD**
