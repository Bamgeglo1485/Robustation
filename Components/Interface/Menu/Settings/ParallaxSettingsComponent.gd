class_name ParallaxSettingsComponent extends Component

var config = ConfigFile.new()
var toggled: bool

func _ready() -> void:
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return
	
	toggled = true
	
	if config.has_section_key("VISUAL", "parallax"):
		toggled = config.get_value("VISUAL", "parallax")
	else:
		config.set_value("VISUAL", "parallax", toggled)
		config.save("user://settings.cfg")
	SettingsConfigSystem.parallax = toggled
	
	if parent is Button:
		parent.toggled.connect(_toggled)
		parent.button_pressed = toggled

func _toggled(button_toggled) -> void:
	config.set_value("VISUAL", "parallax", button_toggled)
	toggled = button_toggled
	config.save("user://settings.cfg")
	SettingsConfigSystem.parallax = toggled
	EventBusManager.parallax_changed.emit(button_toggled)
