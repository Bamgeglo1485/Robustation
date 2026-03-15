class_name RoundstartComponent extends Component

@export_file_path() var arena: String
@export var output_animation: TextPrintingAnimationComponent

func start_game(type: String):
	# shitcode
	if type == "arena":
		if output_animation and output_animation.tween:
			await output_animation.tween.finished
		start_arena()
		return

func start_arena():
	get_tree().change_scene_to_file(arena)
