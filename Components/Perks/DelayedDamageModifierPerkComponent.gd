class_name DelayedDamageModifierPerkComponent extends BasePerkComponent

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")

func _init() -> void:
	untranslated_perk_name = "Galaxythistle"
	perk_desc = "[color=green]Reduces delayed damage by 10%[/color]"
	perk_icon = preload("res://Textures/Perks/galaxythistle.png")
	perk_equipped_texture = preload("res://Textures/Perks/galaxythistle_equipped.png")
	rarity = rarity_classes.SHITTY
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@export var base_delayed_damage_modifier: float = 0.9
var start_delayed_damage_modifier: float

func _ready() -> void:
	start_delayed_damage_modifier = health_component.delayed_damage_modifier
	super._ready()

func apply_modifiers() -> void:
	if !health_component:
		return
	
	health_component.delayed_damage_modifier = start_delayed_damage_modifier * (base_delayed_damage_modifier ** amount)
	set_minor_stat("[color=crimson]Delayed Damage:[/color] " + str(health_component.delayed_damage_modifier * 100) + "%", "delayed_damage_modifier")
