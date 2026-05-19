class_name EnemySpawnerAirlockComponent extends Component

@export var openable: bool = true
@export var unlocked_lights: PointLight2D
@export var collision: StaticBody2D
@export var outer_collision: Area2D

var room: int = 0
var enemy_spawn_position: Vector2
var enemy_move_position: Vector2
@onready var occluder: LightOccluder2D = parent.get_node_or_null("LightOccluder2D")
@onready var openable_airlock: OpenableAirlockComponent = parent.get_node_or_null("OpenableAirlockComponent")

func _ready() -> void:
	if openable:
		EventBusManager.room_end.connect(_on_end)

func _on_end(_room: int) -> void:
	if _room == room:
		occluder.visible = false
		if unlocked_lights:
			unlocked_lights.enabled = true
		if collision:
			collision.queue_free()
		openable_airlock.enabled = true
