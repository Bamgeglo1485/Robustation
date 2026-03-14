class_name PerkOwnerComponent extends Component

var perks: Array[BasePerkComponent]
var ui_perks: Dictionary
var perk_notification_queue: Array[BasePerkComponent]
@export var perk_ui: GridContainer
@export var perk_notification_ui: CanvasLayer
@export var perk_unit: PackedScene = preload("res://Scenes/UI/IngameInterface/Perks/PerkUnit.tscn")
@export var perk_notification_unit: PackedScene = preload("res://Scenes/UI/IngameInterface/Perks/PerkNotification.tscn")
@export var perk_collect_sound: AudioStreamPlayer2D

@export var can_collect: bool = false

func add_perk(new_perk, amount = 1) -> void:
	if perk_collect_sound:
		perk_collect_sound.play()
	
	var existing_perk = get_perk(new_perk)
	if existing_perk:
		existing_perk.amount += amount
		update_perk_ui(existing_perk)
		
		perk_notification_queue.append(existing_perk)
		if perk_notification_queue.size() == 1:
			_notification_update()
		return
	
	var perk_instance = new_perk.new()
	perk_instance.amount = amount
	perks.append(perk_instance)
	parent.add_child.call_deferred(perk_instance)
	
	perk_notification_queue.append(perk_instance)
	if perk_notification_queue.size() == 1:
		_notification_update()
	
	create_perk_ui(perk_instance)

func get_perk(perk_type):
	for perk in perks:
		var perk_type_inst = perk_type.new()
		if perk.get_perk_name() == perk_type_inst.get_perk_name():
			return perk
		perk_type_inst.queue_free()
		
	return null

func remove_perk(perk_to_remove, amount = 1) -> void:
	var existing_perk = get_perk(perk_to_remove)
	if !existing_perk:
		return
	
	existing_perk.amount -= amount
	
	if existing_perk.amount <= 0:
		perks.erase(existing_perk)
		existing_perk.queue_free()
		
		remove_perk_ui(existing_perk)
	else:
		update_perk_ui(existing_perk)

func create_perk_ui(perk: BasePerkComponent) -> void:
	if !perk_ui or !perk_unit:
		return
	
	var perk_unit_instance = perk_unit.instantiate() as Control
	perk_ui.add_child(perk_unit_instance)
	ui_perks[perk] = perk_unit_instance
	
	setup_perk_ui(perk_unit_instance, perk)

func setup_perk_ui(perk_ui_instance: Control, perk: BasePerkComponent) -> void:
	var texture_rect = perk_ui_instance.get_node_or_null("TextureRect")
	var label = perk_ui_instance.get_node_or_null("Label")
	
	if texture_rect:
		texture_rect.texture = perk.perk_icon	
	if label:
		if perk.amount > 1:
			label.text = str(perk.amount)
		else:
			label.text = ""

func update_perk_ui(perk: BasePerkComponent) -> void:
	if !ui_perks.has(perk):
		return
	
	var perk_ui_instance = ui_perks[perk] as Control
	var label = perk_ui_instance.find_child("Label", true, false) as Label
	
	if label:
		if perk.amount > 1:
			label.text = str(perk.amount)
		else:
			label.text = ""

func remove_perk_ui(perk: BasePerkComponent) -> void:
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

func _notification_update() -> void:
	if !perk_notification_queue.is_empty():
		for perk in perk_notification_queue:
			await create_notification(perk)
	perk_notification_queue.clear()

# shitcode yep
func create_notification(perk: BasePerkComponent) -> void:
	if !perk or !perk_notification_ui:
		return
	
	var inst: Control = perk_notification_unit.instantiate()
	perk_notification_ui.add_child(inst)
	var panel: Panel = inst.get_node("Panel")
	panel.get_node("Texture").texture = perk.perk_icon
	var notif_name = panel.get_node("Name")
	notif_name.text = perk.perk_name
	panel.get_node("Desc").text = perk.perk_desc
	
	if perk.rarity == perk.rarity_classes.COMMON:
		notif_name.modulate = Color(0.744, 0.188, 0.0, 1.0)
	elif perk.rarity == perk.rarity_classes.SHITTY:
		notif_name.modulate = Color(0.348, 0.197, 0.0, 1.0)
	elif perk.rarity == perk.rarity_classes.ROBUST:
		notif_name.modulate = Color(0.931, 0.0, 0.323, 1.0)
	elif perk.rarity == perk.rarity_classes.ADMINABUSE:
		notif_name.modulate = Color(0.613, 0.003, 0.899, 1.0)
	
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
	
	perk_notification_queue.remove_at(0)
	inst.queue_free()
