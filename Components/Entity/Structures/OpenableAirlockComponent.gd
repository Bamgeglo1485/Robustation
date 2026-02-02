class_name OpenableAirlockComponent extends Component

@export var trigger_area: Area2D
@onready var airlock_component: AirlockComponent = parent.get_node_or_null("AirlockComponent")

func _physics_process(_delta: float) -> void:
	if !trigger_area or !airlock_component:
		return
	
	var bodies: Array[Node2D] = trigger_area.get_overlapping_bodies()
	if bodies.is_empty():
		airlock_component.close()
	else:
		airlock_component.open()
	
