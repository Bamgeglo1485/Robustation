class_name ChatterComponent extends Component

@export var enabled: bool = true
@export var typing_speed: float = 0.05
@export var typing_sound: AudioStreamPlayer2D
@export var bubble_template: PackedScene
@export var cooldown_delay: float = 1.5
@export var chat: Control
var cooldown = false

func can_say() -> bool:
	return !cooldown

func say(text: String) -> void:
	if cooldown or !chat or !enabled:
		return
	var message: Control = bubble_template.instantiate()
	chat.add_child.call_deferred(message)
	message.modulate = Color(0.0, 0.0, 0.0, 0.0)
	var text_control: Control = message.get_node("Text")
	var delay: float = typing_speed * len(text)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(message, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	tween.tween_property(message, "modulate", Color(1.0, 1.0, 1.0, 1.0), delay)
	tween.tween_property(message, "modulate", Color(0.0, 0.0, 0.0, 0.0), 0.3)
	animate(text_control, tr(text), delay)
	_cooldown()
	if typing_sound:
		typing_sound.play()
	await tween.finished
	message.queue_free()
	if typing_sound:
		typing_sound.stop()

func animate(control: Control, new_text: String, delay: float) -> void:
	var target_text: String
	
	var line: String = "\n"
	control.text = ""
	target_text = new_text
	
	if delay <= 0:
		control.text += line + target_text
	
	var regex = RegEx.new()
	regex.compile("(\\[\\/?[^\\]]+\\])|([^\\[]+)")
	var parts = regex.search_all(target_text)
	
	var visible_chars = 0
	for part in parts:
		var part_text = part.get_string()
		if !part_text.begins_with("["):
			visible_chars += part_text.length()
	
	@warning_ignore("incompatible_ternary")
	var time_per_char = delay / visible_chars if visible_chars > 0 else 0
	
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	var current_text = control.text
	
	for part in parts:
		var part_text = part.get_string()
		
		if part_text.begins_with("["):
			current_text += part_text
			tween.tween_property(control, "text", current_text, 0)
		else:
			for i in range(part_text.length()):
				current_text += part_text[i]
				tween.tween_property(control, "text", current_text, time_per_char)

func _cooldown() -> void:
	if cooldown_delay != 0:
		cooldown = true
		await get_tree().create_timer(cooldown, false).timeout
		cooldown = false
