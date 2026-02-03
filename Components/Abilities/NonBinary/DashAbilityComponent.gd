class_name DashAbilityComponent extends Component

@export var trail_effect: bool = true
@export var dash_sound: AudioStreamPlayer2D
@export var overdose_refuel_sound: AudioStreamPlayer2D
@export var overdose_refuel_damage: int = 5
@export var overdose_refuel_damage_time: int = 8
@export var overdose_refuel_count: float = 2.5

@export var cooldown: bool = false
@export var cooldown_delay: float = 0.5

@export var dash_speed: int = 1050

@export var max_dash_stamina: int = 3
@export var dash_stamina: int = max_dash_stamina
@export var dash_stamina_recovery_delay: float = 3.0

@export var invincibility_delay: float = 0.3
@export var trail_colors: Array[Color]

@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
var recovery_timer: Timer
var active: bool = false

func _ready() -> void:
	recovery_timer = Timer.new()
	add_child(recovery_timer)
	recovery_timer.wait_time = dash_stamina_recovery_delay
	recovery_timer.one_shot = true
	recovery_timer.start()
	recovery_timer.timeout.connect(_stamina_recovery)
	
	if parent.has_node("Area2D"):
		parent.get_node("Area2D").body_entered.connect(_on_collision)
		
func _process(_delta: float) -> void:
	if parent.has_node("InputMoverComponent"):
		input()

func input() -> void:
	if !mob_mover_component:
		return
	
	if Input.is_action_just_pressed("dash"):
		var direction: Vector2 = mob_mover_component.direction
		if direction == Vector2.ZERO:
			direction = (parent.get_global_mouse_position() - parent.global_position)
		
		dash(direction)

func dash(direction) -> void:
	if !mob_mover_component or parent is not CharacterBody2D:
		return
	if dash_stamina == 0 or cooldown or direction == Vector2.ZERO:
		return
	
	dash_stamina -= 1
	
	if parent.has_node("OverdoseAbilityComponent") and parent.get_node("OverdoseAbilityComponent").active:
		parent.get_node("OverdoseAbilityComponent").ability_timer += overdose_refuel_count
		if overdose_refuel_sound:
			overdose_refuel_sound.play()

		if parent.has_node("HealthComponent"):
			var health: HealthComponent = parent.get_node("HealthComponent")
			health.set_delayed_damage(overdose_refuel_damage, overdose_refuel_damage_time)

		if parent.has_node("TrailEffectComponent"):
			parent.get_node("TrailEffectComponent").lifetime_timer += overdose_refuel_count
		return
	
	if trail_effect and !parent.has_node("TrailEffectComponent"):
		var trail: TrailEffectComponent = TrailEffectComponent.new()
		trail.lifetime = 0.5
		trail.colors = trail_colors
		parent.add_child(trail)
	
	if dash_sound:
		dash_sound.play()
	
	mob_mover_component.throw(direction, dash_speed, null, 1000, false)
	
	_cooldown()
	_INVINCIBLE()

func _stamina_recovery() -> void:
	if dash_stamina != max_dash_stamina:
		dash_stamina += 1
		recovery_timer.start()

func _cooldown() -> void:
	if cooldown_delay != 0:
		cooldown = true
		recovery_timer.stop()
		await get_tree().create_timer(cooldown_delay).timeout
		cooldown = false
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
