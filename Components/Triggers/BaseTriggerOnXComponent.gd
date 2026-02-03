@abstract
class_name BaseTriggerOnXComponent extends Component

@export var key: String = "Trigger"
signal on_trigger

func trigger() -> void:
	on_trigger.emit()
