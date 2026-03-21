class_name BossHealthBarsControllerComponent extends Component

@export var container: Container

func add_health_bar(health_bar: Control) -> void:
	if container:
		health_bar.reparent.call_deferred(container)
