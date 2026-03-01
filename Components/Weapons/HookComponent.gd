class_name Hook extends RangeWeapon

@export var rope: Line2D
var hook: Node2D

func _process(_delta: float) -> void:
	if !rope or !hook:
		return
	
	rope.points[1] = parent.to_local(hook.global_position)

func _projectile_shoot(direction) -> Node2D:
	hook = super._projectile_shoot(direction)
	if !hook:
		return null
	
	
	
	return hook
