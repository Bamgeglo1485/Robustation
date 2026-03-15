class_name AdditionalHealthPerkComponent extends BasePerkComponent

func _init() -> void:
	perk_name = "Bandage and (toxic) Marker"
	perk_desc = "[color=green]Increases your health by 15 unit[/color], but [color=crimson]decreases regeneration by 2 unit[/color]"
	perk_icon = preload("res://Textures/Perks/bandage_and_marker.png")
	perk_equipped_texture = preload("res://Textures/Perks/bandage_equipped.png")
	
@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
@onready var regeneration_perk: RegenerationPerkComponent = parent.get_node_or_null("RegenerationPerkComponent")

@export var base_health_increase: int = 15
@export var base_regeneration_decrease: int = 2

func apply_modifiers() -> void:
	if !health_component:
		return
	
	health_component.max_health = health_component.base_max_health + amount * base_health_increase
	if regeneration_perk:
		regeneration_perk.additive_regeneration = -base_regeneration_decrease * amount
