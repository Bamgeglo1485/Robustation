class_name SavePositionComponent extends Component

var config = ConfigFile.new()

func _ready() -> void:
	var err = config.load("user://positions.cfg")
	
	if err != OK:
		return
	
	if config.has_section_key("MENU", parent.name + "_position"):
		parent.global_position = config.get_value("MENU", parent.name + "_position")
	else:
		config.set_value("MENU", parent.name + "_position", parent.global_position)
		config.save("user://positions.cfg")

func _exit_tree() -> void:
	config.load("user://positions.cfg")
	config.set_value("MENU", parent.name + "_position", parent.global_position)
	config.save("user://positions.cfg")
