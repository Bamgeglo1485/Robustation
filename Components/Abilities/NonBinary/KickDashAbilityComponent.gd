class_name KickDashAbilityComponent extends Component

@export var kick_weapon: Weapon
@export var target_clear_timer: Timer
@export var can_teleport_timer: Timer

@export var teleport_sound: AudioStreamPlayer2D
@export var max_kicks: int = 3
var kicks: int = 0

var last_kick_target: CharacterBody2D
var kick_target: CharacterBody2D
var can_teleport: bool

func _ready() -> void:
	if can_teleport_timer != null:
		can_teleport_timer.timeout.connect(_on_kick_teleport_timer_timeout)
	if target_clear_timer != null:
		target_clear_timer.timeout.connect(_on_kick_target_timer_timeout)

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if parent.has_node("InputMoverComponent"):
		input()

func input():
	if Input.is_action_just_pressed("movement_ability"):
		kick()

func kick():
	var targets = {}
	targets = await kick_weapon.attack(self, false)
	if targets != null and not targets.is_empty():
		for target in targets.values():
			kick_target = target
			if parent.has_node("HealthComponent"):
				parent.get_node("HealthComponent").INVINCIBLE = true
			
			if last_kick_target != target:
				last_kick_target = target
				kicks = 0
			can_teleport = false
		
		can_teleport_timer.start()
		return
	
	elif kick_target != null and can_teleport == true and kicks < max_kicks:
		kick_teleport()

func kick_teleport():
	if not is_instance_valid(kick_target):
		kick_target = null
		return
	
	var mouse_direction = (parent.get_global_mouse_position() - parent.global_position).normalized()
	var teleport_position = kick_target.global_position + -mouse_direction * 20
	
	parent.global_position = teleport_position
	
	if kick_target != null and not kick_target.has_node("ProjectileComponent"):
		kick_weapon.cooldown = false
		kick_weapon.attack(self, false)
	elif kick_target.has_node("ProjectileComponent"):
		kick_target = null
	
	if parent.has_node("HealthComponent"):
		parent.get_node("HealthComponent").INVINCIBLE = true
	
	can_teleport = false
	kicks += 1
	
	target_clear_timer.start()
	can_teleport_timer.start()
	
	if teleport_sound != null:
		teleport_sound.global_position = parent.global_position
		teleport_sound.play()
	
	if kicks > max_kicks and kick_target != null:
		if kick_target.has_node("HealthComponent"):
			kick_target.get_node("HealthComponent").take_damage(kick_weapon.damage, parent)

func _on_kick_teleport_timer_timeout() -> void:
	if parent.has_node("HealthComponent"):
		parent.get_node("HealthComponent").INVINCIBLE = false
	can_teleport = true

func _on_kick_target_timer_timeout() -> void:
	kick_target = null
	kicks = 0

func get_attack_direction():
	if kick_target == null:
		return (parent.get_global_mouse_position()-parent.global_position)
	else:
		return (kick_target.global_position-parent.global_position)
