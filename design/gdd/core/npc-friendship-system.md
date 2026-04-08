# NPC好感度系统 (NPCFriendshipSystem)

> **状态**: In Design
> **Author**: Claude Code
> **Last Updated**: 2026-04-03
> **System ID**: C07
> **Implements Pillar**: 社交与关系系统

## Overview

NPC好感度系统管理玩家与34个NPC之间的社交关系。系统包含好感度等级、每日互动（对话/送礼）、恋爱结婚、知己结交、孕期养成、子女成长等完整社交内容。通过与NPC建立深厚关系，玩家可以解锁独特剧情、获得雇佣帮手、最终组建家庭。

系统是游戏情感体验的核心——每个NPC都有独特的性格、喜好和故事，关系的深入带来剧情的展开和游戏的丰富度。

## Player Fantasy

NPC好感度系统给玩家带来**温暖的羁绊感**。玩家应该感受到：

- **交朋友的乐趣** — 每个NPC都有独特的对话和故事，聊天和送礼让人感到建立联系
- **被记住的满足** — NPC会记住你的名字、你们的关系程度，关系越深对话越亲密
- **追求的甜蜜** — 恋爱结婚是一条漫长的道路，需要耐心和投入
- **知己难寻的珍贵** — 知己是同性NPC之间的深层羁绊，与恋爱平行的另一条路
- **家庭港湾的温馨** — 有了配偶和孩子，农场不仅是生产的地方，更是家

**Reference games**: Stardew Valley 的NPC关系系统让每个角色都有独特的存在感；Animal Crossing 的社交互动带来每日的小确幸。

## Detailed Design

### Core Rules

1. **好感度系统**
   - 好感度范围: 0-2500 (10心制，每心250点)
   - 好感等级阈值:
     | 等级 | 英文 | 好感度要求 |
     |------|------|------------|
     | 陌生人 | stranger | 0-499 |
     | 熟人 | acquaintance | 500-999 |
     | 友好 | friendly | 1000-1999 |
     | 挚友 | bestFriend | 2000-2500 |

2. **NPC分类**
   - **可婚NPC**: 12人（6原 + 6新增）
   - **不可婚NPC**: 22人
   - 每位NPC有独特的好恶物品列表

3. **每日互动**
   - **对话**: 每天1次，+20好感度
   - **送礼**: 每天1次，每周上限2次
   - 送礼好感度计算:
     | 反应 | 基础好感 |
     |------|----------|
     | 非常喜欢 | +80 |
     | 还不错 | +45 |
     | 一般 | +20 |
     | 讨厌 | -40 |
   - 品质加成: 普通1.0x, 优良1.25x, 优秀1.5x, 极品2.0x
   - 生日加成: 4倍（当天送礼物）

4. **恋爱系统**
   - **赠帕约会**: 需要8心(2000好感) + 丝帕道具
   - **求婚**: 需要先约会 + 10心(2500好感) + 翡翠戒指
   - **婚礼**: 求婚后3天举行
   - 结婚后好感度固定在3500

5. **知己系统** (同性专属)
   - **赠玉结交**: 需要8心(2000好感) + 知己玉佩
   - 与恋爱平行，只能选择一个
   - 已婚后不可再结交知己

6. **配偶对话/行为**
   - 每天有专属对话（按季节、天气变化）
   - 不聊天会降低好感度（-10/天）
   - 结婚后不降低至1000以下

7. **雇工系统**
   - 雇佣好感度≥4心的NPC
   - 最多同时雇佣2人
   - 任务类型: 浇水/喂食/收获/除草/装饵
   - 每日扣除工资
   - 结婚/结交知己后自动离职

8. **心事件系统**
   - 好感度达标后触发
   - 每个可婚NPC有3个恋爱心事件
   - 知己NPC有2个知己专属心事件
   - 包含场景对话和分支选择

9. **孕期养成**
   - **阶段**: 初期(5天) → 中期(5天) → 后期(5天) → 待产(3天)
   - **照料方式**: 送礼物/陪伴/进补/休息
   - **接生方式**: 普通/高级/豪华（影响成功率）
   - 成功率 = 基础率 + 安产分加成(最高+15%)

10. **子女系统**
    - 最多2个子女
    - 成长阶段: 婴儿 → 幼儿 → 儿童 → 青少年
    - 每日互动增加好感度
    - 儿童期可能带回随机物品

