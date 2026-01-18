extends CharacterBody2D

#region Childrens
@onready var scene: Node2D = get_tree().get_root().get_node("Game")
@onready var sprite: Sprite2D = $Texture
@onready var area2d: Area2D = $Area2D
#endregion

#region Movement, Animation and camera Variables
@export var max_speed: int = 300
@export var acceleration: int = 100
@export var friction: int = 700

var movement_animation_tween: Tween = null

@export var fall_sound: AudioStreamPlayer2D

@export var footstep_sound_length: int = 80
@onready var footstep_sounds: AudioStreamPlayer2D = $FootstepSound
var last_footstep_position: Vector2 = global_position

@onready var fly_timer = $FlyTimer
@onready var fly_damage_timer = $FlyDamageTimer

@export var animation_time_modifier: float = 1
var current_animation: Dictionary = {"tween": Tween, "priority": 0}
signal direction_changed

var direction = Vector2.ZERO

var fly_speed: float = 0.0
var fly_decay: float = 400.0
var fly_direction: Vector2 = Vector2.ZERO
var flying: bool = false
@export var can_fall: bool = false
#endregion

#region Health and Faction Variables
@export var max_health: int = 100
@export var INVINCIBLE: bool = false
@export var health: int = max_health: set = set_health, get = get_health
@export var health_damage_modifier: float = 1

@export var can_enemy_heal: bool = true
@export var heal_for_damage_modifier: float = 0
@export var heal_for_damage_distance: int = 64

@export var faction: String

@export var blood_effect_scene: PackedScene
@export var blood_splurt_effect_scene: PackedScene
@export var gib_effect_scene: PackedScene

@onready var stun_effect: PackedScene = preload("res://Scenes/Effects/Particles/Stun.tscn")
@export var stunned: bool = false
var stun_time: float = 0
var gibbed: bool = false
#endregion

#region Weapon
@export var selected_weapon: Node2D
@onready var attack_cooldown_timer: Timer = $AttackCooldown

@export var parry_symbols: PackedScene
@export var parry_effect: PackedScene
@onready var parry_sound = $ParrySound
var attack_cooldown: bool = false

var damage_modifier: float = 1.0

@onready var swinging_timer: Timer = $SwingingTimer
var swinging: bool = false
#endregion

func _physics_process(_delta: float):
	_local_process(_delta)
	
	_stun(_delta)
	_move(direction, _delta)
	_fly(_delta)

# Локальные процессы для дочерних систем
func _local_process(_delta):
	pass

#region Movement
func _move(_direction, _delta):
	
	if _direction == Vector2.ZERO and flying == false:
		# Если тело не ускоряется
		var _friction_multiplier = friction * _delta
		if velocity.length() > _friction_multiplier: # Если скорость выше силы трения
			velocity -= velocity.normalized() * _friction_multiplier # Постепенно снижаем скорость трением
		else:
			velocity = Vector2.ZERO # Если сила трения сильнее, то останавливаем
	else:
		if stunned == false:
			velocity += _direction * acceleration # Ускоряемся
			if has_node("NavigationAgent"):
				get_node("NavigationAgent").set_velocity(_direction * acceleration)
		velocity = velocity.limit_length(max_speed)
		
		if fly_speed != 0:
			velocity += fly_direction * fly_speed / 10 # добавляем ускорение полёта
			print('alo')
			if velocity.length() <= 0.1:
				velocity = Vector2.ZERO
	
	move_and_slide()
	
	if flying == false:
		_footstep_sound()
		_movement_effects()

func _movement_effects():
	var _speed = velocity.length() / 100
	
	if _speed > 0:
		if movement_animation_tween == null and current_animation.priority <= 1:
			_start_movement_animation()
	elif current_animation.priority <= 1:
		_stop_movement_animation()

func _start_movement_animation():
	if current_animation.priority > 1:
		return
	
	movement_animation_tween = create_tween()
	movement_animation_tween.set_loops()
	movement_animation_tween.set_trans(Tween.TRANS_SINE)
	movement_animation_tween.set_ease(Tween.EASE_IN_OUT)
	
	movement_animation_tween.tween_property(self, "global_rotation", -0.08, 0.2 * animation_time_modifier)
	movement_animation_tween.tween_property(self, "global_rotation", 0.08, 0.2 * animation_time_modifier)
	
	set_animation(movement_animation_tween, 1)

