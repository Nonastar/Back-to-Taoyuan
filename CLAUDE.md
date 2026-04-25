# 归园田居 - Claude Code Game Studios

Indie game development managed through 48 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.6
- **Language**: GDScript (primary), C# (performance-critical systems)
- **Version Control**: Git with trunk-based development
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md

## Development Checklist

**每次回复语言：**
用户母语是中文，每次回答时务必使用中文回复，这样会更友好！

**每次编写代码前必须完成：**

1. 📋 阅读 `docs/FIXES.md` 的检查清单，确保避免所有已知错误模式
2. ⚠️ 常见错误类型：
   - Autoload 脚本不能使用 `class_name` 或 `@onready`
   - TSCN 文件中不能使用 `#` 注释
   - 类型使用 `int` 而非 `enum`
   - 方法名不与 `Resource` 内置方法冲突
   - 返回类型必须与实际返回值匹配（用默认值代替 null）
   - `[ext_resource]` 和 `[sub_resource]` 必须在节点引用之前定义
3. ✅ 对照检查清单逐项确认后再开始编码

> **为什么要这样做？** `docs/FIXES.md` 记录了项目中犯过的所有错误，
> 每次开发前参考可以有效降低报错率，提升开发效率。
