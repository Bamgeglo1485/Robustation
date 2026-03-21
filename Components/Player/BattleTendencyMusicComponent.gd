class_name BattleTendencyMusicComponent extends Component

@onready var battle_tendency_component: BattleTendencyComponent = parent.get_node_or_null("BattleTendencyComponent")
@onready var music_component: MusicComponent = parent.get_node_or_null("MusicComponent")

@export var music_1: AudioStream
@export var music_2: AudioStream
@export var music_3: AudioStream
@export var music_4: AudioStream

var last_section: int = 69

func _ready() -> void:
	if !battle_tendency_component or !music_component:
		return
	
	EventBusManager.tendency_section_changed.connect(_on_section_changed)
	_on_section_changed(parent, false)

func _on_section_changed(_emitter, timer: bool = true):
	if last_section == battle_tendency_component.section:
		return
	
	force_change(timer)

func force_change(timer: bool = true):
	if timer:
		await get_tree().create_timer(3).timeout
	
	last_section = battle_tendency_component.section
	
	if battle_tendency_component.section == 4:
		music_component.set_main(music_4, 1)
	elif battle_tendency_component.section == 3:
		music_component.set_main(music_3, 1)
	elif battle_tendency_component.section == 2:
		music_component.set_main(music_2, 1)
	else:
		music_component.set_main(music_1, 1)
