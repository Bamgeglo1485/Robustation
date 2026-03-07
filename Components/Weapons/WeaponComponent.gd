@abstract
class_name Weapon extends Component

@onready var animation_component: AnimationComponent = parent.get_node_or_null("AnimationComponent")

@export var timers_timescaled: bool = true

@export var can_attack: bool = true
@export var cooldown: bool = false
@export var cooldown_delay: float = 1.0
@export var cooldown_modifier: float = 1.0

@export var swing_delay: float = 0.5
@export var swinging: bool = false

@export var equipped_texture: Texture2D
@export var icon_texture: Texture2D

@export var damage_modifier: float = 1.0
@export var minor_damage_modifiers: Dictionary
var minor_damage_modifier: float = 1.0

@export var self_throw_speed: int = 0
@export var self_throw_stop_speed: int = 300

@export var swing_rotation_multiplier: float = -1.0
@export var attack_rotation_multiplier: float = 1.0
@export var attack_shift_multiplier: float = 1.0

@export var parriable: bool = true
@export var auto: bool = false
@export var parent_weapon: Weapon
@export var alt_attack: Weapon

var swinging_cancelled: bool
var cooldown_timer: Timer
var swinging_timer: Timer
var main_weapon: Weapon
var child_weapons: Array[Weapon]
var can_switch: bool = true

@warning_ignore("unused_signal")
signal swapped(new_weapon: Weapon)

func _ready() -> void:
	if parent is not Node2D:
		parent = parent.get_parent()
		animation_component = parent.get_node_or_null("AnimationComponent")
	
	if parent.has_node("Sounds"):
		var sounds: Node = parent.get_node("Sounds")
		for child in get_children():
			if child is AudioStreamPlayer2D:
				child.reparent(sounds)
	if parent_weapon:
		parent_weapon.child_weapons.append(self)
	if !parent_weapon:
		cooldown_timer = Timer.new()
		cooldown_timer.ignore_time_scale = !timers_timescaled
		cooldown_timer.one_shot = true
		add_child(cooldown_timer)
		swinging_timer = Timer.new()
		swinging_timer.ignore_time_scale = !timers_timescaled
		swinging_timer.one_shot = true
		add_child(swinging_timer)
	else:
		await parent_weapon.ready
		cooldown_timer = parent_weapon.cooldown_timer
		swinging_timer = parent_weapon.swinging_timer
	if alt_attack:
		alt_attack.main_weapon = self

@warning_ignore("unused_parameter")
func on_release(raiser) -> void:
	pass

func _swing(direction) -> void:
	if swing_delay != 0:
		swinging = true
		swinging_cancelled = false
		
		if animation_component and swing_rotation_multiplier != 0:
			animation_component.lean_to_direction(direction, 2, swing_delay, swing_rotation_multiplier)
		
		swinging_timer.wait_time = swing_delay
		swinging_timer.start()
		EventBusManager.swinging_start.emit(parent, self)
		await swinging_timer.timeout
		
		swinging = false

func _cooldown() -> void:
	if cooldown_delay != 0:
		cooldown = true
		var modified_cooldown = cooldown_delay * cooldown_modifier
		cooldown_timer.wait_time = modified_cooldown
		cooldown_timer.start()
		EventBusManager.weapon_cooldown.emit(parent, self)
		await cooldown_timer.timeout
		cooldown = false

func reset_cooldown() -> void:
	if !cooldown:
		return
	cooldown = false
	cooldown_timer.stop()
	
	EventBusManager.weapon_cooldown_reset.emit(parent, self)

func get_cooldown() -> bool:
	return cooldown

func _get_minor_modifiers() -> float:
	var modifier: float = 1.0
	
	if minor_damage_modifiers.is_empty():
		return modifier
	
	for minor_mod in minor_damage_modifiers:
		modifier *= minor_damage_modifiers[minor_mod]
	
	return modifier
