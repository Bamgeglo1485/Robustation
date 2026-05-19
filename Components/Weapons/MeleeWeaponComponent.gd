class_name MeleeWeapon extends Weapon

@export var damage: float = 10
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
@onready var base_throw_speed: int = throw_speed
@onready var base_self_throw_speed: int = self_throw_speed
@onready var parent_mob_mover_component: MobMoverComponent
@onready var parent_faction: FactionComponent
@export var piercing_attack_animation: bool = false
@export var tile_destruction_audio: AudioStreamPlayer2D

@export var can_clear_mark: bool = false

@export var attack_angle: float = 90
@export var ray_count: int = 15
@export var parry_extra_bounces: int = 0
@export var parry_extra_penetrations: int = 0

@export_category("QTE")
@export var qte_icon: Range
@export var qte_icon_perfect_frame: Panel
@export var qte_enabled: bool = false
@export var qte_max_time: float = 1.5
@export var base_qte_perfect_time_min: float = 0.5
@export var base_qte_perfect_time_max: float = 0.9
@export var qte_time_mod: float = 1.0
@export var qte_time_speed: float = 1
@export var qte_perfect_damage_modifier: float = 4.0
@export var qte_perfect_heal_modifier_from_max: float = 0.15
@export var qte_perfect_heal_modifier_from_max_modifier: float = 1.0
@export var qte_perfect_sound: AudioStreamPlayer2D
@export var qte_perfect_time_sound: AudioStreamPlayer2D
@export var qte_perfect_effect: PackedScene
@export var qte_icon_random_perfect_range_min: float = 0
@export var qte_icon_random_perfect_range_max: float = 0.4
var qte_perfect_time_min: float = base_qte_perfect_time_min
var qte_perfect_time_max: float = base_qte_perfect_time_max
var health_component: HealthComponent
var qte_time: float = 0.0
var qte_move_back: bool = false
var qte_active: bool = false
var qte_tween: Tween
var perfect_time_sound_played: bool = false

var excluded_nodes: Array

func _physics_process(delta: float) -> void:
	if qte_enabled and qte_active:
		if !qte_move_back:
			qte_time += delta * qte_time_speed * qte_time_mod / Engine.time_scale
			if qte_time >= qte_max_time:
				qte_time = qte_max_time
				qte_move_back = true
		else:
			qte_time -= delta * qte_time_speed * qte_time_mod  / Engine.time_scale
			if qte_time <= 0:
				qte_time = 0
				qte_move_back = false
		if qte_time > qte_perfect_time_min and qte_time < qte_perfect_time_max and !perfect_time_sound_played and qte_perfect_time_sound:
			qte_perfect_time_sound.play()
			perfect_time_sound_played = true
		if qte_icon:
			qte_icon.value = qte_time

func on_release(_raiser) -> void:
	if qte_enabled and qte_active:
		if qte_tween:
			qte_tween.kill()
		qte_tween = create_tween()
		qte_tween.set_parallel()
		if qte_time > qte_perfect_time_min and qte_time < qte_perfect_time_max:
			minor_damage_modifiers["qte_perfect"] = qte_perfect_damage_modifier
			qte_tween.tween_property(qte_icon, "modulate:g", 4.0, 0.1)
			qte_active = false
			if health_component:
				@warning_ignore("narrowing_conversion")
				health_component.take_damage(-health_component.max_health * qte_perfect_heal_modifier_from_max * qte_perfect_heal_modifier_from_max_modifier, null, "Heal", true)
			if qte_perfect_sound:
				qte_perfect_sound.play()
			if qte_perfect_effect:
				var inst: Node2D = qte_perfect_effect.instantiate()
				inst.global_position = parent.global_position
				scene.add_child.call_deferred(inst)
		else:
			qte_tween.tween_property(qte_icon, "modulate:r", 4.0, 0.1)
		qte_tween.tween_property(qte_icon, "modulate:a", 0.0, 0.2)
		qte_active = false
		perfect_time_sound_played = false
		
		await _try_melee_attack(_raiser.get_attack_direction())
		minor_damage_modifiers["qte_perfect"] = 1.0

