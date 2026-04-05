@tool
class_name PlayAudioAction extends ActionLeaf

@export var audio: AudioStreamPlayer2D

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	audio.play()
	return SUCCESS
