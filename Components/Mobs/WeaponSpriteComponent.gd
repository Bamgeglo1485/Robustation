class_name WeaponSpriteComponent extends Sprite2D

@export var up_position: Marker2D
@export var right_position: Marker2D
@export var down_position: Marker2D
@export var left_position: Marker2D

@export var up_position_below_texture: bool
@export var right_position_below_texture: bool
@export var down_position_below_texture: bool
@export var left_position_below_texture: bool

@export var idle_animation: bool = true
@export var ignore_time_scale: bool = false

@onready var parent = get_parent()
@onready var direction_component: DirectionComponent = parent.get_node_or_null("DirectionComponent")
@onready var parent_texture: Sprite2D = parent.get_node_or_null("Texture")

var weapon_texture: Sprite2D
var right_index: int
var down_index: int
var left_index: int
var up_index: int

var animation_priority: int = -1
var animation_tween: Tween

func set_animation(tween, priority, rewrite = false) -> void:
	if (priority > animation_priority) or (priority == animation_priority and rewrite):
		if animation_tween:
			animation_tween.kill()
		tween.set_ignore_time_scale(ignore_time_scale)
		animation_tween = tween
		animation_priority = priority
		
		animation_tween.finished.connect(clear_animation)
	else:
		tween.kill()

func clear_animation(kill_tween = true) -> void:
	if animation_tween and kill_tween:
		animation_tween.kill()
	animation_priority = -1
	_clear_tween()

func _clear_tween() -> void:
	var _tween: Tween = create_tween()
	_tween.tween_property(weapon_texture, "rotation", 0.0, 0.2)
	_tween.tween_property(weapon_texture, "position", Vector2.ZERO, 0.2)
	_tween.tween_property(weapon_texture, "scale", Vector2(1, 1), 0.2)
	_tween.tween_property(weapon_texture, "skew", 0.0, 0.2)

func _idle_animation() -> void:
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(weapon_texture, "rotation", 0, 0.2)
	_tween.tween_property(weapon_texture, "rotation", 8, 0.5)
	_tween.tween_property(weapon_texture, "rotation", 0, 0.5)
	
	set_animation(_tween, 0, true)

func _ready() -> void:
	direction_component.direction_changed.connect(_on_direction_changed)
	position = down_position.position
	
	var base_index: int = parent_texture.z_index + 1
	var below_offset: int = -2
	
	up_index = base_index + below_offset if up_position_below_texture else base_index
	down_index = base_index + below_offset if down_position_below_texture else base_index
	left_index = base_index + below_offset if left_position_below_texture else base_index
	right_index = base_index + below_offset if right_position_below_texture else base_index
	
	weapon_texture = Sprite2D.new()
	add_child.call_deferred(weapon_texture)
	weapon_texture.texture = texture
	texture = null
	
	_idle_animation()

func _on_direction_changed(_new_rect) -> void:
	match direction_component.direction:
		direction_component.Direction.RIGHT:
			position = right_position.position
			z_index = right_index
		direction_component.Direction.UP:
			position = up_position.position
			z_index = up_index
		direction_component.Direction.LEFT:
			position = left_position.position
			z_index = left_index
		direction_component.Direction.DOWN:
			position = down_position.position
			z_index = down_index
