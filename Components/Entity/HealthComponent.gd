class_name HealthComponent extends Component

@export var max_health: int = 100
@export var INVINCIBLE: bool = false
@export var health: int = max_health: set = set_health, get = get_health
@export var damage_modifier: float = 1
@export var gibbed: bool = false
@export var invinciblitiy_attack_effect: PackedScene

@export var blood_effect_scene: PackedScene
@export var blood_spurt_effect_scene: PackedScene
@export var gib_effect_scene: PackedScene

@export var ignore_time_scale: bool = false

@onready var shader: ShaderMaterial

@export_category("Heal For Damage")
@export var heal_for_damage_multiplier: float = 0
@export var heal_for_damage_range: int = 64

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

func set_health(new_health: int):
	if shader == null and parent != null and parent.material != null:
		shader = parent.material
	
	EventBusManager.health_changed.emit(parent, health, new_health)
	
	if new_health < health:
		if new_health <= 0:
			_death()
	health = clamp(new_health, 0, max_health)
	health_changed.emit(health)
	
	health_effect()

func health_effect():
	if shader != null:
		shader.set_shader_parameter("blood_intensity", (float(health) / float(max_health)))

func get_health():
	return health

# Наносит урон и создаёт эффекты
func take_damage(damage: int, damager):
	if INVINCIBLE == true:
		if invinciblitiy_attack_effect != null:
			var inst = invinciblitiy_attack_effect.instantiate()
			scene.add_child(inst)
			inst.global_position = parent.global_position
		return
	
	var modified_damage = damage * damage_modifier
	health -= int(modified_damage)
	if damage > 0:
		damage_effects(damager)
	
	EventBusManager.damaged.emit(parent, damage, damager)
	
	if damager == null:
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

func damage_effects(damager):
	if parent == null or damager == null:
		return
	
	var attack_direction = (parent.global_position - damager.global_position).normalized()
	_flash()
	
	if blood_effect_scene != null:
		var blood_effect = blood_effect_scene.instantiate()
		scene.add_child(blood_effect)
		blood_effect.global_position = parent.global_position
		blood_effect.rotation = attack_direction.angle()
	
	if blood_spurt_effect_scene != null:
		var blood_spurt_effect = blood_spurt_effect_scene.instantiate()
		scene.add_child(blood_spurt_effect)
		blood_spurt_effect.emitting = true
		blood_spurt_effect.global_position = parent.global_position

func _flash(speed_multiplier: float = 1, color: Color = Color(0.7, 0.0, 0.3, 1.0)):
	if shader != null and shader.get_shader_parameter("flash_color"):
		var _tween = create_tween()
		_tween.tween_property(shader, "shader_parameter/flash_color", color, 0.1 * speed_multiplier)
		_tween.tween_property(shader, "shader_parameter/flash_color", Color(0.7, 0.0, 0.3, 0.0), 0.2 * speed_multiplier)

func _death():
	if gibbed == true:
		return
	gibbed = true
	if gib_effect_scene != null:
		var gib_effect = gib_effect_scene.instantiate()
		scene.add_child.call_deferred(gib_effect)
		gib_effect.global_position = parent.global_position
	
	parent.queue_free()
	
	EventBusManager.gibbed.emit(parent)

func set_delayed_damage(damage: int, time: int):
	delayed_damage_queue.append({"damage": damage, "time": time})
	
	if not delayed_damage_timer.is_stopped():
		delayed_damage_timer.start()

func _delayed_damage_process():
	if delayed_damage_queue.is_empty():
		delayed_damage_timer.start()
		return
	
	var total_damage = 0
	var new_queue = []
	
	for task in delayed_damage_queue:
		total_damage += task.damage
		task.time -= 1
		
		if task.time > 0:
			new_queue.append(task)
	
	delayed_damage_queue = new_queue
	
	if total_damage > 0:
		take_damage(total_damage, null)
		_flash(0.3, Color(0.0, 0.694, 0.508, 0.188))
	
	delayed_damage_timer.start()
