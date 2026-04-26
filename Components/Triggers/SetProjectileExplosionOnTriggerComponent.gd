class_name SetProjectileExplosionOnTriggerComponent extends BaseXOnTriggerComponent

@export var explosion_scene: PackedScene
@export var delete_on_hit: bool = true
@export var explode_on_delete: bool = false
@export var explode_on_hit: bool = false
@export var explode_on_damage: bool = false
@export var explode_lifetime: float = 0.3
@export var speed: int = 69

func on_trigger() -> void:
	var projectile: ProjectileComponent = parent.get_node_or_null("ProjectileComponent")
	if projectile:
		projectile.explode_on_delete = explode_on_delete
		projectile.explode_on_hit = explode_on_hit
		projectile.explode_on_damage = explode_on_damage
		projectile.delete_on_hit = delete_on_hit
		if speed != 69:
			projectile.speed = speed
		
		if explosion_scene:
			projectile.explosion_scene = explosion_scene
		
		if !explode_on_delete:
			return
		
		if explode_lifetime != 0:
			await get_tree().create_timer(explode_lifetime).timeout
			
			projectile._delete()
