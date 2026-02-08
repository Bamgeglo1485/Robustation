class_name ArmorPerkComponent extends BasePerkComponent

func _init() -> void:
	perk_name = "Goliath Plate"
	perk_desc = "Increases your armor by 5%"
	perk_icon = preload("res://Textures/Perks/goliath_plate.png")
	perk_equipped_texture = preload("res://Textures/Perks/goliath_plate_equipped.png")

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")

func apply_modifiers() -> void:
	if !health_component:
		return
	
	health_component.armor *= 0.05
