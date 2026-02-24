class_name StaminaIndicatorComponent extends Component

@export var stamina_0: Texture2D
@export var stamina_1: Texture2D
@export var stamina_2: Texture2D
@export var stamina_3: Texture2D
@export var stamina_4: Texture2D
@export var texture_rect: TextureRect

@onready var stamina_component: StaminaComponent = parent.get_node_or_null("StaminaComponent")

var color: Color = Color(0.0, 0.636, 0.856, 1.0)

func _ready() -> void:
	if !texture_rect or !stamina_component:
		return
	
	if texture_rect.texture:
		texture_rect.texture = texture_rect.texture
	
	EventBusManager.stamina_changed.connect(_on_stamina_changed)
	
	_update_stamina_indicator(stamina_component.stamina)

func _on_stamina_changed(emitter, _old_stamina, new_stamina) -> void:
	if emitter != parent:
		return
	
	_update_stamina_indicator(new_stamina)

func _update_stamina_indicator(stamina_value: float) -> void:
	if !texture_rect:
		return
	
	var ne_pridumal: float = float(stamina_value) / stamina_component.max_stamina
	
	if ne_pridumal <= 0.2:
		texture_rect.texture = stamina_4
		color = Color(0.934, 0.0, 0.295, 1.0)
	elif ne_pridumal <= 0.4:
		texture_rect.texture = stamina_3
		color = Color(0.961, 0.311, 0.0, 1.0)
	elif ne_pridumal <= 0.6:
		texture_rect.texture = stamina_2
		color = Color(0.684, 0.568, 0.0, 1.0)
	elif ne_pridumal <= 0.8:
		texture_rect.texture = stamina_1
		color = Color(0.205, 0.7, 0.0, 1.0)
	else:
		texture_rect.texture = stamina_0
		color = Color(0.0, 0.651, 0.782, 1.0)
