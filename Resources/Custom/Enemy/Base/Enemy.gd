class_name Enemy extends Resource

@export var scene: PackedScene
@export var cost: float
@export var weight: float
enum enemy_types {
	MELEE,
	RANGE,
	ASSIST,
	UNIVERSAL,
	BOSS}
@export var enemy_type: enemy_types = enemy_types.MELEE
