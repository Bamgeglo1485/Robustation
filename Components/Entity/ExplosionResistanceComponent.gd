class_name ExplosionResistanceComponent extends Component

@export var resistance: float = 1.0 : get = get_resisitance

@export var resistance_multipliers: Dictionary
@export var resistance_multiplier: float = 1.0
@export var explosion_multipliers: Dictionary
@export var explosion_multiplier: float = 1.0

func _ready() -> void:
	EventBusManager.explosion.connect(_on_explosion)

func _on_explosion(explosion: Node2D):
	if explosion_multiplier == 1.0:
		return
	explosion.damage *= explosion_multiplier
	explosion.set_radius(explosion.radius * explosion_multiplier)

func get_resisitance() -> float:
	return resistance * resistance_multiplier
