class_name InputMoverComponent extends Component

@onready var mob_mover_component: MobMoverComponent = parent.get_node("MobMoverComponent")

func _process(_delta: float) -> void:
	if mob_mover_component:
		_set_movement_input()
		
func _set_movement_input() -> void:
	mob_mover_component.direction = Input.get_vector("movement_left","movement_right", "movement_up", "movement_down")
