class_name BattleTendencyMusicComponent extends Component

@onready var battle_tendency_component: BattleTendencyComponent = parent.get_node_or_null("BattleTendencyComponent")
@onready var music_component: MusicComponent = parent.get_node_or_null("MusicComponent")

@export var music_1: AudioStream
@export var music_2: AudioStream
@export var music_3: AudioStream
@export var music_4: AudioStream

var last_stage: BattleTendencyComponent.battle_tendency_stages

func _ready() -> void:
	if !battle_tendency_component or !music_component:
		return
	
	EventBusManager.tendency_stage_changed.connect(_on_stage_changed)
	_on_stage_changed(parent)

func _on_stage_changed(_emitter):
	if last_stage == battle_tendency_component.stage:
		return
	
	force_change()

func force_change():
	last_stage = battle_tendency_component.stage
	
	match battle_tendency_component.stage:
		BattleTendencyComponent.battle_tendency_stages.DESPERATE:
			music_component.set_main(music_1, 1)
		BattleTendencyComponent.battle_tendency_stages.STRUGGLE:
			music_component.set_main(music_2, 1)
		BattleTendencyComponent.battle_tendency_stages.PLEASURE:
			music_component.set_main(music_3, 1)
		BattleTendencyComponent.battle_tendency_stages.EUPHORIA:
			music_component.set_main(music_4, 1)
