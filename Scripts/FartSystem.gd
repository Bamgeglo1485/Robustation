extends Node2D

@onready var area2d: Area2D = $Area2D
@export var delayed_damage: int = 3
@export var delayed_time: int = 5
@export var heal_teammates: bool = true
@export var heal_amount: int = 40
@export var radius: int = 128
@export var source: CharacterBody2D
@export var lifetime: float = 4.0
@export var update_rate: float = 0.5
@export var ignore_faction: bool = false
@export var rainbow_delay: float = 2.5

var active: bool = true
var check_timer: Timer

func _ready() -> void:
	if area2d.has_node("CollisionShape2D"):
		var shape = CircleShape2D.new()
		shape.radius = radius
		area2d.get_node("CollisionShape2D").shape = shape
	
	check_timer = Timer.new()
	add_child(check_timer)
	check_timer.wait_time = update_rate
	check_timer.one_shot = false
	check_timer.timeout.connect(_update)
	check_timer.start()
	
	await get_tree().create_timer(lifetime).timeout
	active = false
	if check_timer:
		check_timer.stop()
	area2d.queue_free()
	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = false
	
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _update() -> void:
	if !area2d:
		return
	check_timer.start()
	await get_tree().physics_frame
	var bodies = area2d.get_overlapping_bodies()
	
	for body in bodies:
		if (!ignore_faction and source and source.has_node("FactionComponent") and 
			body.has_node("FactionComponent")):
			
			var source_faction: Node = source.get_node("FactionComponent")
			var body_faction: Node = body.get_node("FactionComponent")
			
			if source_faction.faction == body_faction.faction:
				if !heal_teammates or heal_amount == 0:
					return
				if body.has_node("HealthComponent"):
					var body_health: HealthComponent = body.get_node("HealthComponent")
					body_health.take_damage(-heal_amount, source)
				return
		if body.has_node("HealthComponent"):
			body.get_node("HealthComponent").set_delayed_damage(delayed_damage, delayed_time)
		if body.has_node("RainbowOverlayComponent"):
			body.get_node("RainbowOverlayComponent").set_rainbow(rainbow_delay)
			
