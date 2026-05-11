class_name HealFromParryComponent extends Component

@export var heal_multipliers: Dictionary
@export var heal_multiplier: float = 0.0
@export var heal_addendums: Dictionary
@export var heal_addendum: float = 0.0

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")

func _ready() -> void:
	EventBusManager.parry.connect(_on_parry)

func _on_parry(emitter: Node2D, type: String, enemy: bool) -> void:
	if (heal_multiplier + heal_addendum) * heal_multiplier == 0:
		return
	if type != "Projectile" or !enemy or emitter != parent:
		return
	health_component.take_damage(health_component.health * heal_multiplier - health_component.health, null, "Heal", true)
