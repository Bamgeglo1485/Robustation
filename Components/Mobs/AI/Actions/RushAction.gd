@tool
class_name RushAction extends ActionLeaf

var blackboard: Blackboard
@export var key: String

@export var damage_area2d: Area2D
@export var rush_delay: float = 0.4
@export var stamina_damage_after_wall_hit: float = 100
@export var rush_weapon: MeleeWeapon
@export var weapon_sprite: WeaponSpriteComponent
@export var fall_delay_after_wall_hit: float = 2
@export var delay_before_rush: float = 0.4
@export var fall_after_rush_delay: float = 0.3

@export var rush_sound: AudioStreamPlayer2D
@export var rush_prepare_sound: AudioStreamPlayer2D

@export var throw_speed: float = 500
@export var throw_stop_speed: float = 300

@export var rush_combo: int = 1
var combos: int = 0

@onready var weapon_user_component: WeaponUserComponent = owner.get_node_or_null("WeaponUserComponent")
@onready var direction_component: DirectionComponent = owner.get_node_or_null("DirectionComponent")
@onready var stamina_component: StaminaComponent = owner.get_node_or_null("StaminaComponent")
@onready var mob_mover_component: MobMoverComponent = owner.get_node_or_null("MobMoverComponent")

var preparing_to_rush: bool = false
var rushing: bool = false

func _ready() -> void:
	if damage_area2d:
		damage_area2d.body_entered.connect(_on_body_entered)

func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if rushing or !mob_mover_component or mob_mover_component.movement_blocked:
		return FAILURE
	if !blackboard:
		blackboard = _blackboard
	if !rush_weapon or rush_weapon.cooldown:
		return FAILURE
	var target = blackboard.get_value(key)
	if !target:
		return FAILURE
	
	rush()
	
	return SUCCESS

func rush() -> void:
	if rushing or preparing_to_rush or mob_mover_component.fallen:
		return
	weapon_user_component.select_weapon(rush_weapon)
	mob_mover_component.movement_blocked = true
	preparing_to_rush = true
	if weapon_sprite:
		weapon_sprite.flip_hell_yeah()
	if rush_prepare_sound:
		rush_prepare_sound.play()
	await get_tree().create_timer(delay_before_rush).timeout
	if mob_mover_component.fallen:
		unrush()
		return
	if !blackboard.get_value(key) or mob_mover_component.fallen:
		unrush()
		return
	rushing = true
	mob_mover_component.can_fall = false
	rush_weapon.swinging = true
	if rush_sound:
		rush_sound.play()
	var attack_direction: Vector2 = (blackboard.get_value(key).global_position - owner.global_position)
	direction_component.look_at_direction(attack_direction)
	mob_mover_component.throw(attack_direction, throw_speed, owner, throw_stop_speed, false, true, false)
	preparing_to_rush = false
	if weapon_sprite:
		weapon_sprite.piercing_animation(attack_direction.normalized() * 48, rush_delay - 0.2)
	await get_tree().create_timer(rush_delay).timeout
	unrush()

func unrush() -> void:
	rush_weapon.swinging = false
	mob_mover_component.movement_blocked = false
	preparing_to_rush = false
	rushing = false
	mob_mover_component.can_fall = true
	if rush_combo > 1:
		combos += 1
		if rush_combo > combos:
			rush()
			return
		else:
			combos = 0
	if rush_weapon:
		rush_weapon._cooldown()
	if mob_mover_component and fall_after_rush_delay != 0:
			mob_mover_component.drop(fall_after_rush_delay, true, 100)

func _on_body_entered(body: Node2D) -> void:
	if !rushing or !body:
		return
	var target: Node2D = blackboard.get_value(key)
	if body != target:
		if body is not PhysicsBody2D:
			unrush()
			if stamina_component and stamina_damage_after_wall_hit != 0:
				stamina_component.take_stamina_damage(stamina_damage_after_wall_hit, owner)
			if mob_mover_component and fall_delay_after_wall_hit != 0:
				mob_mover_component.drop(fall_delay_after_wall_hit, true, 100)
		return
	
	var attack_direction: Vector2 = (target.global_position - owner.global_position)
	rush_weapon._melee_attack_target(body, attack_direction)
