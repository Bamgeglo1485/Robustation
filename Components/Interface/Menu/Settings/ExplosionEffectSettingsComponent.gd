class_name ExplosionEffectSettingsComponent extends Component

var config = ConfigFile.new()
var toggled: bool

func _ready() -> void:
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return
	
	toggled = true
	
	if config.has_section_key("VISUAL", "explosion_effect"):
		toggled = config.get_value("VISUAL", "explosion_effect")
	else:
		config.set_value("VISUAL", "explosion_effect", toggled)
		config.save("user://settings.cfg")
	SettingsConfigSystem.explosion_effect = toggled
	
	if parent is Button:
		parent.toggled.connect(_toggled)
		parent.button_pressed = toggled

func _toggled(button_toggled) -> void:
	config.set_value("VISUAL", "explosion_effect", button_toggled)
	toggled = button_toggled
	config.save("user://settings.cfg")
	SettingsConfigSystem.explosion_effect = toggled
