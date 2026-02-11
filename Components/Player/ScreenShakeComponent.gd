class_name ScreenShakeComponent extends Component

@onready var camera: PlayerCamera = parent.get_node_or_null("PlayerCamera")

func shift_to_direction(direction, power) -> void:
	if !camera:
		return
	
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(camera, "position", direction.normalized() * power, 0.2)
	_tween.tween_property(camera, "position", Vector2.ZERO, 0.2)

func shake(power, delay) -> void:
	if !camera:
		return
	
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	
	for i in delay:
		randomize()
		var x: float = randf_range(-power, power)
		var y: float = randf_range(-power, power)
		x = clamp(x, 0, 64)
		y = clamp(x, 0, 64)
		_tween.tween_property(camera, "position", Vector2(x, y), 0.1)
		_tween.tween_property(camera, "position", Vector2.ZERO, 0.1)

func _ready() -> void:
	EventBusManager.projectile_shoot.connect(_on_projectile_shoot)
	EventBusManager.damaged.connect(_on_damaged)
	EventBusManager.explosion.connect(_on_explosion)

func _on_explosion(explosion):
	var direction: Vector2 = (parent.global_position - explosion.global_position)
	shift_to_direction(direction, explosion.damage * 0.5)
	shake(explosion.damage / 3, 2)

func _on_damaged(emitter, damage, damager) -> void:
	if emitter != parent:
		return
	
	if damager:
		var direction = (parent.global_position - damager.global_position)
		shift_to_direction(direction, damage * 2)

func _on_projectile_shoot(emitter, weapon, direction, projectile) -> void:
	if emitter == parent:
		var projectile_component: ProjectileComponent = projectile.get_node("ProjectileComponent")
		if !projectile_component:
			return
		var power: float = projectile_component.damage * weapon.shots
		shift_to_direction(-direction, power * 0.1)
