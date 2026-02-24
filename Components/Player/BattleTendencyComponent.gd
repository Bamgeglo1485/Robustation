class_name BattleTendencyComponent extends Component

@export var battle_tendency: float = 30.0
@export var battle_tendency_on_max_health: float = 50.0
@export var max_battle_tendency: float = 100.0
@export var battle_tendecy_dependency: float = 1.0
@export var battle_tendency_debuff_multiplier: float = 0.15
@export var battle_tendency_buff_multiplier: float = 1.0
@export var battle_tendency_bonus: int = 0
@export var palette_section: int = 2
@export var section: int = 2

@export var euphoria_effect: GPUParticles2D

@export var battle_tendency_effect: ColorRect
@onready var material = parent.get("material")
@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
@onready var weapon_user_component: Node = parent.get_node_or_null("WeaponUserComponent")

var last_section: int = 69

func _ready() -> void:
	EventBusManager.health_changed.connect(_on_health_changed)
	EventBusManager.damaged.connect(_on_damaged)
	EventBusManager.gibbed.connect(_on_gibbed)
	EventBusManager.parry.connect(_on_parry)
	EventBusManager.projectile_miss.connect(_on_projectile_miss)
	EventBusManager.melee_miss.connect(_on_melee_miss)
	
func _on_health_changed(_emitter, _health, _new_health) -> void:
	change_battle_tendency(0)

func _on_damaged(emitter, damage, damager) -> void:
	if damager == emitter and emitter == parent: # SELFHARM
		change_battle_tendency(damage * -0.2)
	elif damager == parent:
		change_battle_tendency(damage * 0.) # DAMAGE
	else:
		change_battle_tendency(damage * -0.1) # PLAYER DAMAGED

func _on_gibbed(damager) -> void:
	if damager != parent:
		change_battle_tendency(1.5)
		
func _on_parry(emitter, _type):
	if emitter == parent:
		change_battle_tendency(1.5)

func _on_projectile_miss(emitter, projectile) -> void:
	if emitter != parent:
		return
	change_battle_tendency(projectile.get_node("ProjectileComponent").damage * -0.05)

func _on_melee_miss(emitter, weapon) -> void:
	if emitter != parent:
		return
	change_battle_tendency(weapon.damage * -0.05)

func change_battle_tendency(value) -> int:
	if !health_component:
		return section
	
	if value > 0:
		value *= battle_tendency_buff_multiplier
	else:
		value *= battle_tendency_debuff_multiplier
	
	if !battle_tendency_bonus:
		battle_tendency_bonus = 0
	
	EventBusManager.tendency_changed.emit(parent)
	battle_tendency_bonus = battle_tendency_bonus + value
	
	battle_tendency = float(health_component.health) / float(health_component.max_health) * battle_tendency_on_max_health + battle_tendency_bonus
	battle_tendency = clamp(battle_tendency, 0, max_battle_tendency)
	
	#print("Battle tendency: ", battle_tendency)
	
	var segmentation: float = max_battle_tendency * 0.25
	var old_section: int = section
	
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
	
	_on_section_changed()
	# print("Section: ", section, " (", get_section_name(), ")")
	return section

func _on_section_changed():
	await get_tree().create_timer(3).timeout
	
	if last_section == section:
		return
	
	last_section = section
	set_battle_tendency_modifiers()
	change_palette()
	EventBusManager.tendency_section_changed.emit(parent)

func get_section_name() -> String:
	match section:
		1: return "DESPERATE"
		2: return "STRUGGLE" 
		3: return "PLEASURE"
		4: return "EUPHORIA"
		_: return "NUH UN WHAT THE FUCK IS A BUG"

func set_battle_tendency_modifiers() -> void:
	if !health_component or !weapon_user_component:
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
func change_palette() -> void:
	if section < 1 or section > 4:
		return
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	match section:
		1:
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/saturation", 0.3, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/contrast", 0.5, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/vignette_strength", 0.4, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/red_factor", 1.0, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/green_factor", 1.0, 0.5)
			
			if euphoria_effect:
				euphoria_effect.visible = false
			
			if material:
				tween.tween_property(material, "shader_parameter/aura_opacity", 0.0, 0.5)
		
		2:
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/saturation", 1.0, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/contrast", 1.0, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/green_factor", 1.0, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/vignette_strength", 0.1, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/red_factor", 1.0, 0.5)
			
			if euphoria_effect:
				euphoria_effect.visible = false
			
			if material:
				tween.tween_property(material, "shader_parameter/aura_opacity", 0.0, 0.5)
		
		3:
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/saturation", 1.5, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/contrast", 1.5, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/green_factor", 0.9, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/red_factor", 1.1, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/vignette_strength", 0.0, 0.5)
			
			if euphoria_effect:
				euphoria_effect.visible = false
				
			if material:
				tween.tween_property(material, "shader_parameter/aura_min_line_width", 0.1, 0.5)
				tween.tween_property(material, "shader_parameter/aura_max_line_width", 1.4, 0.5)
				tween.tween_property(material, "shader_parameter/aura_opacity", 0.2, 0.5)
		
		4:
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/saturation", 2.0, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/contrast", 2.0, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/vignette_strength", 0.0, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/red_factor", 1.2, 0.5)
			tween.tween_property(battle_tendency_effect.material, "shader_parameter/green_factor", 0.8, 0.5)
			
			if euphoria_effect:
				euphoria_effect.visible = true
			
			if material:
				tween.tween_property(material, "shader_parameter/aura_min_line_width", 0.1, 0.5)
				tween.tween_property(material, "shader_parameter/aura_max_line_width", 2.3, 0.5)
				tween.tween_property(material, "shader_parameter/aura_opacity", 0.5, 0.5)
