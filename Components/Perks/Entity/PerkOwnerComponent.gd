class_name PerkOwnerComponent extends Component

var perks: Array[PerkComponent]
var ui_perks: Dictionary
var perk_notification_queue: Array[PerkComponent]
@export var perk_ui: GridContainer
@export var perk_notification_ui: CanvasLayer
@export var perk_unit: PackedScene = preload("res://Scenes/UI/IngameInterface/Perks/PerkUnit.tscn")
@export var perk_notification_unit: PackedScene = preload("res://Scenes/UI/IngameInterface/Perks/PerkNotification.tscn")
@export var perk_collect_sound: AudioStreamPlayer2D

@onready var minor_stat_container: Container

func _ready() -> void:
	if parent.has_node("GUI"):
		minor_stat_container = parent.get_node("GUI").get_node("Touchable").get_node("Characteristics").get_node("MinorStats").get_node("MinorStats")

func add_perk(new_perk: PackedScene, amount: int = 1) -> void:
	if !new_perk:
		return
	
	if perk_collect_sound:
		perk_collect_sound.play()
	
	var existing_perk = get_perk_by_data(new_perk)
	if existing_perk:
		existing_perk.amount += amount
		existing_perk._update_modifiers()
		update_perk_ui(existing_perk)
		queue_notification(existing_perk)
		return
	
	var perk_instance = new_perk.instantiate() as PerkComponent
	perk_instance.minor_stat_container = minor_stat_container
	perk_instance.amount = amount
	perks.append(perk_instance)
	parent.add_child.call_deferred(perk_instance)
	
	create_perk_ui(perk_instance)
	queue_notification(perk_instance)

func get_perk_by_data(perk_data: PackedScene) -> PerkComponent:
	var temp_instance = perk_data.instantiate() as PerkComponent
	var target_id = temp_instance.perk_data.perk_id
	temp_instance.queue_free()
	
	for perk in perks:
		if perk.perk_data.perk_id == target_id:
			return perk
	return null

func get_perk(perk_type: Script) -> PerkComponent:
	for perk in perks:
		if perk.get_script() == perk_type:
			return perk
	return null

func remove_perk(perk_to_remove: PackedScene, amount: int = 1) -> void:
	var existing_perk = get_perk_by_data(perk_to_remove)
	if !existing_perk:
		return
	
	existing_perk.amount -= amount
	
	if existing_perk.amount <= 0:
		perks.erase(existing_perk)
		remove_perk_ui(existing_perk)
		existing_perk.queue_free()
	else:
		existing_perk._update_modifiers()
		update_perk_ui(existing_perk)

func queue_notification(perk: PerkComponent) -> void:
	perk_notification_queue.append(perk)
	if perk_notification_queue.size() == 1:
		_notification_update()

func _notification_update() -> void:
	while !perk_notification_queue.is_empty():
		var perk = perk_notification_queue[0]
		await create_notification(perk)
		perk_notification_queue.remove_at(0)

func create_notification(perk: PerkComponent) -> void:
	if !perk or !perk_notification_ui:
		return
	
	var inst: Control = perk_notification_unit.instantiate()
	perk_notification_ui.add_child(inst)
	
	var panel: Panel = inst.get_node("Panel")
	panel.get_node("Texture").texture = perk.perk_data.icon_texture
	
	var notif_name = panel.get_node("Name")
	notif_name.text = perk.perk_data.perk_name
	
	panel.get_node("Desc").text = perk.perk_data.perk_description
	
	match perk.perk_data.perk_rarity:
		PerkData.rarity_classes.COMMON:
			notif_name.modulate = Color("be3000ff")
		PerkData.rarity_classes.SHITTY:
			notif_name.modulate = Color("593200ff")
		PerkData.rarity_classes.ROBUST:
			notif_name.modulate = Color("ed0052ff")
		PerkData.rarity_classes.ADMINABUSE:
			notif_name.modulate = Color("9c01e5ff")
	
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

func create_perk_ui(perk: PerkComponent) -> void:
	if !perk_ui or !perk_unit:
		return
	
	var perk_unit_instance = perk_unit.instantiate() as Control
	perk_ui.add_child(perk_unit_instance)
	ui_perks[perk] = perk_unit_instance
	
	setup_perk_ui(perk_unit_instance, perk)

func setup_perk_ui(perk_ui_instance: Control, perk: PerkComponent) -> void:
	var texture_rect = perk_ui_instance.get_node_or_null("TextureRect")
	var label = perk_ui_instance.get_node_or_null("Label")
	
	if texture_rect:
		texture_rect.texture = perk.perk_data.icon_texture
	
	if label:
		if perk.amount > 1:
			label.text = str(perk.amount)
		else:
			label.text = ""

func update_perk_ui(perk: PerkComponent) -> void:
	if !ui_perks.has(perk):
		return
	
	var perk_ui_instance = ui_perks[perk] as Control
	var label = perk_ui_instance.find_child("Label", true, false) as Label
	
	if label:
		if perk.amount > 1:
			label.text = str(perk.amount)
		else:
			label.text = ""

func remove_perk_ui(perk: PerkComponent) -> void:
	if ui_perks.has(perk):
		var perk_ui_instance = ui_perks[perk] as Control
		perk_ui_instance.queue_free()
		ui_perks.erase(perk)

func update_ui() -> void:
	for perk in perks:
		if ui_perks.has(perk):
			update_perk_ui(perk)
		else:
			create_perk_ui(perk)
