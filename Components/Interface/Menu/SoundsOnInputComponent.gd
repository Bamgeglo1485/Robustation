class_name SoundsOnInputComponent extends Component

@export var keyboard_audio_player: AudioStreamPlayer2D
@export var mouse_audio_player: AudioStreamPlayer2D

func _input(event):
	if !parent.visible:
		return
		
	if event is InputEventMouseButton:
		if mouse_audio_player and event.pressed:
			mouse_audio_player.play()
			
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if keyboard_audio_player:
				keyboard_audio_player.play()
