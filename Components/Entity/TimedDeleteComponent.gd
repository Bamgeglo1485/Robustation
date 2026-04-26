class_name TimedDeleteComponent extends Component

@export var targets: Array[Node]
@export var delay: float = 5.0
@export var hotkey: String
@export var process_always: bool = false
var deleted: bool = false

func _ready() -> void:
	await get_tree().create_timer(delay, process_always).timeout
	_delete()

func _input(event: InputEvent) -> void:
	if !hotkey:
		return
	if event.is_action_pressed(hotkey):
		_delete()

func _delete() -> void:
	if deleted:
		return
	deleted = true
	for target in targets:
		if target:
			target.queue_free()
	queue_free()
