class_name ProjectileComponent extends Area2D

@onready var scene: Node2D = get_tree().get_root().get_node("Game")
@onready var parent: Node = get_parent()

@export var can_penetrate: bool = true
@export var max_penetrations: int = 0
@export var texture: Sprite2D
@export var hit_sound: AudioStreamPlayer2D
@export var particle_emitter: GPUParticles2D

@export var max_bounces: int = 0
var bounces: int = 0

@export var speed: int = 500
@export var speed_decreasing: int = 0
@export var stop_when_null_speed: bool = false
@export var max_damage: float = 200
@export var damage: float = 10 : set = _set_damage
@export var delayed_damage: float = 0
@export var delayed_damage_delay: float = 0
@export var stamina_damage: float = 0
@export var rotate_speed: int = 0
@export var lifetime: float = 3.0
@export var fade_out_delete: bool = false
@export var throw_speed: float = 0
@export var delete_on_hit: bool = true
@export var embed_on_hit: bool = false
@export var ignore_faction: bool = false
@export var ignore_armor: float = false
@export var fall_time: float = 0.0

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
var targeted_enemies: Array[PhysicsBody2D]

@export_category("Sender")
@export var return_to_sender: bool = false
@export var instant_bullets_recover_to_sender: int = 1
@export var max_distance_from_sender: int = 0

@export_category("Parry")
@export var parriable: bool = true
@export var parry_damage_modifier: float = 1.0
@export var parry_speed_boost: float = 1.5
@export var parry_projectile_to_enemy: bool = true
var can_parry_weapon: MeleeWeapon

@export_category("Explosion")
@export var explosion_scene: PackedScene
@export var explode_on_delete: bool = false
@export var explode_on_hit: bool = false
@export var explode_on_projectile_hit: bool = false
@export var explode_on_damage: bool = false

var sploded: bool = false
var rope: Line2D
var sender_mob_mover: MobMoverComponent

func _set_damage(new_damage):
	damage = new_damage
	damage = clamp(damage, -max_damage, max_damage)

func _ready() -> void:
	if !parent or parent is not CharacterBody2D:
		queue_free()
	
	if shooter:
		shooter_faction = shooter.get_node_or_null("FactionComponent")
	
	if max_distance_from_sender != 0 and shooter:
		max_distance_from_sender *= max_distance_from_sender
		sender_mob_mover = shooter.get_node_or_null("MobMoverComponent")
	
	if lifetime == 0:
		return
	if fade_out_delete:
		await get_tree().create_timer(lifetime - 1, false).timeout
		var _tween = create_tween()
		_tween.tween_property(parent, "modulate:a", 0, 1)
		await get_tree().create_timer(1, false).timeout
	else:
		await get_tree().create_timer(lifetime, false).timeout
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
			var _direction: Vector2 = (global_position - shooter.global_position)
			direction = _direction.angle()
			if rotate_speed == 0:
				parent.global_rotation = direction
			if _direction.length_squared() < 20:
				_delete()
				return
			elif max_distance_from_sender != 0 and _direction.length_squared() > max_distance_from_sender and sender_mob_mover:
				sender_mob_mover.throw(_direction, parent.velocity.length() * 2)
		speed -= speed_decreasing
	elif stop_when_null_speed:
		pass
	
	if speed <= 0 and !return_to_sender and !stop_when_null_speed:
		_delete()
	
	parent.velocity = Vector2(speed, 0).rotated(direction)
	parent.move_and_collide(parent.velocity * delta)
	if rotate_speed != 0:
		parent.rotation += rotate_speed * delta

func _delete() -> void:
	if weapon and return_to_sender:
		weapon.bullets += instant_bullets_recover_to_sender
		weapon._cooldown()
	
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
	
	var area2d: Area2D = parent.get_node_or_null("Area2D")
	if area2d:
		area2d.queue_free()
	
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
	
	@warning_ignore_start("narrowing_conversion")
	speed *= parry_speed_boost
	rotate_speed *= parry_speed_boost
	throw_speed *= parry_speed_boost
	damage *= parry_damage_modifier
	@warning_ignore_restore("narrowing_conversion")

func explode() -> void:
	if explosion_scene and !sploded:
		sploded = true
		var instance: Node = explosion_scene.instantiate()
		instance.global_position = global_position
		if shooter:
			instance.source = shooter
		scene.add_child(instance)

