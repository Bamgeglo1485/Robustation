class_name FOVSettingsComponent extends Component

var config = ConfigFile.new()
var default_fov: float = 100.0

func _ready() -> void:
	parent.value_changed.connect(_save_fov_to_config)
	
	var err = config.load("user://settings.cfg")
	var loaded_fov = default_fov
	
	if err == OK and config.has_section_key("VISUAL", "FOV"):
		loaded_fov = config.get_value("VISUAL", "FOV")
		parent.value = loaded_fov
	else:
		parent.value = default_fov
		_save_fov_to_config(69.0)

func _save_fov_to_config(_value) -> void:
	EventBusManager.field_of_view_changed.emit(parent.value)
	config.set_value("VISUAL", "FOV", parent.value)
	config.save("user://settings.cfg")
