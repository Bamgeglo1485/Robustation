class_name BattleTendencyComponent extends Component

@export var battle_tendency: float = 30
@export var max_battle_tendency: float = 100
@export var battle_tendecy_dependency: float = 1
@export var battle_tendency_debuff_multiplier: float = 0.5
@export var battle_tendency_buff_multiplier: float = 0.1
@export var battle_tendency_bonus = 0
@export var palette_section: int = 2
@export var section: int = 2

@export var battle_tendency_effect: ColorRect
@onready var material = parent.material
@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
@onready var weapon_user_component = parent.get_node_or_null("WeaponUserComponent")

func _ready() -> void:
	EventBusManager.health_changed.connect(_on_health_changed)
	EventBusManager.damaged.connect(_on_damaged)
	EventBusManager.gibbed.connect(_on_gibbed)
	EventBusManager.parry.connect(_on_parry)
	EventBusManager.projectile_miss.connect(_on_projectile_miss)
	EventBusManager.melee_miss.connect(_on_melee_miss)

@warning_ignore("unused_parameter")
func _on_health_changed(emitter, health, new_health):
	change_battle_tendency(0)

func _on_damaged(emitter, damage, damager):
	if damager == emitter and emitter == parent: # SELFHARM
		change_battle_tendency(damage * -0.2)
	elif damager == parent:
		change_battle_tendency(damage * 0.2) # DAMAGE
	else:
		change_battle_tendency(damage * -0.1) # PLAYER DAMAGED

func _on_gibbed(damager):
	if damager != parent:
		change_battle_tendency(1.5)

func _on_parry(emitter):
	if emitter == parent:
		change_battle_tendency(1.5)

func _on_projectile_miss(emitter, projectile):
	if emitter != parent:
		return
	change_battle_tendency(projectile.get_node("ProjectileComponent").damage * -0.05)

func _on_melee_miss(emitter, weapon):
	if emitter != parent:
		return
	change_battle_tendency(weapon.damage * -0.05)

func change_battle_tendency(value):
	if health_component == null:
		return section
	
	if value > 0:
		value *= battle_tendency_buff_multiplier
	else:
		value *= battle_tendency_debuff_multiplier
	
	if battle_tendency_bonus == null:
		battle_tendency_bonus = 0
	
	EventBusManager.tendency_changed.emit(parent)
	battle_tendency_bonus = battle_tendency_bonus + value
	
	battle_tendency = float(health_component.health) / 2.0 + battle_tendency_bonus
	battle_tendency = clamp(battle_tendency, 0, max_battle_tendency)
	
	#print("Battle tendency: ", battle_tendency)
	
	var segmentation = max_battle_tendency / 4.0
	var old_section = section
	
	if battle_tendency > segmentation * 3:
		section = 4  # ЭЙФОРИЯ (EUPHORIA)
	elif battle_tendency > segmentation * 2:
		section = 3  # НАСЛАЖДЕНИЕ (PLEASURE)
	elif battle_tendency - 5 > segmentation:
		section = 2  # БОРЬБА (STRUGGLE)
	else:
		section = 1  # ОТЧАЯНИЕ (DESPERATE)
	
	if section == old_section:
		return section
	
	EventBusManager.tendency_section_changed.emit(parent)
	set_battle_tendency_modifiers()
	
	#print("Section: ", section, " (", get_section_name(), ")")
	return section

func get_section_name() -> String:
	match section:
		1: return "DESPERATE"
		2: return "STRUGGLE" 
		3: return "PLEASURE"
		4: return "EUPHORIA"
		_: return "NUH UN WHAT THE FUCK IS A BUG"

func set_battle_tendency_modifiers():
	if health_component == null or weapon_user_component == null:
		return
	
	if section == 1:
		weapon_user_component.damage_modifier -= 0.5
		health_component.damage_modifier = 1.5
	elif section == 2:
		weapon_user_component.damage_modifier = 1
		health_component.damage_modifier = 1
	elif section == 3:
		weapon_user_component.damage_modifier = 1.5
		health_component.damage_modifier = 0.7
	elif section == 4:
		weapon_user_component.damage_modifier = 2
		health_component.damage_modifier = 0.5
	change_palette()

# PLS REWORK THIS SHIT
func change_palette():
	if palette_section == section:
		return
	
	palette_section = section
	
	if section == 1:
		battle_tendency_effect.material.set_shader_parameter("saturation", 0)
		battle_tendency_effect.material.set_shader_parameter("contrast", 0.5)
		battle_tendency_effect.material.set_shader_parameter("vignette_strength", 1)
		battle_tendency_effect.material.set_shader_parameter("red_factor", 1)
		if material != null:
			var _tween = create_tween()
			_tween.set_trans(Tween.TRANS_SINE)
			_tween.set_ease(Tween.EASE_IN_OUT)
			_tween.tween_property(material, "shader_parameter/aura_opacity", 0, 0.5)
	elif section == 2:
		battle_tendency_effect.material.set_shader_parameter("saturation", 1)
		battle_tendency_effect.material.set_shader_parameter("contrast", 1)
		battle_tendency_effect.material.set_shader_parameter("green_factor", 1)
		battle_tendency_effect.material.set_shader_parameter("vignette_strength", 0.1)
		battle_tendency_effect.material.set_shader_parameter("red_factor", 1)
		if material != null:
			var _tween = create_tween()
			_tween.set_trans(Tween.TRANS_SINE)
			_tween.set_ease(Tween.EASE_IN_OUT)
			_tween.tween_property(material, "shader_parameter/aura_opacity", 0, 0.5)
	elif section == 3:
		battle_tendency_effect.material.set_shader_parameter("saturation", 1.5)
		battle_tendency_effect.material.set_shader_parameter("contrast", 1.5)
		battle_tendency_effect.material.set_shader_parameter("green_factor", 0.9)
		battle_tendency_effect.material.set_shader_parameter("red_factor", 1.1)
		battle_tendency_effect.material.set_shader_parameter("vignette_strength", 0)
		if material != null:
			var _tween = create_tween()
			_tween.set_trans(Tween.TRANS_SINE)
			_tween.set_ease(Tween.EASE_IN_OUT)
			_tween.tween_property(material, "shader_parameter/aura_min_line_width", 0.1, 0.5)
			_tween.tween_property(material, "shader_parameter/aura_max_line_width", 1.4, 0.5)
			_tween.tween_property(material, "shader_parameter/aura_opacity", 0.2, 0.5)
	elif section == 4:
		battle_tendency_effect.material.set_shader_parameter("saturation", 2)
		battle_tendency_effect.material.set_shader_parameter("contrast", 2)
		battle_tendency_effect.material.set_shader_parameter("vignette_strength", 0)
		battle_tendency_effect.material.set_shader_parameter("red_factor", 1.2)
		battle_tendency_effect.material.set_shader_parameter("green_factor", 0.8)
		if material != null:
			var _tween = create_tween()
			_tween.set_trans(Tween.TRANS_SINE)
			_tween.set_ease(Tween.EASE_IN_OUT)
			_tween.tween_property(material, "shader_parameter/aura_min_line_width", 0.1, 0.5)
			_tween.tween_property(material, "shader_parameter/aura_max_line_width", 2.3, 0.5)
			_tween.tween_property(material, "shader_parameter/aura_opacity", 0.5, 0.5)
