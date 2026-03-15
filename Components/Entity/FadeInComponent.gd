class_name FadeInComponent extends Component

@export var delay: float = 5

func _ready() -> void:
	if parent is PointLight2D:
		var color: Color = parent.color
		parent.color = Color(1.0, 1.0, 1.0, 0.0)
		var _tween = create_tween()
		_tween.tween_property(parent, "color", color, delay)
	elif parent is AudioStreamPlayer:
		var volume: float = parent.volume_db
		parent.volume_db = -30
		var _tween = create_tween()
		_tween.tween_property(parent, "volume_linear", volume, delay)
	else:
		var modulate: Color = parent.modulate
		parent.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var _tween = create_tween()
		_tween.tween_property(parent, "modulate", modulate, delay)
