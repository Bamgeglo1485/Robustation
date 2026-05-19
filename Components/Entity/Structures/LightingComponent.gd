class_name LightingComponent extends Component

@export var base: Sprite2D
@export var broken: Sprite2D
@export var glow: Sprite2D
@export var light: PointLight2D
@export var break_audio: AudioStreamPlayer2D

@onready var health: HealthComponent = parent.get_node_or_null("HealthComponent")
var destroyed: bool = false
@onready var room_data: RoomDataComponent = parent.get_node_or_null("RoomDataComponent")

func _ready() -> void:
	health.damaged.connect(_on_damaged)
	EventBusManager.room_start.connect(_enable)
	if room_data.room == -1:
		_enable(-1)

func _enable(_room: int) -> void:
	if room_data.room == _room:
		light.visible = true
		glow.visible = true

func _on_damaged(_damage: float, _damager: Node2D) -> void:
	if destroyed:
		return
	if health.health <= 0:
		destroyed = true
		broken.visible = true
		glow.visible = false
		light.visible = false
		if break_audio:
			break_audio.play()
