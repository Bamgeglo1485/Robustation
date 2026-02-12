class_name TargetPlayerWhenRagedComponent extends Component

@onready var rage_component: RageComponent = parent.get_node_or_null("RageComponent")
@onready var move_to_target_component: MoveToTargetComponent = get_parent().get_node_or_null("MoveToTargetComponent")
@onready var player: CharacterBody2D = scene.get_node_or_null("Player")

func _ready() -> void:
	if rage_component != null:
		rage_component.rage_state_change.connect(on_rage_state_change)

func on_rage_state_change(rage_state: bool) -> void:
	if !move_to_target_component:
		return
	
	if !rage_state:
		move_to_target_component.target = null
	elif player:
		move_to_target_component.target = player
