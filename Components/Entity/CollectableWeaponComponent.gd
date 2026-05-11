class_name CollectableWeaponComponent extends Component

@export var random_weapon: bool = true
@export var weapons: Array[PackedScene]
@export var area: Area2D
@export var sprite: Sprite2D
var weapon: PackedScene

func _ready() -> void:
	if !area:
		parent.queue_free()
		return
	
	weapon = weapons.pick_random()
	
	area.body_entered.connect(_on_collide)
	
	if sprite:
		var inst: Weapon = weapon.instantiate()
		sprite.texture = inst.icon_texture
		inst.queue_free()
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sprite, "position", Vector2(0, 5), 1)
		tween.tween_property(sprite, "position", Vector2(0, -5), 1)
		tween.set_loops()

func _on_collide(body) -> void:
	var weapon_user_comp: PlayerWeaponUserComponent = body.get_node_or_null("PlayerWeaponUserComponent")
	if !weapon or !weapon_user_comp:
		return
	
	var tween: Tween = create_tween()
	tween.tween_property(parent, "global_position", body.global_position, 0.1)
	tween.tween_property(parent, "scale", Vector2(0, 0), 0.1)
	tween.tween_property(parent, "modulate", Color(0.904, 1.0, 0.0, 1.0), 0.1)
	
	await tween.finished
	
	var inst: Weapon = weapon.instantiate()
	weapon_user_comp.add_weapon_to_inventory(inst)
	parent.queue_free()
