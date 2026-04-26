class_name HealthBarComponent extends Component

@onready var health_component: HealthComponent = owner.get_node_or_null("HealthComponent")
var player: CharacterBody2D
var player_controller: BossHealthBarsControllerComponent
var tween: Tween
@export var show_hard_damage: bool = false
@export var on_spawn: bool = false
@export var dont_add_to_player: bool = false
@export var shake_modifier: float = 1.0
@export var label: Label

@onready var material: ShaderMaterial = parent.get("material")

func _ready() -> void:
	if !health_component:
		return
	
	if scene:
		player = scene.get_node_or_null("Player")
	
	if !on_spawn or !player:
		return
	
	if !dont_add_to_player:
		player_controller = player.get_node_or_null("BossHealthBarsControllerComponent")
		if player_controller:
			player_controller.add_health_bar(parent)
	
	parent.visible = true
	parent.max_value = 1.0
	
	if label:
		label.text = str(health_component.max_health)
	
	if show_hard_damage:
		health_component.hard_damage_changed.connect(_on_hard_damage_changed)
		health_component.health_changed.connect(_on_health_changed)
		
		parent.value = health_component.hard_damage / health_component.max_health
		
		if label:
			label.text = str(health_component.hard_damage)
		return
	
	parent.modulate = Color(0.0, 0.0, 0.0, 0.0)
	var _tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(parent, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	_shake(0.8)
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(parent, "value", health_component.health / health_component.max_health, 1)

func _on_health_changed(new_health) -> void:
	if show_hard_damage:
		return
	
	if tween:
		tween.kill()
	if label:
		label.text = str(round(new_health * 10) / 10.0)
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(parent, "value", new_health / health_component.max_health, 0.3)
	_shake()
	if new_health <= 0:
		_shake(0.5)
		var _tween: Tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(parent, "modulate", Color(0.0, 0.0, 0.0, 0.0), 1)
		await _tween.finished
		parent.queue_free()

func _on_hard_damage_changed(new_hard_damage) -> void:
	if tween:
		tween.kill()
	if label:
		label.text = str(round(new_hard_damage * 10) / 10.0)
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(parent, "value", new_hard_damage / health_component.max_health, 0.3)
	_shake()

func _shake(delay: float = 0.2):
	if shake_modifier == 0.0:
		return
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(material, "shader_parameter/amplitude", 0.5 * shake_modifier, delay / 2)
	_tween.tween_property(material, "shader_parameter/amplitude", 0.0, delay / 2)
