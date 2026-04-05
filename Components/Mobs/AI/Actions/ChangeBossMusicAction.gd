@tool
class_name ChangeBossMusicAction extends ActionLeaf

@export var new_track: AudioStream
@onready var boss_music: BossMusicComponent = owner.get_node_or_null("BossMusicComponent")
var changed: bool = false

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if changed:
		return FAILURE
	boss_music.change_music(new_track)
	changed = true
	return SUCCESS
