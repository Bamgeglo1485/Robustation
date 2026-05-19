class_name LevelComponent extends Component

@export_category("Settings")
@export var available_enemies: Array[Enemy]
@export var max_enemies_per_room: int = 10
@export var min_enemies_per_room: int = 10
@export var start_budget: float = 1.5
@export var budget_per_room: float = 1
@export var reward_chance: float = 0.7
@export var reward_enemy_chance: float = 0.5
@export var available_reward_enemies: Array[Enemy]

@export var max_melee_enemies: int = 6
@export var max_range_enemies: int = 6
@export var max_assist_enemies: int = 4
@export var max_universal_enemies: int = 6

@export var delay_before_second_spawn: float = 3.0
@export var perks: Array[PackedScene]
@export var choosable_perk_count_per_wave: int = 4

var first_enemy_spawners: Array[PhysicsBody2D]
var second_enemy_spawners: Array[PhysicsBody2D]

var budget: float = start_budget

@export var perk_choice_start_sound: AudioStreamPlayer
@export var perk_choice_sound: AudioStreamPlayer
@export var perk_selected_sound: AudioStreamPlayer

@export_category("Operational")
var current_enemies: Array[PhysicsBody2D]
var second_spawned: bool = true
var room: int

const MAX_ATTEMPTS = 100

@onready var player: PhysicsBody2D = scene.get_node_or_null("Player")
@onready var weapon_user_component: WeaponUserComponent = player.get_node_or_null("WeaponUserComponent")
@onready var player_perk_ui: Control = player.get_node("GUI").get_node("PerkChoose").get_node("PerkChoose")
@onready var player_perk_ui_list: VBoxContainer = player_perk_ui.get_node("Panel").get_node("VBoxContainer")
var perk_list_unit: PackedScene = preload("res://Scenes/UI/IngameInterface/Perks/PerkChooseUnit.tscn")

var high_pass: AudioEffectHighPassFilter = AudioServer.get_bus_effect(1, 2)
var high_pass_tween: Tween

func _ready() -> void:
	EventBusManager.room_start.connect(_on_start)
	EventBusManager.gibbed.connect(_on_death)

func _on_start(_room: int) -> void:
	if _room < 100:
		second_spawned = false
		room = _room
		
		var first_spawner: PhysicsBody2D = first_enemy_spawners[room]
		var second_spawner: PhysicsBody2D = second_enemy_spawners[room]
		
		spawn_enemies(available_enemies, first_spawner)
		await tree.create_timer(delay_before_second_spawn).timeout
		spawn_enemies(available_enemies, second_spawner)
		second_spawned = true
	else:
		if randf() < reward_enemy_chance:
			second_spawned = true
			room = _room
			spawn_enemies(available_reward_enemies, null, player.global_position)
			EventBusManager.force_bolt.emit(room)
		elif randf() < reward_chance:
			_open_perk_choose()

func spawn_enemies(_enemies: Array[Enemy], spawner: PhysicsBody2D, position: Vector2 = Vector2.ZERO) -> void:
	var spawner_comp: EnemySpawnerAirlockComponent
	if spawner:
		spawner_comp = spawner.get_node_or_null("EnemySpawnerAirlockComponent")
	var enemies: Array[PackedScene] = _choose_enemies(_enemies)
	var mob_movers: Array[MobMoverComponent]
	
	for enemy in enemies:
		var inst_enemy: Node2D = enemy.instantiate()
		if spawner:
			inst_enemy.global_position = spawner_comp.enemy_spawn_position
		else:
			inst_enemy.global_position = position
		scene.add_child(inst_enemy)
		current_enemies.append(inst_enemy)
		
		if !spawner:
			continue
		var tween = create_tween()
		tween.tween_property(inst_enemy, "global_position", spawner_comp.enemy_move_position, 0.5)
		
		var mob_mover: MobMoverComponent = inst_enemy.get_node_or_null("MobMoverComponent")
		mob_mover.movement_blocked = true
		mob_movers.append(mob_mover)
	
	if !spawner:
		return
	var airlock_component: AirlockComponent = spawner.get_node_or_null("AirlockComponent")
	airlock_component.open()
	await tree.create_timer(0.5).timeout
	for mob_mover in mob_movers:
		if is_instance_valid(mob_mover):
			mob_mover.movement_blocked = false
	await tree.create_timer(0.5).timeout
	airlock_component.close()

func _choose_enemies(enemies: Array[Enemy]) -> Array[PackedScene]:
	var choosed_enemies: Array[PackedScene]
	var remaining_budget: float = budget
	var attempts: int = 0
	
	var _available_enemies: Array[Enemy] = enemies.duplicate()
	var melee_enemies_count: int = 0
	var range_enemies_count: int = 0
	var assist_enemies_count: int = 0
	var universal_enemies_count: int = 0
	
	while remaining_budget > 0.1 and attempts < MAX_ATTEMPTS and _available_enemies.size() > 0:
		attempts += 1
		
		var enemy: Enemy = _random_enemy(_available_enemies)
		
		match enemy.enemy_type:
			enemy.enemy_types.MELEE:
				if melee_enemies_count >= max_melee_enemies:
					continue
				melee_enemies_count += 1
			enemy.enemy_types.RANGE:
				if range_enemies_count >= max_range_enemies:
					continue
				range_enemies_count += 1
			enemy.enemy_types.ASSIST:
				if assist_enemies_count >= max_assist_enemies:
					continue
				assist_enemies_count += 1
			enemy.enemy_types.UNIVERSAL:
				if universal_enemies_count >= max_universal_enemies:
					continue
				universal_enemies_count += 1
		
		var max_count: int = floor(remaining_budget / enemy.cost)
		if max_count <= 0:
			_available_enemies.erase(enemy)
			continue
		
		var count_to_spawn: int = 1
		if max_count >= 3 and randf() > 0.5:
			count_to_spawn = randi_range(1, min(3, max_count))
		
		for i in count_to_spawn:
			choosed_enemies.append(enemy.scene)
		remaining_budget -= enemy.cost * count_to_spawn
	
	return choosed_enemies

