class_name TimedEnablerComponent extends Component

@export var targets: Array[Node]
@export var delay: float = 5.0

func _ready() -> void:
	await get_tree().create_timer(delay).timeout
	for target in targets:
		target.visible = true
	queue_free()
