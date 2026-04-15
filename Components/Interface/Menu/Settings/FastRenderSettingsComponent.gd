class_name FastRenderSettingsComponent extends Component

var config = ConfigFile.new()
var toggled: bool

func _ready() -> void:
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		_set_default_settings()
		config.save("user://settings.cfg")
	
	toggled = config.get_value("VISUAL", "fast_render", false)
	
	if parent is Button:
		parent.button_pressed = toggled
		parent.toggled.connect(_toggled)

func _set_default_settings() -> void:
	config.set_value("VISUAL", "fast_render", false)

func _toggled(button_toggled: bool) -> void:
	if button_toggled == toggled:
		return
	
	toggled = button_toggled
	config.set_value("VISUAL", "fast_render", toggled)
	config.save("user://settings.cfg")
	
	var override_config = ConfigFile.new()
	var renderer = "gl_compatibility" if toggled else "forward_plus"
	override_config.set_value("rendering", "renderer/rendering_method", renderer)
	override_config.save("override.cfg")
	
	OS.set_restart_on_exit(true)
	get_tree().quit()
