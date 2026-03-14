extends GPUParticles2D

@export var max_clean_health = 3
@export var clean_health = max_clean_health
@export var do_not_delete: bool = false
func _ready() -> void:
	visible = true
	emitting = true
	
	var clean_delay: float = SettingsConfigSystem.blood_clean_delay
	if clean_delay == 0:
		return
	
	if do_not_delete:
		return
	await get_tree().create_timer(clean_delay - 5).timeout
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate", Color(0.0, 0.0, 1.0, 0.0), 5)
	await get_tree().create_timer(5).timeout
	queue_free()

func is_blood():
	return true

func _on_pause_timer_timeout():
	self.speed_scale = 0
