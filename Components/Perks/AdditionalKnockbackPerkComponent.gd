class_name AdditionalKnockbackPerkComponent extends BasePerkComponent

func _init() -> void:
	perk_name = "Pushorn"
	perk_desc = "[color=green]Increases your selected weapon knockback power[/color]"
	perk_icon = preload("res://Textures/Perks/pushorn.png")
	rarity = rarity_classes.ROBUST

func _ready() -> void:
	EventBusManager.damaged.connect(_on_damaged)

func _on_damaged(source, damage, damager):
	if damager != parent:
		return
	
	var mob_mover_component: MobMoverComponent = source.get_node_or_null("MobMoverComponent")
	if !mob_mover_component:
		return
	
	var direction = (source.global_position - parent.global_position)
	var speed = damage * amount
	mob_mover_component.throw(direction, speed, parent, 100)
