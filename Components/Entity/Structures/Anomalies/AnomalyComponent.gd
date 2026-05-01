class_name AnomalyComponent extends Component

enum anomaly_states {
	IDLE,
	PULSE
}
@export var state: anomaly_states = anomaly_states.IDLE

@export_category("Stats")
@export var pulse_time: float = 8
@export var max_infecteds: int = 3

@export_category("Technical")
@export var base_sprite: Sprite2D
@export var animation_sprite: Sprite2D
@export var impulse_sprite: Sprite2D
@onready var animation_player: AnimationPlayer = parent.get_node_or_null("AnimationPlayer")
@export var pulse_lighting: Array[PointLight2D]
@export var minor_lighting: Array[PointLight2D]
@onready var reflect_component: ReflectComponent = parent.get_node_or_null("ReflectComponent")
@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")
@onready var faction_component: FactionComponent = parent.get_node_or_null("FactionComponent")
@export var pulse_sound: AudioStreamPlayer2D

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")

func _physics_process(_delta: float) -> void:
	if state == anomaly_states.PULSE:
		Input.warp_mouse(parent.get_global_transform_with_canvas().origin)

func _ready() -> void:
	for child in parent.get_children():
		if child is Sprite2D or child is PointLight2D:
			var tween: Tween = create_tween()
			tween.tween_property(child, "position", Vector2(0, 5), 1)
			tween.tween_property(child, "position", Vector2(0, -5), 1)
			tween.set_loops()
		elif child is Node2D:
			for node_child in child.get_children():
				if node_child is Sprite2D or node_child is PointLight2D:
					var tween: Tween = create_tween()
					tween.tween_property(node_child, "position", Vector2(0, 5), 1)
					tween.tween_property(node_child, "position", Vector2(0, -5), 1)
					tween.set_loops()

func pulse():
	# PULSE START
	
	if pulse_sound:
		pulse_sound.play()
	
	_toggle_lighting(true, pulse_lighting)
	_toggle_lighting(false, minor_lighting)
	state = anomaly_states.PULSE
	base_sprite.visible = false
	animation_sprite.visible = true
	animation_player.play("Opening")
	weapon_user_component.can_attack = false
	
	await animation_player.animation_finished
	
	# PULSE
	
	animation_sprite.visible = false
	impulse_sprite.visible = true
	health_component.INVINCIBLE = false
	reflect_component.melee_chance = 0
	reflect_component.projectile_chance = 0
	
	await get_tree().create_timer(pulse_time).timeout
	
	# PULSE ENDING
	
	_toggle_lighting(false, pulse_lighting)
	_toggle_lighting(true, minor_lighting)
	animation_player.play("Closing")
	animation_sprite.visible = true
	impulse_sprite.visible = false
	
	await animation_player.animation_finished
	
	# PULSE END
	
	weapon_user_component.can_attack = true
	animation_sprite.visible = false
	base_sprite.visible = true
	health_component.INVINCIBLE = true
	reflect_component.melee_chance = 1
	reflect_component.projectile_chance = 1

func _toggle_lighting(enable, list):
	var energy: float = 0.0
	
	if enable:
		energy = 16.0
	
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel()
	
	for light in list:
		tween.tween_property(light, "energy", energy, 1)
