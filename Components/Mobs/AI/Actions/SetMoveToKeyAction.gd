@tool
class_name SetMoveToKeyAction extends ActionLeaf

@export var key: String
@export var move_key: String = "MovePoint"

func tick(_actor: Node, blackboard: Blackboard) -> int:
	var value = blackboard.get_value(key)
	if value:
		blackboard.set_value(move_key, value.global_position)
		return SUCCESS
	blackboard.set_value(move_key, Vector2.ZERO)
	return FAILURE
