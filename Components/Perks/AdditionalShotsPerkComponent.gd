class_name AdditionalShotsPerkComponent extends BasePerkComponent

func _init() -> void:
	untranslated_perk_name = "Shiny Green Bullets"
	perk_desc = "[color=green]Increases the amount of shotgun pellets by 1[/color], but [color=crimson]increases overheat per shot by 40%[/color]"
	perk_icon = preload("res://Textures/Perks/shiny_green_bullets.png")
	rarity = rarity_classes.ROBUST
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@onready var weapon_user_component: WeaponUserComponent
@export var base_overheat_per_shoot_modifier: float = 1.3
var starting_overheat_per_shoot_modifier: float = 1.0

func apply_modifiers() -> void:
	if weapon_user_component:
		weapon_user_component.overheat_per_shoot_modifier = starting_overheat_per_shoot_modifier * (base_overheat_per_shoot_modifier ** amount)
		weapon_user_component.extra_shots = amount

func _ready() -> void:
	weapon_user_component = parent.get_node_or_null("WeaponUserComponent")
	if weapon_user_component:
		starting_overheat_per_shoot_modifier = weapon_user_component.overheat_per_shoot_modifier
	super._ready()
