class_name ScreenShakeComponent extends Component

@onready var camera = parent.get_node_or_null("PlayerCamera")

func shift_to_direction(direction, power):
	if camera == null:
		return
	
	var _tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(camera, "position", direction.normalized() * power, 0.2)
	_tween.tween_property(camera, "position", Vector2.ZERO, 0.2)

func shake(power, delay):
	if camera == null:
		return
	
	var _tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	
	for i in delay:
		randomize()
		var x = randf_range(-power, power)
		var y = randf_range(-power, power)
		x = clamp(x, 0, 64)
		y = clamp(x, 0, 64)
		_tween.tween_property(camera, "position", Vector2(x, y), 0.1)
		_tween.tween_property(camera, "position", Vector2.ZERO, 0.1)

func _ready() -> void:
	EventBusManager.gun_shoot_event.connect(_on_gun_shoot)
	EventBusManager.damaged.connect(_on_damaged)
	EventBusManager.explosion.connect(_on_explosion)

func _on_explosion(explosion):
	var direction = (parent.global_position - explosion.global_position)
	shift_to_direction(direction, explosion.damage / 2)
	shake(explosion.damage / 3, 2)

func _on_damaged(emitter, damage, damager):
	if emitter != parent:
		return
	
	if damager != null:
		var direction = (parent.global_position - damager.global_position)
		shift_to_direction(direction, damage * 2)

func _on_gun_shoot(emitter, weapon, direction):
	if emitter == parent:
		var projectile = weapon.projectile.instantiate()
		var projectile_component = projectile.get_node_or_null("ProjectileComponent")
		if projectile_component == null:
			return
		var power = projectile_component.damage * weapon.shots
		shift_to_direction(-direction, power / 10)
		projectile.queue_free()
