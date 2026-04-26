class_name DifficultyDependentProjectileDamageComponent extends Component

@export var damage_on_roleplayer: int = 69
@export var damage_on_agent: int = 69
@export var damage_on_greytide: int = 69

@onready var projectile: ProjectileComponent = parent.get_node_or_null("ProjectileComponent")

func _ready() -> void:
	if !projectile:
		return
	
	match SettingsConfigSystem.difficulty:
		SettingsConfigSystem.difficulties.RPER:
			projectile.damage = damage_on_roleplayer
		SettingsConfigSystem.difficulties.AGENT:
			projectile.damage = damage_on_agent
		SettingsConfigSystem.difficulties.GREYTIDE:
			projectile.damage = damage_on_greytide
