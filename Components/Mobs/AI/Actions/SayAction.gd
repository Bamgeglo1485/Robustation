@tool
class_name SayAction extends ActionLeaf

@onready var chatter_component: ChatterComponent = owner.get_node_or_null("ChatterComponent")
@export var lines: Array[String]
@export var chance: float = 0.5
@export var restrict_repetitions: bool = true
var sayed_lines: Array[String]

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if !chatter_component or randf() > chance or !chatter_component.can_say():
		return FAILURE
	var new_line: String = lines.pick_random()
	if restrict_repetitions and sayed_lines.has(new_line):
		return FAILURE
	chatter_component.say(new_line)
	if restrict_repetitions:
		sayed_lines.append(new_line)
	return SUCCESS
