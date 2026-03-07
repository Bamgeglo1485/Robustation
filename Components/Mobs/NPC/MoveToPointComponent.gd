class_name MoveToPointComponent extends Component

@export var navigation_agent: NavigationAgent2D
@export var point: Vector2 = Vector2.ZERO
@export var current_priority: int = -1
@export var stop_range: int = 48
@export var pathfind_update_rate: float = 0.3
@export var move_update_rate: float = 0.1
@export var retreat_speed_modifier: float = 0.6
@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
@onready var direction_component: DirectionComponent = parent.get_node_or_null("DirectionComponent")

var move_logic_timer: Timer
var pathfinding_timer: Timer

@export var run_to_target_range: float = 130.0
@export var run_from_target_range: float = 250.0
@export var look_at_direction: bool = false

func set_point(position, priority) -> void:
	if current_priority > priority:
		return
	current_priority = priority
	point = position

func _ready() -> void:
	pathfinding_timer = Timer.new()
	add_child(pathfinding_timer)
	pathfinding_timer.one_shot = true
	pathfinding_timer.wait_time = pathfind_update_rate
	pathfinding_timer.timeout.connect(_pathfinding_update)
	pathfinding_timer.start()
	
	move_logic_timer = Timer.new()
	add_child(move_logic_timer)
	move_logic_timer.one_shot = true
	move_logic_timer.wait_time = move_update_rate
	move_logic_timer.timeout.connect(_update_attack_logic)
	move_logic_timer.start()
	
	if navigation_agent:
		navigation_agent.velocity_computed.connect(_on_navigation_agent_velocity_computed)
	if !mob_mover_component:
		mob_mover_component = parent.get_node_or_null("MobMoverComponent")
	if !direction_component:
		direction_component = parent.get_node_or_null("DirectionComponent")
	
	if mob_mover_component and retreat_speed_modifier != 1:
		mob_mover_component.set_minor_speed_modifier("retreat", 1.0)

func _update_attack_logic() -> void:
	if !mob_mover_component or !navigation_agent:
		return
	
	# Randomize update times to avoid lags
	move_logic_timer.wait_time = randf_range(move_update_rate * 0.8, move_update_rate * 1.2)
	move_logic_timer.start()
	
	if point == Vector2.ZERO:
		mob_mover_component.direction = Vector2.ZERO
		return
	
	var direction_to_target: Vector2 = (point - parent.global_position)
	var distance_to_target: float = direction_to_target.length()
	
	if distance_to_target < stop_range:
		mob_mover_component.direction = Vector2.ZERO
		current_priority = -1
		point = Vector2.ZERO
		return
	
	var direction_to_target_normalized: Vector2 = direction_to_target.normalized()
	mob_mover_component.set_minor_speed_modifier("retreat", 1.0)
	
	if distance_to_target > run_from_target_range:
		if !navigation_agent.is_navigation_finished():
			mob_mover_component.direction = parent.global_position.direction_to(navigation_agent.get_next_path_position())
		else:
			mob_mover_component.direction = Vector2.ZERO
		
		_set_direction()
		
	elif distance_to_target < run_to_target_range:
		var away_direction: Vector2 = -direction_to_target_normalized
		mob_mover_component.set_minor_speed_modifier("retreat", retreat_speed_modifier)
		mob_mover_component.direction = away_direction
		_set_direction()
		
	else:
		mob_mover_component.direction = Vector2.ZERO
		_set_direction()

func _set_direction() -> void:
	if !direction_component or !look_at_direction:
		return
	
	if mob_mover_component.direction != Vector2.ZERO:
		direction_component.look_at_direction(mob_mover_component.direction)
	elif point != Vector2.ZERO:
		var direction_to_target = (point - parent.global_position)
		direction_component.look_at_direction(direction_to_target)
	else:
		direction_component.look_at_direction(Vector2.RIGHT)

func _pathfinding_update() -> void:
	navigation_agent.target_position = point
	
	# Randomize update times to avoid lags
	pathfinding_timer.wait_time = randf_range(pathfind_update_rate * 0.8, pathfind_update_rate * 1.2)
	pathfinding_timer.start()

func _on_navigation_agent_velocity_computed(safe_velocity: Vector2) -> void:
	if mob_mover_component and safe_velocity.length_squared() > 0.1:
		mob_mover_component.direction = safe_velocity.normalized()
