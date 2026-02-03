class_name OverdoseAbilityComponent extends BaseAbilityComponent

@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")

@export var trail_colors: Array[Color]
@export var overdose_effect: ColorRect

var speed_modification: float
var acceleration_modification: float
var friction_modification: float

var effect_tween: Tween

func activate_ability() -> void:
	if !mob_mover_component:
		return
	
	overdose_effects()
	
	speed_modification = mob_mover_component.max_speed / Engine.time_scale * 2.0
	acceleration_modification = mob_mover_component.acceleration / Engine.time_scale * 2.0
	friction_modification = mob_mover_component.acceleration * Engine.time_scale * 30.0
	
	mob_mover_component.max_speed += speed_modification
	mob_mover_component.acceleration += acceleration_modification
	mob_mover_component.friction += friction_modification
	mob_mover_component.fly_modifier = 0.2
	
	var time_tween: Tween = create_tween()
	time_tween.tween_property(Engine, "time_scale", 0.35, 0.5)
	
	if overdose_effect and overdose_effect.material:
		effect_tween = create_tween()
		effect_tween.set_trans(Tween.TRANS_SINE)
		effect_tween.set_ease(Tween.EASE_IN_OUT)
		effect_tween.tween_property(overdose_effect.material, "shader_parameter/alpha", 1, 0.5)
		effect_tween.tween_property(overdose_effect.material, "shader_parameter/red_factor", 2, ability_delay)
		effect_tween.tween_property(overdose_effect.material, "shader_parameter/blue_factor", 2, ability_delay)
		effect_tween.tween_property(overdose_effect.material, "shader_parameter/green_factor", 1, ability_delay)
		effect_tween.tween_property(overdose_effect.material, "shader_parameter/hue_shift", -0.3, ability_delay)
		effect_tween.set_ignore_time_scale(true)
		effect_tween.set_loops(100)

func overdose_effects() -> void:
	var trail = TrailEffectComponent.new()
	trail.lifetime = ability_delay
	trail.colors = trail_colors
	trail.color_change_delay = ability_delay / trail_colors.size()
	trail.name = "TrailEffectComponent"
	parent.add_child(trail)

func disable_ability() -> void:
	var time_tween: Tween = create_tween()
	time_tween.tween_property(Engine, "time_scale", 1, 0.5)
	
	mob_mover_component.max_speed -= speed_modification
	mob_mover_component.acceleration -= acceleration_modification
	mob_mover_component.friction -= friction_modification
	mob_mover_component.fly_modifier = 1
	
	if overdose_effect and overdose_effect.material:
		effect_tween.kill()
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(overdose_effect.material, "shader_parameter/alpha", 0, 0.5)
		tween.tween_property(overdose_effect.material, "shader_parameter/red_factor", 1, 0.5)
		tween.tween_property(overdose_effect.material, "shader_parameter/blue_factor", 1, 0.5)
		tween.tween_property(overdose_effect.material, "shader_parameter/green_factor", 1, 0.5)
		tween.tween_property(overdose_effect.material, "shader_parameter/hue_shift", 0, 0.5)
