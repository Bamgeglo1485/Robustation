class_name TextPrintingAnimationComponent extends Component

@export var animate_on_ready: bool = true
@export var animate_on_ready_delay: float = 3
@export var block_frame: Control
var tween: Tween

func _ready() -> void:
	if animate_on_ready:
		animate(parent.text, animate_on_ready_delay, true)

func animate(new_text: String, delay: float, clear: bool = false, double_line: bool = true) -> void:
	var target_text: String
	
	var line: String = "\n"
	if clear:
		parent.text = ""
		target_text = new_text
	else:
		if double_line:
			line += "\n"
		target_text = new_text
	
	if delay <= 0:
		if clear:
			parent.text = target_text
		else:
			parent.text += line + target_text
		return
	
	var regex = RegEx.new()
	regex.compile("(\\[\\/?[^\\]]+\\])|([^\\[]+)")
	var parts = regex.search_all(target_text)
	
	var visible_chars = 0
	for part in parts:
		var part_text = part.get_string()
		if not part_text.begins_with("["):
			visible_chars += part_text.length()
	
	@warning_ignore("incompatible_ternary")
	var time_per_char = delay / visible_chars if visible_chars > 0 else 0
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	var current_text = parent.text
	
	if not clear:
		current_text += line
		tween.tween_property(parent, "text", current_text, 0)
	
	for part in parts:
		var part_text = part.get_string()
		
		if part_text.begins_with("["):
			current_text += part_text
			tween.tween_property(parent, "text", current_text, 0)
		else:
			for i in range(part_text.length()):
				current_text += part_text[i]
				tween.tween_property(parent, "text", current_text, time_per_char)
	
	_block()

func _block() -> void:
	if !block_frame:
		return
	
	block_frame.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED
	await tween.finished
	block_frame.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
