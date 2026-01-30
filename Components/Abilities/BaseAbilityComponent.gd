class_name BaseAbilityComponent extends Component

@export var cooldown: bool = false
@export var cooldown_delay: float = 30

@export var ability_delay: float = 0
@export var cooldown_on_activate: bool = false

@export var start_effect: PackedScene
@export var start_sound: AudioStreamPlayer2D
@export var stop_effect: PackedScene
@export var stop_sound: AudioStreamPlayer2D

var active: bool = false
var ability_timer: float = 0.0

func _ready() -> void:
	if parent.has_node("Sounds"):
		var sounds: Node = parent.get_node("Sounds")
		if start_sound:
			start_sound.reparent(sounds)
		if stop_sound:
			stop_sound.reparent(sounds)

func _process(delta: float) -> void:
	if ability_timer > 0:
		ability_timer -= delta
		if ability_timer <= 0:
			ability_timer = 0
			if active:
				on_disable_ability()
		
	
	input()

func input() -> void:
	if Input.is_action_just_pressed("ability") and !cooldown and !active:
		on_activate_ability()

func on_activate_ability() -> void:
	cooldown = true
	active = true
	
	if cooldown_on_activate:
		_start_cooldown()
	
	activate_ability()
	
	if ability_delay > 0:
		ability_timer = ability_delay
	else:
		on_disable_ability()
	
	if start_sound:
		start_sound.play()
	if start_effect:
		var inst: Node = start_effect.instantiate()
		inst.global_position = parent.global_position
		scene.add_child(inst)

func on_disable_ability() -> void:
	active = false
	
	if !cooldown_on_activate:
		_start_cooldown()
	
	disable_ability()
	
	if stop_sound:
		stop_sound.play()
	if stop_effect:
		var inst: Node = stop_effect.instantiate()
		inst.global_position = parent.global_position
		scene.add_child(inst)

func activate_ability() -> void:
	pass

func disable_ability() -> void:
	pass

func _start_cooldown() -> void:
		cooldown = true
		await get_tree().create_timer(cooldown_delay, true, false, true).timeout
		cooldown = false
