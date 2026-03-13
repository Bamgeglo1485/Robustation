extends GPUParticles2D

@export var _lifetime: float = 0.5

func _ready() -> void:
	emitting = true

func _physics_process(_delta: float) -> void:
	await get_tree().create_timer(_lifetime).timeout
	queue_free()