func _ready() -> void:
	super._ready()
	parent_mob_mover_component = parent.get_node_or_null("MobMoverComponent")
	parent_faction = parent.get_node_or_null("FactionComponent")
	if qte_enabled:
		health_component = parent.get_node_or_null("HealthComponent")
	
	excluded_nodes.append(parent)
	for child in parent.get_children():
		if child is Area2D:
			excluded_nodes.append(child)
	
	if !tile_destruction_audio:
		tile_destruction_audio = AudioStreamPlayer2D.new()
		add_child(tile_destruction_audio)
		tile_destruction_audio.max_distance = 600

func attack(raiser, npc = true) -> Dictionary:
	if !raiser.has_method("get_attack_direction"):
		return {}
	
	if cooldown or !can_attack or swinging:
		return {}
	
	if parent_weapon and parent_weapon is RangeWeapon and parent_weapon.bullets == 0:
		return {}
	
	EventBusManager.try_melee_attack.emit(parent, self)
	
	if qte_enabled:
		qte_time = 0
		qte_active = true
		if qte_tween:
			qte_tween.kill()
		qte_tween = create_tween()
		qte_tween.tween_property(qte_icon, "modulate:a", 1.0, 0.1)
		qte_icon.modulate.g = 1.0
		qte_icon.modulate.r = 1.0
		var range_of_perfect: float = randf_range(qte_icon_random_perfect_range_min, qte_icon_random_perfect_range_max)
		qte_perfect_time_max = base_qte_perfect_time_max + range_of_perfect
		qte_perfect_time_min = base_qte_perfect_time_min + range_of_perfect
		qte_icon_perfect_frame.position.x = _get_thumb_global_position(qte_icon, (qte_perfect_time_max + qte_perfect_time_min) / 2).x - qte_icon.global_position.x
		return {}
	
	if npc:
		var succefull_swing: bool = await attack_logic(raiser)
		if !succefull_swing:
			return {}
		_melee_attack_target(raiser.get_attack_target(), raiser.get_attack_direction())
	else:
		var succefull_swing: bool = await attack_logic(raiser)
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
	
	var angle_step: float = attack_angle / (ray_count - 1) if ray_count > 1 else 0.0
	var start_angle: float = -attack_angle / 2.0
	
	for i in range(ray_count):
		var angle_offset: float = deg_to_rad(i * angle_step + start_angle)
		var ray_direction: Vector2 = direction.rotated(angle_offset)
		var ray_start: Vector2
		var ray_end: Vector2
		if ray_count > 1:
			ray_start = parent.global_position - ray_direction * 0.4
			ray_end = parent.global_position + ray_direction * attack_range
		else:
			ray_start = parent.get_global_mouse_position()
			ray_end = parent.get_global_mouse_position()
		
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
		query.collision_mask = 1 | 2 | 4 | 7 | 12
		query.collide_with_areas = true
		query.hit_from_inside = true
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
		if enemy is not TileMapLayer and (enemy.global_position - parent.global_position).length() > attack_range:
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

func _melee_attack_target(target, direction: Vector2, 
multiple_attack: bool = false) -> bool:
	
	if !multiple_attack:
		_attack_animation(direction)
	
	if target is TileMapLayer:
		var tile_pos = target.local_to_map(target.to_local(parent.global_position + direction.normalized() * 32))
		var tile_data = target.get_cell_tile_data(tile_pos)
		if tile_data and !tile_data.has_custom_data("Invincible") and tile_data.has_custom_data("Health"):
			var health: float = tile_data.get_custom_data("Health")
			tile_data.set_custom_data("Health", health - damage)
			if health <= 0:
				target.set_cell(tile_pos)
				if tile_data.has_custom_data("DestructionSound"):
					tile_destruction_audio.stream = tile_data.get_custom_data("DestructionSound")
					tile_destruction_audio.play()
		else:
			target = null
	
	if target is not TileMapLayer and (target and (target.global_position - parent.global_position).length() > attack_range):
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
	
	var reflect_component = target.get_node_or_null("ReflectComponent")
	if reflect_component and target != parent:
		if reflect_component.melee_reflect(parent, self):
			return false
	
	var projectile = target.get_node_or_null("ProjectileComponent")
	if parry_force != 0 and projectile:
		if projectile.parriable == false:
			return false
		parry_projectile(target, projectile, direction)
	
	var target_weapon_user_component = target.get_node_or_null("WeaponUserComponent")
	if can_parry_weapon and target_weapon_user_component and target_weapon_user_component.selected_weapon:
		var weapon = target_weapon_user_component.selected_weapon 
		if weapon.swinging and weapon.parriable:
			parry_weapon(weapon, target)
	
	var target_health_component: HealthComponent = target.get_node_or_null("HealthComponent")
	if target_health_component:
		target_health_component.take_damage(damage * damage_modifier * damage_multiplier * _get_minor_modifiers(), parent, "Melee", ignore_armor)
		if delayed_damage != 0 and delayed_damage_delay != 0:
			target_health_component.set_delayed_damage(delayed_damage * damage_multiplier * _get_minor_modifiers(), delayed_damage_delay)
	
	var target_mover: MobMoverComponent = target.get_node_or_null("MobMoverComponent")
	if target_mover and direction:
		if throw_speed != 0:
			target_mover.throw(direction, throw_speed * minor_damage_modifier, parent, throw_stop_speed)
		if drop_enemy_delay != 0:
			target_mover.drop(drop_enemy_delay, drop_forced, drop_resistance_force)
		throw_speed = base_throw_speed
	
	var target_stamina: StaminaComponent = target.get_node_or_null("StaminaComponent")
	if target_stamina and stamina_damage != 0:
		target_stamina.take_stamina_damage(stamina_damage * damage_modifier, parent)
	
	if self_throw_speed != 0 and !multiple_attack:
		if parent_mob_mover_component and direction:
			parent_mob_mover_component.throw(-direction, self_throw_speed, parent, self_throw_stop_speed, true, false)
			self_throw_speed = base_self_throw_speed
	
	return true

