class_name DifficultyDependentWeaponDamageComponent extends Component

@export var damage_on_roleplayer: int = 69
@export var damage_on_agent: int = 69
@export var damage_on_greytide: int = 69

func _ready() -> void:
	match SettingsConfigSystem.difficulty:
		SettingsConfigSystem.difficulties.RPER:
			parent.set_multiplier("damage", "difficulty", damage_on_roleplayer)
		SettingsConfigSystem.difficulties.AGENT:
			parent.set_multiplier("damage", "difficulty", damage_on_agent)
		SettingsConfigSystem.difficulties.GREYTIDE:
			parent.set_multiplier("damage", "difficulty", damage_on_greytide)
