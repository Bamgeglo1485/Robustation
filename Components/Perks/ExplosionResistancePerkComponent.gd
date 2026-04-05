class_name ExplosionResistancePerkComponent extends BasePerkComponent

func _init() -> void:
	untranslated_perk_name = "Rocket Jumpers"
	perk_desc = "[color=green]Increases your explosion resistance by 10%[/color]"
	perk_icon = preload("res://Textures/Perks/rocket_jumpers.png")
	perk_equipped_texture = preload("res://Textures/Perks/rocket_jumpers_equipped.png")
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@onready var explosion_resist: ExplosionResistanceComponent = parent.get_node_or_null("ExplosionResistanceComponent")
@export var base_resist: float = 0.90
var base_resistance: float = 1.0

func _ready() -> void:
	if !explosion_resist:
		explosion_resist = ExplosionResistanceComponent.new()
		parent.add_child.call_deferred(explosion_resist)
	if explosion_resist:
		base_resistance = explosion_resist.resistance
	super._ready()

func apply_modifiers() -> void:
	await ready
	explosion_resist.resistance = base_resistance * (explosion_resist.resistance ** amount)
