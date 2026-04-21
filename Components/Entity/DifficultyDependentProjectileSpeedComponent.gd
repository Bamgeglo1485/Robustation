class_name DifficultyDependentProjectileSpeedComponent extends BaseXOnTriggerComponent

@export var speed_on_roleplayer: int = 69
@export var speed_on_agent: int = 69
@export var speed_on_greytide: int = 69

@onready var projectile: ProjectileComponent = parent.get_node_or_null("ProjectileComponent")

func _ready() -> void:
	if !projectile:
		return
	
	match SettingsConfigSystem.difficulty:
		SettingsConfigSystem.difficulties.RPER:
			projectile.speed = speed_on_roleplayer
		SettingsConfigSystem.difficulties.AGENT:
			projectile.speed = speed_on_agent
		SettingsConfigSystem.difficulties.GREYTIDE:
			projectile.speed = speed_on_greytide
