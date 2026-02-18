class_name OffScreenComponent extends Component

@export var button: TextureButton
@export var effect: ColorRect
@export var start_animation: bool = true
@export var off_sound: AudioStreamPlayer2D

func _ready() -> void:
	if button:
		button.pressed.connect(_off)
	if start_animation and effect:
		effect.visible = true
		effect.material.set_shader_parameter("vignette_strength", 20)
		effect.material.set_shader_parameter("brightness", -1)
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_parallel()
		tween.tween_property(effect.material, "shader_parameter/brightness", 0, 0.4)
		tween.tween_property(effect.material, "shader_parameter/vignette_strength", 0, 0.4)
		await tween.finished
		effect.visible = false
		effect.material.set_shader_parameter("vignette_strength", 0.0)
		effect.material.set_shader_parameter("brightness", 0.0)

func _off() -> void:
	effect.visible = true
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(effect.material, "shader_parameter/brightness", 0.3, 0.2)
	tween.tween_property(effect.material, "shader_parameter/vignette_strength", 2000000, 0.4)
	
	if off_sound:
		off_sound.play()
	
	await tween.finished
	get_tree().quit()
