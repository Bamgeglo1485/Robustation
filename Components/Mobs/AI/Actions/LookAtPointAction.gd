@tool
class_name LookAtDirectionAction extends ActionLeaf

@onready var direction_component: DirectionComponent = owner.get_node_or_null("DirectionComponent")
@export var key: String

func tick(actor: Node, blackboard: Blackboard) -> int:
	if !direction_component:
		return FAILURE
	var point = blackboard.get_value(key)
	if !point or !actor:
		return FAILURE
	
	direction_component.look_at_direction(point - actor.global_position)
	return SUCCESS
