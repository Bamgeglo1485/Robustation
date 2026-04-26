class_name DragButtonComponent extends Component

@export var frame_to_drag: Control
@export var margin: int = 10
@export var use_parent_corners: bool = false
@export var parent_bounds_control: Control

var dragging: bool = false
var offset: Vector2 = Vector2.ZERO
var last_pressed: bool = false
var viewport_rect: Rect2

func _input(_event: InputEvent) -> void:
	if !parent.visible:
		return
	
	viewport_rect = get_viewport().get_visible_rect()
	
	if !parent.button_pressed or !frame_to_drag:
		last_pressed = parent.button_pressed
		return
	
	if !last_pressed and parent.button_pressed:
		offset = frame_to_drag.position - parent.get_global_mouse_position()
		dragging = true
	elif dragging:
		var new_position: Vector2 = parent.get_global_mouse_position() + offset
		new_position = _clamp_position(new_position)
		frame_to_drag.position = new_position
	
	if last_pressed and !parent.button_pressed:
		dragging = false
		offset = Vector2.ZERO
	
	last_pressed = parent.button_pressed

func _clamp_position(position: Vector2) -> Vector2:
	var bounds: Rect2
	
	if use_parent_corners:
		var bounds_control: Control = parent_bounds_control if parent_bounds_control else frame_to_drag.get_parent()
		
		if bounds_control and bounds_control is Control:
			var parent_global_rect: Rect2 = bounds_control.get_global_rect()
			
			bounds = Rect2(
				parent_global_rect.position.x + margin,
				parent_global_rect.position.y + margin,
				parent_global_rect.size.x - frame_to_drag.size.x - margin * 2,
				parent_global_rect.size.y - frame_to_drag.size.y - margin * 2
			)
		else:
			bounds = _get_viewport_bounds()
	else:
		bounds = _get_viewport_bounds()
	
	bounds.size.x = max(0, bounds.size.x)
	bounds.size.y = max(0, bounds.size.y)
	
	return Vector2(
		clamp(position.x, bounds.position.x, bounds.position.x + bounds.size.x),
		clamp(position.y, bounds.position.y, bounds.position.y + bounds.size.y)
	)

func _get_viewport_bounds() -> Rect2:
	return Rect2(
		viewport_rect.position.x + margin,
		viewport_rect.position.y + margin,
		viewport_rect.size.x - frame_to_drag.size.x - margin * 2,
		viewport_rect.size.y - frame_to_drag.size.y - margin * 2
	)
