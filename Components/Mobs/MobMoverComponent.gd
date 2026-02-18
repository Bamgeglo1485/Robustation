class_name MobMoverComponent extends Component

@onready var animation_component: AnimationComponent = parent.get_node_or_null("AnimationComponent")

@export var base_max_speed: float = 300.0
@onready var max_speed: float = base_max_speed
@export var acceleration: float = 100.0
@export var friction: float = 700.0
@export var minor_modifiers: Dictionary
@export var speed_modifier: float = 1.0
var direction: Vector2 = Vector2.ZERO

@export var fallen_speed_modifier: float = 0.3
@export var fall_delay_modifier: float = 1.0
@export var can_fall: bool = true
@export var can_fall_from_body: bool = true
@export var movement_blocked: bool = false
@export var set_navigation_velocity: bool = false

@export var fly_impact_area: Area2D
var flying: bool = false
var base_fly_speed: float = 0.0
var fly_speed: float = 0.0
var fly_direction: Vector2 = Vector2.ZERO
var fly_stop_speed: float = 200.0
var fly_modifier: float = 1.0
var fly_source: Node2D

@export var body_fall_sound: AudioStreamPlayer2D
@export var fall_effect: PackedScene = preload("res://Scenes/Effects/Particles/Fall.tscn")
@export var drop_resistance: int = 0
var fallen: bool = false
var force_fallen: bool = false
var standing_delay: float = 0.0

@onready var navigation_agent: NavigationAgent2D = parent.get_node_or_null("NavigationAgent")
@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")

var walking_tween: Tween
var drop_tween: Tween

func _ready() -> void:
	if fly_impact_area:
		fly_impact_area.body_entered.connect(on_fly_impact)
	
	minor_modifiers["fallen_modifier"] = 1.0

func _physics_process(delta: float) -> void:
	if flying and fly_speed > 0:
		_fly(delta)
	
	_move(delta)

func _process(delta: float) -> void:
	if animation_component and !flying and !fallen:
		_walk_animation()
	if fallen:
		_fall_process(delta)

func _move(delta: float) -> void:
	if not parent is CharacterBody2D:
		return
	
	if flying:
		_fly_movement()
		return
	
	var velocity: Vector2 = parent.velocity
	var speed: float = velocity.length()
	
	if direction.is_zero_approx():
		if !velocity.is_zero_approx():
			var friction_amount: float = friction * delta
			if speed > friction_amount:
				velocity -= (velocity / speed) * friction_amount
			else:
				velocity = Vector2.ZERO
	elif !movement_blocked:
		velocity += direction * acceleration
		
		var minor_modifier: float = _get_minor_modifiers()
		
		if navigation_agent:
			var nav_vel: Vector2 = direction * acceleration * speed_modifier * minor_modifier
			navigation_agent.set_velocity(nav_vel)
		
		var max_speed_current: float = max_speed * speed_modifier * minor_modifier
		if speed > max_speed_current:
			velocity = (velocity / speed) * max_speed_current
	
	parent.velocity = velocity
	parent.move_and_slide()

func _get_minor_modifiers() -> float:
	var modifier: float = 1.0
	
	if !minor_modifiers:
		return modifier
	
	for minor_mod in minor_modifiers:
		modifier *= minor_modifiers[minor_mod]
	
	return modifier

func _walk_animation() -> void:
	if parent.velocity == Vector2.ZERO and animation_component.animation_priority == 1:
		animation_component.clear_animation()
	elif parent.velocity.length_squared() != 0 and animation_component.animation_priority < 1:
		walking_tween = create_tween()
		walking_tween.set_loops()
		walking_tween.set_trans(Tween.TRANS_SINE)
		walking_tween.set_ease(Tween.EASE_IN_OUT)
		
		var modified_time: float = 0.2 * max_speed / base_max_speed
		
		walking_tween.tween_property(parent, "global_rotation", -0.08, modified_time)
		walking_tween.tween_property(parent, "global_rotation", 0.08, modified_time)
		
		animation_component.set_animation(walking_tween, 1)

