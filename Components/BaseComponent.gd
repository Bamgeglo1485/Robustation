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

func set_multiplier(stat: String, key: String, value: float) -> void:
	var dict = get(stat + "_multipliers")
	dict[key] = value
	var multiplier: float = 1.0
	for dick_multiplier in dict.values():
		multiplier *= dick_multiplier
	set(stat + "_multiplier", multiplier)

func remove_multiplier(stat: String, key: String) -> void:
	var dict = get(stat + "_multipliers")
	dict.erase(key)
	var multiplier: float = 1.0
	for dick_multiplier in dict.values():
		multiplier *= dick_multiplier
	set(stat + "_multiplier", multiplier)

func set_addendum(stat: String, key: String, value: float) -> void:
	var dict = get(stat + "_addendums")
	dict[key] = value
	var addendum: float = 0.0
	for dick_addendum in dict.values():
		addendum += dick_addendum
	set(stat + "_addendum", addendum)

func remove_addendum(stat: String, key: String) -> void:
	var dict = get(stat + "_addendums")
	dict.erase(key)
	var addendum: float = 0.0
	for dick_addendum in dict.values():
		addendum += dick_addendum
	set(stat + "_addendum", addendum)
