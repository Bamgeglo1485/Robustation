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
	
	if clear:
		parent.text = ""
		target_text = new_text
	else:
		var line: String = "\n"
		if double_line:
			line += "\n"
		target_text = parent.text + line + new_text
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(parent, "text", target_text, delay)
	
	if !block_frame:
		return
	
	block_frame.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED
	await tween.finished
	block_frame.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
