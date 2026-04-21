class_name HealForParryPerkComponent extends BasePerkComponent

func _init() -> void:
	untranslated_perk_name = "Redspace Paint"
	perk_desc = "[color=green]Adds and increases healing from projecile parry by 2%[/color]"
	perk_icon = preload("res://Textures/Perks/redspace_paint.png")
	perk_equipped_texture = preload("res://Textures/Perks/redspace_paint_equipped.png")
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")

@export var base_heal_for_parry_multiplier: float = 1.02
var heal_for_parry_multiplier: float = 1.02

func _ready() -> void:
	super._ready()
	EventBusManager.parry.connect(_on_parry)

func apply_modifiers() -> void:
	heal_for_parry_multiplier = base_heal_for_parry_multiplier ** amount

func _on_parry(emitter: Node2D, type: String, enemy: bool) -> void:
	if emitter != parent or type != "Projectile" or !enemy:
		return
	
	health_component.take_damage(-health_component.health * heal_for_parry_multiplier - health_component.health, null)
