class_name WeaponSpriteComponent extends Node2D

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

@onready var parent = get_parent().get_parent()
@onready var direction_component: DirectionComponent = parent.get_node_or_null("DirectionComponent")

@export var weapon_texture: Sprite2D
@export var attack_texture: Sprite2D
var weapon_icon: Texture
var equipped_scale: Vector2
var directed_position: Vector2
var right_index: int
var down_index: int
var left_index: int
var up_index: int
var direction: int

var attack_tween: Tween

var animation_priority: int = -1
var animation_tween: Tween
var swing_left: bool = true

func change_weapon_texture(new_texture: Texture, new_weapon_icon: Texture, new_equipped_scale: Vector2):
	weapon_icon = new_weapon_icon
	weapon_texture.texture = new_texture
	weapon_texture.scale = new_equipped_scale
	equipped_scale = new_equipped_scale
	clear_animation(true, true)
	_rotate_to_direction()

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

func clear_animation(kill_tween: bool = true, instant_clear: bool = false) -> void:
	if animation_tween and kill_tween:
		animation_tween.kill()
	animation_priority = -1
	
	if !instant_clear:
		_clear_tween()
	else:
		weapon_texture.position = Vector2.ZERO
		weapon_texture.rotation = 0
		weapon_texture.skew = 0

func _clear_tween() -> void:
	var _tween: Tween = create_tween()
	_tween.tween_property(weapon_texture, "rotation", 0.0, 0.1)
	_tween.tween_property(weapon_texture, "position", Vector2.ZERO, 0.1)
	_tween.tween_property(weapon_texture, "skew", 0.0, 0.1)

func piercing_animation(attack_direction: Vector2, attack_delay: float) -> void:
	attack_texture.texture = weapon_icon
	attack_texture.position = Vector2.ZERO
	var _modulate_tween: Tween = create_tween()
	_modulate_tween.tween_property(attack_texture, "modulate", Color(1.0, 1.0, 1.0, 0.45), 0.2)
	_modulate_tween.tween_property(attack_texture, "modulate", Color(1.0, 1.0, 1.0, 0.0), attack_delay + 0.2)
	
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(attack_texture, "position", to_local(global_position + attack_direction), attack_delay)
	_tween.tween_property(attack_texture, "position", position, 0.2)

func slash_animation(attack_direction: Vector2, attack_length: float = 1.5, arc_angle: float = 130.0, offset: float = 25.0) -> void:
	swing_left = !swing_left
	
	attack_texture.texture = weapon_icon
	attack_texture.global_position = global_position
	attack_texture.modulate = Color(1.0, 1.0, 1.0, 0.8)
	
	var arc_rad = deg_to_rad(arc_angle)
	var base_angle = attack_direction.angle()
	
	var start_angle: float
	var end_angle: float
	
	if swing_left:
		start_angle = base_angle + arc_rad * 0.5
		end_angle = base_angle - arc_rad * 0.5
	else:
		start_angle = base_angle - arc_rad * 0.5
		end_angle = base_angle + arc_rad * 0.5
	
	attack_texture.rotation = start_angle
	attack_texture.position = Vector2(offset, 0).rotated(start_angle)
	
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	
	_tween.tween_method(
		func(t: float):
			var progress = t
			var current_angle = lerp(start_angle, end_angle, progress)
			attack_texture.rotation = current_angle
			
			var direction_offset = Vector2(offset, 0).rotated(current_angle)
			attack_texture.position = direction_offset
			attack_texture.modulate.a = lerp(0.8, 0.0, progress)
			, 0.0, 1.0, attack_length)
	
	await _tween.finished
	
	attack_texture.modulate = Color(1.0, 1.0, 1.0, 0.0)
	attack_texture.position = Vector2.ZERO
	attack_texture.rotation = 0

func ease_out_quart(x: float) -> float:
	return 1.0 - pow(1.0 - x, 4.0)

func flip_hell_yeah(priority: int = 3) -> void:
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.set_ease(Tween.EASE_OUT)
	var negative: float = -1.0
	if direction == 1 or direction == 2:
		negative = 1
	_tween.tween_property(weapon_texture, "rotation", 6.2 * negative, 0.5)
	
	set_animation(_tween, priority, true)
	
	await _tween.finished
	weapon_texture.rotation = 0

func reload(priority: int = 2) -> void:
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.set_ease(Tween.EASE_OUT)
	var negative: float = -1.0
	if direction == 1 or direction == 2:
		negative = 1
	_tween.tween_property(weapon_texture, "rotation", -1.2 * negative, 0.3)
	_tween.tween_property(weapon_texture, "rotation", 0, 0.2)
	
	set_animation(_tween, priority, true)
	
	await _tween.finished
	weapon_texture.rotation = 0

func _ready() -> void:
	if direction_component:
		direction_component.direction_changed.connect(_on_direction_changed)
	position = down_position.position
	
	
	var base_index: int = get_parent().z_index + 1
	var below_offset: int = -2
	
	up_index = base_index + below_offset if up_position_below_texture else base_index
	down_index = base_index + below_offset if down_position_below_texture else base_index
	left_index = base_index + below_offset if left_position_below_texture else base_index
	right_index = base_index + below_offset if right_position_below_texture else base_index

func _on_direction_changed(_new_rect) -> void:
	_rotate_to_direction()
	weapon_texture.region_rect = _new_rect

func _rotate_to_direction() -> void:
	match direction_component.direction:
		direction_component.Direction.RIGHT:
			directed_position = right_position.position
			z_index = right_index
			weapon_texture.scale = equipped_scale
		direction_component.Direction.UP:
			directed_position = up_position.position
			z_index = up_index
			weapon_texture.scale = equipped_scale
		direction_component.Direction.LEFT:
			directed_position = left_position.position
			z_index = left_index
			weapon_texture.scale = Vector2(-equipped_scale.x, equipped_scale.y)
		direction_component.Direction.DOWN:
			directed_position = down_position.position
			z_index = down_index
			weapon_texture.scale = Vector2(-equipped_scale.x, equipped_scale.y)
	
	direction = direction_component.direction
	position = directed_position
	weapon_texture.position = Vector2.ZERO
