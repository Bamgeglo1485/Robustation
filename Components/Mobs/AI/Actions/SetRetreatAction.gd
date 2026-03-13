@tool
class_name SetRetreatAction extends ActionLeaf

@export var move_to_point_action: MoveToPointAction
@export var set_on: bool = true

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if !move_to_point_action:
		return FAILURE
	
	move_to_point_action.retreat = set_on
	return SUCCESS
