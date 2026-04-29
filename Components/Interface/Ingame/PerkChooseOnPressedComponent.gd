class_name PerkChooseOnPressedComponent extends Component

@export var perk: PackedScene
@export var delete: bool = true
var player: PhysicsBody2D

func _ready() -> void:
	parent.pressed.connect(_on_button_pressed)
	if scene:
		player = scene.get_node_or_null("Player")

func _on_button_pressed() -> void:
	if !player:
		if delete:
			queue_free()
		return
	
	if perk:
		player.get_node("PerkOwnerComponent").add_perk(perk)
	EventBusManager.on_perk_choosed.emit()
	if delete:
		queue_free()
