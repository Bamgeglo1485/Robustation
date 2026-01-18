extends AudioStreamPlayer

var current_priority: int = 0
var current_timed: bool = false
var queue_stream: AudioStream
var queue_priority: int

func _ready() -> void:
	max_polyphony = 3

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if playing == false and queue_stream != null:
		set_music(queue_stream, queue_priority)

func set_music(new_stream, priority = 1, timed = false):
	if timed == true and current_timed != true and stream != null:
		queue_stream = stream
		queue_priority = priority
	
	set_stream(new_stream)
	
	current_priority = priority
	current_timed = timed
	
	play()

func clear_musics():
	stop()
	current_priority = 0
	stream = null
