class_name DungeonTemplate extends Resource

@export var base_plating_position: Vector2i = Vector2i.ZERO
@export var base_wall_position: Vector2i = Vector2i.ZERO
@export var door: PackedScene

@export var WIDTH = 50
@export var HEIGHT = 50
@export var MIN_ROOM_SIZE = 10
@export var MAX_ROOM_SIZE = 15
@export var MAX_ROOMS = 100
@export var CORRIDOR_WIDTH = 2
