@abstract
class_name BasePerkComponent extends Component

@export var perk_name: String
@export var perk_desc: String
@export var amount: int = 1: set = set_amount, get = get_amount

func _ready() -> void:
	apply_modifiers()

func set_amount(new_amount: int) -> void:
	amount = new_amount
	apply_modifiers()

func get_amount() -> int:
	return amount

func apply_modifiers() -> void:
	pass
