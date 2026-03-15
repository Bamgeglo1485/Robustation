class_name CollectablePerkComponent extends Component

@export var random_perk: bool = true
@export_file_path() var random_perks: Array[String]
@export var perk: Script
@export var area: Area2D
@export var sprite: Sprite2D
@export var amount: int = 1

func _ready() -> void:
	if !area:
		parent.queue_free()
		return
	
	area.body_entered.connect(_on_collide)
	
	if random_perk:
		perk = _get_random_perk()
	
	if !perk:
		push_error("404: PERK NOT FOUND")
		parent.queue_free()
		return
	
	if sprite:
		var inst_perk = perk.new()
		sprite.texture = inst_perk.perk_icon
		inst_perk.queue_free()
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sprite, "position", Vector2(0, 5), 1)
		tween.tween_property(sprite, "position", Vector2(0, -5), 1)
		tween.set_loops()

func _on_collide(body) -> void:
	var perk_comp: PerkOwnerComponent = body.get_node("PerkOwnerComponent")
	if !perk or !perk_comp or !perk_comp.can_collect:
		return
	
	var tween: Tween = create_tween()
	tween.tween_property(parent, "global_position", body.global_position, 0.1)
	tween.tween_property(parent, "scale", Vector2(0, 0), 0.1)
	tween.tween_property(parent, "modulate", Color(0.904, 1.0, 0.0, 1.0), 0.1)
	
	await tween.finished
	
	perk_comp.add_perk(perk, amount)
	parent.queue_free()

func _get_random_perk():
		var valid_perks: Array[Script] = []
		for potential_perk in random_perks:
			var loaded_perk = load(potential_perk)
			if loaded_perk is Script:
				valid_perks.append(loaded_perk)
		
		if valid_perks.is_empty():
			return
		
		return valid_perks.pick_random()
