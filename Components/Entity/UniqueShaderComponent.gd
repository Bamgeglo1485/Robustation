class_name UniqueShaderComponent extends Component

func _ready() -> void:
	if parent.materiall:
		parent.material = parent.material.duplicate()
		queue_free()
