class_name TrayComponent extends Component

@export_category("Plant")
@export var plant_sprite: Sprite2D
@export var max_plant_progress: int = 4
var plant_progress: int = 0
@export var plant_textures: Array[Texture2D]
@export var progress_stage_delay: float = 1.0
@export var plant_scene: PackedScene

var stage_timer: Timer

@export_category("Tray")
@export var max_plants: int = 5
var plants: Array[Node2D]

func _ready() -> void:
	EventBusManager.gibbed.connect(_on_gibbed)
	stage_timer = Timer.new()
	stage_timer.one_shot = true
	stage_timer.wait_time = progress_stage_delay
	stage_timer.timeout.connect(_stage_progress)
	stage_timer.autostart = true
	add_child(stage_timer)

func _stage_progress() -> void:
	stage_timer.start()
	if max_plants <= plants.size():
		return
	plant_progress += 1
	if plant_progress >= max_plant_progress:
		plant_progress = 0
		var plant_inst: Node2D = plant_scene.instantiate()
		plant_inst.global_position = parent.global_position
		scene.add_child.call_deferred(plant_inst)
	
	plant_sprite.texture = plant_textures[plant_progress]

func _on_gibbed(emitter: Node2D) -> void:
	if !plants.has(emitter):
		return
	plants.erase(emitter)

func free() -> void:
	for plant in plants:
		var health: HealthComponent = plant.get_node_or_null("HealthComponent")
		if health:
			health._death()
		else:
			plant.queue_free()