func _stop_movement_animation():
	if movement_animation_tween != null:
		movement_animation_tween.kill()
		movement_animation_tween = null
	
	if current_animation.priority <= 1:
		clear_animation()

func _footstep_sound():
	if (last_footstep_position - global_position).length() > footstep_sound_length:
		footstep_sounds.play()
		last_footstep_position = global_position

func _fly(_delta):
	if fly_speed <= 0 or fly_direction == Vector2.ZERO:
		return
	
	fly_speed = clamp(fly_speed - fly_decay, 0, 1000000)
	
	if fly_speed == 0:
		fly_timer.start()

func fly_off(_direction, speed):
	fly_speed += speed * 1000
	fly_direction = _direction.normalized()
	flying = true
	
	var _tween = create_tween()
	
	_tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)

func _on_fly_timer_timeout():
	if flying == false:
		return
	
	flying = false
	
	var _tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1, 1), 0.2)
	
	fly_damage_timer.start()

func fall(time):
	fall_sound.play()
	set_stun(time-0.5, false)
	direction = Vector2.ZERO
	velocity = Vector2.ZERO
	
	var _tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.stop()
	
	_tween.tween_property(self, "global_rotation", -1.5, 0.3)
	_tween.tween_property(self, "global_rotation", -1.5, stun_time - 0.5)
	_tween.tween_property(self, "global_rotation", 0, 0.2)
	
	set_animation(_tween, 4)

#endregion

#region Animations
func look_at_direction(_angle_deg, _set_sprite = true):
	_angle_deg = fmod(_angle_deg + 360, 360)
	
	var _weapon_sprite = null
	
	if selected_weapon != null:
		_weapon_sprite = selected_weapon.get_node("Texture")
	
	if _angle_deg >= 315 or _angle_deg < 45:
		if _set_sprite == true:
			var rect = Rect2(0, 32, 32, 32)
			sprite.region_rect = rect
			direction_changed.emit(rect)
		return 1
	elif _angle_deg >= 45 and _angle_deg < 135:
		if _set_sprite == true:
			var rect = Rect2(0, 0, 32, 32)
			sprite.region_rect = rect
			direction_changed.emit(rect)
		return 2
	elif _angle_deg >= 135 and _angle_deg < 225:
		if _set_sprite == true:
			var rect = Rect2(32, 32, 32, 32)
			sprite.region_rect = rect
			direction_changed.emit(rect)
		return 3
	elif _angle_deg >= 225 and _angle_deg < 315:
		if _set_sprite == true:
			var rect = Rect2(32, 0, 32, 32)
			sprite.region_rect = rect
			direction_changed.emit(rect)
		return 4

func get_rotation_from_angle(_angle_deg):
	var _side = look_at_direction(_angle_deg, false)
	
	if _side == 2 or _side == 4:
		return {"type": "skew", "value": 0.3}
	elif _side == 1:
		return {"type": "global_rotation", "value": 0.5}
	elif _side == 3:
		return {"type": "global_rotation", "value": -0.5}

func set_animation(tween: Tween, priority: int):
	if priority <= current_animation.priority:
		tween.kill()
		return
	
	clear_animation()
	
	tween.play()
	current_animation = {"tween": tween, "priority": priority}
	
	tween.connect("finished", _on_tween_finished)

func clear_animation():
	if current_animation.tween != null and current_animation.tween is Tween:
		current_animation.tween.kill()
		current_animation.tween = null
	current_animation.priority = 0
	
	_clear_tween()

func _clear_tween():
	var _tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	
	_tween.tween_property(self, "global_rotation", 0, 0.1)
	_tween.tween_property(self, "skew", 0, 0.1)

func _on_tween_finished():
	clear_animation()

func lean_to_direction(_direction, priority, rotation_multiplier = 1):
	var _angle = _direction.angle()
	var _angle_deg = rad_to_deg(_angle)
	
	var _rotation = get_rotation_from_angle(_angle_deg)
	
	var _tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.stop()
		
	_tween.tween_property(self, _rotation.type, _rotation.value * rotation_multiplier, 0.2 * animation_time_modifier)
	_tween.tween_property(self, _rotation.type, 0 , 0.2 * animation_time_modifier)
		
	set_animation(_tween, priority)

