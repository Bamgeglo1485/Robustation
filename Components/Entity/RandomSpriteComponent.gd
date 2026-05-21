class_name RandomSpriteComponent extends Component

@export var textures: Array[Texture]

func _ready() -> void:
	parent.texture = textures.pick_random()
