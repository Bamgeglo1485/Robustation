class_name CMDInputComponent extends Component

@export var off_screen: OffScreenComponent
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
	var start_game: String
	if check_text == "geglo":
		text = "!best motherfucker in universe!"
	elif check_text == "hello":
		text = "Hello, Manager!"
	elif check_text == "hi":
		text = "Hello, Manager!"
	elif check_text == "hello, world!":
		text = "Hello, Manager!"
	elif check_text == "sex":
		text = "[color=red]NO ERP![/color]"
	elif check_text == "purge_system" or check_text == "test_system":
		text = "[color=red]Command required![/color]"
	elif check_text == "test_system init":
		text = "[color=red]Test type required![/color]"
	elif check_text == "cum":
		text = "[color=red]Must've been the wind[/color]"
	elif check_text == "readmin":
		text = "[color=red]Access denied[/color]"
	elif check_text == "sv_cheats 1":
		text = "[color=red]Access denied. Fuck you, nerd.[/color]"
	elif check_text == "shutdown":
		text = "[color=red]Shutdowning...[/color]"
		if off_screen:
			off_screen._off()
	
	# COMMANDS
	elif check_text == "test_system init arena" and roundstart_component:
		start_game = "arena"
		text = "[color=yellow]WARN: Purger subject testing procedure initialized...[/color]\n[color=green]Subject loaded\nArea injection: Successful!\nSubject injection: Successful!\nData verification: Successful![/color]\n\n[color=red]Have fun![/color]"
	elif check_text == "ultrakill is shit" and roundstart_component:
		start_game = "v1"
		text = "[color=yellow]WARN: Purger subject testing procedure initialized...[/color]\n[color=green]Subject loaded\nArea injection: Successful!\nSubject injection: Successful!\nData verification: Successful![/color]\n\n[color=red]Have fun![/color]"
	elif check_text == "test_system init arena" and !roundstart_component:
		text = "[color=red]ERROR 404: test_system NOT FOUND[/color]"
	else:
		text = new_text + "[color=red] not recognized as an internal or external command[/color]"
	
	cmd_output.text += "\n\n" + input_text + new_text
	text_printing.animate(text, delay, false, false)
	if roundstart_component and start_game:
		roundstart_component.start_game(start_game)
