class_name MobMoverComponent extends Component

@onready var animation_component = parent.get_node_or_null("AnimationComponent")

@export var base_max_speed: int = 300
@export var max_speed: int = base_max_speed
@export var acceleration: int = 100
@export var friction: int = 700
@export var speed_modifier: float = 1
var direction = Vector2.ZERO

@export var can_fall: bool = true
@export var movement_blocked: bool = false
@export var set_navigation_velocity: bool = false

@export var fly_impact_area: Area2D
var flying: bool = false
var base_fly_speed: float = 0.0
var fly_speed: float = 0.0
var fly_direction: Vector2 = Vector2.ZERO
var fly_stop_speed: float = 200
var fly_modifier: float = 1
var fly_source

@export var body_fall_sound: AudioStreamPlayer2D
@export var fall_effect: PackedScene = preload("res://Scenes/Effects/Particles/Fall.tscn")
var fallen: bool = false
var standing_delay: float = 0

@onready var navigation_agent: NavigationAgent2D = parent.get_node_or_null("NavigationAgent")

func _ready() -> void:
	if fly_impact_area != null:
		fly_impact_area.body_entered.connect(on_fly_impact)

func _physics_process(delta: float) -> void:
	_fly(delta)
	_move(delta)

func _process(delta: float) -> void:
	_walk_animation()
	_fall_process(delta)

func _move(delta) -> void:
	if not parent is CharacterBody2D:
		return
	
	if flying:
		_fly_movement()
		return
	
	var velocity = parent.velocity
	
	if direction.is_zero_approx():
		if not velocity.is_zero_approx():
			var friction_amount = friction * delta
			var speed = velocity.length()
			if speed > friction_amount:
				velocity -= (velocity / speed) * friction_amount
			else:
				velocity = Vector2.ZERO
	elif not movement_blocked and not fallen:
		var dir = direction
		velocity += dir * acceleration
		
		if navigation_agent:
			var nav_vel = dir * acceleration * speed_modifier
			navigation_agent.set_velocity(nav_vel)
		
		var max_speed_current = max_speed * speed_modifier
		var current_speed = velocity.length()
		if current_speed > max_speed_current:
			velocity = (velocity / current_speed) * max_speed_current
	
	parent.velocity = velocity
	parent.move_and_slide()

func _walk_animation():
	if animation_component == null or flying == true or fallen == true:
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
	
	if direction != Vector2.ZERO and fallen == false:
		var control_velocity = direction * acceleration
		var combined_velocity = fly_velocity + control_velocity
		parent.velocity = combined_velocity.limit_length(fly_speed + max_speed)
	else:
		parent.velocity = fly_velocity
	
	parent.move_and_slide()

func _fly(delta):
	if not flying or fly_speed <= 0:
		return
	
	fly_speed -= 400 * delta
	
	if fly_speed < fly_stop_speed * 20:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(parent, "scale", Vector2(1, 1), 0.2)
	
	if fly_speed < fly_stop_speed:
		fly_speed = 0
		fly_direction = Vector2.ZERO
		parent.velocity = Vector2.ZERO
		flying = false

func throw(throw_direction: Vector2, throw_speed: float, throw_source = null, throw_stop_speed: float = 10, animation = true):
	var max_throw_speed = 2000
	var actual_speed = min(throw_speed, max_throw_speed)
	fly_source = throw_source
	
	if throw_direction.length_squared() > 0:
		fly_direction = throw_direction.normalized()
	else:
		fly_direction = Vector2.ZERO
	
	fly_speed = actual_speed
	base_fly_speed = actual_speed
	fly_stop_speed = throw_stop_speed
	
	if fly_speed > 100 and fly_direction != Vector2.ZERO:
		flying = true
	
	if animation == true:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		
		tween.tween_property(parent, "scale", Vector2(1.35, 1.35), 0.2)

func _fall_process(delta):
	if fallen == false:
		return
	
	if flying == false:
		standing_delay -= delta
	if standing_delay <= 0:
		stand_up()

func drop(delay):
	if can_fall == false or delay < 0.3:
		return
	
	standing_delay += delay
	
	if fallen == true:
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
 
func on_fly_impact(body):
	if not flying:
		return
	if not body.has_node("MobMoverComponent") or fly_speed < 200:
		return
	if body is Area2D or body == parent:
		return
	var mob_mover = body.get_node("MobMoverComponent")
	if mob_mover.can_fall == false:
		return
	mob_mover.throw(parent.velocity, fly_speed/1.5)
	mob_mover.drop(1)
	if body.has_node("HealthComponent"):
		body.get_node("HealthComponent").take_damage(fly_speed/50, fly_source)
