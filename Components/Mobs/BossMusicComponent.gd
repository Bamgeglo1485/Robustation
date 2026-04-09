class_name BossMusicComponent extends Component

@onready var player: CharacterBody2D = scene.get_node_or_null("Player")
@onready var player_health: HealthComponent = player.get_node_or_null("HealthComponent")
@onready var player_music: MusicComponent = player.get_node_or_null("MusicComponent")
@onready var player_tendency_music: BattleTendencyMusicComponent = player.get_node_or_null("BattleTendencyMusicComponent")
@onready var health: HealthComponent = parent.get_node_or_null("HealthComponent")

@export var music: AudioStream

var pitch_tween: Tween
@export var player_pitch: float = 0.3
@export var pitch: float = 0.3

func change_music(new_music: AudioStream):
	player_music.set_main(new_music, 2)

func _ready() -> void:
	if health:
		health.health_changed.connect(_health_changed)
	if player_health:
		player_health.health_changed.connect(_player_health_changed)
	player_music.set_main(music, 2)

func _health_changed(_new_health: float) -> void:
	if _new_health <= 0:
		player_music.reset_main()
		player_music.main_music_player.pitch_scale = 1.0
		player_tendency_music.force_change(true)
		return
	_update_boss_pitch()

func _player_health_changed(_new_health: float) -> void:
	if _new_health <= 0:
		if pitch_tween and pitch_tween.is_valid():
			pitch_tween.kill()
		return
	_update_boss_pitch()

func _update_boss_pitch() -> void:
	if !player_music:
		return
	if health:
		pitch = 1.0 - (float(health.health) / health.max_health)
	if player_health:
		player_pitch = 1.0 - (float(player_health.health) / player_health.max_health)
	
	var target_pitch = 1.0 + (pitch + player_pitch) / 4
	
	if pitch_tween and pitch_tween.is_valid():
		pitch_tween.kill()
		
	pitch_tween = create_tween()
	pitch_tween.tween_property(player_music.main_music_player, "pitch_scale", target_pitch, 0.5)
