class_name WeaponIconComponent extends Component

@export var weapon: Weapon
var progress_tween: Tween

func _ready() -> void:
	EventBusManager.weapon_cooldown.connect(_try_update_bar)
	EventBusManager.swinging_start.connect(_try_update_bar)
	EventBusManager.update_weapon_icon.connect(_try_update_bar)
	EventBusManager.weapon_cooldown_reset.connect(_on_cooldown_reset)

# shit
func _progress_bar() -> void:
	if !weapon or parent is not TextureRect:
		return
	if progress_tween:
		progress_tween.kill()
	if !weapon.can_attack:
		parent.material.set_shader_parameter("progress", 0.0)
	if weapon is MeleeWeapon:
		if weapon is ChargingMeleeWeaponComponent:
			if weapon.charging:
				var progress_value = weapon.charge / weapon.max_charge_time
				var charge_delay = weapon.max_charge_time - weapon.charge
				parent.material.set_shader_parameter("progress", progress_value)
				_start_progress_tween(1.0, charge_delay)
				return
		if weapon.swinging:
			parent.material.set_shader_parameter("progress", 0.0)
			_start_progress_tween(1.0, weapon.swinging_timer.time_left)
			return
		if !weapon.cooldown:
			parent.material.set_shader_parameter("progress", 0.0)
		else:
			var modifier: float = 0.0
			if weapon.cooldown_timer.time_left == weapon.cooldown_timer.wait_time and weapon.swing_delay == 0:
				_start_progress_tween(1.0, 0.15)
				modifier = 0.15
				await progress_tween.finished
			if !is_instance_valid(weapon):
				return
			var progress_value = weapon.cooldown_timer.time_left / weapon.cooldown_timer.wait_time + modifier
			parent.material.set_shader_parameter("progress", progress_value)
			_start_progress_tween(0.0, weapon.cooldown_timer.time_left)
	elif weapon is RangeWeapon:
		if weapon.swinging:
			parent.material.set_shader_parameter("progress", 0.0)
			_start_progress_tween(1.0, weapon.swinging_timer.time_left)
			return
		if weapon.bullets != 0:
			if weapon.show_cooldown_on_icon:
				if !weapon.cooldown:
					parent.material.set_shader_parameter("progress", 0.0)
					return
				else:
					var modifier: float = 0.0
					if weapon.cooldown_timer.time_left == weapon.cooldown_timer.wait_time and weapon.swing_delay == 0:
						_start_progress_tween(1.0, 0.15)
						modifier = 0.15
						await progress_tween.finished
					if !is_instance_valid(weapon):
						return
					@warning_ignore("confusable_local_declaration")
					var progress_value = weapon.cooldown_timer.time_left / weapon.cooldown_timer.wait_time + modifier
					parent.material.set_shader_parameter("progress", progress_value)
					_start_progress_tween(0.0, weapon.cooldown_timer.time_left)
					return
			var progress_value = 1.0 - (float(weapon.bullets) / weapon.bullets_max_count)
			if !weapon.cooldown:
				parent.material.set_shader_parameter("progress", progress_value)
			else:
				var cooldown_time = weapon.cooldown_timer.time_left 
				_start_progress_tween(progress_value, cooldown_time)
		else:
			if weapon.bullets_recover_timer and weapon.bullets_recover_timer.time_left == 0:
				parent.material.set_shader_parameter("progress", 1.0)
				return
			var modifier: float = 0.0
			if weapon.cooldown and weapon.swing_delay == 0:
				var cooldown_time = weapon.cooldown_timer.time_left
				_start_progress_tween(1.0, cooldown_time)
				modifier = cooldown_time
				await progress_tween.finished
			if !is_instance_valid(weapon) or !weapon.bullets_recover_timer:
				return
			var progress_value = weapon.bullets_recover_timer.time_left / weapon.bullets_recover_timer.wait_time + modifier
			parent.material.set_shader_parameter("progress", progress_value)
			_start_progress_tween(0.0, weapon.bullets_recover_timer.time_left)

func _start_progress_tween(value, delay) -> void:
		progress_tween = create_tween()
		progress_tween.set_ignore_time_scale()
		progress_tween.tween_property(parent.material, "shader_parameter/progress", value, delay)

func _on_cooldown_reset(_emitter, suka_weapon) -> void:
	if suka_weapon != weapon:
		return
	
	if progress_tween:
		progress_tween.kill()
	
	_start_progress_tween(0.0, 0.1)

func _try_update_bar(_emitter, suka_weapon) -> void:
	if suka_weapon != weapon:
		return
	
	_progress_bar()
