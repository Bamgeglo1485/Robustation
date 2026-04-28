class_name WeaponSlotButtonComponent extends Component

@export var number: int = 0
@export var melee: bool = false

func _ready() -> void:
	parent.pressed.connect(_button_pressed)

func _button_pressed() -> void:
	if !melee:
		EventBusManager.weapon_slot_changed.emit(number)
	else:
		EventBusManager.weapon_slot_changed.emit(69)
