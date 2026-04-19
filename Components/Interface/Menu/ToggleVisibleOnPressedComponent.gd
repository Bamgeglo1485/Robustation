class_name ToggleVisibleOnPressedComponent extends Component

@export var toggle_frame: Control
@export var animation_time: float = 0.1
@export var require_double_click: bool = false
@export var double_click_time: float = 0.2

var tween: Tween
var _last_click_time: float = 0.0
var _click_count: int = 0

func _ready() -> void:
	if !toggle_frame:
		return
	parent.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if !toggle_frame:
		return
	
	if require_double_click:
		var current_time: float = Time.get_ticks_msec() / 1000.0
		
		if current_time - _last_click_time <= double_click_time:
			_click_count += 1
		else:
			_click_count = 1
		
		_last_click_time = current_time
		
		if _click_count >= 2:
			_click_count = 0
			_execute_toggle()
	else:
		_execute_toggle()

func _execute_toggle() -> void:
	if tween and tween.is_running():
		return
	
	if animation_time == 0:
		toggle_frame.visible = !toggle_frame.visible
		return
	
	if !toggle_frame.visible == true:
		toggle_frame.visible = true
		toggle_frame.scale = Vector2(0, 0)
		tween = create_tween()
		tween.tween_property(toggle_frame, "scale", Vector2(1, 1), animation_time)
	else:
		tween = create_tween()
		tween.tween_property(toggle_frame, "scale", Vector2(0, 0), animation_time)
		await tween.finished
		toggle_frame.visible = false
