class_name VisibleOnScreenVisibleComponent extends Component

@export var visible_on_screen: VisibleOnScreenNotifier2D
@export var sprite: Node2D

func _ready() -> void:
	if sprite:
		visible_on_screen.screen_entered.connect(screen_entered)
		visible_on_screen.screen_exited.connect(screen_exited)

func screen_entered() -> void:
	sprite.show()

func screen_exited() -> void:
	sprite.hide()
