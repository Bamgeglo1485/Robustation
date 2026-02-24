class_name PlayerWeaponUserComponent extends Component

@onready var weapon_user_component: WeaponUserComponent = parent.get_node("WeaponUserComponent")

@export var weapon_1: Weapon
@export var weapon_2: Weapon
@export var weapon_3: Weapon
@export var weapon_icon: TextureRect
var weapon_icon_component: WeaponIconComponent

func _ready() -> void:
	if weapon_icon:
		weapon_icon_component = weapon_icon.get_node_or_null("WeaponIconComponent")

func _input(_event: InputEvent) -> void:
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
	
	var selected_weapon: Weapon = weapon_user_component.selected_weapon
	
	if weapon_icon and weapon_icon_component and (input_weapon_1 or input_weapon_2 or input_weapon_3) and selected_weapon:
		weapon_icon.texture = weapon_user_component.selected_weapon.icon_texture
		weapon_icon_component.weapon = selected_weapon
		weapon_icon_component._progress_bar()
	
	var attack: bool = Input.is_action_just_pressed("attack")
	if attack and weapon_user_component.selected_weapon:
		weapon_user_component.attack(self, false)

func get_attack_direction() -> Vector2:
	if !parent.has_method("get_global_mouse_position"):
		return Vector2.ZERO
	else:
		return (parent.get_global_mouse_position() - parent.global_position)
