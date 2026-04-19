extends Node2D

@onready var tree: SceneTree = get_tree()
@onready var area2d: Area2D = $Area2D
@export var impact_frame: bool = true
@export var damage: float = 80
@export var fly_force: int = 4000
@export var fall_time: int = 2
@export var radius: int = 128
@export var source: PhysicsBody2D
@export var explosion_duration: float = 0.3
@export var check_interval: float = 0.1
@export var ignore_faction: bool = false
@export var drop_forced: bool = false
@export var drop_resistance_force: int = 3
@export var main_lighting: PointLight2D
var active: bool = true
var source_faction: FactionComponent

var damaged_bodies: Array = []
var check_timer: Timer

func _ready() -> void:
	var collision_shape = area2d.get_node("CollisionShape2D").shape
	if collision_shape is CircleShape2D:
		collision_shape.radius = radius
	if source:
		source_faction = source.get_node_or_null("FactionComponent")
	
	check_timer = Timer.new()
	add_child(check_timer)
	check_timer.wait_time = check_interval
	check_timer.timeout.connect(_check_overlapping_bodies)
	check_timer.start()
	
	_set_lighting()
	
	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = true
	
	EventBusManager.explosion.emit(self)
	
	await tree.create_timer(0.15).timeout
	_check_overlapping_bodies()
	
	await tree.create_timer(explosion_duration).timeout
	active = false
	if check_timer:
		check_timer.stop()
	area2d.queue_free()
	
	await tree.create_timer(2.0).timeout
	queue_free()

func _set_lighting():
	main_lighting.scale = Vector2(0.0, 0.0)
	
	var main_tween: Tween = create_tween()
	main_tween.set_trans(Tween.TRANS_SINE)
	main_tween.set_ease(Tween.EASE_IN_OUT)
	main_tween.tween_property(main_lighting, "scale", Vector2(1, 1), 0.25)
	main_tween.tween_property(main_lighting, "scale", Vector2(0, 0), 0.25)

func _check_overlapping_bodies() -> void:
	check_timer.start()
	if !active:
		return
	
	var bodies: Array[Node2D] = area2d.get_overlapping_bodies()
	for body in bodies:
		if is_instance_valid(body) and body not in damaged_bodies and body.has_node("HealthComponent"):
			_apply_damage_to_body(body)

func _apply_damage_to_body(body: Node2D) -> void:
	if !is_instance_valid(body) or body in damaged_bodies:
		return
	var body_faction: Node = body.get_node_or_null("FactionComponent")
	if source_faction and !ignore_faction and source and body_faction:
		if source_faction.faction == body_faction.faction:
			return
	
	var distance: float = (body.global_position - global_position).length()
	var distance_factor = 1.0 - clamp(distance / radius, 0.0, 1.0)
	
	if distance_factor > 0.1:
		var modifier: float = 1
		
		var explosion_resist: ExplosionResistanceComponent = body.get_node_or_null("ExplosionResistanceComponent")
		if explosion_resist:
			modifier = explosion_resist.resistance
		
		var health: HealthComponent = body.get_node_or_null("HealthComponent")
		if health:
			health.take_damage(damage * distance_factor * modifier, source)
		
		var mob_mover: MobMoverComponent = body.get_node_or_null("MobMoverComponent")
		if mob_mover:
			mob_mover.drop(fall_time * distance_factor, drop_forced, drop_resistance_force)
			var direction: Vector2 = (body.global_position - global_position).normalized()
			if direction.length_squared() > 0:
				mob_mover.throw(direction, fly_force * distance_factor)
		
		damaged_bodies.append(body)
