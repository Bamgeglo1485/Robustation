@tool
class_name AddHealthBarAction extends ActionLeaf

@export var target: HealthBarComponent
var added: bool = false

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if added:
		return FAILURE
	target.on_spawn = true
	target._ready()
	added = true
	return SUCCESS
