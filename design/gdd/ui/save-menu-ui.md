# 存档菜单 UI 设计 (Save Menu UI)

> **状态**: Approved
> **Author**: Dev
> **Last Updated**: 2026-04-21
> **System ID**: U08
> **Implements**: F04 SaveLoadSystem

## Overview

存档菜单 UI 为玩家提供手动存档、读取存档、以及存档管理的操作入口。界面设计遵循"简洁清晰、一目了然"的原则，支持 3 个存档槽位显示（槽位状态/玩家名/游戏天数/季节），以及新游戏/继续游戏的入口。

## Player Fantasy

玩家应该感受到：
- **清晰可辨** — 一眼能看出哪个槽位有存档、哪个是空的
- **操作安全** — 覆盖存档时有明确确认，不会意外丢失
- **快速上手** — 新游戏/继续/读取的路径无歧义

## UI Layout

```
+----------------------------------------+
|         [存档菜单]                      |
|                                        |
|  [槽位 0] 第1年 春 第1天 — 200g         |
|  [槽位 1] (空)                          |
|  [槽位 2] (空)                          |
|                                        |
|  [新游戏]          [删除]  [返回]       |
+----------------------------------------+
```

### 槽位卡片信息

每个槽位卡片显示：
- 存档名（玩家名 或 "空槽位"）
- 游戏天数（第X年 第X天）
- 季节 Emoji + 季节名
- 当前金币数量
- 存档时间（最后保存时间）
- 缩略图（可选：如果存档有截图）

### 操作按钮

| 按钮 | 位置 | 行为 |
|------|------|------|
| 存档槽位卡片 | 主体区域 | 点击 → 进入确认/加载流程 |
| 新游戏 | 底部左侧 | 弹出确认对话框后开始新游戏 |
| 删除 | 槽位旁边 | 仅在有存档时显示，弹出确认后删除 |
| 返回 | 底部右侧 | 关闭存档菜单 |

### 对话框

**覆盖确认对话框**：
```
"此槽位已有存档，是否覆盖？"
[取消]  [覆盖]
```

**删除确认对话框**：
```
"确定要删除此存档吗？此操作不可撤销。"
[取消]  [删除]
```

**新游戏确认对话框**：
```
"确定要开始新游戏吗？当前未保存的进度将丢失。"
[取消]  [开始]
```

## Component Specification

### SaveMenuPanel (主面板)

- **类型**: CanvasLayer 或 Control overlay
- **尺寸**: 居中，600×400px
- **背景**: 半透明黑色遮罩

### SaveSlotCard (存档卡片)

- **尺寸**: 560×80px
- **状态**:
  - `empty`: 显示"空槽位"，灰色背景
  - `has_save`: 显示存档信息，亮色背景
  - `hover`: 鼠标悬停，背景加亮
  - `selected`: 点击选中，金色边框

### ConfirmDialog (确认对话框)

- **类型**: 模态对话框
- **尺寸**: 300×150px
- **按钮**: 取消（默认焦点）、确认

## API Design

```gdscript
class_name SaveMenuUI extends CanvasLayer

## 显示存档菜单
func show_save_menu() -> void:
    """打开存档菜单界面"""

## 隐藏存档菜单
func hide_save_menu() -> void:
    """关闭存档菜单界面"""

## 槽位点击处理
func _on_slot_clicked(slot_index: int) -> void:
    """槽位被点击时的处理逻辑"""
    if _slots[slot_index].is_empty:
        _show_new_game_dialog(slot_index)
    else:
        _show_overwrite_dialog(slot_index)

## 删除存档
func delete_save(slot_index: int) -> void:
    """删除指定槽位的存档"""
    SaveManager.delete_save(slot_index)
    _refresh_slots()

## 开始新游戏到指定槽位
func start_new_game_to_slot(slot_index: int) -> void:
    """在新存档槽位开始游戏"""
    GameManager.start_new_game_to_slot(slot_index)
    hide_save_menu()

## 加载存档
func load_save(slot_index: int) -> void:
    """加载指定槽位的存档"""
    GameManager.continue_game(slot_index)
    hide_save_menu()
```

## Interaction Flow

```
1. 玩家按 ESC 或点击菜单按钮
2. 显示存档菜单（3个槽位卡片）
3. 玩家点击槽位：
   - 空槽位 → 新游戏确认 → 开始新游戏
   - 有存档 → 覆盖确认 → 覆盖存档并开始
4. 玩家可点击返回关闭菜单
```

## States

### SaveMenuState enum

```gdscript
enum SaveMenuState {
    MAIN,           # 主界面：显示槽位列表
    CONFIRM_NEW,    # 新游戏确认对话框
    CONFIRM_OVERWRITE, # 覆盖确认对话框
    CONFIRM_DELETE, # 删除确认对话框
}
```

### SlotState enum

```gdscript
enum SlotState {
    EMPTY,      # 空槽位
    HAS_SAVE,   # 有存档
    LOADING,    # 加载中
    SAVING,     # 保存中
}
```

## Dependency

- **SaveManager**: 存档元数据查询、删除操作
- **GameManager**: start_new_game_to_slot, continue_game
- **I18n**: 所有字符串本地化

## Edge Cases

| 场景 | 处理 |
|------|------|
| 加载不存在的存档 | 提示"存档损坏" |
| 保存时磁盘满 | 提示"存储空间不足" |
| 游戏进行中存档 | 自动存档覆盖当前槽位 |

## Acceptance Criteria

- [ ] 存档菜单可正常打开/关闭（ESC 和按钮两种方式）
- [ ] 3 个槽位状态（空/有存档）正确显示
- [ ] 点击有存档的槽位弹出覆盖确认对话框
- [ ] 点击空槽位弹出新游戏确认对话框
- [ ] 覆盖/删除确认对话框的"取消"能正确关闭对话框
- [ ] 确认后正确调用 GameManager 开始/加载游戏
- [ ] 所有字符串通过 I18n 翻译
- [ ] 游戏手柄/键盘导航可用

## TODO List for Implementation

- [ ] 创建 SaveMenuUI.tscn 场景文件
- [ ] 实现 SaveMenuUI.gd 逻辑
- [ ] 连接 GameManager.open_save_menu() 到 TODO
- [ ] 单元测试覆盖