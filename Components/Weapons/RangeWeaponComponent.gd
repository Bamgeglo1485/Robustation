class_name RangeWeapon extends Weapon

@export var projectile: PackedScene
@export var spread_angle: int = 10
@export var spread_modifier: float = 1.0

@export var bullets_max_count: int = 2
@export var bullets: int = bullets_max_count : set = set_bullets, get = get_bullets
@export var bullets_recover_count: int = 2

@export var shots: int = 3
@export var extra_shots: int = 0
@export var shots_angle: int = 15

@export var case_scene: PackedScene

@export var shoot_sound: AudioStreamPlayer2D
@export var empty_shoot_sound: AudioStreamPlayer2D
@export var bullets_end_sound: AudioStreamPlayer2D
@export var bullets_recover_sound: AudioStreamPlayer2D

@export var bullets_recovery_delay: float = 4
@export var gun_fire_effect: PackedScene
@export var projectile_can_parry_weapon: Weapon

@export var parent_shared_bullets: bool = true

@export var show_cooldown_on_icon: bool = false
@export var rope: Line2D

@export var flip_after_shoot: bool = true
@export var reload_animation: bool = true

@export var random_bullet_recover_delay_coef: float = 0.0

@export_category("Overheat")
@export var overheat_enabled: bool = false
@export var max_overheat: float = 7.0
@export var overheat_per_shoot_modifier: float = 1.0
@export var overheat_per_shoot: float = 2.0
@export var cool_delay: float = 0.1
@export var cool_count: float = 0.15
@export var min_overheat_damage_debuff: float = 0.3
@export var explosion_on_max_heat: PackedScene
@export var overheat_alert: AudioStreamPlayer2D
@export var alert_on_heat: float = 5.0
var cool_timer: Timer
var overheat: float

var bullets_recover_timer: Timer
var projectile_speed: float

func set_bullets(new_value) -> void:
	bullets = new_value
	clamp(bullets, 0, new_value)
	if parent_weapon:
		parent_weapon.bullets += new_value - bullets

func get_bullets() -> int:
	if !parent_weapon:
		return bullets
	
	return parent_weapon.bullets

func _ready() -> void:
	super._ready()
	
	if !parent_weapon:
		if overheat_enabled:
			cool_timer = Timer.new()
			cool_timer.ignore_time_scale = !timers_timescaled
			cool_timer.timeout.connect(_on_cool)
			cool_timer.one_shot = true
			cool_timer.wait_time = cool_delay
			cool_timer.autostart = true
			add_child(cool_timer)
		
		bullets_recover_timer = Timer.new()
		bullets_recover_timer.ignore_time_scale = !timers_timescaled
		bullets_recover_timer.timeout.connect(_on_bullets_recover)
		bullets_recover_timer.one_shot = true
		add_child(bullets_recover_timer)
	else:
		await parent_weapon.ready
		if parent_weapon is not RangeWeapon:
			return
		bullets_recover_timer = parent_weapon.bullets_recover_timer
		if overheat_enabled:
			cool_timer = parent_weapon.cool_timer
			cool_timer.timeout.connect(_on_cool)
			_overheat_visuals()
	
	if projectile:
		var inst: Node2D = projectile.instantiate()
		var projectile_comp: ProjectileComponent = inst.get_node_or_null("ProjectileComponent")
		if !projectile_comp:
			inst.queue_free()
			return
		projectile_speed = projectile_comp.speed
		inst.queue_free()
	
	swapped.connect(_on_swap)

func attack(raiser, _npc = true) -> void:
	if cooldown or !can_attack or swinging or !projectile or not raiser.has_method("get_attack_direction"):
		return
	if bullets == 0 or parent_weapon and parent_weapon.bullets == 0:
		if empty_shoot_sound:
			empty_shoot_sound.play()
		return
	
	await _swing(raiser.get_attack_direction())
	
	if overheat_enabled:
		overheat += overheat_per_shoot * overheat_per_shoot_modifier
		overheat = clamp(overheat, 0, max_overheat)
		if overheat_alert and overheat >= alert_on_heat:
			overheat_alert.play()
		if explosion_on_max_heat and overheat == max_overheat:
			var expl: Node2D = explosion_on_max_heat.instantiate()
			scene.add_child(expl)
			expl.global_position = parent.global_position
			overheat = 0
			_overheat_visuals()
			return
		_overheat_visuals()
	
	var direction = raiser.get_attack_direction()
	
	if flip_after_shoot and weapon_sprite:
		weapon_sprite.flip_hell_yeah()
	
	if parent.has_node("MobMoverComponent"):
		if self_throw_speed != 0:
			parent.get_node("MobMoverComponent").throw(-direction, self_throw_speed, null, self_throw_stop_speed, true, self_throw_rewrite)
	
	if shots > 1 and bullets >= 1:
		var total_spread: float = deg_to_rad(shots_angle)
		var angle_step: float = total_spread / (shots - 1) if shots > 1 else 0.0
		var start_angle: float = -total_spread * 0.5
		
		var possible_shots: int = 0
		if bullets < shots:
			possible_shots = bullets
		else:
			possible_shots = shots
		
		bullets -= possible_shots
		bullets = clamp(bullets, 0, bullets_max_count)
		
		for i in range(possible_shots + extra_shots):
			var shot_direction = direction.rotated(start_angle + angle_step * i)
			_projectile_shoot(shot_direction)
			
	else:
		_projectile_shoot(direction)
		bullets -= 1
	
	if shoot_sound:
		shoot_sound.play()
	
	if bullets == 0 and bullets_recovery_delay != 0 and bullets_recover_timer:
		if !parent_weapon:
			bullets_recover_timer.wait_time = bullets_recovery_delay
		else:
			bullets_recover_timer.wait_time = parent_weapon.bullets_recovery_delay
		if random_bullet_recover_delay_coef != 0:
			bullets_recover_timer.wait_time *= randf_range(1 - random_bullet_recover_delay_coef, 1 + random_bullet_recover_delay_coef)
		bullets_recover_timer.start()
		EventBusManager.bullets_end.emit(parent, self)
		if bullets_end_sound:
			bullets_end_sound.play()
	
	if case_scene:
		var case: Node = case_scene.instantiate()
		case.global_position = parent.global_position
		scene.add_child(case)
	
	if gun_fire_effect:
		var fire: Node = gun_fire_effect.instantiate()
		fire.global_position = parent.global_position
		fire.global_rotation = direction.angle()
		fire.emitting = true
		scene.add_child(fire)
	
	_cooldown()
	
	if animation_component:
		if attack_rotation_multiplier != 0:
			animation_component.lean_to_direction(direction, 3, 0.2, attack_rotation_multiplier)
		if attack_shift_multiplier != 0:
			animation_component.shift_to_direction(direction, 0.2, attack_shift_multiplier)

