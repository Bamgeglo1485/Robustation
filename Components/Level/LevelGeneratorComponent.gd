class_name LevelGeneratorComponent extends Component

@warning_ignore_start("integer_division")
@export_category("Settings")
@export var max_room_width: int = 24
@export var min_room_width: int = 18
@export var max_room_height: int = 20
@export var min_room_height: int = 8
@export var max_last_room_width: int = 24
@export var min_last_room_width: int = 20
@export var max_last_room_height: int = 24
@export var min_last_room_height: int = 20
@export var room_count: int = 8

@export var reward_room_min_size: int = 10
@export var reward_room_max_size: int = 15

@export_category("Technical")
@export var wall_tile_map: TileMapLayer
@export var destructible_wall_tile_map: TileMapLayer
@export var tiles_tile_map: TileMapLayer
@export var minor_tiles_tile_map: TileMapLayer

@export_category("Entities")
@export var airlock: PackedScene
@export var enemy_airlock: PackedScene
@export var exit_airlock: PackedScene
@export var entry_airlock: PackedScene

@export var generation_units: Array[GenerationUnit]

@export_category("Tiles")
@export var wall_terrain_set: int = 0
@export var wall_terrain: int = 0
@export var floor_tile_source_id: int = 1
@export var floor_tile_atlas_coords: Vector2i = Vector2i.ZERO

@export var tile_generation_units: Array[TileGenerationUnit]

@onready var level_component: LevelComponent = get_parent().get_node_or_null("LevelComponent")

@export_category("Operational")
var positions: Array[Vector2i]
var current_position: Vector2i = Vector2i.ZERO
var previous_room_size: Vector2i = Vector2i.ZERO
var room: int = -1

func _ready() -> void:
	generate_level()

func generate_level() -> void:
	current_position = Vector2i.ZERO
	previous_room_size = Vector2i.ZERO
	
	for i in range(room_count):
		generate_room(i > 0)
		room += 1

func generate_room(connect_to_previous: bool = false) -> void:
	positions.clear()
	
	var width: int
	var height: int
	if room + 3 >= room_count:
		width = _get_random_odd(min_last_room_width, max_last_room_width)
		height = _get_random_odd(min_last_room_height, max_last_room_height)
	else:
		width = _get_random_odd(min_room_width, max_room_width)
		height = _get_random_odd(min_room_height, max_room_height)
	
	if connect_to_previous:
		var y_offset = (previous_room_size.y - height) / 2
		current_position.y += y_offset
	else:
		current_position.y = -height / 2
	
	_build_floor(width, height)
	_build_walls(width, height)
	
	if connect_to_previous:
		_connect_rooms(height)
		_set_enemy_spawners(width, height)
	
	for tile_unit in tile_generation_units:
		_set_tile_generation_unit(tile_unit, width, height)
	for generation_unit in generation_units:
		_set_generation_unit(generation_unit, width, height)
	
	if room + 2 == room_count:
		_set_exit(width, height)
	elif room == -1:
		_set_entry(height)
	
	previous_room_size = Vector2i(width, height)
	current_position.x += width - 1

func _set_exit(width: int, height: int) -> void:
	if !exit_airlock:
		return
	
	var exit_inst: PhysicsBody2D = exit_airlock.instantiate()
	scene.add_child.call_deferred(exit_inst)
	var round_airlock: RoundAirlockComponent = exit_inst.get_node_or_null("RoundAirlockComponent")
	round_airlock.room = room
	
	var exit_tile_pos = Vector2i(width - 1, height / 2) + current_position
	
	var world_pos = tiles_tile_map.to_global(tiles_tile_map.map_to_local(exit_tile_pos))
	exit_inst.global_position = world_pos
	
	wall_tile_map.erase_cell(exit_tile_pos)
	tiles_tile_map.set_cell(exit_tile_pos, floor_tile_source_id, floor_tile_atlas_coords)

