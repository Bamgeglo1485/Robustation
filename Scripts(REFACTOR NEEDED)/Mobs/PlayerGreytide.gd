extends "res://Scripts/Mobs/PlayerSystem.gd"

@onready var kick_weapon: Node2D = $Kick
@onready var kick_target_timer: Timer = $KickTargetTimer
@onready var kick_teleport_timer: Timer = $KickTeleportTimer

@export var teleport_sound: AudioStreamPlayer2D
@export var max_kicks: int = 3
var kicks: int = 0

var last_kick_target: CharacterBody2D
var kick_target: CharacterBody2D
var can_teleport: bool

#region Weapon
func movement_ability():
	kick()

func kick():
	var _direction = global_position.direction_to(get_global_mouse_position())
	var _targets = {}
	
	_targets = try_melee_attack(kick_weapon, _direction, kick_weapon.rotation_multiplier)
	
	if (_targets == null or _targets.is_empty()) and kick_target != null and can_teleport == true and kicks < max_kicks:
		kick_teleport()
		return
	elif _targets == null or _targets.is_empty():
		return
	
	for _target in _targets.values():
		if _target.has_method("set_animation"):
			var _tween = create_tween()
			_tween.set_trans(Tween.TRANS_SINE)
			_tween.set_ease(Tween.EASE_IN_OUT)
			_tween.stop()
			
			_tween.tween_property(self, "global_rotation", 10, 0.2)
			_tween.tween_property(self, "global_rotation", 0, 0.2)
			
			_target.set_animation(_tween, 4)
			
			kick_teleport_timer.start()
			kick_target_timer.start()
			kick_target = _target
			INVINCIBLE = true
			
			if last_kick_target != _target:
				last_kick_target = _target
				kicks = 0
			can_teleport = false
	
	fly_off(-_direction, kick_weapon.fly_off_speed)

func kick_teleport():
	var mouse_direction = (get_global_mouse_position()-global_position).normalized()
	var teleport_position = kick_target.global_position + -mouse_direction * 20
	
	self.global_position = teleport_position
	
	kick_weapon.can_attack = true
	_melee_attack_target(kick_target, kick_weapon, kick_weapon.rotation_multiplier, mouse_direction)
	kick_teleport_timer.start()
	kick_target_timer.start()
	INVINCIBLE = true
	can_teleport = false
	kicks += 1
	
	if teleport_sound != null:
		teleport_sound.play()
	
	if kicks + 1 == max_kicks and kick_target != null:
		ImpactFrame.impact_frame(0.05, 0.15)
		kick_target.take_damage(kick_weapon.melee_damage, self)

func _on_kick_target_timer_timeout() -> void:
	kick_target = null
	kicks = 0

func _on_kick_teleport_timer_timeout() -> void:
	INVINCIBLE = false
	can_teleport = true
	kick_target_timer.start()
#endregion
