class_name ArenaComponent extends Component

@export_category("Settings")
@export var enabled: bool = true
@export var perks: Array[PackedScene]
@export var enemy_perks: Array[PackedScene]
@export var boss_battles_per: int = 10
@export var area_info: RichTextLabel
@export var start_budget: float = 5
@export var choosable_perk_count_per_wave: int = 4
@export var available_enemies: Array[Enemy]
@export var available_bosses: Array[Enemy]
@export var budget_per_wave: float = 1.5
@export var spawn_positions: Array[Vector2]
@export var difficulty: int = 2

@export var max_melee_enemies: int = 6
@export var max_range_enemies: int = 6
@export var max_assist_enemies: int = 4
@export var max_universal_enemies: int = 6

@export_category("Variables")
@export var wave: int = 0

var budget: float = start_budget + budget_per_wave

var melee_enemies: Array[Enemy]
var range_enemies: Array[Enemy]
var assist_enemies: Array[Enemy]
var universal_enemies: Array[Enemy]
var time: float
var loose: bool = false

@onready var player: Node2D = scene.get_node_or_null("Player")
@onready var weapon_user_component: WeaponUserComponent = player.get_node_or_null("WeaponUserComponent")
@onready var health_component: HealthComponent = player.get_node_or_null("HealthComponent")
@onready var stamina_component: StaminaComponent = player.get_node_or_null("StaminaComponent")
@onready var player_perk_ui: Control = player.get_node("GUI").get_node("PerkChoose").get_node("PerkChoose")
@onready var player_perk_ui_list: VBoxContainer = player_perk_ui.get_node("Panel").get_node("VBoxContainer")
var perk_list_unit: PackedScene = preload("res://Scenes/UI/IngameInterface/Perks/PerkChooseUnit.tscn")

@export var perk_choice_start_sound: AudioStreamPlayer
@export var perk_choice_sound: AudioStreamPlayer
@export var perk_selected_sound: AudioStreamPlayer

@export_category("Operational")
var wave_active: bool = false
var current_enemies: Array[PhysicsBody2D]

var high_pass: AudioEffectHighPassFilter = AudioServer.get_bus_effect(1, 2)
var high_pass_tween: Tween

const MAX_ATTEMPTS: int = 100

func _ready() -> void:
	if !enabled:
		return
	EventBusManager.gibbed.connect(_on_gibbed)
	for enemy in available_enemies:
		match enemy.enemy_type:
			enemy.enemy_types.MELEE:
				melee_enemies.append(enemy)
			enemy.enemy_types.RANGE:
				range_enemies.append(enemy)
			enemy.enemy_types.ASSIST:
				assist_enemies.append(enemy)
			enemy.enemy_types.UNIVERSAL:
				universal_enemies.append(enemy)
	
	start_game()

func _physics_process(delta: float) -> void:
	if !wave_active or tree.paused:
		return
	time += delta
	if area_info:
		area_info.text = "Wave: " + str(wave) + "\nTime: " + str(round(time * 10) / 10.0)

func start_game() -> void:
	time = 0.0
	start_new_wave(true)

func start_new_wave(new_game: bool = false) -> void:
	if !new_game:
		health_component.delayed_damage_queue.clear()
		health_component.set_health(health_component.max_health)
		stamina_component.set_stamina(stamina_component.max_stamina)
		await _open_perk_choose()
	
	wave_active = true
	wave += 1
	budget = start_budget + budget_per_wave * wave
	
	var bosses: Array[PhysicsBody2D]
	if wave % boss_battles_per == 0:
		var boss_enemy: Enemy = _random_enemy(available_bosses)
		var boss_array: Array[PackedScene]
		boss_array.append(boss_enemy.scene)
		bosses = _spawn_enemies(boss_array)
		budget -= boss_enemy.cost
		current_enemies.append_array(bosses)
	
	current_enemies.append_array(_spawn_enemies(_choose_enemies(available_enemies)))
	
	if budget < 2:
		return
	
	var targets = bosses if !bosses.is_empty() else current_enemies
	var attempts: int = 0
	while budget >= 2 and attempts < MAX_ATTEMPTS:
		attempts += 1
		_add_perks(targets)

func _spawn_enemies(enemies: Array[PackedScene]) -> Array[PhysicsBody2D]:
	var spawned_enemies: Array[PhysicsBody2D]
	
	for enemy in enemies:
		var inst: PhysicsBody2D = enemy.instantiate()
		scene.add_child.call_deferred(inst)
		inst.global_position = spawn_positions.pick_random()
		spawned_enemies.append(inst)
	
	return spawned_enemies

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
	
	budget = remaining_budget
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

func _add_perks(enemies: Array[PhysicsBody2D]) -> void:
	for enemy in enemies:
		if !is_instance_valid(enemy):
			continue
		var perk_owner_comp: PerkOwnerComponent = enemy.get_node_or_null("PerkOwnerComponent")
		if !perk_owner_comp:
			continue
		
		perk_owner_comp.add_perk(_get_random_perk(enemy_perks), 5)
		perk_owner_comp.add_perk(_get_random_perk(enemy_perks), 5)
		budget -= 2

func _get_random_perk(list: Array[PackedScene]) -> PackedScene:
	if list.is_empty():
		return null
	return list.pick_random()

func _clean_blood() -> void:
	var blood_pools: Array[Node] = get_tree().get_nodes_in_group("Blood")
	for blood in blood_pools:
		if blood.has_method("clean"):
			blood.clean()
	
	var phys_particles: Array[Node] = get_tree().get_nodes_in_group("PhysicalParticle")
	for particle in phys_particles:
		if particle.has_method("clean"):
			particle.clean()

func _open_perk_choose() -> void:
	if loose:
		return
	
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

func _on_player_death() -> void:
	wave_active = false
	loose = true

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

func _on_gibbed(emitter: Node2D) -> void:
	if emitter == player:
		_on_player_death()
		return
	if current_enemies.has(emitter):
		current_enemies.erase(emitter)
		if current_enemies.is_empty():
			wave_active = false
			_clean_blood()
			await start_new_wave()
