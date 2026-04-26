class_name PerfectTimerPerkComponent extends BasePerkComponent

func _init() -> void:
	untranslated_perk_name = "Speed Up + Reverb"
	perk_desc = "[color=green]Increases HP recovery from a perfect hit by 10%[/color], but [color=crimson]speeds up the arrow by 10%[/color]"
	perk_icon = preload("res://Textures/Perks/speed_up.png")
	rarity = rarity_classes.ROBUST
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@onready var weapon_user_component: WeaponUserComponent
@export var base_hp_recovery_modifier: float = 1.1
@export var base_arrow_speed_modifier: float = 1.1
var starting_hp_recovery_modifier: float = 0.3
var starting_arrow_speed_modifier: float = 0.3

func apply_modifiers() -> void:
	if weapon_user_component:
		weapon_user_component.qte_time_mod = starting_arrow_speed_modifier * (base_arrow_speed_modifier ** amount)
		weapon_user_component.qte_perfect_heal_modifier_from_max_modifier = starting_hp_recovery_modifier * (base_hp_recovery_modifier ** amount)
		set_minor_stat("[color=crimson]Heal From Perfect Hit:[/color] " + str(weapon_user_component.qte_perfect_heal_modifier_from_max_modifier * 100 - 100) + "%", "qte_perfect_heal_modifier_from_max_modifier")
		set_second_minor_stat("[color=crimson]Perfect Hit Arrow Speed:[/color] " + str(weapon_user_component.qte_time_mod * 100) + "%", "qte_time_mod")

func _ready() -> void:
	weapon_user_component = parent.get_node_or_null("WeaponUserComponent")
	if weapon_user_component:
		starting_hp_recovery_modifier = weapon_user_component.qte_perfect_heal_modifier_from_max_modifier
		starting_arrow_speed_modifier = weapon_user_component.qte_time_mod
	super._ready()
