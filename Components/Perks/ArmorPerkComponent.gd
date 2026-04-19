class_name ArmorPerkComponent extends BasePerkComponent

func _init() -> void:
	untranslated_perk_name = "Goliath Plate"
	perk_desc = "[color=green]Increases your armor by 5%[/color], but [color=crimson]decreases healing from organs crushing by 10%[/color]"
	perk_icon = preload("res://Textures/Perks/goliath_plate.png")
	perk_equipped_texture = preload("res://Textures/Perks/goliath_plate_equipped.png")
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
@export var base_armor: float = 0.95
@export var base_organ_heal_modifier: float = 0.9

func apply_modifiers() -> void:
	if !health_component:
		return
	
	health_component.armor *= (base_armor ** amount)
	health_component.healing_from_organs_modifier = base_organ_heal_modifier ** amount
