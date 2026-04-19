class_name MusicComponent extends Component

@export var main_music_player: AudioStreamPlayer
@export var main_music_player_staged: AudioStreamPlayer
@export var minor_music_player: AudioStreamPlayer

var main_priority: int = -1
var minor_priority: int = -1

func _ready() -> void:
	main_music_player.finished.connect(_on_main_music_end)

func set_main(new_stream: AudioStream, priority: int) -> void:
	if priority < main_priority:
		return
	
	if main_music_player.playing:
		main_music_player_staged.stream = main_music_player.stream
		main_music_player_staged.volume_db = 0
		main_music_player_staged.play(main_music_player.get_playback_position())
		
		main_music_player.stream = new_stream
		main_music_player.volume_db = -40
		main_music_player.play(main_music_player_staged.get_playback_position())
		
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(main_music_player_staged, "volume_db", -40, 2.0)
		tween.tween_property(main_music_player, "volume_db", 0, 1.0)
		
		await tween.finished
		
		main_music_player_staged.stop()
		main_music_player_staged.stream = null
	else:
		main_music_player.stream = new_stream
		main_music_player.volume_db = 0
		main_music_player.play()
	
	main_priority = priority

func reset_main():
		var tween: Tween = create_tween()
		tween.tween_property(main_music_player, "volume_db", -40, 1.0)
		
		await tween.finished
		
		main_music_player.stop()
		main_music_player.stream = null
		main_priority = -1

func _on_main_music_end():
	main_priority = -1
