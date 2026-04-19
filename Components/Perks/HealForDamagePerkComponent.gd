class_name HealForDamagePerkComponent extends BasePerkComponent

func _init() -> void:
	untranslated_perk_name = "Crusher Module"
	perk_desc = "[color=green]Adds and increases healing from damage by 4%[/color], but [color=crimson]healing only works within 3 tiles[/color]"
	perk_icon = preload("res://Textures/Perks/crusher_module.png")
	perk_equipped_texture = preload("res://Textures/Perks/crusher_module_equipped.png")
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")

@export var base_heal_for_damage_multiplier: float = 1.04
@export var heal_for_damage_radius: int = 96
var heal_for_damage_multiplier: float = 1.04

func _ready() -> void:
	super._ready()
	EventBusManager.damaged.connect(_on_damage)
	heal_for_damage_radius *= heal_for_damage_radius

func apply_modifiers() -> void:
	heal_for_damage_multiplier = base_heal_for_damage_multiplier ** amount

func _on_damage(emitter: Node2D, damage: float, damager: Node2D) -> void:
	if !is_instance_valid(emitter) or damager != parent or emitter == parent or damage <= 0:
		return
	if (emitter.global_position - parent.global_position).length_squared() > heal_for_damage_radius:
		return
	var heal: float = damage * heal_for_damage_multiplier - damage
	health_component.take_damage(-heal, parent)
