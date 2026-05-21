class_name LightingComponent extends Component

@export var base: Sprite2D
@export var broken: Sprite2D
@export var glow: Sprite2D
@export var light: PointLight2D
@export var break_audio: AudioStreamPlayer2D
@export var enable_audio: AudioStreamPlayer2D
@export var flickering_light_chance: float = 0.2
@export var flickering_delay: float = 1.0
@export var flickering_pattern: Array[float] = [0.1, 0.7, 0.4, 0.2, 0.3, 0.3, 0.7, 0.5, 0.6, 0.3]
var pattern_state: int = 0
var flickering: bool = true
var flickering_update_timer: Timer
var flickering_timer: Timer
@onready var normal_light: float = light.energy
@onready var low_light: float = light.energy / 10

@onready var health: HealthComponent = parent.get_node_or_null("HealthComponent")
var destroyed: bool = false
@onready var room_data: RoomDataComponent = parent.get_node_or_null("RoomDataComponent")

func _ready() -> void:
	if randf() < flickering_light_chance:
		flickering_update_timer = Timer.new()
		flickering_update_timer.one_shot = true
		flickering_update_timer.wait_time = flickering_delay
		flickering_update_timer.timeout.connect(_flick)
		add_child(flickering_update_timer)
		
		flickering_timer = Timer.new()
		flickering_timer.one_shot = true
		flickering_timer.wait_time = 0.2
		add_child(flickering_timer)
	
	health.damaged.connect(_on_damaged)
	EventBusManager.room_start.connect(_enable)
	if room_data.room == -1:
		_enable(-1)

func _enable(_room: int) -> void:
	if room_data.room == _room:
		light.enabled = true
		glow.visible = true
		if flickering_update_timer:
			flickering_update_timer.start()
		if enable_audio:
			enable_audio.play()

func _on_damaged(_damage: float, _damager: Node2D) -> void:
	if destroyed:
		return
	if health.health <= 0:
		destroyed = true
		broken.visible = true
		glow.visible = false
		light.enabled = false
		if flickering_update_timer:
			flickering = false
			flickering_update_timer.stop()
		if break_audio:
			break_audio.play()

func _flick() -> void:
	glow.visible = false
	light.energy = low_light
	pattern_state += 1
	if pattern_state >= flickering_pattern.size():
		pattern_state = 0
	flickering_timer.wait_time = flickering_pattern[pattern_state]
	flickering_timer.start()
	await flickering_timer.timeout
	if !flickering:
		return
	glow.visible = true
	light.energy = normal_light
	flickering_update_timer.start()
	if enable_audio:
		enable_audio.play()
