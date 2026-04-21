class_name DifficultySettingsComponent extends Component

var config = ConfigFile.new()

@export var button_difficulty: SettingsConfigSystem.difficulties = SettingsConfigSystem.difficulties.AGENT
@export var difficulty_title: Control
@export var toggle_visible_comp: ToggleVisibleOnPressedComponent

func _ready() -> void:
	var err = config.load("user://settings.cfg")
	if err != OK:
		return
	
	if SettingsConfigSystem.difficulty == button_difficulty:
		_set_title_color()
	
	if parent is Button:
		parent.pressed.connect(_pressed)

func _pressed() -> void:
	config.load("user://settings.cfg")
	config.set_value("GAMEPLAY", "difficulty", button_difficulty)
	SettingsConfigSystem.difficulty = button_difficulty
	config.save("user://settings.cfg")
	if difficulty_title:
		_set_title_color()
	if toggle_visible_comp:
		toggle_visible_comp._execute_toggle()

func _set_title_color() -> void:
	var color: Color
	match button_difficulty:
		SettingsConfigSystem.difficulties.RPER:
			color = Color(0.0, 0.558, 0.376, 1.0)
		SettingsConfigSystem.difficulties.AGENT:
			color = Color(0.769, 0.304, 0.0, 1.0)
		SettingsConfigSystem.difficulties.GREYTIDE:
			color = Color(0.869, 0.0, 0.301, 1.0)
	difficulty_title.modulate = color
