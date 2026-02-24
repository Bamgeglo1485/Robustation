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
	
	EventBusManager.fullscreen_changed.connect(_on_fullscreen_changed_event)

func _on_fullscreen_changed_event(fullscreen: bool) -> void:
	if parent is not Button:
		return
	
	if parent.button_pressed == fullscreen:
		return
	
	parent.button_pressed = fullscreen

func _toggled(button_toggled) -> void:
	if button_toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		EventBusManager.fullscreen_changed.emit(true)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		EventBusManager.fullscreen_changed.emit(false)
	
	config.set_value("VISUAL", "fullscreen", button_toggled)
	toggled = button_toggled
	config.save("user://settings.cfg")

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		_toggled(!toggled)
