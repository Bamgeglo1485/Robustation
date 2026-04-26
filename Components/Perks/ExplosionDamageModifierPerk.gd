class_name ExplosionDamageModifierPerkComponent extends BasePerkComponent

func _init() -> void:
	untranslated_perk_name = "Opened Plasma Tank"
	perk_desc = "[color=green]Increases explosion damage by 10%[/color], but [color=crimson]increases also for enemies[/color]"
	perk_icon = preload("res://Textures/Perks/plasma_tank.png")
	perk_equipped_texture = preload("res://Textures/Perks/plasma_tank_equipped.png")
	rarity = rarity_classes.ROBUST
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@export var base_explosion_damage_modifier: float = 1.15
var explosion_damage_modifier: float = 1.15

func _ready() -> void:
	EventBusManager.explosion.connect(_on_exlosion)
	super._ready()

func apply_modifiers() -> void:
	explosion_damage_modifier = base_explosion_damage_modifier ** amount
	set_minor_stat("[color=crimson]Explosion Damage:[/color] " + str(explosion_damage_modifier * 100) + "%", "explosion_damage_modifier")

func _on_exlosion(explosion: Node2D):
	explosion.damage *= explosion_damage_modifier
	explosion.radius *= explosion_damage_modifier
