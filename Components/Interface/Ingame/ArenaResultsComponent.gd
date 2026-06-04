class_name ArenaResultsComponent extends Component

@export var results_text_label: RichTextLabel

func _ready() -> void:
	if !scene:
		return
	
	var difficulty: String
	match SettingsConfigSystem.difficulty:
		SettingsConfigSystem.difficulties.RPER:
			difficulty = "Roleplayer [1]"
		SettingsConfigSystem.difficulties.AGENT:
			difficulty = "Agent [2]"
		SettingsConfigSystem.difficulties.GREYTIDE:
			difficulty = "Greytide [3]"
	
	var station_run: StationRunComponent = tree.get_root().get_node_or_null("StationRunComponent")
	var arena_comp: ArenaComponent = scene.get_node_or_null("ArenaComponent")
	if arena_comp:
		var results: String
		results = ("[color=crimson]Wave: [/color]" + str(arena_comp.wave) + "\n" +
		"[color=crimson]Time: [/color]" + str(round(arena_comp.time * 10) / 10.0) + "\n" +
		"[color=crimson]Difficulty: [/color]" + difficulty)
		
		results_text_label.text = results
	elif station_run:
		var results: String
		results = ("[color=crimson]Level: [/color]" + str(station_run.current_level) + "\n" +
		"[color=crimson]Kills: [/color]" + str(station_run.kills) + "\n" +
		"[color=crimson]Time: [/color]" + str(round(station_run.time * 10) / 10.0) + "\n" +
		"[color=crimson]Difficulty: [/color]" + difficulty)
		
		results_text_label.text = results
