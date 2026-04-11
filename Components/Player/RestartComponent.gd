class_name RestartComponent extends Component

func _unhandled_input(_event: InputEvent) -> void:
	if _event.is_action_pressed("Restart"):
		get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")
		Engine.time_scale = 1
		return
	if _event.is_action_pressed("movement"):
		get_tree().reload_current_scene()
		Engine.time_scale = 1
