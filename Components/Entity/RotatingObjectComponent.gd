class_name RotatingObjectComponent extends Component

@export var speed = 3

func _physics_process(delta: float) -> void:
	parent.rotation += speed * delta
