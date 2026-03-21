class_name AnchorToCursorComponent extends Component

@export var offset: Vector2 = Vector2.ZERO

func _process(_delta: float) -> void:
	if !parent.visible:
		return
	
	parent.global_position = parent.get_global_mouse_position() + offset
