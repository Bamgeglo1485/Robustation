@abstract
class_name Weapon extends Component

@onready var animation_component = parent.get_node_or_null("AnimationComponent")

@export var timers_timescaled: bool = true

@export var can_attack: bool = true
@export var cooldown: bool = false
@export var cooldown_delay: float = 1

@export var swing_delay: float = 0.5
@export var swinging: bool = false

@export var equipped_texture: Texture2D
@export var icon_texture: Texture2D

@export var damage_modifier: float = 1

@export var self_throw_speed: int = 0
@export var self_throw_stop_speed: int = 300

@export var swing_rotation_multiplier: float = -1
@export var attack_rotation_multiplier: float = 1
@export var attack_shift_multiplier: float = 1

@export var parriable: bool = true

var swinging_cancelled: bool

func _ready() -> void:
	if parent is not Node2D:
		parent = parent.get_parent()
		animation_component = parent.get_node_or_null("AnimationComponent")
	
	if parent.has_node("Sounds"):
		var sounds: Node = parent.get_node("Sounds")
		for child in get_children():
			if child is AudioStreamPlayer2D:
				child.reparent(sounds)

func _swing(direction):
	if swing_delay != 0:
		swinging = true
		swinging_cancelled = false
		
		if animation_component != null and swing_rotation_multiplier != 0:
			animation_component.lean_to_direction(direction, 2, swing_delay, swing_rotation_multiplier)
		
		if timers_timescaled == true:
			await get_tree().create_timer(swing_delay).timeout
		else:
			await get_tree().create_timer(swing_delay, true, false, true).timeout
		
		swinging = false

func _cooldown():
	if cooldown_delay != 0:
		cooldown = true
		if timers_timescaled == true:
			await get_tree().create_timer(cooldown_delay).timeout
		else:
			await get_tree().create_timer(cooldown_delay, true, false, true).timeout
		cooldown = false

func get_cooldown():
	return cooldown
