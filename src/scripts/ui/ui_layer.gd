extends CanvasLayer

## UILayer - 拦截点击事件，防止穿透到游戏世界
## 挂在 Main.tscn 的 UILayer 节点上

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var btn = $SleepButton
		if btn and btn.visible and btn.get_global_rect().has_point(event.global_position):
			# 直接触发睡觉逻辑，不依赖按钮的 pressed 信号
			# （因为 set_input_as_handled 会阻止信号触发）
			if TimeManager and TimeManager.time_state == TimeManager.TimeState.TIME_RUNNING:
				TimeManager.player_sleep()
			get_tree().root.set_input_as_handled()