### States and Transitions

### NPC状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **Single** | 未婚/未结交知己 | 初始状态 |
| **Dating** | 约会中 | 赠帕成功后 |
| **Zhiji** | 知己关系 | 赠玉成功后 |
| **Engaged** | 求婚待婚 | 求婚成功，婚礼倒计时中 |
| **Married** | 已结婚 | 婚礼完成 |

### 关系状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **SingleNPC** | 普通NPC | 未达挚友 |
| **BestFriend** | 挚友 | 好感度≥2000 |
| **Hired** | 被雇佣 | 雇佣成功后 |

### 孕期状态

| 状态 | 描述 | 触发条件 |
|------|------|----------|
| **NotPregnant** | 无孕期 | 初始状态 |
| **EarlyPregnancy** | 孕初期 | 接受要孩子 |
| **MidPregnancy** | 孕中期 | 孕初期结束 |
| **LatePregnancy** | 孕后期 | 孕中期结束 |
| **ReadyToDeliver** | 待产 | 孕后期结束 |

### 子女成长阶段

| 阶段 | 描述 | 触发条件 |
|------|------|----------|
| **Baby** | 婴儿 | 出生后0-13天 |
| **Toddler** | 幼儿 | 14-27天 |
| **Child** | 儿童 | 28-55天 |
| **Teen** | 青少年 | 56+天 |

### Interactions with Other Systems

### 系统交互矩阵

| 依赖系统 | 依赖类型 | 输入 | 输出 | 接口说明 |
|----------|----------|------|------|----------|
| **F03 ItemDataSystem** | 硬依赖 | - | 物品定义 | 查询礼物物品名称 |
| **C02 InventorySystem** | 硬依赖 | 物品检查/扣除 | 结果 | removeItem() 送礼 |
| **C01 PlayerStatsSystem** | 软依赖 | 玩家名称/称谓 | NPC对话 | playerName, gender |
| **F01 TimeSeasonSystem** | 硬依赖 | 日期/季节变化 | 每日重置 | dailyReset() |

### API 设计

```gdscript
class_name NpcFriendshipSystem extends Node

## 单例访问
static func get_instance() -> NpcFriendshipSystem

## 好感度 API
func talk_to(npc_id: String) -> Dictionary:
    """与NPC对话，返回 {message, friendshipGain}"""

func give_gift(npc_id: String, item_id: String, quality: String) -> Dictionary:
    """送礼，返回 {gain, reaction}"""

func get_friendship(npc_id: String) -> int
func get_friendship_level(npc_id: String) -> String

## 恋爱/知己 API
func start_dating(npc_id: String) -> bool
func propose(npc_id: String) -> bool
func become_zhiji(npc_id: String) -> bool

## 雇工 API
func hire_helper(npc_id: String, task: String) -> bool
func dismiss_helper(npc_id: String) -> bool
func get_hired_helpers() -> Array

## 心事件 API
func check_heart_event(npc_id: String) -> HeartEventDef | null
func trigger_heart_event(npc_id: String, event_id: String)

## 孕期/子女 API
func check_child_proposal() -> bool
func respond_to_proposal(response: String) -> bool
func perform_pregnancy_care(action: String) -> bool
func get_children() -> Array

## 每日更新
func daily_reset()
func daily_pregnancy_update() -> Dictionary
func daily_child_update()
```

## Formulas

### 1. 送礼好感度计算

```
base_gain =
    if item in loved_items: 80
    elif item in liked_items: 45
    elif item in hated_items: -40
    else: 20

quality_multiplier = { normal: 1.0, fine: 1.25, excellent: 1.5, supreme: 2.0 }
birthday_multiplier = is_birthday ? 4.0 : 1.0

final_gain = floor(base_gain × quality_multiplier × birthday_multiplier)
friendship = max(0, friendship + final_gain)
```

### 2. 心事件触发判定

```
# 满足条件时触发
if friendship >= event.required_friendship
    and event not in triggered_events
    and (not event.requires_zhiji or state.zhiji)
    and not (state.zhiji and event.id.ends_with('_heart_8')):  # 知己不触发告白
    trigger_event()
```

### 3. 孕期成功率计算

```
# 基础成功率 + 安产分加成
care_bonus = (care_score / 100) × 0.15  # 最高15%
total_success_rate = min(1.0, base_success_rate + care_bonus)

# 医疗方案基础率: normal=0.8, advanced=0.95, luxury=1.0
```

