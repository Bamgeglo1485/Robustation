class_name SliderPercentageComponent extends Component

@export var percentage_frame: Label
@export var percentage_symbol: String = "%"

func _ready() -> void:
	_on_changed(parent.value)
	parent.value_changed.connect(_on_changed)

func _on_changed(new_value) -> void:
	if percentage_frame:
		percentage_frame.text = str(int(new_value)) + percentage_symbol
