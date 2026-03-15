class_name HealthComponent extends Component

@export var do_not_delete_after_gib: bool = false
@export var max_health: int = 100
@export var INVINCIBLE: bool = false
var base_max_health: int = max_health
@export var health: int = max_health: set = set_health, get = get_health
@export var damage_type_modifiers: Dictionary[String, float]
@export var damage_modifier: float = 1
@export var armor: float = 1 # I'm too lazy to integrate armor perk with other systems.
@export var gibbed: bool = false
@export var invinciblitiy_attack_effect: PackedScene

@export var blood_effect_scene: PackedScene
@export var blood_spurt_effect_scene: PackedScene
@export var gib_effect_scene: PackedScene

@export var ignore_time_scale: bool = false

@onready var shader: ShaderMaterial
@onready var animation_component: AnimationComponent = parent.get_node_or_null("AnimationComponent")

@export_category("Heal For Damage")
@export var heal_for_damage_multiplier: float = 0.0
@export var heal_for_damage_range: int = 64

@export_category("Delayed damage")
@export var delayed_damage_modifier: float = 1.0
var delayed_damage_timer: Timer
var delayed_damage_queue: Array = []
var current_delayed_damage: int = 0

signal health_changed(new_health)

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

func set_health(new_health: int) -> void:
	EventBusManager.health_changed.emit(parent, health, new_health)
	
	if new_health < health:
		if new_health <= 0:
			_death()
	health = clamp(new_health, 0, max_health)
	health_changed.emit(health)
	
	health_effect()

func health_effect() -> void:
	if shader:
		shader.set_shader_parameter("blood_intensity", (float(health) / float(max_health)))

func get_health() -> int:
	return health

# Наносит урон и создаёт эффекты
func take_damage(damage: int, damager: Node2D, damage_type: String = "Generic", ignore_damage_modifier: bool = false) -> void:
	if INVINCIBLE:
		if invinciblitiy_attack_effect:
			var inst: Node2D = invinciblitiy_attack_effect.instantiate()
			inst.global_position = parent.global_position
			scene.add_child(inst)
		return
	var modifier = armor * damage_modifier
	if !damage_type_modifiers.is_empty() and damage_type_modifiers.has(damage_type):
		modifier *= damage_type_modifiers[damage_type]
	if ignore_damage_modifier:
		modifier = 1
	
	var modified_damage: float = damage * damage_modifier * modifier
	health -= int(modified_damage)
	if damage > 0:
		damage_effects(damager)
	else:
		_flash(1, Color(0.0, 0.937, 0.792, 1.0))
	
	EventBusManager.damaged.emit(parent, damage, damager)
	
	if !damager:
		return
	var direction = (damager.global_position-parent.global_position)
	
	if parent.has_node("AnimationComponent"):
		parent.get_node("AnimationComponent").lean_to_direction(-direction, 4)
	if parent.has_node("TriggerOnDamageComponent"):
		parent.get_node("TriggerOnDamageComponent").trigger()
	if damager.has_node("HealthComponent") and damager != parent and damage > 0:
		var damager_health = damager.get_node("HealthComponent")
		if direction.length() <= damager_health.heal_for_damage_range:
			damager_health.set_health(damager_health.health + damage * damager_health.heal_for_damage_multiplier)

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
			if child == self or child is HealthOverlayComponent:
				continue
			if child is PlayerCamera:
				continue
			if child is CanvasLayer:
				continue
			child.queue_free()

func set_delayed_damage(damage: int, time: int) -> void:
	delayed_damage_queue.append({"damage": damage, "time": time})
	
	if !delayed_damage_timer.is_stopped():
		delayed_damage_timer.start()

func _delayed_damage_process() -> void:
	if delayed_damage_queue.is_empty():
		delayed_damage_timer.start()
		return
	
	var total_damage: int = 0
	var new_queue: Array = []
	
	for task in delayed_damage_queue:
		total_damage += task.damage
		task.time -= 1
		
		if task.time > 0:
			new_queue.append(task)
	
	delayed_damage_queue = new_queue
	
	if total_damage > 0:
		@warning_ignore("narrowing_conversion")
		take_damage(total_damage * delayed_damage_modifier, null)
		_flash(0.5, Color(0.0, 0.694, 0.508, 0.188))
	
	delayed_damage_timer.start()
