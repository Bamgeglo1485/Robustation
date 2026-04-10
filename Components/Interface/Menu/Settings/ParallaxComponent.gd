class_name ParallaxComponent extends Component

func _ready() -> void:
	parent.visible = SettingsConfigSystem.parallax
	EventBusManager.parallax_changed.connect(_parallax_changed)

func _parallax_changed(parallax: bool):
	parent.visible = parallax
