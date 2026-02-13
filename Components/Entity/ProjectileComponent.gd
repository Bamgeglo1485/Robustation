class_name ProjectileComponent extends Area2D

@onready var scene: Node2D = get_tree().get_root().get_node("Game")
@onready var parent: Node = get_parent()

@export var max_penetrations: int = 0
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
var deleted: bool = false
var penetration_damaged_bodies: Array
var penetrations: int = 0

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
	if !parent or parent is not CharacterBody2D:
		queue_free()
	
	await get_tree().create_timer(lifetime).timeout
	if deleted:
		return
	
	_delete()
	EventBusManager.projectile_miss.emit(shooter, parent)

func _physics_process(delta: float) -> void:
	if !moving:
		return
	
	if speed_decreasing != 0:
		speed -= speed_decreasing
	
	if speed <= 0:
		_delete()
	
	parent.velocity = Vector2(speed, 0).rotated(direction)
	parent.rotation += rotate_speed * delta
	parent.move_and_collide(parent.velocity * delta)

func _delete() -> void:
	parriable = false
	moving = false
	deleted = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	self.collision_layer = 0
	
	var ignore_component = MeleeAttackIgnoreComponent.new()
	parent.add_child(ignore_component)
	
	if parent.has_node("Area2D"):
		parent.get_node("Area2D").queue_free()
	
	if texture:
		texture.texture = null
	
	if particle_emitter:
		particle_emitter.emitting = false
	
	if explode_on_delete:
		explode()
	
	await get_tree().create_timer(5.0).timeout
	parent.queue_free()

func explode() -> void:
	if explosion_scene and !sploded:
		sploded = true
		var instance: Node = explosion_scene.instantiate()
		instance.global_position = parent.global_position
		if shooter:
			instance.source = shooter
		scene.add_child(instance)

func _on_body_entered(body: Node2D) -> void:
	if !body:
		return
	
	if body.has_node("ProjectileIgnoreComponent"):
		return
	
	if max_penetrations != 0 and penetration_damaged_bodies.has(body):
		return
	
	if shooter:
		if shooter == body:
			return
		if (!ignore_faction and shooter.has_node("FactionComponent") and 
			body.has_node("FactionComponent")):
			
			var shooter_faction: Node = shooter.get_node("FactionComponent")
			var body_faction: Node = body.get_node("FactionComponent")
			
			if shooter_faction.faction == body_faction.faction:
				return
	
	if reflect(body):
		return
	
	if hit_sound:
		hit_sound.play()
	
	var modified_damage: float = damage * damage_modifier
	
	if body.has_node("HealthComponent"):
		if !shooter:
			shooter = null
		body.get_node("HealthComponent").take_damage(modified_damage, shooter)
		if max_penetrations != 0:
			penetration_damaged_bodies.append(body)
			penetrations += 1
	else:
		max_penetrations = 0
	
	if body.has_node("MobMoverComponent") and throw_speed != 0:
		body.get_node("MobMoverComponent").throw(parent.velocity, throw_speed, shooter)
	
	if explode_on_hit:
		explode()
	
	if max_penetrations == 0:
		_delete()
	else:
		if max_penetrations < penetrations:
			_delete()

func reflect(target) -> bool:
	if !shooter:
		return false
	
	var reflect_component = target.get_node_or_null("ReflectPerkComponent")
	if !reflect_component:
		return false
	
	if randf() > reflect_component.chance:
		return false
	
	var angle = (shooter.global_position - parent.global_position).normalized().angle()
	parent.modulate = Color(2.658, 2.362, 0.0, 1.0)
	parent.global_rotation = angle
	direction = angle
	shooter = target
	
	reflect_component.on_reflect()
	
	var trail = TrailEffectComponent.new()
	trail.trail_lifetime = 0.2
	trail.end_color = Color(0.544, 0.0, 0.578, 0.0)
	var colors: Array[Color] = [
		Color(3.674, 1.907, 0.0, 1.0),
		Color(3.236, 0.576, 1.751, 1.0)]
	trail.colors = colors
	parent.add_child(trail)
	
	return true
