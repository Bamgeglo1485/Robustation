class_name CleanbotComponent extends Component

var cleaning: bool = false
var target: Node2D = null

@onready var weapon_user_component: WeaponUserComponent = parent.get_node_or_null("WeaponUserComponent")
@onready var move_to_point_component: MoveToPointComponent = get_parent().get_node_or_null("MoveToPointComponent")

var CLEANING_DISTANCE: float = 48.0

var _last_blood_pools_check: float = 0.0
var _blood_pools_cache: Array[Node2D] = []
var _blood_pool_check_interval: float = 0.5

func _process(_delta) -> void:
	_last_blood_pools_check += _delta
	
	if cleaning and target:
		_clean()
		return
	
	if cleaning and !target:
		cleaning = false
		return
	
	_find_blood_pool()

func _clean() -> void:
	var distance_to_target = parent.global_position.distance_to(target.global_position)
	if distance_to_target > CLEANING_DISTANCE:
		if move_to_point_component:
			move_to_point_component.set_point(target.global_position, 1)
		return
	
	if !weapon_user_component:
		return
	
	var weapon: Weapon = weapon_user_component.selected_weapon
	if !weapon or weapon.cooldown or weapon.swinging:
		return
	
	_clean_target(weapon)

func _clean_target(weapon: Node) -> void:
	if !is_instance_valid(target):
		target = null
		cleaning = false
		return
	
	await weapon.attack(self)
	
	if !is_instance_valid(target):
		target = null
		cleaning = false
		return
	
	target.clean_health -= 1
	_clean_visual()
	
	if target.clean_health <= 0:
		_complete_cleaning()

func _clean_visual() -> void:
	if !is_instance_valid(target):
		return
	
	var progress: float = 1.0 - target.clean_health / target.max_clean_health
	
	var start_color: Color = Color(0.705, 0.029, 0.236, 1.0)
	var end_color: Color = Color(0.0, 0.0, 1.0, 0.1)
	
	var new_color: Color = start_color.lerp(end_color, progress)
	
	var tween: Tween = create_tween()
	tween.tween_property(target, "self_modulate", new_color, 0.1)

func _complete_cleaning() -> void:
	if is_instance_valid(target):
		target.queue_free()
	
	target = null
	cleaning = false
	
	_blood_pools_cache.clear()
	_last_blood_pools_check = 0.0

func _find_blood_pool() -> void:
	if _last_blood_pools_check < _blood_pool_check_interval and !_blood_pools_cache.is_empty():
		_find_closest_pool(_blood_pools_cache)
		return
	
	_blood_pools_cache.clear()
	var all_nodes: Array[Node] = scene.get_children()
	
	for node in all_nodes:
		if is_instance_valid(node) and node.has_method("is_blood"):
			_blood_pools_cache.append(node)
	
	_last_blood_pools_check = 0.0
	
	_find_closest_pool(_blood_pools_cache)

func _find_closest_pool(pools: Array[Node2D]) -> void:
	if pools.is_empty():
		target = null
		cleaning = false
		return
	
	var closest_pool: Node2D = null
	var closest_distance: float = INF
	
	for pool in pools:
		if not is_instance_valid(pool):
			continue
		
		var distance = parent.global_position.distance_to(pool.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_pool = pool
	
	if closest_pool:
		cleaning = true
		target = closest_pool
		
		if move_to_point_component:
			move_to_point_component.set_point(target.global_position, 1)
	else:
		cleaning = false
		target = null

func get_attack_direction() -> Vector2:
	if not is_instance_valid(target):
		return Vector2.ZERO
	
	return (target.global_position - parent.global_position).normalized()

func get_attack_target():
	return null

func set_cleaning_target(new_target: Node2D) -> void:
	if is_instance_valid(new_target) and new_target.has_method("is_blood"):
		target = new_target
		cleaning = true

func stop_cleaning() -> void:
	cleaning = false
	target = null
	
	if move_to_point_component:
		move_to_point_component.stop_moving()
