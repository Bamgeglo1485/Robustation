class_name TimedSceneAdderComponent extends Component

@export var targets: Array[PackedScene]
@export var target_parent: Node
@export var delay: float = 5

func _ready() -> void:
	await get_tree().create_timer(delay).timeout
	for target in targets:
		var _inst = target.instantiate()
		if target_parent:
			target_parent.add_child.call_deferred(_inst)
	queue_free()