func _set_entry(height: int) -> void:
	if !entry_airlock:
		return
	
	var entry_inst: PhysicsBody2D = entry_airlock.instantiate()
	scene.add_child.call_deferred(entry_inst)
	
	var entry_tile_pos = Vector2i(0, height / 2) + current_position
	
	var world_pos = tiles_tile_map.to_global(tiles_tile_map.map_to_local(entry_tile_pos))
	entry_inst.global_position = world_pos
	
	wall_tile_map.erase_cell(entry_tile_pos)
	tiles_tile_map.set_cell(entry_tile_pos, floor_tile_source_id, floor_tile_atlas_coords)

func _build_floor(width: int, height: int, position: Vector2i = current_position) -> void:
	if !tiles_tile_map:
		return
	
	for x in range(1, width - 1):
		for y in range(1, height - 1):
			var tile_pos = Vector2i(x, y) + position
			tiles_tile_map.set_cell(tile_pos, floor_tile_source_id, floor_tile_atlas_coords)
			
			if y == 1 and x > 1 and x < width - 2:
				positions.append(tile_pos)
			elif y == height - 2 and x > 1 and x < width - 2:
				positions.append(tile_pos)
			elif x == 1 and y > 1 and y < height - 2:
				positions.append(tile_pos)
			elif x == width - 2 and y > 1 and y < height - 2:
				positions.append(tile_pos)

func _build_walls(width: int, height: int, position: Vector2i = current_position, exclude_cells: Array[Vector2i] = []) -> void:
	if !wall_tile_map:
		return
	
	var wall_cells: Array[Vector2i] = []
	
	for x in range(width):
		for y in range(height):
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				var wall_pos = Vector2i(x, y) + position
				if !exclude_cells.has(wall_pos):
					wall_cells.append(wall_pos)
	
	wall_tile_map.set_cells_terrain_connect(wall_cells, wall_terrain_set, wall_terrain)

func _set_generation_unit(unit: GenerationUnit, width: int, height: int, position: Vector2i = current_position) -> void:
	if randf() > unit.chance_to_appear:
		return
	
	var units_to_spawn = randi_range(unit.min_units, unit.max_units)
	
	var other_positions: Array[Vector2i] = []
	for i in range(units_to_spawn):
		match unit.spawn_pattern:
			GenerationUnit.spawn_patterns.SIDE:
				var inst: Node2D = _spawn_on_side(unit, width, height, other_positions, position)
				if inst:
					other_positions.append(Vector2i(inst.global_position))
			GenerationUnit.spawn_patterns.NOISE:
				var inst: Node2D = _spawn_noise(unit, width, height, other_positions, position)
				if inst:
					other_positions.append(Vector2i(inst.global_position))

func _spawn_on_side(unit: GenerationUnit, room_width: int, room_height: int, other_positions: Array[Vector2i], position: Vector2i = current_position) -> Node2D:
	var spawn_position: Vector2i = Vector2i.ZERO
	var spawn_rotation: float = 0.0
	
	for attempt in range(150):
		var side = randi_range(0, 3)
		
		match side:
			0:
				spawn_position = Vector2i(randi_range(1, room_width - 2), 1) + position
				spawn_rotation = 90
			1:
				spawn_position = Vector2i(randi_range(1, room_width - 2), room_height - 2) + position
				spawn_rotation = -90
			2:
				spawn_position = Vector2i(1, randi_range(1, room_height - 2)) + position
				spawn_rotation = 0
			3:
				spawn_position = Vector2i(room_width - 2, randi_range(1, room_height - 2)) + position
				spawn_rotation = 180
		
		if positions.has(spawn_position):
			continue
		
		var too_close = false
		if unit.min_range_from_others > 0:
			for pos in other_positions:
				if pos.distance_squared_to(spawn_position) < unit.min_range_from_others:
					too_close = true
					break
		
		if too_close:
			continue
		
		positions.append(spawn_position)
		other_positions.append(spawn_position)
		
		return _spawn_unit(unit, spawn_position, spawn_rotation)
	
	return null

