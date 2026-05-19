## The component responsible for movement, falling, and flight of CharacterBody2D
class_name MobMoverComponent extends Component

## Component to animate parent with tweens
@onready var animation_component: AnimationComponent = parent.get_node_or_null("AnimationComponent")

@export var base_max_speed: float = 300.0
@onready var max_speed: float = base_max_speed
@export var acceleration: float = 100.0
@export var friction: float = 700.0
## Minor modifiers. To set just add key to dictionary with modifier value (minor_modifiers["erectile dysfunction"] = 0.5
@export var minor_speed_modifiers: Dictionary
var minor_speed_modifier: float
## Master speed modifier
@export var speed_modifier: float = 1.0
## The direction in which the body goes
@export var direction: Vector2 = Vector2.ZERO

## Move speed when fallen
@export var fallen_speed_modifier: float = 0.3
@export var fall_delay_modifier: float = 1.0
@export var can_fall: bool = true
## Can it fall if another body hits it
@export var can_fall_from_body: bool = true
@export var movement_blocked: bool = false
## Toggles the ability to bypass other bodies
@export var set_navigation_velocity: bool = false

@export var moving_animation_lean: float = 0.08

## An area to crash into and knock down other bodies while flying.
@export var fly_impact_area: Area2D
var flying: bool = false
var base_fly_speed: float = 0.0
var fly_speed: float = 0.0
var fly_direction: Vector2 = Vector2.ZERO
var fly_throw_off: bool = false
## The speed at which the flight is forced to end
var fly_stop_speed: float = 200.0
@export var fly_modifier: float = 1.0
## The body that made fly, actually damager
var fly_source: Node2D
var fly_priority: int = 0

@export var body_fall_sound: AudioStreamPlayer2D
@export var fall_effect: PackedScene = preload("res://Scenes/Effects/Particles/Fall.tscn")
## For example, if the toolbox has drop_force = 3, and the body has drop_resistance = 4, then the toolbox cannot make it fall.
@export var drop_resistance: int = 0
var fallen: bool = false
var force_fallen: bool = false
## The time it takes for the body to rise
var standing_delay: float = 0.0

@onready var navigation_agent: NavigationAgent2D = parent.get_node_or_null("NavigationAgent")
@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")

@onready var texture: Sprite2D = parent.get_node_or_null("Texture")

# Non binary animation tweens
var unfly_animation_tween: Tween
var fly_animation_tween: Tween
var walking_tween: Tween
var drop_tween: Tween

# signals
signal unflied

# Cache

var max_speed_current: float
var friction_amount: float
var velocity: Vector2
var speed: float

@export_category("Modifiers")
@export var speed_multipliers: Dictionary
@export var speed_multiplier: float = 1.0

func _ready() -> void:
	if fly_impact_area:
		fly_impact_area.body_entered.connect(on_fly_impact)
	set_minor_speed_modifier("fallen", 1.0)

func _physics_process(delta: float) -> void:
	if flying and fly_speed > 0:
		# First we run the flight logic, then the movement logic.
		_fly(delta)
	_move(delta)
	if animation_component and !flying and !fallen:
		_walk_animation()
	if fallen:
		_fall_process(delta)

# Movement logic
func _move(delta: float) -> void:
	if !parent is CharacterBody2D:
		return
	
	if flying:
		_fly_movement()
		return
	
	velocity = parent.velocity
	speed = velocity.length()
	
	if direction.is_zero_approx():
		# If the body does not go somewhere, we apply friction
		if !velocity.is_zero_approx():
			friction_amount = friction * delta
			if speed > friction_amount:
				velocity -= (velocity / speed) * friction_amount
			else:
				velocity = Vector2.ZERO
	elif !movement_blocked:
		# Just movement
		velocity += direction * acceleration
		
		if navigation_agent:
			var nav_vel: Vector2 = direction * acceleration * speed_modifier * minor_speed_modifier
			navigation_agent.set_velocity(nav_vel)
		
		max_speed_current = max_speed * speed_modifier * minor_speed_modifier * speed_multiplier
		if speed > max_speed_current:
			velocity = (velocity / speed) * max_speed_current
	
	parent.velocity = velocity
	parent.move_and_slide()

func set_minor_speed_modifier(key: String, value: float) -> void:
	minor_speed_modifiers[key] = value
	var mod: float = 1.0
	for modifier in minor_speed_modifiers.values():
		mod *= modifier
	minor_speed_modifier = mod

func _walk_animation() -> void:
	if parent.velocity == Vector2.ZERO and animation_component.animation_priority == 1:
		animation_component.clear_animation()
	elif parent.velocity.length_squared() != 0 and animation_component.animation_priority < 1:
		walking_tween = create_tween()
		walking_tween.set_loops()
		
		var modified_time: float = 0.2 * max_speed / base_max_speed
		
		walking_tween.stop()
		walking_tween.tween_property(texture, "rotation", -moving_animation_lean, modified_time)
		walking_tween.tween_property(texture, "rotation", moving_animation_lean, modified_time)
		animation_component.set_animation(walking_tween, 1)

