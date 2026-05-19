class_name OpenableAirlockComponent extends Component

@export var enabled: bool = true
@export var trigger_area: Area2D
@onready var airlock_component: AirlockComponent = parent.get_node_or_null("AirlockComponent")

func _ready() -> void:
	trigger_area.body_entered.connect(_check)
	trigger_area.body_exited.connect(_check)

func _check(body: Node2D) -> void:
	if !enabled:
		return
	if airlock_component.state == AirlockComponent.airlock_states.BOLTED or !airlock_component.can_open:
		return
	if body is not CharacterBody2D or !trigger_area:
		return
	
	var bodies: Array[Node2D] = trigger_area.get_overlapping_bodies()
	for _body in bodies:
		if _body is not CharacterBody2D:
			bodies.erase(_body)
	
	if bodies.is_empty():
		airlock_component.close()
	else:
		airlock_component.open()
