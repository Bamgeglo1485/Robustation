extends Control

@onready var explosion = material

func _ready() -> void:
	var _tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	
	_tween.tween_property(explosion, "shader_parameter/radius", 6 , 1)
