class_name DragButtonComponent extends Component

@export var frame_to_drag: Control
@export var margin: int = 10

var dragging: bool = false
var offset: Vector2 = Vector2.ZERO
var last_pressed: bool = false
var viewport_rect: Rect2

func _ready() -> void:
	viewport_rect = get_viewport().get_visible_rect()

func _process(_delta: float) -> void:
	viewport_rect = get_viewport().get_visible_rect()
	
	if !parent.button_pressed or !frame_to_drag:
		last_pressed = parent.button_pressed
		return
	
	if !last_pressed and parent.button_pressed:
		offset = frame_to_drag.global_position - parent.get_global_mouse_position()
		dragging = true
	elif dragging:
		var new_position: Vector2 = parent.get_global_mouse_position() + offset
		
		new_position = _clamp_position(new_position)
		frame_to_drag.global_position = new_position
	
	if last_pressed and !parent.button_pressed:
		dragging = false
		offset = Vector2.ZERO
	
	last_pressed = parent.button_pressed

func _clamp_position(position: Vector2) -> Vector2:
	var clamped_position: Vector2 = position
	var frame_size: Vector2 = frame_to_drag.size
	
	clamped_position.x = clamp(
		position.x,
		viewport_rect.position.x + margin,
		viewport_rect.position.x + viewport_rect.size.x - frame_size.x - margin
	)
	
	clamped_position.y = clamp(
		position.y,
		viewport_rect.position.y + margin,
		viewport_rect.position.y + viewport_rect.size.y - frame_size.y - margin
	)
	
	return clamped_position
