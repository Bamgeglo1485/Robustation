class_name RangeWeapon extends Weapon

@export var projectile: PackedScene
@export var spread_angle: int = 10

@export var bullets_max_count: int = 2
@export var bullets: int = bullets_max_count
@export var bullets_recover_count: int = 2

@export var shots: int = 3
@export var shots_angle: int = 15

@export var case_scene: PackedScene

@export var shoot_sound: AudioStreamPlayer2D
@export var empty_shoot_sound: AudioStreamPlayer2D
@export var bullets_end_sound: AudioStreamPlayer2D
@export var bullets_recover_sound: AudioStreamPlayer2D

@export var bullets_recovery_delay: float = 4
@export var gun_fire_effect: PackedScene

@warning_ignore("unused_parameter")
func attack(raiser, npc = true):
	if cooldown == true or can_attack == false or swinging == true or projectile == null or not raiser.has_method("get_attack_direction"):
		return
	
	if bullets == 0:
		if empty_shoot_sound != null:
			empty_shoot_sound.play()
		return
	
	await _swing(raiser.get_attack_direction())
	
	var direction = raiser.get_attack_direction()
	EventBusManager.gun_shoot_event.emit(parent, self, direction)
	
	if parent.has_node("MobMoverComponent"):
		if self_throw_speed != 0:
			parent.get_node("MobMoverComponent").throw(-direction, self_throw_speed, null, self_throw_stop_speed)
	
	if shots > 1:
		var total_spread = deg_to_rad(shots_angle)
		@warning_ignore("incompatible_ternary")
		var angle_step = total_spread / (shots - 1) if shots > 1 else 0
		var start_angle = -total_spread / 2
		
		var possible_shots: int = 0
		if bullets < shots:
			possible_shots = bullets
		else:
			possible_shots = shots
		
		bullets -= possible_shots
		
		for i in range(possible_shots):
			var shot_direction = direction.rotated(start_angle + angle_step * i)
			_projectile_shoot(shot_direction)
			
	else:
		_projectile_shoot(direction)
		bullets -= 1
	
	if shoot_sound != null:
		shoot_sound.play()
	
	if bullets <= 0:
		if timers_timescaled == true:
			get_tree().create_timer(bullets_recovery_delay).timeout.connect(_on_bullets_recover)
		else:
			get_tree().create_timer(bullets_recovery_delay, true, false, true).timeout.connect(_on_bullets_recover)
		if bullets_end_sound != null:
			bullets_end_sound.play()
	
	if case_scene != null:
		var case = case_scene.instantiate()
		case.global_position = parent.global_position
		scene.add_child(case)
	
	if gun_fire_effect != null:
		var fire = gun_fire_effect.instantiate()
		fire.global_position = parent.global_position
		fire.global_rotation = direction.angle()
		fire.emitting = true
		scene.add_child(fire)
	
	_cooldown()
	
	if animation_component != null:
		if attack_rotation_multiplier != 0:
			animation_component.lean_to_direction(direction, 3, 0.2, attack_rotation_multiplier)
		if attack_shift_multiplier != 0:
			animation_component.shift_to_direction(direction, 0.2, attack_shift_multiplier)

func _projectile_shoot(direction):
	if direction > Vector2(1, 1):
		direction = direction.normalized()
	
	var weapon_spread: int = spread_angle
	var spread: float = 0
	
	if weapon_spread != 0:
		spread = deg_to_rad(randf_range(-weapon_spread, weapon_spread))
		direction = direction.rotated(spread)
	
	var angle = direction.normalized().angle()
	
	var inst_projectile = projectile.instantiate()
	
	if not inst_projectile.has_node("ProjectileComponent"):
		inst_projectile.queue_free()
		return
	
	var projectile_component = inst_projectile.get_node("ProjectileComponent")
	
	inst_projectile.global_position = parent.global_position
	inst_projectile.global_rotation = angle
	
	projectile_component.direction = angle
	projectile_component.shooter = parent
	
	if scene != null:
		scene.add_child.call_deferred(inst_projectile)

func _on_bullets_recover():
	bullets += bullets_recover_count
	if bullets_recover_sound != null:
		bullets_recover_sound.play()
