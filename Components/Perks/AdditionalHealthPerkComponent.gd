class_name AdditionalHealthPerkComponent extends BasePerkComponent

func _init() -> void:
	untranslated_perk_name = "Bandage and (Toxic) Marker"
	perk_desc = "[color=green]Increases your maximum health by 5 unit[/color], but [color=crimson]decreases passive regeneration by 2 unit[/color]"
	perk_icon = preload("res://Textures/Perks/bandage_and_marker.png")
	perk_equipped_texture = preload("res://Textures/Perks/bandage_equipped.png")
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
@onready var regeneration_perk: RegenerationPerkComponent = parent.get_node_or_null("RegenerationPerkComponent")

@export var base_health_increase: int = 5
@export var base_regeneration_decrease: int = 4

func apply_modifiers() -> void:
	if !health_component:
		return
	
	health_component.max_health = health_component.base_max_health + amount * base_health_increase
	if regeneration_perk:
		regeneration_perk.additive_regeneration = -base_regeneration_decrease * amount
