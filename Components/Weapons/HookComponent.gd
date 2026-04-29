class_name Hook extends RangeWeapon

enum hook_states {
	BASE,
	FLYING,
	HOOKED,
	HOOKING,
	RETURNING}
@export var hook_speed: int = 1200
@export var returning_radius: int = 48
@export var state: hook_states = hook_states.BASE
@export var drop_force: int = 1
@export var hook_throw_force: int = 600
@export var weapon_to_reload: RangeWeapon

@export var reel_sound: AudioStreamPlayer2D

var hook: Node2D
var hook_projectile_comp: ProjectileComponent
var hooked_body: Node2D
var mob_mover_component: MobMoverComponent
var hook_enemy: bool = false
var target_mob_mover: MobMoverComponent

func _ready() -> void:
	super._ready()
	EventBusManager.projectile_hit.connect(_on_hit)
	EventBusManager.gibbed.connect(_on_gibbed)
	
	returning_radius *= returning_radius
	mob_mover_component = parent.get_node_or_null("MobMoverComponent")
	if main_weapon:
		main_weapon.swapped.connect(_on_swap)

func attack(raiser, _npc = true) -> void:
	if cooldown or !can_attack or swinging or !projectile or not raiser.has_method("get_attack_direction"):
		return
	
	if bullets == 0 and state == hook_states.BASE:
		return
	
	await _swing(raiser.get_attack_direction())
	bullets = 0
	var direction: Vector2 = raiser.get_attack_direction()
	
	if mob_mover_component:
		if self_throw_speed != 0:
			mob_mover_component.throw(-direction, self_throw_speed, null, self_throw_stop_speed)
	
	attack_logic(direction)

func on_release(_raiser) -> void:
	if state == hook_states.FLYING:
		_return()
	elif state == hook_states.HOOKED:
		_hook()

func _on_swap(_new_weapon: Weapon) -> void:
	if state == hook_states.HOOKED:
		_hook()
	elif state == hook_states.BASE:
		return
	elif state == hook_states.RETURNING:
		_return()

func attack_logic(direction):
	if state == hook_states.BASE:
		_shoot(direction)
	else:
		return

func _hook():
	state = hook_states.HOOKING
	target_mob_mover = hooked_body.get_node_or_null("MobMoverComponent")
	
	if reel_sound:
		reel_sound.play()
	var projectile_component: ProjectileComponent = hooked_body.get_node_or_null("ProjectileComponent")
	if projectile_component:
		var angle: float = (parent.global_position - hooked_body.global_position).angle()
		projectile_component.direction = angle
		projectile_component.max_penetrations = 100
		projectile_component.max_bounces += 12
		hooked_body.global_rotation = angle
	elif target_mob_mover and target_mob_mover.drop_resistance < drop_force:
		hook_enemy = true
		target_mob_mover.movement_blocked = true
	else:
		if mob_mover_component:
			mob_mover_component.movement_blocked = true

func _return():
	if cooldown:
		return
	state = hook_states.RETURNING
	if hook_projectile_comp:
		hook_projectile_comp.moving = true
		hook_projectile_comp.can_hit = false
	if hook_enemy and hooked_body:
		target_mob_mover.movement_blocked = false
	if reel_sound:
		reel_sound.play()

func _physics_process(_delta: float) -> void:
	if !rope or !hook:
		return
	var direction = parent.global_position - hook.global_position
	if state == hook_states.RETURNING and hook_projectile_comp:
		hook_projectile_comp.direction = direction.angle()
	elif state == hook_states.FLYING or state == hook_states.HOOKED:
		return
	elif state == hook_states.HOOKING:
		if !hook_enemy:
			parent.velocity = -direction.normalized() * hook_speed
		elif hooked_body is CharacterBody2D:
			hooked_body.velocity = direction.normalized() * hook_speed
	
	if direction.length_squared() < returning_radius:
		_delete_hook()
		if hooked_body and state == hook_states.HOOKING:
			if !hook_enemy:
				target_mob_mover.throw(parent.velocity, hook_throw_force, parent)

func _shoot(direction) -> Node2D:
	hook = super._shoot(direction)
	if !hook:
		return null
	hook_projectile_comp = hook.get_node_or_null("ProjectileComponent")
	state = hook_states.FLYING
	rope.visible = true
	
	if shoot_sound:
		shoot_sound.play()
	
	_cooldown()
	return hook

func _on_hit(emitter: Node2D, _projectile: Node2D) -> void:
	if _projectile != hook:
		return
	state = hook_states.HOOKED
	hooked_body = emitter

func _delete_hook():
	if mob_mover_component and !hook_enemy:
		mob_mover_component.movement_blocked = false
	elif hooked_body and target_mob_mover and hook_enemy:
		hooked_body.velocity = Vector2.ZERO
		target_mob_mover.movement_blocked = false
	if weapon_to_reload:
		weapon_to_reload._on_bullets_recover()
		weapon_to_reload.bullets_recover_timer.stop()
		EventBusManager.update_weapon_icon.emit(parent, weapon_to_reload)
	
	hook_enemy = false
	state = hook_states.BASE
	cooldown_timer.start()
	hook.queue_free()
	rope.visible = false
	bullets_recover_timer.start()
	parent.velocity /= 2
	if reel_sound:
		reel_sound.stop()
	_cooldown()

func _on_gibbed(emitter):
	if emitter == hooked_body and is_instance_valid(hook):
		hook.cancel_free()
		hook.call_deferred("reparent", scene)
		_return()
