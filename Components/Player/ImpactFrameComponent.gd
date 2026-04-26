class_name ImpactFrameComponent extends Component

@export var effect_frame: ColorRect
@export var color_modify_frame: ColorRect

var color_tween: Tween
var pitch_tween: Tween
var aberration_tween: Tween
var pitch: AudioEffectPitchShift = AudioServer.get_bus_effect(0, 1)

var freeze_lifetime: float
signal freeze_end

func _process(delta: float) -> void:
	if freeze_lifetime <= 0:
		return
	freeze_lifetime -= delta
	if freeze_lifetime <= 0:
		freeze_lifetime = 0
		freeze_end.emit()

func impact_frame(
	impact_time: float = 0.3,
	wait_time: float = 0.0,
	modify_color: bool = true,
	distort_audio: bool = false
	) -> void:
	if wait_time != 0:
		await(tree.create_timer(wait_time, true, false, true).timeout)
	effect_frame.visible = true
	frame_freeze(impact_time)
	if freeze_lifetime <= 0:
		await(tree.create_timer(impact_time, true, false, true).timeout)
	else:
		await freeze_end
	effect_frame.visible = false
	if modify_color:
		set_color_modify(distort_audio)

func frame_freeze(impact_time = 0.3) -> void:
	if !tree.paused:
		tree.paused = true
	SettingsConfigSystem.impact_frame = true
	if impact_time > 0:
		freeze_lifetime += impact_time
		await freeze_end
	SettingsConfigSystem.impact_frame = false
	if SettingsConfigSystem.paused:
		return
	tree.paused = false

func set_color_modify(distort_audio = false) -> void:
	if !color_modify_frame or !color_modify_frame.material:
		return
	var material: Material = color_modify_frame.material
	
	if color_tween:
		color_tween.kill()
	if aberration_tween:
		aberration_tween.kill()
	if pitch_tween:
		pitch_tween.kill()
		pitch.pitch_scale = 1.0
	
	if distort_audio and pitch:
		pitch.pitch_scale = 0.1
		pitch_tween = create_tween()
		pitch_tween.tween_property(pitch, "pitch_scale", 1.0, 0.9)
		pitch_tween.set_ignore_time_scale()
	
	material.set_shader_parameter("chromatic_aberration_strength", 0.0)
	aberration_tween = create_tween()
	aberration_tween.set_trans(Tween.TRANS_SINE)
	aberration_tween.set_ease(Tween.EASE_IN_OUT)
	aberration_tween.set_ignore_time_scale()
	aberration_tween.tween_property(material, "shader_parameter/chromatic_aberration_strength", 0.01, 0.5)
	aberration_tween.tween_property(material, "shader_parameter/chromatic_aberration_strength", 0.0, 0.3)
	
	color_tween = create_tween()
	color_tween.set_trans(Tween.TRANS_SINE)
	color_tween.set_ease(Tween.EASE_IN_OUT)
	color_tween.set_ignore_time_scale()
	
	material.set_shader_parameter("green_factor", 1)
	material.set_shader_parameter("blue_factor", 1)
	material.set_shader_parameter("red_factor", 1)
	material.set_shader_parameter("hue_shift", 0)
	material.set_shader_parameter("alpha", 1.0)
	
	color_tween.tween_property(material, "shader_parameter/alpha", 0.0, 1)
	
	if randf() > 0.5:
		material.set_shader_parameter("hue_shift", randf_range(-2.5, -1.0))
		return
	
	var suppressed_channel = randi() % 3
	
	var red_factor: float
	var green_factor: float
	var blue_factor: float
	
	match suppressed_channel:
		0:
			red_factor = randf_range(1, 2)
			green_factor = randf_range(3, 5.5)
			blue_factor = randf_range(3, 5.5)
		1:
			red_factor = randf_range(3, 5.5)
			green_factor = randf_range(1, 2)
			blue_factor = randf_range(3, 5.5)
		2:
			red_factor = randf_range(3, 5.5)
			green_factor = randf_range(3, 5.5)
			blue_factor = randf_range(1, 2)
	
	material.set_shader_parameter("red_factor", red_factor)
	material.set_shader_parameter("green_factor", green_factor)
	material.set_shader_parameter("blue_factor", blue_factor)

func _ready() -> void:
	EventBusManager.explosion.connect(_on_exlosion)
	EventBusManager.kick_dash_combo.connect(_on_kickdash_combo)
	EventBusManager.parry.connect(_on_parry)
	EventBusManager.request_impact_frame.connect(impact_frame)

func _on_exlosion(explosion) -> void:
	if !explosion.impact_frame:
		return
	impact_frame(0.3, 0, true, true)

func _on_parry(emitter, type, _enemy):
	if emitter == parent and type == "Projectile":
		impact_frame(0.05, 0, false)

func _on_kickdash_combo(emitter) -> void:
	if emitter != parent:
		return
	
	impact_frame(0.1, 0.1)
