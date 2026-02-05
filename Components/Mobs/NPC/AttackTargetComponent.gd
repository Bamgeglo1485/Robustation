class_name AttackTargetComponent extends Component

@onready var move_to_target_component: MoveToTargetComponent = get_parent().get_node_or_null("MoveToTargetComponent")
@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")
@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")

var attack_direction: Vector2
var target: CharacterBody2D

@export var update_rate: float = 0.2
var update_timer: Timer

func _ready() -> void:
	update_timer = Timer.new()
	add_child(update_timer)
	update_timer.one_shot = true
	update_timer.wait_time = update_rate
	update_timer.timeout.connect(_update)
	update_timer.start()
	
	if !move_to_target_component:
		move_to_target_component = parent.get_node_or_null("MoveToTargetComponent")
	if !weapon_user_component:
		weapon_user_component = parent.get_node_or_null("WeaponUserComponent")
	if !mob_mover_component:
		mob_mover_component = parent.get_node_or_null("MobMoverComponent")
		
func _update() -> void:
	if !move_to_target_component or !weapon_user_component:
		return
	
	# Randomize update times to avoid lags
	update_timer.wait_time = randf_range(update_rate * 0.8, update_rate * 1.2)
	update_timer.start()
	
	if mob_mover_component:
		if mob_mover_component.fallen:
			return
	
	if !target and move_to_target_component and move_to_target_component.target:
		target = move_to_target_component.target
	
	if !target or !weapon_user_component.selected_weapon:
		return
	
	attack_direction = target.global_position - parent.global_position
	
	var weapon: Weapon = weapon_user_component.selected_weapon
	
	if weapon is MeleeWeapon:
		if attack_direction.length() > weapon.attack_range:
			return
		weapon_user_component.attack(self)
	elif weapon.bullets != 0:
		weapon_user_component.attack(self)

func get_attack_direction() -> Vector2:
	return attack_direction

func get_attack_target() -> CharacterBody2D:
	if move_to_target_component:
		return target
	else:
		return null
