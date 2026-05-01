class_name RainbowOverlayComponent extends Component

@export var transparency: float = 0.98
@export var overlay: ColorRect
var lifetime: float = 0
var enabled: bool = false
var material: Material
var effect_tween: Tween

func _process(delta: float) -> void:
	if lifetime <= 0 and !enabled:
		return
	elif lifetime <= 0 and enabled:
		enabled = false
		lifetime = 0
		var _tween: Tween = create_tween()
		_tween.tween_property(material, "shader_parameter/transparency", 1, 1)
		_tween.finished.connect(_destroy_tween)
		return
	
	lifetime -= delta

func set_rainbow(delay):
	lifetime += delay
	overlay.visible = true
	enabled = true
	if effect_tween:
		return
	effect_tween = create_tween()
	effect_tween.tween_property(material, "shader_parameter/transparency", transparency, delay / 3)
	effect_tween.loop_finished.connect(_destroy_tween)

func _destroy_tween():
	effect_tween.kill()
	overlay.visible = false
