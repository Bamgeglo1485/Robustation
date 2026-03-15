class_name TimedEnablerComponent extends Component

@export var targets: Array[Node]
@export var delay: float = 5.0
@export var hotkey: String
var enabled: bool = false

func _ready() -> void:
	await get_tree().create_timer(delay).timeout
	_enable()

func _input(event: InputEvent) -> void:
	if !hotkey:
		return
	if event.is_action_pressed(hotkey):
		_enable()

func _enable() -> void:
	if enabled:
		return
	enabled = true
	for target in targets:
		if target:
			target.visible = !target.visible
	queue_free()
