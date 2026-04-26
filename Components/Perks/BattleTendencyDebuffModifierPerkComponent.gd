class_name BattleTendencyDebuffModifierPerkComponent extends BasePerkComponent

@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
@onready var ephedrine_overdose: OverdoseAbilityComponent = parent.get_node_or_null("OverdoseAbilityComponent")

func _init() -> void:
	untranslated_perk_name = "Inspector's Flask"
	perk_desc = "[color=green]Decreases your Battle Tendency reduction by 10%[/color], but [color=crimson]increases weapon spread by 25%[/color]"
	perk_icon = preload("res://Textures/Perks/inspectors_flask.png")
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@export var base_tendency_modifier: float = 0.9
@export var base_spread_modifier: float = 1.25
var starting_base_tendency_modifier: float = 1.0
var starting_spread_modifier: float = 1.0
@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")
@onready var battle_tendency_component: BattleTendencyComponent = parent.get_node_or_null("BattleTendencyComponent")

func _ready() -> void:
	super._ready()
	starting_base_tendency_modifier = battle_tendency_component.batte_tendency_decrease_multiplier
	starting_spread_modifier = weapon_user_component.spread_modifier

func apply_modifiers() -> void:
	if !mob_mover_component:
		return
	
	battle_tendency_component.batte_tendency_decrease_multiplier = starting_base_tendency_modifier * (base_tendency_modifier ** amount)
	weapon_user_component.spread_modifier = starting_spread_modifier * (base_spread_modifier ** amount)
	set_second_minor_stat("[color=crimson]Spread:[/color] " + str(weapon_user_component.spread_modifier * 100) + "%", "spread_modifier")
