class_name BuddyComponent extends Component

@export var buddy: CharacterBody2D

@export var set_buddy_on_start: bool = false
@export var buddy_group: String

@export var rage_when_buddy_dead: bool = true
@export var set_buddy_as_attack_target: bool = false

@export var move_to_buddy: bool = false
@export var move_priority: int = 1
@onready var move_to_point_component = parent.get_node_or_null("MoveToPoinComponent")

func _ready() -> void:
	EventBusManager.gibbed.connect(on_gibbed)
	
	if move_to_point_component == null and parent.has_node("AI"):
		move_to_point_component = parent.get_node("AI").get_node_or_null("MoveToPointComponent")
	
	if buddy_group != null and set_buddy_on_start == true:
		var potential_buddies = parent.get_parent().get_children()
		
		for potential_buddy in potential_buddies:
			var buddy_component = potential_buddy.get_node_or_null("BuddyComponent")
			if buddy_component == null:
				continue
			if buddy_component.buddy_group != buddy_group or buddy_component.buddy != null:
				continue
			
			buddy = potential_buddy
			buddy_component.buddy = parent
	
	if set_buddy_as_attack_target == true and buddy != null:
		var attack_target_component = parent.get_node_or_null("AttackTargetComponent")
		if attack_target_component == null and parent.has_node("AI"):
			attack_target_component = parent.get_node("AI").get_node_or_null("AttackTargetComponent")
			if attack_target_component == null:
				return
		
		attack_target_component.target = buddy

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if move_to_buddy == false or move_to_point_component == null or buddy == null:
		return
	move_to_point_component.set_point(buddy.global_position, move_priority)

func on_gibbed(emitter):
	if emitter != buddy:
		return
	
	var rage_component = parent.get_node_or_null("RageComponent")
	
	if rage_component != null:
		rage_component.rage()
