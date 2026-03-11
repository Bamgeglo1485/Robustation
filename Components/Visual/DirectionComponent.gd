class_name DirectionComponent extends Component

enum Direction {
	RIGHT = 1,
	DOWN = 2,
	LEFT = 3,
	UP = 4}

@export var direction: Direction = Direction.DOWN

signal direction_changed(new_rect: Rect2)

func look_at_direction(look_direction: Vector2) -> Direction:
	var angle: float = look_direction.angle()
	var angle_deg: float = rad_to_deg(angle)
	angle_deg = fmod(angle_deg + 360, 360)
	
	var rect: Rect2
	var prev_dir: Direction = direction
	
	if angle_deg >= 315 or angle_deg < 45:
		rect = Rect2(0, 32, 32, 32)
		direction = Direction.RIGHT
	elif angle_deg >= 45 and angle_deg < 135:
		rect = Rect2(0, 0, 32, 32)
		direction = Direction.DOWN
	elif angle_deg >= 135 and angle_deg < 225:
		rect = Rect2(32, 32, 32, 32)
		direction = Direction.LEFT
	elif angle_deg >= 225 and angle_deg < 315:
		rect = Rect2(32, 0, 32, 32)
		direction = Direction.UP
	
	if direction != prev_dir:
		change_rect(rect)
	return direction

func change_rect(rect) -> void:
	direction_changed.emit(rect)
