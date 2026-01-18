extends "res://Scripts/Mobs/MobSystem.gd"

@export var target = null

@export var chase_player: bool = true
@export var random_speed: bool = true
@export var stop_range: int = 98

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent
@onready var player: CharacterBody2D = scene.get_node("Player")
@onready var pathfinding_update_timer: Timer = $PathfindingUpdateTimer

var target_attack_position

func _ready() -> void:
	if random_speed == true:
		max_speed = int(randf_range(max_speed * 0.8, max_speed * 1.2))
		acceleration = int(randf_range(acceleration * 0.8, acceleration * 1.2))

func _local_process(_delta):
	_enemy_logic(_delta)
	_set_target_player()
	_set_direction()
	
	if target == null or navigation_agent.is_navigation_finished() or (target.global_position - global_position).length() < stop_range:
		direction = Vector2.ZERO
		return
	
	direction = global_position.direction_to(navigation_agent.get_next_path_position())

func _enemy_logic(_delta):
	pass

func _set_target_player():
	if player == null or chase_player == false:
		return
	
	target = player

func _on_pathfinding_update_timer_timeout() -> void:
	if target == null:
		return
	
	navigation_agent.target_position = target.global_position
	
	pathfinding_update_timer.wait_time = randf_range(pathfinding_update_timer.wait_time * 0.9, pathfinding_update_timer.wait_time *1.2)
	pathfinding_update_timer.start()

func _set_direction():
	var _direction = (navigation_agent.get_next_path_position() - global_position).normalized()
	
	var _angle = _direction.angle()
	var _angle_deg = rad_to_deg(_angle)
	
	look_at_direction(_angle_deg)

func swing():
	if swinging_timer.wait_time > 0.01:
		swinging = true
		swinging_timer.start()
		
		var _direction = (target.global_position - global_position).normalized()
		target_attack_position = target.global_position
		
		lean_to_direction(-_direction, 2, 1)
	else:
		_on_swinging_timer_timeout()

func cancel_swinging():
	swinging = false
	swinging_timer.stop()

func get_swinging():
	return swinging

func _on_swinging_timer_timeout() -> void:
	if target == null:
		return
	
	swinging = false
	var _direction = (target.global_position - global_position)
	
	if _direction.length() > selected_weapon.melee_range or (target_attack_position != null and (target_attack_position-target.global_position).length() > selected_weapon.melee_range):
		_melee_attack_target(null, selected_weapon, 1, _direction.normalized() * 2)
	
	attack(_direction.normalized(), target)

func _on_navigation_agent_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
