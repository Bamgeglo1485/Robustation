class_name HitscanComponent extends Component

@export var ray_line: Line2D

@export var hit_effect: PackedScene

@export var tween_speed: float = 0.2
@export var damage: int = 10
@export var disappear_speed: float = 0.1
@export var after_delete_lifetime: float = 2

@export var drop_enemy_delay: float = 0.0
@export var throw_speed: float = 0

@export var max_bounces: int = 0
var bounces: int = 0

@export var max_penetrations: int = 0
var penetrations: int = 0

var last_target: Node2D

var shooter: CharacterBody2D
var direction: float
var damage_modifier: float = 1
var deleted: bool = false

@export var explosion_scene: PackedScene

@export_category("ModifyByRange")
@export var modify_by_range_base_range: int = 0
@export var modify_by_range_min_value: float = 0.3
@export var modify_by_range_max_value: float = 2.5

func _ready() -> void:
	ray_line.clear_points()
	ray_line.add_point(Vector2(0,0))
	ray_line.global_position = parent.global_position
	fire()
	_ray_appear_effects()
	await get_tree().create_timer(disappear_speed).timeout
	_ray_disappear_effects()
	await get_tree().create_timer(after_delete_lifetime + tween_speed).timeout
	parent.queue_free()

func _physics_process(_delta: float) -> void:
	if ray_line.points.size() >= 2:
		ray_line.points[0] -= ray_line.points[1].normalized() * 3

func fire() -> void:
	if parent is not RayCast2D:
		return
	
	if shooter:
		parent.clear_exceptions()
		parent.add_exception(shooter)
		if last_target:
			parent.add_exception(last_target)
	
	parent.target_position = Vector2.from_angle(direction) * 1000
	await get_tree().physics_frame
	parent.force_raycast_update()
	
	var target_position: Vector2 = ray_line.to_local(parent.get_collision_point())
	ray_line.add_point(target_position)
	
	damage_collider()

func damage_collider() -> void:
	var collider: Node2D = parent.get_collider()
	var collision_point: Vector2 = parent.get_collision_point()
	var collision_normal: Vector2 = parent.get_collision_normal()
	if collider and collider is Area2D:
		collider = collider.get_parent()
	if !collider:
		return
	
	if collider is not TileMapLayer:
		last_target = collider
	
	var target_health: HealthComponent = collider.get_node_or_null("HealthComponent")
	if target_health and shooter:
		@warning_ignore("narrowing_conversion")
		var total_damage: int = damage
		if modify_by_range_base_range != 0:
			var distance: float = (shooter.global_position - collider.global_position).length()
			total_damage *= clamp(distance/modify_by_range_base_range, modify_by_range_min_value, modify_by_range_max_value) 
		@warning_ignore("narrowing_conversion")
		target_health.take_damage(total_damage * damage_modifier, shooter, "Hitscan")
	var target_mover: MobMoverComponent = collider.get_node_or_null("MobMoverComponent")
	if target_mover:
		if drop_enemy_delay != 0:
			target_mover.drop(drop_enemy_delay)
		if throw_speed != 0:
			target_mover.throw(collider.global_position - shooter.global_position, throw_speed, shooter, 10, true, true)
	if explosion_scene and collider:
		var inst: Node2D = explosion_scene.instantiate()
		inst.global_position = collision_point
		inst.source = shooter
		scene.add_child(inst)
	if hit_effect and collider:
		var inst: Node2D = hit_effect.instantiate()
		inst.global_position = collision_point
		scene.add_child(inst)
	if bounces < max_bounces and (collider is TileMapLayer or collider is TileMap):
		bounces += 1
		
		if hit_effect:
			var inst: Node2D = hit_effect.instantiate()
			inst.global_position = collision_point
			scene.add_child(inst)
		
		var incoming_dir = Vector2.from_angle(direction)
		var bounce_dir = incoming_dir.bounce(collision_normal)
		
		direction = bounce_dir.angle()
		parent.global_position = collision_point
		
		fire()
		return
	elif penetrations < max_penetrations:
		penetrations += 1
		fire()

func _ray_appear_effects() -> void:
	if !ray_line:
		return
	
	var _tween: Tween = create_tween()
	_tween.tween_property(ray_line, "width", ray_line.width, tween_speed)
	ray_line.width = 0

func _ray_disappear_effects() -> void:
	if ray_line:
		var _width_tween: Tween = create_tween()
		_width_tween.set_trans(Tween.TRANS_BACK)
		_width_tween.set_ease(Tween.EASE_OUT)
		_width_tween.tween_property(ray_line, "width", 0, tween_speed)
