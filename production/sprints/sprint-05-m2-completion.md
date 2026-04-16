# Sprint 5 -- 2026-04-14 to 2026-04-27

## Sprint Goal

**完成 M2 里程碑：完善畜牧系统（养殖、互动、产出）和钓鱼系统扩展（鱼类图鉴、鱼塘管理）**

## 背景

### Sprint 4 回顾
- ✅ S4-T1 鱼饵系统完成
- ✅ S4-T2 辅助模式完成
- ✅ S4-T3 鱼塘基础系统完成
- ✅ S4-T4 畜牧数据定义完成
- ✅ S4-T5 畜棚场景基础完成
- ✅ S4-T6 鱼类图鉴完成
- ✅ S4-T7 鱼塘升级完成

### M2 里程碑进度
| 系统 | GDD | 状态 | Sprint |
|------|-----|------|--------|
| C01 玩家属性系统 | ✅ | 完成 | Sprint 3 |
| C02 库存系统 | ✅ | 完成 | Sprint 3 |
| C04 农场地块系统 | ✅ | 完成 | Sprint 3/4 |
| C03 技能系统 | ✅ | 完成 | Sprint 4 |
| P01 畜牧系统 | ✅ | 进行中 | Sprint 5 |
| P02 钓鱼系统 | ✅ | 进行中 | Sprint 5 |

### Sprint 5 目标
- 完成畜牧系统（好感度、产出、疾病）
- 完成钓鱼系统扩展（图鉴完善、鱼塘管理）
- M2 垂直切片验收

## Capacity

| 项目 | 值 |
|------|-----|
| 总天数 | 14天 |
| 缓冲 (20%) | 3天 |
| 可用天数 | 11天 |
| 团队 | 1人 (独立开发者) |

## Sprint 5 详细任务

### Must Have (P0) - 畜牧系统核心

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| S5-T1 | 畜牧好感度系统 | Dev | 2 | S4-T4 | 好感度增减、等级判定、等级奖励 |
| S5-T2 | 畜牧产出系统 | Dev | 2 | S5-T1 | 每日产出判定、品质加成、收集到背包 |
| S5-T3 | 畜牧交互UI | Dev | 2 | S5-T1, S5-T2 | 动物信息面板、喂养/抚摸按钮、产出提示 |

### Should Have (P1) - 钓鱼系统完善

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| S5-T4 | 钓鱼图鉴UI | Dev | 1 | S4-T6 | 图鉴界面、分类筛选、已钓/未钓状态 |
| S5-T5 | 鱼塘管理界面 | Dev | 1 | S4-T3 | 鱼塘详情、放入/取出鱼类、产出记录 |

### Nice to Have (P2) - 扩展功能

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| S5-T6 | 畜牧疾病系统 | Dev | 2 | S5-T1 | 生病判定、治疗逻辑、影响产出 |
| S5-T7 | 动物喂食消耗 | Dev | 1 | S5-T1, F03 | 干草消耗逻辑、背包联动 |
| S5-T8 | 钓鱼成就挂钩 | Dev | 1 | S5-T4 | 钓鱼里程碑成就触发 |

## 工作量估算

| 类别 | 任务数 | 总天数 |
|------|--------|--------|
| Must Have | 3 | 6天 |
| Should Have | 2 | 2天 |
| Nice to Have | 3 | 4天 |
| **总计** | **8** | **12天** |

**注**: 预估12天略超可用11天，优先完成 Must Have + Should Have

## 任务优先级

```
Sprint 5 优先级排序:
1. S5-T1 好感度系统 (2天) - 阻塞其他畜牧功能
2. S5-T2 产出系统 (2天) - 核心收益逻辑
3. S5-T3 畜牧UI (2天) - 玩家交互入口
---
Must Have 总计: 6天
---
4. S5-T4 钓鱼图鉴UI (1天) - 收集系统完善
5. S5-T5 鱼塘管理界面 (1天) - 鱼塘可用性
---
Should Have 总计: 2天 (共8天，3天缓冲)
---
6. S5-T6 疾病系统 (2天) - 深度玩法
7. S5-T7 喂食消耗 (1天) - 经济循环
8. S5-T8 钓鱼成就 (1天) - 成就系统集成
```

## Carryover from Sprint 4

| Task | Reason | New Estimate |
|------|--------|-------------|
| 无 | Sprint 4 全部完成 | - |

## 风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 畜牧UI复杂度高 | 中 | 中 | MVP先做简单面板，后续迭代 |
| 产出与背包耦合 | 低 | 低 | 使用现有 InventorySystem 接口 |
| 疾病系统影响平衡 | 中 | 中 | MVP先不做，使用简单产出模型 |

## Dependencies on External Factors

- **Animal Husbandry GDD**: `design/gdd/feature/animal-husbandry-system.md` (✅ Approved)
- **Fish Pond GDD**: `design/gdd/feature/fish-pond-system.md` (✅ Approved)
- **Fishing System GDD**: `design/gdd/feature/fishing-system.md` (✅ Approved)
- **InventorySystem**: `design/gdd/core/inventory-system.md` (✅ Completed)
- **SkillSystem**: `design/gdd/core/skill-system.md` (✅ Completed)
- **ItemDataSystem**: `design/gdd/foundation/item-data-system.md` (✅ Completed)

## 设计文档参考

### 畜牧好感度系统设计 (来自 Animal Husbandry GDD)

**好感度范围**: 0-1000
```
friendship_delta = clamp(random_integer(1, 3), 0, 1000 - current_friendship)
# 喂养增加 1~3 点

friendship_delta = clamp(random_integer(5, 12), 0, 1000 - current_friendship)
# 抚摸增加 5~12 点
```

