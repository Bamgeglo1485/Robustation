@tool
class_name PointInRangeCondition extends ConditionLeaf

@export var negative: bool = false
@export var min_distance: int = 0
@export var max_distance: int = 32
@export var key: String = "MovePoint"
@export var clear_point: bool = false

@onready var min_distance_squared: int = min_distance * min_distance
@onready var max_distance_squared: int = max_distance * max_distance

func tick(actor: Node, blackboard: Blackboard) -> int:
	var point = blackboard.get_value(key)
	if !point:
		return FAILURE
	
	var length_squared: float = (point - actor.global_position).length_squared()
	var in_range = length_squared >= min_distance_squared and length_squared <= max_distance_squared
	
	if negative:
		if !in_range:
			return SUCCESS
		else:
			if clear_point:
				blackboard.set_value(key, Vector2.ZERO)
			return FAILURE
	else:
		if in_range:
			return SUCCESS
		else:
			if clear_point:
				blackboard.set_value(key, Vector2.ZERO)
			return FAILURE
