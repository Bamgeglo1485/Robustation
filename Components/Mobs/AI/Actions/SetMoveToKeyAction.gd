@tool
class_name SetMoveToKeyAction extends ActionLeaf

@export var key: String

func tick(_actor: Node, blackboard: Blackboard) -> int:
	var value = blackboard.get_value(key)
	if value:
		blackboard.set_value("MovePoint", value.global_position)
		return SUCCESS
	blackboard.set_value("MovePoint", Vector2.ZERO)
	return FAILURE