func _fly_movement() -> void:
	var fly_velocity: Vector2 = fly_direction * fly_speed
	
	if direction != Vector2.ZERO and !fallen:
		var control_velocity: Vector2 = direction * acceleration
		var combined_velocity: Vector2 = fly_velocity + control_velocity
		parent.velocity = combined_velocity.limit_length(fly_speed + max_speed)
	else:
		parent.velocity = fly_velocity
	
	parent.move_and_slide()

func _fly(delta) -> void:
	fly_speed -= 400 * delta
	
	if fly_speed < fly_stop_speed * 20:
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(parent, "scale", Vector2(1, 1), 0.2)
	
	if fly_speed < fly_stop_speed:
		fly_speed = 0
		fly_direction = Vector2.ZERO
		parent.velocity = Vector2.ZERO
		flying = false

func throw(
	throw_direction: Vector2,
	throw_speed: float,
	throw_source: Node2D = null,
	throw_stop_speed: float = 10,
	animation = true
	) -> void:
	
	var max_throw_speed: int = 2000
	var actual_speed = min(throw_speed, max_throw_speed)
	fly_source = throw_source
	
	if throw_direction.length() > 0:
		fly_direction = throw_direction.normalized()
	else:
		fly_direction = Vector2.ZERO
	
	fly_speed = actual_speed * fly_modifier
	base_fly_speed = actual_speed * fly_modifier
	fly_stop_speed = throw_stop_speed * fly_modifier
	
	if fly_speed > 100 and fly_direction != Vector2.ZERO:
		flying = true
	
	if animation:
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		
		tween.tween_property(parent, "scale", Vector2(1.35, 1.35), 0.2)

func _fall_process(delta: float) -> void:
	if !flying:
		standing_delay -= delta
	if standing_delay <= 0:
		stand_up()

func drop(delay: float, force: bool = false, resistance_force: int = 0) -> void:
	if !can_fall or delay < 0.3 or force_fallen or drop_resistance > resistance_force:
		return
	
	var modifier: float = 1.0
	if !force:
		modifier = fall_delay_modifier
		
	standing_delay += delay * modifier
	
	if standing_delay <= 0.1:
		standing_delay = 0
		return
	
	parent.velocity = Vector2.ZERO
	force_fallen = force
	
	if fallen:
		return
	
	fallen = true
	minor_modifiers["fallen_modifier"] = fallen_speed_modifier
	
	if animation_component:
		drop_tween = create_tween()
		drop_tween.set_trans(Tween.TRANS_SINE)
		drop_tween.set_ease(Tween.EASE_IN_OUT)
		drop_tween.tween_property(parent, "global_rotation", -1.55, 0.2)
		drop_tween.tween_property(parent, "global_rotation", -1.55, 690)
		animation_component.set_animation(drop_tween, 69)
	if fall_effect:
		if health_component and health_component.health <= 0:
			return
		
		var inst: Node = fall_effect.instantiate()
		inst.global_position = parent.global_position
		scene.add_child(inst)
	if body_fall_sound:
		body_fall_sound.play()

func try_stand_up() -> void:
	if force_fallen:
		return
	
	stand_up()

func stand_up() -> void:
	standing_delay = 0
	
	if animation_component:
		animation_component.clear_animation()
	
	await get_tree().create_timer(0.3).timeout
	
	minor_modifiers["fallen_modifier"] = 1.0
	fallen = false
	force_fallen = false
 
func on_fly_impact(body: Node) -> void:
	if body == fly_source:
		return
	if !flying or !body.has_node("MobMoverComponent") or fly_speed < 200 or body is Area2D or body == parent:
		return
	var mob_mover: MobMoverComponent = body.get_node("MobMoverComponent")
	if !mob_mover.can_fall_from_body:
		return
	mob_mover.throw(parent.velocity, fly_speed/1.5)
	mob_mover.drop(1)
	if body.has_node("HealthComponent"):
		body.get_node("HealthComponent").take_damage(fly_speed/50, fly_source)
