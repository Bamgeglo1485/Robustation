class_name PerkModifier extends Resource

@export var target_component: String
@export var ensure_component: bool = false
@export var property: String
@export var operation: operations 
@export var value: float = 1.0
@export var type: types

enum operations {
	MULTIPLY,
	ADD
}

enum types {
	BUFF,
	NEUTRAL,
	DEBUFF
}