func _set_tile_generation_unit(unit: TileGenerationUnit, width: int, height: int, position: Vector2i = current_position) -> void:
	if randf() > unit.chance_to_appear:
		return
	
	var target_tile_map: TileMapLayer
	match unit.tile_map_layer:
		0:
			target_tile_map = tiles_tile_map
		1:
			target_tile_map = minor_tiles_tile_map
		2:
			target_tile_map = destructible_wall_tile_map
		_:
			target_tile_map = tiles_tile_map
	
	match unit.spawn_pattern:
		TileGenerationUnit.spawn_patterns.NOISE:
			_generate_noise_tiles(unit, width, height, position, target_tile_map)
		TileGenerationUnit.spawn_patterns.HORIZONTAL_LINE:
			_generate_horizontal_line(unit, width, height, position, target_tile_map)
		TileGenerationUnit.spawn_patterns.VERTICAL_LINE:
			_generate_vertical_line(unit, width, height, position, target_tile_map)
		TileGenerationUnit.spawn_patterns.CROSS_LINE:
			_generate_vertical_line(unit, width, height, position, target_tile_map)
			_generate_horizontal_line(unit, width, height, position, target_tile_map)
		TileGenerationUnit.spawn_patterns.SIDE:
			_generate_side_tiles(unit, width, height, position, target_tile_map)

func _generate_side_tiles(unit: TileGenerationUnit, room_width: int, room_height: int, position: Vector2i, target_tile_map: TileMapLayer) -> void:
	if !target_tile_map:
		return
	
	var cells: Array[Vector2i] = []
	var side_width = unit.width
	
	if unit.place_on_all_sides:
		for x in range(1, room_width - 1):
			for y in range(1, 1 + side_width):
				if y >= room_height - 1:
					break
				var tile_pos = Vector2i(x, y) + position
				if !(unit.restrict_overlaying and positions.has(tile_pos)):
					cells.append(tile_pos)
		
		for x in range(1, room_width - 1):
			for y in range(room_height - 1 - side_width, room_height - 1):
				if y < 1:
					continue
				var tile_pos = Vector2i(x, y) + position
				if !(unit.restrict_overlaying and positions.has(tile_pos)):
					cells.append(tile_pos)
		
		for x in range(1, 1 + side_width):
			if x >= room_width - 1:
				break
			for y in range(1, room_height - 1):
				var tile_pos = Vector2i(x, y) + position
				if !(unit.restrict_overlaying and positions.has(tile_pos)):
					cells.append(tile_pos)
		
		for x in range(room_width - 1 - side_width, room_width - 1):
			if x < 1:
				continue
			for y in range(1, room_height - 1):
				var tile_pos = Vector2i(x, y) + position
				if !(unit.restrict_overlaying and positions.has(tile_pos)):
					cells.append(tile_pos)
	else:
		var side = randi_range(0, 3)
		match side:
			0:
				for x in range(1, room_width - 1):
					for y in range(1, 1 + side_width):
						if y >= room_height - 1:
							break
						var tile_pos = Vector2i(x, y) + position
						if !(unit.restrict_overlaying and positions.has(tile_pos)):
							cells.append(tile_pos)
			1:
				for x in range(1, room_width - 1):
					for y in range(room_height - 1 - side_width, room_height - 1):
						if y < 1:
							continue
						var tile_pos = Vector2i(x, y) + position
						if !(unit.restrict_overlaying and positions.has(tile_pos)):
							cells.append(tile_pos)
			2:
				for x in range(1, 1 + side_width):
					if x >= room_width - 1:
						break
					for y in range(1, room_height - 1):
						var tile_pos = Vector2i(x, y) + position
						if !(unit.restrict_overlaying and positions.has(tile_pos)):
							cells.append(tile_pos)
			3:
				for x in range(room_width - 1 - side_width, room_width - 1):
					if x < 1:
						continue
					for y in range(1, room_height - 1):
						var tile_pos = Vector2i(x, y) + position
						if !(unit.restrict_overlaying and positions.has(tile_pos)):
							cells.append(tile_pos)
	
	_set_terrain_cells(target_tile_map, cells, unit, unit.delete_under_plate)
	
	if unit.restrict_overlaying:
		positions.append_array(cells)

