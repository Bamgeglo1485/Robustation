class_name PlayerCamera extends Camera2D

@export var offset_modifier: int = 15
@export var default_fov: float = 100.0

@onready var parent: Node = get_parent()
@onready var direction_component: DirectionComponent = get_direction_component()

var base_zoom: Vector2
var config = ConfigFile.new()

func _ready() -> void:
	base_zoom = zoom
	
	var err = config.load("user://settings.cfg")
	var fov = default_fov
	
	if err == OK and config.has_section_key("VISUAL", "FOV"):
		fov = config.get_value("VISUAL", "FOV")
	
	zoom = base_zoom * (fov / 100.0)
	EventBusManager.field_of_view_changed.connect(_field_of_view_changed)

func _field_of_view_changed(value: float) -> void:
	zoom = base_zoom * (value / 100.0)

func _notification(notif: int) -> void:
	if notif == NOTIFICATION_PARENTED:
		parent = get_parent()
		direction_component = get_direction_component()

func get_direction_component() -> Node:
	return parent.get_node("DirectionComponent") if parent.has_node("DirectionComponent") else null
	
func _physics_process(_delta: float) -> void:
	_set_camera_offset()
	_look_at_cursor()

func _set_camera_offset() -> void:
	var mouse_position: Vector2 = get_global_mouse_position()
	var mouse_offset = mouse_position - parent.global_position
	
	var normalized_offset: Vector2 = Vector2(
		mouse_offset.x / offset_modifier,
		mouse_offset.y / offset_modifier)
	
	offset = normalized_offset

func _look_at_cursor() -> void:
	if direction_component == null:
		return
	
	var mouse_position: Vector2 = get_global_mouse_position()
	var direction: Vector2 = (mouse_position - global_position).normalized()
	
	direction_component.look_at_direction(direction)
