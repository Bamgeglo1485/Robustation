class_name SpeedModifierPerkComponent extends BasePerkComponent

@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
@onready var ephedrine_overdose: OverdoseAbilityComponent = parent.get_node_or_null("OverdoseAbilityComponent")

func _init() -> void:
	untranslated_perk_name = "Ephedrine Cigarette"
	perk_desc = "[color=green]Increases your movement speed by 5%[/color], but [color=crimson]decreases Ephedrine Overdose delay by 5%[/color]"
	perk_icon = preload("res://Textures/Perks/ephderine_cigarette.png")
	perk_equipped_texture = preload("res://Textures/Perks/cigarette_equipped.png")
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@export var base_speed_modifier = 1.05
@export var base_overdose_modifier = 0.95
var base_overdose_delay: float = 1.0

func _ready() -> void:
	if ephedrine_overdose:
		base_overdose_delay = ephedrine_overdose.ability_delay
	super._ready()

func apply_modifiers() -> void:
	if !mob_mover_component:
		return
	
	mob_mover_component.set_minor_speed_modifier("SpeedModifier", base_speed_modifier ** amount)
	if ephedrine_overdose:
		ephedrine_overdose.ability_delay = base_overdose_delay * (base_overdose_modifier ** amount)
