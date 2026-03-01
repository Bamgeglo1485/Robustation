class_name RotatingToObjectComponent extends Component

@export var object: Node2D
@export var set_player: bool = true
@export var modify_scale: bool = true

func _ready() -> void:
	if set_player:
		object = scene.get_node_or_null("Player")

func _physics_process(_delta: float) -> void:
	if !object:
		return
	
	var direction: Vector2 = (object.global_position - parent.global_position)
	var angle: float = direction.angle()
	parent.rotation = angle
	
	if !modify_scale:
		return
	
	var cone_scale: float = clamp(direction.length() / 170, 0.15, 3.0)
	parent.scale = Vector2(cone_scale, cone_scale / 2)
	parent.global_rotation = angle
