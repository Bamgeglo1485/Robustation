@tool
class_name MoveToPointAction extends ActionLeaf

@export var retreat: bool = false : set = set_retreat
@export var retreat_distance: float = 60
@export var retreat_speed_modifier: float = 0.7
@export var stop_range_min: int = 0
@export var stop_range_max: int = 0
@export var pathfind_update_rate: float = 0.15
@export var move_update_rate: float = 0.1

@onready var parent = owner
@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
@onready var navigation_agent: NavigationAgent2D = parent.get_node_or_null("NavigationAgent")

var move_logic_timer: Timer
var pathfinding_timer: Timer
var point: Vector2
var target_reached: bool = false

@onready var stop_range_min_squared: int = stop_range_min * stop_range_min
@onready var stop_range_max_squared: int = stop_range_max * stop_range_max

@export var key: String = "MovePoint"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if blackboard.has_value(key):
		point = blackboard.get_value(key)
		
		var distance_to_point: float = (point - actor.global_position).length_squared()
		
		if retreat:
			target_reached = false
			return SUCCESS
		
		var in_stop_zone = true
		
		if stop_range_min_squared > 0 and distance_to_point < stop_range_min_squared:
			in_stop_zone = false
		
		if stop_range_max_squared > 0 and distance_to_point > stop_range_max_squared:
			in_stop_zone = false
		
		if stop_range_max_squared == 0 and stop_range_min_squared == 0:
			in_stop_zone = false
		
		if in_stop_zone:
			target_reached = true
			mob_mover_component.direction = Vector2.ZERO
			return SUCCESS
		else:
			target_reached = false
			return SUCCESS
			
	point = Vector2.ZERO
	return FAILURE

func _ready() -> void:
	pathfinding_timer = Timer.new()
	add_child(pathfinding_timer)
	pathfinding_timer.one_shot = true
	pathfinding_timer.wait_time = randf_range(pathfind_update_rate * 0.80, pathfind_update_rate * 1.20)
	pathfinding_timer.timeout.connect(_pathfinding_update)
	pathfinding_timer.start()
	
	move_logic_timer = Timer.new()
	add_child(move_logic_timer)
	move_logic_timer.one_shot = true
	move_logic_timer.wait_time = randf_range(move_update_rate * 0.8, move_update_rate * 1.2)
	move_logic_timer.timeout.connect(_update_move_logic)
	move_logic_timer.start()
	
	if navigation_agent:
		navigation_agent.velocity_computed.connect(_on_navigation_agent_velocity_computed)

func _update_move_logic() -> void:
	if !mob_mover_component or !navigation_agent:
		return
	
	move_logic_timer.start()
	
	if point == Vector2.ZERO or navigation_agent.is_navigation_finished() or target_reached:
		mob_mover_component.direction = Vector2.ZERO
		return
	
	var direction_to_target: Vector2 = (navigation_agent.get_next_path_position() - parent.global_position).normalized()
	mob_mover_component.direction = direction_to_target

func _pathfinding_update() -> void:
	if target_reached:
		pathfinding_timer.start()
		return
		
	if !retreat:
		navigation_agent.target_position = point
	else:
		var direction_from_point = (parent.global_position - point).normalized()
		var retreat_point = parent.global_position + direction_from_point * retreat_distance
		navigation_agent.target_position = retreat_point
	
	pathfinding_timer.start()

func _on_navigation_agent_velocity_computed(safe_velocity: Vector2) -> void:
	if mob_mover_component and safe_velocity.length_squared() > 0.1 and !target_reached:
		mob_mover_component.direction = safe_velocity.normalized()

func set_retreat(new_value) -> void:
	retreat = new_value
	if mob_mover_component:
		if retreat:
			mob_mover_component.set_minor_speed_modifier("retreat", retreat_speed_modifier)
		else:
			mob_mover_component.set_minor_speed_modifier("retreat", 1.0)
