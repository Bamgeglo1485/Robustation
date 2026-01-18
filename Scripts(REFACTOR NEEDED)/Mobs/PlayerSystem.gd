extends "res://Scripts/Mobs/MobSystem.gd"

@onready var camera: Camera2D = $Camera

@export var weapon_1: Node2D
@export var weapon_2: Node2D
@export var weapon_3: Node2D

@export var battle_tendency: float = 50
@export var max_battle_tendency: float = 100
@export var battle_tendecy_dependency: float = 1
@export var battle_tendency_debuff_multiplier: float = 0.5
@export var battle_tendency_buff_multiplier: float = 0.2
@export var battle_tendency_bonus = 0
@export var palette_section: int = 2
@export var section: int = 2
@onready var palette_change_timer: Timer = $PaletteChangeTimer

@onready var battle_tendency_frame: ColorRect = get_tree().get_root().get_node("Game").get_node("Effects").get_node("BattleTendency")
@onready var damage_frame: ColorRect = get_tree().get_root().get_node("Game").get_node("Effects").get_node("Damage")

func _local_process(_delta):
	_set_input()
	_camera()
	_set_direction()

#region Input
func _set_input():
	direction = Input.get_vector("movement_left","movement_right", "movement_up", "movement_down")
	
	var _movement_ability := Input.is_action_just_pressed("movement_ability")
	var _attack := Input.is_action_just_pressed("attack")
	
	if _attack:
		attack((get_global_mouse_position()-global_position))
	if _movement_ability:
		movement_ability()
	
	var _weapon_1 := Input.is_action_just_pressed("weapon_1")
	var _weapon_2 := Input.is_action_just_pressed("weapon_2")
	var _weapon_3 := Input.is_action_just_pressed("weapon_3")
	
	if _weapon_1 and weapon_1 != null and weapon_1 != selected_weapon:
		change_weapon(weapon_1)
	if _weapon_2 and weapon_2 != null and weapon_2 != selected_weapon:
		change_weapon(weapon_2)
	if _weapon_3 and weapon_3 != null and weapon_3 != selected_weapon:
		change_weapon(weapon_3)

func _subclasses_inputs():
	pass
#endregion

#region Movement and camera
func _camera():
	if camera == null:
		return
	
	var _mouse_position = get_global_mouse_position()
	
	var _mouse_offset = _mouse_position - global_position
	
	var _normalized_offset = Vector2(
		_mouse_offset.x / (15),
		_mouse_offset.y / (15)
	)
	
	camera.offset = _normalized_offset

func _set_direction():
	var _mouse_position = get_global_mouse_position()
	var _direction = (_mouse_position - global_position).normalized()
	
	var _angle = _direction.angle()
	var _angle_deg = rad_to_deg(_angle)
	
	look_at_direction(_angle_deg)
#endregion

#region Health
func health_effect():
	if material != null:
		material.set_shader_parameter("blood_intensity", (float(health) / float(max_health)))
		
	if damage_frame and damage_frame.material != null:
		var _tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.set_ease(Tween.EASE_IN_OUT)
		
		if health < float(max_health) / 2:
			var intensity = 1 - (float(health) / float(max_health))
			_tween.tween_property(damage_frame.material, "shader_parameter/intensity", intensity, 0.5)
		else:
			_tween.tween_property(damage_frame.material, "shader_parameter/intensity", 0, 0.5)
#endregion

#region Battle Tendency
func on_successful_attack(damage):
	change_battle_tendency(damage * 0.1)

func on_damage(damage, _damager):
	change_battle_tendency(damage * 0.2)

func on_enemy_gib():
	change_battle_tendency(1.5)

func on_miss():
	change_battle_tendency(-1.5)

func on_parry():
	change_battle_tendency(1.5)

func change_battle_tendency(value):
	if value > 0:
		value *= battle_tendency_buff_multiplier
	else:
		value *= battle_tendency_debuff_multiplier
	
	if battle_tendency_bonus == null:
		battle_tendency_bonus = 0
	
	battle_tendency_bonus = battle_tendency_bonus + value
	
	battle_tendency = float(health) / 2.0 + battle_tendency_bonus
	battle_tendency = clamp(battle_tendency, 0, max_battle_tendency)
	
	print("Battle tendency: ", battle_tendency)
	
	var segmentation = max_battle_tendency / 4.0
	
	if battle_tendency > segmentation * 3:
		section = 4  # ЭЙФОРИЯ (Euphoria)
	elif battle_tendency > segmentation * 2:
		section = 3  # НАСЛАЖДЕНИЕ (PLEASURE)
	elif battle_tendency - 5 > segmentation:
		section = 2  # БОРЬБА (STRUGGLE)
	else:
		section = 1  # ОТЧАЯНИЕ (DESPERATE)
	
	set_battle_tendency_modifiers()
	
	print("Section: ", section, " (", get_section_name(), ")")
	return section

