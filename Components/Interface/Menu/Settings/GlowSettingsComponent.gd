class_name GlowSettingsComponent extends Component

var config = ConfigFile.new()
var toggled: bool

func _ready() -> void:
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return
	
	toggled = true
	
	if config.has_section_key("VISUAL", "glow"):
		toggled = config.get_value("VISUAL", "glow")
	else:
		config.set_value("VISUAL", "glow", toggled)
		config.save("user://settings.cfg")
	
	if parent is Button:
		parent.toggled.connect(_toggled)
		parent.button_pressed = toggled

func _toggled(button_toggled) -> void:
	config.set_value("VISUAL", "fullscreen", button_toggled)
	toggled = button_toggled
	config.save("user://settings.cfg")
	EventBusManager.glow_changed.emit(button_toggled)
