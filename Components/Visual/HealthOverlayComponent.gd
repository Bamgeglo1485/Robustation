class_name HealthOverlayComponent extends Component

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
@export var overlay: ColorRect
@export var curve: Curve
var material: ShaderMaterial

@export var death_effect: ColorRect
@export var death_screen: PackedScene
@export var death_screen_parent: CanvasLayer
@export var death_screen_wait_time: float = 1.25
var dead: bool = false

func _ready() -> void:
	if health_component and overlay:
		health_component.health_changed.connect(_on_health_changed)
		material = overlay.material
		material.set_shader_parameter("intensity", 0)

func _on_health_changed(health) -> void:
	if !material:
		return
	
	if health <= 0 and !dead:
		dead = true
		if death_effect:
			var _effect_tween = create_tween()
			_effect_tween.set_parallel()
			_effect_tween.tween_property(death_effect.material, "shader_parameter/bg_color", Color(0.0, 0.0, 0.0, 1.0), 1.5)
			_effect_tween.tween_property(death_effect.material, "shader_parameter/fg_color", Color(1.0, 1.0, 1.0, 1.0), 1.5)
		EventBusManager.change_player.emit(null, 0)
		EventBusManager.player_death.emit()
		if death_screen:
			await get_tree().create_timer(death_screen_wait_time).timeout
			var inst = death_screen.instantiate()
			death_screen_parent.add_child(inst)
		return
	
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	
	var max_health: int = health_component.max_health
	
	var health_percent: float = float(health) / float(max_health)
	var intensity: float
	
	if curve:
		intensity = curve.sample(1.0 - health_percent)
	else:
		if health < float(max_health) * 0.5:
			intensity = 1 - health_percent
		else:
			intensity = 0
	
	_tween.tween_property(material, "shader_parameter/intensity", intensity, 0.5)
