# Release Checklist: EA v0.1.0 -- PC

**Release Date**: TBD  
**Release Manager**: Dev  
**Current Stage**: Polish  
**Status**: [ ] GO / [ ] NO-GO

---

## Build Verification

- [ ] Clean build succeeds on target platform (Windows/macOS/Linux as planned)
- [ ] No compiler/runtime warnings in release build path
- [ ] Build version number set correctly: `0.1.0`
- [ ] Build is reproducible from tagged commit
- [ ] Build size within budget (fill actual vs budget)
- [ ] All assets included and loading correctly
- [ ] No debug/dev-only features enabled in release build

---

## Quality Gates

### Critical Bugs

- [ ] Zero S1 (Critical) bugs open
- [ ] Zero S2 (Major) bugs open (or exception table approved)

| Bug ID | Description | Exception Rationale | Approved By |
| ------ | ----------- | ------------------- | ----------- |
|        |             |                     |             |

### Test Coverage

- [ ] Core gameplay path tested end-to-end and signed off
- [ ] Regression suite passed (record pass rate)
- [ ] Soak test completed (4+ hours)
- [ ] Edge case testing complete

### Performance

- [ ] Target FPS met on minimum spec
- [ ] Memory usage within budget
- [ ] Load times within budget
- [ ] No memory leak observed in soak run
- [ ] No severe frame drops in normal gameplay

---

## Content Complete

- [ ] Placeholder assets replaced
- [ ] Player-facing text proofread
- [ ] No hardcoded player-facing text in `src/`
- [ ] Localization complete for target locales
- [ ] Audio mix finalized
- [ ] Credits complete and accurate
- [ ] Legal notices / third-party attributions complete

---

## Platform: PC

- [ ] Minimum/recommended specs documented
- [ ] Keyboard + mouse fully functional
- [ ] Controller support verified
- [ ] Resolution scaling tested (1080p/1440p/4K)
- [ ] Window modes working (windowed/borderless/fullscreen)
- [ ] Graphics settings save/load correctly
- [ ] Store SDK integration tested (if required)
- [ ] Achievements functional (if enabled)
- [ ] Cloud saves functional (if enabled)

---

## Store and Distribution

- [ ] Store metadata complete and proofread
- [ ] Store screenshots up to date and compliant
- [ ] Trailer/current media validated
- [ ] Capsule/key art final
- [ ] Age ratings prepared (if required for target store)
- [ ] EULA/Privacy/ToS prepared
- [ ] Pricing configured for all target regions

---

## Launch Readiness

- [ ] Analytics/telemetry verified
- [ ] Crash reporting configured
- [ ] Day-one patch plan prepared (if needed)
- [ ] On-call schedule for first 72 hours
- [ ] Community announcement draft ready
- [ ] Support known-issues brief ready
- [ ] Rollback plan documented

---

## Current Known Blockers (2026-04-16)

- [ ] Missing formal QA test plan document
- [ ] Missing release checklist completion evidence from previous gate
- [ ] Missing balance review report (`/balance-check`)
- [ ] Localization not yet externalized/completed
- [ ] Missing changelog/patch-notes draft
- [ ] Missing performance evidence for release targets

---

## Sign-offs

| Role               | Name | Status       | Date |
| ------------------ | ---- | ------------ | ---- |
| QA Lead            |      | [ ] Approved |      |
| Technical Director |      | [ ] Approved |      |
| Producer           |      | [ ] Approved |      |
| Creative Director  |      | [ ] Approved |      |

---

## Final Decision

**GO / NO-GO**: ____________

**Rationale**:  
[If NO-GO, list blockers and ETA. If GO, list accepted risks.]

**Notes**:  
[Additional context and release conditions.]
