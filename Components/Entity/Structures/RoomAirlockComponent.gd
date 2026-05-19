class_name RoomAirlockComponent extends Component

@export var trigger_area: Area2D
@onready var airlock: AirlockComponent = parent.get_node_or_null("AirlockComponent")
@onready var occluder: LightOccluder2D = parent.get_node_or_null("LightOccluder2D")
var room: int = 0

func _ready() -> void:
	trigger_area.body_entered.connect(_start)
	EventBusManager.room_start.connect(_on_start)
	EventBusManager.room_end.connect(_on_end)
	EventBusManager.force_bolt.connect(_on_force_block)
	EventBusManager.force_unbolt.connect(_on_force_unblock)

func _start(_body: Node2D) -> void:
	trigger_area.set_deferred("monitoring", false)
	EventBusManager.room_start.emit(room)

func _on_start(_room: int) -> void:
	if (_room == room or _room + 1 == room) and _room < 100:
		airlock.bolt()

func _on_end(_room: int) -> void:
	if (_room == room or _room + 1 == room) and _room < 100:
		airlock.unbolt()

func _on_force_block(_room: int) -> void:
	if _room == room:
		airlock.bolt()

func _on_force_unblock(_room: int) -> void:
	if _room == room:
		airlock.unbolt()
