class_name RoundstartOnPressedComponent extends Component

@export var roundstart_component: RoundstartComponent
@export var type: String
@export var require_double_click: bool = false
@export var double_click_time: float = 0.2

var _last_click_time: float = 0.0
var _click_count: int = 0

func _ready() -> void:
	parent.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if !roundstart_component:
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
			_execute_start()
	else:
		_execute_start()

func _execute_start() -> void:
	roundstart_component.start_game(type)
