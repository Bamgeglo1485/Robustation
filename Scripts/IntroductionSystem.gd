extends Node

var config: ConfigFile = ConfigFile.new()

var introductiones_enemies: Array[String]

func _ready() -> void:
	var err = config.load("user://save.cfg")
	if err != OK:
		return
	
	if config.has_section("INTRODUCTION"):
		for intr in config.get_section_keys("INTRODUCTION"):
			introductiones_enemies.append(intr)
