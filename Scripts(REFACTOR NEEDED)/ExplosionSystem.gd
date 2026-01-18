extends Node2D

@onready var area2d: Area2D = $Area2D
@export var impact_frame: bool = true
@export var damage: float = 80
@export var fly_force: int = 4000
@export var fall_time: int = 2
@export var radius: int = 128
@export var source: CharacterBody2D
@export var explosion_duration: float = 0.3
var active = true

var damaged_bodies = []

func _ready() -> void:
	area2d.get_node("CollisionShape2D").shape.radius = radius
	area2d.body_entered.connect(_on_body_entered)
	
	await get_tree().physics_frame
	var initial_bodies = area2d.get_overlapping_bodies()
	for body in initial_bodies:
		_apply_damage_to_body(body)
	
	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = true
	
	await get_tree().create_timer(explosion_duration).timeout
	area2d.queue_free()

func _on_body_entered(body: Node2D) -> void:
	if active == false:
		return
	_apply_damage_to_body(body)

func _apply_damage_to_body(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	
	if body in damaged_bodies:
		return
	
	var distance = (body.global_position - global_position).length()
	var distance_factor = 1.0 - clamp(distance / radius, 0.0, 1.0)
	
	if distance_factor > 0.1:
		if body.has_node("HealthComponent"):
			body.get_node("HealthComponent").take_damage(damage * distance_factor, source)
		
		if body.has_node("MobMoverComponent"):
			var mob_mover = body.get_node("MobMoverComponent")
			mob_mover.drop(fall_time * distance_factor)
			mob_mover.throw((body.global_position - global_position).normalized(), fly_force * distance_factor)
		
		if body.has_node("OrganComponent"):
			body.get_node("OrganComponent")._on_step(body)
		
		damaged_bodies.append(body)
