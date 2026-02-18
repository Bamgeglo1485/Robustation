class_name CMDInputComponent extends Component

@export var cmd_output: Control
@onready var text_printing: TextPrintingAnimationComponent = cmd_output.get_node_or_null("TextPrintingAnimationComponent")

@export var delay: float = 0.2

@export var roundstart_component: RoundstartComponent

var animation_tween: Tween

func _ready() -> void:
	if !cmd_output or parent is not LineEdit:
		return
	
	parent.text_submitted.connect(_on_text_submitted)
	parent.editing_toggled.connect(_editing_toggled)
	_start_animation()

func _start_animation() -> void:
	animation_tween = create_tween()
	animation_tween.set_trans(Tween.TRANS_SINE)
	animation_tween.set_ease(Tween.EASE_IN_OUT)
	animation_tween.set_loops()
	
	animation_tween.tween_property(parent, "text", "", delay)
	animation_tween.tween_property(parent, "text", ".", delay)

func _editing_toggled(toggled) -> void:
	if toggled:
		animation_tween.kill()
		parent.text = ""
	else:
		_start_animation()

func _on_text_submitted(new_text: String):
	parent.text = ""
	var check_text: String = new_text.to_lower()
	var input_text: String = "C:/Omega/Manager>"
	var text: String
	if check_text == "geglo":
		text = "!best motherfucker in universe!"
	elif check_text == "omega":
		text = "STATUS: BRAINFARMS ACTIVE\nINF CODE: 33F4\nANNOTATIONS: OVERLAPPING DETECTED!\nACCESS DENIED"
	elif check_text == "33f4":
		text = "Egregor stabilization is unstable. 300> Remnants detected. Possible merge anomalies."
	elif check_text == "hello":
		text = "Hello, Manager!"
	elif check_text == "hello, world!":
		text = "Hello, Manager!"
	elif check_text == "sex":
		text = "NO ERP!"
	elif check_text == "purge_system" or check_text == "test_system":
		text = "Command required!"
	elif check_text == "test_system init":
		text = "Test type required!"
	elif check_text == "merge anomalies" or check_text == "merge anomaly":
		text = "Merge Anomalies are manifestations resulting from the blending of multiple layers of information, creating spatial distortions. The primary cause is a large amount of Remnant."
	elif check_text == "remnant":
		text = "Remnant is residual information within an Egregore, mostly representing alternative scenarios or potential developments of events. In rare cases, it is information left behind after the deletion of an Eidos."
	elif check_text == "eidos":
		text = "Eidos is information within an Egregore that has acquired a physical form within it due to the superimposition of data."
	elif check_text == "egregore":
		text = "Egregore is an informational field containing data from the entire universe within an invisible, all-encompassing space."
	elif check_text == "egregore":
		text = "Egregore is an informational field containing data from the entire universe within an invisible, all-encompassing space."
	
	# COMMANDS
	
	elif check_text == "test_system init arena" and roundstart_component:
		roundstart_component.start_game("arena")
		text = "WARN: Purger subject testing procedure initialized...\nSubject loaded\nArea injection: Successful!\nSubject injection: Successful!\nData verification: Successful!\n\nHave fun!"
	elif check_text == "test_system init arena" and !roundstart_component:
		text = "ERROR 404: test_system NOT FOUND"
	else:
		text = new_text + " not recognized as an internal or external command"
	
	cmd_output.text += "\n\n" + input_text + new_text
	text_printing.animate(text, delay, false, false)
