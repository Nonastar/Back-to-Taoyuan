extends PanelContainer

## QuestUI - 任务面板
## 显示主线任务和告示栏委托列表，提供接受/查看/完成操作

# ============ 常量 ============

const QUEST_STATE_LABEL: Dictionary = {
	0: "未解锁",   # PENDING
	1: "可接取",   # AVAILABLE
	2: "进行中",   # ACTIVE
	3: "已完成",   # COMPLETED
	4: "已失败"    # EXPIRED
}

const STATE_EMOJI: Dictionary = {
	0: "🔒",
	1: "📋",
	2: "⏳",
	3: "✅",
	4: "❌"
}

# ============ 节点引用 ============

var _main_quest_list: VBoxContainer
var _daily_quest_list: VBoxContainer
var _tabs: TabContainer
var _close_btn: Button

# ============ 状态 ============

var _visible: bool = false

# ============ 生命周期 ============

func _ready() -> void:
	_setup_node_references()
	_connect_signals()

func _setup_node_references() -> void:
	var vbox = $VBox
	_tabs = vbox.get_node_or_null("Tabs")
	var header = vbox.get_node_or_null("Header")
	_close_btn = header.get_node_or_null("CloseBtn") if header else null
	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)

	if _tabs:
		var main_tab = _tabs.get_node_or_null("MainQuests")
		if main_tab:
			_main_quest_list = main_tab.get_node_or_null("ScrollContainer/QuestItems")
		var daily_tab = _tabs.get_node_or_null("DailyQuests")
		if daily_tab:
			_daily_quest_list = daily_tab.get_node_or_null("ScrollContainer/QuestItems")
		# 设置 tab 标题（Control 节点没有 text 属性，需要手动设置）
		_tabs.set_tab_title(0, "主线")
		_tabs.set_tab_title(1, "委托")

func _connect_signals() -> void:
	if EventBus:
		EventBus.time_day_changed.connect(_refresh_quests)
	if QuestSystem:
		QuestSystem.quest_accepted.connect(_on_quest_accepted)
		QuestSystem.quest_progress_updated.connect(_on_quest_progress_updated)
		QuestSystem.quest_completed.connect(_on_quest_completed)

# ============ 公共 API ============

func open_panel() -> void:
	_show_panel()
	_refresh_all_quests()

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

func _refresh_all_quests() -> void:
	_refresh_main_quests()
	_refresh_daily_quests()

func _refresh_main_quests() -> void:
	if not _main_quest_list:
		return

	for child in _main_quest_list.get_children():
		child.queue_free()

	if not QuestSystem:
		return

	var all_quests = QuestSystem.get_all_quests()
	for quest in all_quests:
		if quest.get("type") != QuestSystem.QuestType.MAIN:
			continue
		var row = _create_quest_row(quest)
		_main_quest_list.add_child(row)

func _refresh_daily_quests() -> void:
	if not _daily_quest_list:
		return

	for child in _daily_quest_list.get_children():
		child.queue_free()

	if not QuestSystem:
		return

	var all_quests = QuestSystem.get_all_quests()
	var has_daily = false
	for quest in all_quests:
		if quest.get("type") == QuestSystem.QuestType.DAILY:
			has_daily = true
			var row = _create_quest_row(quest)
			_daily_quest_list.add_child(row)

	if has_daily:
		var daily_tab = _tabs.get_node_or_null("DailyQuests")
		if daily_tab:
			var empty = daily_tab.get_node_or_null("EmptyLabel")
			if empty:
				empty.visible = false

