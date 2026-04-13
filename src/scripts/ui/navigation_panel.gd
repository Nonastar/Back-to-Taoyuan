extends CanvasLayer

## NavigationPanel - 导航面板
## 底部导航栏，允许玩家切换区域

# ============ 常量 ============

## 地点组颜色
const GROUP_COLORS: Dictionary = {
	"farm": Color(0.2, 0.8, 0.4, 1),      # 绿色
	"village": Color(0.9, 0.7, 0.3, 1),  # 金色
	"nature": Color(0.3, 0.7, 0.3, 1),    # 深绿
	"mine": Color(0.6, 0.5, 0.7, 1),      # 紫色
	"hanhai": Color(0.9, 0.8, 0.5, 1)    # 沙色
}

## 面板信息
const PANEL_INFO: Dictionary = {
	# 农场区域
	"farm": {"name": "农场", "group": "farm", "emoji": "🌾"},
	"animal": {"name": "畜棚", "group": "farm", "emoji": "🐄"},
	"home": {"name": "家中", "group": "farm", "emoji": "🏠"},
	"fishpond": {"name": "鱼塘", "group": "farm", "emoji": "🐟"},
	# 桃源村
	"village": {"name": "村落", "group": "village", "emoji": "🏘️"},
	"shop": {"name": "商店", "group": "village", "emoji": "🛒"},
	"cooking": {"name": "烹饪", "group": "village", "emoji": "🍳"},
	"upgrade": {"name": "工坊", "group": "village", "emoji": "🔧"},
	# 野外
	"forage": {"name": "采集", "group": "nature", "emoji": "🌿"},
	"fishing": {"name": "钓鱼", "group": "nature", "emoji": "🎣"},
	# 矿洞
	"mining": {"name": "采矿", "group": "mine", "emoji": "💎"},
	# 瀚海
	"hanhai": {"name": "瀚海", "group": "hanhai", "emoji": "🏜️"}
}

## 无地点面板
const NO_LOCATION_PANELS: Array = ["inventory", "skills", "achievement", "charinfo"]

# ============ 节点引用 ============

var panel_container: HBoxContainer
var panel_buttons: Dictionary = {}
var current_panel: String = "farm"

# ============ 状态 ============

var _expanded: bool = false
var _current_group: String = "farm"

## 需要钓鱼按钮的场景
const FISHING_BUTTON_SCENES: Array = ["fishpond", "fishing"]

## 需要工具栏的场景
const TOOLBAR_SCENES: Array = ["farm"]

# ============ 初始化 ============

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_update_display()

## 设置 UI
func _setup_ui() -> void:
	# 底部导航容器
	var nav_bg = ColorRect.new()
	nav_bg.name = "NavBG"
	nav_bg.color = Color(0, 0, 0, 0.7)
	nav_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav_bg.offset_top = -120
	nav_bg.size = Vector2(1280, 120)
	add_child(nav_bg)

	# 面板容器
	panel_container = HBoxContainer.new()
	panel_container.name = "PanelContainer"
	panel_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel_container.offset_top = -110
	panel_container.offset_bottom = -10
	panel_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(panel_container)

	# 创建所有面板按钮
	_create_all_buttons()

## 创建所有按钮
func _create_all_buttons() -> void:
	# 按组分类显示
	var groups: Array = ["farm", "village", "nature", "mine", "hanhai"]

	for group in groups:
		# 组标签
		var group_label = Label.new()
		group_label.name = "Group_%s" % group
		group_label.text = _get_group_emoji(group)
		group_label.add_theme_font_size_override("font_size", 16)
		group_label.add_theme_color_override("font_color", GROUP_COLORS.get(group, Color.WHITE))
		panel_container.add_child(group_label)

		# 该组的所有面板
		for panel_key in PANEL_INFO:
			var info = PANEL_INFO[panel_key]
			if info["group"] == group:
				var btn = _create_panel_button(panel_key, info)
				panel_buttons[panel_key] = btn
				panel_container.add_child(btn)

		# 组间距
		var spacer = Control.new()
		spacer.custom_minimum_size.x = 20
		panel_container.add_child(spacer)

