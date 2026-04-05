class_name BounceModifierPerkComponent extends BasePerkComponent

@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")

func _init() -> void:
	untranslated_perk_name = "Rubber Bullets(Without jokes about dildos pls)"
	perk_desc = "[color=green]Increases projectile bounce[/color], but [color=crimson]decreases projectile penetration[/color]"
	perk_icon = preload("res://Textures/Perks/rubber_bullets.png")
	rarity = rarity_classes.ROBUST
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

func _ready() -> void:
	super._ready()
	EventBusManager.projectile_shoot.connect(_on_projectile_shoot)

func _on_projectile_shoot(emitter, _weapon, _direction, projectile):
	if emitter != parent:
		return
	
	var projectile_component: ProjectileComponent = projectile.get_node_or_null("ProjectileComponent")
	if !projectile_component:
		return
	
	projectile_component.max_bounces += amount
	if projectile_component.max_penetrations != 0:
		projectile_component.max_penetrations -= amount
