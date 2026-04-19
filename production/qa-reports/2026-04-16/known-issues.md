# Known Issues - 2026-04-16

**Build Version**: `v0.1.0`  
**Owner**: QA Lead / Dev  
**Source**: QA execution + release gate tracking

---

## Severity Definitions

- **S1 (Critical)**: crash, save corruption, unrecoverable blocker.
- **S2 (Major)**: major feature unusable, severe progression issue.
- **S3 (Minor)**: non-blocking logic/UI/visual issues.

---

## Open Issues

| Issue ID | Severity | Area | Description | Repro | Workaround | Target Fix | Blocks GO |
|----------|----------|------|-------------|-------|------------|------------|-----------|
| KI-001 | S2 | Release Evidence | Missing complete release evidence chain (balance/localization/perf/changelog) | N/A | Produce required reports in `production/` | Before release gate rerun | Yes |
| KI-002 | S2 | QA Process | Formal QA run not fully executed and signed | N/A | Execute `execution-log.md` fully and sign off | Before release gate rerun | Yes |
| KI-003 | S2 | Localization | Hardcoded player-facing strings still exist in `src/` | Static scan | Externalize strings and verify | Before release gate rerun | Yes |
| KI-004 | S3 | Technical Debt | Remaining TODOs in non-core files (e.g. audio polish path) | Code review | Plan cleanup in Sprint 6+ | Sprint 6 | No |

---

## Candidate Waivers (If Needed)

Use only for non-blocking S2/S3 items with explicit approval.

| Issue ID | Waiver Reason | Risk Acceptance Owner | Expiry | Status |
|----------|---------------|-----------------------|--------|--------|
|          |               |                       |        |        |

---

## Recently Closed Issues

| Issue ID | Severity | Summary | Closed Date | Verified By |
|----------|----------|---------|-------------|-------------|
| KI-C001 | S2 | `game_manager` new/continue flow TODO converted to executable path | 2026-04-16 | Dev |
| KI-C002 | S3 | Fish pond / compendium tests strengthened for key behavior paths | 2026-04-16 | Dev |

---

## Release Decision Guardrails

- If any **S1** open issue exists -> **NO-GO**
- If any **S2** open issue exists without approved waiver -> **NO-GO**
- `Blocks GO = Yes` items must be closed before final sign-off

---

## Approval

| Role | Name | Date | Comment |
|------|------|------|---------|
| QA Lead |  |  |  |
| Dev Lead |  |  |  |
