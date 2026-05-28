class_name StationRunComponent extends Component

@export var levels: Array[PackedScene]
var current_level: int = 0

@onready var root: Window = tree.get_root()
@onready var player: CharacterBody2D = get_parent().get_node_or_null("Player")
@onready var current_scene: Node2D = get_parent()

func _ready() -> void:
	GlobalVariables.player = player
	
	call_deferred("reparent", root)
	player.tree_exited.connect(_player_exit)
	await tree.create_timer(1).timeout
	start_new_level()

func start_new_level() -> void:
	current_level += 1
	
	player.reparent(root, false)
	
	get_tree().change_scene_to_packed(levels[current_level - 1])
	
	await root.child_entered_tree
	
	current_scene = root.get_node("Game")
	
	var new_player = current_scene.get_node_or_null("Player")
	if new_player:
		new_player.queue_free()
	
	player.reparent(current_scene, false)
	

func _player_exit() -> void:
	queue_free()
