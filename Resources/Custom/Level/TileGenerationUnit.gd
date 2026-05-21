class_name TileGenerationUnit extends Resource

@export var tile_source_id: int = 0
@export var tile_atlas_coords: Vector2i = Vector2i.ZERO
@export var tile_map_layer: int = 0  # 0 = tiles_tile_map, 1 = minor_tiles_tile_map, 2 = destructible_wall_tile_map
@export var spawn_pattern: spawn_patterns
@export var restrict_overlaying: bool = true
@export var chance_to_appear: float = 1.0
@export var max_units: int = 10
@export var min_units: int = 5

enum spawn_patterns {
	NOISE,
	VERTICAL_LINE,
	HORIZONTAL_LINE,
	CROSS_LINE,
	SIDE
}

@export_category("Shared")
@export var terrain_set: int = 0
@export var terrain: int = 0
@export var width: int = 1
@export var delete_under_plate: bool = false

@export_category("Noise")
@export var noise: NoiseTexture2D
@export var noise_threshold: float = 0.5
@export var noise_scale: float = 0.1
@export var noise_offset: Vector2 = Vector2.ZERO

@export_category("Side")
@export var place_on_all_sides: bool = true  
