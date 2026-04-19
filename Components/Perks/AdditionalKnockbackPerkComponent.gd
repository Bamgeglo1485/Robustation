class_name AdditionalKnockbackPerkComponent extends BasePerkComponent

func _init() -> void:
	untranslated_perk_name = "Git Push"
	perk_desc = "[color=green]Increases your attack knockback power and the damage of enemy-to-enemy collisions by 40%[/color]"
	perk_icon = preload("res://Textures/Perks/pushorn.png")
	rarity = rarity_classes.ROBUST
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

@export var base_throw_damage_modifier: float = 1.4
var throw_damage_modifier: float = 1.4

func _ready() -> void:
	EventBusManager.damaged.connect(_on_damaged)
	EventBusManager.body_to_body_collision.connect(_on_collide)

func apply_modifiers() -> void:
	throw_damage_modifier = base_throw_damage_modifier ** amount

func _on_damaged(source, damage, damager):
	if damager != parent:
		return
	
	var mob_mover_component: MobMoverComponent = source.get_node_or_null("MobMoverComponent")
	if !mob_mover_component:
		return
	
	await tree.physics_frame
	
	if !is_instance_valid(source):
		return
	
	var direction = (source.global_position - parent.global_position)
	mob_mover_component.throw(direction, damage * amount, parent, 100, true, true, true, 0)

func _on_collide(source: Node2D, _body: Node2D, damage: float, body_health: HealthComponent) -> void:
	if body_health and damage != 0:
		body_health.take_damage(damage * throw_damage_modifier - throw_damage_modifier, source, "Collision")
