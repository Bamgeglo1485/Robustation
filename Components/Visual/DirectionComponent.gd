class_name DirectionComponent extends Component

enum Direction {
	RIGHT = 1,
	DOWN = 2,
	LEFT = 3,
	UP = 4}

@export var direction: Direction = Direction.DOWN

signal direction_changed(new_rect: Rect2)

func look_at_direction(look_direction: Vector2) -> Direction:
	var new_direction: Direction = Direction.UP
	
	if abs(look_direction.x) > abs(look_direction.y):
		if look_direction.x > 0:
			new_direction = Direction.RIGHT
		else:
			new_direction = Direction.LEFT
	else:
		if look_direction.y > 0:
			new_direction = Direction.DOWN
		else:
			new_direction = Direction.UP
	
	if new_direction != direction:
		direction = new_direction
		change_rect(_get_rect_for_direction(direction))
	
	return direction

func _get_rect_for_direction(dir: Direction) -> Rect2:
	match dir:
		Direction.RIGHT:
			return Rect2(0, 32, 32, 32)
		Direction.DOWN:
			return Rect2(0, 0, 32, 32)
		Direction.LEFT:
			return Rect2(32, 32, 32, 32)
		Direction.UP:
			return Rect2(32, 0, 32, 32)
		_:
			return Rect2(0, 0, 32, 32)

func change_rect(rect) -> void:
	direction_changed.emit(rect)
