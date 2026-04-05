class_name AdditionalKnockbackPerkComponent extends BasePerkComponent

func _init() -> void:
	untranslated_perk_name = "Git Push"
	perk_desc = "[color=green]Increases your attack knockback power[/color]"
	perk_icon = preload("res://Textures/Perks/pushorn.png")
	rarity = rarity_classes.ROBUST
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

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
