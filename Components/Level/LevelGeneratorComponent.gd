class_name LevelGeneratorComponent extends Node

@export_category("Settings")
@export var max_arena_rooms: int = 10
@export var corridor_length: int = 4

@export_category("References")
@export var available_arena_rooms: Array[PackedScene]
@export var wall_tile_map: TileMapLayer
@export var door_scene: PackedScene
@export var rooms_parent: Node

@export_category("Tiles")
@export var wall_terrain_set: int = 0
@export var wall_terrain: int = 0
@export var floor_tile_source_id: int = -1
@export var floor_tile_atlas_coords: Vector2i = Vector2i.ZERO

var _room_sizes: Dictionary = {}
var _rooms: Array[RoomData] = []

class RoomData:
	var instance: Node
	var top_left: Vector2i
	var size: Vector2i
	var connections: Dictionary

	func _init(p_instance, p_top_left, p_size):
		instance = p_instance
		top_left = p_top_left
		size = p_size
		connections = {}

const DIRS = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

func _ready() -> void:
	for scene in available_arena_rooms:
		var inst = scene.instantiate()
		var sz: Vector2i = inst.get("room_size") if "room_size" in inst else Vector2i(10, 10)
		_room_sizes[scene] = sz
		inst.queue_free()
	
	generate_level()

func generate_level() -> void:

	if available_arena_rooms.is_empty():
		return

	var first_scene = available_arena_rooms.pick_random()
	var first_top_left = Vector2i.ZERO
	_add_room(first_scene, first_top_left)

	var attempts = 0
	while _rooms.size() < max_arena_rooms and attempts < 100:
		var candidate = _find_valid_expansion()
		if candidate == null:
			break
		var room: RoomData = candidate.room
		var dir: Vector2i = candidate.dir
		var new_scene = available_arena_rooms.pick_random()
		var new_size = _room_sizes[new_scene]

		var new_top_left = _calculate_new_top_left(room, dir, new_size)
		if _is_area_free(new_top_left, new_size, room, dir):
			var new_room = _add_room(new_scene, new_top_left)
			_connect_rooms(room, dir, new_room)
			attempts = 0
		else:
			attempts += 1

func _add_room(scene: PackedScene, top_left: Vector2i) -> RoomData:
	var instance = scene.instantiate()
	rooms_parent.add_child.call_deferred(instance)
	
	# Позиция: сдвиг на половину тайла, чтобы origin (левый верхний угол) совпал с углом клетки
	var tile_size = wall_tile_map.tile_set.tile_size
	instance.global_position = wall_tile_map.map_to_local(top_left) - tile_size / 2.0
	
	var sz: Vector2i = _room_sizes[scene]
	_place_walls_around_room(top_left, sz)
	
	var room_data = RoomData.new(instance, top_left, sz)
	_rooms.append(room_data)
	return room_data

func _place_walls_around_room(top_left: Vector2i, size: Vector2i) -> void:
	var wall_cells: Array[Vector2i] = []
	for x in range(top_left.x - 1, top_left.x + size.x + 1):
		for y in range(top_left.y - 1, top_left.y + size.y + 1):
			if x >= top_left.x and x < top_left.x + size.x and y >= top_left.y and y < top_left.y + size.y:
				continue
			wall_cells.append(Vector2i(x, y))
	
	wall_tile_map.set_cells_terrain_connect(wall_cells, wall_terrain_set, wall_terrain)

func _get_door_cell(top_left: Vector2i, size: Vector2i, dir: Vector2i) -> Vector2i:
	match dir:
		Vector2i.RIGHT:
			return Vector2i(top_left.x + size.x, top_left.y + size.y / 2)
		Vector2i.LEFT:
			return Vector2i(top_left.x - 1, top_left.y + size.y / 2)
		Vector2i.DOWN:
			return Vector2i(top_left.x + size.x / 2, top_left.y + size.y)
		Vector2i.UP:
			return Vector2i(top_left.x + size.x / 2, top_left.y - 1)
		_:
			return top_left

func _connect_rooms(room1: RoomData, dir: Vector2i, room2: RoomData) -> void:
	var cell1 = _get_door_cell(room1.top_left, room1.size, dir)
	var cell2 = _get_door_cell(room2.top_left, room2.size, -dir)
	
	_replace_wall_with_floor(cell1)
	_replace_wall_with_floor(cell2)
	
	_spawn_door(cell1, dir)
	_spawn_door(cell2, -dir)
	
	var step = dir
	var pos = cell1 + step
	while pos != cell2:
		_replace_wall_with_floor(pos)
		pos += step
	
	room1.connections[dir] = room2
	room2.connections[-dir] = room1

func _replace_wall_with_floor(cell: Vector2i) -> void:
	if floor_tile_source_id >= 0:
		wall_tile_map.set_cell(cell, floor_tile_source_id, floor_tile_atlas_coords)
	else:
		wall_tile_map.erase_cell(cell)

func _spawn_door(cell: Vector2i, dir: Vector2i) -> void:
	var door = door_scene.instantiate()
	rooms_parent.add_child.call_deferred(door)
	var tile_size = wall_tile_map.tile_set.tile_size
	door.global_position = wall_tile_map.map_to_local(cell) - tile_size / 2.0  # аналогично комнате
	if dir == Vector2i.RIGHT:
		door.rotation_degrees = 90
	elif dir == Vector2i.LEFT:
		door.rotation_degrees = -90
	elif dir == Vector2i.DOWN:
		door.rotation_degrees = 180

func _find_valid_expansion() -> Dictionary:
	var candidates = []
	for room in _rooms:
		for dir in DIRS:
			if not room.connections.has(dir):
				candidates.append({"room": room, "dir": dir})
	if candidates.is_empty():
		return {}
	return candidates.pick_random()

func _calculate_new_top_left(room: RoomData, dir: Vector2i, new_size: Vector2i) -> Vector2i:
	var door_cur = _get_door_cell(room.top_left, room.size, dir)
	match dir:
		Vector2i.RIGHT:
			return Vector2i(door_cur.x + 2 + corridor_length, door_cur.y - new_size.y / 2)
		Vector2i.LEFT:
			return Vector2i(door_cur.x - 1 - corridor_length - new_size.x, door_cur.y - new_size.y / 2)
		Vector2i.DOWN:
			return Vector2i(door_cur.x - new_size.x / 2, door_cur.y + 2 + corridor_length)
		Vector2i.UP:
			return Vector2i(door_cur.x - new_size.x / 2, door_cur.y - 1 - corridor_length - new_size.y)
	return Vector2i.ZERO

func _is_area_free(top_left: Vector2i, size: Vector2i, from_room: RoomData, dir: Vector2i) -> bool:
	var min_x = top_left.x - 1
	var min_y = top_left.y - 1
	var max_x = top_left.x + size.x + 1
	var max_y = top_left.y + size.y + 1

	for other in _rooms:
		if other == from_room:
			continue
		var o_min_x = other.top_left.x - 1
		var o_min_y = other.top_left.y - 1
		var o_max_x = other.top_left.x + other.size.x + 1
		var o_max_y = other.top_left.y + other.size.y + 1
		if min_x < o_max_x and max_x > o_min_x and min_y < o_max_y and max_y > o_min_y:
			return false
	return true
