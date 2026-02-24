class_name IngameMenuComponent extends Component

@export var menu: Control
@export var action_event: String
@export var paused_effect: ColorRect
@export var ambience: AudioStreamPlayer2D

func _ready() -> void:
	menu.visibility_changed.connect(_visibility_changed)

func _unhandled_input(_event: InputEvent) -> void:
	if !menu:
		return
	
	var toggle_action = Input.is_action_just_pressed(action_event)
	if toggle_action:
		_toggle()

func _toggle():
	menu.visible = !menu.visible

func _visibility_changed():
	get_tree().paused = menu.visible
	if paused_effect:
		paused_effect.visible = menu.visible
	if menu.visible and ambience:
		ambience.play()
	elif ambience:
		ambience.stop()
