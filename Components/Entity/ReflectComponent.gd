class_name ReflectComponent extends Component

@export var projectile_chance: float = 0.0
@export var melee_chance: float = 0.0

@export var melee_reflect_sound: AudioStream = preload("res://Audio/Weapon/parry.ogg")
@export var projectile_reflect_sound: AudioStream = preload("res://Audio/Effects/glass_crack4.ogg")
var projectile_reflect_player: AudioStreamPlayer2D
var melee_reflect_player: AudioStreamPlayer2D

@export_category("Modifier")
@export var projectile_chance_addendums: Dictionary
@export var projectile_chance_addendum: float = 0.0
@export var melee_chance_addendums: Dictionary
@export var melee_chance_addendum: float = 0.0

func _ready() -> void:
	if projectile_reflect_sound:
		projectile_reflect_player = AudioStreamPlayer2D.new()
		projectile_reflect_player.stream = projectile_reflect_sound
		parent.add_child.call_deferred(projectile_reflect_player)
	if melee_reflect_sound:
		melee_reflect_player = AudioStreamPlayer2D.new()
		melee_reflect_player.stream = melee_reflect_sound
		parent.add_child.call_deferred(melee_reflect_player)

func melee_reflect(attacker: PhysicsBody2D, weapon: MeleeWeapon) -> bool:
	if randf() > melee_chance:
		return false
	if !attacker or !weapon:
		return false
	var direction: Vector2 = attacker.global_position - parent.global_position
	weapon._melee_attack_target(attacker, direction, false)
	
	if melee_reflect_player:
		melee_reflect_player.play()
	
	return true

func projectile_reflect(target: Node2D, projectile: Node2D, projectile_comp: ProjectileComponent) -> bool:
	if randf() > projectile_chance:
		return false
	
	var angle = (projectile_comp.shooter.global_position - projectile.global_position).normalized().angle()
	
	projectile.modulate = Color(2.658, 2.362, 0.0, 1.0)
	projectile.global_rotation = angle
	projectile_comp.direction = angle
	projectile_comp.shooter = target
	var target_faction: FactionComponent = target.get_node_or_null("FactionComponent")
	projectile_comp.shooter_faction = target_faction
	
	if projectile_reflect_player:
		projectile_reflect_player.play()
	
	var trail = TrailEffectComponent.new()
	trail.trail_lifetime = 0.2
	trail.end_color = Color(0.544, 0.0, 0.578, 0.0)
	var colors: Array[Color] = [
		Color(3.674, 1.907, 0.0, 1.0),
		Color(3.236, 0.576, 1.751, 1.0)]
	trail.colors = colors
	projectile.add_child(trail)
	
	return true
