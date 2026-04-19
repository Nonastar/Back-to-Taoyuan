extends Resource
class_name UITokens

## UI Design System Tokens
## 归园田居 - 统一界面设计系统

# ============ 颜色 Token ============

# 面板颜色
const PANEL_BG: Color = Color(0.12, 0.12, 0.16, 0.95)      # 深色背景
const PANEL_BORDER: Color = Color(0.25, 0.25, 0.32, 1.0)  # 边框色

# 按钮颜色
const BUTTON_NORMAL: Color = Color(0.2, 0.2, 0.25, 1.0)    # 按钮默认
const BUTTON_HOVER: Color = Color(0.3, 0.3, 0.38, 1.0)    # 按钮悬停
const BUTTON_PRESSED: Color = Color(0.15, 0.15, 0.2, 1.0) # 按钮按下
const BUTTON_DISABLED: Color = Color(0.1, 0.1, 0.12, 1.0) # 按钮禁用

# 文字颜色
const TEXT_PRIMARY: Color = Color(0.95, 0.95, 0.95, 1.0)  # 主要文字
const TEXT_SECONDARY: Color = Color(0.7, 0.7, 0.75, 1.0)  # 次要文字
const TEXT_MUTED: Color = Color(0.5, 0.5, 0.55, 1.0)     # 暗淡文字

# 功能颜色
const ACCENT_GREEN: Color = Color(0.18, 0.8, 0.44, 1.0)   # 确认/成功
const ACCENT_RED: Color = Color(0.91, 0.3, 0.24, 1.0)     # 错误/警告
const ACCENT_GOLD: Color = Color(1.0, 0.84, 0.0, 1.0)     # 金币/重要

# ============ 间距 Token ============

const SPACE_4: int = 4   # 紧凑间距
const SPACE_8: int = 8   # 标准小间距
const SPACE_12: int = 12 # 中等间距
const SPACE_16: int = 16 # 标准大间距
const SPACE_24: int = 24 # 宽松间距
const SPACE_32: int = 32 # 特大间距

# ============ 圆角 Token ============

const RADIUS_SM: float = 4.0  # 小圆角
const RADIUS_MD: float = 8.0  # 中等圆角
const RADIUS_LG: float = 12.0 # 大圆角

# ============ 字体大小 Token ============

const FONT_SIZE_SM: int = 12  # 小字体
const FONT_SIZE_MD: int = 14  # 中等字体
const FONT_SIZE_LG: int = 16  # 大字体
const FONT_SIZE_XL: int = 20  # 特大字体

# ============ 尺寸 Token ============

const BUTTON_HEIGHT: int = 44
const BUTTON_WIDTH_SM: int = 60
const BUTTON_WIDTH_MD: int = 100
const BUTTON_WIDTH_LG: int = 140
const ICON_SIZE: int = 24
const PANEL_HEADER_HEIGHT: int = 50
