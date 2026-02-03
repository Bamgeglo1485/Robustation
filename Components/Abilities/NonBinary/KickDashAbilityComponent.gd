class_name KickDashAbilityComponent extends Component

@export var kick_weapon: Weapon
@export var target_clear_timer: Timer
@export var can_teleport_timer: Timer

@export var teleport_sound: AudioStreamPlayer2D
@export var max_kicks: int = 2
var kicks: int = 0

var last_kick_target: CharacterBody2D
var kick_target: CharacterBody2D
var can_teleport: bool

func _ready() -> void:
	if can_teleport_timer:
		can_teleport_timer.timeout.connect(_on_kick_teleport_timer_timeout)
	if target_clear_timer:
		target_clear_timer.timeout.connect(_on_kick_target_timer_timeout)
		
func _process(_delta: float) -> void:
	if parent.has_node("InputMoverComponent"):
		input()
	
func input() -> void:
	if Input.is_action_just_pressed("movement_ability"):
		kick()

func kick() -> void:
	var targets = {}
	targets = await kick_weapon.attack(self, false)
	if targets and !targets.is_empty():
		for target in targets.values():
			if target is not CharacterBody2D:
				continue
			kick_target = target
			if parent.has_node("HealthComponent"):
				parent.get_node("HealthComponent").INVINCIBLE = true
			
			if last_kick_target != target:
				last_kick_target = target
				kicks = 0
			can_teleport = false
		
		can_teleport_timer.start()
		target_clear_timer.start()
		return
	
	elif kick_target and can_teleport and kicks < max_kicks:
		kick_teleport()

func kick_teleport() -> void:
	if not is_instance_valid(kick_target):
		kick_target = null
		return
	
	var mouse_direction = (parent.get_global_mouse_position() - parent.global_position).normalized()
	var teleport_position = kick_target.global_position + -mouse_direction * 20
	
	parent.global_position = teleport_position
	
	if kick_target != null and not kick_target.has_node("ProjectileComponent"):
		var direction = (kick_target.global_position - parent.global_position)
		kick_weapon._melee_attack_target(kick_target, direction)
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
	
	if kicks >= max_kicks and kick_target != null:
		EventBusManager.kick_dash_combo.emit(parent)
		if kick_target.has_node("HealthComponent"):
			kick_target.get_node("HealthComponent").take_damage(kick_weapon.damage * 10, parent)

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
