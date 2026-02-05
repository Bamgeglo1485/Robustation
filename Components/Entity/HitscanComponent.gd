class_name HitscanComponent extends Component

@export var ray_line: Line2D

@export var hit_sound: AudioStreamPlayer2D
@export var hit_effect: GPUParticles2D

@export var tween_speed: float = 0.2
@export var damage: int = 10
@export var lifetime_speed: float = 0.1

@export var drop_enemy_delay: float = 0.0

var shooter: CharacterBody2D
var direction: float
var damage_modifier: float = 1
var deleted: bool = false

@export var explosion_scene: PackedScene

func _ready() -> void:
	if parent is not RayCast2D:
		return
	
	if shooter:
		parent.add_exception(shooter)
	
	await get_tree().physics_frame
	parent.force_raycast_update()
	
	_ray_appear_effects()
	damage_collider()
	parent.enabled = false
	
	await get_tree().create_timer(lifetime_speed).timeout
	_ray_disappear_effects()
	await get_tree().create_timer(tween_speed).timeout
	parent.queue_free()

func damage_collider():
	var collider: Object = parent.get_collider()
	if !collider:
		return
	
	if collider.has_node("HealthComponent"):
		collider.get_node("HealthComponent").take_damage(damage * damage_modifier, shooter)
	if collider.has_node("MobMoverComponent"):
		if drop_enemy_delay != 0:
			collider.get_node("MobMoverComponent").drop(drop_enemy_delay)
	if explosion_scene:
		var instance = explosion_scene.instantiate()
		scene.call_deferred("add_child", instance)
		instance.global_position = parent.global_position
		instance.source = shooter

func _ray_appear_effects():
	if ray_line:
		var target_position: Vector2 = parent.target_position
		var collider: Object = parent.get_collider()
		if collider:
			target_position = ray_line.to_local(collider.global_position)
		ray_line.points[1] = target_position
		
		var target_width: float = ray_line.width
		ray_line.width = 0
		
		var _width_tween: Tween = create_tween()
		_width_tween.tween_property(ray_line, "width", target_width, tween_speed)

func _ray_disappear_effects():
	if ray_line:
		var _width_tween: Tween = create_tween()
		_width_tween.tween_property(ray_line, "width", 0, tween_speed)
