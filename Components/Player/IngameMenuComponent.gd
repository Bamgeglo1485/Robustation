class_name IngameMenuComponent extends Component

@export var menu: Control
@export var action_event: String
@export var paused_effect: ColorRect
@export var ambience: AudioStreamPlayer2D
var prev_pause_state: bool = false

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
	SettingsConfigSystem.paused = menu.visible

func _visibility_changed():
	if menu.visible:
		if !SettingsConfigSystem.impact_frame:
			prev_pause_state = get_tree().paused
		else:
			prev_pause_state = false
		get_tree().paused = true
		SettingsConfigSystem.paused = true
	else:
		get_tree().paused = prev_pause_state
		SettingsConfigSystem.paused = false
	if paused_effect:
		paused_effect.visible = menu.visible
	if menu.visible and ambience:
		ambience.play()
	elif ambience:
		ambience.stop()
