class_name SoundOnPressedComponent extends Component

@export var audio: AudioStreamPlayer

func _ready() -> void:
	parent.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	audio.play()
