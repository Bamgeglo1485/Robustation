class_name GreytideBossRunnerComponent extends Component

@export_category("Settings")
@export var boss: PackedScene
@onready var level_generator_component: LevelGeneratorComponent = get_parent().get_node_or_null("LevelGeneratorComponent")
var inst_boss: Node2D
var boss_mover: MobMoverComponent
var tween: Tween

func _ready() -> void:
	EventBusManager.room_start.connect(_on_start)
	EventBusManager.room_end.connect(_on_end)
	
	inst_boss = boss.instantiate()
	parent.add_child.call_deferred(inst_boss)
	inst_boss.global_position = Vector2(5000, 5000)
	boss_mover = inst_boss.get_node_or_null("MobMoverComponent")

func _on_start(room: int) -> void:
	if room + 2 == level_generator_component.room_count:
		inst_boss.queue_free()
		return
	if tween:
		tween.kill()
	await tree.physics_frame
	boss_mover.movement_blocked = true
	
	var spawner: Node = _find_spawner(room)
	if !spawner:
		return
	var enemy_spawner: EnemySpawnerAirlockComponent = spawner.get_node_or_null("EnemySpawnerAirlockComponent")
	var airlock_component: AirlockComponent = spawner.get_node_or_null("AirlockComponent")
	
	inst_boss.global_position = enemy_spawner.enemy_spawn_position
	tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(inst_boss, "global_position", enemy_spawner.enemy_move_position, 0.5)
	
	if airlock_component.state != AirlockComponent.airlock_states.OPENING:
		airlock_component.open()
	
	await tween.finished
	boss_mover.movement_blocked = false
	
	if airlock_component.state != AirlockComponent.airlock_states.CLOSING:
		airlock_component.close()

func _on_end(room: int) -> void:
	if tween:
		tween.kill()
	boss_mover.movement_blocked = true
	var spawner: Node = _find_spawner(room)
	if !spawner:
		return
	var enemy_spawner: EnemySpawnerAirlockComponent = spawner.get_node_or_null("EnemySpawnerAirlockComponent")
	var airlock_component: AirlockComponent = spawner.get_node_or_null("AirlockComponent")
	tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(inst_boss, "global_position", enemy_spawner.enemy_move_position, 1.5)
	airlock_component.open()
	await tween.finished
	tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(inst_boss, "global_position", enemy_spawner.enemy_spawn_position, 0.5)
	await tween.finished
	airlock_component.close()
	boss_mover.movement_blocked = false
	inst_boss.global_position = Vector2(5000, 5000)

func _find_spawner(room: int) -> Node:
	var spawners: Array[Node] = tree.get_nodes_in_group("EnemySpawner")
	var valid_spawners: Array[Node]
	for spawner in spawners:
		var enemy_spawner: EnemySpawnerAirlockComponent = spawner.get_node_or_null("EnemySpawnerAirlockComponent")
		if !enemy_spawner or enemy_spawner.room != room or enemy_spawner.openable:
			continue
		valid_spawners.append(spawner)
	
	if !valid_spawners:
		return null
	
	return valid_spawners.pick_random()
