class_name PrintOnButtonPressComponent extends Component

@export var print_frame: Control
@export_multiline var instant_text: String
@export_multiline var text: String
@export var text_double_line: bool = false
@export var delay: float = 1.0
@export var clear_text: bool = false
@export var require_double_click: bool = false
@export var double_click_time: float = 0.2

@onready var print_animation_component: TextPrintingAnimationComponent = print_frame.get_node_or_null("TextPrintingAnimationComponent")

var _last_click_time: float = 0.0
var _click_count: int = 0

func _ready() -> void:
	parent.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if require_double_click:
		var current_time: float = Time.get_ticks_msec() / 1000.0
		
		if current_time - _last_click_time <= double_click_time:
			_click_count += 1
		else:
			_click_count = 1
		
		_last_click_time = current_time
		
		if _click_count >= 2:
			_click_count = 0
			_execute_print()
	else:
		_execute_print()

func _execute_print() -> void:
	if !print_animation_component:
		return
	
	if instant_text:
		print_frame.text += "\n\n" + instant_text
	print_animation_component.animate(text, delay, clear_text, text_double_line)
