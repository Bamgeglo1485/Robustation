extends Control

@onready var explosion = material

func _ready() -> void:
	if !SettingsConfigSystem.explosion_effect:
		visible = false
		return
	var _tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	
	_tween.tween_property(explosion, "shader_parameter/radius", 2 , 1)
	
	await _tween.finished
	
	visible = false
