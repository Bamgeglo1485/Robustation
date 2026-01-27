class_name OpenableAirlockComponent extends Component

@export var trigger_area: Area2D
@onready var airlock_component: AirlockComponent = parent.get_node_or_null("AirlockComponent")

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if trigger_area == null or airlock_component == null:
		return
	
	var bodies = trigger_area.get_overlapping_bodies()
	if bodies.is_empty():
		airlock_component.close()
	else:
		airlock_component.open()
	
