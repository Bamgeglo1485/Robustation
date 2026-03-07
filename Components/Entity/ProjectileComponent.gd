class_name ProjectileComponent extends Area2D

@onready var scene: Node2D = get_tree().get_root().get_node("Game")
@onready var parent: Node = get_parent()

@export var max_penetrations: int = 0
@export var texture: Sprite2D
@export var hit_sound: AudioStreamPlayer2D
@export var particle_emitter: GPUParticles2D

@export var speed: int = 500
@export var speed_decreasing: int = 0
@export var max_damage: int = 200
@export var damage: int = 10 : set = _set_damage
@export var stamina_damage: float = 0
@export var rotate_speed: int = 0
@export var lifetime: float = 3.0
@export var throw_speed: float = 0
@export var delete_on_hit: bool = true
@export var embed_on_hit: bool = false
@export var ignore_faction: bool = false

var shooter: PhysicsBody2D
var direction: float
var damage_modifier: float = 1.0
var moving: bool = true
var deleted: bool = false
var penetration_damaged_bodies: Array
var penetrations: int = 0
var can_hit: bool = true
var weapon: RangeWeapon
var shooter_faction: FactionComponent
var targeted_enemies: Array[CharacterBody2D]

@export_category("Sender")
@export var return_to_sender: bool = false
@export var instant_bullets_recover_to_sender: int = 1
@export var max_distance_from_sender: int = 0

@export_category("Parry")
@export var parriable: bool = true
@export var parry_speed_boost: float = 1.5
@export var parry_projectile_to_enemy: bool = true
var can_parry_weapon: MeleeWeapon

@export_category("Explosion")

@export var explosion_scene: PackedScene
@export var explode_on_delete: bool = false
@export var explode_on_hit: bool = false
@export var explode_on_damage: bool = false
var sploded: bool = false
var rope: Line2D
var sender_mob_mover: MobMoverComponent

func _set_damage(new_damage):
	damage = new_damage
	clamp(damage, -max_damage, max_damage)

func _ready() -> void:
	if !parent or parent is not CharacterBody2D:
		queue_free()
	
	shooter_faction = shooter.get_node_or_null("FactionComponent")
	
	if max_distance_from_sender != 0:
		max_distance_from_sender *= max_distance_from_sender
		sender_mob_mover = shooter.get_node_or_null("MobMoverComponent")
	
	if lifetime == 0:
		return
	await get_tree().create_timer(lifetime).timeout
	if deleted:
		return
	
	_delete()
	
	if penetration_damaged_bodies.is_empty():
		EventBusManager.projectile_miss.emit(shooter, parent)

func _physics_process(delta: float) -> void:
	if rope and shooter:
		rope.points[1] = shooter.to_local(global_position)
	if !moving:
		return
	if speed_decreasing != 0 and speed > 0:
		speed -= speed_decreasing
	elif return_to_sender:
		if shooter:
			var _direction: Vector2 = (global_position-shooter.global_position)
			direction = _direction.angle()
			if rotate_speed == 0:
				parent.global_rotation = direction
			if _direction.length_squared() < 20:
				_delete()
				if weapon:
					weapon.bullets += instant_bullets_recover_to_sender
					clamp(weapon.bullets, 0, weapon.bullets_max_count)
					weapon._cooldown()
				return
			elif max_distance_from_sender != 0 and _direction.length_squared() > max_distance_from_sender and sender_mob_mover:
				sender_mob_mover.throw(_direction, parent.velocity.length() * 2)
		speed -= speed_decreasing
	
	if speed <= 0 and !return_to_sender:
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
	parent.collision_layer = 0
	if rope:
		rope.visible = false
	
	var ignore_component: MeleeAttackIgnoreComponent = MeleeAttackIgnoreComponent.new()
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

func on_parried():
	if speed < 0 and return_to_sender:
		speed *= -1

func explode() -> void:
	if explosion_scene and !sploded:
		sploded = true
		var instance: Node = explosion_scene.instantiate()
		instance.global_position = global_position
		if shooter:
			instance.source = shooter
		scene.add_child(instance)

