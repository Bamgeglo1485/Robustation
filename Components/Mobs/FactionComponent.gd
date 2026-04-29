class_name FactionComponent extends Component

@export var faction: StringName : set = set_faction
signal faction_changed(new_faction: StringName)

func get_faction() -> StringName:
	return faction

func set_faction(new_faction: StringName) -> void:
	faction = new_faction
	faction_changed.emit(new_faction)
