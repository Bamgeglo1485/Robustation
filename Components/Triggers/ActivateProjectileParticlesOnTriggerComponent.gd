class_name ActivateProjectileParticlesOnTriggerComponent extends BaseXOnTriggerComponent

@onready var projectile: ProjectileComponent = parent.get_node_or_null("ProjectileComponent")

func _ready() -> void:
	super._ready()
	
	if projectile and projectile.particle_emitter:
		projectile.particle_emitter.emitting = false

func on_trigger():
	if projectile and projectile.particle_emitter:
		projectile.particle_emitter.emitting = true
