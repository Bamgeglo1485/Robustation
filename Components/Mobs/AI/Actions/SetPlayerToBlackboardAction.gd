@tool
class_name SetPlayerToBlackboardAction extends ActionLeaf

@export var key: String = "Target"
@export var ignore_player_change: bool = false

@onready var scene = get_tree().get_root().get_node_or_null("Game")
var player: Node2D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if !ignore_player_change:
		EventBusManager.change_player.connect(_player_changed)
	EventBusManager.player_death.connect(_player_death)

func tick(_actor: Node, blackboard: Blackboard) -> int:
	if !scene:
		return FAILURE
	
	if !player:
		player = scene.get_node_or_null("Player")
		if !player or !player.has_node("MobMoverComponent"):
			player = null
	
	if !player or !is_instance_valid(player):
		blackboard.erase_value(key)
		return FAILURE
	
	blackboard.set_value(key, player)
	
	return SUCCESS

func _player_changed(new_player, wait_time) -> void:
	if wait_time > 0:
		await get_tree().create_timer(wait_time).timeout
	player = new_player

func _player_death() -> void:
	player = null
