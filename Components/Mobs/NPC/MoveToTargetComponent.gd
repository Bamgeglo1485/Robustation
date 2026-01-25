class_name MoveToTargetComponent extends Component

@export var set_player_as_target: bool = true

@onready var target: CharacterBody2D
@onready var move_to_point_component: MoveToPointComponent = get_parent().get_node_or_null("MoveToPointComponent")
var direction_component: DirectionComponent

@export var priority: int = 2
@export var look_at_target: bool = true

func _ready() -> void:
	direction_component = parent.get_node_or_null("DirectionComponent")

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if set_player_as_target == true:
		target = scene.get_node_or_null("Player")
	
	if target == null or move_to_point_component == null:
		return
	
	move_to_point_component.set_point(target.global_position, priority)
	
	_look_at_target()
	
func _look_at_target():
	if direction_component == null or look_at_target == false:
		return
	
	var direction = (target.global_position - parent.global_position)
	direction_component.look_at_direction(direction)
