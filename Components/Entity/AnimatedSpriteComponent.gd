class_name AnimatedSpriteComponent extends Component

var max_x: int
var max_y: int
var animation_timer: Timer

@export var animation_h_frames: int
@export var animation_w_frames: int
@export var frame_resolution: int = 32
@export var frame_delay: float = 0.1

func _ready() -> void:
	if !parent.texture or parent.texture is not AtlasTexture:
		return
	
	max_x = animation_h_frames * frame_resolution
	max_y = animation_w_frames * frame_resolution
	animation_timer = Timer.new()
	add_child(animation_timer)
	animation_timer.one_shot = true
	animation_timer.wait_time = frame_delay
	animation_timer.timeout.connect(_animation_process)
	animation_timer.start()
	
func _animation_process() -> void:
	animation_timer.start()
	if !parent.visible or !parent.texture or parent.texture is not AtlasTexture:
		return
	
	var new_x = parent.texture.region.position.x + frame_resolution
	var new_y = parent.texture.region.position.y
	
	if new_x >= max_x:
		new_x = 0
		new_y += frame_resolution
		
		if new_y >= max_y:
			new_y = 0
	
	parent.texture.region.position = Vector2(new_x, new_y)
