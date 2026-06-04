class_name BattleTendencyComponent extends Component

enum battle_tendency_stages {
	DESPERATE,
	STRUGGLE,
	PLEASURE,
	EUPHORIA
}
@export var stage: battle_tendency_stages = battle_tendency_stages.STRUGGLE

@export var battle_tendency: float = 50.0 : set = set_battle_tendency

@export var max_stage_battle_tendency: float = 100.0
@export var battle_tendency_on_stage_decrease: float = 80.0
@export var battle_tendency_on_stage_increase: float = 15.0

@export var euphoria_effect: GPUParticles2D

@export var battle_tendency_effect: ColorRect
@onready var material = parent.material
@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
@onready var weapon_user_component: Node = parent.get_node_or_null("WeaponUserComponent")

var effects_tween: Tween

@export_category("Modifiers")

@export var battle_tendency_by_damage_multipliers: Dictionary
@export var battle_tendency_by_damage_multiplier: float = 0.05
@export var batte_tendency_decrease_multipliers: Dictionary
@export var batte_tendency_decrease_multiplier: float = 0.9

# BASE
func set_battle_tendency(value: float) -> void:
	battle_tendency = clamp(value, 0, max_stage_battle_tendency)
	
	# print(get_stage_name(), " ", battle_tendency)
	
	if stage == battle_tendency_stages.EUPHORIA:
		health_component.hard_damage = 0
		
	if battle_tendency == 0 and stage != battle_tendency_stages.DESPERATE:
		stage = (stage - 1) as battle_tendency_stages
		battle_tendency = battle_tendency_on_stage_decrease
		EventBusManager.tendency_stage_changed.emit(parent)
		change_palette()
	elif battle_tendency == max_stage_battle_tendency and stage != battle_tendency_stages.EUPHORIA:
		stage = (stage + 1) as battle_tendency_stages
		battle_tendency = battle_tendency_on_stage_increase
		EventBusManager.tendency_stage_changed.emit(parent)
		change_palette()

func change_palette() -> void:
	effects_tween = create_tween()
	effects_tween.set_parallel(true)
	
	match stage:
		battle_tendency_stages.DESPERATE:
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/saturation", 0.7, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/contrast", 0.7, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/vignette_strength", 0.1, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/red_factor", 1.0, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/green_factor", 1.0, 0.5)
			
			if euphoria_effect:
				euphoria_effect.visible = false
			
			if material:
				effects_tween.tween_property(material, "shader_parameter/aura_opacity", 0.0, 0.5)
		
		battle_tendency_stages.STRUGGLE:
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/saturation", 1.0, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/contrast", 1.0, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/green_factor", 1.0, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/vignette_strength", 0.05, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/red_factor", 1.0, 0.5)
			
			if euphoria_effect:
				euphoria_effect.visible = false
			
			if material:
				effects_tween.tween_property(material, "shader_parameter/aura_opacity", 0.0, 0.5)
		
		battle_tendency_stages.PLEASURE:
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/saturation", 1.5, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/contrast", 1.5, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/green_factor", 0.9, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/red_factor", 1.1, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/vignette_strength", 0.0, 0.5)
			
			if euphoria_effect:
				euphoria_effect.visible = false
				
			if material:
				effects_tween.tween_property(material, "shader_parameter/aura_min_line_width", 0.1, 0.5)
				effects_tween.tween_property(material, "shader_parameter/aura_max_line_width", 1.4, 0.5)
				effects_tween.tween_property(material, "shader_parameter/aura_opacity", 0.2, 0.5)
		
		battle_tendency_stages.EUPHORIA:
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/saturation", 2.0, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/contrast", 2.0, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/vignette_strength", 0.0, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/red_factor", 1.2, 0.5)
			effects_tween.tween_property(battle_tendency_effect.material, "shader_parameter/green_factor", 0.8, 0.5)
			
			if euphoria_effect:
				euphoria_effect.visible = true
			
			if material:
				effects_tween.tween_property(material, "shader_parameter/aura_min_line_width", 0.1, 0.5)
				effects_tween.tween_property(material, "shader_parameter/aura_max_line_width", 2.3, 0.5)
				effects_tween.tween_property(material, "shader_parameter/aura_opacity", 0.5, 0.5)

func get_stage_name() -> String:
	var stage_name: String = "Orgasm"
	match stage:
		battle_tendency_stages.DESPERATE:
			stage_name = "Desperate"
		battle_tendency_stages.STRUGGLE:
			stage_name = "Struggle"
		battle_tendency_stages.PLEASURE:
			stage_name = "Pleasure"
		battle_tendency_stages.EUPHORIA:
			stage_name = "Euphoria"
	return stage_name

# TENDENCY CHANGING

func _ready() -> void:
	EventBusManager.damaged.connect(_on_damaged)
	EventBusManager.invincibility_damage_block.connect(_on_invincibility_block)
	EventBusManager.parry.connect(_on_parry)
	
	match SettingsConfigSystem.difficulty:
		SettingsConfigSystem.difficulties.RPER:
			batte_tendency_decrease_multiplier = 0.5
		SettingsConfigSystem.difficulties.AGENT:
			batte_tendency_decrease_multiplier = 0.75
		SettingsConfigSystem.difficulties.GREYTIDE:
			batte_tendency_decrease_multiplier = 1.0

func _on_invincibility_block(emitter: Node2D):
	if emitter == parent:
		battle_tendency += 30
		if stage != battle_tendency_stages.EUPHORIA:
			health_component.hard_damage -= 10

func _on_parry(emitter: Node2D, type: String, enemy: bool):
	if emitter == parent and enemy and type == "Projectile":
		battle_tendency += 30
		if stage != battle_tendency_stages.EUPHORIA:
			health_component.hard_damage -= 10

func _on_damaged(emitter: Node2D, damage: float, damager: Node2D) -> void:
	if damage <= 0:
		return
	var amount: float
	# ON ENEMY DAMAGED
	if emitter != parent and damager == parent:
		amount = damage * battle_tendency_by_damage_multiplier
	# ON PARENT DAMAGED BY ENEMY
	if emitter == parent and damager != parent:
		amount = -damage * 13 * battle_tendency_by_damage_multiplier * batte_tendency_decrease_multiplier
	# ON SELFHARM
	if emitter == parent and damager == parent:
		amount = -damage * 16 * battle_tendency_by_damage_multiplier * batte_tendency_decrease_multiplier
	
	battle_tendency += amount
	if stage != battle_tendency_stages.EUPHORIA:
		health_component.hard_damage -= amount * 0.25
