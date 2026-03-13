class_name WorldEnvComponent extends Component

func _ready() -> void:
	parent.environment.glow_enabled = SettingsConfigSystem.glow
	EventBusManager.glow_changed.connect(_glow_changed)

func _glow_changed(glow: bool):
	parent.environment.glow_enabled = glow
