class_name FootstepComponent extends Component

@export var footstep_sound: AudioStreamPlayer2D
@export var footstep_range: int = 4096 # 64^2
var last_position: Vector2 = Vector2.ZERO
var update_timer: Timer

func _ready() -> void:
	update_timer = Timer.new()
	add_child(update_timer)
	update_timer.wait_time = 0.2
	update_timer.one_shot = true
	update_timer.start()
	update_timer.timeout.connect(_update)

func _update() -> void:
	update_timer.start()
	if (last_position - parent.global_position).length_squared() > footstep_range: # squared for faster calculate
		last_position = parent.global_position
		if footstep_sound:
			footstep_sound.play()
