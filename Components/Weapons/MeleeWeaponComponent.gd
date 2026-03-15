class_name MeleeWeapon extends Weapon

@export var damage: int = 10
@export var stamina_damage: int = 0
@export var attack_range: int = 64
@export var ignore_armor: bool = false

@export var delayed_damage: int = 0
@export var delayed_damage_delay: int = 0

@export var parry_effect: PackedScene = preload("res://Scenes/Effects/Particles/ParryEffect.tscn")
@export var parry_sound: AudioStreamPlayer2D
@export var parry_color: Color = Color(5.565, 1.36, 1.878, 1.0)
@export var play_parried_sound: bool = false

@export var attack_sound: AudioStreamPlayer2D
@export var miss_sound: AudioStreamPlayer2D

@export var can_parry_weapon: bool = true
@export var parry_force: float = 0

@export var attack_animation_speed: float = 0.3
@export var throw_speed: int = 300
@export var throw_stop_speed: int = 10
@export var drop_resistance_force: int = 1
@export var drop_forced: bool = false
@export var drop_enemy_delay: float = 0.0
@onready var base_throw_speed: float = throw_speed
@onready var base_self_throw_speed: float = self_throw_speed
@onready var parent_mob_mover_component: MobMoverComponent
@export var piercing_attack_animation: bool = false

func _ready() -> void:
	super._ready()
	parent_mob_mover_component = parent.get_node_or_null("MobMoverComponent")

func attack(raiser, npc = true) -> Dictionary:
	if !raiser.has_method("get_attack_direction"):
		return {}
	
	if cooldown or !can_attack or swinging:
		return {}
	
	if parent_weapon and parent_weapon is RangeWeapon and parent_weapon.bullets == 0:
		return {}
	
	if npc:
		var succefull_swing = await attack_logic(raiser)
		if !succefull_swing:
			return {}
		_melee_attack_target(raiser.get_attack_target(), raiser.get_attack_direction())
	else:
		var succefull_swing = await attack_logic(raiser)
		if !succefull_swing:
			return {}
		return await _try_melee_attack(raiser.get_attack_direction())
	return {}

func attack_logic(raiser) -> bool:
	await _swing(raiser.get_attack_direction())
	if swinging_cancelled:
		return false
	_cooldown()
	return true

func _try_melee_attack(direction) -> Dictionary:
	await get_tree().physics_frame
	var space_state = parent.get_world_2d().direct_space_state
	var _targets: Dictionary
	var attacked_enemies: Array = []
	
	for i in range(10):
		var angle_offset: float = deg_to_rad(i * 20 - 90)
		var ray_direction: Vector2 = direction.rotated(angle_offset)
		var ray_start: Vector2 = parent.global_position - ray_direction * 0.2
		var ray_end: Vector2 = parent.global_position + ray_direction * attack_range
		
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
		query.collision_mask = 1 | 2 | 3 | 4
		query.collide_with_areas = true
		
		var excluded_nodes: Array
		excluded_nodes.append(parent)
		for child in parent.get_children():
			if child is Area2D:
				excluded_nodes.append(child)
		
		query.exclude = excluded_nodes
		
		var result = space_state.intersect_ray(query)
		
		if result.is_empty():
			continue
		
		var enemy = result.collider
		if enemy is Area2D:
			enemy = enemy.get_parent()
		
		if attacked_enemies.has(enemy):
			continue
		
		if enemy.has_node("MeleeAttackIgnoreComponent"):
			continue
		if (enemy.global_position - parent.global_position).length() > attack_range:
			continue
		
		var _attacked = _melee_attack_target(enemy, direction, true)
		
		if enemy:
			_targets[i] = enemy
			attacked_enemies.append(enemy)
	
	if _targets.is_empty():
		_melee_attack_target(null, direction, true)
	else:
		if self_throw_speed != 0:
			if parent_mob_mover_component and direction:
				parent_mob_mover_component.throw(-direction, self_throw_speed, parent, self_throw_stop_speed)
				@warning_ignore("narrowing_conversion")
				self_throw_speed = base_self_throw_speed
	
	_attack_animation(direction)
	return _targets

