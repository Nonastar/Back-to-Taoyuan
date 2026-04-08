## 归园田居

Godot 4.6 农场模拟游戏

## 项目结构

```
.
├── project.godot          # Godot项目配置
├── src/                   # 源代码目录
│   ├── scripts/          # 脚本文件
│   │   ├── autoload/    # 全局单例系统
│   │   ├── entities/     # 游戏实体基类
│   │   ├── components/   # 可复用组件
│   │   ├── systems/     # 游戏系统实现
│   │   └── ui/          # UI逻辑
│   ├── scenes/          # 场景文件
│   │   ├── entities/    # 实体场景
│   │   ├── ui/          # UI场景
│   │   └── levels/      # 关卡场景
│   └── resources/       # 资源文件
│       ├── data/         # 数据定义
│       └── configs/       # 配置文件
├── design/              # 设计文档
├── docs/                # 技术文档
├── prototypes/          # 原型
└── production/          # 生产管理
```

## 快速开始

1. 使用 Godot 4.6 打开此项目
2. 按 F5 运行游戏

## 文档

- [系统索引](design/architecture/systems-index.md)
- [架构决策](design/architecture/)
- [技术偏好](.claude/docs/technical-preferences.md)
