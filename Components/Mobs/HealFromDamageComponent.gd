class_name HealFromDamageComponent extends Component

@export var radius: int = 96
@export var heal_multipliers: Dictionary
@export var heal_multiplier: float = 0.0
@export var heal_addendums: Dictionary
@export var heal_addendum: float = 0.0

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")

func _ready() -> void:
	radius *= radius
	EventBusManager.damaged.connect(_on_damaged)

func _on_damaged(emitter: Node2D, taked_damage: float, damager: Node2D) -> void:
	if (heal_multiplier + heal_addendum) * heal_multiplier == 0:
		return
	if damager != parent or emitter == parent or taked_damage <= 0:
		return
	
	if (damager.global_position-emitter.global_position).length_squared() > radius:
		return
	
	health_component.take_damage(taked_damage * heal_multiplier - taked_damage, null, "Heal", true)
