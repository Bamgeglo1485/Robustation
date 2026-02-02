class_name RandomizeMobMoverComponent extends Component

@export var max_speed: int = 0
@export var min_speed: int = 0
@export var max_acceleration: int = 0
@export var min_acceleration: int = 0

@export var randomize_multiplier_min: float = 0
@export var randomize_multiplier_max: float = 0

@onready var mob_mover_component: MobMoverComponent = parent.get_node("MobMoverComponent")

func _ready() -> void:
	if !mob_mover_component:
		return
	
	if max_speed != 0 and min_speed != 0:
		mob_mover_component.max_speed = randi_range(min_speed, max_speed)
	if max_acceleration != 0 and min_acceleration != 0:
		mob_mover_component.acceleration = randi_range(min_acceleration, max_acceleration)
	if randomize_multiplier_max != 0 and randomize_multiplier_min != 0:
		randomize()
		var multiplier: float = randf_range(randomize_multiplier_min, randomize_multiplier_max)
	
		mob_mover_component.acceleration *= multiplier
		mob_mover_component.max_speed *= multiplier