### 4. 雇工效率计算

```
efficiency = friendship >= 2000 ? 1.5 : 1.0

# 浇水: 4×效率 + 0~2随机
water_count = min(unwatered_plots, floor(4 × efficiency) + rand(0,2))

# 收获: 5×效率
harvest_count = min(harvestable_plots, floor(5 × efficiency))
```

### 5. 每日好感衰减

```
if not talked_today and state.married:
    friendship = max(1000, friendship - 10)  # 不降至1000以下
if not talked_today and state.zhiji:
    friendship = max(0, friendship - 5)
```

### 变量定义表

| 变量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `MAX_FRIENDSHIP` | int | 2500 | 最大好感度 |
| `HEARTS_COUNT` | int | 10 | 总心数 |
| `FRIENDSHIP_PER_HEART` | int | 250 | 每心好感度 |
| `TALK_FRIENDSHIP_GAIN` | int | 20 | 对话好感增加 |
| `LOVED_GIFT_BASE` | int | 80 | 喜爱礼物基础好感 |
| `BIRTHDAY_MULTIPLIER` | float | 4.0 | 生日加成倍数 |
| `DAILY_MARRIED_DECAY` | int | 10 | 配偶每日衰减 |
| `DAILY_ZHIJI_DECAY` | int | 5 | 知己每日衰减 |
| `PREGNANCY_MIN_CARE_SCORE` | int | 40 | 早产阈值 |
| `PREGNANCY_MAX_CARE_SCORE` | int | 80 | 健康阈值 |

## Edge Cases

### 1. 同一天多次对话/送礼
- **场景**: 玩家尝试在同一天与同一NPC多次对话
- **处理**: 返回失败，提示"今天已经聊过了"

### 2. 向非可婚NPC求婚
- **场景**: 尝试向不可婚NPC求婚
- **处理**: 返回失败，提示"此人无法求婚"

### 3. 向同性NPC求爱
- **场景**: 男性角色向男性NPC求爱
- **处理**: 返回失败，提示"只能向异性求婚"

### 4. 已有配偶时再求婚
- **场景**: 已经结婚后尝试向其他人求婚
- **处理**: 返回失败，提示"你已经结婚了"

### 5. 约会未开始就求婚
- **场景**: 未赠帕就开始约会就求婚
- **处理**: 返回失败，提示"需要先赠帕约会"

### 6. 知己和恋爱冲突
- **场景**: 已经约会后尝试结交知己
- **处理**: 返回失败，提示"无法与恋人结为知己"

### 7. 孕期中再次提议要孩子
- **场景**: 配偶已怀孕后再次提议
- **处理**: 返回 false，孕期中不触发新提议

### 8. 难产处理
- **场景**: 医疗方案成功率不足
- **处理**: 触发流产，配偶好感-200

### 9. 旧存档好感度迁移
- **场景**: 加载v1.0存档（300制好感度）
- **处理**: 好感度 × 8，迁移至2500制

### 10. 子女名字重复
- **场景**: 第二个孩子出生时名字池耗尽
- **处理**: 使用默认名字"小宝"

## Dependencies

### 上游依赖（C07 依赖其他系统）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **F03** | ItemDataSystem | 硬依赖 | 查询物品定义（名称、好恶列表） |
| **C02** | InventorySystem | 硬依赖 | 物品检查/扣除，送礼 |
| **C01** | PlayerStatsSystem | 软依赖 | 玩家名称、性别 |
| **F01** | TimeSeasonSystem | 硬依赖 | 日期/季节变化触发每日重置 |

### 下游依赖（其他系统依赖 C07）

| 系统 ID | 系统名称 | 依赖类型 | 接口说明 |
|---------|----------|----------|----------|
| **P08** | QuestSystem | 软依赖 | NPC好感度任务 |
| **P15** | DialogueEventSystem | 硬依赖 | 心事件对话 |
| **F04** | SaveLoadSystem | 硬依赖 | 存档所有NPC状态 |

## Tuning Knobs

