class_name RandomWeaponSelectorComponent extends Component

@export var weapons_to_select: Array[Weapon]
@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")

func _ready() -> void:
	if !weapon_user_component or weapons_to_select.is_empty():
		return
	
	randomize()
	weapon_user_component.select_weapon(weapons_to_select.pick_random())
