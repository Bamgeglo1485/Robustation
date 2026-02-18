class_name PlayerCamera extends Camera2D

@export var offset_modifier: int = 15
@onready var parent: Node = get_parent()
@onready var direction_component: DirectionComponent = get_direction_component()

var config = ConfigFile.new()

func _ready() -> void:
	var err = config.load("user://settings.cfg")
	if err != OK:
		return
	
	var fov = config.get_value("VISUAL", "FOV")
	
	zoom *= fov/100

func _notification(notif):
	if notif == NOTIFICATION_PARENTED:
		parent = get_parent()
		direction_component = get_direction_component()

func get_direction_component() -> Node:
	return parent.get_node("DirectionComponent")
	
func _process(_delta: float) -> void:
	_set_camera_offset()
	_look_at_cursor()

func _set_camera_offset():
	var _mouse_position: Vector2 = get_global_mouse_position()
	var _mouse_offset = _mouse_position - parent.global_position
	
	var _normalized_offset: Vector2 = Vector2(
		_mouse_offset.x / (offset_modifier),
		_mouse_offset.y / (offset_modifier))
	
	offset = _normalized_offset

func _look_at_cursor() -> void:
	if !parent.has_node("DirectionComponent"):
		return
	
	var mouse_position: Vector2 = get_global_mouse_position()
	var direction: Vector2 = (mouse_position - global_position).normalized()
	
	direction_component.look_at_direction(direction)