func _melee_attack_target(target: Node2D, direction: Vector2, 
multiple_attack: bool = false) -> bool:
	
	if !multiple_attack:
		_attack_animation(direction)
	
	if (target and (target.global_position - parent.global_position).length() > attack_range):
		target = null
	
	if attack_sound and target:
		attack_sound.play()
		
	elif miss_sound:
		miss_sound.play()
	
	if multiple_attack:
		_cooldown()
	
	if animation_component and direction:
		if attack_rotation_multiplier != 0:
			animation_component.lean_to_direction(direction, 3, 0.2, attack_rotation_multiplier)
		if attack_shift_multiplier != 0:
			animation_component.shift_to_direction(direction, 0.2, attack_shift_multiplier)
	
	if !target:
		EventBusManager.melee_miss.emit(parent, self)
		return false
	
	var reflect_component = target.get_node_or_null("ReflectMeleePerkComponent")
	if reflect_component and target != parent:
		if randf() < reflect_component.chance:
			reflect_component.reflect(parent, self)
			return false
	
	var projectile = target.get_node_or_null("ProjectileComponent")
	if parry_force != 0 and projectile:
		if projectile.parriable == false:
			return false
		parry_projectile(target, projectile, direction)
	
	var target_weapon_user_component = target.get_node_or_null("WeaponUserComponent")
	if can_parry_weapon and target_weapon_user_component:
		if target_weapon_user_component and target_weapon_user_component.selected_weapon:
			var weapon = target_weapon_user_component.selected_weapon 
			if weapon.swinging and weapon.parriable:
				parry_weapon(weapon, target)
	
	var target_health_component: HealthComponent = target.get_node_or_null("HealthComponent")
	if target_health_component:
		@warning_ignore_start("narrowing_conversion")
		target_health_component.take_damage(damage * damage_modifier * _get_minor_modifiers(), parent, "Melee", ignore_armor)
		if delayed_damage != 0 and delayed_damage_delay != 0:
			target_health_component.set_delayed_damage(delayed_damage * _get_minor_modifiers(), delayed_damage_delay)
	
	var target_mover: MobMoverComponent = target.get_node_or_null("MobMoverComponent")
	if target_mover and direction:
		if throw_speed != 0:
			target_mover.throw(direction, throw_speed * minor_damage_modifier, parent, throw_stop_speed)
		if drop_enemy_delay != 0:
			target_mover.drop(drop_enemy_delay, drop_forced, drop_resistance_force)
		throw_speed = base_throw_speed
	
	if target.has_node("StaminaComponent") and stamina_damage != 0:
		target.get_node("StaminaComponent").take_stamina_damage(stamina_damage * damage_modifier, parent)
	
	if self_throw_speed != 0 and !multiple_attack:
		if parent_mob_mover_component and direction:
			parent_mob_mover_component.throw(-direction, self_throw_speed, parent, self_throw_stop_speed, true, false)
			self_throw_speed = base_self_throw_speed
	
	return true

func parry_weapon(weapon, target) -> void:
	EventBusManager.parry.emit(parent, "Weapon")
	weapon.swinging_cancelled = true
	parry_effects()
	if parry_sound and weapon is MeleeWeapon and weapon.play_parried_sound:
		parry_sound.play()
	
	if target.has_node("HealthComponent"):
		target.get_node("HealthComponent").take_damage(damage * 0.5, parent)
	
	var direction = (target.global_position - parent.global_position)
	
	var target_mob_mover: MobMoverComponent = target.get_node_or_null("MobMoverComponent")
	if target_mob_mover:
		target_mob_mover.throw(-direction, 300, parent, 50, true, self_throw_rewrite)
		target_mob_mover.drop(0.5)

func _attack_animation(direction):
	if !weapon_sprite:
		return
	
	if !piercing_attack_animation:
		weapon_sprite.slash_animation(direction, attack_animation_speed)
	else:
		weapon_sprite.piercing_animation(direction, attack_animation_speed)

func parry_projectile(projectile: Node2D, projectile_component: ProjectileComponent, direction: Vector2) -> void:
	if !projectile_component.parriable:
		return
	EventBusManager.parry.emit(parent, "Projectile")
	var angle = direction.angle()
	projectile.modulate = parry_color
	projectile.global_rotation = angle
	projectile_component.speed *= projectile_component.parry_speed_boost
	projectile_component.damage *= parry_force
	projectile_component.rotate_speed *= projectile_component.parry_speed_boost
	projectile_component.throw_speed *= projectile_component.parry_speed_boost
	projectile_component.direction = angle
	projectile_component.shooter = parent
	projectile_component.on_parried()
		
	if parry_sound:
		parry_sound.play()
	parry_effects()
	
	var trail = TrailEffectComponent.new()
	trail.trail_lifetime = 0.2
	trail.end_color = Color(0.544, 0.0, 0.578, 0.0)
	var colors: Array[Color] = [
		Color(4.455, 0.0, 0.0, 1.0),
		Color(3.236, 0.576, 1.751, 1.0)]
	trail.colors = colors
	projectile.add_child(trail)
	
	var trigger_on_parry: TriggerOnParryComponent = projectile.get_node("TriggerOnParryComponent")
	if trigger_on_parry:
		trigger_on_parry.trigger()

func parry_effects():
	if parry_effect:
		var inst: Node = parry_effect.instantiate()
		inst.global_position = parent.global_position
		scene.add_child(inst)
