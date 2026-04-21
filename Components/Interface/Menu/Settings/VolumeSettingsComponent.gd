class_name VolumeSettingsComponent extends Component

var config = ConfigFile.new()
@export var audio_bus_name: String
var audio_bus_id: int

func _ready() -> void:
	if audio_bus_name.is_empty():
		return
	
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	if audio_bus_id == -1:
		return
	
	parent.value_changed.connect(_on_changed)
	
	var volume = 100.0
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return
	
	if config.has_section_key("VOLUME", audio_bus_name + "_volume"):
		volume = config.get_value("VOLUME", audio_bus_name + "_volume")
	else:
		config.set_value("VOLUME", audio_bus_name + "_volume", volume)
		config.save("user://settings.cfg")
	
	var volume_db = linear_to_db(volume / 100.0)
	AudioServer.set_bus_volume_db(audio_bus_id, volume_db)
	
	parent.value = volume

func _on_changed(new_value: float) -> void:
	var volume_db = linear_to_db(new_value / 100.0)
	AudioServer.set_bus_volume_db(audio_bus_id, volume_db)
	
	config.load("user://settings.cfg")
	config.set_value("VOLUME", audio_bus_name + "_volume", new_value)
	config.save("user://settings.cfg")