func _generate_noise_tiles(unit: TileGenerationUnit, room_width: int, room_height: int, position: Vector2i, target_tile_map: TileMapLayer) -> void:
	if !target_tile_map:
		return
	
	var available_positions = _get_noise_positions(
		room_width,
		room_height,
		position,
		unit.noise,
		unit.noise_threshold,
		unit.noise_scale,
		unit.noise_offset
	)
	
	var tiles_to_place: int = randi_range(unit.min_units, unit.max_units)
	var placed_tiles: int = 0
	
	for tile_pos in available_positions:
		if placed_tiles >= tiles_to_place:
			break
		
		if unit.restrict_overlaying and positions.has(tile_pos):
			continue
		
		_set_terrain_cells(target_tile_map, [tile_pos], unit, unit.delete_under_plate)
		if unit.restrict_overlaying:
			positions.append(tile_pos)
		placed_tiles += 1

func _generate_vertical_line(unit: TileGenerationUnit, room_width: int, room_height: int, position: Vector2i, target_tile_map: TileMapLayer) -> void:
	if !target_tile_map:
		return
	
	var center_x = room_width / 2
	var line_width = unit.width
	var cells: Array[Vector2i] = []
	
	for x in range(center_x - line_width / 2, center_x + line_width / 2 + 1):
		for y in range(1, room_height - 1):
			var tile_pos = Vector2i(x, y) + position
			
			if unit.restrict_overlaying and positions.has(tile_pos):
				continue
			
			cells.append(tile_pos)
	
	_set_terrain_cells(target_tile_map, cells, unit, unit.delete_under_plate)
	
	if unit.restrict_overlaying:
		positions.append_array(cells)

func _generate_horizontal_line(unit: TileGenerationUnit, room_width: int, room_height: int, position: Vector2i, target_tile_map: TileMapLayer) -> void:
	if !target_tile_map:
		return
	
	var center_y = room_height / 2
	var line_width = unit.width
	var cells: Array[Vector2i] = []
	
	for y in range(center_y - line_width / 2, center_y + line_width / 2 + 1):
		for x in range(1, room_width - 1):
			var tile_pos = Vector2i(x, y) + position
			
			if unit.restrict_overlaying and positions.has(tile_pos):
				continue
			
			cells.append(tile_pos)
	
	_set_terrain_cells(target_tile_map, cells, unit, unit.delete_under_plate)
	
	if unit.restrict_overlaying:
		positions.append_array(cells)

