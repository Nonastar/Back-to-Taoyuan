---
name: 严格遵循 CLAUDE.md 开发检查清单
description: 每次写代码前必须阅读 docs/FIXES.md — 用户明确要求，上轮会话因跳过此步骤导致大量文件损坏
type: feedback
---

**规则:** 每次编写或修改代码前，必须先阅读 `docs/FIXES.md` 的完整检查清单，逐项对照确认。

**Why:** CLAUDE.md 中明文规定"每次编写代码前必须完成：📋 阅读 docs/FIXES.md 的检查清单"。上轮会话（2026-04-28）中跳过此步骤，直接使用 `sed` 修改 GDScript 文件，造成大量损坏（`_tabfix_` 前缀、`ColorUITokens` 拼接错误、if/else 块结构破坏），用户对此严重不满。

**How to apply:** 在调用任何 Write/Edit/Bash（写文件）工具之前，必须先 Read `docs/FIXES.md`，特别关注检查清单部分。如果 FIXES.md 中有对应场景的教训，优先采用其中推荐的做法（如用 Python 而非 sed）。
