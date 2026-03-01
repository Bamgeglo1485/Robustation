class_name DashAbilityComponent extends Component

@export var trail_effect: bool = true
@export var dash_sound: AudioStreamPlayer2D
@export var overdose_refuel_sound: AudioStreamPlayer2D
@export var overdose_refuel_damage: int = 5
@export var overdose_refuel_damage_time: int = 8
@export var overdose_refuel_count: float = 1.5
@export var ability_icon: TextureRect

@export var cooldown: bool = false
@export var cooldown_delay: float = 0.5

@export var dash_speed: int = 1050

@export var max_dash_stamina: int = 3
@export var dash_stamina: int = max_dash_stamina
@export var dash_stamina_recovery_delay: float = 3.0

@export var invincibility_delay: float = 0.3
@export var trail_colors: Array[Color]

@export var parry_weapon: MeleeWeapon

@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
var recovery_timer: Timer
var active: bool = false
var progress_tween: Tween
var stamina_tween: Tween
var current_stamina_progress: float = 0.0

func _ready() -> void:
	recovery_timer = Timer.new()
	add_child(recovery_timer)
	recovery_timer.wait_time = dash_stamina_recovery_delay
	recovery_timer.one_shot = true
	recovery_timer.start()
	recovery_timer.timeout.connect(_stamina_recovery)
	
	if parent.has_node("Area2D"):
		parent.get_node("Area2D").body_entered.connect(_on_collision)
	
	_update_stamina_bar()
	
	EventBusManager.projectile_shoot.connect(_on_shoot)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("dash"):
		var direction: Vector2 = mob_mover_component.direction
		if direction == Vector2.ZERO:
			direction = (parent.get_global_mouse_position() - parent.global_position)
		
		dash(direction)

func _update_stamina_bar():
	if !ability_icon or !ability_icon.material:
		return
	
	var target_progress = 1.0 - (float(dash_stamina) / float(max(1, max_dash_stamina)))
	
	if stamina_tween:
		stamina_tween.kill()
		stamina_tween = null
	
	stamina_tween = create_tween()
	stamina_tween.set_ignore_time_scale(true)
	stamina_tween.set_trans(Tween.TRANS_SINE)
	stamina_tween.set_ease(Tween.EASE_OUT)
	stamina_tween.tween_method(_set_stamina_progress, current_stamina_progress, target_progress, 0.3)

func _set_stamina_progress(value: float):
	current_stamina_progress = value
	if ability_icon and ability_icon.material:
		ability_icon.material.set_shader_parameter("progress", value)

func dash(direction) -> void:
	if !mob_mover_component or parent is not CharacterBody2D:
		return
	if dash_stamina == 0 or cooldown or direction == Vector2.ZERO:
		return
	
	var old_stamina = dash_stamina
	dash_stamina -= 1
	
	if ability_icon and ability_icon.material:
		if progress_tween:
			progress_tween.kill()
		
		var old_progress = 1.0 - (float(old_stamina) / float(max(1, max_dash_stamina)))
		var new_progress = 1.0 - (float(dash_stamina) / float(max(1, max_dash_stamina)))
		
		progress_tween = create_tween()
		progress_tween.set_ignore_time_scale(true)
		progress_tween.set_trans(Tween.TRANS_SINE)
		progress_tween.set_ease(Tween.EASE_OUT)
		progress_tween.tween_method(_set_stamina_progress, old_progress, new_progress, 0.15)
		await progress_tween.finished
	
	if parent.has_node("OverdoseAbilityComponent") and parent.get_node("OverdoseAbilityComponent").active:
		parent.get_node("OverdoseAbilityComponent").ability_timer += overdose_refuel_count
		if overdose_refuel_sound:
			overdose_refuel_sound.play()

		if parent.has_node("HealthComponent"):
			var health: HealthComponent = parent.get_node("HealthComponent")
			health.set_delayed_damage(overdose_refuel_damage, overdose_refuel_damage_time)

		if parent.has_node("TrailEffectComponent"):
			parent.get_node("TrailEffectComponent").lifetime_timer += overdose_refuel_count
		
		_update_stamina_bar()
		return
	
	_cooldown()
	_INVINCIBLE()
	
	if trail_effect and !parent.has_node("TrailEffectComponent"):
		var trail: TrailEffectComponent = TrailEffectComponent.new()
		trail.lifetime = 0.5
		trail.colors = trail_colors
		parent.add_child(trail)
	
	if dash_sound:
		dash_sound.play()
	
	mob_mover_component.throw(direction, dash_speed, null, 1000, false)
	mob_mover_component.try_stand_up()

func _stamina_recovery() -> void:
	if dash_stamina < max_dash_stamina:
		var old_stamina = dash_stamina
		dash_stamina += 1
		
		if ability_icon and ability_icon.material:
			if stamina_tween:
				stamina_tween.kill()
			
			var old_progress = 1.0 - (float(old_stamina) / float(max(1, max_dash_stamina)))
			var new_progress = 1.0 - (float(dash_stamina) / float(max(1, max_dash_stamina)))
			
			stamina_tween = create_tween()
			stamina_tween.set_ignore_time_scale(true)
			stamina_tween.set_trans(Tween.TRANS_SINE)
			stamina_tween.set_ease(Tween.EASE_OUT)
			stamina_tween.tween_method(_set_stamina_progress, old_progress, new_progress, 0.3)
			await stamina_tween.finished
		
		if dash_stamina < max_dash_stamina:
			recovery_timer.start()

func _cooldown() -> void:
	if cooldown_delay != 0:
		cooldown = true
		recovery_timer.stop()
		await get_tree().create_timer(cooldown_delay, true, false, true).timeout
		cooldown = false
		
		if dash_stamina < max_dash_stamina:
			recovery_timer.start()

func _INVINCIBLE() -> void:
	if invincibility_delay != 0 and parent.has_node("HealthComponent"):
		var health_component = parent.get_node("HealthComponent")
		health_component.INVINCIBLE = true
		active = true
		await get_tree().create_timer(invincibility_delay).timeout
		health_component.INVINCIBLE = false
		active = false

func _on_collision(body) -> void:
	if !active:
		return
	if body is Area2D or body == parent:
		return
	if body.has_node("MobMoverComponent"):
		var mob_mover = body.get_node("MobMoverComponent")
		if mob_mover.flying:
			return
		
		var angle: float = deg_to_rad(randf_range(-90, 90))
		var random_direction = parent.velocity.rotated(angle).normalized()
		
		mob_mover.drop(1)
		mob_mover.throw(random_direction, 300, parent)

func _on_shoot(emitter: Node2D, _weapon: Weapon, direction: Vector2, projectile: Node2D) -> void:
	if !active or !parry_weapon or emitter != parent:
		return
	
	var projectile_component: ProjectileComponent = projectile.get_node_or_null("ProjectileComponent")
	if !projectile_component:
		return
	
	parry_weapon.parry_projectile(projectile, projectile_component, direction)
