@tool
class_name LookAtDirectionAction extends ActionLeaf

@onready var direction_component: DirectionComponent = owner.get_node_or_null("DirectionComponent")
var blackboard: Blackboard
@export var key: String
@export var update_delay: float = 0.4
var update_timer: Timer

func _ready() -> void:
	update_timer = Timer.new()
	update_timer.autostart = true
	update_timer.one_shot = true
	update_timer.wait_time = update_delay
	update_timer.timeout.connect(_update)
	add_child(update_timer)

func _update() -> void:
	update_timer.wait_time = update_delay * randf_range(0.7, 1.3)
	update_timer.start()
	if !blackboard:
		return
	var point = blackboard.get_value(key)
	if !direction_component or !point or !owner:
		return
	direction_component.look_at_direction(point - owner.global_position)

func tick(actor: Node, _blackboard: Blackboard) -> int:
	if !direction_component:
		return FAILURE
	blackboard = _blackboard
	if !blackboard.get_value(key) or !actor:
		return FAILURE
	return SUCCESS
