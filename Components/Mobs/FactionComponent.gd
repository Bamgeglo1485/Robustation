class_name FactionComponent extends Component

@export var faction: String : set = set_faction
signal faction_changed(new_faction: String)

func get_faction() -> String:
	return faction

func set_faction(new_faction: String) -> void:
	faction = new_faction
	faction_changed.emit(new_faction)
