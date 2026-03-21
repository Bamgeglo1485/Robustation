@tool
class_name IsNotRushingCondition extends ConditionLeaf

@export var rush_action: RushAction
@export var needed_state: bool = false

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if !rush_action or rush_action.rushing != needed_state or rush_action.preparing_to_rush != needed_state:
		return FAILURE
	return SUCCESS
