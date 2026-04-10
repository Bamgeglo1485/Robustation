class_name FootstepComponent extends Component

@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
@export var footstep_sound: AudioStreamPlayer2D
@export var footstep_range: int = 64
var last_position: Vector2 = Vector2.ZERO
var update_timer: Timer

func _ready() -> void:
	update_timer = Timer.new()
	update_timer.wait_time = 0.3
	update_timer.one_shot = true
	update_timer.timeout.connect(_update)
	add_child(update_timer)
	update_timer.start()
	footstep_range *= footstep_range

func _update() -> void:
	update_timer.start()
	if mob_mover_component and mob_mover_component.fallen or mob_mover_component.flying:
		return
	if (last_position - parent.global_position).length_squared() > footstep_range: # squared for faster calculate
		last_position = parent.global_position
		if footstep_sound:
			footstep_sound.play()
