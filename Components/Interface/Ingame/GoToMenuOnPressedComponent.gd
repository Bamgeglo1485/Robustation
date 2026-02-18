class_name ChangeSceneOnPressedComponent extends Component

@export var new_scene: PackedScene

func _ready() -> void:
	if parent is not Button:
		return
	
	parent.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if !new_scene:
		return
	
	get_tree().change_scene_to_file(new_scene.resource_path)
