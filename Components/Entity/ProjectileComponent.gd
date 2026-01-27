class_name ProjectileComponent extends Area2D

@onready var scene: Node2D = get_tree().get_root().get_node("Game")
@onready var parent = get_parent()

@export var texture: Sprite2D
@export var hit_sound: AudioStreamPlayer2D
@export var particle_emitter: GPUParticles2D

@export var speed: int = 500
@export var speed_decreasing: int = 0
@export var damage: int = 10
@export var rotate_speed: int = 0
@export var lifetime: float = 3
@export var throw_speed: float = 0

var shooter: CharacterBody2D
var direction: float
var damage_modifier: float = 1
var moving: bool = true

@export var parriable: bool = true
@export var parry_speed_boost: float = 1.5
@export var ignore_faction: bool = false

@export_category("Explosion")

@export var explosion_scene: PackedScene
@export var explode_on_delete: bool = false
@export var explode_on_hit: bool = false
@export var explode_on_damage: bool = false
var sploded: bool = false

func _ready() -> void:
	if parent == null or parent is not CharacterBody2D:
		queue_free()
	
	await get_tree().create_timer(lifetime).timeout
	_delete()
	EventBusManager.projectile_miss.emit(shooter, parent)

func _physics_process(delta: float) -> void:
	if moving == false:
		return
	
	if speed_decreasing != 0:
		speed -= speed_decreasing
	
	parent.velocity = Vector2(speed, 0).rotated(direction)
	parent.rotation += rotate_speed * delta
	parent.move_and_collide(parent.velocity * delta)

func _delete():
	parriable = false
	moving = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	self.collision_layer = 0
	
	if parent.has_node("Area2D"):
		parent.get_node("Area2D").queue_free()
	
	if texture != null:
		texture.texture = null
	
	if particle_emitter != null:
		particle_emitter.emitting = false
	
	if explode_on_delete == true:
		explode()
	
	await get_tree().create_timer(5.0).timeout
	parent.queue_free()

func explode():
	if explosion_scene != null and sploded == false:
		sploded = true
		var instance = explosion_scene.instantiate()
		instance.global_position = parent.global_position
		instance.source = shooter
		scene.add_child(instance)

func _on_body_entered(body: Node2D) -> void:
	if body == null:
		return
	
	if body.has_node("ProjectileIgnoreComponent"):
		return
	
	if shooter != null:
		if shooter == body:
			return
		if (ignore_faction == false and shooter.has_node("FactionComponent") and 
			body.has_node("FactionComponent")):
			
			var shooter_faction = shooter.get_node("FactionComponent")
			var body_faction = body.get_node("FactionComponent")
			
			if shooter_faction.faction == body_faction.faction:
				return
	
	if hit_sound != null:
		hit_sound.play()
	
	var modified_damage = damage * damage_modifier
	
	if body.has_node("HealthComponent"):
		body.get_node("HealthComponent").take_damage(modified_damage, shooter)
	
	if body.has_node("MobMoverComponent") and throw_speed != 0:
		body.get_node("MobMoverComponent").throw(parent.velocity, throw_speed, shooter)
	
	if explode_on_hit == true:
		explode()
	
	_delete()
