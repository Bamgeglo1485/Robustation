class_name FullcreenSettingsComponent extends Component

var config = ConfigFile.new()
var toggled: bool
var window_size: Vector2i

func _ready() -> void:
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		_set_default_settings()
		config.save("user://settings.cfg")
	else:
		_load_settings()
	
	if parent is Button:
		parent.toggled.connect(_toggled)
		parent.button_pressed = toggled
	
	_apply_window_mode()
	
	get_tree().root.size_changed.connect(_on_window_resized)
	EventBusManager.fullscreen_changed.connect(_on_fullscreen_changed_event)

func _set_default_settings() -> void:
	config.set_value("VISUAL", "fullscreen", false)
	config.set_value("VISUAL", "window_width", 1920)
	config.set_value("VISUAL", "window_height", 1080)
	toggled = false
	window_size = Vector2i(1920, 1080)

func _load_settings() -> void:
	toggled = config.get_value("VISUAL", "fullscreen", false)
	window_size = Vector2i(
		config.get_value("VISUAL", "window_width", 1920),
		config.get_value("VISUAL", "window_height", 1080)
	)

func _center_window() -> void:
	var screen_size = DisplayServer.screen_get_size()
	var new_position = (screen_size - window_size) / 2.0
	DisplayServer.window_set_position(new_position)

func _apply_window_mode() -> void:
	if toggled:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			window_size = DisplayServer.window_get_size()
		
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(window_size)
		_center_window()

func _on_fullscreen_changed_event(fullscreen: bool) -> void:
	if parent is not Button:
		return
	
	if parent.button_pressed == fullscreen:
		return
	
	parent.button_pressed = fullscreen

func _toggled(button_toggled: bool) -> void:
	toggled = button_toggled
	
	if button_toggled:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			window_size = DisplayServer.window_get_size()
		
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		EventBusManager.fullscreen_changed.emit(true)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(window_size)
		_center_window()
		EventBusManager.fullscreen_changed.emit(false)
	
	_save_settings()

func _save_settings() -> void:
	config.set_value("VISUAL", "fullscreen", toggled)
	config.set_value("VISUAL", "window_width", window_size.x)
	config.set_value("VISUAL", "window_height", window_size.y)
	config.save("user://settings.cfg")

func _on_window_resized() -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		window_size = DisplayServer.window_get_size()
		_save_settings()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		_toggled(!toggled)
