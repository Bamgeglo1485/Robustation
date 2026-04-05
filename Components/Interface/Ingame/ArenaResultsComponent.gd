class_name ArenaResultsComponent extends Component

@export var results_text_label: RichTextLabel

func _ready() -> void:
	if !scene:
		return
	
	var arena_comp: ArenaComponent = scene.get_node_or_null("ArenaComponent")
	if !arena_comp:
		return
	
	var results: String
	results = ("[color=crimson]Wave: [/color]" + str(arena_comp.wave) + "\n" +
	"[color=crimson]Time: [/color]" + str(round(arena_comp.time * 10) / 10.0))
	
	results_text_label.text = results
