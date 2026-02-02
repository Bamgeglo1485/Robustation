class_name ChangeWeaponOnRageComponent extends Component

@export var weapon: Weapon

func _ready() -> void:
	if !weapon:
		return
	var rage_component: RageComponent = parent.get_node_or_null("RageComponent")
	if !rage_component:
		return
	EventBusManager.raged.connect(on_raged)

func on_raged(emitter) -> void:
	if emitter == parent:
		var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")
		if !weapon_user_component:
			return
		weapon_user_component.selected_weapon = weapon
