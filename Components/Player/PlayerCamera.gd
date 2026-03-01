class_name PlayerCamera extends Camera2D

@export var offset_modifier: int = 15
@export var default_fov: float = 100.0
@export var flashlight: PointLight2D

@onready var parent: Node = get_parent()
@onready var direction_component: DirectionComponent = get_direction_component()

@export var flashlight_min_scale: float = 0.15
@export var flashlight_max_scale: float = 3.0

@export var flashlight_off: AudioStreamPlayer2D
@export var flashlight_on: AudioStreamPlayer2D

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
	var mouse_position: Vector2 = get_global_mouse_position()
	var mouse_offset: Vector2 = mouse_position - parent.global_position
	
	var normalized_offset: Vector2 = Vector2(
		mouse_offset.x / offset_modifier,
		mouse_offset.y / offset_modifier)
	
	offset = normalized_offset
	
	if direction_component == null:
		return
	
	var direction: Vector2 = (mouse_position - global_position)
	direction_component.look_at_direction(direction)
	
	if flashlight and flashlight.energy != 0:
		var cone_scale: float = clamp(direction.length() / 170, flashlight_min_scale, flashlight_max_scale)
		flashlight.scale = Vector2(cone_scale, cone_scale / 2)
		flashlight.global_rotation = direction.angle()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_flashlight") and flashlight:
		if flashlight.energy == 0:
			flashlight.energy = 15
			if flashlight_on:
				flashlight_on.play()
		else:
			flashlight.energy = 0
			if flashlight_off:
				flashlight_off.play()
