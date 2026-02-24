class_name SoundsOnInputComponent extends Component

@export var keyboard_audio_player: AudioStreamPlayer2D
@export var mouse_audio_player: AudioStreamPlayer2D

func _unhandled_input(event):
	if !parent.visible:
		return
	if event is InputEventKey:
		if event.pressed or event.as_text_key_label():
			if keyboard_audio_player:
				keyboard_audio_player.play()

func _input(event):
	if !parent.visible:
		return
	if event is InputEventMouseButton:
		if mouse_audio_player and event.pressed:
			mouse_audio_player.play()
