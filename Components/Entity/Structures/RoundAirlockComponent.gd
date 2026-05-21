class_name RoundAirlockComponent extends Component

@export var roundend: bool = true
@export var area: Area2D

func _ready() -> void:
	area.body_entered.connect(body_enteted)

func body_enteted(body: Node2D) -> void:
	pass
