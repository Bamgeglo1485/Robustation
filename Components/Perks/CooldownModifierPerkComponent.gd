class_name CooldownModifierPerkComponent extends BasePerkComponent

@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")

func _init() -> void:
	untranslated_perk_name = "Combat Glove"
	perk_desc = "[color=green]Reduces weapon cooldown by 5%[/color]"
	perk_icon = preload("res://Textures/Perks/combat_glove.png")
	perk_equipped_texture = preload("res://Textures/Perks/combat_glove_equipped.png")
	rarity = rarity_classes.ROBUST
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@export var base_cooldown_modifier = 0.95
@onready var start_cooldown_modifier: float = weapon_user_component.cooldown_modifier
@onready var start_recover_modifier: float = weapon_user_component.recover_modifier

func apply_modifiers() -> void:
	if !weapon_user_component:
		return
	
	var modifier: float = (base_cooldown_modifier ** amount)
	weapon_user_component.cooldown_modifier = start_cooldown_modifier * modifier
	weapon_user_component.recover_modifier = start_recover_modifier * modifier
