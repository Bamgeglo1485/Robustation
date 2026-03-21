class_name IntroductionSubjectComponent extends Component

@export var group: String
@export var subject_name: String
@export_multiline() var subject_desc: String
@export var subject_prefix: String
@export var theme: AudioStream = preload("res://Audio/EnemyThemes/Crew.ogg")

@onready var screen_notifier: VisibleOnScreenNotifier2D = parent.get_node_or_null("VisibleOnScreenNotifier2D")

func _ready() -> void:
	if !screen_notifier:
		return
	if screen_notifier.is_on_screen():
		_if_on_screen()
	else:
		screen_notifier.screen_entered.connect(_on_screen)

func _if_on_screen() -> void:
	EventBusManager.introduction_subject_on_screen.emit(parent)
	screen_notifier.queue_free()

func _on_screen() -> void:
	_if_on_screen()
