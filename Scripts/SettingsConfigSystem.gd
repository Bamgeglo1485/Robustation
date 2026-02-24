extends Node

var config = ConfigFile.new()

var blood_clean_delay: float = 70.0

func _ready() -> void:
	var err = config.load("user://settings.cfg")
	if err != OK:
		return
	
	if config.has_section_key("VISUAL", "v_sync"):
		var toggled: bool = config.get_value("VISUAL", "v_sync")
		if toggled:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if config.has_section_key("VOLUME", "Master_volume"):
		var volume: float = config.get_value("VOLUME", "Master_volume")
		var volume_db = linear_to_db(volume / 100.0)
		var audio_bus_id: int
		audio_bus_id = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_volume_db(audio_bus_id, volume_db)
	if config.has_section_key("VISUAL", "Blood_cleaning_delay"):
		blood_clean_delay = config.get_value("VISUAL", "Blood_cleaning_delay")

static func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)
