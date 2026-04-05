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

var untranslated_perk_name: String
var sprite: DirectionalSprite

func _ready() -> void:
	name = get_script().get_global_name()
	apply_modifiers()
	
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

func get_amount() -> int:
	return amount

func apply_modifiers() -> void:
	pass

func get_perk_name() -> String:
	return untranslated_perk_name