func _on_body_entered(body: Node2D) -> void:
	if !body or !can_hit:
		return
	if can_parry_weapon and body.has_node("ProjectileComponent"):
		var _direction: Vector2 = -body.velocity
		body.get_node("ProjectileComponent").speed *= 2
		if shooter_faction:
			var nearest_enemy = _get_nearest_enemy()
			if nearest_enemy:
				_direction = nearest_enemy.global_position - parent.global_position
		can_parry_weapon.parry_projectile(body, body.get_node("ProjectileComponent"), _direction)
	if body.has_node("ProjectileIgnoreComponent"):
		return
	if max_penetrations != 0 and penetration_damaged_bodies.has(body):
		return
	if shooter and shooter_faction:
		if shooter == body:
			return
		if (!ignore_faction and 
			body.has_node("FactionComponent")):
			
			var body_faction: FactionComponent = body.get_node_or_null("FactionComponent")
			
			if shooter_faction.faction == body_faction.faction:
				return
	
	if reflect(body):
		return
	if hit_sound:
		hit_sound.play()
	
	var modified_damage: float = damage * damage_modifier
	
	EventBusManager.projectile_hit.emit(body, parent)
	
	if body.has_node("HealthComponent"):
		if !shooter:
			shooter = null
		body.get_node("HealthComponent").take_damage(modified_damage, shooter)
		if max_penetrations != 0:
			penetration_damaged_bodies.append(body)
			penetrations += 1
	else:
		max_penetrations = 0
	
	if body.has_node("StaminaComponent") and stamina_damage != 0:
		body.get_node("StaminaComponent").take_stamina_damage(stamina_damage * damage_modifier, shooter)
	if body.has_node("MobMoverComponent") and throw_speed != 0:
		body.get_node("MobMoverComponent").throw(parent.velocity, throw_speed, shooter)
	if explode_on_hit:
		explode()
	if embed_on_hit:
		parent.reparent.call_deferred(body)
		deleted = true
		moving = false
		parent.velocity = Vector2.ZERO
		can_hit = false
		return
	
	if body.has_node("WeaponUserComponent") and can_parry_weapon:
		var body_weapon_user_comp: WeaponUserComponent = body.get_node("WeaponUserComponent")
		if body_weapon_user_comp.selected_weapon and body_weapon_user_comp.selected_weapon.swinging:
			can_parry_weapon.parry_weapon(body_weapon_user_comp.selected_weapon, body)
	
	if max_penetrations == 0 and delete_on_hit:
		_delete()
	else:
		if max_penetrations < penetrations:
			_delete()

func reflect(target) -> bool:
	if !parriable:
		return false
	if !shooter:
		return false
	var reflect_component = target.get_node_or_null("ReflectPerkComponent")
	if !reflect_component:
		return false
	
	if randf() > reflect_component.chance:
		return false
	
	var angle = (shooter.global_position - global_position).normalized().angle()
	
	if !reflect_component.reflect_to_attacker:
		angle = -angle
	
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

func _on_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	var area_parent: Node2D = area.get_parent()
	if area_parent == parent:
		return
	_on_body_entered(area_parent)

func _get_nearest_enemy() -> CharacterBody2D:
	var enemies: Array[CharacterBody2D] = _get_valid_enemies()
	var parent_pos: Vector2 = parent.global_position
	
	if enemies.is_empty():
		enemies = _get_valid_enemies(false)
		if enemies.is_empty():
			targeted_enemies.clear()
			return null
	
	var nearest_enemy: CharacterBody2D = enemies[0]
	var nearest_distance: float = (parent_pos - nearest_enemy.global_position).length_squared()
	
	for enemy in enemies:
		var distance: float = (parent_pos - enemy.global_position).length_squared()
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	targeted_enemies.append(nearest_enemy)
	return nearest_enemy

func _get_valid_enemies(check_in_targeted: bool = true) -> Array[CharacterBody2D]:
	var enemies: Array[CharacterBody2D] = []
	for child in scene.get_children():
		if child is not CharacterBody2D:
			continue
		if check_in_targeted and targeted_enemies.has(child):
			continue
		var faction_comp: FactionComponent = child.get_node_or_null("FactionComponent")
		if !faction_comp or faction_comp.faction == shooter_faction.faction:
			continue
		enemies.append(child)
	
	return enemies
