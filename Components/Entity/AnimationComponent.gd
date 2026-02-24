class_name AnimationComponent extends Component

var animation_priority: int = -1
var animation_tween: Tween = null

var last_time_scale: float

@export var ignore_time_scale: bool = false
@onready var shader: ShaderMaterial

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
	
	_tween.tween_property(parent, "global_rotation", 0, 0.2)
	_tween.tween_property(parent, "scale", Vector2(1, 1), 0.2)
	_tween.tween_property(parent, "skew", 0, 0.2)

func shift_to_direction(
	direction: Vector2,
	time: float,
	multiplier: float = 1.0
	) -> void:
	
	for child in parent.get_children():
		if child is not Sprite2D:
			continue
		
		if child.position.length() > 13:
			continue
		
		var _tween: Tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.set_ease(Tween.EASE_IN_OUT)
		
		_tween.tween_property(child, "position", child.position + direction.normalized() * multiplier * 10, time)
		_tween.tween_property(child, "position", Vector2.ZERO, time)

func lean_to_direction(
	direction: Vector2,
	priority,
	time: float = 0.2,
	rotation_multiplier: float = 1.0
	) -> void:
	
	var angle: float = direction.angle()
	var angle_deg: float = rad_to_deg(angle)
	
	var rotation: Dictionary = get_rotation_from_angle(angle_deg)
	
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	
	_tween.tween_property(parent, rotation.type, rotation.value * rotation_multiplier, time)
	_tween.tween_property(parent, rotation.type, 0 , time)
	
	set_animation(_tween, priority)

func get_rotation_from_angle(angle_deg: float) -> Dictionary:
	var side: int = get_direction(angle_deg)
	
	if side == 2 or side == 4:
		return {"type": "skew", "value": 0.25}
	elif side == 1:
		return {"type": "rotation", "value": 0.5}
	elif side == 3:
		return {"type": "rotation", "value": -0.5}
	else:
		return {"type": null, "value": null}

func get_direction(angle_deg: float) -> int:
	var direction: int
	angle_deg = fmod(angle_deg + 360.0, 360.0)
	
	if angle_deg >= 315.0 or angle_deg < 45.0:
		direction = 1
	elif angle_deg >= 45.0 and angle_deg < 135.0:
		direction = 2
	elif angle_deg >= 135.0 and angle_deg < 225.0:
		direction = 3
	elif angle_deg >= 225.0 and angle_deg < 315.0:
		direction = 4
	
	return direction

func flash(
	speed_multiplier: float = 1,
	color: Color = Color(0.7, 0.0, 0.3, 0.729)
	) -> void:
	
	if (!shader and parent and parent.material) or shader and parent.material and shader != parent.material:
		shader = parent.material
	
	if shader and shader.get_shader_parameter("flash_color"):
		var _tween: Tween = create_tween()
		_tween.tween_property(shader, "shader_parameter/flash_color", color, 0.1 * speed_multiplier)
		_tween.tween_property(shader, "shader_parameter/flash_color", Color(0.7, 0.0, 0.3, 0.0), 0.2 * speed_multiplier)
