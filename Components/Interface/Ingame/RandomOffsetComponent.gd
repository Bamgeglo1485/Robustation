class_name RandomOffsetComponent extends Component

@export var min_offset: int = -64
@export var max_offset: int = 64
@export var min_scale: float = 1.5
@export var max_scale: float = 0.4
@export var update_rate: float = 0.1

@onready var grandparent: Node = parent.get_parent()
var base_position: Vector2
var timer: Timer

func _ready() -> void:
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = update_rate
	timer.timeout.connect(_update)
	add_child(timer)
	timer.start()
	
	base_position = parent.position

func _update() -> void:
	timer.start()
	if !parent.visible or !grandparent.visible:
		return
	
	if min_offset != max_offset:
		var random_x_position: int = randi_range(min_offset, max_offset)
		var random_y_position: int = randi_range(min_offset, max_offset)
		parent.position = base_position + Vector2(random_x_position, random_y_position)
	
	var random_x_scale: float = randf_range(min_scale, max_scale)
	var random_y_scale: float = randf_range(min_scale, max_scale)
	parent.scale = Vector2(random_x_scale, random_y_scale)
