class_name SayOnSpawnComponent extends Component

@onready var chatter_component: ChatterComponent = parent.get_node_or_null("ChatterComponent")
@export var lines: Array[String]

func _ready() -> void:
	chatter_component.say(lines.pick_random())
