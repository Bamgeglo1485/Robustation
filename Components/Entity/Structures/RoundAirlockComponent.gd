class_name RoundAirlockComponent extends Component

@export var roundend: bool = true
@export var area: Area2D
@export var exit_position: Vector2
@export var start_position: Vector2
@export var effect: ColorRect
@export var light: PointLight2D
@onready var airlock: AirlockComponent = parent.get_node_or_null("AirlockComponent")
@onready var level_component: LevelComponent = scene.get_node_or_null("LevelComponent")
@onready var player: CharacterBody2D = scene.get_node_or_null("Player")
@onready var stats_text_printing: TextPrintingAnimationComponent = player.get_node_or_null("Level").get_node_or_null("LevelName").get_node_or_null("Stats").get_node_or_null("TextPrintingAnimationComponent")
var camera: Camera2D
var prev_camera: Camera2D
var roundended: bool = false
var room: int

func _ready() -> void:
	
	camera = Camera2D.new()
	add_child(camera)
	
	EventBusManager.room_end.connect(_room_end)
	
	area.set_deferred("Monitoring", false)
	if roundend:
		area.body_entered.connect(_body_enteted)
		airlock.bolt()
	else:
		var mob_mover: MobMoverComponent = player.get_node_or_null("MobMoverComponent")
		mob_mover.movement_blocked = true
		var weapon_user: WeaponUserComponent = player.get_node_or_null("WeaponUserComponent")
		weapon_user.can_attack = false
	
		player.global_position = parent.global_position + start_position
		prev_camera = get_viewport().get_camera_2d()
		camera.global_position = exit_position
		camera.zoom = prev_camera.zoom
		camera.make_current()
		var tween = create_tween()
		tween.set_parallel()
		tween.tween_property(camera, "zoom", Vector2(4.0, 4.0), 0.7)
		effect.visible = true
		tween.tween_property(effect.material, "shader_parameter/global_alpha", 1.0, 0.4)
		await tween.finished
		airlock.open()
		tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "global_position", parent.global_position + exit_position, 0.5)
		await tween.finished
		tween = create_tween()
		tween.set_parallel()
		tween.tween_property(camera, "zoom", prev_camera.zoom, 0.1)
		tween.tween_property(camera, "global_position", prev_camera.global_position, 0.1)
		tween.tween_property(effect.material, "shader_parameter/global_alpha", 0.0, 0.1)
		await tween.finished
		prev_camera.make_current()
		camera.queue_free()
		weapon_user.can_attack = true
		mob_mover.movement_blocked = false

func _body_enteted(body: Node2D) -> void:
	if body == parent or roundended:
		return
	var mob_mover: MobMoverComponent = body.get_node_or_null("MobMoverComponent")
	mob_mover.movement_blocked = true
	mob_mover.direction = Vector2.ZERO
	body.velocity = Vector2.ZERO
	var weapon_user: WeaponUserComponent = body.get_node_or_null("WeaponUserComponent")
	weapon_user.can_attack = false
	
	roundended = true
	prev_camera = get_viewport().get_camera_2d()
	camera.global_position = prev_camera.global_position
	camera.zoom = prev_camera.zoom
	camera.make_current()
	airlock.unbolt()
	airlock.open()
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(camera, "zoom", Vector2(4.0, 4.0), 2.0)
	tween.tween_property(body, "global_position", parent.global_position + start_position, 0.2)
	effect.visible = true
	tween.tween_property(effect.material, "shader_parameter/global_alpha", 1.0, 0.4)
	
	await tween.finished
	_stats()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(body, "global_position", parent.global_position + exit_position * 10, 1.0)
	
	await tween.finished
	
	airlock.bolt()

func _stats() -> void:
	if stats_text_printing:
		var difficulty: String
		match SettingsConfigSystem.difficulty:
			SettingsConfigSystem.difficulties.RPER:
				difficulty = "Roleplayer [1]"
			SettingsConfigSystem.difficulties.AGENT:
				difficulty = "Agent [2]"
			SettingsConfigSystem.difficulties.GREYTIDE:
				difficulty = "Greytide [3]"
		
		var text: String = ""
		text += "[color=crimson]Time:[/color] " + str(round(level_component.time * 10) / 10.0)
		text += "\n"
		text += "[color=crimson]Kills:[/color] " + str(level_component.kills)
		text += "\n"
		text += "[color=crimson]Difficulty: [/color]" + difficulty
		stats_text_printing.animate(text, 0.5)

func _room_end(_room: int) -> void:
	if room == _room:
		area.set_deferred("monitoring", true)
		light.enabled = true
