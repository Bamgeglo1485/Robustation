class_name PenetrationModifierComponent extends BasePerkComponent

@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")
@onready var bounce_modifier_component: BounceModifierPerkComponent = parent.get_node_or_null("BounceModifierPerkComponent")

func _init() -> void:
	untranslated_perk_name = "Double Penetration Bullets"
	perk_desc = "[color=green]Increases projectile penetration[/color], but [color=crimson]decreases damage by 10%[/color]"
	perk_icon = preload("res://Textures/Perks/double_penetration.png")
	perk_equipped_texture = preload("res://Textures/Perks/double_penetration_equipped.png")
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@export var base_damage_modifier: float = 0.9
var extra_penetrations: int = 0

func _ready() -> void:
	super._ready()

func apply_modifiers() -> void:
	if !bounce_modifier_component and parent:
		bounce_modifier_component = parent.get_node_or_null("BounceModifierPerkComponent")
	if parent and bounce_modifier_component and extra_penetrations >= 0:
		bounce_modifier_component.apply_modifiers()
	if !weapon_user_component and parent:
		weapon_user_component = owner.get_node_or_null("WeaponUserComponent")
	if weapon_user_component:
		weapon_user_component.set_minor_modifier("PenetrationModifier", base_damage_modifier ** amount)
		weapon_user_component.extra_penetrations = amount + extra_penetrations
		set_second_minor_stat("[color=crimson]Damage Modifier:[/color] " + str(weapon_user_component.minor_damage_modifier), "damage_modifier")
		set_minor_stat("[color=crimson]Projectile Penetrations:[/color] " + str(weapon_user_component.extra_penetrations), "penetrations")
