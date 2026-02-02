class_name PlayerWeaponUserComponent extends Component

@onready var weapon_user_component: WeaponUserComponent = parent.get_node("WeaponUserComponent")

@export var weapon_1: Weapon
@export var weapon_2: Weapon
@export var weapon_3: Weapon

func _process(_delta: float) -> void:
	if !weapon_user_component:
		return
	
	_weapon_input()

func _weapon_input():
	var input_weapon_1: bool = Input.is_action_just_pressed("weapon_1")
	var input_weapon_2: bool = Input.is_action_just_pressed("weapon_2")
	var input_weapon_3: bool = Input.is_action_just_pressed("weapon_3")
	
	if input_weapon_1:
		weapon_user_component.select_weapon(weapon_1)
	elif input_weapon_2:
		weapon_user_component.select_weapon(weapon_2)
	elif input_weapon_3:
		weapon_user_component.select_weapon(weapon_3)
	
	var attack: bool = Input.is_action_just_pressed("attack")
	if attack and weapon_user_component.selected_weapon:
		weapon_user_component.attack(self, false)

func get_attack_direction() -> Vector2:
	if !parent.has_method("get_global_mouse_position"):
		return Vector2.ZERO
	else:
		return (parent.get_global_mouse_position() - parent.global_position)
