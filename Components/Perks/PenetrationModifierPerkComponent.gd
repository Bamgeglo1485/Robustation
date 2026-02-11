class_name PenetrationModifierComponent extends BasePerkComponent

func _init() -> void:
	perk_name = "Double Penetration Bullets"
	perk_desc = "Increases projectile penetration"
	perk_icon = preload("res://Textures/Perks/double_penetration.png")
	perk_equipped_texture = preload("res://Textures/Perks/double_penetration_equipped.png")
	rarity = rarity_classes.ADMINABUSE

func _ready() -> void:
	super._ready()
	
	EventBusManager.projectile_shoot.connect(_on_projectile_shoot)

func _on_projectile_shoot(emitter, _weapon, _direction, projectile):
	if emitter != parent:
		return
	
	var projectile_component = projectile.get_node("ProjectileComponent")
	if !projectile_component:
		return
	
	projectile_component.max_penetrations += amount
