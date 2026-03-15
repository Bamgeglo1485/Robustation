class_name TimedSceneAdderComponent extends Component

@export var targets: Array[PackedScene]
@export var target_parent: Node
@export var delay: float = 5
@export var parent_of_target: bool = false
@export var hotkey: String
var spawned: bool = false

func _input(event: InputEvent) -> void:
	if !hotkey:
		return
	if event.is_action_pressed(hotkey):
		_spawn()

func _ready() -> void:
	await get_tree().create_timer(delay).timeout
	_spawn()

func _spawn() -> void:
	if spawned:
		return
	spawned = true
	for target in targets:
		var _inst = target.instantiate()
		if target_parent:
			if !parent_of_target:
				target_parent.add_child.call_deferred(_inst)
			else:
				target_parent.get_parent().add_child.call_deferred(_inst)
	queue_free()
