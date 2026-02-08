class_name MeleeWeapon extends Weapon

@export var damage: int = 10
@export var attack_range: int = 4096 # 64^2
@export var slash_effect: PackedScene = preload("res://Scenes/Effects/Slash.tscn")

@export var parry_effect: PackedScene = preload("res://Scenes/Effects/Particles/ParryEffect.tscn")
@export var parry_sound: AudioStreamPlayer2D
@export var parry_color: Color = Color(5.565, 1.36, 1.878, 1.0)

@export var attack_sound: AudioStreamPlayer2D
@export var miss_sound: AudioStreamPlayer2D

@export var can_parry_weapon: bool = true
@export var parry_force: float = 0

@export var throw_speed: int = 300
@export var throw_stop_speed: int = 10
@export var drop_enemy_delay: float = 0.0

func attack(raiser, npc = true) -> Dictionary:
	if !raiser.has_method("get_attack_direction"):
		return {}
	
	if cooldown or !can_attack or swinging:
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
	
	for i in range(5):
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
		
		if enemy in attacked_enemies:
			continue
		
		if enemy.has_node("MeleeAttackIgnoreComponent"):
			continue
		
		if (enemy.global_position - parent.global_position).length() > attack_range:
			continue
		
		var _attacked = _melee_attack_target(enemy, direction, true)
		
		if _attacked and enemy:
			_targets[i] = enemy
			attacked_enemies.append(enemy)
	
	if _targets.is_empty():
		_melee_attack_target(null, direction, true)
	
	return _targets

func _melee_attack_target(target, direction = null, multiple_attack = false) -> bool:
	if slash_effect:
		var _slash_effect: Node = slash_effect.instantiate()
		_slash_effect.global_rotation = direction.angle() + 90
		parent.add_child(_slash_effect)
		if _slash_effect.has_node("AnimationPlayer"):
			_slash_effect.get_node("AnimationPlayer").play("Slash")
	
	if (target and (target.global_position - parent.global_position).length() > attack_range):
		target = null
	
	if attack_sound and target:
		attack_sound.play()
	elif miss_sound:
		miss_sound.play()
	
	if multiple_attack:
		_cooldown()
	
	if animation_component:
		if attack_rotation_multiplier != 0:
			animation_component.lean_to_direction(direction, 3, 0.2, attack_rotation_multiplier)
		if attack_shift_multiplier != 0:
			animation_component.shift_to_direction(direction, 0.2, attack_shift_multiplier)
	
	if !target:
		EventBusManager.melee_miss.emit(parent, self)
		return false
	
	if target.has_node("ProjectileComponent") and parry_force != 0:
		var projectile = target.get_node("ProjectileComponent")
		if projectile.parriable == false:
			return false
		parry_projectile(target, projectile, direction)
	
	if can_parry_weapon and target.has_node("WeaponUserComponent"):
		var target_weapon_user_component = target.get_node("WeaponUserComponent")
		if target_weapon_user_component and target_weapon_user_component.selected_weapon:
			var weapon = target_weapon_user_component.selected_weapon 
			if weapon.swinging and weapon.parriable:
				parry_weapon(weapon, target)
	
	if target.has_node("HealthComponent"):
		target.get_node("HealthComponent").take_damage(damage * damage_modifier, parent)
	
	if target.has_node("MobMoverComponent"):
		if throw_speed != 0:
			target.get_node("MobMoverComponent").throw(direction, throw_speed, parent, throw_stop_speed)
		if drop_enemy_delay != 0:
			target.get_node("MobMoverComponent").drop(drop_enemy_delay)
	
	if parent.has_node("MobMoverComponent"):
		if self_throw_speed != 0:
			parent.get_node("MobMoverComponent").throw(-direction, self_throw_speed, self_throw_stop_speed)
	
	return true

func parry_weapon(weapon, target) -> void:
	EventBusManager.parry.emit(parent, "Weapon")
	weapon.swinging_cancelled = true
	parry_effects()
	
	if target.has_node("HealthComponent"):
		target.get_node("HealthComponent").take_damage(damage * 0.5, parent)
	
	var direction = (target.global_position - parent.global_position)
	
	if target.has_node("MobMoverComponent"):
		target.get_node("MobMoverComponent").throw(-direction, 300, 50)
		target.get_node("MobMoverComponent").drop(0.5)

func parry_projectile(target, projectile, direction) -> void:
		EventBusManager.parry.emit(parent, "Projectile")
		var angle = direction.normalized().angle()
		target.modulate = parry_color
		target.global_rotation = angle
		projectile.speed *= projectile.parry_speed_boost
		projectile.damage *= parry_force
		projectile.rotate_speed *= projectile.parry_speed_boost
		projectile.throw_speed *= projectile.parry_speed_boost
		projectile.direction = angle
		projectile.shooter = parent
		
		parry_effects()
		
		var trail = TrailEffectComponent.new()
		trail.trail_lifetime = 0.2
		trail.end_color = Color(0.544, 0.0, 0.578, 0.0)
		var colors: Array[Color] = [
			Color(4.455, 0.0, 0.0, 1.0),
			Color(3.236, 0.576, 1.751, 1.0)]
		trail.colors = colors
		target.add_child(trail)

func parry_effects():
	if parry_sound:
		parry_sound.play()
	if parry_effect:
		var inst: Node = parry_effect.instantiate()
		inst.global_position = parent.global_position
		scene.add_child(inst)
