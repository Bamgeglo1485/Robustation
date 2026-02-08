class_name SpeedModifierPerkComponent extends BasePerkComponent

@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")

func _init() -> void:
	perk_name = "Ephedrine Cigarette"
	perk_desc = "Increases your movement speed by 5%"
	perk_icon = preload("res://Textures/Perks/ephderine_cigarette.png")
	perk_equipped_texture = preload("res://Textures/Perks/cigarette_equipped.png")

func apply_modifiers() -> void:
	if !mob_mover_component:
		return
	
	mob_mover_component.speed_modifier *= 1.05
