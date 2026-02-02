extends AudioStreamPlayer

var current_priority: int = 0
var current_timed: bool = false
var queue_stream: AudioStream
var queue_priority: int

func _ready() -> void:
	max_polyphony = 3
	
func _process(_delta: float) -> void:
	if !playing and queue_stream:
		set_music(queue_stream, queue_priority)

func set_music(new_stream, priority = 1, timed = false) -> void:
	if timed and !current_timed and stream:
		queue_stream = stream
		queue_priority = priority
	
	set_stream(new_stream)
	
	current_priority = priority
	current_timed = timed
	
	play()

func clear_musics() -> void:
	stop()
	current_priority = 0
	stream = null
