class_name RageOnTriggerComponent extends BaseXOnTriggerComponent

@onready var rage_component: RageComponent = parent.get_node_or_null("RageComponent")

func on_trigger() -> void:
	if rage_component:
		rage_component.rage()
