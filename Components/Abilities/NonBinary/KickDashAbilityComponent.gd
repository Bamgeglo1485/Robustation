class_name KickDashAbilityComponent extends Component

@export var kick_weapon: Weapon
@export var target_clear_timer: Timer
@export var can_teleport_timer: Timer

@export var combo_effect: PackedScene = preload("res://Scenes/Effects/Particles/Combo.tscn")
@export var teleport_sound: AudioStreamPlayer2D
@export var max_kicks: int = 2
var kicks: int = 0

@onready var parent_health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
var last_kick_target: CharacterBody2D
var kick_target: CharacterBody2D
var can_teleport: bool

func _ready() -> void:
	if can_teleport_timer:
		can_teleport_timer.timeout.connect(_on_kick_teleport_timer_timeout)
	if target_clear_timer:
		target_clear_timer.timeout.connect(_on_kick_target_timer_timeout)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("movement_ability"):
		kick()

func kick() -> void:
	var targets = {}
	targets = await kick_weapon.attack(self, false)
	if targets and !targets.is_empty():
		if parent_health_component:
			parent_health_component.INVINCIBLE = true
		can_teleport_timer.start()
		target_clear_timer.start()
		can_teleport = false
		for target in targets.values():
			if target is not CharacterBody2D:
				continue
			
			var projectile_comp: ProjectileComponent = target.get_node_or_null("ProjectileComponent")
			if projectile_comp and !projectile_comp.parriable:
				continue
			
			kick_target = target
			
			if last_kick_target != target:
				last_kick_target = target
				kicks = 0
	elif kick_target and can_teleport and kicks < max_kicks:
		kick_teleport()

func kick_teleport() -> void:
	if not is_instance_valid(kick_target):
		kick_target = null
		return
	
	if kick_target:
		var mouse_direction = (parent.get_global_mouse_position() - parent.global_position).normalized()
		var teleport_position = kick_target.global_position + -mouse_direction * 20
		parent.global_position = teleport_position
	
	var target_projectile_comp: ProjectileComponent = kick_target.get_node_or_null("ProjectileComponent")
	if kick_target != null and !target_projectile_comp:
		var direction = (kick_target.global_position - parent.global_position)
		kick_weapon.reset_cooldown()
		kick_weapon._melee_attack_target(kick_target, direction)
		kick_weapon._cooldown()
	elif target_projectile_comp:
		if target_projectile_comp.delete_on_hit:
			kick_target = null
	
	if parent_health_component:
		parent_health_component.INVINCIBLE = true
	
	can_teleport = false
	kicks += 1
	
	target_clear_timer.start()
	can_teleport_timer.start()
	
	if teleport_sound != null:
		teleport_sound.global_position = parent.global_position
		teleport_sound.play()
	
	if kicks >= max_kicks and kick_target != null:
		EventBusManager.kick_dash_combo.emit(parent)
		if combo_effect:
			var effect = combo_effect.instantiate()
			parent.add_child.call_deferred(effect)
		var target_health: HealthComponent = kick_target.get_node_or_null("HealthComponent")
		if target_health:
			target_health.take_damage(kick_weapon.damage * 10, parent)

func _on_kick_teleport_timer_timeout() -> void:
	if parent_health_component:
		parent_health_component.INVINCIBLE = false
	can_teleport = true

func _on_kick_target_timer_timeout() -> void:
	kick_target = null
	kicks = 0

func get_attack_direction():
	if kick_target == null:
		return (parent.get_global_mouse_position()-parent.global_position)
	else:
		return (kick_target.global_position-parent.global_position)
