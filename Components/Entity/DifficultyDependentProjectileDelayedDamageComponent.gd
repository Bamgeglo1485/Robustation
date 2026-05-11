class_name DifficultyDependentProjectileDelayedDamageComponent extends Component

@export var damage_on_roleplayer: float = 69
@export var damage_on_agent: float = 69
@export var damage_on_greytide: float = 69

@onready var projectile: ProjectileComponent = parent.get_node_or_null("ProjectileComponent")

func _ready() -> void:
	if !projectile:
		return
	
	match SettingsConfigSystem.difficulty:
		SettingsConfigSystem.difficulties.RPER:
			projectile.delayed_damage = damage_on_roleplayer
		SettingsConfigSystem.difficulties.AGENT:
			projectile.delayed_damage = damage_on_agent
		SettingsConfigSystem.difficulties.GREYTIDE:
			projectile.delayed_damage = damage_on_greytide
