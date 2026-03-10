class_name MoveToTargetComponent extends Component

@export var set_player_as_target: bool = true

@onready var target: CharacterBody2D
@onready var move_to_point_component: MoveToPointComponent = get_parent().get_node_or_null("MoveToPointComponent")
@onready var player: Node = scene.get_node_or_null("Player")
var direction_component: DirectionComponent

@export var priority: int = 2
@export var look_at_target: bool = true

@export var look_at_target_update_rate: float = 0.3
var look_at_target_update_timer: Timer

func _ready() -> void:
	direction_component = parent.get_node_or_null("DirectionComponent")
	look_at_target_update_timer = Timer.new()
	add_child(look_at_target_update_timer)
	look_at_target_update_timer.one_shot = true
	look_at_target_update_timer.wait_time = look_at_target_update_rate
	look_at_target_update_timer.timeout.connect(_look_at_target)
	look_at_target_update_timer.start()
	
	if set_player_as_target:
		EventBusManager.change_player.connect(_player_changed)

func _process(_delta: float) -> void:
	if set_player_as_target and player != target:
		target = player
	
	if !target or !move_to_point_component:
		return
	
	if move_to_point_component.current_priority > priority:
		return
	
	move_to_point_component.set_point(target.global_position, priority)
	
func _look_at_target() -> void:
	if !target or !direction_component or !look_at_target:
		return
	
	look_at_target_update_timer.start()
	
	var direction: Vector2 = (target.global_position - parent.global_position)
	direction_component.look_at_direction(direction)

func _player_changed(new_player, wait_time) -> void:
	if wait_time > 0:
		await get_tree().create_timer(wait_time).timeout
	player = new_player
	target = new_player
