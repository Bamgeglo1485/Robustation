class_name ImpactFrameComponent extends Component

@export var effect_frame: ColorRect
@export var color_modify_frame: ColorRect

var color_tween: Tween
var pitch_tween: Tween
var pitch: AudioEffectPitchShift = AudioServer.get_bus_effect(0, 1)

func impact_frame(
	impact_time = 0.3,
	wait_time = 0.0,
	modify_color = true,
	distort_audio = false
	) -> void:
	if modify_color:
		set_color_modify(distort_audio)
	if wait_time != 0:
		await(get_tree().create_timer(wait_time, true, false, true).timeout)
	effect_frame.visible = true
	frame_freeze(impact_time)
	await(get_tree().create_timer(impact_time, true, false, true).timeout)
	effect_frame.visible = false

func frame_freeze(impact_time = 0.3) -> void:
	get_tree().paused = true
	await(get_tree().create_timer(impact_time, true, false, true).timeout)
	get_tree().paused = false

func set_color_modify(distort_audio = false) -> void:
	if !color_modify_frame or !color_modify_frame.material:
		return
	var material: Material = color_modify_frame.material
	
	if color_tween:
		color_tween.kill()
	if pitch_tween:
		pitch_tween.kill()
	
	if distort_audio and pitch:
		pitch.pitch_scale = 0.1
		pitch_tween = create_tween()
		pitch_tween.tween_property(pitch, "pitch_scale", 1, 1)
	
	color_tween = create_tween()
	color_tween.set_trans(Tween.TRANS_SINE)
	color_tween.set_ease(Tween.EASE_IN_OUT)
	color_tween.set_ignore_time_scale(true)
	
	material.set_shader_parameter("green_factor", 1)
	material.set_shader_parameter("blue_factor", 1)
	material.set_shader_parameter("red_factor", 1)
	material.set_shader_parameter("hue_shift", 0)
	material.set_shader_parameter("alpha", 0.9)
	
	color_tween.tween_property(material, "shader_parameter/alpha", 0, 1)
	
	if randf() > 0.5:
		material.set_shader_parameter("hue_shift", randf_range(-1.5, -0.7))
		return
	
	material.set_shader_parameter("red_factor", randf_range(1, 1.5))
	material.set_shader_parameter("green_factor", randf_range(1, 1.5))
	material.set_shader_parameter("blue_factor", randf_range(1, 1.5))

func _ready() -> void:
	EventBusManager.explosion.connect(_on_exlosion)
	EventBusManager.kick_dash_combo.connect(_on_kickdash_combo)
	EventBusManager.parry.connect(_on_parry)
	EventBusManager.request_impact_frame.connect(impact_frame)

func _on_exlosion(explosion) -> void:
	if !explosion.impact_frame:
		return
	impact_frame(0.3, 0, true, true)

func _on_parry(emitter, type):
	if emitter == parent and type == "Projectile":
		impact_frame(0.1, 0, false)

func _on_kickdash_combo(emitter) -> void:
	if emitter != parent:
		return
	
	impact_frame(0.1, 0.1)
