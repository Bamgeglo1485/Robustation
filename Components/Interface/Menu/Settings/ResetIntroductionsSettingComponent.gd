class_name ResetIntroductionsSettingComponent extends Component

var config = ConfigFile.new()

func _ready() -> void:
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return

	if parent is Button:
		parent.pressed.connect(_toggled)

func _toggled() -> void:
	for intro in config.get_section_keys("INTRODUCTION"):
		config.erase_section_key("INTRODUCTION", intro)
		config.save("user://settings.cfg")
		SettingsConfigSystem.introductiones_enemies.clear()
