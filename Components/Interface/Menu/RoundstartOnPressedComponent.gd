class_name RoundstartOnPressedComponent extends Component

@export var roundstart_component: RoundstartComponent
@export var type: String

func _ready() -> void:
	if parent is not Button:
		return
	
	parent.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if !roundstart_component:
		return
	roundstart_component.start_game(type)
