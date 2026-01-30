class_name MoveToPointComponent extends Component

@export var navigation_agent: NavigationAgent2D
@export var point: Vector2 = Vector2.ZERO
@export var current_priority: int = -1
@export var stop_range: int = 48
@export var update_rate: float = 0.1
@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
@onready var direction_component: DirectionComponent = parent.get_node_or_null("DirectionComponent")
var pathfinding_timer: Timer

@export var run_to_target_range: float = 130
@export var run_from_target_range: float = 250
@export var look_at_direction: bool = false

func set_point(position, priority):
	if current_priority > priority:
		return
	current_priority = priority
	point = position

func _ready() -> void:
	pathfinding_timer = Timer.new()
	add_child(pathfinding_timer)
	pathfinding_timer.one_shot = true
	pathfinding_timer.wait_time = update_rate
	pathfinding_timer.timeout.connect(_pathfinding_update)
	pathfinding_timer.start()
	
	if navigation_agent != null:
		navigation_agent.velocity_computed.connect(_on_navigation_agent_velocity_computed)
	if mob_mover_component == null:
		mob_mover_component = parent.get_node_or_null("MobMoverComponent")
	if direction_component == null:
		direction_component = parent.get_node_or_null("DirectionComponent")

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if mob_mover_component == null or navigation_agent == null:
		return
	
	if point == Vector2.ZERO:
		mob_mover_component.direction = Vector2.ZERO
		_set_direction()
		return
	
	var direction_to_target = (point - parent.global_position)
	var distance_to_target = direction_to_target.length()
	
	if distance_to_target < stop_range:
		mob_mover_component.direction = Vector2.ZERO
		current_priority = -1
		point = Vector2.ZERO
		_set_direction()
		return
	
	if distance_to_target > run_from_target_range:
		if not navigation_agent.is_navigation_finished():
			mob_mover_component.direction = parent.global_position.direction_to(navigation_agent.get_next_path_position())
		else:
			mob_mover_component.direction = direction_to_target.normalized()
		
		_set_direction()
		
	elif distance_to_target < run_to_target_range:
		var away_direction = -direction_to_target.normalized()
		mob_mover_component.direction = away_direction
		_set_direction()
		
	else:
		mob_mover_component.direction = Vector2.ZERO
		_set_direction()

func _set_direction():
	if direction_component == null or look_at_direction == false:
		return
	
	if mob_mover_component.direction != Vector2.ZERO:
		direction_component.look_at_direction(mob_mover_component.direction)
	elif point != Vector2.ZERO:
		var direction_to_target = (point - parent.global_position).normalized()
		direction_component.look_at_direction(direction_to_target)
	else:
		direction_component.look_at_direction(Vector2.RIGHT)

func _pathfinding_update():
	if point != Vector2.ZERO:
		navigation_agent.target_position = point
	
	randomize()
	pathfinding_timer.wait_time = randf_range(update_rate * 0.8, update_rate * 1.2)
	pathfinding_timer.start()

func _on_navigation_agent_velocity_computed(safe_velocity: Vector2) -> void:
	if mob_mover_component != null and safe_velocity.length_squared() > 0.1:
		mob_mover_component.direction = safe_velocity.normalized()
