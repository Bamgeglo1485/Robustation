class_name PhysicalParticleComponent extends Component

@export var fall_sound: AudioStreamPlayer2D
@export var min_acceleration_time: float = 0.3
@export var max_acceleration_time: float = 0.6
@export var min_lifetime: float = 20
@export var max_lifetime: float = 30
@export var speed: float = 200

@onready var sprite: Sprite2D = parent.get_node("Texture")

var accelerating: bool = true
var direction: float = 0.0
var lifetime: float
var acceleration_time: float

var cleaning: bool = false

func _ready() -> void:
	if parent is not CharacterBody2D:
		queue_free()
		return
	
	if !parent.is_in_group("PhysicalParticle"):
		add_to_group("PhysicalParticle")
	direction = randf_range(0, 360)
	
	lifetime = randf_range(min_lifetime, max_lifetime)
	acceleration_time = randf_range(min_acceleration_time, max_acceleration_time)
	parent.rotation = randf_range(0, 360)
	
	await get_tree().create_timer(lifetime - 5).timeout
	clean()

func clean() -> void:
	if cleaning:
		return
	cleaning = true
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(parent, "modulate", Color(1.0, 1.0, 1.0, 0.0), 3)
	await get_tree().create_timer(3).timeout
	parent.queue_free()

func _physics_process(_delta: float) -> void:
	if !accelerating:
		return
	
	acceleration_time -= _delta
	lifetime -= _delta
	
	if acceleration_time < 0:
		accelerating = false
		if fall_sound:
			fall_sound.global_position = parent.global_position
			fall_sound.play()
	
	parent.velocity = Vector2(acceleration_time * speed, 0).rotated(direction)
	parent.move_and_slide()