func _get_noise_positions(width: int, height: int, position: Vector2i, noise_texture: NoiseTexture2D, threshold: float, scale: float, offset: Vector2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	
	if !noise_texture or !noise_texture.noise:
		return result
	
	var noise_obj = noise_texture.noise
	
	for x in range(1, width - 1):
		for y in range(1, height - 1):
			var tile_pos = Vector2i(x, y) + position
			
			if positions.has(tile_pos):
				continue
			
			var noise_x = (tile_pos.x * 100 + offset.x) * scale
			var noise_y = (tile_pos.y * 100 + offset.y) * scale
			var noise_value = noise_obj.get_noise_2d(noise_x, noise_y)
			
			var normalized_noise = (noise_value + 1.0) / 2.0
			
			if normalized_noise >= threshold:
				result.append(tile_pos)
	
	result.shuffle()
	return result

func _spawn_noise(unit: GenerationUnit, room_width: int, room_height: int, other_positions: Array[Vector2i], position: Vector2i = current_position) -> Node2D:
	if !unit.noise or !unit.noise.noise:
		return null
	
	var available_positions = _get_noise_positions(
		room_width,
		room_height,
		position,
		unit.noise,
		unit.noise_threshold,
		unit.noise_scale,
		unit.noise_offset
	)
	
	for spawn_position in available_positions:
		if positions.has(spawn_position):
			continue
		
		var too_close = false
		if unit.min_range_from_others > 0:
			for pos in other_positions:
				if pos.distance_squared_to(spawn_position) < unit.min_range_from_others:
					too_close = true
					break
		
		if too_close:
			continue
		
		positions.append(spawn_position)
		other_positions.append(spawn_position)
		
		return _spawn_unit(unit, spawn_position, 0.0)
	
	return null

func _set_terrain_cells(target_tile_map: TileMapLayer, cells: Array[Vector2i], unit: TileGenerationUnit, delete_under_plate: bool = false) -> void:
	if cells.is_empty():
		return
	
	var tile_set: TileSet = target_tile_map.tile_set
	var has_terrain: bool = unit.terrain_set >= 0 and unit.terrain >= 0
	
	if has_terrain and tile_set and unit.terrain_set < tile_set.get_terrain_sets_count():
		target_tile_map.set_cells_terrain_connect(cells, unit.terrain_set, unit.terrain)
		if delete_under_plate:
			for cell in cells:
				tiles_tile_map.set_cell(cell, -1, Vector2i(0, 0))
	else:
		for cell in cells:
			target_tile_map.set_cell(cell, unit.tile_source_id, unit.tile_atlas_coords)
			if delete_under_plate:
				tiles_tile_map.set_cell(cell, -1, Vector2i(0, 0))

func _spawn_unit(unit: GenerationUnit, position: Vector2i, rotation: float = 0.0) -> Node2D:
	var instance: Node2D = unit.scene.instantiate()
	scene.add_child.call_deferred(instance)
	
	var world_pos = tiles_tile_map.to_global(tiles_tile_map.map_to_local(position))
	instance.global_position = world_pos
	instance.rotation_degrees = rotation
	var room_data: RoomDataComponent = instance.get_node_or_null("RoomDataComponent")
	if room_data:
		room_data.room = room
	
	positions.append(position)
	
	return instance

func _connect_rooms(height: int) -> void:
	var prev_center_y = previous_room_size.y / 2
	var current_center_y = height / 2
	
	var connect_y = (prev_center_y + current_center_y) / 2
	
	var left_airlock_pos = Vector2i(0, connect_y) + current_position
	var right_airlock_pos = Vector2i(previous_room_size.x - 1, connect_y) + current_position - Vector2i(previous_room_size.x, 0)
	
	var airlock_inst: PhysicsBody2D = airlock.instantiate()
	scene.add_child.call_deferred(airlock_inst)
	
	var mid_position = (left_airlock_pos + right_airlock_pos) / 2
	var world_position = tiles_tile_map.map_to_local(mid_position)
	airlock_inst.global_position = tiles_tile_map.to_global(world_position)
	airlock_inst.global_position.x += 32
	
	var room_airlock: RoomAirlockComponent = airlock_inst.get_node_or_null("RoomAirlockComponent")
	if room_airlock:
		room_airlock.room = room
	
	wall_tile_map.erase_cell(left_airlock_pos)
	wall_tile_map.erase_cell(right_airlock_pos)
	
	tiles_tile_map.set_cell(left_airlock_pos, floor_tile_source_id, floor_tile_atlas_coords)
	tiles_tile_map.set_cell(right_airlock_pos, floor_tile_source_id, floor_tile_atlas_coords)

func _set_enemy_spawners(width: int, height: int) -> void:
	var center_x = width / 2
	
	var top_spawn = Vector2i(center_x, 0) + current_position
	var bottom_spawn = Vector2i(center_x, height - 1) + current_position
	
	wall_tile_map.erase_cell(top_spawn)
	wall_tile_map.erase_cell(bottom_spawn)
	tiles_tile_map.set_cell(top_spawn, floor_tile_source_id, floor_tile_atlas_coords)
	tiles_tile_map.set_cell(bottom_spawn, floor_tile_source_id, floor_tile_atlas_coords)
	
	var top_openable: bool = false
	var bottom_openable: bool = false
	
	randomize()
	if randf() > 0.5:
		top_openable = true
	else:
		bottom_openable = true
	_set_enemy_spawner(top_spawn, true, top_openable)
	_set_enemy_spawner(bottom_spawn, false, bottom_openable)

func _set_enemy_spawner(spawn_position: Vector2i, top: bool, openable: bool = true) -> void:
	var spawner_inst: PhysicsBody2D = enemy_airlock.instantiate()
	scene.add_child.call_deferred(spawner_inst)
	
	spawner_inst.global_position = tiles_tile_map.to_global(tiles_tile_map.map_to_local(spawn_position))
	
	var room_airlock: RoomAirlockComponent = spawner_inst.get_node_or_null("RoomAirlockComponent")
	if room_airlock:
		room_airlock.room = room + 100
	var start_zone: Area2D = spawner_inst.get_node_or_null("StartZone")
	var enemy_spawner: EnemySpawnerAirlockComponent = spawner_inst.get_node_or_null("EnemySpawnerAirlockComponent")
	if enemy_spawner:
		enemy_spawner.openable = openable
		enemy_spawner.room = room
		if top:
			enemy_spawner.enemy_spawn_position = spawner_inst.global_position - Vector2(0, 32)
			enemy_spawner.enemy_move_position = spawner_inst.global_position + Vector2(randi_range(-12, 12), 96)
			level_component.first_enemy_spawners.append(spawner_inst)
			positions.append(spawner_inst.global_position + Vector2(0, 32))
			_generate_reward_room(spawn_position, Vector2i.UP)
			start_zone.global_rotation_degrees = -90
		else:
			enemy_spawner.enemy_spawn_position = spawner_inst.global_position + Vector2(0, 32)
			enemy_spawner.enemy_move_position = spawner_inst.global_position - Vector2(randi_range(-12, 12), 96)
			level_component.second_enemy_spawners.append(spawner_inst)
			positions.append(spawner_inst.global_position - Vector2(0, 32))
			_generate_reward_room(spawn_position, Vector2i.DOWN)
			start_zone.global_rotation_degrees = 90

func _get_random_odd(min_val: int, max_val: int) -> int:
	if min_val % 2 == 0:
		min_val += 1
	if max_val % 2 == 0:
		max_val -= 1
	
	var result = randi_range(min_val, max_val)
	if result % 2 == 0:
		result += 1
	
	return result

func _generate_reward_room(spawn_position: Vector2i, direction: Vector2i) -> void:
	var room_size = Vector2i(
		_get_random_odd(reward_room_min_size, reward_room_max_size),
		_get_random_odd(reward_room_min_size, reward_room_max_size)
	)
	
	var room_start: Vector2i
	
	if direction == Vector2i.UP:
		room_start = spawn_position + Vector2i(-room_size.x / 2, -room_size.y)
	elif direction == Vector2i.DOWN:
		room_start = spawn_position + Vector2i(-room_size.x / 2, 1)
	else:
		return
	
	var exclude_cells: Array[Vector2i] = []
	if direction == Vector2i.UP:
		exclude_cells.append(room_start + Vector2i(room_size.x / 2, room_size.y - 1))
	elif direction == Vector2i.DOWN:
		exclude_cells.append(room_start + Vector2i(room_size.x / 2, 0))
	
	_build_floor(room_size.x, room_size.y, room_start)
	_build_walls(room_size.x, room_size.y, room_start, exclude_cells)
	
	for passage_pos in exclude_cells:
		tiles_tile_map.set_cell(passage_pos, floor_tile_source_id, floor_tile_atlas_coords)
	
	room += 100
	for generation_unit in generation_units:
		_set_generation_unit(generation_unit, room_size.x, room_size.y, room_start)
	for tile_unit in tile_generation_units:
		_set_tile_generation_unit(tile_unit, room_size.x, room_size.y, room_start)
	room -= 100
