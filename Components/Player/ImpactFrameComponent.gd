class_name ImpactFrameComponent extends Component

@export var effect_frame: ColorRect
@export var color_modify_frame: ColorRect

var color_tween: Tween

func impact_frame(impact_time = 0.3, wait_time = 0.0, modify_color = true):
	if wait_time != 0:
		await(get_tree().create_timer(wait_time, true, false, true).timeout)
	effect_frame.visible = true
	frame_freeze(impact_time)
	if modify_color == true:
		set_color_modify()
	await(get_tree().create_timer(impact_time, true, false, true).timeout)
	effect_frame.visible = false

func frame_freeze(impact_time = 0.3):
	get_tree().paused = true
	await(get_tree().create_timer(impact_time, true, false, true).timeout)
	get_tree().paused = false

func set_color_modify():
	if color_modify_frame == null or color_modify_frame.material == null:
		return
	var material = color_modify_frame.material
	
	if color_tween != null:
		color_tween.kill()
	
	color_tween = create_tween()
	color_tween.set_trans(Tween.TRANS_SINE)
	color_tween.set_ease(Tween.EASE_IN_OUT)
	color_tween.set_ignore_time_scale(true)
	
	material.set_shader_parameter("green_factor", 1)
	material.set_shader_parameter("blue_factor", 1)
	material.set_shader_parameter("red_factor", 1)
	material.set_shader_parameter("hue_shift", 0)
	material.set_shader_parameter("alpha", 0.5)
	
	color_tween.tween_property(material, "shader_parameter/alpha", 0, 3)
	
	if randf() > 0.5:
		material.set_shader_parameter("hue_shift", randf_range(-0.15, 0.15))
		return
	
	randomize()
	material.set_shader_parameter("red_factor", randf_range(1, 1.5))
	randomize()
	material.set_shader_parameter("green_factor", randf_range(1, 1.5))
	randomize()
	material.set_shader_parameter("blue_factor", randf_range(1, 1.5))

func _ready() -> void:
	EventBusManager.explosion.connect(on_exlosion)
	EventBusManager.kick_dash_combo.connect(on_kickdash_combo)

func on_exlosion(explosion):
	if explosion.impact_frame == false:
		return
	impact_frame()

func on_kickdash_combo(emitter):
	if emitter != parent:
		return
	
	impact_frame(0.1, 0.1)
