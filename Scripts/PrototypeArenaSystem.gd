extends Node2D

var diff: float = 1.0
var enemies_per_wave = 5
var wave_cleanbots: Array[CharacterBody2D] = []
var wave_assistants: Array[CharacterBody2D] = []
var wave_special_agents: Array[CharacterBody2D] = []
@onready var wave_timer = $WaveTimer
@onready var player: CharacterBody2D = $Player
@export var assistant: PackedScene
@export var pun_pun: PackedScene
@export var bartender: PackedScene
@export var cleanbot: PackedScene

func _ready():
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	wave_timer.start()

func _on_wave_timer_timeout() -> void:
	_clean_invalid_instances(wave_cleanbots)
	
	if wave_cleanbots.is_empty():
		var bot_count = randi_range(1, 3)
		for i in range(bot_count):
			_spawn_enemy(cleanbot, wave_cleanbots)
	
	var spawn_chance = randf() * (diff / 3.0)
	if spawn_chance > 0.7:
		_clean_invalid_instances(wave_special_agents)
		if wave_special_agents.size() < 2:
			_spawn_special_enemies()
	
	_clean_invalid_instances(wave_assistants)
	
	if wave_assistants.size() <= 20:
		var enemy_count = randi_range(1, 3)
		for i in range(enemy_count):
			_spawn_enemy(assistant, wave_assistants)
	
	diff += 0.1
	wave_timer.start()

func _clean_invalid_instances(array: Array) -> void:
	var valid_instances: Array[CharacterBody2D] = []
	for instance in array:
		if is_instance_valid(instance):
			valid_instances.append(instance)
	array.clear()
	array.append_array(valid_instances)

func _spawn_enemy(enemy_scene: PackedScene, target_array: Array) -> void:
	var spawn_pos = _get_random_spawn_position()
	var inst = enemy_scene.instantiate()
	inst.global_position = spawn_pos
	add_child(inst)
	target_array.append(inst)

func _spawn_special_enemies() -> void:
	var spawn_pos = _get_random_spawn_position()
	
	var pun_inst = pun_pun.instantiate()
	pun_inst.global_position = spawn_pos
	add_child(pun_inst)
	
	var bartender_pos = spawn_pos + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	var bartender_inst = bartender.instantiate()
	bartender_inst.global_position = bartender_pos
	add_child(bartender_inst)
	
	wave_special_agents.append(bartender_inst)
	wave_special_agents.append(pun_inst)

func _get_random_spawn_position() -> Vector2:
	var x_spawn_pos = randf_range(0, 500)
	var y_spawn_pos = randf_range(0, 500)
	
	return Vector2(x_spawn_pos, y_spawn_pos)
