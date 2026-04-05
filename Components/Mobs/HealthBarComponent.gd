class_name HealthBarComponent extends Component

@onready var health_component: HealthComponent = owner.get_node_or_null("HealthComponent")
@onready var player: CharacterBody2D = scene.get_node_or_null("Player")
@onready var player_controller: BossHealthBarsControllerComponent = player.get_node_or_null("BossHealthBarsControllerComponent")
var tween: Tween
@export var on_spawn: bool = false

func _ready() -> void:
	if !on_spawn:
		return
	if player_controller:
		player_controller.add_health_bar(parent)
	parent.visible = true
	
	parent.modulate = Color(0.0, 0.0, 0.0, 0.0)
	var _tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(parent, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	_shake(0.8)
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		parent.max_value = health_component.max_health
		tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(parent, "value", health_component.health, 1)

func _on_health_changed(new_health) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(parent, "value", new_health, 0.3)
	_shake()
	if new_health <= 0:
		_shake(0.5)
		var _tween: Tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(parent, "modulate", Color(0.0, 0.0, 0.0, 0.0), 1)
		await _tween.finished
		parent.queue_free()

func _shake(delay: float = 0.2):
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	var vector_1: Vector2 = Vector2(randf_range(-10,10), randf_range(-10,10))
	var vector_2: Vector2 = Vector2(randf_range(-10,10), randf_range(-10,10))
	var delay_per_tween: float = delay / 4.0
	_tween.tween_property(parent, "position", parent.position + vector_1, delay_per_tween)
	_tween.tween_property(parent, "position", parent.position + -vector_1, delay_per_tween)
	_tween.tween_property(parent, "position", parent.position + vector_2, delay_per_tween)
	_tween.tween_property(parent, "position", parent.position + -vector_2, delay_per_tween)
	_tween.tween_property(parent, "position", parent.position, 0.1)
