extends GPUParticles2D

var deleting = false
var _lifetime: float = 4

func _physics_process(_delta: float) -> void:
	_lifetime -= _delta
	if _lifetime <= 0:
		queue_free()

func _on_delete_timeout() -> void:
	self.emitting = false
	deleting = true
