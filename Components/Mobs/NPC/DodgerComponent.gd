class_name DodgerComponent extends Component

@onready var navigation: NavigationAgent2D = parent.get_node_or_null("NavigationAgent")
@onready var mob_mover: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
@onready var faction: FactionComponent = parent.get_node_or_null("FactionComponent")

@export var modify_dodge_force_by_difficulty: bool = true

@export var dodge_melee: bool = false
@export var move_priority: int = 5
@export var dash_force: float = 2000.0
@export var dash_stop_speed: float = 1930.0
@export var dodge_sound: AudioStreamPlayer2D

@export var max_stamina: int = 2
@onready var stamina: int = max_stamina
@export var stamina_recovery_delay: float = 2
var recovery_timer: Timer

func _ready() -> void:
	EventBusManager.projectile_shoot.connect(_on_shoot)
	if dodge_melee:
		EventBusManager.try_melee_attack.connect(_on_melee)
	
	if max_stamina > 0:
		recovery_timer = Timer.new()
		add_child(recovery_timer)
		recovery_timer.wait_time = stamina_recovery_delay
		recovery_timer.one_shot = true
		recovery_timer.timeout.connect(_stamina_recovery)
	
	if modify_dodge_force_by_difficulty:
		match SettingsConfigSystem.difficulty:
			SettingsConfigSystem.difficulties.RPER:
				dash_force *= 0.8
			SettingsConfigSystem.difficulties.AGENT:
				dash_force *= 1.0
			SettingsConfigSystem.difficulties.GREYTIDE:
				max_stamina *= 2
				stamina *= 2
				dash_force *= 1.6
				dash_stop_speed *= 1.7
				dodge_melee = true

func _on_melee(emitter: Node2D, weapon: Weapon) -> void:
	if !_check(emitter):
		return
	if (parent.global_position - emitter.global_position).length() > weapon.attack_range * 1.25:
		return
	_dodge()

func _on_shoot(emitter: Node2D, _weapon: Weapon, direction: Vector2, _projectile: Node2D) -> void:
	if !_check(emitter):
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
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.exclude = [emitter]
		
		var result = space_state.intersect_ray(query)
		
		if !result.is_empty():
			hit_detected = true
			break
	
	if !hit_detected:
		return
	
	_dodge()

func _check(emitter) -> bool:
	if stamina <= 0 and max_stamina > 0:
		return false
	if !emitter or !parent:
		return false
	if !faction:
		push_error(("DODGER " + str(parent) + "HAS NOT FACTION COMPONENT!"))
	var emitter_faction: FactionComponent = emitter.get_node_or_null("FactionComponent")
	if faction.faction == emitter_faction.faction:
		return false
	if mob_mover.fallen:
		return false
	return true

func _dodge() -> void:
	var dodge_direction: Vector2 = Vector2(30, 30).rotated(0.3)
	randomize()
	if randf() >= 0.5:
		dodge_direction = dodge_direction.rotated(deg_to_rad(180))
	
	mob_mover.throw(dodge_direction, dash_force, parent, dash_stop_speed, false, true, false, 1000)
	
	if dodge_sound:
		dodge_sound.play()
	if max_stamina > 0:
		stamina -= 1
		recovery_timer.start()

func _stamina_recovery():
	recovery_timer.start()
	stamina += 1
