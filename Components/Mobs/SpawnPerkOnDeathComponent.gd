class_name SpawnPerkOnDeathComponent extends Component

@export var perk: PackedScene = preload("res://Scenes/Collectables/CollectableRandomPerk.tscn")
@export var chance: float = 0.4

func _ready() -> void:
	EventBusManager.gibbed.connect(_on_gib)

func _on_gib(emitter) -> void:
	if emitter != parent:
		return
	
	if randf() > chance:
		return
	
	var inst = perk.instantiate()
	inst.global_position = parent.global_position
	scene.add_child.call_deferred(inst)
