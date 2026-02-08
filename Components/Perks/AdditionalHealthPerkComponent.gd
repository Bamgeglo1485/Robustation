class_name AdditionalHealthPerkComponent extends BasePerkComponent

func _init() -> void:
	perk_name = "Bandage and (toxic) Marker"
	perk_desc = "Increases your health by 10 unit"
	perk_icon = preload("res://Textures/Perks/bandage_and_marker.png")
	perk_equipped_texture = preload("res://Textures/Perks/bandage_equipped.png")
	
@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")

func apply_modifiers() -> void:
	if !health_component:
		return
	
	health_component.max_health = health_component.base_max_health + amount * 10
