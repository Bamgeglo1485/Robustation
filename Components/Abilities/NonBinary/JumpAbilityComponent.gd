class_name JumpAbilityComponent extends Component

@export var stamina_cost: float = 5

@export var jump_delay: float = 0.4
var is_on_air: bool

@export var jump_mask: int = 20

@export var cooldown_delay: float = 0.5
var cooldown: bool = false

@export var sound_effect: AudioStreamPlayer2D
@export var wall_sound_effect: AudioStreamPlayer2D

var fly_animation_tween: Tween
@onready var mob_mover: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")
@onready var stamina: StaminaComponent = parent.get_node_or_null("StaminaComponent")
@onready var animation: AnimationComponent = parent.get_node_or_null("AnimationComponent")
@onready var texture: Sprite2D = parent.get_node_or_null("Texture")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()

func jump() -> void:
	if !is_instance_valid(mob_mover):
		return
	if parent.is_on_wall() and is_on_air:
		mob_mover.throw(parent.get_wall_normal(), 900, null, 750, false, false, false)
		if wall_sound_effect:
			wall_sound_effect.play()
	if cooldown:
		return
	if is_on_air or mob_mover.fallen or mob_mover.flying:
		return
	is_on_air = true
	_cooldown()
	
	parent.set_collision_mask_value(jump_mask, false)
	mob_mover.throw(parent.velocity, 650, null, 550, false, false, false)
	
	fly_animation_tween = create_tween()
	fly_animation_tween.tween_property(texture, "scale", Vector2(1.2, 1.2), jump_delay/2)
	fly_animation_tween.tween_property(texture, "scale", Vector2(1.0, 1.0), jump_delay/2)
	animation.set_animation(fly_animation_tween, 100, true)
	
	if stamina_cost != 0:
		stamina.take_stamina_damage(stamina_cost, null)
	
	if sound_effect:
		sound_effect.play()
	
	await tree.create_timer(jump_delay).timeout
	
	parent.set_collision_mask_value(jump_mask, true)
	is_on_air = false
	if animation.animation_priority <= 100:
		animation.clear_animation()
	else:
		fly_animation_tween = create_tween()
		fly_animation_tween.tween_property(texture, "scale", Vector2(1, 1), 0.1)

func _cooldown() -> void:
	if cooldown_delay != 0:
		cooldown = true
		await tree.create_timer(cooldown_delay, true, false, true).timeout
		cooldown = false
