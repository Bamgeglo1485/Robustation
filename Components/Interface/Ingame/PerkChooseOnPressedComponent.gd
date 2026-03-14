class_name PerkChooseOnPressedComponent extends Component

@export var perk: Script
@onready var player: PhysicsBody2D = scene.get_node_or_null("Player")

func _ready() -> void:
	if parent is not Button:
		return
	
	parent.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if !perk or !player:
		queue_free()
		return
	
	player.get_node("PerkOwnerComponent").add_perk(perk)
	EventBusManager.on_perk_choosed.emit()
	queue_free()
