class_name OrganComponent extends PhysicalParticleComponent

@export var area2d: Area2D
@export var step_sound: AudioStreamPlayer2D
@export var blood_scene: PackedScene = preload("res://Scenes/Effects/Particles/Blood.tscn")
@export var health_bonus: float = 8

func _ready() -> void:
	parent.reparent.call_deferred(scene)
	if area2d:
		area2d.body_entered.connect(_on_step)
	super._ready()

func _on_step(_body) -> void:
	if accelerating or cleaning:
		return
	
	if blood_scene:
		var _effect: Node = blood_scene.instantiate()
		_effect.global_position = _body.global_position
		scene.add_child.call_deferred(_effect)
		var health_component: HealthComponent = _body.get_node("HealthComponent")
		if health_component:
			_effect.rotation = _body.velocity.angle()
			health_component.take_damage(-health_bonus * health_component.healing_from_organs_multiplier, null, "Heal", true)
	
	if step_sound:
		step_sound.global_position = _body.global_position
		step_sound.play()
		area2d.set_deferred("monitoring", false)
		area2d.set_deferred("monitorable", false)
		parent.visible = false
		await step_sound.finished
	
	parent.queue_free()