func make_effect(effect, _position = null):
	if effect != null and scene != null:
		var _effect = effect.instantiate()
		scene.add_child(_effect)
		if _position == null:
			_effect.global_position = global_position
		else:
			_effect.global_position = _position
		_effect.emitting = true

#endregion

#region Health and Faction
# Устанавливает ХП
func set_health(_new_health: int):
	if _new_health < health:
		if _new_health <= 0:
			_death()
	health = clamp(_new_health, 0, max_health)
	
	health_effect()

func health_effect():
	if material != null:
		material.set_shader_parameter("blood_intensity", (float(health) / float(max_health)))

func get_health():
	return health

# Наносит урон и создаёт эффекты
func take_damage(_damage: int, _damager):
	if INVINCIBLE == true:
		return
	
	var modified_damage = _damage * health_damage_modifier
	
	health -= int(modified_damage)
	
	if _damage > 0:
		damage_effects(_damager)
		on_damage(modified_damage, _damager)
		
		if can_enemy_heal == true and _damager is CharacterBody2D and _damager.heal_for_damage_modifier != 0 and (_damager.global_position - global_position).length() <= heal_for_damage_distance:
			_damager.set_health(_damager.health + (_damage * _damager.heal_for_damage_modifier))
	
	if health <= 0:
		_damager.on_enemy_gib()

func damage_effects(_damager):
	if material != null:
		var _tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.set_ease(Tween.EASE_IN_OUT)
		
		_tween.tween_property(material, "shader_parameter/flash_color", Color(0.7, 0.0, 0.3, 0.7), 0.1)
		_tween.tween_property(material, "shader_parameter/flash_color", Color(0.7, 0.0, 0.3, 0.0), 0.2)
	
	if _damager == null:
		return
	
	var _direction = (global_position - _damager.global_position).normalized()
	lean_to_direction(_direction, 4)
	
	make_effect(blood_splurt_effect_scene)
	
	if blood_effect_scene != null and scene != null:
		var blood_effect = blood_effect_scene.instantiate()
		scene.add_child(blood_effect)
		blood_effect.global_position = global_position
		blood_effect.rotation = _direction.angle()

func _death():
	if gibbed == true:
		return
	
	gibbed = true
	
	if gib_effect_scene != null:
		var gib_effect = gib_effect_scene.instantiate()
		scene.add_child(gib_effect)
		gib_effect.global_position = global_position
	
	queue_free()

func get_faction():
	return faction

func set_stun(time, display: bool = true):
	stun_time += time
	stunned = true
	
	if display == true:
		make_effect(stun_effect)

func _stun(_delta):
	if stun_time <= 0:
		stunned = false
		stun_time = 0
	stun_time -= _delta
#endregion

#region Weapons and Abilities
func movement_ability():
	pass
	
func attack(_direction: Vector2, _target = null):
	if selected_weapon == null or attack_cooldown == true or stunned == true and _direction is not Vector2:
		return
	
	attack_cooldown = true
	attack_cooldown_timer.start()
	
	if selected_weapon.weapon_type == "Melee" and _target == null:
		try_melee_attack(selected_weapon, _direction, selected_weapon.rotation_multiplier)
	elif _target != null:
		_melee_attack_target(_target, selected_weapon, selected_weapon.rotation_multiplier, _direction)
	elif selected_weapon.weapon_type == "Range":
		projectile_shoot(selected_weapon, _direction)
	elif selected_weapon.weapon_type == "Gun":
		gun_shoot(selected_weapon, _direction)

func change_weapon(_new_weapon):
	if selected_weapon == null:
		selected_weapon = _new_weapon
	else:
		if selected_weapon.has_node("Texture"):
			selected_weapon.get_node("Texture").visible = false
		selected_weapon = _new_weapon
	if _new_weapon.has_node("Texture"):
		_new_weapon.get_node("Texture").visible = true
	
	if swinging_timer != null:
		swinging_timer.wait_time = _new_weapon.swing_time

