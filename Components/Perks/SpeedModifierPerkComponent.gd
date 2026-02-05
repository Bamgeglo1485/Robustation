class_name SpeedModifierPerkComponent extends BasePerkComponent

@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")

func _init() -> void:
	perk_name = "Ephedrine Cigarette"
	perk_desc = "Increases your movement speed by 10%"

func apply_modifiers() -> void:
	if mob_mover_component == null:
		return
	
	mob_mover_component.speed_modifier = 1.0 + amount / 10.0
