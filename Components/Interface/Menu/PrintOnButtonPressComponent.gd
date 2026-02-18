class_name PrintOnButtonPressComponent extends Component
@export var print_frame: Control
@export_multiline var instant_text: String
@export_multiline var text: String
@export var text_double_line: bool = false
@export var delay: float = 1.0
@export var clear_text: bool = false


@onready var print_animation_component: TextPrintingAnimationComponent = print_frame.get_node_or_null("TextPrintingAnimationComponent")

func _ready() -> void:
	if parent is not Button:
		return
	
	parent.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if !print_animation_component:
		return
	
	if instant_text:
		print_frame.text += "\n\n" + instant_text
	print_animation_component.animate(text, delay, clear_text, text_double_line)
