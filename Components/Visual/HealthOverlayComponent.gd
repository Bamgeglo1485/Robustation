class_name HealthOverlayComponent extends Component

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
@export var overlay: ColorRect
var material

func _ready() -> void:
	if health_component and overlay:
		health_component.health_changed.connect(_on_health_changed)
		material = overlay.material

func _on_health_changed(health) -> void:
	if !material:
		return
	
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	
	var max_health: int = health_component.max_health
	
	if health < float(max_health) * 0.5:
		var intensity: float = 1 - (float(health) / float(max_health))
		_tween.tween_property(material, "shader_parameter/intensity", intensity, 0.5)
	else:
		_tween.tween_property(material, "shader_parameter/intensity", 0, 0.5)
