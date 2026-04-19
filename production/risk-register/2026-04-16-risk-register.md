# Risk Register - 2026-04-16

| ID | Risk | Probability | Impact | Status | Mitigation | Owner |
|----|------|-------------|--------|--------|------------|-------|
| R-001 | Release evidence chain incomplete (checklists, QA sign-off, perf data) | High | High | Open | Run release/balance/localization workflows and archive outputs in `production/` | Dev |
| R-002 | `game_manager` start/load flow was incomplete and could block playable path | Medium | High | Monitoring | Implemented core start/load flow; verify in sprint demo and add regression tests | Dev |
| R-003 | Localization not externalized; hardcoded player-facing strings remain | High | High | Open | Execute localization workflow, extract strings, and replace hardcoded text | Dev |
| R-004 | Fish pond / compendium regression risk due to limited targeted tests | Medium | Medium | Open | Add deterministic unit tests for add/remove/collect and compendium record/progress paths | Dev |
| R-005 | Technical debt concentration in `audio_manager.gd` and remaining TODOs | Medium | Medium | Open | Schedule debt cleanup in Sprint 6 and track closure per file | Dev |
| R-006 | No formal bug severity tracking may hide S1/S2 issues | Medium | High | Open | Create lightweight bug triage doc with S1/S2/S3 counters | Dev |

## Review Notes

- Next review date: Sprint 6 planning day.
- Exit criteria for release phase: R-001 and R-003 move to `Closed`, R-004 at least `Monitoring`.
