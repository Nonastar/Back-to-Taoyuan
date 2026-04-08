# 单元测试指南

## 概述

本项目使用基于GDScript的轻量级测试框架，包含单元测试和集成测试。

## 测试结构

```
tests/
├── unit/                    # 单元测试
│   ├── test_base.gd        # 测试基类
│   ├── quality_test.gd     # 品质枚举测试
│   ├── item_category_test.gd # 物品分类测试
│   ├── weather_system_test.gd # 天气系统测试
│   └── player_stats_test.gd  # 玩家属性测试
├── integration/             # 集成测试 (待实现)
├── test_runner.gd          # 测试运行器
└── gut-plugin-config.json  # GUT配置
```

## 运行测试

### 方法1: 使用测试运行器 (命令行)

```bash
# 在项目目录中运行
godot --path . --script tests/test_runner.gd
```

### 方法2: 在Godot编辑器中运行

1. 打开Godot编辑器
2. 打开测试场景或直接运行测试脚本
3. 查看输出面板的测试结果

## 编写测试

### 基本结构

```gdscript
extends "res://tests/unit/test_base.gd"

## 测试说明
func test_example():
    # 使用断言
    assert_eq(actual, expected, "可选的错误消息")
    assert_true(condition, "条件应为真")
    assert_false(condition, "条件应为假")
    assert_almost_eq(actual, expected, tolerance, "浮点数近似比较")
```

### before_each / after_each

```gdscript
var _my_system: Node = null

func before_each():
    # 每个测试前运行
    _my_system = create_test_instance()

func after_each():
    # 每个测试后运行
    _my_system.free()
```

### 可用的断言

| 方法 | 说明 |
|------|------|
| `assert_true(condition, msg?)` | 断言为真 |
| `assert_false(condition, msg?)` | 断言为假 |
| `assert_eq(actual, expected, msg?)` | 断言相等 |
| `assert_ne(actual, expected, msg?)` | 断言不相等 |
| `assert_gt(a, b, msg?)` | a > b |
| `assert_lt(a, b, msg?)` | a < b |
| `assert_ge(a, b, msg?)` | a >= b |
| `assert_le(a, b, msg?)` | a <= b |
| `assert_almost_eq(a, b, tol, msg?)` | 浮点数近似 |
| `assert_null(value, msg?)` | 断言为空 |
| `assert_not_null(value, msg?)` | 断言非空 |
| `assert_array_contains(arr, val, msg?)` | 数组包含 |
| `assert_dict_has_key(dict, key, msg?)` | 字典有键 |

## 测试规范

### 命名规范

- 测试文件: `xxx_test.gd`
- 测试类: `XXXTest`
- 测试方法: `test_xxx_yyy()`

### 覆盖范围目标

| 系统 | 覆盖率目标 | 当前状态 |
|------|-----------|---------|
| Quality | 100% | ✅ |
| ItemCategory | 100% | ✅ |
| WeatherSystem | 80% | ✅ |
| PlayerStats | 80% | ✅ |
| InventorySystem | 60% | 待实现 |
| ItemDataSystem | 60% | 待实现 |

## CI/CD集成

测试可以在CI管道中运行:

```bash
#!/bin/bash
godot --path . --script tests/test_runner.gd > test_output.txt 2>&1
if grep -q "失败: 0" test_output.txt; then
    echo "所有测试通过"
    exit 0
else
    echo "有测试失败"
    exit 1
fi
```

## 报告问题

如果发现测试失败，请检查:

1. 测试是否正确反映了预期行为
2. 被测代码是否有Bug
3. 断言是否正确

使用 `push_error()` 输出的内容会显示在控制台中。