### 好感度配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `MAX_FRIENDSHIP` | 2500 | 2000-3000 | 最大好感度 |
| `FRIENDSHIP_PER_HEART` | 250 | 固定 | 每心好感度 |
| `TALK_FRIENDSHIP_GAIN` | 20 | 10-30 | 对话好感增加 |
| `LOVED_GIFT_GAIN` | 80 | 60-100 | 喜爱礼物好感 |
| `LIKED_GIFT_GAIN` | 45 | 30-60 | 喜欢礼物好感 |
| `NEUTRAL_GIFT_GAIN` | 20 | 10-30 | 普通礼物好感 |
| `HATED_GIFT_GAIN` | -40 | -60--20 | 讨厌礼物好感 |
| `BIRTHDAY_MULTIPLIER` | 4.0 | 2.0-8.0 | 生日加成倍数 |
| `MAX_HEARTS` | 10 | 8-12 | 总心数 |

### 恋爱系统配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `DATING_REQUIREMENT` | 2000 | 1500-2500 | 约会好感度要求 |
| `MARRIAGE_REQUIREMENT` | 2500 | 2000-3000 | 结婚好感度要求 |
| `WEDDING_COUNTDOWN` | 3 | 2-7 | 婚礼倒计时天数 |

### 孕期配置

| 参数名 | 默认值 | 安全范围 | 说明 |
|--------|--------|----------|------|
| `PREGNANCY_EARLY_DAYS` | 5 | 3-7 | 孕初期天数 |
| `PREGNANCY_MID_DAYS` | 5 | 3-7 | 孕中期天数 |
| `PREGNANCY_LATE_DAYS` | 5 | 3-7 | 孕后期天数 |
| `PREGNANCY_READY_DAYS` | 3 | 2-5 | 待产天数 |
| `NORMAL_BIRTH_SUCCESS` | 0.8 | 0.6-0.9 | 普通接生成功率 |
| `ADVANCED_BIRTH_SUCCESS` | 0.95 | 0.9-1.0 | 高级接生成功率 |
| `MAX_CHILDREN` | 2 | 1-4 | 最大子女数 |

## Visual/Audio Requirements

### 视觉效果
- **好感度显示**: 心形图标显示好感度等级
- **送礼反应**: 角色头像表情变化（笑脸/爱心/讨厌）
- **心事件**: 剧情场景以对话框形式呈现

### 音效
- **送礼音效**: 收到礼物时播放轻柔音效
- **好感升级**: 好感度提升时播放心跳音效
- **婚礼音效**: 婚礼场景播放喜庆音乐

## UI Requirements

### 社交界面
- **角色详情面板**: 头像、名称、当前好感度、关系状态
- **好恶物品列表**: 显示NPC喜欢的和讨厌的物品
- **对话历史**: NPC对话记录

### 互动界面
- **送礼面板**: 物品选择、品质显示、反应预览
- **雇工面板**: 可雇佣NPC列表、任务选择

### 家庭界面
- **配偶/知己面板**: 关系详情、互动选项
- **孕期面板**: 当前阶段、照料选项
- **子女面板**: 子女列表、成长阶段

## Acceptance Criteria

### 功能验收标准

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **AC-01** | 对话增加好感 | 每日首次对话验证+20 |
| **AC-02** | 送礼计算正确 | 测试各种物品/品质/生日加成 |
| **AC-03** | 恋爱流程完整 | 赠帕→约会→求婚→婚礼 |
| **AC-04** | 知己流程完整 | 赠玉→知己→专属对话 |
| **AC-05** | 雇工系统正常 | 雇佣→每日任务→发工资→离职 |
| **AC-06** | 孕期流程完整 | 提议→接受→照料→分娩 |
| **AC-07** | 子女成长正常 | 出生→成长→互动 |

### 跨系统集成测试

| ID | 验收标准 | 测试方法 |
|----|----------|----------|
| **CS-01** | 存档完整 | 保存加载后所有NPC状态恢复 |
| **CS-02** | 每日重置 | 验证对话/送礼状态重置 |
| **CS-03** | 雇工调用 | 验证浇水/喂食等实际生效 |

## Open Questions

| # | 问题 | 状态 | 负责人 | 目标日期 |
|---|------|------|--------|----------|
| **OQ-01** | 离婚后是否可以有新的恋爱/知己？ | 待决定 | 策划 | v1.0 |
| **OQ-02** | 子女是否可以有更多互动？ | 待决定 | 策划 | v1.0+ |
| **OQ-03** | 是否有子女结婚/离家的剧情？ | 待决定 | 策划 | v2.0 |
