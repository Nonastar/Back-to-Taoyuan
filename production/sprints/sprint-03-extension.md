# Sprint 3 (扩展) -- 2026-05-06 to 2026-05-19

## Sprint Goal

**完成钓鱼系统扩展功能：鱼饵系统、辅助模式、鱼塘基础功能**

## Sprint 3 完成状态

| 任务 | 状态 | 预估天 | 实际天 |
|------|------|--------|--------|
| S3-T1 鱼类数据定义 | ✅ 完成 | 2 | - |
| S3-T2 FishingSystem Autoload | ✅ 完成 | 3 | - |
| S3-T3 钓鱼小游戏核心 | ✅ 完成 | 4 | - |
| S3-T4 钓鱼UI集成 | ✅ 完成 | 2 | - |
| S3-T5 钓鱼技能集成 | ✅ 完成 | 1 | - |

**Must Have 全部完成 ✅**

## Capacity

| 项目 | 值 |
|------|-----|
| 总天数 | 剩余约5天 |
| 缓冲 (20%) | 1天 |
| 可用天数 | 4天 |
| 团队 | 1人 (独立开发者) |

## Sprint 3 扩展任务

### Must Have (P0) - 核心扩展

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| S3-T6 | 鱼饵系统 | Dev | 2 | S3-T2, F03 | 鱼饵消耗、效果加成(咬钩率+20%~50%)、传说鱼概率 |
| S3-T7 | 辅助模式 | Dev | 1 | S3-T3 | 放大安全区，简化时机判定 |

### Should Have (P1) - 鱼塘MVP

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| S3-T8 | 鱼塘基础系统 | Dev | 2 | S3-T1, C02 | 建造鱼塘、放入鱼类、每日产出 |

### Nice to Have (P2)

| ID | 任务 | 负责人 | 预估天 | 依赖 | 验收标准 |
|----|------|--------|--------|------|----------|
| S3-T9 | 鱼类图鉴 | Dev | 1 | S3-T1 | 收集进度显示，已钓/未钓分类 |
| S3-T10 | 鱼塘升级 | Dev | 1 | S3-T8 | 容量升级 (5→10→20) |

## 工作量估算

| 类别 | 任务数 | 总天数 |
|------|--------|--------|
| Must Have | 2 | 3天 |
| Should Have | 1 | 2天 |
| Nice to Have | 2 | 2天 |
| **总计** | **5** | **7天** |

**注**: 预估7天超出可用4天，优先完成 Must Have + Should Have

## 任务优先级

```
Sprint 3 扩展优先级排序:
1. S3-T6 鱼饵系统 (2天) - 增强钓鱼体验
2. S3-T7 辅助模式 (1天) - 改善新手体验
---
Must Have 总计: 3天 ✅
---
3. S3-T8 鱼塘MVP (2天) - 新玩法内容
---
Should Have 总计: 2天
```

## Carryover from Sprint 3

| Task | Reason | New Estimate |
|------|--------|-------------|
| 无 | Sprint 3 Must Have 全部完成 | - |

## 风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 鱼塘系统复杂度高 | 中 | 中 | MVP只实现核心养殖，跳过繁殖/遗传 |
| 鱼饵UI需要新界面 | 低 | 低 | 使用现有背包界面扩展 |
| 辅助模式与普通模式冲突 | 低 | 低 | 使用游戏设置开关切换 |

## Dependencies on External Factors

- **ItemDataSystem**: `design/gdd/foundation/item-data-system.md` (✅ 已完成)
- **InventorySystem**: `design/gdd/core/inventory-system.md` (✅ 已完成)
- **SkillSystem**: `design/gdd/core/skill-system.md` (✅ 已完成)
- **Fish Pond GDD**: `design/gdd/feature/fish-pond-system.md` (✅ Approved)

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

## Definition of Done for this Sprint

- [ ] 鱼饵消耗正确触发
- [ ] 鱼饵效果（咬钩率+20%~50%）正确应用
- [ ] 辅助模式放大安全区
- [ ] 鱼塘可建造
- [ ] 鱼类可放入鱼塘
- [ ] 每日产出正确计算
- [ ] 代码符合命名规范
- [ ] Git 提交包含任务 ID

## 每日检查点

| 日期 | 目标 | 状态 |
|------|------|------|
| Day 1-2 | S3-T6 完成 | [ ] |
| Day 3 | S3-T7 完成 | [ ] |
| Day 4-5 | S3-T8 完成 | [ ] |

## 下一步 (Sprint 4 预览)

| 任务 | 描述 |
|------|------|
| C04 农场地块完善 | 作物生长优化、收获动画 |
| C03 技能系统完善 | 天赋系统、更多技能加成 |
| S3-T10 鱼塘升级 | 容量升级、水质系统 |

---

*最后更新: 2026-04-13*
