@tool
class_name ChangeFactionAction extends ActionLeaf

@export var faction: String = "GreyTide"
@onready var faction_comp: FactionComponent = owner.get_node_or_null("FactionComponent")

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if !faction_comp or faction_comp.faction == faction:
		return FAILURE
	
	faction_comp.faction = faction
	return SUCCESS
