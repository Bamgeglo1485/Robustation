class_name FactionComponent extends Component

@export var faction: String

func get_faction() -> String:
	return faction

func set_faction(new_faction) -> void:
	faction = new_faction
