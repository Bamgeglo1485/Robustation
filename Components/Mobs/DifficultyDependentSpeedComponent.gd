class_name DifficultyDependentSpeedComponent extends Component

@export var speed_modifier_on_roleplayer: float = 0.8
@export var speed_modifier_on_agent: float = 1.0
@export var speed_modifier_on_greytide: float = 1.1

@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")

func _ready() -> void:
	if !mob_mover_component:
		return
	await tree.create_timer(0.2).timeout
	match SettingsConfigSystem.difficulty:
		SettingsConfigSystem.difficulties.RPER:
			mob_mover_component.speed *= speed_modifier_on_roleplayer
			mob_mover_component.base_max_speed *= speed_modifier_on_roleplayer
			mob_mover_component.max_speed *= speed_modifier_on_roleplayer
		SettingsConfigSystem.difficulties.AGENT:
			mob_mover_component.speed *= speed_modifier_on_agent
			mob_mover_component.base_max_speed *= speed_modifier_on_agent
			mob_mover_component.max_speed *= speed_modifier_on_agent
		SettingsConfigSystem.difficulties.GREYTIDE:
			mob_mover_component.speed *= speed_modifier_on_greytide
			mob_mover_component.base_max_speed *= speed_modifier_on_greytide
			mob_mover_component.max_speed *= speed_modifier_on_greytide