# Movement when body flying
func _fly_movement() -> void:
	var fly_velocity: Vector2 = fly_direction * fly_speed
	
	if direction != Vector2.ZERO and !fallen:
		var control_velocity: Vector2 = direction * acceleration
		var combined_velocity: Vector2 = fly_velocity + control_velocity
		parent.velocity = combined_velocity.limit_length(fly_speed + max_speed)
	else:
		parent.velocity = fly_velocity
	
	parent.move_and_slide()

# Flight processing
func _fly(delta) -> void:
	fly_speed -= 400 * delta
	
	if fly_animation_tween:
		fly_animation_tween.kill()
	
	if fly_speed < fly_stop_speed * 20:
		unfly_animation_tween = create_tween()
		unfly_animation_tween.set_trans(Tween.TRANS_SINE)
		unfly_animation_tween.set_ease(Tween.EASE_IN_OUT)
		unfly_animation_tween.tween_property(texture, "scale", Vector2(1.0, 1.0), 0.2)
	
	if fly_speed < fly_stop_speed:
		fly_speed = 0
		fly_direction = Vector2.ZERO
		parent.velocity = Vector2.ZERO
		flying = false
		fly_priority = 0
		
		unflied.emit()

# Make body fly
func throw(
	throw_direction: Vector2,
	throw_speed: float,
	throw_source: Node2D = null,
	throw_stop_speed: float = 10,
	animation: bool = true,
	_rewrite: bool = true,
	throw_throw_off: bool = true,
	priority: int = 0
	) -> void:
	if priority < fly_priority:
		return
	var max_throw_speed: int = 2000
	var actual_speed = min(throw_speed, max_throw_speed)
	
	if actual_speed * fly_modifier > 100 and throw_direction.normalized() != Vector2.ZERO:
		flying = true
		fly_source = throw_source
		fly_throw_off = throw_throw_off
		fly_priority = priority
		fly_speed = actual_speed * fly_modifier
		base_fly_speed = actual_speed * fly_modifier
		fly_stop_speed = throw_stop_speed * fly_modifier
		fly_direction = throw_direction.normalized()
	if animation:
		fly_animation_tween = create_tween()
		fly_animation_tween.set_trans(Tween.TRANS_SINE)
		fly_animation_tween.set_ease(Tween.EASE_IN_OUT)
		fly_animation_tween.tween_property(texture, "scale", Vector2(1.5, 1.5), 0.2)

func _fall_process(delta: float) -> void:
	if !flying:
		standing_delay -= delta
	if standing_delay <= 0 and fallen:
		stand_up()

# Causes the body to fall
func drop(delay: float, force: bool = false, resistance_force: int = 0) -> void:
	if !can_fall or delay < 0.3 or force_fallen or drop_resistance > resistance_force:
		return
	
	var modifier: float = 1.0
	if !force:
		modifier = fall_delay_modifier
	
	standing_delay += delay * modifier
	
	if standing_delay <= 0.2:
		standing_delay = 0
		return
	
	parent.velocity = Vector2.ZERO
	force_fallen = force
	
	if animation_component:
		drop_tween = create_tween()
		drop_tween.set_trans(Tween.TRANS_SINE)
		drop_tween.set_ease(Tween.EASE_IN_OUT)
		drop_tween.tween_property(texture, "global_rotation", -1.55, 0.2)
		drop_tween.tween_property(texture, "global_rotation", -1.55, 690)
		animation_component.set_animation(drop_tween, 69, true)
	
	if fallen:
		return
	
	fallen = true
	set_minor_speed_modifier("fallen", fallen_speed_modifier)
	if fall_effect:
		if health_component and health_component.health <= 0:
			return
		var inst: Node = fall_effect.instantiate()
		inst.global_position = parent.global_position
		scene.add_child.call_deferred(inst)
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
	fallen = false
	force_fallen = false
	
	await get_tree().create_timer(0.3).timeout
	
	if animation_component:
		animation_component.clear_animation()
	
	set_minor_speed_modifier("fallen", 1.0)
 
# When flying body hits another body
func on_fly_impact(body: Node2D) -> void:
	if !fly_throw_off or !is_instance_valid(body):
		return
	if body == fly_source:
		return
	if !flying or fly_speed < 200 or body is Area2D or body == parent:
		return
	var mob_mover: MobMoverComponent = body.get_node_or_null("MobMoverComponent")
	if !mob_mover or !mob_mover.can_fall_from_body:
		return
	mob_mover.throw(parent.velocity, fly_speed/1.5)
	mob_mover.drop(1)
	var body_health_component: HealthComponent = body.get_node_or_null("HealthComponent")
	var damage: float = fly_speed/25.0
	if body_health_component and fly_source:
		body_health_component.take_damage(damage, fly_source, "Collision")
	EventBusManager.body_to_body_collision.emit(parent, body, damage, body_health_component)
