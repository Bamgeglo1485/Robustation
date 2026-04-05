class_name PenetrationModifierComponent extends BasePerkComponent

@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")

func _init() -> void:
	untranslated_perk_name = "Double Penetration Bullets"
	perk_desc = "[color=green]Increases projectile penetration[/color], but [color=crimson]decreases damage by 4%[/color]"
	perk_icon = preload("res://Textures/Perks/double_penetration.png")
	perk_equipped_texture = preload("res://Textures/Perks/double_penetration_equipped.png")
	rarity = rarity_classes.ROBUST
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@export var base_damage_modifier: float = 0.96

func _ready() -> void:
	super._ready()
	EventBusManager.projectile_shoot.connect(_on_projectile_shoot)

func apply_modifiers() -> void:
	if weapon_user_component:
		weapon_user_component.set_minor_modifier("PenetrationModifier", base_damage_modifier ** amount)

func _on_projectile_shoot(emitter, _weapon, _direction, projectile):
	if emitter != parent:
		return
	
	var projectile_component = projectile.get_node_or_null("ProjectileComponent")
	if !projectile_component:
		return
	
	projectile_component.max_penetrations += amount
