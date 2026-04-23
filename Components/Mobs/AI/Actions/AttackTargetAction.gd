@tool
class_name AttackTargetAction extends ActionLeaf

@onready var weapon_user_component: WeaponUserComponent = owner.get_node_or_null("WeaponUserComponent")
var blackboard: Blackboard
@export var key: String = "Target"
@export var weapon: Weapon

@export var prediction_coef: float = 0.8

var out_of_ammo: bool = false

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if !blackboard:
		blackboard = _blackboard
	if !weapon_user_component or !owner:
		return FAILURE
	var target = blackboard.get_value(key)
	if !target:
		return FAILURE
	
	if weapon:
		weapon_user_component.selected_weapon = weapon
	if !weapon_user_component.selected_weapon:
		return FAILURE
	
	if weapon_user_component.selected_weapon is MeleeWeapon:
		if (blackboard.get_value(key).global_position - owner.global_position).length() > weapon_user_component.selected_weapon.attack_range * 1.25:
			return FAILURE
	elif weapon_user_component.selected_weapon is RangeWeapon:
		if weapon_user_component.selected_weapon.bullets == 0:
			if out_of_ammo:
				return FAILURE
			weapon_user_component.attack(self)
			out_of_ammo = true
			return FAILURE
		else:
			out_of_ammo = false
		
	var result: bool = weapon_user_component.attack(self)
	
	if result:
		return SUCCESS
	else:
		return FAILURE

func get_attack_direction() -> Vector2:
	var target: Node2D = blackboard.get_value(key)
	if !target:
		return Vector2.ZERO
	
	var target_pos: Vector2 = target.global_position
	var to_target: Vector2 = target_pos - owner.global_position
	
	if weapon_user_component.selected_weapon is not RangeWeapon:
		return to_target
	
	var _weapon = weapon_user_component.selected_weapon
	if !_weapon or prediction_coef == 0 or target is not CharacterBody2D:
		return to_target
	
	var time_to_target: float = to_target.length() / _weapon.projectile_speed * prediction_coef
	var predicted_pos: Vector2 = target_pos + target.velocity * time_to_target
	
	return owner.global_position.direction_to(predicted_pos)

func get_attack_target() -> PhysicsBody2D:
	return blackboard.get_value(key)
