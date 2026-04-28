class_name WeaponInventoryComponent extends Component

@export var weapon_slot_buttons: Array[Button]
@export var melee_weapon_slot: Button

@export var description: RichTextLabel
@export var weapons_container: Container

@onready var weapon_notification_ui: CanvasLayer = get_parent().get_parent()
@export var weapon_notification_unit: PackedScene = preload("res://Scenes/UI/IngameInterface/Perks/PerkNotification.tscn")

@export var weapon_collect_sound: AudioStreamPlayer
@export var weapon_added_to_slot_audio: AudioStreamPlayer
@export var weapon_removed_from_slot_audio: AudioStreamPlayer
@export var weapon_selected_audio: AudioStreamPlayer
@export var weapon_deselected_audio: AudioStreamPlayer

var selected_weapon: Weapon

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
	_update_inventory(null)
	
	EventBusManager.weapon_selected.connect(select_weapon)
	EventBusManager.weapon_slot_changed.connect(change_slot)
	player_weapon_user_component.inventory_updated.connect(_update_inventory)

func select_weapon(weapon: Weapon) -> void:
	if !weapon:
		selected_weapon = null
		description.text = ""
		return
	description.text = tr(weapon.weapon_desc)
	selected_weapon = weapon
	if weapon_selected_audio:
		weapon_selected_audio.play()

func change_slot(slot_number: int) -> void:
	if selected_weapon and weapon_added_to_slot_audio:
		weapon_added_to_slot_audio.play()
	elif !selected_weapon and weapon_removed_from_slot_audio:
		weapon_removed_from_slot_audio.play()
	
	if slot_number == 69:
		player_weapon_user_component.melee_weapon = selected_weapon
		select_weapon(null)
		_update_weapon_slots()
		return
	
	var property_name = "weapon_" + str(slot_number)
	player_weapon_user_component.set(property_name, selected_weapon)
	
	select_weapon(null)
	_update_weapon_slots()

func _update_inventory(new_weapon: Weapon) -> void:
	if !player_weapon_user_component:
		return
	
	if new_weapon:
		create_notification(new_weapon)
	
	for weapon_unit in weapons_container.get_children():
		if weapon_unit.name != "Ignore":
			weapon_unit.queue_free()
	for weapon in player_weapon_user_component.weapon_inventory:
		_create_weapon_unit(weapon)
	
	_update_weapon_slots()

func _update_weapon_slots() -> void:
	var weapon_slot_number: int = 0
	for weapon_slot_button in weapon_slot_buttons:
		weapon_slot_number += 1
		var text: RichTextLabel = weapon_slot_button.get_node("Text")
		var weapon_slot_string: String = str(weapon_slot_number)
		text.text = "WEAPON SLOT " + weapon_slot_string
		var weapon: Weapon = player_weapon_user_component.get("weapon_" + weapon_slot_string)
		if weapon:
			text.text += "\n" + _get_color_from_rarity(weapon) + "("+weapon.weapon_name+")"
	
	var melee_text: RichTextLabel = melee_weapon_slot.get_node("Text")
	melee_text.text = "QUICK SLOT"
	if player_weapon_user_component.melee_weapon:
		melee_text.text += "\n" + _get_color_from_rarity(player_weapon_user_component.melee_weapon) + "("+player_weapon_user_component.melee_weapon.weapon_name+")"

func _create_weapon_unit(weapon: Weapon) -> void:
	if !weapon:
		return
	var inst: Control = weapon_unit_scene.instantiate()
	inst.get_node("Icon").texture = weapon.icon_texture
	
	var weapon_rarity: String = _get_weapon_rarity_text(weapon)
	
	var text: String = "[color="+weapon.color.to_html()+"]"+ weapon.weapon_name + "[/color]\n" + weapon.weapon_class + "\n" + weapon_rarity
	inst.get_node("Name").text = text
	inst.get_node("Button").get_node("WeaponSelectButtonComponent").weapon = weapon
	
	weapons_container.add_child.call_deferred(inst)

func _get_weapon_rarity_text(weapon: Weapon) -> String:
	var weapon_rarity: String = _get_color_from_rarity(weapon)
	match weapon.weapon_rarity:
		weapon.rarity_classes.SHITTY:
			weapon_rarity += "Shitty[/color]"
		weapon.rarity_classes.COMMON:
			weapon_rarity += "Common[/color]"
		weapon.rarity_classes.ROBUST:
			weapon_rarity += "Robust[/color]"
		weapon.rarity_classes.ADMINABUSE:
			weapon_rarity += "AdminAbuse[/color]"
	return weapon_rarity

func _get_color_from_rarity(weapon: Weapon) -> String:
	var weapon_rarity: String
	match weapon.weapon_rarity:
		weapon.rarity_classes.SHITTY:
			weapon_rarity = "[color=593200ff]"
		weapon.rarity_classes.COMMON:
			weapon_rarity = "[color=be3000ff]"
		weapon.rarity_classes.ROBUST:
			weapon_rarity = "[color=ed0052ff]"
		weapon.rarity_classes.ADMINABUSE:
			weapon_rarity = "[color=9c01e5ff]"
	return weapon_rarity

func create_notification(weapon: Weapon) -> void:
	if !weapon or !weapon_notification_ui:
		return
	
	if weapon_collect_sound:
		weapon_collect_sound.play()
	
	var inst: Control = weapon_notification_unit.instantiate()
	weapon_notification_ui.add_child(inst)
	var panel: Panel = inst.get_node("Panel")
	panel.get_node("Texture").texture = weapon.icon_texture
	var notif_name = panel.get_node("Name")
	notif_name.text = weapon.weapon_name
	panel.get_node("Desc").text = weapon.weapon_class + '\n' + _get_weapon_rarity_text(weapon)
	
	panel.modulate = Color(0.0, 0.0, 0.0, 0.0)

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	
	await get_tree().create_timer(1.5).timeout
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(panel, "modulate", Color(3.705, 3.705, 3.705, 0.0), 0.5)
	
	await get_tree().create_timer(0.5).timeout
	inst.queue_free()
