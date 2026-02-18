class_name ToggleVisibleOnPressedComponent extends Component

@export var toggle_frame: Control

func _ready() -> void:
	if !toggle_frame:
		return
	parent.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	toggle_frame.visible = !toggle_frame.visible
