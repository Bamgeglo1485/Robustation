class_name DirectionalSprite extends Sprite2D

var parent: Node = get_parent()
@onready var direction_component : DirectionComponent = get_direction_component()

@export var random_textures : Array[Texture2D]
@export var random_color : bool = false

func _notification(notif):
	if notif == NOTIFICATION_PARENTED:
		parent = get_parent()
		direction_component = get_direction_component()

func get_direction_component() -> DirectionComponent:
	if parent.has_node("DirectionComponent"):
		return parent.get_node("DirectionComponent")
	else:
		return null

func _ready() -> void:
	if direction_component:
		direction_component.direction_changed.connect(change_sprite_direction)
	if !random_textures.is_empty():
		texture = random_textures.pick_random()
	if random_color:
		self_modulate = Color(randf_range(0,0.4), randf_range(0,0.4), randf_range(0,0.4))
	
	#var notifier: VisibleOnScreenNotifier2D = VisibleOnScreenNotifier2D.new()
	#add_child.call_deferred(notifier)
	#notifier.screen_entered.connect(_on_screen_entered)
	#notifier.screen_exited.connect(_on_screen_exited)

func change_sprite_direction(rect: Rect2):
	region_rect = rect

func _on_screen_entered():
	visible = true

func _on_screen_exited():
	visible = false
