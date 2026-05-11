class_name SlideAbilityComponent extends Component

@export var stamina_cost: float = 15
@export var cooldown_delay: float = 1.5
var cooldown: bool = false

var sliding: bool = false

@export var sound_effect: AudioStreamPlayer2D

var slide_tween: Tween
@onready var stamina: StaminaComponent = parent.get_node_or_null("StaminaComponent")
@onready var mob_mover: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
@onready var animation: AnimationComponent = parent.get_node_or_null("AnimationComponent")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("slide"):
		slide()

func slide() -> void:
	if !is_instance_valid(mob_mover):
		return
	if cooldown or sliding:
		return
	if mob_mover.fallen or parent.velocity.is_zero_approx():
		return
	_cooldown()
	
	sliding = true
	mob_mover.throw(parent.velocity, parent.velocity.length() * 0.65, null, 100, false, false, true)
	var velocity: Vector2 = -parent.velocity
	var rotation: Dictionary = animation.get_rotation_from_angle(rad_to_deg(velocity.angle()))
	slide_tween = create_tween()
	slide_tween.set_loops()
	if rotation.value > 0.25 and rotation.value <= 0.5:
		rotation.value = 0.5
	elif rotation.value < 0.5 and rotation.value >= -0.5:
		rotation.value = -0.5
	slide_tween.tween_property(parent, "rotation", rotation.value * 3, 0.1)
	animation.set_animation(slide_tween, 150, true)
	
	if stamina_cost != 0:
		stamina.take_stamina_damage(stamina_cost, null)
	
	if sound_effect:
		sound_effect.play()
	
	await mob_mover.unflied
	
	sliding = false
	animation.clear_animation()

func _cooldown() -> void:
	if cooldown_delay != 0:
		cooldown = true
		await tree.create_timer(cooldown_delay, true, false, true).timeout
		cooldown = false
