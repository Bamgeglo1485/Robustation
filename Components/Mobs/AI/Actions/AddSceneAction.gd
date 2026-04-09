@tool
class_name AddSceneAction extends ActionLeaf

@export var target: Node2D
@export var position_target: Node2D
@export var scene: PackedScene
@export var max_nodes: int = 1
@export var cooldown_delay: float = 3
var added_nodes: int = 0
var cooldown: bool = false

func _ready() -> void:
	if !target:
		target = get_tree().get_root().get_node_or_null("Game")

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if cooldown or added_nodes >= max_nodes:
		return FAILURE
	var inst: Node = scene.instantiate()
	target.add_child(inst)
	if position_target:
		inst.global_position = position_target.global_position
	added_nodes += 1
	_cooldown()
	return SUCCESS

func _cooldown() -> void:
	if cooldown_delay != 0:
		cooldown = true
		await get_tree().create_timer(cooldown_delay).timeout
		cooldown = false
