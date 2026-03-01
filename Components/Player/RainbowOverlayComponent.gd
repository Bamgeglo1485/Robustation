class_name RainbowOverlayComponent extends Component

@export var transparency: float = 0.98
@export var overlay: ColorRect
var lifetime: float = 0
var enabled: bool = false
var material: Material
var effect_tween: Tween

func _process(delta: float) -> void:
	if !material and overlay:
		material = overlay.material
	
	if !material:
		return
	
	if lifetime <= 0 and !enabled:
		return
	elif lifetime <= 0 and enabled:
		enabled = false
		lifetime = 0
		_destroy_tween()
		var _tween: Tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(material, "shader_parameter/transparency", 1, 1)
		_tween.loop_finished.connect(_destroy_tween)
		return
	
	lifetime -= delta

func set_rainbow(delay):
	lifetime += delay
	enabled = true
	if effect_tween:
		return
	effect_tween = create_tween()
	effect_tween.set_trans(Tween.TRANS_SINE)
	effect_tween.set_ease(Tween.EASE_IN_OUT)
	effect_tween.tween_property(material, "shader_parameter/transparency", transparency, delay / 3)
	effect_tween.loop_finished.connect(_destroy_tween)

func _destroy_tween():
	effect_tween.kill()