func _create_quest_row(quest: Dictionary) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var quest_id = quest.get("id", "")
	var state = quest.get("state", 0)
	var progress = quest.get("progress", 0)
	var target = quest.get("target_count", 1)
	var title = quest.get("title", "未知任务")

	# 状态 emoji
	var emoji_label = Label.new()
	emoji_label.text = STATE_EMOJI.get(state, "❓")
	emoji_label.custom_minimum_size = Vector2(24, 0)
	hbox.add_child(emoji_label)

	# 任务信息
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_label = Label.new()
	title_label.text = title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(title_label)

	# 进度显示（ACTIVE 和 COMPLETED 状态显示）
	if state == QuestSystem.QuestState.ACTIVE or state == QuestSystem.QuestState.COMPLETED:
		var progress_label = Label.new()
		if state == QuestSystem.QuestState.COMPLETED:
			progress_label.text = "✅ %d/%d" % [progress, target]
			progress_label.modulate = Color(0.3, 0.9, 0.3, 1)
		else:
			if progress >= target:
				progress_label.text = "🎯 %d/%d" % [progress, target]
				progress_label.modulate = Color(0.3, 0.9, 0.3, 1)
			else:
				progress_label.text = "📋 %d/%d" % [progress, target]
				progress_label.modulate = Color(0.8, 0.8, 0.4, 1)
		info_vbox.add_child(progress_label)
	elif state == QuestSystem.QuestState.PENDING or state == QuestSystem.QuestState.AVAILABLE:
		# 未接取/可接取状态显示目标
		var target_label = Label.new()
		target_label.text = "🎯 目标: %d" % target
		target_label.modulate = Color(0.5, 0.5, 0.5, 1)
		info_vbox.add_child(target_label)

	var desc_label = Label.new()
	desc_label.text = quest.get("description", "")
	desc_label.modulate = Color(0.7, 0.7, 0.7, 1)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_label)

	# 奖励信息
	var reward_label = Label.new()
	var money = quest.get("reward_money", 0)
	if money > 0:
		reward_label.text = "💰 %d" % money
		reward_label.modulate = Color(1, 0.85, 0.3, 1)
	info_vbox.add_child(reward_label)

	hbox.add_child(info_vbox)

	# 操作按钮
	var action_btn = Button.new()
	action_btn.name = "ActionBtn"

	match state:
		QuestSystem.QuestState.PENDING:
			action_btn.text = "查看"
		QuestSystem.QuestState.AVAILABLE:
			action_btn.text = "接取"
		QuestSystem.QuestState.ACTIVE:
			if progress >= target:
				action_btn.text = "完成"
				action_btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3, 1))
			else:
				action_btn.text = "查看"
		QuestSystem.QuestState.COMPLETED:
			action_btn.text = "已完成"
			action_btn.disabled = true
		QuestSystem.QuestState.EXPIRED:
			action_btn.text = "已过期"
			action_btn.disabled = true

	action_btn.pressed.connect(_on_action_pressed.bind(quest_id, state, action_btn))
	hbox.add_child(action_btn)

	return hbox

func _refresh_quests(_day: int = 0, _season: String = "", _year: int = 0) -> void:
	if _visible:
		_refresh_all_quests()

# ============ 信号处理 ============

func _on_close_pressed() -> void:
	close_panel()

func _on_action_pressed(quest_id: String, state: int, btn: Button) -> void:
	if not QuestSystem:
		return

	match state:
		QuestSystem.QuestState.PENDING:
			# 主线任务点击后接取
			var quest = QuestSystem.get_quest(quest_id)
			if quest.get("type") == QuestSystem.QuestType.MAIN:
				var result = QuestSystem.accept_quest(quest_id)
				if result.get("success", false):
					_refresh_all_quests()
				else:
					if NotificationManager:
						NotificationManager.show_info(result.get("message", "无法接取任务"))
			else:
				var desc = quest.get("description", "")
				if NotificationManager:
					NotificationManager.show_info("「%s」: %s" % [quest.get("title", ""), desc])
		QuestSystem.QuestState.AVAILABLE:
			# 接取任务
			var result = QuestSystem.accept_quest(quest_id)
			if result.get("success", false):
				_refresh_all_quests()
		QuestSystem.QuestState.ACTIVE:
			# 尝试完成
			var quest = QuestSystem.get_quest(quest_id)
			if quest.get("progress", 0) >= quest.get("target_count", 1):
				var result = QuestSystem.complete_quest(quest_id)
				if result.get("success", false):
					_refresh_all_quests()
			else:
				var desc = quest.get("description", "")
				if NotificationManager:
					NotificationManager.show_info("「%s」: %s" % [quest.get("title", ""), desc])

func _on_quest_accepted(_quest_id: String, quest_title: String) -> void:
	_refresh_all_quests()
	if NotificationManager:
		NotificationManager.show_success("任务接取: 「%s」" % quest_title)

func _on_quest_progress_updated(_quest_id: String, _progress: int, _target: int) -> void:
	_refresh_all_quests()

func _on_quest_completed(_quest_id: String, quest_title: String) -> void:
	_refresh_all_quests()
	if NotificationManager:
		NotificationManager.show_success("🎉 任务完成: 「%s」" % quest_title)
