class_name ChainAttacksComponent extends Component

@export var ray_line: Line2D

@export var max_chain_radius: int = 160
@export var max_chains: int = 6
var chains: int = 0

@export var tween_speed: float = 0.2
@export var damage: int = 10
@export var stamina_damage: int = 0
@export var disappear_speed: float = 0.4
@export var after_delete_lifetime: float = 2

@export var drop_enemy_delay: float = 0.0
@export var throw_speed: float = 0

var shooter: PhysicsBody2D
var faction: String

func _ready() -> void:
	ray_line.clear_points()
	ray_line.add_point(Vector2(0,0))
	fire()
	_ray_appear_effects()
	await tree.create_timer(disappear_speed).timeout
	_ray_disappear_effects()
	await tree.create_timer(after_delete_lifetime + tween_speed).timeout
	parent.queue_free()

func fire() -> void:
	var mobs: Array[Node2D] = _get_nearby_mobs(parent.global_position)
	if mobs.is_empty():
		return
	
	for mob in mobs:
		if chains >= max_chains:
			break
		chains += 1
		ray_line.add_point(ray_line.to_local(mob.global_position))
		
		if damage != 0:
			var target_health: HealthComponent = mob.get_node_or_null("HealthComponent")
			if target_health and shooter:
				var total_damage: float = damage 
				target_health.take_damage(int(total_damage), shooter, "Hitscan")
		
		if stamina_damage != 0:
			var target_stamina: StaminaComponent = mob.get_node_or_null("StaminaComponent")
			if target_stamina:
				target_stamina.take_stamina_damage(stamina_damage, shooter)
		
		if drop_enemy_delay != 0 or throw_speed != 0:
			var target_mover: MobMoverComponent = mob.get_node_or_null("MobMoverComponent")
			if target_mover:
				if drop_enemy_delay != 0:
					target_mover.drop(drop_enemy_delay)
				if throw_speed != 0:
					target_mover.throw(mob.global_position - shooter.global_position, throw_speed, shooter, 10, true, true)

func _get_nearby_mobs(position: Vector2) -> Array[Node2D]:
	var mobs: Array[Node] = get_tree().get_nodes_in_group("Mob")
	var valid_mobs: Array[Node2D] = []
	
	var last_mob_position: Vector2 = position
	
	for mob in mobs:
		if !is_instance_valid(mob):
			continue
		
		if faction:
			var faction_comp: FactionComponent = mob.get_node_or_null("FactionComponent")
			if faction_comp and faction_comp.faction == faction:
				continue
		
		var distance: float = (mob.global_position - last_mob_position).length()
		if distance <= max_chain_radius:
			valid_mobs.append(mob)
			last_mob_position = mob.global_position
	
	valid_mobs.sort_custom(func(a, b):
		var dist_a = (a.global_position - position).length_squared()
		var dist_b = (b.global_position - position).length_squared()
		return dist_a < dist_b)
	
	return valid_mobs

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
