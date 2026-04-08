## Gui Yuan Tian Ju

Godot 4.6 Farming Simulation Game

## Project Structure

```
.
├── project.godot          # Godot project config
├── src/                   # Source code
│   ├── scripts/          # Script files
│   │   ├── autoload/    # Global singleton systems
│   │   ├── entities/     # Game entity base classes
│   │   ├── components/   # Reusable components
│   │   ├── systems/     # Game system implementations
│   │   └── ui/          # UI logic
│   ├── scenes/          # Scene files
│   │   ├── entities/    # Entity scenes
│   │   ├── ui/          # UI scenes
│   │   └── levels/      # Level scenes
│   └── resources/       # Resource files
│       ├── data/         # Data definitions
│       └── configs/       # Configuration files
├── design/              # Design documents
├── docs/                # Technical documents
├── prototypes/          # Prototypes
└── production/          # Production management
```

## Getting Started

1. Open this project in Godot 4.6
2. Press F5 to run

## Documentation

- [Systems Index](design/architecture/systems-index.md)
- [Architecture Decisions](design/architecture/)
- [Technical Preferences](.claude/docs/technical-preferences.md)
