extends Node2D

@onready var area2d: Area2D = $Area2D
@export var impact_frame: bool = true
@export var damage: float = 80
@export var fly_force: int = 4000
@export var fall_time: int = 2
@export var radius: int = 128
@export var source: CharacterBody2D
@export var explosion_duration: float = 0.3
@export var check_interval: float = 0.05
var active = true

var damaged_bodies = []
var check_timer: Timer

func _ready() -> void:
	if area2d.has_node("CollisionShape2D"):
		var shape = CircleShape2D.new()
		shape.radius = radius
		area2d.get_node("CollisionShape2D").shape = shape
	
	area2d.body_entered.connect(_on_body_entered)
	
	check_timer = Timer.new()
	add_child(check_timer)
	check_timer.wait_time = check_interval
	check_timer.one_shot = false
	check_timer.timeout.connect(_check_overlapping_bodies)
	check_timer.start()
	
	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = true
	
	EventBusManager.explosion.emit(self)
	
	await get_tree().create_timer(0.1).timeout
	_check_overlapping_bodies()
	
	await get_tree().create_timer(explosion_duration).timeout
	active = false
	if check_timer:
		check_timer.stop()
	area2d.queue_free()
	
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _check_overlapping_bodies():
	if not active:
		return
	
	var bodies = area2d.get_overlapping_bodies()
	for body in bodies:
		if is_instance_valid(body) and body not in damaged_bodies:
			_apply_damage_to_body(body)

func _on_body_entered(body: Node2D) -> void:
	if active == false:
		return
	if is_instance_valid(body) and body not in damaged_bodies:
		_apply_damage_to_body(body)

func _apply_damage_to_body(body: Node2D) -> void:
	if not is_instance_valid(body) or body in damaged_bodies:
		return
	
	var distance = (body.global_position - global_position).length()
	var distance_factor = 1.0 - clamp(distance / radius, 0.0, 1.0)
	
	if distance_factor > 0.1:
		var modifier: float = 1
		
		if body.has_node("ExplosionResistanceComponent"):
			modifier = body.get_node("ExplosionResistanceComponent").resistance
		
		if body.has_node("HealthComponent"):
			body.get_node("HealthComponent").take_damage(damage * distance_factor * modifier, source)
		
		if body.has_node("MobMoverComponent"):
			var mob_mover = body.get_node("MobMoverComponent")
			mob_mover.drop(fall_time * distance_factor)
			var direction = (body.global_position - global_position).normalized()
			if direction.length_squared() > 0:
				mob_mover.throw(direction, fly_force * distance_factor)
		
		if body.has_node("OrganComponent"):
			body.get_node("OrganComponent")._on_step(body)
		
		damaged_bodies.append(body)