func _projectile_shoot(direction) -> Node2D:
	if direction > Vector2(1, 1):
		direction = direction.normalized()
	
	var weapon_spread: float = spread_angle * spread_modifier
	var spread: float = 0.0
	
	if weapon_spread != 0:
		spread = deg_to_rad(randf_range(-weapon_spread, weapon_spread))
		direction = direction.rotated(spread)
	
	var angle: float = direction.normalized().angle()
	
	var instance: Node = projectile.instantiate()
	EventBusManager.projectile_shoot.emit(parent, self, direction, instance)
	
	if instance.has_node("ProjectileComponent"):
		var projectile_component: ProjectileComponent = instance.get_node("ProjectileComponent")
		
		instance.global_position = parent.global_position
		instance.global_rotation = angle
		
		projectile_component.direction = angle
		projectile_component.shooter = parent
		projectile_component.weapon = self
		if projectile_can_parry_weapon:
			projectile_component.can_parry_weapon = projectile_can_parry_weapon
		if rope:
			rope.visible = true
			projectile_component.rope = rope
			if rope.material:
				rope.material.set_shader_parameter("wave_amplitude", 0.15)
				var tween: Tween = create_tween()
				tween.set_trans(Tween.TRANS_SINE)
				tween.set_ease(Tween.EASE_IN_OUT)
				tween.tween_property(rope.material, "shader_parameter/wave_amplitude", 0, 0.5)
		if scene:
			scene.add_child(instance)
		if overheat_enabled:
			var heat_factor: float = overheat / max_overheat
			var damage_multiplier: float = 1.0 - pow(heat_factor, 2) * (1.0 - min_overheat_damage_debuff)
			projectile_component.damage = int(projectile_component.damage * damage_multiplier)
	elif instance.has_node("HitscanComponent"):
		var hitscan_component: HitscanComponent = instance.get_node("HitscanComponent")
		instance.global_position = parent.global_position
		
		hitscan_component.direction = angle
		hitscan_component.shooter = parent
		
		if scene:
			scene.add_child(instance)
	else:
		instance.queue_free()
	
	return instance

func _on_swap(_new_weapon: Weapon) -> void:
	if !overheat_enabled:
		return
	if _new_weapon == self:
		_overheat_visuals()
	else:
		weapon_inhand_texture.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if player_weapon_user:
			player_weapon_user.weapon_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_bullets_recover() -> void:
	if weapon_sprite and weapon_sprite.weapon_texture.texture == equipped_texture and reload_animation:
		weapon_sprite.reload()
	bullets += bullets_recover_count + extra_shots
	bullets = clamp(bullets, 0, bullets_max_count)
	if bullets_recover_sound:
		bullets_recover_sound.play()

func _on_cool() -> void:
	cool_timer.start()
	overheat -= cool_count
	overheat = clamp(overheat, 0, max_overheat)
	_overheat_visuals()

func _overheat_visuals() -> void:
	if !weapon_inhand_texture:
		return
	if overheat == 0 or weapon_inhand_texture.texture != equipped_texture:
		return
	
	var t: float = overheat / max_overheat
	var base: float = 5.0
	var overheat_factor: float = 1.0 + pow(t, base) * 2.0
	
	overheat_factor = clamp(overheat_factor, 1.0, 3.0)
	
	var red: float = overheat_factor
	var green: float = 1.0 / overheat_factor
	var blue: float = 1.0 / overheat_factor
	
	weapon_inhand_texture.modulate = Color(red, green, blue, 1.0)
	if player_weapon_user:
		player_weapon_user.weapon_icon.modulate = Color(red, green, blue, 1.0)
