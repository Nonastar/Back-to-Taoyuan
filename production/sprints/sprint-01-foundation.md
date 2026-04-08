# Sprint 1 -- 2026-04-08 to 2026-04-21

## Sprint Goal

**搭建Godot项目基础框架，实现核心基础设施系统（时间、存档、物品数据），为后续游戏系统开发奠定基础。**

## 背景

### 项目概述
- **项目**: 桃源乡 - Vue.js → Godot 4.6 移植
- **类型**: 农场模拟经营游戏
- **参考**: Stardew Valley
- **规模**: 46个系统，31,536行GDD文档

### 设计完成情况
- ✅ 46个系统 GDD 已完成
- ✅ 14个架构决策 ADR 已完成
- ✅ 农场核心循环原型已验证

## Capacity

| 项目 | 值 |
|------|-----|
| 总天数 | 14天 |
| 缓冲 (20%) | 3天 |
| 可用天数 | 11天 |
| 团队 | 1人 (独立开发者) |

## Sprint 1 详细任务

### Must Have (Foundation 基础设施)

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| T01 | Godot项目初始化 | Dev | 1 | - | 项目结构符合ADR-0001，分支已创建 |
| T02 | Autoload系统框架 | Dev | 2 | T01 | GameManager, EventBus, SaveManager框架完成 |
| T03 | F01时间/季节系统 | Dev | 3 | T02 | 28天季节，日夜循环，事件派发 |
| T04 | F04存档系统 | Dev | 3 | T02, T03 | 3存档槽，JSON序列化，加密 |
| T05 | F03物品数据系统 | Dev | 3 | T02 | ItemData基类，ItemDatabase，10个物品定义 |

### Should Have (Core 核心系统)

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| T06 | C01玩家属性系统 | Dev | 2 | T03 | HP/体力/金钱，基础数值 |
| T07 | C02库存系统 | Dev | 3 | T05, T06 | 背包30格，物品添加/移除/堆叠 |
| T08 | F05音效系统 | Dev | 2 | T02 | AudioManager，BGM/SFX播放，音量控制 |

### Nice to Have

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| T09 | F02天气系统 | Dev | 2 | T03 | 6种天气类型，每日天气生成 |
| T10 | 单元测试框架 | Dev | 1 | T01 | GUT测试框架，基础测试 |

## 工作量估算

| 类别 | 任务数 | 总预估天数 |
|------|--------|----------|
| Must Have | 5 | 12天 |
| Should Have | 3 | 7天 |
| Nice to Have | 2 | 3天 |
| **总计** | **10** | **22天** |

**注**: 预估22天超出可用11天，优先完成Must Have (T01-T05)

## 任务优先级

```
Sprint 1 优先级排序:
1. T01 Godot项目初始化 (1天) - 阻塞所有其他任务
2. T02 Autoload系统框架 (2天) - 基础设施
3. T03 F01时间/季节系统 (3天) - 核心依赖
4. T04 F04存档系统 (3天) - 依赖时间系统
5. T05 F03物品数据系统 (3天) - 依赖Autoload框架
---
总计: 12天 (在缓冲范围内)
```

## 技术债务

| 债务 | 来源 | 风险 | 计划 |
|------|------|------|------|
| 原型代码 | farming-core-loop | 低 | Sprint 2 重构为生产代码 |
| 音效资源 | 暂无音频文件 | 中 | 使用占位符，后续替换 |

## 风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| Godot 4.6 API不熟悉 | 中 | 中 | 阅读ADR-0002参考文档 |
| 数据序列化问题 | 低 | 高 | 提前设计存档格式 |
| 时间系统Bug | 中 | 高 | TDD，先写测试 |

## Definition of Done

- [ ] T01-T05 所有Must Have任务完成
- [ ] 所有功能通过验收标准
- [ ] 代码符合命名规范 (参考ADR-0001)
- [ ] Git提交规范，提交信息包含任务ID
- [ ] 存档系统可正常保存/加载
- [ ] 项目结构符合架构文档

## 参考文档

- **架构**: `design/architecture/adr-*.md`
- **系统设计**: `design/architecture/systems-index.md`
- **技术偏好**: `.claude/docs/technical-preferences.md`
- **原型**: `prototypes/farming-core-loop/`

## 每日检查点

| 日期 | 目标 | 完成状态 |
|------|------|----------|
| Day 1 | T01完成 | [x] 2026-04-08 |
| Day 2-3 | T02完成 | [x] 2026-04-08 |
| Day 4-6 | T03完成 | [x] 2026-04-08 |
| Day 7-9 | T04完成 | [ ] |
| Day 10-12 | T05完成 | [ ] |
| Day 13-14 | 缓冲/测试 | [ ] |

## 已完成工作

### T01 Godot项目初始化 ✅
- [x] 项目结构创建 (src/scripts, src/scenes, src/resources)
- [x] project.godot 配置
- [x] .gitignore 文件
- [x] 基础Autoload脚本框架

### T02 Autoload系统框架 ✅
- [x] game_manager.gd - 游戏状态管理
- [x] event_bus.gd - 全局事件总线
- [x] time_manager.gd - 时间/季节系统框架
- [x] save_manager.gd - 存档系统框架
- [x] audio_manager.gd - 音频系统框架
- [x] inventory_system.gd - 库存系统框架
- [x] 主场景集成

### T03 F01时间/季节系统 ✅
- [x] 时间状态机 (TIME_RUNNING, TIME_PAUSED, MINI_GAME, SLEEPING, DAY_TRANSITION, SEASON_TRANSITION)
- [x] 季节枚举和名称映射
- [x] 时段划分 (早晨/下午/傍晚/夜晚/深夜)
- [x] 时间推进 (700ms/游戏小时)
- [x] 睡眠系统 (24时就寝90%恢复, 25时60%, 强制50%)
- [x] 日结算和季节切换
- [x] 信号派发 (hour_changed, day_changed, season_changed, year_changed, sleep_triggered) |
