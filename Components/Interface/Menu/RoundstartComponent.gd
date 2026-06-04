class_name RoundstartComponent extends Component

@export_file_path() var station_run: String
@export_file_path() var arena: String
@export_file_path() var v1: String
@export var output_animation: TextPrintingAnimationComponent

func start_game(type: String):
	# shitcode
	if type == "arena":
		if output_animation and output_animation.tween:
			await output_animation.tween.finished
		tree.change_scene_to_file(arena)
	elif type == "station_run":
		if output_animation and output_animation.tween:
			await output_animation.tween.finished
		tree.change_scene_to_file(station_run)
	elif type == "v1":
		if output_animation and output_animation.tween:
			await output_animation.tween.finished
		tree.change_scene_to_file(v1)
