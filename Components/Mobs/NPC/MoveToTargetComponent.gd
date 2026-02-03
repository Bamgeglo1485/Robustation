class_name MoveToTargetComponent extends Component

@export var set_player_as_target: bool = true

@onready var target: CharacterBody2D
@onready var move_to_point_component: MoveToPointComponent = get_parent().get_node_or_null("MoveToPointComponent")
@onready var player: Node = scene.get_node_or_null("Player")
var direction_component: DirectionComponent

@export var priority: int = 2
@export var look_at_target: bool = true

func _ready() -> void:
	direction_component = parent.get_node_or_null("DirectionComponent")
	
func _process(_delta: float) -> void:
	if set_player_as_target and player != target:
		target = player
	
	if !target or !move_to_point_component:
		return
	
	if move_to_point_component.current_priority > priority:
		return
	
	move_to_point_component.set_point(target.global_position, priority)
	
	_look_at_target()
	
func _look_at_target() -> void:
	if !direction_component or !look_at_target:
		return
	
	var direction: Vector2 = (target.global_position - parent.global_position)
	direction_component.look_at_direction(direction)
