class_name DeathScreenComponent extends Component

@export var error_panel: Panel
@export var clone_count: int = 20
@export var spawn_time: float = 2.75

@export var min_rotation: float = -8.0
@export var max_rotation: float = 8.0
@export var min_scale: float = 0.7
@export var max_scale: float = 1.3
@export var margin: int = 50
@export var can_restart_delay: float = 0.5

var clone_timer: Timer
var current_clones: int = 0
var spawn_area: Rect2
var base_interval: float

func _ready() -> void:
	if !error_panel:
		return
	
	error_panel.hide()
	base_interval = spawn_time / clone_count
	
	await tree.process_frame
	_calculate_spawn_area()
	
	clone_timer = Timer.new()
	clone_timer.one_shot = false
	clone_timer.timeout.connect(_clone_error_panel)
	add_child(clone_timer)
	_reset_timer()
	
	await tree.create_timer(can_restart_delay).timeout
	var restart: RestartComponent = RestartComponent.new()
	add_child(restart)

func _calculate_spawn_area() -> void:
	if get_parent() is Control:
		var parent_control = get_parent() as Control
		spawn_area = Rect2(
			margin,
			margin,
			parent_control.size.x - margin * 2,
			parent_control.size.y - margin * 2
		)
	else:
		var viewport = get_viewport().get_visible_rect()
		spawn_area = Rect2(
			margin,
			margin,
			viewport.size.x - margin * 2,
			viewport.size.y - margin * 2)

func _reset_timer() -> void:
	clone_timer.wait_time = base_interval
	clone_timer.start()

func _clone_error_panel() -> void:
	if current_clones >= clone_count:
		clone_timer.stop()
		scene.get_node("Player").global_position = Vector2(1000, 1000)
		clear_errors()
		return
	
	var new_panel = error_panel.duplicate()
	new_panel.show()
	new_panel.modulate.a = 0
	new_panel.z_index = clone_count * 3
	
	var x = randf_range(spawn_area.position.x, spawn_area.end.x)
	var y = randf_range(spawn_area.position.y, spawn_area.end.y)
	
	if new_panel is Control:
		new_panel.position = Vector2(x, y)
	else:
		new_panel.global_position = Vector2(x, y)
	
	new_panel.rotation_degrees = randf_range(min_rotation, max_rotation)
	new_panel.scale = Vector2.ONE * randf_range(min_scale, max_scale)
	
	error_panel.get_parent().add_child(new_panel)
	
	var tween = create_tween()
	tween.tween_property(new_panel, "modulate:a", 1.0, 0.15)
	
	current_clones += 1

func start_death_sequence() -> void:
	current_clones = 0
	_calculate_spawn_area()
	if clone_timer:
		_reset_timer()

func clear_errors() -> void:
	for child in error_panel.get_parent().get_children():
		if child != error_panel and child is Panel:
			child.queue_free()
	current_clones = 0
	clone_timer.stop()

func _on_viewport_size_changed() -> void:
	_calculate_spawn_area()
