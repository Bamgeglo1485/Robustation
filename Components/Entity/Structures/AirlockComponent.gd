class_name AirlockComponent extends Component

const OPENED = "Opened"
const CLOSED = "Closed"
const OPENING = "Opening"
const CLOSING = "Closing"
const BOLTED = "Bolted"

enum airlock_states {OPENED, CLOSED, OPENING, CLOSING, BOLTED}
@export var state: airlock_states = airlock_states.CLOSED
@export var collision: CollisionShape2D

@export_category("Delays")
@export var closing_collision_delay: float = 0.3
@export var closing_delay: float = 0.5
@export var opening_collision_delay: float = 0.3
@export var opening_delay: float = 0.5

@export_category("Sprites")
@export var closed_sprite: Sprite2D
@export var closed_unlit_sprite: Sprite2D
@export var opened_sprite: Sprite2D
@export var opened_unlit_sprite: Sprite2D
@export var closing_sprite: Sprite2D
@export var closing_unlit_sprite: Sprite2D
@export var opening_sprite: Sprite2D
@export var opening_unlit_sprite: Sprite2D
@export var bolted_unlit: Sprite2D

@export var closing_animation_frames: int = 5
@export var opening_animation_frames: int = 5

@export_category("Sounds")
@export var open_sound: AudioStreamPlayer2D
@export var close_sound: AudioStreamPlayer2D
@export var bolt_sound: AudioStreamPlayer2D
@export var unbolt_sound: AudioStreamPlayer2D

func open(unbolt_airlock = false):
	if state == airlock_states.OPENED or state == airlock_states.OPENING:
		return
	
	if state == airlock_states.BOLTED:
		if unbolt_airlock == true:
			unbolt()
		else:
			return
	
	if state != airlock_states.CLOSED:
		return
	
	closed_sprite.visible = false
	if closed_unlit_sprite != null:
		opening_unlit_sprite.frame = 0
		closed_unlit_sprite.visible = false
	
	opening_sprite.frame = 0
	opening_sprite.visible = true
	
	if open_sound != null:
		open_sound.play()
	
	if opening_animation_frames > 1:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(opening_sprite, "frame", opening_animation_frames, opening_delay)
	
	if opening_unlit_sprite != null:
		opening_unlit_sprite.visible = true
		if opening_animation_frames > 1:
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(opening_unlit_sprite, "frame", opening_animation_frames, opening_delay)
	
	state = airlock_states.OPENING
	
	await get_tree().create_timer(opening_collision_delay).timeout
	if collision != null:
		collision.disabled = true
	
	await get_tree().create_timer(opening_delay - opening_collision_delay).timeout
	
	state = airlock_states.OPENED
	
	opening_sprite.visible = false
	if opening_unlit_sprite != null:
		opening_unlit_sprite.visible = false
	
	opened_sprite.visible = true
	if opened_unlit_sprite != null:
		opened_unlit_sprite.visible = true

func close():
	if state == airlock_states.CLOSED or state == airlock_states.CLOSING or state == airlock_states.BOLTED:
		return
	
	if state != airlock_states.OPENED:
		return
	
	opened_sprite.visible = false
	if opened_unlit_sprite != null:
		opened_unlit_sprite.visible = false
	
	closing_sprite.frame = 0
	closing_sprite.visible = true
	
	if close_sound != null:
		close_sound.play()
	
	if closing_animation_frames > 1:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(closing_sprite, "frame", closing_animation_frames, closing_delay)
	
	if closing_unlit_sprite != null:
		closing_unlit_sprite.frame = 0
		closing_unlit_sprite.visible = true
		if closing_animation_frames > 1:
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(closing_unlit_sprite, "frame", closing_animation_frames, closing_delay)
	
	state = airlock_states.CLOSING
	
	await get_tree().create_timer(closing_collision_delay).timeout
	if collision != null:
		collision.disabled = false
	
	await get_tree().create_timer(closing_delay - closing_collision_delay).timeout
	
	state = airlock_states.CLOSED
	
	closing_sprite.visible = false
	if closing_unlit_sprite != null:
		closing_unlit_sprite.visible = false
	
	closed_sprite.visible = true
	if closed_unlit_sprite != null:
		closed_unlit_sprite.visible = true

func bolt():
	if state != airlock_states.CLOSED:
		if state == airlock_states.OPENED or state == airlock_states.OPENING:
			await close()
		else:
			return
	
	if bolt_sound != null:
		bolt_sound.play()
	
	state = airlock_states.BOLTED
	
	closed_sprite.visible = false
	if closed_unlit_sprite != null:
		closed_unlit_sprite.visible = false
	
	if bolted_unlit != null:
		bolted_unlit.visible = true

func unbolt():
	if state != airlock_states.BOLTED:
		return
	
	if unbolt_sound != null:
		unbolt_sound.play()
	
	state = airlock_states.CLOSED
	
	if bolted_unlit != null:
		bolted_unlit.visible = false
	
	closed_sprite.visible = true
	if closed_unlit_sprite != null:
		closed_unlit_sprite.visible = true
