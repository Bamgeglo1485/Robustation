class_name ArmorPerkComponent extends BasePerkComponent

func _init() -> void:
	untranslated_perk_name = "Goliath Plate"
	perk_desc = "[color=green]Increases your armor by 5%[/color], but [color=crimson]decreases heal for damage by 5%[/color]"
	perk_icon = preload("res://Textures/Perks/goliath_plate.png")
	perk_equipped_texture = preload("res://Textures/Perks/goliath_plate_equipped.png")
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
@export var base_armor: float = 0.95
@export var base_health_for_damage_modifier: float = 0.95
## STARTING HEALTH COMPONENT HEAL FOR DAMAGE MULT
var base_heal_for_damage_multiplier: float = 0.95

func _ready() -> void:
	if health_component:
		base_heal_for_damage_multiplier = health_component.heal_for_damage_multiplier
	super._ready()

func apply_modifiers() -> void:
	if !health_component:
		return
	
	health_component.armor *= (base_armor ** amount)
	health_component.heal_for_damage_multiplier = base_heal_for_damage_multiplier * (base_health_for_damage_modifier ** amount)
