class_name RestartComponent extends Component

func _unhandled_input(_event: InputEvent) -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")
	Engine.time_scale = 1
