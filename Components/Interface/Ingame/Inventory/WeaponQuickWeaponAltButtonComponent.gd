class_name WeaponQuickWeaponAltButtonComponent extends Component

var player_weapon_user_component: PlayerWeaponUserComponent

func _ready() -> void:
	parent.toggled.connect(_button_toggled)
	
	const max_attempts: int = 15
	var attempts: int = 0
	
	while parent is not PhysicsBody2D:
		var potential_parent: Node = parent.get_parent()
		if potential_parent:
			parent = potential_parent
		attempts += 1
		if parent is PhysicsBody2D:
			break
		if attempts > max_attempts:
			break
	if parent:
		player_weapon_user_component = parent.get_node_or_null("PlayerWeaponUserComponent")

func _button_toggled(state: bool) -> void:
	if !player_weapon_user_component:
		return
	player_weapon_user_component.melee_weapon_use_alt = state
