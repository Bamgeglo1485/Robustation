@abstract
class_name BaseTriggerOnXComponent extends Component

@export var key: String = "Trigger"
var connected_xontriggers: Array[BaseXOnTriggerComponent]
signal on_trigger

func trigger() -> void:
	on_trigger.emit()
