@tool
class_name SetEnemyToBlackboardAction extends ActionLeaf

@export var key: String = "Target"
@export var delete_if_no_enemies: bool = false
@export var targeted_faction: String

@onready var tree: SceneTree = get_tree()
@onready var faction_comp: FactionComponent = owner.get_node_or_null("FactionComponent")
@onready var faction: String = faction_comp.faction

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	faction_comp.faction_changed.connect(_faction_changed)

func _faction_changed(new_faction):
	faction = new_faction

func tick(actor: Node, blackboard: Blackboard) -> int:
	var enemies: Array[Node] = tree.get_nodes_in_group("Enemies")
	
	if enemies.is_empty():
		blackboard.erase_value(key)
		if delete_if_no_enemies:
			queue_free()
		return FAILURE
	
	var parent_pos: Vector2 = actor.global_position
	var nearest_enemy: Node2D = null
	var nearest_distance: float = INF
	
	for enemy in enemies:
		if enemy == actor:
			continue
		
		var faction_component = enemy.get_node_or_null("FactionComponent")
		if faction_component:
			if targeted_faction and faction_component.faction != targeted_faction:
				continue
			elif faction_component.faction == faction:
				continue
		var distance: float = (parent_pos - enemy.global_position).length_squared()
		
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	if !nearest_enemy:
		blackboard.erase_value(key)
		if delete_if_no_enemies:
			queue_free()
		return FAILURE
	
	blackboard.set_value(key, nearest_enemy)
	return SUCCESS
