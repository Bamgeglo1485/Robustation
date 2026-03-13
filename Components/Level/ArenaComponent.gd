class_name ArenaComponent extends Component

@export_category("Settings")
@export var available_enemies: Array[Enemy]
@export var budget_per_wave: float = 1
@export var spawn_positions: Array[Vector2]
@export var difficulty: int = 2

@export var max_range: int = 10
@export var melee_range: int = 15

@export_category("Variables")
@export var wave: int = 0
var budget: float = budget_per_wave

var melee_enemies: Array[Enemy]
var range_enemies: Array[Enemy]
var assist_enemies: Array[Enemy]
var universal_enemies: Array[Enemy]
var boss_enemies: Array[Enemy]

@export_category("Operational")
var current_enemies: Array[PhysicsBody2D]

#-----------------------READY-----------------------
func _ready() -> void:
	EventBusManager.gibbed.connect(_on_gibbed)
	for enemy in available_enemies:
		if enemy.enemy_type == enemy.enemy_types.MELEE:
			melee_enemies.append(enemy)
		elif enemy.enemy_type == enemy.enemy_types.RANGE:
			range_enemies.append(enemy)
		elif enemy.enemy_type == enemy.enemy_types.ASSIST:
			assist_enemies.append(enemy)
		elif enemy.enemy_type == enemy.enemy_types.UNIVERSAL:
			universal_enemies.append(enemy)
		elif enemy.enemy_type == enemy.enemy_types.BOSS:
			boss_enemies.append(enemy)
	
	start_game()

#-----------------------PROCESS-----------------------
func start_game() -> void:
	start_new_wave()

func start_new_wave() -> void:
	wave += 1
	budget = budget_per_wave * wave
	
	current_enemies.append_array(_spawn_enemies(_choose_enemies(budget, available_enemies)))

#-----------------------ASSIST FUNCTIONS-----------------------
func _spawn_enemies(enemies: Array[PackedScene]) -> Array[PhysicsBody2D]:
	var spawned_enemies: Array[PhysicsBody2D]
	
	for enemy in enemies:
		var inst: PhysicsBody2D = enemy.instantiate()
		scene.add_child.call_deferred(inst)
		inst.global_position = spawn_positions.pick_random()
		spawned_enemies.append(inst)
	
	return spawned_enemies

func _choose_enemies(choose_budget: float, enemies: Array[Enemy]) -> Array[PackedScene]:
	var choosed_enemies: Array[PackedScene]
	var remaining_budget: float = choose_budget
	var attempts: int = 0
	const MAX_ATTEMPTS: int = 100
	
	var _available_enemies: Array[Enemy] = enemies.duplicate()
	
	while remaining_budget > 0.1 and attempts < MAX_ATTEMPTS and _available_enemies.size() > 0:
		attempts += 1
		
		var enemy: Enemy = _weighted_random_enemy(_available_enemies)
		
		var max_count: int = floor(remaining_budget / enemy.cost)
		if max_count <= 0:
			_available_enemies.erase(enemy)
			continue
		
		var count_to_spawn: int
		if max_count >= 3 and randf() > 0.5:
			count_to_spawn = randi_range(1, min(3, max_count))
		else:
			count_to_spawn = 1
		
		for i in count_to_spawn:
			choosed_enemies.append(enemy.scene)
		remaining_budget -= enemy.cost * count_to_spawn
	
	return choosed_enemies

func _weighted_random_enemy(enemies: Array[Enemy]) -> Enemy:
	var total_weight: float = 0.0
	for enemy in enemies:
		total_weight += enemy.weight
	
	var random_value: float = randf() * total_weight
	
	var current_weight: float = 0.0
	for enemy in enemies:
		current_weight += enemy.weight
		if random_value <= current_weight:
			return enemy
	
	return enemies.back()

#-----------------------SIGNALS-----------------------
func _on_gibbed(emitter: Node2D) -> void:
	if current_enemies.has(emitter):
		current_enemies.erase(emitter)
		if current_enemies.is_empty():
			start_new_wave()
