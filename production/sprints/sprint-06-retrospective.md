# Sprint 6 Retrospective

**Sprint 6** — 2026-04-20 to 2026-04-21 (持续中)

## 团队
独立开发者 (Dev)

---

## Sprint 目标回顾

**目标**: 完成 M3 里程碑开局：商店系统（购买/出售/动物商店）和烹饪系统（食谱/烹饪锅）核心逻辑上线，同步推进本地化和风险关闭。

**结果**: ✅ 目标基本达成，核心功能已上线，仍有少量 Nice-to-Have 任务延期。

---

## 交付成果

### 商店系统 (S6-T1~T4)
- [x] `ShopSystem.gd` Autoload，营业时间检查
- [x] 杂货铺购买/出售 UI（商品列表、数量选择、状态提示）
- [x] 动物商店 UI（7 种动物：白鸡/棕鸡/鸭/牛/绵羊/猪/山羊）
- [x] 购买成功/失败状态提示（绿色/红色文字）
- [x] 动物物品注册到 ItemDataSystem（ANIMAL 分类）
- [x] 修复 Bug：StatusBar 被 NavigationPanel 遮挡
- [x] 修复 Bug：出售标签页未刷新背包列表
- [x] 修复 Bug：item_def 类型错误

### 烹饪系统 (S6-T5~T7)
- [x] `CookingSystem.gd` Autoload，10 种食谱
- [x] 烹饪核心逻辑（投入食材、计时、产出物品、品质继承）
- [x] 食用料理 Buff 系统（体力恢复/速度/幸运）
- [x] 精通计数（10 次烹饪达到精通）
- [x] `_output_to_recipe` 反向索引（O(1) 查找产出→Buff）
- [x] 10 种烹饪产出物品注册到 ItemDataSystem
- [x] 21 种鱼类物品注册到 ItemDataSystem
- [x] 烹饪面板 UI（含 _build_output_index 初始化）

### 本地化 (S6-T8)
- [x] `I18n` Autoload 建立
- [x] `strings.csv` 翻译表生成
- [x] `I18n.translate(key)` 和 `I18n.trf(key, args)` API
- [x] 批量替换 UI 硬编码字符串 → i18n 调用

### 单元测试 (S6-T9~T10)
- [x] `fish_pond_system_test.gd` — 全部通过
- [x] `fish_compendium_test.gd` — 全部通过
- [x] `cooking_system_test.gd` — 全部通过
- [x] `shop_system_test.gd` — 全部通过（动物商店数量修正）

---

## 修复的关键 Bug

| Bug | 根因 | 修复 |
|-----|------|------|
| 购买后无提示 | StatusBar 被 NavigationPanel 遮挡 + Label height=0 | 调换 HUD/NavigationPanel 加载顺序，移除 size_flags_vertical=1 |
| 背包格子 128px | icon.svg (128×128) + EXPAND_IGNORE_SIZE 撑大格子 | 设置 TextureRect.custom_minimum_size=64, BackpackGrid size_flags=SHRINK_END |
| QualityBorder 挡图标 | ColorRect 全尺寸填充盖住图标 | 改为 inset 3px 边框模式 |
| 背包显示白块 | icon.svg 图标文件目录不存在 | 创建 item_placeholder.png，或用正确属性加载 SVG |
| 出售标签显示商店商品 | `_on_sell_pressed()` 未调用 `_populate_items()` | 添加 `_populate_items()` 调用 |
| 烹饪系统 eat_dish 返回空 Buff | `_output_to_recipe` 仅在 cook_item() 时初始化 | `_initialize_recipes()` 中调用 `_build_output_index()` |
| 动物商店"物品不存在" | 动物物品未注册到 ItemDataSystem | 添加 ANIMAL 分类 + `_create_animal_items()` |

---

## 未完成任务

| 任务 | 原因 | 延期至 |
|------|------|--------|
| S6-T11 game_manager TODO清理 | UI 功能需单独设计存档菜单 | Sprint 7 |
| S6-T12 Bug严重性分级文档 | 优先级低于功能开发 | Sprint 7 |
| S5-T6 畜牧疾病UI暴露 | Sprint 5 代码已存在，UI 延期 | Sprint 7 |
| S5-T7 深度喂食逻辑 | 需商店系统支持多饲料购买 | Sprint 7 |

---

## 经验教训

### 做得好的
1. **代码审查先行** — 通过 `/code-review sprint-6` 在提交前发现了 5 个 HIGH 严重性问题
2. **测试驱动修复** — 单元测试覆盖 fish_pond/compendium/cooking/shop 系统，修复即验证
3. **配置外部化** — shop_data.json / recipes.json 与代码分离，减少硬编码
4. **物品注册模式** — 统一在 ItemDataSystem._create_default_items() 中注册所有游戏物品，避免 add_item 失败

### 需要改进
1. **UI 调试效率低** — TextureRect expand_mode/stretch_mode 属性组合花费大量时间定位，下次先查 Godot 文档
2. **手动测试流程缺失** — 应在 TDD 流程中加入"每次提交后执行一次手动冒烟测试"的步骤
3. **物品图标资产缺失** — assets/art/items/ 目录不存在，所有物品无图标，下次提前规划资产管线

---

## 下一步 (Sprint 7 候选)

| 优先级 | 任务 | 依赖 |
|--------|------|------|
| P0 | Sprint 6 Bug 修复扫尾（所有测试通过验证） | — |
| P1 | 商店系统完善（好感度折扣/动态库存） | 好感度系统 |
| P1 | 畜牧疾病 UI 暴露 | S5-T6 |
| P1 | 深度喂食逻辑 | S5-T7 |
| P2 | game_manager TODO — 存档菜单 UI | S6-T11 |
| P2 | Bug 严重性分级文档 | S6-T12 |
| P3 | 地图 UI / 任务系统 UI | HUD stub 已存在 |

---

## 指标

| 指标 | 值 |
|------|-----|
| 提交数 | 10 |
| 新增文件 | 4 (.gd 物品注册/测试 + 1 PNG 占位符) |
| 修改文件 | 14 |
| 关闭测试用例 | 30+ |
| 关键 Bug 修复 | 7 |
| Sprint Goal 完成率 | ~90% (Nice-to-Have 延期) |
