class_name HealthComponent extends Component

@export var hitstop_on_death: bool = false
@export var do_not_delete_after_gib: bool = false
@export var max_health: float = 100 : get = get_max_health
@export var INVINCIBLE: bool = false
var base_max_health: float = max_health
@export var health: float = max_health: set = set_health, get = get_health
@export var damage_type_modifiers: Dictionary[String, float]
@export var armor: float = 1 # I'm too lazy to integrate armor perk with other systems.
@export var gibbed: bool = false
@export var invinciblitiy_attack_effect: PackedScene
@export var invinciblitiy_attack_sound: AudioStreamPlayer2D
@export var healing_from_organs_modifier: float = 1.0

## Unremovable damage that affects maximum health.
@export var hard_damage: float = 0.0

@export var blood_effect_scene: PackedScene
@export var blood_spurt_effect_scene: PackedScene
@export var gib_effect_scene: PackedScene

@export var ignore_time_scale: bool = false

@onready var shader: ShaderMaterial
@onready var animation_component: AnimationComponent = parent.get_node_or_null("AnimationComponent")
@onready var trigger_on_damage_component: TriggerOnDamageComponent = parent.get_node_or_null("TriggerOnDamageComponent")

@export_category("Delayed damage")
var delayed_damage_timer: Timer
var delayed_damage_queue: Array = []
var current_delayed_damage: float = 0

signal health_changed(new_health)
signal hard_damage_changed(new_damage)

@export_category("Modifier")
@export var max_health_multipliers: Dictionary
@export var max_health_multiplier: float = 1.0
@export var max_health_addendums: Dictionary
@export var max_health_addendum: float = 0.0

@export var damage_multipliers: Dictionary
@export var damage_multiplier: float = 1.0

@export var delayed_damage_multipliers: Dictionary
@export var delayed_damage_multiplier: float = 1.0

func _ready():
	delayed_damage_timer = Timer.new()
	delayed_damage_timer.wait_time = 1.0
	delayed_damage_timer.one_shot = true
	delayed_damage_timer.timeout.connect(_delayed_damage_process)
	delayed_damage_timer.ignore_time_scale = ignore_time_scale
	add_child(delayed_damage_timer)
	delayed_damage_timer.start()
	
	health = max_health
	if parent.has_node("UniqueShaderComponent"):
		await parent.get_node("UniqueShaderComponent").ready
	shader = parent.material

func set_health(new_health: float) -> void:
	EventBusManager.health_changed.emit(parent, health, new_health)
	
	if new_health < health:
		if new_health <= 0:
			_death()
	health = clamp(new_health, 0, max_health - hard_damage)
	health_changed.emit(health)
	
	health_effect()

func health_effect() -> void:
	if shader:
		shader.set_shader_parameter("blood_intensity", (float(health) / float(max_health)))

func get_health() -> float:
	return health

# Наносит урон и создаёт эффекты
func take_damage(damage: float, damager: Node2D, damage_type: String = "Generic", ignore_damage_modifier: bool = false) -> void:
	if INVINCIBLE:
		EventBusManager.invincibility_damage_block.emit(parent)
		if damage > 5:
			invincibility_effects()
		return
	var modifier: float = damage_multiplier
	if !damage_type_modifiers.is_empty() and damage_type_modifiers.has(damage_type):
		modifier *= damage_type_modifiers[damage_type]
	if ignore_damage_modifier:
		modifier = 1.0
	
	var modified_damage: float = damage * modifier
	health -= modified_damage
	if modified_damage > 0:
		damage_effects(damager)
	else:
		_flash(1, Color(0.0, 0.937, 0.792, 1.0))
	
	EventBusManager.damaged.emit(parent, modified_damage, damager)
	
	if !damager:
		return
	var direction = (damager.global_position-parent.global_position)
	
	if animation_component:
		animation_component.lean_to_direction(-direction, 4)
	if trigger_on_damage_component:
		trigger_on_damage_component.trigger()

func invincibility_effects() -> void:
		if invinciblitiy_attack_effect:
			var inst: Node2D = invinciblitiy_attack_effect.instantiate()
			inst.global_position = parent.global_position
			scene.add_child(inst)
			EventBusManager.request_impact_frame.emit(0, 0, true, false)
			if invinciblitiy_attack_sound:
				invinciblitiy_attack_sound.play()
		return

func damage_effects(damager) -> void:
	if !parent or !damager:
		return
	
	var attack_direction = (parent.global_position - damager.global_position).normalized()
	_flash()
	
	if blood_effect_scene:
		var blood_effect: Node = blood_effect_scene.instantiate()
		blood_effect.global_position = parent.global_position
		scene.add_child(blood_effect)
		blood_effect.rotation = attack_direction.angle()
	
	if blood_spurt_effect_scene:
		var blood_spurt_effect: Node = blood_spurt_effect_scene.instantiate()
		blood_spurt_effect.global_position = parent.global_position
		blood_spurt_effect.emitting = true
		scene.add_child(blood_spurt_effect)

func _flash(
	speed_multiplier: float = 1,
	color: Color = Color(0.7, 0.0, 0.3, 0.729)
	) -> void:
	
	if animation_component:
		animation_component.flash(speed_multiplier, color)

func _death() -> void:
	if gibbed:
		return
	gibbed = true
	if gib_effect_scene:
		var gib_effect: Node = gib_effect_scene.instantiate()
		gib_effect.global_position = parent.global_position
		scene.add_child.call_deferred(gib_effect)
	
	EventBusManager.gibbed.emit(parent)
	if !do_not_delete_after_gib:
		parent.call_deferred("queue_free")
	else:
		for child in parent.get_children():
			if !is_instance_valid(child) or child == self or child is HealthOverlayComponent:
				continue
			if child is PlayerCamera or child is CanvasLayer:
				continue
			if child is MusicComponent:
				var pitch_tween = create_tween()
				pitch_tween.tween_property(child.main_music_player, "pitch_scale", 0.1, 1.5)
				continue
			if child is BaseAbilityComponent:
				await child.disable_ability()
			child.queue_free()
	if hitstop_on_death:
		EventBusManager.request_impact_frame.emit(0.5, 0, true, true)

func set_delayed_damage(damage: float, time: float) -> void:
	delayed_damage_queue.append({"damage": damage, "time": time})
	
	if !delayed_damage_timer.is_stopped():
		delayed_damage_timer.start()

func _delayed_damage_process() -> void:
	if delayed_damage_queue.is_empty():
		delayed_damage_timer.start()
		return
	
	var total_damage: float = 0
	var new_queue: Array = []
	
	for task in delayed_damage_queue:
		total_damage += task.damage
		task.time -= 1
		
		if task.time > 0:
			new_queue.append(task)
	
	delayed_damage_queue = new_queue
	
	if total_damage > 0:
		@warning_ignore("narrowing_conversion")
		take_damage(total_damage * delayed_damage_multiplier, null)
		_flash(0.5, Color(0.0, 0.694, 0.508, 0.188))
	
	delayed_damage_timer.start()

func get_max_health() -> float:
	return max_health * max_health_multiplier + max_health_addendum

func set_hard_damage(new_value: float) -> void:
	hard_damage = clamp(new_value, 0, max_health)
	hard_damage_changed.emit(hard_damage)
	set_health(clamp(health, 0, max_health - hard_damage))