## 创建面板按钮
func _create_panel_button(panel_key: String, info: Dictionary) -> Button:
	var btn = Button.new()
	btn.name = "Btn_%s" % panel_key
	btn.custom_minimum_size = Vector2(70, 60)

	# 内容
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var emoji_label = Label.new()
	emoji_label.text = info["emoji"]
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(emoji_label)

	var name_label = Label.new()
	name_label.text = info["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(name_label)

	btn.add_child(vbox)

	# 连接信号
	btn.pressed.connect(_on_panel_button_pressed.bind(panel_key))

	return btn

## 获取组 Emoji
func _get_group_emoji(group: String) -> String:
	match group:
		"farm": return "🏠"
		"village": return "🏘️"
		"nature": return "🌲"
		"mine": return "⛏️"
		"hanhai": return "🏜️"
		_: return "📍"

# ============ 信号连接 ============

func _connect_signals() -> void:
	# EventBus 面板变化信号
	if EventBus and EventBus.has_signal("panel_changed"):
		EventBus.panel_changed.connect(_on_panel_changed)

	# NavigationSystem 位置变化信号
	if NavigationSystem and NavigationSystem.has_signal("location_changed"):
		NavigationSystem.location_changed.connect(_on_location_changed)

	# 旅行相关信号
	if NavigationSystem and NavigationSystem.has_signal("travel_started"):
		NavigationSystem.travel_started.connect(_on_travel_started)
	if NavigationSystem and NavigationSystem.has_signal("shop_access_denied"):
		NavigationSystem.shop_access_denied.connect(_on_shop_access_denied)
	if NavigationSystem and NavigationSystem.has_signal("past_bedtime"):
		NavigationSystem.past_bedtime.connect(_on_past_bedtime)

## 面板按钮被点击
func _on_panel_button_pressed(panel_key: String) -> void:
	# 钓鱼面板特殊处理
	if panel_key == "fishing":
		_on_fishing_selected()
		return

	if not NavigationSystem:
		return

	# 检查是否是室内场景
	var scene_path = NavigationSystem.get_panel_scene(panel_key)
	if _is_interior_panel(panel_key):
		_load_interior(panel_key, scene_path)
		return

	# 检查是否是世界场景（室内场景返回 false）
	if _is_world_panel(panel_key):
		_switch_world(panel_key, scene_path)
		return

	# 获取旅行消耗预览
	var cost = NavigationSystem.get_travel_cost(panel_key)

	# 检查是否可以前往
	if not NavigationSystem.can_navigate_to(panel_key):
		_show_cannot_navigate_message(panel_key)
		return

	# 执行导航
	var result = NavigationSystem.navigate_to_panel(panel_key)

	if result.get("success", false):
		# 显示旅行信息
		if result.get("is_travel", false):
			var time_cost = result.get("time_cost", 0.0)
			var stamina_cost = result.get("stamina_cost", 0)
			var minutes = int(time_cost * 60)
			var msg = "前往%s" % PANEL_INFO.get(panel_key, {}).get("name", panel_key)
			if minutes > 0:
				msg += " (花费%d分钟" % minutes
				if stamina_cost > 0:
					msg += ", %d体力" % stamina_cost
				msg += ")"
			_show_travel_message(msg)
	else:
		# 显示失败原因
		var reason = result.get("reason", "无法前往")
		_show_error_message(reason)

## 检查是否为室内面板
func _is_interior_panel(panel_key: String) -> bool:
	# 检查是否是室内场景（通过 NavigationSystem 的 scene 字段判断）
	if NavigationSystem:
		var panel_data = NavigationSystem.get_panel_info(panel_key)
		if panel_data and panel_data.has("scene"):
			return not panel_data["scene"].is_empty()
	# 如果没有 scene 字段，检查是否在室内路径表中
	if SceneManager and SceneManager.INTERIOR_PATHS.has(panel_key):
		return true
	return false

## 检查是否是世界场景
func _is_world_panel(panel_key: String) -> bool:
	# 检查是否在 WorldPaths 中
	if SceneManager and SceneManager.WORLD_PATHS.has(panel_key):
		return true
	# 检查是否没有 scene 字段且不是室内
	if NavigationSystem:
		var panel_data = NavigationSystem.get_panel_info(panel_key)
		if panel_data.is_empty():
			return false
		# 如果没有 scene 字段，检查是否是导航区域组
		if not panel_data.has("scene") or panel_data["scene"].is_empty():
			var group = panel_data.get("group", -1)
			# 农场、村落、野外、矿洞、瀚海都是世界区域
			return group in [0, 1, 2, 3, 4]
	return false

## 加载室内场景
func _load_interior(panel_key: String, scene_path: String) -> void:
	if SceneManager:
		var success = SceneManager.load_interior(panel_key)
		if success:
			_show_travel_message("进入%s" % PANEL_INFO.get(panel_key, {}).get("name", panel_key))
		else:
			_show_error_message("无法进入该地点")
	else:
		push_error("[NavigationPanel] SceneManager not found")

## 切换世界场景
func _switch_world(panel_key: String, scene_path: String) -> void:
	print("[NavigationPanel] Switching world: " + str(panel_key))

	if SceneManager:
		var success = SceneManager.switch_world(panel_key)
		if success:
			_show_travel_message("前往%s" % PANEL_INFO.get(panel_key, {}).get("name", panel_key))
		else:
			_show_error_message("无法前往该地点")
	else:
		push_error("[NavigationPanel] SceneManager not found")

## 面板变化回调
func _on_panel_changed(panel_key: String) -> void:
	current_panel = panel_key
	_update_button_styles()
	_update_fishing_button_visibility()
	_update_toolbar_visibility()

## 位置变化回调
func _on_location_changed(new_group: int, old_group: int) -> void:
	var group_name = NavigationSystem.get_current_group_name().to_lower()
	_current_group = group_name
	_update_button_styles()
	_update_fishing_button_visibility()
	_update_toolbar_visibility()

## 旅行开始
func _on_travel_started(time_cost: float, stamina_cost: int) -> void:
	# 可以在这里播放旅行动画
	pass

## 商店拒绝访问
func _on_shop_access_denied(panel_key: String, reason: String) -> void:
	_show_error_message(reason)

## 就寝时间
func _on_past_bedtime() -> void:
	_show_error_message("已经深夜，无法出行！")

## 钓鱼按钮点击
func _on_fishing_selected() -> void:
	print("[NavPanel] _on_fishing_selected called")
	print("[NavPanel]   current_panel: " + str(current_panel))
	print("[NavPanel]   current_interior: " + str(SceneManager.get_current_interior() if SceneManager else "N/A"))

	# 获取当前钓鱼地点
	var fishing_location = _get_current_fishing_location()
	print("[NavPanel] Fishing location: " + str(fishing_location))

	# 检查是否已经在该钓鱼场景内
	if SceneManager and SceneManager.get_current_interior() == fishing_location:
		print("[NavPanel] Already in fishing interior, just starting fishing system")
		# 已经在鱼塘内，直接启动钓鱼系统（如果尚未开始）
		if FishingSystem and not FishingSystem.is_fishing():
			FishingSystem.start_fishing(fishing_location)
			print("[NavPanel] Fishing started (was already in location)")
			_show_travel_message("开始钓鱼: " + _get_location_display_name(fishing_location))
	else:
		# 加载鱼塘室内场景（这会卸载农场场景）
		print("[NavPanel] Loading new interior: " + str(fishing_location))
		if SceneManager:
			var success = SceneManager.load_interior(fishing_location)
			print("[NavPanel] load_interior result: " + str(success))
			if not success:
				_show_error_message("无法进入钓鱼区域")
				_update_fishing_button_visibility()
				return

		# 启动钓鱼系统
		if FishingSystem:
			FishingSystem.start_fishing(fishing_location)
			print("[NavPanel] Fishing started at: " + str(fishing_location))
			_show_travel_message("开始钓鱼: " + _get_location_display_name(fishing_location))
		else:
			push_error("[NavPanel] FishingSystem not found!")

	# 确保钓鱼按钮保持可见
	_update_fishing_button_visibility()

## 获取当前钓鱼地点
func _get_current_fishing_location() -> String:
	# 根据当前位置组确定钓鱼地点
	# 注意：如果已经在鱼塘内，返回 fishpond
	if SceneManager:
		var current_int = SceneManager.get_current_interior()
		if current_int in ["fishpond", "river", "forest_pond", "mountain_lake", "ocean"]:
			return current_int

	if NavigationSystem:
		var group = NavigationSystem.get_current_group_name().to_lower()
		match group:
			"farm":
				return "fishpond"
			"village":
				return "river"
			"nature":
				return "forest_pond"
			"mine":
				return "mountain_lake"
			"hanhai":
				return "ocean"
	return "fishpond"  # 默认返回鱼塘

## 获取地点显示名称
func _get_location_display_name(location_id: String) -> String:
	var names: Dictionary = {
		"fishpond": "鱼塘",
		"river": "河流",
		"forest_pond": "森林池塘",
		"mountain_lake": "高山湖泊",
		"ocean": "海洋",
		"witch_swamp": "女巫沼泽",
		"secret_pond": "隐秘池塘"
	}
	return names.get(location_id, location_id)

# ============ 显示更新 ============

## 更新显示
func _update_display() -> void:
	if NavigationSystem:
		current_panel = NavigationSystem.current_panel
	_current_group = _get_panel_group(current_panel)
	_update_button_styles()
	_update_fishing_button_visibility()
	_update_toolbar_visibility()

## 更新钓鱼按钮可见性
func _update_fishing_button_visibility() -> void:
	if not panel_buttons.has("fishing"):
		return

	var fishing_btn = panel_buttons["fishing"]
	var should_show = current_panel in FISHING_BUTTON_SCENES

	if fishing_btn.visible != should_show:
		fishing_btn.visible = should_show

## 更新工具栏可见性
func _update_toolbar_visibility() -> void:
	var should_show = current_panel in TOOLBAR_SCENES

	# 动态查找 HUD 节点
	var hud = _find_hud()
	if hud:
		if hud.has_method("set_farming_tools_visible"):
			hud.set_farming_tools_visible(should_show)
	else:
		print("[NavigationPanel] HUD node not found")

## 查找 HUD 节点
func _find_hud() -> Node:
	# 方法1: 通过节点组（最可靠）
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		return hud

	# 方法2: 尝试从当前节点向上查找
	var current = get_node(".")
	while current:
		if current.name == "HUD":
			return current
		current = current.get_parent()

	# 方法3: 直接尝试常见路径
	var root = get_tree().root
	var main = root.get_node_or_null("Main")
	if main:
		var ui_layer = main.get_node_or_null("UILayer")
		if ui_layer:
			return ui_layer.get_node_or_null("HUD")
		return main.get_node_or_null("HUD")

	return null

## 更新按钮样式
func _update_button_styles() -> void:
	for panel_key in panel_buttons:
		var btn = panel_buttons[panel_key]
		var info = PANEL_INFO.get(panel_key, {})
		var group = info.get("group", "farm")

		# 钓鱼按钮永远不禁用
		if panel_key == "fishing":
			btn.disabled = false

		# 创建样式
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.content_margin_left = 4
		style.content_margin_top = 4
		style.content_margin_right = 4
		style.content_margin_bottom = 4

		# 当前面板
		if panel_key == current_panel:
			style.bg_color = GROUP_COLORS.get(group, Color.GRAY) * 0.5
			style.border_color = GROUP_COLORS.get(group, Color.GRAY)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
		else:
			style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
			style.border_color = Color(0.3, 0.3, 0.4, 0.5)
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

		# 检查是否可以访问
		if NavigationSystem:
			var can_access = NavigationSystem.can_navigate_to(panel_key)
			btn.disabled = not can_access
			if not can_access:
				var disabled_style = StyleBoxFlat.new()
				disabled_style.bg_color = Color(0.1, 0.1, 0.1, 0.5)
				btn.add_theme_stylebox_override("disabled", disabled_style)

## 获取面板所属组
func _get_panel_group(panel_key: String) -> String:
	var info = PANEL_INFO.get(panel_key, {})
	return info.get("group", "farm")

# ============ 消息显示 ============

func _show_travel_message(msg: String) -> void:
	if EventBus and EventBus.has_signal("notification_show"):
		EventBus.notification_show.emit(msg, 2.0)

func _show_error_message(msg: String) -> void:
	if EventBus and EventBus.has_signal("notification_show"):
		EventBus.notification_show.emit(msg, 3.0)

## 获取商店营业状态
func _get_shop_status(panel_key: String) -> Dictionary:
	if not NavigationSystem:
		return {"accessible": true}

	# 商店开门时间
	var open_hour = 6
	var close_hour = 24

	# 工坊特殊时间
	if panel_key == "upgrade":
		open_hour = 8
		close_hour = 20

	# 检查当前时间
	if TimeManager:
		var hour = TimeManager.current_hour
		if hour < open_hour:
			return {"accessible": false, "reason": "尚未开门 (%d:00营业)" % open_hour}
		if hour >= close_hour:
			return {"accessible": false, "reason": "已经打烊 (%d:00关门)" % close_hour}

	return {"accessible": true}

func _show_cannot_navigate_message(panel_key: String) -> void:
	if not NavigationSystem:
		return

	var cost = NavigationSystem.get_travel_cost(panel_key)
	var stamina_needed = cost.get("stamina_cost", 0)

	if NavigationSystem.can_navigate_to(panel_key):
		return

	# 检查原因
	var shop_check = _get_shop_status(panel_key)
	if not shop_check.get("accessible", true):
		_show_error_message(shop_check.get("reason", "商店未营业"))
	elif TimeManager and TimeManager.current_hour >= 26:
		_show_error_message("已经深夜，无法出行！")
	elif stamina_needed > 0 and PlayerStats and PlayerStats.stamina < stamina_needed:
		_show_error_message("体力不足 (需要%d点)" % stamina_needed)
	else:
		_show_error_message("无法前往此处")
