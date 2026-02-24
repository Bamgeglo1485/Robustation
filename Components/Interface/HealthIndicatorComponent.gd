class_name HealthIndicatorComponent extends Component

@export var health_0: Texture2D
@export var health_1: Texture2D
@export var health_2: Texture2D
@export var health_3: Texture2D
@export var health_4: Texture2D
@export var animation_h_frames: int
@export var animation_w_frames: int
@export var texture_rect: TextureRect
@export var frame_resolution: int = 32
@export var frame_delay: float = 0.1
@onready var health_component: HealthComponent = parent.get_node_or_null("HealthComponent")
var max_x: int
var max_y: int
var animation_timer: Timer
var color: Color = Color(0.0, 0.706, 0.237, 1.0)

func _ready() -> void:
	if !texture_rect or !health_component:
		return
	
	max_x = animation_h_frames * frame_resolution
	max_y = animation_w_frames * frame_resolution
	animation_timer = Timer.new()
	add_child(animation_timer)
	animation_timer.one_shot = true
	animation_timer.wait_time = frame_delay
	animation_timer.timeout.connect(_animation_process)
	animation_timer.start()
	
	texture_rect.texture = texture_rect.texture
	
	EventBusManager.health_changed.connect(_on_health_changed)

func _animation_process() -> void:
	animation_timer.start()
	if !texture_rect.texture:
		return
	
	var new_x = texture_rect.texture.region.position.x + frame_resolution
	var new_y = texture_rect.texture.region.position.y
	
	if new_x >= max_x:
		new_x = 0
		new_y += frame_resolution
		
		if new_y >= max_y:
			new_y = 0
	
	texture_rect.texture.region.position = Vector2(new_x, new_y)

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