func parry_melee(_target, _attacker, _direction):
	if _target is not CharacterBody2D or _attacker is not CharacterBody2D:
		return
	
	parry_sound.play()
	parry_effects(_attacker.global_position + _direction.normalized() * 2)
	
	_target.cancel_swinging()
	_target.selected_weapon.can_attack = false
	_target.selected_weapon.cooldown_timer.start()
	_target.set_stun(0.5, false)
	
	on_parry()

func parry_range(_attacker, _direction, _projectile):
	pass

func parry_effects(_position):
	make_effect(parry_symbols)
	make_effect(parry_effect, _position)

func _on_attack_cooldown_timeout() -> void:
	attack_cooldown = false
#endregion

#region Melee Weapon
func try_melee_attack(_weapon, _direction, rotation_multiplier = 1):
	if _weapon.can_attack == false:
		return
	
	var space_state = get_world_2d().direct_space_state
	var _targets: Dictionary
	var attacked_enemies = []
	
	for i in range(5):
		var angle_offset = deg_to_rad(i * 20 - 60)
		var ray_direction = _direction.rotated(angle_offset)
		var ray_start = global_position - ray_direction * 0.2
		var ray_end = global_position + ray_direction * _weapon.melee_range
		
		var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
		query.collision_mask = 2 | 3 | 4
		query.exclude = [self]
		
		var result = space_state.intersect_ray(query)
		
		if result.is_empty():
			continue
		
		var enemy = result.collider
		
		if enemy in attacked_enemies:
			continue
		
		if enemy.has_method("is_projectile"):
			parry_range(self, _direction, enemy)
			print("ДОБАВЬ ПАРИРОВАНИЕ ПРОДЖЕКТАЙЛОВ ГЕГЛО ИЗ БУДУЩЕГО")
			continue
		
		if enemy.has_method("get_faction") and enemy.get_faction() == _weapon.attacker_faction:
			continue
		
		if (enemy.global_position - global_position).length() > _weapon.melee_range:
			continue
		
		var _attacked = _melee_attack_target(enemy, _weapon, rotation_multiplier, _direction)
		
		if _attacked == true and enemy != null:
			_targets[i] = enemy
			attacked_enemies.append(enemy)
	
	if _targets.is_empty():
		_melee_attack_target(null, _weapon, rotation_multiplier, _direction, )
	
	_weapon.can_attack = false
	_weapon.cooldown_timer.start()
	
	return _targets

# Гарантированная атака цели
func _melee_attack_target(_target, _weapon, rotation_multiplier = 1, _direction = null, negative = false, weapon_logics = true):
	if _weapon.can_attack == false or stunned == true:
		return
	
	var lean_direction = _direction
	
	if _direction != null and _direction is Vector2:
		if negative == true:
			lean_direction = -_direction
		lean_to_direction(lean_direction, 3, rotation_multiplier)
		
		if _weapon.melee_slash_effect != null:
			var _slash_effect = _weapon.melee_slash_effect.instantiate()
			_slash_effect.global_rotation = _direction.angle() + 90
			self.add_child(_slash_effect)
			if _slash_effect.has_node("AnimationPlayer"):
				_slash_effect.get_node("AnimationPlayer").play("Slash")
	
	if weapon_logics == true:
		_weapon.can_attack = false
		_weapon.cooldown_timer.start()
	
	if _target != null and _target.has_method("get_swinging") and _target.get_swinging() == true and _weapon.can_parry == true and _target.selected_weapon.can_parriable == true:
		parry_melee(_target, self, _direction)
	
	var _attack_access = false
	if _target != null and _target.has_method("on_enemy_melee_attack"):
		_attack_access = _target.on_enemy_melee_attack(self)
	
	if _weapon.melee_attack_sound != null and _attack_access == true:
		_weapon.melee_attack_sound.play()
	elif _weapon.melee_miss_sound != null and _attack_access == false:
		_weapon.melee_miss_sound.play()
	
	if _target == null:
		return false
	
	var damage = _weapon.melee_damage * damage_modifier
	
	if _weapon.fly_off_speed != 0 and _target.has_method("fly_off"):
		_target.fly_off(_direction, _weapon.fly_off_speed)
		if _weapon.fall == true:
			_target.fall(_weapon.stun_time)
	
	if _target.has_method("take_damage"):
		_target.take_damage(damage, self)
	
	if _target.has_method("set_stun") and _weapon.stun_time != 0 and _weapon.fall == false:
		_target.set_stun(_weapon.stun_time)
	
	if _weapon.melee_effect != null:
		var _effect = _weapon.melee_effect.instantiate()
		_target.add_child(_effect)
	
	on_successful_attack(damage)
	return true

