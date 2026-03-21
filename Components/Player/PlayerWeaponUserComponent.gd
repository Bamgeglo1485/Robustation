class_name PlayerWeaponUserComponent extends Component

@onready var weapon_user_component: WeaponUserComponent = parent.get_node("WeaponUserComponent")

@export var weapon_1: Weapon
@export var weapon_2: Weapon
@export var weapon_3: Weapon
@export var melee_weapon: Weapon
@export var weapon_icon: TextureRect
@export var alt_weapon_icon: TextureRect
var weapon_icon_component: WeaponIconComponent
var alt_weapon_icon_component: WeaponIconComponent
var kostil: bool = true

func _ready() -> void:
	if weapon_icon:
		weapon_icon_component = weapon_icon.get_node_or_null("WeaponIconComponent")
	if alt_weapon_icon:
		alt_weapon_icon_component = alt_weapon_icon.get_node_or_null("WeaponIconComponent")

func _input(_event: InputEvent) -> void:
	if !weapon_user_component:
		return
	_weapon_input()

func _weapon_input():
	var input_weapon_1: bool = Input.is_action_just_pressed("weapon_1")
	var input_weapon_2: bool = Input.is_action_just_pressed("weapon_2")
	var input_weapon_3: bool = Input.is_action_just_pressed("weapon_3")
	var melee_attack: bool = Input.is_action_just_pressed("melee_attack")
	var melee_release_attack: bool = Input.is_action_just_released("melee_attack")
	
	if kostil:
		kostil = false
		input_weapon_1 = true
	
	var weapon_selected: bool = false
	if input_weapon_1:
		weapon_user_component.select_weapon(weapon_1)
		weapon_selected = true
	elif input_weapon_2:
		weapon_user_component.select_weapon(weapon_2)
		weapon_selected = true
	elif input_weapon_3:
		weapon_user_component.select_weapon(weapon_3)
		weapon_selected = true
	elif melee_attack:
		_attack(true, "melee_attack", melee_weapon, false)
		return
	elif melee_release_attack:
		_attack(true, "melee_attack", melee_weapon, false)
		return
	_attack(weapon_selected)


func _attack(weapon_selected: bool, attack_event: String = "attack", selected_weapon: Weapon = null, change_weapon_icon: bool = true):
	if !selected_weapon:
		selected_weapon = weapon_user_component.selected_weapon
	
	if selected_weapon and (selected_weapon.swinging or !selected_weapon.can_switch):
		return
	
	if weapon_icon and weapon_icon_component and weapon_selected and selected_weapon and change_weapon_icon:
		weapon_icon.texture = weapon_user_component.selected_weapon.icon_texture
		weapon_icon_component.weapon = selected_weapon
		weapon_icon_component._progress_bar()
		if alt_weapon_icon and alt_weapon_icon_component and selected_weapon.alt_attack:
			alt_weapon_icon.texture = weapon_user_component.selected_weapon.alt_attack.icon_texture
			alt_weapon_icon_component.weapon = weapon_user_component.selected_weapon.alt_attack
			alt_weapon_icon_component._progress_bar()
	
	if !selected_weapon:
		return
	
	var attack: bool = Input.is_action_just_pressed(attack_event)
	if selected_weapon.auto:
		attack = Input.is_action_pressed(attack_event)
	if attack:
		weapon_user_component.attack(self, false, selected_weapon)
	
	var release: bool = Input.is_action_just_released(attack_event)
	if release:
		selected_weapon.on_release(self)
	
	if !selected_weapon.alt_attack:
		return
	var alt_weapon: Weapon = selected_weapon.alt_attack
	
	var attack_alt: bool = Input.is_action_just_pressed("alt_attack")
	if alt_weapon.auto:
		attack = Input.is_action_pressed("alt_attack")
	if attack_alt:
		var current_weapon: Weapon = selected_weapon
		weapon_user_component.force_select_weapon(alt_weapon)
		weapon_user_component.attack(self, false)
		weapon_user_component.force_select_weapon(current_weapon)
	
	var release_alt: bool = Input.is_action_just_released("alt_attack")
	if release_alt:
		alt_weapon.on_release(self)

func get_attack_direction() -> Vector2:
	if !parent.has_method("get_global_mouse_position"):
		return Vector2.ZERO
	else:
		return (parent.get_global_mouse_position() - parent.global_position)
