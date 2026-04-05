@tool
class_name FactionCondition extends ConditionLeaf

@export var target_faction: String = "Enemy"

@onready var faction_comp: FactionComponent = owner.get_node_or_null("FactionComponent")
@onready var faction: String = faction_comp.faction

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	faction_comp.faction_changed.connect(_faction_changed)

func _faction_changed(new_faction):
	faction = new_faction

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if faction != target_faction:
		return FAILURE
	return SUCCESS
