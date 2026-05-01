class_name RegenerationComponent extends Component

@export var regeneration: float = 0.0 : set = set_regeneration

@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
var regeneration_timer: Timer

@export_category("Modifier")
@export var regeneration_multipliers: Dictionary
@export var regeneration_multiplier: float = 1.0
@export var regeneration_addendums: Dictionary
@export var regeneration_addendum: float = 0.0 : set = set_regeneration_addendum

func _ready():
	regeneration_timer = Timer.new()
	regeneration_timer.wait_time = 1.0
	regeneration_timer.one_shot = true
	regeneration_timer.timeout.connect(_regenerate)
	regeneration_timer.ignore_time_scale = true
	regeneration_timer.autostart = true
	add_child(regeneration_timer)

func _regenerate() -> void:
	if regeneration + regeneration_addendum == 0:
		return
	regeneration_timer.start()
	health_component.health += (regeneration + regeneration_addendum) * regeneration_multiplier

func set_regeneration(new_value: float) -> void:
	regeneration = new_value
	if regeneration_timer:
		regeneration_timer.start()

func set_regeneration_addendum(new_value: float) -> void:
	regeneration_addendum = new_value
	if regeneration_timer:
		regeneration_timer.start()
