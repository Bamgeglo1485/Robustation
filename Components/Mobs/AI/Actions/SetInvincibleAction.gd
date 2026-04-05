@tool
class_name SetInvincibleAction extends ActionLeaf

@onready var health: HealthComponent = owner.get_node_or_null("HealthComponent")
@export var state: bool = false

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if !health or health.INVINCIBLE == state:
		return FAILURE
	health.INVINCIBLE = state
	return SUCCESS
