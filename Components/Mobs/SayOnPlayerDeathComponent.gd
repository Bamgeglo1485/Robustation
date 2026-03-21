class_name SayOnPlayerDeathComponent extends Component

@onready var chatter_component: ChatterComponent = parent.get_node_or_null("ChatterComponent")
@export var lines: Array[String]

func _ready() -> void:
	if chatter_component and !lines.is_empty():
		EventBusManager.player_death.connect(_on_player_death)

func _on_player_death():
	chatter_component.say(lines.pick_random())
