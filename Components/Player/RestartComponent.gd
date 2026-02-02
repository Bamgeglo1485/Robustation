class_name RestartComponent extends Component

func _process(_delta: float) -> void:
	var input: bool = Input.is_action_just_pressed("Restart")
	
	if input:
		get_tree().reload_current_scene()
		Engine.time_scale = 1
