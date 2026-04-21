class_name OverdoseAbilityComponent extends BaseAbilityComponent

@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
@onready var dash_component: DashAbilityComponent = parent.get_node_or_null("DashAbilityComponent")

@export var trail_colors: Array[Color]
@export var overdose_effect: ColorRect
## A body that will replace the player so that enemies will shoot at him, like Sandevistan in Cyberpunk
@export var distraction_scene: PackedScene
var distraction: CharacterBody2D

var friction_modification: float

var effect_tween: Tween
var pitch: AudioEffectPitchShift = AudioServer.get_bus_effect(0, 2)

func _init() -> void:
	ignore_time_scale = true

func _ready() -> void:
	super._ready()
	if distraction_scene and scene:
		distraction = distraction_scene.instantiate()
		scene.add_child.call_deferred(distraction)

func activate_ability() -> bool:
	if !mob_mover_component:
		return false
	
	if dash_component:
		if dash_component.dash_stamina < dash_component.max_dash_stamina:
			return false
		dash_component.dash_stamina = 1
		dash_component._update_stamina_bar()
		dash_component._cooldown()
	
	overdose_effects()
	mob_mover_component.set_minor_speed_modifier("overdose", 2.0)
	friction_modification = mob_mover_component.acceleration * Engine.time_scale * 30.0
	mob_mover_component.fly_modifier = 0
	mob_mover_component.friction += friction_modification
	
	var time_tween: Tween = create_tween()
	time_tween.tween_property(pitch, "pitch_scale", 0.35, 0.5)
	time_tween.tween_property(Engine, "time_scale", 0.35, 0.5)
	
	if overdose_effect and overdose_effect.material:
		overdose_effect.visible = true
		effect_tween = create_tween()
		effect_tween.set_trans(Tween.TRANS_SINE)
		effect_tween.set_ease(Tween.EASE_IN_OUT)
		effect_tween.tween_property(overdose_effect.material, "shader_parameter/alpha", 1.0, 0.5)
		effect_tween.tween_property(overdose_effect.material, "shader_parameter/red_factor", 2.0, ability_delay)
		effect_tween.tween_property(overdose_effect.material, "shader_parameter/blue_factor", 2.0, ability_delay)
		effect_tween.tween_property(overdose_effect.material, "shader_parameter/green_factor", 1.0, ability_delay)
		effect_tween.tween_property(overdose_effect.material, "shader_parameter/hue_shift", -0.3, ability_delay)
		effect_tween.set_ignore_time_scale(true)
		effect_tween.set_loops()
	
	if distraction:
		distraction.global_position = parent.global_position
		EventBusManager.change_player.emit(distraction, 0)
	return true

func overdose_effects() -> void:
	var trail = TrailEffectComponent.new()
	trail.lifetime = ability_delay
	trail.colors = trail_colors
	trail.color_change_delay = ability_delay / trail_colors.size()
	trail.name = "TrailEffectComponent"
	trail.ignore_time_scale = true
	parent.add_child(trail)

func disable_ability() -> void:
	var time_tween: Tween = create_tween()
	time_tween.tween_property(pitch, "pitch_scale", 1, 0.5)
	time_tween.tween_property(Engine, "time_scale", 1, 0.5)
	
	if mob_mover_component:
		mob_mover_component.fly_modifier = 1
		mob_mover_component.set_minor_speed_modifier("overdose", 1.0)
		mob_mover_component.friction -= friction_modification
	
	if distraction:
		EventBusManager.change_player.emit(parent, 0.5)
	
	if overdose_effect and overdose_effect.material:
		if effect_tween:
			effect_tween.kill()
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(overdose_effect.material, "shader_parameter/alpha", 0.0, 0.5)
		tween.tween_property(overdose_effect.material, "shader_parameter/red_factor", 1.0, 0.5)
		tween.tween_property(overdose_effect.material, "shader_parameter/blue_factor", 1.0, 0.5)
		tween.tween_property(overdose_effect.material, "shader_parameter/green_factor", 1.0, 0.5)
		tween.tween_property(overdose_effect.material, "shader_parameter/hue_shift", 0.0, 0.5)
		await tween.finished
		overdose_effect.visible = false