func get_section_name() -> String:
	match section:
		1: return "DESPERATE"
		2: return "STRUGGLE" 
		3: return "PLEASURE"
		4: return "EUPHORIA"
		_: return "NUH UN WHAT THE FUCK IS A BUG"

func set_battle_tendency_modifiers():
	if section == 1:
		damage_modifier = 0.5
		health_damage_modifier = 1.5
	elif section == 2:
		damage_modifier = 1
		health_damage_modifier = 1
	elif section == 3:
		damage_modifier = 1.5
		health_damage_modifier = 0.7
	elif section == 4:
		damage_modifier = 2
		health_damage_modifier = 0.5
	palette_change_timer.start()

func change_palette():
	if palette_section == section:
		return
	palette_section = section
	
	if section == 1:
		battle_tendency_frame.material.set_shader_parameter("saturation", 0)
		battle_tendency_frame.material.set_shader_parameter("contrast", 0.5)
		battle_tendency_frame.material.set_shader_parameter("vignette_strength", 1)
		battle_tendency_frame.material.set_shader_parameter("red_factor", 1)
		if material != null:
			var _tween = create_tween()
			_tween.set_trans(Tween.TRANS_SINE)
			_tween.set_ease(Tween.EASE_IN_OUT)
			_tween.tween_property(material, "shader_parameter/aura_opacity", 0, 0.5)
	elif section == 2:
		battle_tendency_frame.material.set_shader_parameter("saturation", 1)
		battle_tendency_frame.material.set_shader_parameter("contrast", 1)
		battle_tendency_frame.material.set_shader_parameter("green_factor", 1)
		battle_tendency_frame.material.set_shader_parameter("vignette_strength", 0.1)
		battle_tendency_frame.material.set_shader_parameter("red_factor", 1)
		if material != null:
			var _tween = create_tween()
			_tween.set_trans(Tween.TRANS_SINE)
			_tween.set_ease(Tween.EASE_IN_OUT)
			_tween.tween_property(material, "shader_parameter/aura_opacity", 0, 0.5)
	elif section == 3:
		battle_tendency_frame.material.set_shader_parameter("saturation", 1.5)
		battle_tendency_frame.material.set_shader_parameter("contrast", 1.5)
		battle_tendency_frame.material.set_shader_parameter("green_factor", 0.9)
		battle_tendency_frame.material.set_shader_parameter("red_factor", 1.1)
		battle_tendency_frame.material.set_shader_parameter("vignette_strength", 0)
		if material != null:
			var _tween = create_tween()
			_tween.set_trans(Tween.TRANS_SINE)
			_tween.set_ease(Tween.EASE_IN_OUT)
			_tween.tween_property(material, "shader_parameter/aura_min_line_width", 0.1, 0.5)
			_tween.tween_property(material, "shader_parameter/aura_max_line_width", 1.4, 0.5)
			_tween.tween_property(material, "shader_parameter/aura_opacity", 0.2, 0.5)
	elif section == 4:
		battle_tendency_frame.material.set_shader_parameter("saturation", 2)
		battle_tendency_frame.material.set_shader_parameter("contrast", 2)
		battle_tendency_frame.material.set_shader_parameter("vignette_strength", 0)
		battle_tendency_frame.material.set_shader_parameter("red_factor", 1.2)
		battle_tendency_frame.material.set_shader_parameter("green_factor", 0.8)
		if material != null:
			var _tween = create_tween()
			_tween.set_trans(Tween.TRANS_SINE)
			_tween.set_ease(Tween.EASE_IN_OUT)
			_tween.tween_property(material, "shader_parameter/aura_min_line_width", 0.1, 0.5)
			_tween.tween_property(material, "shader_parameter/aura_max_line_width", 2.3, 0.5)
			_tween.tween_property(material, "shader_parameter/aura_opacity", 0.5, 0.5)

func _on_palette_change_timer_timeout() -> void:
	if palette_section == section:
		return
	
	change_palette()

#endregion
