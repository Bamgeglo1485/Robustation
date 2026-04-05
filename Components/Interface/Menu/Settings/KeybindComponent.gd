class_name KeybindComponent extends Component

@export var action: StringName
var default_key
var default_event
@onready var label: Label = parent.get_node_or_null("Label")
@onready var reset: Button = parent.get_node_or_null("Reset")
var config: ConfigFile = ConfigFile.new()
var input: InputEvent

func _ready() -> void:
	config.load("user://keybinds.cfg")
	
	var config_key = null
	if config and config.has_section("KEYBINDS"):
		if config.has_section_key("KEYBINDS", action):
			config_key = config.get_value("KEYBINDS", action)
	
	input = InputMap.action_get_events(action)[0]
	if input is InputEventKey:
		default_event = input
		default_key = default_event.physical_keycode
		if config_key == null:
			parent.text = OS.get_keycode_string(default_key)
		else:
			if config_key is InputEventKey:
				parent.text = OS.get_keycode_string(config_key.physical_keycode)
			elif config_key is InputEventMouseButton:
				_mouse_text(config_key)
	elif input is InputEventMouseButton:
		if config_key == null:
			_mouse_text(input)
		else:
			_mouse_text(config_key)
		default_key = input.button_index
	reset.pressed.connect(_reset)
	
	if config_key != null:
		_remap(config_key, false)

func _input(event: InputEvent) -> void:
	if !parent.button_pressed or !event.is_pressed():
		return
	
	if event is InputEventMouseButton:
		_mouse_text(event)
		_remap(event)
	elif event is InputEventKey:
		parent.text = OS.get_keycode_string(event.physical_keycode)
		_remap(event)

func _mouse_text(event: InputEventMouseButton) -> void:
		if event.button_index == MOUSE_BUTTON_LEFT:
			parent.text = "LMB"
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			parent.text = "RMB"
		elif event.button_index == MOUSE_BUTTON_XBUTTON1:
			parent.text = "MB4"
		elif event.button_index == MOUSE_BUTTON_XBUTTON2:
			parent.text = "MB5"

func _remap(event: InputEvent, save_config: bool = true) -> void:
	parent.button_pressed = false
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	if event is InputEventMouseButton:
		if event.button_index != default_key:
			reset.disabled = false
		else:
			reset.disabled = true
	elif event is InputEventKey:
		if event.physical_keycode != default_key:
			reset.disabled = false
		else:
			reset.disabled = true
	if save_config:
		config.load("user://keybinds.cfg")
		config.set_value("KEYBINDS", action, event)
		config.save("user://keybinds.cfg")

func _reset() -> void:
	reset.disabled = true
	_remap(default_event)
	if input is InputEventKey:
		parent.text = OS.get_keycode_string(default_key)
	elif default_key is InputEventMouseButton:
		_mouse_text(default_event)
