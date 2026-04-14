# Sprint 4 -- 2026-05-20 to 2026-06-02

## Sprint Goal

**完成钓鱼扩展功能（鱼饵系统、鱼塘MVP）并开始畜牧系统基础实现**

## 背景

### Sprint 3 回顾
- ✅ S3-T1 ~ T5 全部完成
- ✅ 钓鱼系统核心功能就绪
- ✅ 鱼类数据定义完成 (~25种鱼)
- ✅ 钓鱼小游戏正常工作
- ✅ 钓鱼技能集成完成

### Sprint 4 目标
- 完成钓鱼扩展（S3-T6 ~ T8）
- 为畜牧系统奠定基础

## Capacity

| 项目 | 值 |
|------|-----|
| 总天数 | 14天 |
| 缓冲 (20%) | 3天 |
| 可用天数 | 11天 |
| 团队 | 1人 (独立开发者) |

## Sprint 4 详细任务

### Must Have (P0) - 钓鱼扩展

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| S4-T1 | 鱼饵系统 | Dev | 2 | S3-T2 | 鱼饵消耗、效果加成(咬钩率+20%~50%)、传说鱼概率提升 |
| S4-T2 | 辅助模式 | Dev | 1 | S3-T3 | 放大安全区，简化时机判定，可开关切换 |
| S4-T3 | 鱼塘基础系统 | Dev | 3 | S3-T1, C02 | 建造鱼塘、放入鱼类、每日产出计算 |

### Should Have (P1) - 畜牧基础

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| S4-T4 | 畜牧数据定义 | Dev | 2 | F03 | 动物类型定义(鸡/牛/羊/猪)、产出物品、养殖条件 |
| S4-T5 | 畜棚场景 | Dev | 2 | S4-T4 | 畜棚场景、动物放置、基础交互 |

### Nice to Have (P2)

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| S4-T6 | 鱼类图鉴 | Dev | 1 | S3-T1 | 收集进度显示，已钓/未钓分类 |
| S4-T7 | 鱼塘升级 | Dev | 1 | S4-T3 | 容量升级 (5→10→20) |

## 工作量估算

| 类别 | 任务数 | 总天数 |
|------|--------|--------|
| Must Have | 3 | 6天 |
| Should Have | 2 | 4天 |
| Nice to Have | 2 | 2天 |
| **总计** | **7** | **12天** |

**注**: 预估12天超出可用11天，优先完成 Must Have + Should Have

## 任务优先级

```
Sprint 4 优先级排序:
1. S4-T1 鱼饵系统 (2天) - 增强钓鱼体验
2. S4-T2 辅助模式 (1天) - 改善新手体验
3. S4-T3 鱼塘基础系统 (3天) - 新玩法内容
---
Must Have 总计: 6天
---
4. S4-T4 畜牧数据定义 (2天) - 畜牧系统基础
5. S4-T5 畜棚场景 (2天) - 畜牧系统入口
---
Should Have 总计: 4天 (共10天，1天缓冲)
```

## Carryover from Sprint 3

| Task | Reason | New Estimate |
|------|--------|-------------|
| S3-T6 鱼饵系统 | 延期到 Sprint 4 | 2天 |
| S3-T7 辅助模式 | 延期到 Sprint 4 | 1天 |
| S3-T8 鱼塘MVP | 延期到 Sprint 4 | 3天 |

## 风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 鱼塘系统复杂度高 | 中 | 中 | MVP只实现核心养殖，跳过繁殖/遗传 |
| 鱼饵UI需要新界面 | 低 | 低 | 使用现有背包界面扩展 |
| 畜牧系统涉及多个GDD | 中 | 中 | 先完成数据定义，再实现交互 |

## Dependencies on External Factors

- **ItemDataSystem**: `design/gdd/foundation/item-data-system.md` (✅ 已完成)
- **InventorySystem**: `design/gdd/core/inventory-system.md` (✅ 已完成)
- **SkillSystem**: `design/gdd/core/skill-system.md` (✅ 已完成)
- **Fish Pond GDD**: `design/gdd/feature/fish-pond-system.md` (✅ Approved)
- **Animal Husbandry GDD**: `design/gdd/feature/animal-husbandry-system.md` (✅ Approved)
- **Fishing System GDD**: `design/gdd/feature/fishing-system.md` (✅ Approved)

## 设计文档参考

### 鱼饵系统设计 (来自 FishingSystem GDD)

```gdscript
# 鱼饵类型和效果
const BAIT_TYPES: Dictionary = {
    "common": {"name": "普通饵料", "bite_bonus": 0.10, "legendary_bonus": 0.0},
    "deluxe": {"name": "美味饵料", "bite_bonus": 0.20, "legendary_bonus": 0.0},
    "legendary": {"name": "传说饵料", "bite_bonus": 0.50, "legendary_bonus": 0.10}
}

# 咬钩成功率公式
final_bite_success = base_bite_chance(0.60) + bait_bonus
```

### 鱼塘MVP设计 (来自 Fish Pond GDD)

**简化版MVP范围**：
- ✅ 鱼塘建造（费用: 5000g + 木材×100 + 竹子×50）
- ✅ 放入可养殖鱼类（13种基础鱼类）
- ✅ 每日产出计算
- ✅ 鱼塘容量（基础5条）

**MVP排除的功能**（延期到未来Sprint）：
- ❌ 水质系统
- ❌ 疾病系统
- ❌ 繁殖/遗传系统
- ❌ 品种系统（400品种）
- ❌ 鱼塘升级

### 畜牧基础设计 (来自 Animal Husbandry GDD)

**简化版MVP范围**：
- ✅ 畜棚建造（费用: 2000g + 木材×50）
- ✅ 购买动物（鸡: 400g, 牛: 1000g, 羊: 800g, 猪: 1200g）
- ✅ 每日产出（鸡蛋/牛奶/羊毛/松露）
- ✅ 动物喂食（干草消耗）

**MVP排除的功能**（延期到未来Sprint）：
- ❌ 繁殖系统
- ❌ 亲密度系统
- ❌ 特殊动物（鸭/兔/鸵鸟）
- ❌ 牧草系统

## Definition of Done for this Sprint

- [ ] 鱼饵消耗正确触发
- [ ] 鱼饵效果（咬钩率+20%~50%）正确应用
- [ ] 辅助模式放大安全区
- [ ] 鱼塘可建造
- [ ] 鱼类可放入鱼塘
- [ ] 每日产出正确计算
- [ ] 畜牧数据定义完成
- [ ] 畜棚场景可进入
- [ ] 代码符合命名规范
- [ ] Git 提交包含任务 ID

## 每日检查点

| 日期 | 目标 | 状态 |
|------|------|------|
| Day 1-2 | S4-T1 完成 | [ ] |
| Day 3 | S4-T2 完成 | [ ] |
| Day 4-6 | S4-T3 完成 | [ ] |
| Day 7-8 | S4-T4 完成 | [ ] |
| Day 9-10 | S4-T5 完成 | [ ] |
| Day 11-14 | S4-T6/T7 或缓冲 | [ ] |

## 下一步 (Sprint 5 预览)

| 任务 | 描述 |
|------|------|
| C03 技能系统完善 | 天赋系统、更多技能加成 |
| 畜牧养殖系统 | 繁殖、亲密度、特殊动物 |
| 商店系统 | 基础商店购买/出售 |

---

*最后更新: 2026-04-14*
