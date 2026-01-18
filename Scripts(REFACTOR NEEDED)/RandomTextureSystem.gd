extends Sprite2D

@export var change_rect = false
@export var random_color = false

func _ready() -> void:
	if owner != null:
		owner.direction_changed.connect(_direction_changed)
	
	var textures = self.get_children(false)
	
	if textures.is_empty():
		return
	
	var selected_texture = textures.pick_random()
	texture = selected_texture.texture
	
	for texture_to_delete in textures:
		texture_to_delete.queue_free()
	
	if random_color == true:
		modulate = Color(randf_range(0,0.4), randf_range(0,0.4), randf_range(0,0.4))
		

func _direction_changed(rect) -> void:
	if change_rect == true:
		region_rect = rect