func parry_weapon(weapon, target) -> void:
	EventBusManager.parry.emit(parent, "Weapon", true)
	weapon.swinging_cancelled = true
	parry_effects()
	if parry_sound and weapon is MeleeWeapon and weapon.play_parried_sound:
		parry_sound.play()
	
	var health: HealthComponent = target.get_node("HealthComponent")
	if health:
		health.take_damage(damage * 0.5, parent)
	
	var direction = (target.global_position - parent.global_position)
	
	var target_mob_mover: MobMoverComponent = target.get_node_or_null("MobMoverComponent")
	if target_mob_mover:
		target_mob_mover.throw(-direction, 300, parent, 50, true, self_throw_rewrite)
		target_mob_mover.drop(0.5)

func _attack_animation(direction):
	if !weapon_sprite:
		return
	
	if !piercing_attack_animation:
		weapon_sprite.slash_animation(direction, attack_animation_speed, attack_angle)
	else:
		weapon_sprite.piercing_animation(direction, attack_animation_speed)

func parry_projectile(projectile: Node2D, projectile_component: ProjectileComponent, direction: Vector2) -> void:
	if !projectile_component.parriable:
		return
	# To prevent shotgun projectile boost spamming
	if is_instance_valid(projectile_component.weapon) and projectile_component.weapon.overheat_enabled and projectile_component.shooter == parent:
		if projectile_component.weapon.overheat > projectile_component.weapon.alert_on_heat:
			projectile_component.shooter_faction = null
			projectile_component.shooter = null
			projectile_component.direction = (parent.global_position - projectile.global_position).angle()
			return
	var enemy: bool = false
	if projectile_component.shooter != parent:
		enemy = true
	EventBusManager.parry.emit(parent, "Projectile", enemy)
	var angle = direction.angle()
	projectile.modulate = parry_color
	projectile.global_rotation = angle
	projectile_component.damage *= parry_force * _get_minor_modifiers() * damage_modifier
	projectile_component.direction = angle
	projectile_component.shooter = parent
	projectile_component.shooter_faction = parent_faction
	projectile_component.on_parried()
	if parry_extra_bounces:
		projectile_component.max_bounces += parry_extra_bounces
	if parry_extra_penetrations:
		projectile_component.max_penetrations += parry_extra_penetrations
	
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
	projectile.global_position = parent.global_position

func parry_effects():
	if parry_effect:
		var inst: Node = parry_effect.instantiate()
		inst.global_position = parent.global_position
		scene.add_child(inst)

func _get_thumb_global_position(slider: HSlider, value: float) -> Vector2:
	var global_pos = slider.global_position
	
	var percent = (value - slider.min_value) / (slider.max_value - slider.min_value)
	
	var thumb_global_x = global_pos.x + (slider.size.x * percent)
	var thumb_global_y = global_pos.y + slider.size.y / 2
	
	return Vector2(thumb_global_x, thumb_global_y)
