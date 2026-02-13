extends Node2D

func _ready() -> void:
	var parent = get_parent()
	for child in get_children():
		child.reparent.call_deferred(parent)
