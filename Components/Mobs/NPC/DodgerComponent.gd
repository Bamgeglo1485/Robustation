class_name DodgerComponent extends Component

@onready var navigation: NavigationAgent2D = parent.get_node_or_null("NavigationAgent")
@onready var mob_mover: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
@onready var faction: FactionComponent = parent.get_node_or_null("FactionComponent")

@export var move_priority: int = 5
@export var dash_force: float = 600.0
@export var dash_stop_speed: float = 500.0

@export var max_stamina: int = 2
var stamina: int = max_stamina
@export var stamina_recovery_delay: float = 2
var recovery_timer: Timer

func _ready() -> void:
	EventBusManager.projectile_shoot.connect(_on_shoot)
	
	recovery_timer = Timer.new()
	add_child(recovery_timer)
	recovery_timer.wait_time = stamina_recovery_delay
	recovery_timer.one_shot = true
	recovery_timer.timeout.connect(_stamina_recovery)
	
func _on_shoot(emitter: Node2D, _weapon: Weapon, direction: Vector2, _projectile: Node2D) -> void:
	if stamina <= 0:
		return
	if !emitter or !owner:
		return
	if !faction:
		push_error(("DODGER " + str(parent) + "HAS NOT FACTION COMPONENT!"))
	var emitter_faction: FactionComponent = emitter.get_node_or_null("FactionComponent")
	if faction.faction == emitter_faction.faction:
		return
	
	if mob_mover.fallen:
		return
	
	await get_tree().physics_frame
	
	var space_state = parent.get_world_2d().direct_space_state
	if !space_state:
		return
	
	var ray_start: Vector2 = emitter.global_position
	var ray_length: float = 500
	var deviation_angle: float = deg_to_rad(5)
	
	var directions: Array[Vector2] = [
		direction, 
		direction.rotated(deviation_angle),
		direction.rotated(-deviation_angle)]
	
	var hit_detected: bool = false
	
	for ray_direction in directions:
		var ray_end: Vector2 = ray_start + ray_direction * ray_length
		
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
		query.collision_mask = parent.collision_layer
		query.collide_with_areas = true
		
		var result = space_state.intersect_ray(query)
		
		if !result.is_empty() and result.collider == parent:
			hit_detected = true
			break
	
	if !hit_detected:
		return
	
	var dodge_direction: Vector2 = Vector2(30, 30).rotated(0.3)
	randomize()
	if randf() >= 0.5:
		dodge_direction = dodge_direction.rotated(deg_to_rad(180))
	
	stamina -= 1
	recovery_timer.start()
	mob_mover.throw(dodge_direction, dash_force, parent, dash_stop_speed, false, true, true)

func _stamina_recovery():
	stamina += 1
