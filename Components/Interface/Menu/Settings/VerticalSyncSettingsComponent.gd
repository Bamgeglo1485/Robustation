class_name VerticalSyncSettingsComponent extends Component

var config = ConfigFile.new()

func _ready() -> void:
	parent.toggled.connect(_toggled)
	
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return
	
	var toggled: bool = true
	
	if config.has_section_key("VISUAL", "v_sync"):
		toggled = config.get_value("VISUAL", "v_sync")
	else:
		config.set_value("VISUAL", "v_sync", toggled)
		config.save("user://settings.cfg")
	
	parent.button_pressed = toggled
	if toggled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _toggled(toggled) -> void:
	if toggled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	config.set_value("VISUAL", "v_sync", toggled)
	config.save("user://settings.cfg")
