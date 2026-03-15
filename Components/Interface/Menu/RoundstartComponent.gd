class_name RoundstartComponent extends Component

@export var arena: String = "res://Game/game.tscn"  # Изменил на .tscn
@export var output_animation: TextPrintingAnimationComponent

var arena_scene: PackedScene = null
var is_loading: bool = false

func start_game(type: String):
	if type == "arena":
		_start_loading_arena()
		
		if output_animation and output_animation.tween:
			await output_animation.tween.finished
		
		await _wait_for_load()
		
		start_arena()

func _start_loading_arena():
	if is_loading:
		return
	
	is_loading = true
	ResourceLoader.load_threaded_request(arena)

func _wait_for_load():
	while true:
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(arena, progress)
		
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				arena_scene = ResourceLoader.load_threaded_get(arena)
				is_loading = false
				return
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Failed to load arena: ", arena)
				is_loading = false
				return
			_:
				await get_tree().process_frame

func start_arena():
	if arena_scene:
		get_tree().change_scene_to_packed(arena_scene)
	else:
		var new_scene = load(arena)
		if new_scene:
			get_tree().change_scene_to_packed(new_scene)
		else:
			push_error("Could not load arena: ", arena)
