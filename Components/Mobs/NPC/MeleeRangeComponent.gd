class_name MeleeRangeComponent extends Component

@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")
@onready var move_to_point_component: MoveToPointComponent = get_parent().get_node_or_null("MoveToPointComponent")
@onready var attack_target_component: AttackTargetComponent = get_parent().get_node_or_null("AttackTargetComponent")

@export var set_alt_weapon_when_cooldown: bool = true
@export var set_weapon_logic: bool = true
@export var melee_weapons: Array[MeleeWeapon]
@export var range_weapons: Array[RangeWeapon]
@export var range_weapon_distance: int = 64
@export var update_rate: float = 1

var update_timer: Timer

func _ready() -> void:
	update_timer = Timer.new()
	add_child(update_timer)
	update_timer.one_shot = true
	update_timer.wait_time = update_rate
	update_timer.timeout.connect(_update)
	update_timer.start()

func _update() -> void:
	update_timer.wait_time = update_rate * randf_range(0.8, 1.2)
	update_timer.start()
	
	if !weapon_user_component or !attack_target_component:
		return
	
	if !attack_target_component.target:
		return
	
	var distance: float = (attack_target_component.target.global_position - parent.global_position).length()
	if distance < range_weapon_distance and weapon_user_component.selected_weapon is MeleeWeapon:
		return
	elif weapon_user_component.selected_weapon is RangeWeapon:
		weapon_user_component.selected_weapon = _pick_weapon(melee_weapons)
		if weapon_user_component.selected_weapon.cooldown and set_alt_weapon_when_cooldown:
			weapon_user_component.selected_weapon = _pick_weapon(range_weapons)
	else:
		weapon_user_component.selected_weapon = _pick_weapon(range_weapons)
		if weapon_user_component.selected_weapon is RangeWeapon and weapon_user_component.selected_weapon.bullets == 0 and set_alt_weapon_when_cooldown:
			weapon_user_component.selected_weapon = _pick_weapon(melee_weapons)
	
	if move_to_point_component and set_weapon_logic:
		if weapon_user_component.selected_weapon is MeleeWeapon:
			move_to_point_component.run_from_target_range = 16
			move_to_point_component.run_to_target_range = 1000
		else:
			move_to_point_component.run_from_target_range = 200
			move_to_point_component.run_to_target_range = 150

func _pick_weapon(weapons: Array) -> Weapon:
	if weapons.is_empty() or weapons.size() == 1:
		return weapons[0]
	
	var valid_weapons: Array[Weapon]
	for weapon in weapons:
		if !weapon.can_attack or weapon.cooldown:
			continue
		
		valid_weapons.append(weapon)
	
	if valid_weapons.is_empty() or valid_weapons.size() == 1:
		return valid_weapons[0]
	
	return valid_weapons.pick_random()
