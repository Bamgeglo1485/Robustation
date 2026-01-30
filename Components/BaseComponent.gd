@abstract
class_name Component extends Node

var parent: Node = _get_valid_parent()
@onready var scene: Node2D = get_tree().get_root().get_node("Game")

func _get_valid_parent() -> Node:
	var current_parent: Node = get_parent()
	
	if current_parent == null:
		return null
	
	while current_parent is ComponentFolder:
		var next_parent: Node = current_parent.get_parent()
		if next_parent == null:
			break
		current_parent = next_parent
	
	return current_parent

func _notification(notif) -> void:
	if notif == NOTIFICATION_PARENTED:
		parent = _get_valid_parent()
