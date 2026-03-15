class_name PerkChooseOnPressedComponent extends Component

@export var perk: Script
@export var delete: bool = true
@onready var player: PhysicsBody2D = scene.get_node_or_null("Player")

func _ready() -> void:
	parent.pressed.connect(_on_button_pressed)

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
