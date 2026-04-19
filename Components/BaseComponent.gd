@abstract
class_name Component extends Node

var parent: Node = get_parent()
@onready var tree: SceneTree = get_tree()
@onready var scene: Node2D = tree.get_root().get_node_or_null("Game")

func _init() -> void:
	name = get_script().get_global_name()

func _notification(notif) -> void:
	if notif == NOTIFICATION_PARENTED:
		parent = get_parent()
