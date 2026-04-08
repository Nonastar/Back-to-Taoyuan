## 桃源乡 Taoyuan

A farming simulation game inspired by Stardew Valley, built with Godot 4.6.

## Getting Started

1. Install Godot 4.6
2. Open this project in Godot
3. Click Run (F5) to start

## Project Structure

```
src/
├── scripts/
│   ├── autoload/     # Global singleton systems
│   ├── entities/     # Game entity base classes
│   ├── components/   # Reusable components
│   ├── systems/       # Game system implementations
│   └── ui/           # UI logic
├── scenes/
│   ├── entities/     # Entity scenes
│   ├── ui/           # UI scenes
│   └── levels/       # Level scenes
└── resources/
    ├── data/         # Game data definitions
    └── configs/       # Configuration files
```

## Architecture

See `design/architecture/` for detailed architecture decisions.

## Documentation

- Systems Index: `design/architecture/systems-index.md`
- Architecture Decisions: `design/architecture/adr-*.md`
- Technical Preferences: `.claude/docs/technical-preferences.md`