func _on_body_entered(body: Node2D) -> void:
	if !body or !can_hit or body == parent:
		return
	if body.has_node("ProjectileIgnoreComponent"):
		return
	var projectile_comp: ProjectileComponent = body.get_node_or_null("ProjectileComponent")
	if projectile_comp and shooter_faction and projectile_comp.shooter_faction and projectile_comp.shooter_faction.faction == shooter_faction.faction:
		if explode_on_projectile_hit:
			explode_on_delete = true
			_delete()
			return
		elif can_parry_weapon:
			var _direction: Vector2 = -body.velocity
			projectile_comp.speed *= 2
			if shooter_faction:
				var nearest_enemy = _get_nearest_enemy()
				if nearest_enemy:
					_direction = nearest_enemy.global_position - parent.global_position
			body.global_position = parent.global_position
			can_parry_weapon.parry_projectile(body, projectile_comp, _direction)
	if max_penetrations != 0 and penetration_damaged_bodies.has(body):
		return
	if shooter and shooter_faction:
		if shooter == body:
			return
		var body_faction: FactionComponent = body.get_node_or_null("FactionComponent")
		if (!ignore_faction and 
			body_faction):
			if shooter_faction.faction == body_faction.faction:
				return
	
	if reflect(body):
		return
	if hit_sound:
		hit_sound.play()
	
	var modified_damage: float = damage * damage_modifier
	var health_comp: HealthComponent = body.get_node_or_null("HealthComponent")
	if health_comp:
		if health_comp.INVINCIBLE:
			return
		if !shooter:
			shooter = null
		@warning_ignore("narrowing_conversion")
		health_comp.take_damage(modified_damage, shooter, "Projectile" ,ignore_armor)
		if delayed_damage != 0 and delayed_damage_delay != 0:
			@warning_ignore("narrowing_conversion")
			health_comp.set_delayed_damage(delayed_damage * damage_modifier, delayed_damage_delay)
		if max_penetrations != 0 and can_penetrate:
			penetration_damaged_bodies.append(body)
			penetrations += 1
	else:
		max_penetrations = 0
	
	EventBusManager.projectile_hit.emit(body, parent)
	
	if stamina_damage != 0:
		var stamina_comp: StaminaComponent = body.get_node_or_null("StaminaComponent")
		if stamina_comp:
			stamina_comp.take_stamina_damage(stamina_damage * damage_modifier, shooter)
	
	var mover_comp: MobMoverComponent = body.get_node_or_null("MobMoverComponent")
	if mover_comp:
		if throw_speed != 0:
			mover_comp.throw(parent.velocity, throw_speed, shooter)
		if fall_time != 0:
			mover_comp.drop(fall_time)
		
	if embed_on_hit:
		parent.reparent.call_deferred(body)
		deleted = true
		moving = false
		parent.velocity = Vector2.ZERO
		can_hit = false
		if body is PhysicsBody2D:
			await tree_entered
			var _tween = create_tween()
			_tween.tween_property(parent, "position", Vector2.ZERO, 0.2)
		return
	
	var body_weapon_user_comp: WeaponUserComponent = body.get_node_or_null("WeaponUserComponent")
	if body_weapon_user_comp and can_parry_weapon:
		if body_weapon_user_comp.selected_weapon and body_weapon_user_comp.selected_weapon.swinging:
			can_parry_weapon.parry_weapon(body_weapon_user_comp.selected_weapon, body)
	
	if bounces < max_bounces and body is not PhysicsBody2D:
		bounces += 1
		var bounce_direction = (parent.global_position - body.global_position).normalized()
		var velocity = parent.velocity
		var dot = velocity.dot(bounce_direction)
		var final_rotation: float = (velocity - 2 * dot * bounce_direction).angle()
		direction = final_rotation
		parent.rotation = final_rotation
		return
	
	if max_penetrations == 0 and delete_on_hit:
		_delete()
	elif max_penetrations < penetrations and can_penetrate:
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
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if check_in_targeted and targeted_enemies.has(enemy):
			continue
		var faction_comp: FactionComponent = enemy.get_node_or_null("FactionComponent")
		if !faction_comp or faction_comp.faction == shooter_faction.faction:
			continue
		enemies.append(enemy)
	
	return enemies
