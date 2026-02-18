class_name FOVSettingsComponent extends Component

var config = ConfigFile.new()

func _ready() -> void:
	parent.value_changed.connect(_on_changed)
	
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return
	
	var fov: float
	
	if config.has_section_key("VISUAL", "FOV"):
		fov = config.get_value("VISUAL", "FOV")
	else:
		config.set_value("VISUAL", "FOV", fov)
		config.save("user://settings.cfg")
	
	parent.value = fov

func _on_changed(new_value: float) -> void:
	config.set_value("VISUAL", "FOV", new_value)
	config.save("user://settings.cfg")
