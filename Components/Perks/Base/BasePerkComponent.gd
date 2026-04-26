@abstract
class_name BasePerkComponent extends Component

enum rarity_classes {
	SHITTY,
	COMMON,
	ROBUST,
	ADMINABUSE
}

@export var perk_equipped_texture: Texture
@export var perk_icon: Texture
@export var perk_name: String
@export var perk_desc: String
@export var amount: int = 1: set = set_amount, get = get_amount
@export var rarity: rarity_classes = rarity_classes.COMMON
@export var minor_stat_control_scene: PackedScene = preload("res://Scenes/UI/IngameInterface/BaseMinorStat.tscn")
var minor_stat_control: Control
var second_minor_stat_control: Control
var minor_stat_container: Container

var untranslated_perk_name: String
var sprite: DirectionalSprite

func _ready() -> void:
	name = get_script().get_global_name()
	if perk_equipped_texture:
		sprite = DirectionalSprite.new()
		sprite.name = untranslated_perk_name
		sprite.texture = perk_equipped_texture
		sprite.region_enabled = true
		parent.add_child.call_deferred(sprite)

func set_amount(new_amount: int) -> void:
	if new_amount <= 0:
		queue_free()
		return
	
	amount = new_amount
	apply_modifiers()

func _enter_tree() -> void:
	if !is_node_ready():
		await ready
	await tree.physics_frame
	apply_modifiers()

func set_minor_stat(text: String, id: String) -> void:
	if !minor_stat_container:
		return
	if minor_stat_control:
		minor_stat_control.text = text
	else:
		var already_exist: Control = minor_stat_container.get_node_or_null(id)
		if !already_exist:
			var inst: Control = minor_stat_control_scene.instantiate()
			minor_stat_container.add_child.call_deferred(inst)
			inst.text = text
			inst.name = id
			minor_stat_control = inst
		else:
			minor_stat_control = already_exist
			already_exist.text = text

func set_second_minor_stat(text: String, id: String) -> void:
	if !minor_stat_container:
		return
	if second_minor_stat_control:
		second_minor_stat_control.text = text
	else:
		var already_exist: Control = minor_stat_container.get_node_or_null(id)
		if !already_exist:
			var inst: Control = minor_stat_control_scene.instantiate()
			minor_stat_container.add_child.call_deferred(inst)
			inst.text = text
			inst.name = id
			second_minor_stat_control = inst
		else:
			second_minor_stat_control = already_exist
			already_exist.text = text

func get_amount() -> int:
	return amount

func apply_modifiers() -> void:
	pass

func get_perk_name() -> String:
	return untranslated_perk_name
