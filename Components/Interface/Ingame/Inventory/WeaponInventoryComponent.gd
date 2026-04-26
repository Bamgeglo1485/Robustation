class_name WeaponInventoryComponent extends Component

@export var description: RichTextLabel
@export var weapons_container: Container

var weapon_unit_scene: PackedScene = preload("res://Scenes/UI/IngameInterface/Inventory/WeaponUnit.tscn")
var player_weapon_user_component: PlayerWeaponUserComponent

func _ready() -> void:
	if !parent:
		return
	
	const max_attempts: int = 15
	var attempts: int = 0
	
	while parent is not PhysicsBody2D:
		var potential_parent: Node = parent.get_parent()
		if potential_parent:
			parent = potential_parent
		attempts += 1
		if parent is PhysicsBody2D:
			break
		if attempts > max_attempts:
			break
	
	player_weapon_user_component = parent.get_node_or_null("PlayerWeaponUserComponent")
	_update_inventory()

func _update_inventory() -> void:
	if !player_weapon_user_component:
		return
	
	for weapon_unit in weapons_container.get_children():
		if weapon_unit.name != "Ignore":
			weapon_unit.queue_free()
		weapon_unit.queue_free()
	for weapon in player_weapon_user_component.weapon_inventory:
		_create_weapon_unit(weapon)

func _create_weapon_unit(weapon: Weapon) -> void:
	var inst: Control = weapon_unit_scene.instantiate()
	inst.get_node("Icon").texture = weapon.icon_texture
	
	var weapon_rarity: String
	match weapon.weapon_rarity:
		weapon.rarity_classes.SHITTY:
			weapon_rarity = "[color=#593200ff]Shitty[/color]"
		weapon.rarity_classes.COMMON:
			weapon_rarity = "[color=#be3000ff]Common[/color]"
		weapon.rarity_classes.ROBUST:
			weapon_rarity = "[color=#ed0052ff]Robust[/color]"
		weapon.rarity_classes.ADMINABUSE:
			weapon_rarity = "[color=#9c01e5ff]AdminAbuse[/color]"
	
	var text: String = "[color="+weapon.color.to_html()+"]"+ weapon.weapon_name + "[/color]\n" + weapon.weapon_class + "\n" + weapon_rarity
	inst.get_node("Name").text = text
	
	weapons_container.add_child.call_deferred(inst)
