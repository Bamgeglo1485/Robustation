@abstract
class_name BaseXOnTriggerComponent extends Component

@export var key: String = "Trigger"

func _init() -> void:
	await tree_entered
	for child in parent.get_children():
		if child is BaseTriggerOnXComponent and child.key == key:
			child.on_trigger.connect(on_trigger)
			child.connected_xontriggers.append(self)

func on_trigger():
	pass
