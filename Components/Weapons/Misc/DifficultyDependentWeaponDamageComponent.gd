class_name DifficultyDependentWeaponDamageComponent extends Component

@export var damage_on_roleplayer: float = 0.5
@export var damage_on_agent: float = 1.0
@export var damage_on_greytide: float = 1.5

func _ready() -> void:
	match SettingsConfigSystem.difficulty:
		SettingsConfigSystem.difficulties.RPER:
			parent.set_multiplier("damage", "difficulty", damage_on_roleplayer)
		SettingsConfigSystem.difficulties.AGENT:
			parent.set_multiplier("damage", "difficulty", damage_on_agent)
		SettingsConfigSystem.difficulties.GREYTIDE:
			parent.set_multiplier("damage", "difficulty", damage_on_greytide)
