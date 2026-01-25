class_name ChangeWeaponOnRageComponent extends Component

@export var weapon: Weapon

func _ready() -> void:
	if weapon == null:
		return
	var rage_component = parent.get_node_or_null("RageComponent")
	if rage_component == null:
		return
	EventBusManager.raged.connect(on_raged)

func on_raged(emitter):
	if emitter == parent:
		var weapon_user_component = parent.get_node_or_null("WeaponUserComponent")
		if weapon_user_component == null:
			return
		weapon_user_component.selected_weapon = weapon
