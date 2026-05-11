class_name DifficultyDependentHealthComponent extends Component

@export var health_on_roleplayer: float = 69
@export var health_on_agent: float = 69
@export var health_on_greytide: float = 69

@onready var health_component: HealthComponent = parent.get_node("HealthComponent")

func _ready() -> void:
	if !health_component:
		return
	
	var health: float
	match SettingsConfigSystem.difficulty:
		SettingsConfigSystem.difficulties.RPER:
			health = health_on_roleplayer
		SettingsConfigSystem.difficulties.AGENT:
			health = health_on_agent
		SettingsConfigSystem.difficulties.GREYTIDE:
			health = health_on_greytide
	health_component.base_max_health = health
	health_component.max_health = health
	health_component.health = health
	
	health_component.base_max_health *= GlobalVariables.enemy_health_modifier
	health_component.max_health *= GlobalVariables.enemy_health_modifier
	health_component.health *= GlobalVariables.enemy_health_modifier 
