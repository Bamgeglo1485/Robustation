class_name WeaponSelectButtonComponent extends Component

@export var weapon: Weapon
var state: bool = false

func _ready() -> void:
	parent.pressed.connect(_button_pressed)
	EventBusManager.weapon_selected.connect(_weapon_selected)
	EventBusManager.weapon_slot_changed.connect(_weapon_slot_changed)

func _button_pressed() -> void:
	state = !state
	if state:
		EventBusManager.weapon_selected.emit(weapon)
	else:
		EventBusManager.weapon_selected.emit(null)

func _weapon_selected(selected_weapon: Weapon) -> void:
	if selected_weapon == weapon or selected_weapon == null:
		return
	parent.button_pressed = false
	state = false

func _weapon_slot_changed(_number: int) -> void:
	parent.button_pressed = false
	state = false
