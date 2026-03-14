class_name FadeInComponent extends Component

@export var delay: float = 5

func _ready() -> void:
	if parent is not PointLight2D:
		parent.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var _tween = create_tween()
		_tween.tween_property(parent, "modulate", Color(1.0, 1.0, 1.0, 1.0), delay)
	else:
		parent.color = Color(1.0, 1.0, 1.0, 0.0)
		var _tween = create_tween()
		_tween.tween_property(parent, "color", Color(1.0, 1.0, 1.0, 1.0), delay)
