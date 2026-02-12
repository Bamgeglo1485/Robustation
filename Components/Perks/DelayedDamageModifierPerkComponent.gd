class_name DelayedDamageModifierPerkComponent extends BasePerkComponent

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")

func _init() -> void:
	perk_name = "Galaxythistle"
	perk_desc = "Reduces delayed damage by 5%"
	perk_icon = preload("res://Textures/Perks/galaxythistle.png")
	perk_equipped_texture = preload("res://Textures/Perks/galaxythistle_equipped.png")

func apply_modifiers() -> void:
	if !health_component:
		return
	
	health_component.delayed_damage_modifier *= 0.95
