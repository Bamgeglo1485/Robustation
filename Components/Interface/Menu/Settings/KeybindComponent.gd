class_name KeybindComponent extends Component

@export var action: StringName
var default_key
var default_event
@onready var label: Label = parent.get_node_or_null("Label")
@onready var reset: Button = parent.get_node_or_null("Reset")
var config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	config.load("user://keybinds.cfg")
	
	var config_event = null
	if config.has_section("KEYBINDS") and config.has_section_key("KEYBINDS", action):
		config_event = config.get_value("KEYBINDS", action)
	
	default_event = InputMap.action_get_events(action)[0]
	default_key = _get_event_key(default_event)
	
	# Устанавливаем текст кнопки
	if config_event == null:
		_set_button_text(default_event)
	else:
		_set_button_text(config_event)
		_remap(config_event, false)
	
	reset.pressed.connect(_reset)

func _input(event: InputEvent) -> void:
	if not parent.button_pressed or not event.is_pressed():
		return
	
	_set_button_text(event)
	_remap(event)

func _get_event_key(event: InputEvent):
	if event is InputEventKey:
		return event.physical_keycode
	elif event is InputEventMouseButton:
		return event.button_index
	return null

func _get_event_text(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_XBUTTON1:
				return "MB4"
			MOUSE_BUTTON_XBUTTON2:
				return "MB5"
			_:
				return "MB" + str(event.button_index)
	return "Unknown"

func _set_button_text(event: InputEvent) -> void:
	parent.text = _get_event_text(event)

func _remap(event: InputEvent, save_config: bool = true) -> void:
	parent.button_pressed = false
	
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	
	var event_key = _get_event_key(event)
	reset.disabled = (event_key == default_key)
	
	if save_config:
		config.load("user://keybinds.cfg")
		config.set_value("KEYBINDS", action, event)
		config.save("user://keybinds.cfg")

func _reset() -> void:
	reset.disabled = true
	_set_button_text(default_event)
	_remap(default_event, true)
