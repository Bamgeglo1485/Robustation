## Toggles visible if config key doesnt exist.
class_name ToggleVisibleIfConfigComponent extends Component

var config = ConfigFile.new()

@export var config_section: String
@export var config_key: String
@export var toggle_visible_comp: ToggleVisibleOnPressedComponent

func _ready() -> void:
	var err = config.load("user://settings.cfg")
	if err != OK:
		return
	
	if !config.has_section_key(config_section, config_key):
		toggle_visible_comp._execute_toggle()