func _melee_effects(_direction):
	pass

# Функция для дочерних скриптов, активируется при попытке атаковать сущность. При False атака отменяется
func on_enemy_melee_attack(_attacker):
	return true
#endregion

#region Range Weapon
func projectile_shoot(_weapon, _direction, gun = false):
	if _weapon.can_attack == false or _weapon.projectile == null:
		return
	
	_direction = _direction.normalized()
	
	if gun == false:
		_weapon.can_attack = false
		_weapon.cooldown_timer.start()
		
		lean_to_direction(_direction, 3)
	
	var weapon_spread: int = _weapon.spread_angle
	var spread: float = 0
	if weapon_spread != 0:
		spread = deg_to_rad(randf_range(-weapon_spread, weapon_spread))
		_direction = _direction.rotated(spread)
	
	var angle = _direction.normalized().angle()
	
	var projectile = _weapon.projectile.instantiate()
	projectile.direction = angle
	projectile.spawn_position = global_position
	projectile.spawn_rotation = angle
	projectile.zndex = z_index - 1
	projectile.stun_time = _weapon.stun_time
	if scene != null:
		scene.add_child.call_deferred(projectile)
	
	if self is CharacterBody2D:
		projectile.shooter = self
		projectile.shooter_faction = faction
#endregion

#region Gun Weapon
func gun_shoot(_weapon, _direction):
	if _weapon.can_attack == false or _weapon.projectile == null:
		return
	
	if _weapon.bullets == 0:
		return
	
	if _weapon.shots > 1:
		var total_spread = deg_to_rad(_weapon.shots_angle)
		var angle_step = total_spread / (_weapon.shots - 1) if _weapon.shots > 1 else 0
		var start_angle = -total_spread / 2
		
		var possible_shots: int = 0
		if _weapon.bullets < _weapon.shots:
			possible_shots = _weapon.bullets
		else:
			possible_shots = _weapon.shots
		
		_weapon.bullets -= possible_shots
		
		for i in range(possible_shots):
			var shot_direction = _direction.rotated(start_angle + angle_step * i)
			projectile_shoot(_weapon, shot_direction, true)
			
	else:
		projectile_shoot(_weapon, _direction, true)
		_weapon.bullets -= 1
	
	_weapon.can_attack = false
	_weapon.cooldown_timer.start()
	
	if _weapon.shoot_sound != null:
		_weapon.shoot_sound.play()
	
	if _weapon.case_scene != null:
		var case = _weapon.case_scene.instantiate()
		case.global_position = global_position
		scene.add_child(case)
	
	if _weapon.gun_fire_effect != null:
		var fire = _weapon.gun_fire_effect.instantiate()
		fire.global_position = global_position
		fire.global_rotation = _direction.angle()
		fire.emitting = true
		scene.add_child(fire)
	
	lean_to_direction(_direction, 3, _weapon.rotation_multiplier)
	
	_weapon.bullets_recovery_timer.start()
#endregion

func _on_area_2d_body_entered(body: Node2D) -> void:
	if flying == false and body is CharacterBody2D and body.flying == true or not body.fly_damage_timer.is_stopped():
		if can_fall == false:
			return
		
		var damage = body.direction.length() * 20
		
		fall(2)
		take_damage(damage, body)
		
		var player = scene.get_node("Player")
		if player != null:
			player.on_successful_attack(damage)

@warning_ignore("unused_parameter")
func on_successful_attack(damage):
	pass

@warning_ignore("unused_parameter")
func on_damage(damage, _damager):
	pass

@warning_ignore("unused_parameter")
func on_self_attack(damage):
	pass

func on_enemy_gib():
	pass

func on_miss():
	pass

func on_parry():
	pass
