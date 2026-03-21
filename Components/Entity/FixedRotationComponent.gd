class_name FixedRotationComponent extends Component

@onready var parents_parent: Node = parent.get_parent()
@onready var offset = parent.position

func _physics_process(delta: float) -> void:
	parent.position = parents_parent.position + offset
