class_name BloodCleaningSettingsComponent extends Component

var config = ConfigFile.new()
var default_delay: float = 70.0

func _ready() -> void:
	parent.value_changed.connect(_save_to_config)
	
	var err = config.load("user://settings.cfg")
	var loaded = default_delay
	
	if err == OK and config.has_section_key("VISUAL", "Blood_cleaning_delay"):
		loaded = config.get_value("VISUAL", "Blood_cleaning_delay")
		parent.value = loaded
	else:
		parent.value = default_delay
		_save_to_config(69.0)

func _save_to_config(_value) -> void:
	config.set_value("VISUAL", "Blood_cleaning_delay", parent.value)
	SettingsConfigSystem.blood_clean_delay = parent.value
	config.save("user://settings.cfg")
