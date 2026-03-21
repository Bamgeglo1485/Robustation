class_name RotatingObjectComponent extends Component

@export var speed = 3
@onready var grandparent: Node = parent.get_parent()

func _physics_process(delta: float) -> void:
	if !parent.visible or !grandparent.visible:
		return
	parent.rotation += speed * delta
