class_name StationRunComponent extends Component

@export var levels: Array[PackedScene]
var current_level: int = 0

@onready var root: Window = tree.get_root()
@onready var player: CharacterBody2D = get_parent().get_node_or_null("Player")
@onready var current_scene: Node2D = get_parent()
var ended: bool = false
var time: float
var kills: int

func _ready() -> void:
	call_deferred("reparent", root)
	player.tree_exited.connect(_player_exit)
	await tree.physics_frame
	start_new_level()
	
	EventBusManager.level_ended.connect(_level_ended)

func start_new_level() -> void:
	current_level += 1
	ended = false
	for child in scene.get_children():
		if child != player and child != self:
			child.queue_free()
	
	if levels.size() < current_level - 1:
		player.get_node("HealthComponent").health = 0
		return
	
	var inst_level: Node2D = levels[current_level - 1].instantiate()
	scene.add_child(inst_level)
	for child in inst_level.get_children():
		child.reparent(scene)
	
	EventBusManager.scene_changed.emit(current_scene)

func _input(_event: InputEvent) -> void:
	if ended and Input.is_action_just_pressed("movement"):
		start_new_level()

func _level_ended(_level: int) -> void:
	ended = true

func _player_exit() -> void:
	queue_free()
