class_name BounceModifierPerkComponent extends BasePerkComponent

@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")
@onready var penetration_perk: PenetrationModifierComponent = parent.get_node_or_null("PenetrationModifierComponent")

func _init() -> void:
	untranslated_perk_name = "Rubber Bullets(Without jokes about dildos pls)"
	perk_desc = "[color=green]Increases projectile bounce[/color], but [color=crimson]decreases projectile penetration[/color]"
	perk_icon = preload("res://Textures/Perks/rubber_bullets.png")
	rarity = rarity_classes.ROBUST
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

func _ready() -> void:
	super._ready()

func apply_modifiers() -> void:
	if !penetration_perk and parent:
		penetration_perk = parent.get_node_or_null("PenetrationModifierComponent")
	
	if !weapon_user_component and parent:
		weapon_user_component = parent.get_node_or_null("WeaponUserComponent")
	
	if weapon_user_component:
		weapon_user_component.extra_bounces = amount
	if penetration_perk:
		penetration_perk.extra_penetrations = -amount
		penetration_perk.apply_modifiers()
	
	set_minor_stat("[color=crimson]Projectile Bounces:[/color] " + str(amount), "bounces")
	if weapon_user_component:
		set_second_minor_stat("[color=crimson]Projectile Penetrations:[/color] " + str(weapon_user_component.extra_penetrations), "penetrations")
