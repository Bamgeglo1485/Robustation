class_name PlayerIntroductionComponent extends Component

var introduction_queue: Array[Node2D]
var can_skip: bool = false
var introductioning: bool = false
var camera: Camera2D
@export_multiline() var placeholder_text: String
@onready var player_camera: PlayerCamera = parent.get_node_or_null("PlayerCamera")
@export var control: Control
@export var scan_scene: PackedScene
@onready var ingame_menu: IngameMenuComponent = parent.get_node("IngameMenuComponent")
@onready var texture: TextureRect = control.get_node("Texture")
@onready var information: RichTextLabel = control.get_node("Information")
@onready var information_animation: TextPrintingAnimationComponent = information.get_node("TextPrintingAnimationComponent")
var scan: ReferenceRect
var scan_offset: RandomOffsetComponent
var prev_timescale: float = 1.0

@export var alarm_sound: AudioStreamPlayer
@export var scan_start_sound: AudioStreamPlayer
@export var scan_loop_sound: AudioStreamPlayer
@export var computer_loop_sound: AudioStreamPlayer
@export var return_sound: AudioStreamPlayer
@export var enemy_theme: AudioStreamPlayer

var config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBusManager.introduction_subject_on_screen.connect(_on_subject_on_screen)
	camera = Camera2D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child.call_deferred(camera)
	
	scan = scan_scene.instantiate()
	scan.modulate.a = 0
	scan.visible = false
	scene.add_child.call_deferred(scan)
	scan_offset = scan.get_node("RandomOffsetComponent")
	config.load("user://settings.cfg")

func _on_subject_on_screen(target: Node2D) -> void:
	var target_introduction: IntroductionSubjectComponent = target.get_node_or_null("IntroductionSubjectComponent")
	if SettingsConfigSystem.introductiones_enemies.has(target_introduction.group):
		return
	SettingsConfigSystem.introductiones_enemies.append(target_introduction.group)
	config.set_value("INTRODUCTION", target_introduction.group, true)
	config.save("user://settings.cfg")
	if introductioning:
		introduction_queue.append(target)
	else:
		introduction(target)

func introduction(target: Node2D) -> void:
	prev_timescale = Engine.time_scale
	Engine.time_scale = 1.0
	
	for child in control.get_children():
		if child is CanvasLayer:
			child.visible = true
	
	computer_loop_sound.play()
	alarm_sound.play()
	
	texture.modulate.a = 0
	introductioning = true
	control.modulate.a = 1
	control.visible = true
	# CAMERA SETUP STAGE
	get_tree().paused = true
	_setup_camera()
	var _tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(camera, "global_position", target.global_position, 1)
	_tween.tween_property(camera, "zoom", Vector2(4, 4), 0.5)
	
	await _tween.finished
	
	var direction_component: DirectionComponent = target.get_node_or_null("DirectionComponent")
	if direction_component:
		direction_component.look_at_direction(Vector2(0, 1))
	# SCAN STAGE
	scan_start_sound.play()
	scan_loop_sound.play()
	scan.visible = true
	scan.scale = Vector2(0.1, 0.1)
	scan.global_position = target.global_position - scan.pivot_offset/2
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_parallel()
	_tween.tween_property(scan, "modulate:a", 1, 0.1)
	_tween.tween_property(scan, "scale", Vector2(2, 2), 0.5)
	
	await _tween.finished
	
	# VARIABLES STAGE
	var target_introduction: IntroductionSubjectComponent = target.get_node_or_null("IntroductionSubjectComponent")
	var target_health: HealthComponent = target.get_node_or_null("HealthComponent")
	var target_mob_mover: MobMoverComponent = target.get_node_or_null("MobMoverComponent")
	
	enemy_theme.stream = target_introduction.theme
	enemy_theme.play()
	texture.texture = target.get_node("Texture").texture
	var _texture_tween = create_tween()
	_texture_tween.set_trans(Tween.TRANS_BACK)
	_texture_tween.set_ease(Tween.EASE_IN_OUT)
	_texture_tween.tween_property(texture, "modulate:a", 0.4, 1)
	
	# INFORMATION STAGE
	
	information_animation.animate(placeholder_text, 1, true, false)
	await information_animation.tween.finished
	var info_text: String = (
	"[color=crimson]NEW TARGET DETECTED. LOADING INFORMATION FROM THE DATABASE[/color]" +
	"\n.................." +
	"\n[color=green]LOADING SUCCESSFUL[/color]:" +
	"\n" +
	"\nTARGET_NAME: [color=crimson]" + target_introduction.subject_name + 
	"\n[/color]TARGET_PREFIX: [color=crimson]" + target_introduction.subject_prefix +
	"\n[/color]TARGET_DESC: [color=crimson]" + target_introduction.subject_desc +
	"\n[/color]TARGET_HEALTH: [color=crimson]" + str(target_health.max_health) +
	"\n[/color]TARGET_SPEED: [color=crimson]" + str(roundf(target_mob_mover.max_speed)) +
	"\n---------------------" +
	"\n[color=green]INPUT 'R' TO RESUME REPLAY[/color]"
	)
	information_animation.animate(info_text, 1, true, false)
	
	await information_animation.tween.finished
	can_skip = true

func _setup_camera(to_introduction: bool = true):
	if to_introduction:
		camera.offset = player_camera.offset
		camera.global_position = player_camera.global_position
		camera.zoom = player_camera.zoom
		camera.make_current()
	else:
		player_camera.make_current()

func _resume() -> void:
	Engine.time_scale = prev_timescale
	
	enemy_theme.stop()
	computer_loop_sound.stop()
	scan_loop_sound.stop()
	return_sound.play()
	can_skip = false
	var _tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(control, "modulate:a", 0, 0.2)
	
	await _tween.finished
	scan.modulate.a = 0
	information.text = ""
	
	_setup_camera(false)
	get_tree().paused = false
	introductioning = false
	
	for child in control.get_children():
		if child is CanvasLayer:
			child.visible = false

func _input(_event: InputEvent) -> void:
	if !can_skip or ingame_menu.menu.visible:
		return
	if Input.is_action_just_pressed("Restart"):
		await _resume()
		if !introduction_queue.is_empty():
			introduction(introduction_queue[0])
			introduction_queue.remove_at(0)
