class_name CooldownModifierPerkComponent extends BasePerkComponent

@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")

func _init() -> void:
	untranslated_perk_name = "Combat Glove"
	perk_desc = "[color=green]Reduces weapon cooldown by 5%[/color]"
	perk_icon = preload("res://Textures/Perks/combat_glove.png")
	perk_equipped_texture = preload("res://Textures/Perks/combat_glove_equipped.png")
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

func apply_modifiers() -> void:
	if !weapon_user_component:
		return
	
	weapon_user_component.cooldown_modifier *= 1.05
