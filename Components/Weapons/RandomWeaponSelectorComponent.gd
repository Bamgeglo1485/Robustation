class_name RandomWeaponSelectorComponent extends Component

@export var weapons_to_select: Array[Weapon]
@export var change_behavior: bool = false
@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")

func _ready() -> void:
	if weapon_user_component == null or weapons_to_select.is_empty():
		return
	
	weapon_user_component.select_weapon(weapons_to_select.pick_random())
	
	if change_behavior == false:
		return
	
	var move_to_point_component = parent.get_node_or_null("MoveToPointComponent")
	if move_to_point_component == null:
		var ai_folder = parent.get_node_or_null("AI")
		move_to_point_component = ai_folder.get_node_or_null("MoveToPointComponent")
		if move_to_point_component == null:
			return
	
	if weapon_user_component.selected_weapon is MeleeWeapon:
		move_to_point_component.run_from_target_range = 16
		move_to_point_component.run_to_target_range = 1000
	else:
		move_to_point_component.run_from_target_range = 130
		move_to_point_component.run_to_target_range = 250
