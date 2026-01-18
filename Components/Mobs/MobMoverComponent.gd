class_name MobMoverComponent extends Component

@onready var animation_component = parent.get_node_or_null("AnimationComponent")

@export var base_max_speed: int = 300
@export var max_speed: int = base_max_speed
@export var acceleration: int = 100
@export var friction: int = 700
var direction = Vector2.ZERO

@export var can_fall: bool
@export var movement_blocked: bool
@export var set_navigation_velocity: bool

var fly_direction: Vector2 = Vector2.ZERO
var flying: bool
var base_fly_speed: float
var fly_speed: float
var fly_stop_speed: float = 200
var fly_modifier: float = 1

@export var body_fall_sound: AudioStreamPlayer2D
var fallen: bool
var standing_delay: float

@export var fall_effect: PackedScene = preload("res://Scenes/Effects/Particles/Fall.tscn")

func _physics_process(delta: float) -> void:
	_fly(delta)
	_move(delta)
	_fall_process(delta)
	_walk_animation()

func _move(delta) -> void:
	if parent is not CharacterBody2D:
		return
	
	if flying:
		_fly_movement()
		return
	
	if direction == Vector2.ZERO:
		var _friction_multiplier = friction * delta
		if parent.velocity.length() > _friction_multiplier:
			parent.velocity -= parent.velocity.normalized() * _friction_multiplier
		else:
			parent.velocity = Vector2.ZERO
	elif !movement_blocked and !fallen:
		parent.velocity += direction * acceleration
		if parent.has_node("NavigationAgent"):
			parent.get_node("NavigationAgent").set_velocity(direction * acceleration)
		parent.velocity = parent.velocity.limit_length(max_speed)
	
	parent.move_and_slide()

func _walk_animation():
	if animation_component == null or flying or !fallen:
		return
	
	if parent.velocity == Vector2.ZERO and animation_component.animation_priority == 1:
		animation_component.clear_animation()
	elif parent.velocity.length_squared() > 0.01 and animation_component.animation_priority < 1:
		var walk_tween = create_tween()
		walk_tween.set_loops()
		walk_tween.set_trans(Tween.TRANS_SINE)
		walk_tween.set_ease(Tween.EASE_IN_OUT)
		
		var modified_time = 0.2 * (float(max_speed) / float(base_max_speed))
		
		walk_tween.tween_property(parent, "global_rotation", -0.08, modified_time)
		walk_tween.tween_property(parent, "global_rotation", 0.08, modified_time)
		
		animation_component.set_animation(walk_tween, 1)

func _fly_movement() -> void:
	var fly_velocity = fly_direction * fly_speed * fly_modifier
	
	if direction != Vector2.ZERO and !fallen:
		var control_velocity = direction * acceleration
		var combined_velocity = fly_velocity + control_velocity
		parent.velocity = combined_velocity.limit_length(fly_speed + max_speed)
	else:
		parent.velocity = fly_velocity
	
	parent.move_and_slide()

func _fly(delta):
	if !flying or fly_speed <= 0:
		return
	
	fly_speed -= 400 * delta
	
	if fly_speed < fly_stop_speed:
		fly_speed = 0
		fly_direction = Vector2.ZERO
		parent.velocity = Vector2.ZERO
		flying = false

func throw(throw_direction: Vector2, throw_speed: float, throw_stop_speed: float = 10):
	var max_throw_speed = 2000
	var actual_speed = min(throw_speed, max_throw_speed)
	
	if throw_direction.length_squared() > 0:
		fly_direction = throw_direction.normalized()
	else:
		fly_direction = Vector2.ZERO
	
	fly_speed = actual_speed
	base_fly_speed = actual_speed
	fly_stop_speed = throw_stop_speed
	
	if fly_speed > 100 and fly_direction != Vector2.ZERO:
		flying = true

func _fall_process(delta):
	if !fallen:
		return
	
	if !flying:
		standing_delay -= delta
	if standing_delay <= 0:
		stand_up()

func drop(delay):
	standing_delay += delay
	
	if fallen:
		return
	
	fallen = true
	
	if animation_component != null:
		var tween = create_tween()
		tween.set_loops()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(parent, "global_rotation", -1.55, 0.2)
		animation_component.set_animation(tween, 5)
	if fall_effect != null:
		if parent.has_node("HealthComponent") and parent.get_node("HealthComponent").health <= 0:
			return
		
		var inst = fall_effect.instantiate()
		scene.add_child(inst)
		inst.global_position = parent.global_position
	if body_fall_sound != null:
		body_fall_sound.play()

func stand_up():
	standing_delay = 0
	
	if animation_component != null:
		animation_component.clear_animation()
	
	await get_tree().create_timer(0.3).timeout
	
	fallen = false
