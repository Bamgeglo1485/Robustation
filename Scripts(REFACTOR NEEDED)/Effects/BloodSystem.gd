extends GPUParticles2D

@export var max_clean_health = 3
@export var clean_health = max_clean_health

func is_blood():
	return true

func _on_pause_timer_timeout():
	self.speed_scale = 0
