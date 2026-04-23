extends PanelContainer

## NpcFriendshipUI - NPC好感度面板
## 显示所有NPC列表、当前好感度、每日对话状态
## MVP: 列表显示 + 对话触发 + 好感度心形图标

# ============ 常量 ============

## 每心好感度
const FRIENDSHIP_PER_HEART: int = 250

## 心形 emoji 映射
const HEART_FILLED: String = "❤️"
const HEART_EMPTY: String = "🖤"

# ============ 节点引用 ============

var _npc_list_vbox: VBoxContainer
var _close_btn: Button
var _npc_items: Dictionary = {}  # npc_id -> {row, hearts_label, talk_btn}

# ============ 状态 ============

var _visible: bool = false

# ============ 生命周期 ============

func _ready() -> void:
	_setup_node_references()
	_connect_signals()
	_hide_panel()

func _setup_node_references() -> void:
	var vbox = $VBox
	_npc_list_vbox = vbox.get_node_or_null("NPCScroll/NPCList")
	_close_btn = vbox.get_node_or_null("Header/CloseBtn")
	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)

func _connect_signals() -> void:
	if EventBus:
		EventBus.time_day_changed.connect(_refresh_npc_list)
		EventBus.time_sleep_triggered.connect(_on_day_ended)

# ============ 公共 API ============

func open_panel() -> void:
	_show_panel()
	_populate_npc_list()

func close_panel() -> void:
	_hide_panel()

func toggle_panel() -> void:
	if _visible:
		close_panel()
	else:
		open_panel()

# ============ 私有方法 ============

func _show_panel() -> void:
	visible = true
	_visible = true
	z_index = 10

func _hide_panel() -> void:
	visible = false
	_visible = false

func _populate_npc_list() -> void:
	if not _npc_list_vbox:
		return

	# 清空现有列表
	for child in _npc_list_vbox.get_children():
		child.queue_free()
	_npc_items.clear()

	# 获取所有 NPC
	var npcs = NpcFriendshipSystem.get_all_npcs() if NpcFriendshipSystem else []
	for npc in npcs:
		var npc_id = npc.get("id", "")
		var npc_name = npc.get("name", npc_id)
		var friendship = NpcFriendshipSystem.get_friendship(npc_id) if NpcFriendshipSystem else 0
		var talked_today = NpcFriendshipSystem.has_talked_today(npc_id) if NpcFriendshipSystem else false

		# 创建 NPC 行
		var row = _create_npc_row(npc_id, npc_name, friendship, talked_today)
		_npc_list_vbox.add_child(row)
		_npc_items[npc_id] = {
			"row": row,
			"friendship": friendship,
			"talked_today": talked_today
		}

func _create_npc_row(npc_id: String, npc_name: String, friendship: int, talked_today: bool) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# NPC 名称
	var name_label = Label.new()
	name_label.text = npc_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_label)

	# 心形图标
	var hearts_label = Label.new()
	hearts_label.text = _get_hearts_string(friendship)
	hearts_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(hearts_label)

	# 对话按钮
	var talk_btn = Button.new()
	talk_btn.text = "对话" if not talked_today else "已对话"
	talk_btn.disabled = talked_today
	talk_btn.pressed.connect(_on_talk_pressed.bind(npc_id))
	hbox.add_child(talk_btn)

	return hbox

func _get_hearts_string(friendship: int) -> String:
	var hearts = clampi(friendship / FRIENDSHIP_PER_HEART, 0, 10)
	var empty = 10 - hearts
	return HEART_FILLED.repeat(hearts) + HEART_EMPTY.repeat(empty)

func _refresh_npc_list() -> void:
	# 每日重置时刷新列表（对话状态会变）
	if _visible:
		_populate_npc_list()

func _on_day_ended(_bedtime: int, _forced: bool) -> void:
	# 新的一天开始，刷新对话状态
	if _visible:
		_populate_npc_list()

# ============ 信号处理 ============

func _on_close_pressed() -> void:
	close_panel()

func _on_talk_pressed(npc_id: String) -> void:
	if not NpcFriendshipSystem:
		push_error("[NpcFriendshipUI] NpcFriendshipSystem not found")
		return

	var result = NpcFriendshipSystem.talk_to(npc_id)
	if result.get("success", false):
		# 通知成功，显示飘窗
		if NotificationManager:
			var gain = result.get("friendship_gain", 0)
			var npc_name = NpcFriendshipSystem.get_npc(npc_id).get("name", npc_id)
			NotificationManager.show_gain("与 %s 对话，好感度 +%d" % [npc_name, gain])
		# 更新按钮状态
		_update_npc_row(npc_id)
	else:
		var message = result.get("message", "对话失败")
		if NotificationManager:
			NotificationManager.show_warning(message)

func _update_npc_row(npc_id: String) -> void:
	if not _npc_items.has(npc_id):
		return
	var item = _npc_items[npc_id]
	if not item.has("row"):
		return
	var row = item["row"] as Control
	if not row:
		return

	# 更新心形图标
	var friendship = NpcFriendshipSystem.get_friendship(npc_id) if NpcFriendshipSystem else 0
	var talked_today = NpcFriendshipSystem.has_talked_today(npc_id) if NpcFriendshipSystem else false

	# 刷新整行
	var hbox = row as HBoxContainer
	if hbox:
		# 找到心形 Label（第二个子节点）和按钮（第三个）
		if hbox.get_child_count() >= 3:
			var hearts_label = hbox.get_child(1) as Label
			var talk_btn = hbox.get_child(2) as Button
			if hearts_label:
				hearts_label.text = _get_hearts_string(friendship)
			if talk_btn:
				talk_btn.text = "已对话"
				talk_btn.disabled = true

	item["friendship"] = friendship
	item["talked_today"] = talked_today