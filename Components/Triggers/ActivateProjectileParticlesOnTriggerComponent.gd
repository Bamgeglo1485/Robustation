class_name ActivateProjectileParticlesOnTriggerComponent extends BaseXOnTriggerComponent

@onready var projectile: ProjectileComponent = parent.get_node_or_null("ProjectileComponent")

func _init() -> void:
	super._init()
	
	if projectile and projectile.particle_emitter:
		projectile.particle_emitter.emitting = false

func on_trigger():
	if projectile and projectile.particle_emitter:
		projectile.particle_emitter.emitting = true
