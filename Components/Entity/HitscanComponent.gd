class_name HitscanComponent extends Component

@export var ray_line: Line2D

@export var hit_effect: PackedScene

@export var tween_speed: float = 0.2
@export var damage: int = 10
@export var stamina_damage: int = 0
@export var disappear_speed: float = 0.1
@export var after_delete_lifetime: float = 2

@export var delayed_damage: float = 2
@export var delayed_damage_delay: float = 0

@export var drop_enemy_delay: float = 0.0
@export var throw_speed: float = 0

@export var max_bounces: int = 0
var bounces: int = 0

@export var max_penetrations: int = 0
var penetrations: int = 0

var last_target

var shooter: PhysicsBody2D
var direction: Vector2 = Vector2.RIGHT
var damage_modifier: float = 1
var deleted: bool = false

@export var explosion_scene: PackedScene
@export var chain_scene: PackedScene

@export_category("MarkOfDeath")
@export var mark_delay: float = 0.0
@export var mark_heal: float = 0.4
@export var mark_damage: float = 1.0
@export var mark_hard_damage: float = 0.3

@export_category("ModifyByRange")
@export var modify_by_range_base_range: int = 0
@export var modify_by_range_min_value: float = 0.3
@export var modify_by_range_max_value: float = 2.5

func _ready() -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	
	ray_line.clear_points()
	ray_line.add_point(Vector2(0,0))
	ray_line.global_position = parent.global_position
	fire()
	_ray_appear_effects()
	await tree.create_timer(disappear_speed).timeout
	_ray_disappear_effects()
	await tree.create_timer(after_delete_lifetime + tween_speed).timeout
	parent.queue_free()

func _physics_process(_delta: float) -> void:
	if ray_line.points.size() >= 2:
		ray_line.points[0] -= ray_line.points[1].normalized() * 3

func fire() -> void:
	if parent is not RayCast2D:
		return
	
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	
	if shooter:
		parent.clear_exceptions()
		parent.add_exception(shooter)
		if last_target:
			parent.add_exception(last_target)
	
	parent.target_position = direction * 2000
	await get_tree().physics_frame
	parent.force_raycast_update()
	
	var collision_point: Vector2 = parent.get_collision_point()
	
	if collision_point == Vector2.ZERO:
		collision_point = parent.global_position + direction * 2000
	
	var target_position: Vector2 = ray_line.to_local(collision_point)
	ray_line.add_point(target_position)
	
	var collider = parent.get_collider()
	if collider:
		damage_collider(collider)

func damage_collider(collider: Node2D) -> void:
	var collision_point: Vector2 = parent.get_collision_point()
	var collision_normal: Vector2 = parent.get_collision_normal()
	
	if collision_point == Vector2.ZERO:
		return
	
	if collider and collider is Area2D:
		collider = collider.get_parent()
	if !collider:
		return
	var projectile_comp: ProjectileComponent = collider.get_node_or_null("ProjectileComponent")
	if projectile_comp:
		if projectile_comp.can_parry_weapon:
			var nearest_enemy = projectile_comp._get_nearest_enemy()
			if !nearest_enemy:
				direction = -direction
			else:
				direction = nearest_enemy.global_position - parent.global_position
			@warning_ignore("narrowing_conversion")
			damage *= projectile_comp.can_parry_weapon.parry_force
			fire()
		else:
			last_target = collider
			fire()
		return
	
	if collider is not TileMapLayer:
		last_target = collider
	
	if mark_delay != 0:
		var mark_comp: MarkOfDeathComponent = collider.get_node_or_null("MarkOfDeathComponent")
		if mark_comp:
			mark_comp.set_mark(mark_delay, mark_heal, mark_damage, mark_hard_damage)
	
	if damage != 0:
		var target_health: HealthComponent = collider.get_node_or_null("HealthComponent")
		if target_health and shooter:
			var total_damage: float = damage
			if modify_by_range_base_range != 0:
				var distance: float = (shooter.global_position - collider.global_position).length()
				total_damage *= clamp(distance / modify_by_range_base_range, modify_by_range_min_value, modify_by_range_max_value) 
			target_health.take_damage(int(total_damage * damage_modifier), shooter, "Hitscan")
			if delayed_damage != 0 and delayed_damage_delay != 0:
				target_health.set_delayed_damage(delayed_damage * damage_modifier, delayed_damage_delay)
	
	if stamina_damage != 0:
		var target_stamina: StaminaComponent = collider.get_node_or_null("StaminaComponent")
		if target_stamina:
			target_stamina.take_stamina_damage(stamina_damage, shooter)
	
	if drop_enemy_delay != 0 or throw_speed != 0:
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
	
	if chain_scene and collider:
		var inst: Node2D = chain_scene.instantiate()
		inst.global_position = collision_point
		var chain_comp: ChainAttacksComponent = inst.get_node_or_null("ChainAttacksComponent")
		if chain_comp:
			chain_comp.shooter = shooter
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
		
		if collision_normal != Vector2.ZERO:
			direction = direction.bounce(collision_normal)
		else:
			direction = -direction
		
		parent.global_position = collision_point + direction * 5
		
		fire()
		return
	elif penetrations < max_penetrations:
		penetrations += 1
		parent.global_position = collision_point + direction * 5
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
		
