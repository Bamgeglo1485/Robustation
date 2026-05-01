@abstract
class_name Weapon extends Component

@onready var animation_component: AnimationComponent = parent.get_node_or_null("AnimationComponent")

@export var timers_timescaled: bool = true

@export var can_attack: bool = true
@export var cooldown: bool = false
@export var cooldown_delay: float = 1.0
# Cooldown delay modifier
@export var cooldown_modifier: float = 1.0

@export var swing_delay: float = 0.5
@export var swinging: bool = false

@export var equipped_texture: Texture2D
@export var equipped_scale: Vector2 = Vector2(0.8, 0.8)
@export var icon_texture: Texture2D

@export var damage_modifier: float = 1.0
@export var minor_damage_modifiers: Dictionary
var minor_damage_modifier: float = 1.0

@export var self_throw_speed: int = 0
@export var self_throw_stop_speed: int = 300
# check MobMoverComponent > throw to understand
@export var self_throw_rewrite: bool = false

# animation offset modifiers
@export var swing_rotation_multiplier: float = -1.0
@export var attack_rotation_multiplier: float = 1.0
@export var attack_shift_multiplier: float = 1.0

# Can weapon be parried?
@export var parriable: bool = true
# If true, the attack occurs while the mouse is pressed
@export var auto: bool = false
# If there is a parent, it inherits its timers, ammo, and cooldown.
@export var parent_weapon: Weapon
# Alternative attack on RMB
@export var alt_attack: Weapon

@export var random_cooldown_delay_coef: float = 0.0

@export var swinging_sound: AudioStreamPlayer2D
var swinging_cancelled: bool
var cooldown_timer: Timer
var swinging_timer: Timer

var main_weapon: Weapon
var child_weapons: Array[Weapon]
var can_switch: bool = true

var player_weapon_user: PlayerWeaponUserComponent
var weapon_inhand_texture: Sprite2D
var weapon_sprite: WeaponSpriteComponent

@export_category("Information")
@export var weapon_name: String
@export var color: Color
@export var weapon_class: String
@export_multiline() var weapon_desc: String

@export_category("Modifiers")
@export var damage_multipliers: Dictionary
@export var damage_multiplier: float = 1.0

enum rarity_classes {
	SHITTY,
	COMMON,
	ROBUST,
	ADMINABUSE
}

@export var weapon_rarity: rarity_classes = rarity_classes.COMMON

@warning_ignore("unused_signal")
signal swapped(new_weapon: Weapon)

func _ready() -> void:
	const max_attempts: int = 15
	var attempts: int = 0
	
	while parent is not PhysicsBody2D:
		var potential_parent: Node = parent.get_parent()
		if potential_parent:
			parent = potential_parent
		attempts += 1
		if parent is PhysicsBody2D:
			break
		if attempts > max_attempts:
			break
	
	animation_component = parent.get_node_or_null("AnimationComponent")
	player_weapon_user = parent.get_node_or_null("PlayerWeaponUserComponent")
	weapon_sprite = parent.get_node_or_null("Texture").get_node_or_null("WeaponSpriteComponent")
	weapon_inhand_texture = weapon_sprite.weapon_texture
	
	# We move the sounds in Node2D so that they are tied to the parent's position
	# Перемещаем звуки в Node2D, что те были привязаны к позиции родителя
	if parent.has_node("Sounds"):
		var sounds: Node = parent.get_node("Sounds")
		for child in get_children():
			if child is AudioStreamPlayer2D:
				child.reparent(sounds)
				child.position = Vector2(0, 0)
	
	# эту хуйню не трогайте
	# dont touch this shit
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

# A function to inherit. Called when the mouse button is released.
func on_release(_raiser) -> void:
	pass

func _swing(direction) -> void:
	if swing_delay != 0:
		swinging = true
		swinging_cancelled = false
		if swinging_sound:
			swinging_sound.play()
		
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
		if random_cooldown_delay_coef != 0:
			modified_cooldown *= randf_range(1.0 - random_cooldown_delay_coef, 1 + random_cooldown_delay_coef)
		
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
