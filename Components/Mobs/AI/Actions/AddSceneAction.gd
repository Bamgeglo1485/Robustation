@tool
class_name AddSceneAction extends ActionLeaf

@export var target: Node
@export var scene: PackedScene
@export var one_shot: bool = true
var added: bool = false

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if one_shot and added == true:
		return FAILURE
	var inst: Node = scene.instantiate()
	target.add_child(inst)
	added = true
	return SUCCESS
