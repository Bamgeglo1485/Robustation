class_name GenerationUnit extends Resource

@export var scene: PackedScene
@export var spawn_pattern: spawn_patterns
@export var restrict_overlaying: bool = true
@export var chance_to_appear: float = 1.0
@export var max_units: int = 3
@export var min_units: int = 1

enum spawn_patterns {
	SIDE,
	NOISE
}

@export_category("Shared")
@export var min_range_from_others: int = 256

@export_category("Side")
@export var rotate: bool = true

@export_category("Noise")
@export var noise: NoiseTexture2D
@export var noise_threshold: float = 0.5
@export var noise_scale: float = 0.1
@export var noise_offset: Vector2 = Vector2.ZERO
