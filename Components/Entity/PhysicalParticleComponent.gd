class_name PhysicalParticleComponent extends Component

@export var fall_sound: AudioStreamPlayer2D
@export var min_acceleration_time: float = 0.3
@export var max_acceleration_time: float = 0.6
@export var min_lifetime: float = 60
@export var max_lifetime: float = 66
@export var speed: float = 200

@onready var sprite: Sprite2D = parent.get_node("Texture")

var accelerating = true
var direction: float = 0
var lifetime: float
var acceleration_time: float

func _ready() -> void:
	if parent is not CharacterBody2D:
		queue_free()
		return
	
	direction = randf_range(0, 360)
	
	lifetime = randf_range(min_lifetime, max_lifetime)
	acceleration_time = randf_range(min_acceleration_time, max_acceleration_time)
	parent.rotation = randf_range(0, 360)

func _physics_process(_delta: float) -> void:
	acceleration_time -= _delta
	lifetime -= _delta
	
	if lifetime < 0:
		parent.queue_free()
	
	if acceleration_time < 0 and accelerating == true:
		accelerating = false
		if fall_sound != null:
			fall_sound.global_position = parent.global_position
			fall_sound.play()
	
	if accelerating == true:
		parent.velocity = Vector2(acceleration_time * speed, 0).rotated(direction)
		parent.move_and_slide()
	
	sprite.self_modulate.a = clamp(lifetime, 0, 1)
