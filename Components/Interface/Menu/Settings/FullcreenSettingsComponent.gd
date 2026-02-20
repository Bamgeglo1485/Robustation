class_name FullcreenSettingsComponent extends Component

var config = ConfigFile.new()
var toggled: bool

func _ready() -> void:
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return
	
	toggled = true
	
	if config.has_section_key("VISUAL", "fullscreen"):
		toggled = config.get_value("VISUAL", "fullscreen")
	else:
		config.set_value("VISUAL", "fullscreen", toggled)
		config.save("user://settings.cfg")
	
	if parent is Button:
		parent.toggled.connect(_toggled)
		parent.button_pressed = toggled
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _toggled(button_toggled) -> void:
	if button_toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	config.set_value("VISUAL", "fullscreen", button_toggled)
	toggled = button_toggled
	config.save("user://settings.cfg")

func _process(_delta):
	if Input.is_action_just_pressed("fullscreen"):
		_toggled(!toggled)