func _random_enemy(enemies: Array[Enemy]) -> Enemy:
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

func _on_death(emitter: Node2D) -> void:
	if current_enemies.has(emitter):
		current_enemies.erase(emitter)
		if current_enemies.is_empty() and second_spawned:
			if room < 100:
				EventBusManager.room_end.emit(room)
				budget += budget_per_room
			else:
				EventBusManager.room_end.emit(room)
				EventBusManager.force_unbolt.emit(room)
				room -= 100
				if randf() < reward_chance:
					_open_perk_choose()

func _open_perk_choose() -> void:
	_high_pass_set(true)
	
	perk_choice_start_sound.play()
	weapon_user_component.can_attack = false
	player_perk_ui.visible = true
	
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(player_perk_ui, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	
	await tween.finished
	
	var perk_units: Array[Panel]
	var perk_units_buttons: Array[Button]
	
	for i in choosable_perk_count_per_wave:
		var perk_scene = _get_random_perk(perks)
		if !perk_scene:
			continue
		
		var inst_perk: PerkComponent = perk_scene.instantiate()
		
		scene.add_child(inst_perk)
		if !inst_perk.is_node_ready():
			await inst_perk.ready
		
		var perk_unit: Panel = perk_list_unit.instantiate()
		player_perk_ui_list.add_child.call_deferred(perk_unit)
		perk_unit.modulate = Color(0.0, 0.0, 0.0, 0.0)
		perk_units.append(perk_unit)
		
		perk_unit.get_node("TextureRect").texture = inst_perk.perk_data.icon_texture
		perk_unit.get_node("Desc").text = inst_perk.perk_data.perk_description
		
		var perk_name_label: Label = perk_unit.get_node("Name")
		perk_name_label.text = inst_perk.perk_data.perk_name
		
		match inst_perk.perk_data.perk_rarity:
			PerkData.rarity_classes.COMMON:
				perk_name_label.modulate = Color(0.744, 0.188, 0.0, 1.0)
			PerkData.rarity_classes.SHITTY:
				perk_name_label.modulate = Color(0.348, 0.197, 0.0, 1.0)
			PerkData.rarity_classes.ROBUST:
				perk_name_label.modulate = Color(0.931, 0.0, 0.323, 1.0)
			PerkData.rarity_classes.ADMINABUSE:
				perk_name_label.modulate = Color(0.613, 0.003, 0.899, 1.0)
		
		inst_perk.queue_free()
		
		var perk_unit_button: Button = perk_unit.get_node("Button")
		perk_unit_button.disabled = true
		perk_units_buttons.append(perk_unit_button)
		perk_unit_button.get_node("PerkChooseOnPressedComponent").perk = perk_scene
	
	for perk in perk_units:
		perk_choice_sound.play()
		var perk_tween: Tween = create_tween()
		perk_tween.set_trans(Tween.TRANS_SINE)
		perk_tween.set_ease(Tween.EASE_IN_OUT)
		perk_tween.tween_property(perk, "modulate", Color(4.416, 4.416, 4.416, 1.0), 0.15)
		perk_tween.tween_property(perk, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
		await perk_tween.finished
	
	for button in perk_units_buttons:
		button.disabled = false
	
	await EventBusManager.on_perk_choosed
	_close_perk_choose()

func _close_perk_choose() -> void:
	if !weapon_user_component:
		player_perk_ui.visible = false
		return
	
	_high_pass_set(false)
	
	perk_selected_sound.play()
	weapon_user_component.can_attack = true
	
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(player_perk_ui, "modulate", Color(0.0, 0.0, 0.0, 0.0), 0.5)
	
	await tween.finished
	
	player_perk_ui.visible = false
	for child in player_perk_ui_list.get_children():
		child.queue_free()

func _high_pass_set(enable: bool) -> void:
	if high_pass_tween and high_pass_tween.is_running():
		high_pass_tween.kill()
	
	if enable:
		high_pass.cutoff_hz = 1
		high_pass_tween = create_tween()
		high_pass_tween.tween_property(high_pass, "cutoff_hz", 700, 1)
		AudioServer.set_bus_effect_enabled(1, 2, true)
	else:
		high_pass.cutoff_hz = 700
		high_pass_tween = create_tween()
		high_pass_tween.tween_property(high_pass, "cutoff_hz", 1, 1)
		await high_pass_tween.finished
		AudioServer.set_bus_effect_enabled(1, 2, false)

func _get_random_perk(list: Array[PackedScene]) -> PackedScene:
	if list.is_empty():
		return null
	return list.pick_random()
