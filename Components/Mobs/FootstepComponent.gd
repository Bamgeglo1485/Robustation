class_name FootstepComponent extends Component

@export var footstep_sound: AudioStreamPlayer2D
@export var footstep_range: int = 4096 # 64^2
var last_position: Vector2 = Vector2.ZERO

func _process(_delta: float) -> void:
	if (last_position - parent.global_position).length_squared() > footstep_range: # squared for faster calculate
		last_position = parent.global_position
		if footstep_sound:
			footstep_sound.global_position = parent.global_position
			footstep_sound.play()
