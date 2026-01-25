class_name RageComponent extends Component

var raged = false

@export var rage_delay: float = 15
@export var rage_damage_addendum: float = 1
@export var rage_damage_resistance_subtrahend: float = 0.5
@export var rage_speed_modifier_addendum: float = 0
@export var aura_effect: Node2D

@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")
@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")

@export var rage_sound: AudioStreamPlayer2D
@export var unrage_sound: AudioStreamPlayer2D
@export var rage_effect: PackedScene
@export var rage_sprite: Sprite2D

signal rage_state_change(raged)

func rage():
	if raged == true:
		return
	
	EventBusManager.raged.emit(parent)
	
	raged = true
	rage_state_change.emit(raged)
	
	if rage_sound != null:
		rage_sound.play()
	if rage_effect != null:
		var inst = rage_effect.instantiate()
		scene.add_child(inst)
		inst.global_position = parent.global_position
	if rage_sprite != null:
		rage_sprite.visible = true
	
	if aura_effect != null:
		var _tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(aura_effect.material, "shader_parameter/aura_min_line_width", 0.1, 0.5)
		_tween.tween_property(aura_effect.material, "shader_parameter/aura_max_line_width", 2.3, 0.5)
		_tween.tween_property(aura_effect.material, "shader_parameter/aura_opacity", 0.5, 0.5)
	
	if weapon_user_component != null:
		weapon_user_component.damage_modifier += rage_damage_addendum
	if health_component != null:
		health_component.damage_modifier -= rage_damage_resistance_subtrahend
	if mob_mover_component != null:
		mob_mover_component.speed_modifier += rage_speed_modifier_addendum
	
	if rage_delay != 0:
		await get_tree().create_timer(rage_delay).timeout
		unrage()

func unrage():
	raged = false
	rage_state_change.emit(raged)
	
	if rage_sound != null:
		rage_sound.stop()
	if unrage_sound != null:
		unrage_sound.play()
	if rage_sprite != null:
		rage_sprite.visible = false
	
	if aura_effect != null:
		var _tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(aura_effect.material, "shader_parameter/aura_min_line_width", 0, 0.5)
		_tween.tween_property(aura_effect.material, "shader_parameter/aura_max_line_width", 0, 0.5)
		_tween.tween_property(aura_effect.material, "shader_parameter/aura_opacity", 0, 0.5)
	
	if weapon_user_component != null:
		weapon_user_component.damage_modifier -= rage_damage_addendum
	if health_component != null:
		health_component.damage_modifier += rage_damage_resistance_subtrahend
	if mob_mover_component != null:
		mob_mover_component.speed_modifier -= rage_speed_modifier_addendum
