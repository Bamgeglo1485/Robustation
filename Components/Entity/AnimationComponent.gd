class_name AnimationComponent extends Component

var animation_priority: int = -1
var animation_tween: Tween = null

var last_time_scale: float

@export var ignore_time_scale: bool = false

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if ignore_time_scale == true and last_time_scale == Engine.time_scale:
		return
	
	last_time_scale = Engine.time_scale
	
	if animation_tween != null:
		animation_tween.set_speed_scale(Engine.time_scale)

func set_animation(tween, priority, rewrite = false):
	if (priority > animation_priority) or (priority == animation_priority and rewrite == true):
		if animation_tween != null:
			animation_tween.kill()
		tween.set_ignore_time_scale(ignore_time_scale)
		animation_tween = tween
		animation_priority = priority
		
		animation_tween.finished.connect(_on_animation_end)
	else:
		tween.kill()

func clear_animation():
	if animation_tween != null:
		animation_tween.kill()
	animation_priority = -1
	_clear_tween()

func _clear_tween():
	var _tween = create_tween()
	
	_tween.tween_property(parent, "global_rotation", 0, 0.2)
	_tween.tween_property(parent, "scale", Vector2(1, 1), 0.2)
	_tween.tween_property(parent, "skew", 0, 0.2)

func _on_animation_end():
	clear_animation()

func shift_to_direction(direction, time, multiplier = 1):
	for child in parent.get_children():
		if child is not Sprite2D:
			continue
		
		var _tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.set_ease(Tween.EASE_IN_OUT)
		
		_tween.tween_property(child, "position", child.position + direction.normalized() * multiplier * 10, time)
		_tween.tween_property(child, "position", Vector2.ZERO, time)

func lean_to_direction(direction, priority, time = 0.2, rotation_multiplier = 1):
	var angle = direction.angle()
	var angle_deg = rad_to_deg(angle)
	
	var rotation = get_rotation_from_angle(angle_deg)
	
	var _tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	
	_tween.tween_property(parent, rotation.type, rotation.value * rotation_multiplier, time)
	_tween.tween_property(parent, rotation.type, 0 , time)
	
	set_animation(_tween, priority)

func get_rotation_from_angle(angle_deg):
	var side = get_direction(angle_deg)
	
	if side == 2 or side == 4:
		return {"type": "skew", "value": 0.25}
	elif side == 1:
		return {"type": "rotation", "value": 0.5}
	elif side == 3:
		return {"type": "rotation", "value": -0.5}

func get_direction(angle_deg):
	var direction
	angle_deg = fmod(angle_deg + 360, 360)
	
	if angle_deg >= 315 or angle_deg < 45:
		direction = 1
	elif angle_deg >= 45 and angle_deg < 135:
		direction = 2
	elif angle_deg >= 135 and angle_deg < 225:
		direction = 3
	elif angle_deg >= 225 and angle_deg < 315:
		direction = 4
	
	return direction
