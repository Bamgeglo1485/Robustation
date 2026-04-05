class_name ExplosionDamageModifierPerkComponent extends BasePerkComponent

func _init() -> void:
	untranslated_perk_name = "Opened Plasma Tank"
	perk_desc = "[color=green]Increases explosion damage by 10%[/color], but [color=crimson]increases also for enemies[/color]"
	perk_icon = preload("res://Textures/Perks/plasma_tank.png")
	perk_equipped_texture = preload("res://Textures/Perks/plasma_tank_equipped.png")
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@export var base_explosion_damage_modifier: float = 1.15

func _ready() -> void:
	EventBusManager.explosion.connect(_on_exlosion)
	super._ready()

func _on_exlosion(explosion: Node2D):
	explosion.damage *= base_explosion_damage_modifier ** amount