**好感度等级判定**:
```
if friendship >= 700:   level = "Best Friend"
elif friendship >= 400:  level = "Friend"
elif friendship >= 200:  level = "Pal"
else:                    level = "Stranger"
```

**品质加成**:
```
friendship_bonus = {
    "Stranger": 0%,
    "Pal": +2%,
    "Friend": +5%,
    "Best Friend": +10%
}
```

### 畜牧产出系统设计

**每日产出判定**:
```
if animal.is_producing_today:
    if product_type == "egg" or "milk":
        produce_quantity = 1
    elif product_type == "wool":
        # 需要检查剪毛冷却 (每3天)
    elif product_type == "truffle":
        # 松露猪使用概率 (30%基础)
```

### 畜牧UI设计 (MVP范围)

**简化版UI**:
- 动物点击 → 显示信息面板（名称、好感度、状态）
- 喂养按钮 → 消耗饲料，增加好感度
- 抚摸按钮 → 增加好感度
- 收集按钮 → 将产出移入背包
- 建筑信息 → 容量显示

**MVP排除的UI功能**:
- ❌ 好感度动画
- ❌ 动物状态图标
- ❌ 批量操作
- ❌ 特殊动物详情

## Definition of Done for this Sprint

- [ ] 动物好感度可正确增减
- [ ] 好感度等级显示正确（Stranger/Pal/Friend/Best Friend）
- [ ] Best Friend 产出高品质概率+10%
- [ ] 每日刷新后产出判定正确
- [ ] 产出品可收集到背包
- [ ] 畜牧UI面板可打开
- [ ] 喂养/抚摸按钮功能正常
- [ ] 钓鱼图鉴UI显示所有鱼类
- [ ] 鱼塘管理界面可添加/取出鱼类
- [ ] 代码符合命名规范
- [ ] Git 提交包含任务 ID

## M2 垂直切片验收检查

**Sprint 5 后应满足以下条件**:

| 功能 | 验收标准 | 状态 |
|------|----------|------|
| 玩家属性 | 体力/HP/金钱正常 | ✅ |
| 库存系统 | 添加/移除/堆叠物品 | ✅ |
| 农场地块 | 耕地/播种/浇水/收获 | ✅ |
| 技能系统 | 经验获取、升级 | ✅ |
| 畜牧系统 | 喂养/产出/收集 | 🔄 Sprint 5 |
| 钓鱼系统 | 完整钓鱼流程 | 🔄 Sprint 5 |

## 每日检查点

| 日期 | 目标 | 状态 |
|------|------|------|
| Day 1-2 | S5-T1 完成 | [ ] |
| Day 3-4 | S5-T2 完成 | [ ] |
| Day 5-6 | S5-T3 完成 | [ ] |
| Day 7 | S5-T4 完成 | [ ] |
| Day 8 | S5-T5 完成 | [ ] |
| Day 9-14 | S5-T6/T7/T8 或缓冲 | [ ] |

## 技术债务清理 (Sprint 5)

### TODO 清理优先级

| 文件 | TODO数 | 优先级 | 行动 |
|------|--------|--------|------|
| `game_manager.gd` | 5 | 高 | 规划新游戏/加载流程 |
| `audio_manager.gd` | 5 | 中 | 添加音频资源或占位符 |
| `inventory_system.gd` | 1 | 中 | 物品使用逻辑完善 |
| `time_manager.gd` | 1 | 低 | 午夜警告UI |

**注**: Sprint 5 不包含 TODO 清理，作为并行任务处理

## 下一步 (Sprint 6 预览)

| 任务 | 描述 | 状态 |
|------|------|------|
| M3 内容系统 | 商店/烹饪/加工 | 待规划 |
| P06 商店系统 | 购买/出售系统 | In Design |
| P04 烹饪系统 | 食谱/烹饪 | In Design |

## Sprint 5 完成状态

### Must Have (P0) - 畜牧系统核心 ✅

| ID | 任务 | 状态 | 验收标准 | 完成日期 |
|----|------|------|----------|----------|
| S5-T1 | 畜牧好感度系统 | ✅ 完成 | 好感度增减、等级判定、等级奖励 | 2026-04-14 |
| S5-T2 | 畜牧产出系统 | ✅ 完成 | 每日产出判定、品质加成、收集到背包 | 2026-04-14 |
| S5-T3 | 畜牧交互UI | ✅ 完成 | 动物信息面板、喂养/抚摸按钮、产出提示 | 2026-04-14 |

### Should Have (P1) - 钓鱼系统完善 ✅

| ID | 任务 | 状态 | 验收标准 | 完成日期 |
|----|------|------|----------|----------|
| S5-T4 | 钓鱼图鉴UI | ✅ 完成 | 图鉴界面、分类筛选、已钓/未钓状态 | 2026-04-14 |
| S5-T5 | 鱼塘管理界面 | ✅ 完成 | 鱼塘详情、放入/取出鱼类、产出记录 | 2026-04-14 |

### Nice to Have (P2) - 延期到Sprint 6 ⚠️

| ID | 任务 | 状态 | 延期原因 |
|----|------|------|----------|
| S5-T6 | 畜牧疾病系统 | ⏸️ 延期 | MVP不需要，简化版产出正常 |
| S5-T7 | 动物喂食消耗 | ⚠️ 部分完成 | 基础消耗已实现(干草x1)，深度逻辑延期 |
| S5-T8 | 钓鱼成就挂钩 | ⏸️ 延期 | 成就系统尚未实现 |

---

*最后更新: 2026-04-15*
