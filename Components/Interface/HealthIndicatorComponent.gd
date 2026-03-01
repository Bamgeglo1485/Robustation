class_name HealthIndicatorComponent extends Component

@export var health_0: Texture2D
@export var health_1: Texture2D
@export var health_2: Texture2D
@export var health_3: Texture2D
@export var health_4: Texture2D
@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
@export var texture_rect: TextureRect

var color: Color = Color(0.0, 0.706, 0.237, 1.0)

func _ready() -> void:
	
	EventBusManager.health_changed.connect(_on_health_changed)

func _on_health_changed(emitter, _health, new_health) -> void:
	if emitter != parent:
		return
	
	var ne_pridumal: float = float(new_health) / health_component.max_health
	if ne_pridumal <= 0.2:
		texture_rect.texture.atlas = health_4
		color = Color(0.934, 0.0, 0.295, 1.0)
	elif ne_pridumal <= 0.4:
		texture_rect.texture.atlas = health_3
		color = Color(0.961, 0.311, 0.0, 1.0)
	elif ne_pridumal <= 0.6:
		texture_rect.texture.atlas = health_2
		color = Color(0.684, 0.568, 0.0, 1.0)
	elif ne_pridumal <= 0.8:
		texture_rect.texture.atlas = health_1
		color = Color(0.52, 0.642, 0.0, 1.0)
	else:
		texture_rect.texture.atlas = health_0
		color = Color(0.0, 0.706, 0.237, 1.0)
