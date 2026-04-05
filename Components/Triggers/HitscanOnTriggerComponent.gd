class_name HitscanOnTriggerComponent extends BaseXOnTriggerComponent

@export var hitscan_scene: PackedScene
@export var delete_parent: bool = true

func on_trigger() -> void:
	if !hitscan_scene:
		return
	
	var inst = hitscan_scene.instantiate()
	inst.global_position = parent.global_position
	var hitscan_comp: HitscanComponent = inst.get_node_or_null("HitscanComponent")
	var projectile_comp: ProjectileComponent = parent.get_node_or_null("ProjectileComponent")
	if hitscan_comp and projectile_comp:
		hitscan_comp.direction = projectile_comp.direction
	scene.add_child(inst)
	if delete_parent:
		parent.queue_free()
