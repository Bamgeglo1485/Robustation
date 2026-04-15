class_name FastRenderSettingsComponent extends Component

var config = ConfigFile.new()
var toggled: bool

func _ready() -> void:
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return
	
	toggled = false
	
	if config.has_section_key("VISUAL", "fast_render"):
		toggled = config.get_value("VISUAL", "fast_render")
	else:
		config.set_value("VISUAL", "fast_render", toggled)
		config.save("user://settings.cfg")
	
	if parent is Button:
		parent.toggled.connect(_toggled)
		parent.button_pressed = toggled

func _toggled(button_toggled) -> void:
	if button_toggled == toggled:
		return
	config.set_value("VISUAL", "fast_render", button_toggled)
	toggled = button_toggled
	if toggled:
		ProjectSettings.set_setting("rendering/renderer/rendering_method", "gl_compatibility")
	else:
		ProjectSettings.set_setting("rendering/renderer/rendering_method", "forward_plus")
	ProjectSettings.save()
	config.save("user://settings.cfg")
	OS.set_restart_on_exit(true)
	get_tree().quit()
